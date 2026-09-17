import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";
import {
  getAccessToken,
  parseServiceAccount,
  sendFcmMessage,
  stringifyData,
} from "../_shared/fcm.ts";

type CampaignRow = {
  id: string;
  title: string;
  body: string;
  type: string;
  data: Record<string, unknown> | null;
};

type TokenRow = {
  token: string;
  user_id: string;
};

const CHUNK = 100;
const CONCURRENCY = 20;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const authHeader = request.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("Usuário não autenticado.", 401);
  }

  let body: { campaignId?: string };
  try {
    body = await request.json();
  } catch (_) {
    return errorResponse("Payload inválido.", 400);
  }

  const campaignId = (body.campaignId ?? "").trim();
  if (!campaignId) {
    return errorResponse("campaignId obrigatório.", 400);
  }

  const rawAccount = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!rawAccount) {
    return jsonResponse({
      ok: false,
      skipped: true,
      reason: "FCM_SERVICE_ACCOUNT_JSON não configurado.",
      sent: 0,
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const bearer = authHeader.replace(/^Bearer\s+/i, "").trim();
  const isServiceRole = bearer === serviceRoleKey;

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);

  if (!isServiceRole) {
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return errorResponse("Usuário não autenticado.", 401);
    }
    const { data: profile } = await serviceClient
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();
    const role = (profile as { role?: string } | null)?.role;
    if (role !== "admin" && role !== "financeiro") {
      return errorResponse("Sem permissão para enviar push.", 403);
    }
  }

  const { data: campaign, error: campaignError } = await serviceClient
    .from("notification_campaigns")
    .select("id, title, body, type, data")
    .eq("id", campaignId)
    .maybeSingle();

  if (campaignError || !campaign) {
    return errorResponse("Campanha não encontrada.", 404);
  }

  const campaignRow = campaign as CampaignRow;
  const { data: recipients, error: recipientsError } = await serviceClient
    .from("notifications")
    .select("user_id")
    .eq("campaign_id", campaignId);

  if (recipientsError) {
    return errorResponse(`Erro ao listar destinatários: ${recipientsError.message}`, 500);
  }

  const userIds = [...new Set(
    ((recipients ?? []) as Array<{ user_id: string }>).map((row) => row.user_id),
  )];

  if (userIds.length === 0) {
    return jsonResponse({ ok: true, sent: 0, failed: 0, skippedTokens: 0 });
  }

  const tokens: TokenRow[] = [];
  for (let i = 0; i < userIds.length; i += CHUNK) {
    const slice = userIds.slice(i, i + CHUNK);
    const { data, error } = await serviceClient
      .from("device_tokens")
      .select("token, user_id")
      .in("user_id", slice);
    if (error) {
      return errorResponse(`Erro ao buscar tokens: ${error.message}`, 500);
    }
    tokens.push(...((data ?? []) as TokenRow[]));
  }

  if (tokens.length === 0) {
    return jsonResponse({
      ok: true,
      sent: 0,
      failed: 0,
      skippedTokens: 0,
      reason: "Nenhum aparelho registrado.",
    });
  }

  let account;
  try {
    account = parseServiceAccount(rawAccount);
  } catch (error) {
    return errorResponse(String(error), 500);
  }

  let accessToken: string;
  try {
    accessToken = await getAccessToken(account);
  } catch (error) {
    return errorResponse(String(error), 500);
  }

  const payload = {
    title: campaignRow.title,
    body: campaignRow.body,
    data: {
      ...stringifyData(campaignRow.data),
      campaign_id: campaignRow.id,
      type: campaignRow.type,
    },
  };

  let sent = 0;
  let failed = 0;
  const stale: string[] = [];

  for (let i = 0; i < tokens.length; i += CONCURRENCY) {
    const batch = tokens.slice(i, i + CONCURRENCY);
    const results = await Promise.all(
      batch.map((row) =>
        sendFcmMessage(account.project_id, accessToken, row.token, payload)
      ),
    );
    results.forEach((result, index) => {
      if (result.ok) {
        sent += 1;
        return;
      }
      failed += 1;
      if (result.unregistered) stale.push(batch[index].token);
    });
  }

  if (stale.length > 0) {
    await serviceClient.from("device_tokens").delete().in("token", stale);
  }

  return jsonResponse({
    ok: true,
    sent,
    failed,
    skippedTokens: stale.length,
  });
});
