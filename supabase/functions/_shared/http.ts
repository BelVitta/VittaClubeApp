export const jsonResponse = (body: unknown, status = 200): Response => {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
};

export const errorResponse = (message: string, status = 400): Response => {
  return jsonResponse({ ok: false, error: message }, status);
};

type RpcClient = {
  rpc: (
    fn: string,
    args?: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: { message?: string } | null }>;
};

/** Rate limit por JWT (tabela public.rate_limit_buckets). null = pode seguir. */
export async function enforceRateLimit(
  client: RpcClient,
  action: string,
  max: number,
  windowSeconds = 60,
): Promise<Response | null> {
  const { data, error } = await client.rpc("try_consume_rate_limit", {
    p_action: action,
    p_max: max,
    p_window_seconds: windowSeconds,
  });
  if (error) {
    return errorResponse("Não foi possível processar a solicitação.", 500);
  }
  if (data === false) {
    return errorResponse(
      "Muitas tentativas. Aguarde um minuto e tente novamente.",
      429,
    );
  }
  return null;
}
