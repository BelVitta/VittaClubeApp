export const jsonResponse = (body: unknown, status = 200): Response => {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
};

export const errorResponse = (message: string, status = 400): Response => {
  return jsonResponse({ ok: false, error: message }, status);
};
