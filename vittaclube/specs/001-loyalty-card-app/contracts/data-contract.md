# Data Contract: Vitta Clube

## Repository Contract

Repositories devem retornar `Either<Failure, T>` e expor entities de dominio,
nunca models de Supabase diretamente.

```text
UseCase -> Repository interface -> Repository implementation -> DataSource
```

## DataSource Contract

Datasources podem ser:

- local/static para primeira versao da home comercial;
- Supabase para dados dinamicos;
- mock apenas em testes ou ambientes de desenvolvimento.

Datasources convertem erros externos em exceptions internas. Repositories
convertem exceptions em failures.

## Commercial Home Content Contract

Origem inicial: datasource local/static.

Origem futura: Supabase ou CMS.

Campos minimos:

- hero: headline, subtitle, CTAs, proof, priceHint;
- steps: title, description, icon;
- benefits: title, description, icon;
- plans: name, price, billingCycle, benefits, CTA;
- levels: name, discountPercent, limit, requirements;
- professionals: name, specialty, registry, photoUrl;
- partners: name, category, services, discount;
- draws: title, prize, rules, date;
- faq: question, answer;
- contact: phone, WhatsApp, email, address/region, hours;
- seo: title, description, region, keywords, social image.

## Supabase Contract

Dados devem ser separados por intencao de acesso:

- public_content: conteudo comercial e SEO sem dados sensiveis;
- profiles: dados de usuario, com mascaramento por role;
- subscriptions: plano e status do cliente;
- payments: status para cliente/admin, valores para super admin;
- professionals/specialties: leitura para clientes, escrita para admin/super
  admin;
- partners/services: leitura para clientes, escrita conforme role;
- consultations: cliente ve proprias, admin/super admin operam;
- draws/coupons: cliente ve elegiveis, super admin configura;
- audit_log: escrita obrigatoria para acoes sensiveis, leitura restrita.

## Cache Contract

Cache local permitido para:

- sessao e flags nao sensiveis;
- conteudo publico pouco mutavel;
- preferencias de UI;
- ultimos dados nao sensiveis para melhorar experiencia offline parcial.

Cache local proibido para:

- tokens de pagamento;
- CPF completo;
- dados financeiros detalhados;
- segredos;
- payloads que permitam fraude de beneficios.

## Error Contract

Falhas devem ser classificadas como:

- network;
- unauthorized;
- forbidden;
- notFound;
- validation;
- conflict;
- server;
- unknown.

Toda falha visivel deve ter mensagem humana, proximo passo e opcao de tentar
novamente quando aplicavel.
