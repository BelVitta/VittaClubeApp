// Página-ponte para o retorno do checkout InfinitePay.
//
// A API da InfinitePay exige que `redirect_url` seja uma URI http(s) —
// recusa esquemas customizados como `vittaclube://...` (erro "is not a
// valid URI"). Por isso o app manda esta URL (https) como redirect_url.
//
// O gateway de Edge Functions do Supabase injeta um
// `Content-Security-Policy: sandbox` nas respostas, o que bloquearia um
// redirecionamento via <script>/JS. Por isso usamos um 302 HTTP puro com
// `Location` apontando pro esquema customizado — o navegador/SO intercepta
// o redirect sem precisar executar nada.
const APP_DEEP_LINK = "vittaclube://payment/infinitypay/return";

Deno.serve((request) => {
  const url = new URL(request.url);
  const query = url.search.replace(/^\?/, "");
  const target = query ? `${APP_DEEP_LINK}?${query}` : APP_DEEP_LINK;
  return Response.redirect(target, 302);
});
