import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { errorResponse, jsonResponse } from "../_shared/http.ts";

Deno.serve(async (request) => {
  if (request.method !== "GET" && request.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  const authHeader = request.headers.get("Authorization");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");

  if (!authHeader || !anonKey || !serviceRoleKey || !supabaseUrl) {
    return errorResponse("Health-check not configured.", 500);
  }

  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (token !== anonKey && token !== serviceRoleKey) {
    return errorResponse("Unauthorized.", 401);
  }

  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  const { error } = await serviceClient
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .limit(1);

  if (error) {
    return errorResponse(`Database health-check failed: ${error.message}`, 500);
  }

  return jsonResponse({
    ok: true,
    checkedAt: new Date().toISOString(),
  });
});
