# Setup Dev / Prod — TODO futuro

> Staging hoje aponta para o mesmo Supabase de prod. Quando der tempo, separar.

## Criar projeto `vita-clube-dev`
- [ ] Dashboard Supabase → New Project → `vita-clube-dev`
- [ ] Guardar URL e anon key
- [ ] Ativar extensões: `uuid-ossp`, `pgcrypto`, `pgsodium`
- [ ] `ALTER DATABASE postgres SET app.encryption_key = '<chave-forte>';`

## Aplicar schema no dev
- [ ] Rodar `supabase/schema.sql` inteiro no SQL Editor
- [ ] Rodar `supabase/migrations/20260422_fix_google_signup.sql`
- [ ] Criar policy `Allow profile creation on signup` em `public.profiles`
- [ ] Authentication → Providers → Google (usar mesmo OAuth client do app)

## Popular seed
- [ ] Authentication → Users → Add User: `demo@vitaclube.com` (Auto Confirm)
- [ ] Rodar `supabase/seed.sql` no SQL Editor

## Apontar staging pro novo dev
- [ ] Em `lib/core/config/app_config.dart` função `initStaging()`:
  - [ ] Trocar `supabaseUrl` default pelo URL do `vita-clube-dev`
  - [ ] Trocar `supabaseAnonKey` default pelo anon key do `vita-clube-dev`
- [ ] Testar: `flutter run -t lib/main_staging.dart`

## Sessão 24h (quando fizer)
- [ ] Dashboard → Authentication → Sessions:
  - [ ] JWT expiry = 3600
  - [ ] Inactivity timeout = 86400
  - [ ] Time-box = 86400
- [ ] No `SplashBloc` validar `session.createdAt + 24h` e deslogar se expirado

## Outros TODOs
- [ ] Gateway real de pagamento (Stripe / Mercado Pago / Pagar.me) — trocar `MockPaymentGateway` no DI
- [ ] Edge Function de webhook de pagamento (`supabase/functions/payment_webhook/`)
- [ ] Flavors nativos Android/iOS (`productFlavors` + schemes)
- [ ] Tela "completar cadastro" (CPF/telefone) após login Google quando `profile.cpf_hash IS NULL`
- [ ] Feature `consultation` para usuário final — listar `consultations` do Supabase filtrado por `user_id` na home (hoje está hardcoded em `home_page.dart` `_consultations`)
