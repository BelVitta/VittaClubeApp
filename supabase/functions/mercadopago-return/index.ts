const outcomes: Record<string, { title: string; message: string }> = {
  approved: {
    title: "Pagamento recebido",
    message: "Você pode fechar esta página e voltar ao aplicativo.",
  },
  pending: {
    title: "Pagamento em processamento",
    message: "Volte ao aplicativo para acompanhar a confirmação da assinatura.",
  },
  rejected: {
    title: "Pagamento não aprovado",
    message: "Volte ao aplicativo para revisar o pagamento e tentar novamente.",
  },
};

Deno.serve((request) => {
  if (request.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const status = new URL(request.url).searchParams.get("status") ?? "pending";
  const outcome = outcomes[status] ?? outcomes.pending;
  const html = `<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${outcome.title} — Vitta Clube</title>
    <style>
      body { font-family: system-ui, sans-serif; margin: 0; min-height: 100vh;
        display: grid; place-items: center; background: #f7f8fa; color: #17202a; }
      main { max-width: 32rem; margin: 1.5rem; padding: 2rem; border-radius: 1rem;
        background: #fff; box-shadow: 0 8px 32px rgba(0,0,0,.08); text-align: center; }
      h1 { margin-top: 0; }
    </style>
  </head>
  <body><main><h1>${outcome.title}</h1><p>${outcome.message}</p></main></body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'",
      "X-Content-Type-Options": "nosniff",
    },
  });
});
