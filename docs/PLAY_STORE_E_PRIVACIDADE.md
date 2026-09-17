# Play Store, termos e privacidade — Vitta Clube

O que a Google vai revisar para o app ir à produção, o que o código tem hoje e o que falta. Foco na primeira loja: **Google Play**. App Store (iOS) só entra como nota.

Este documento não cobre PIX/landing. Fonte da verdade do produto de clube: [sdd-loyalty-mvp-implementation.md](./sdd-loyalty-mvp-implementation.md).

---

## 1. O que a Play Store realmente valida

O revisor **não testa** se o laboratório aplica 15% no caixa. Ele compara **o APK + a ficha + a política de privacidade + o formulário Data safety**. Se o app pede CPF e a política não fala CPF, recusam.

| Etapa no Play Console | O que pedem | Estado no repo hoje |
|---|---|---|
| Conta de desenvolvedor | Taxa única; contas **pessoais novas** precisam de **teste fechado ~14 dias com ≥12 testadores** antes da produção | Operacional (fora do git) |
| Identidade do APK | `applicationId` único, keystore de upload, `versionCode`/`versionName` | **`com.example.vita_clube`**. Release em `android/app/build.gradle.kts` ainda usa **signing debug** |
| Ficha da loja | Nome, descrição, ícone, screenshots telefone, categoria, e-mail de contato | Precisa existir e bater com o produto (clube de desconto, **não** plano de saúde) |
| **Política de privacidade** | URL **https pública**, sem login, no Console **e** no app | **Não existe.** Perfil → Privacidade → “Política” é `TODO` |
| Data safety | O que coleta, se criptografa em trânsito, se vende dado, se o usuário pode apagar | App coleta nome, e-mail, CPF, telefone, pagamento — tem que declarar |
| Recursos financeiros | Assinatura / Pix / cartão | Declarar cobrança recorrente |
| Saúde | Consulta e desconto médico | Pode cair em declaração de saúde; **não vender diagnóstico** |
| Permissões | Câmera (scanner QR) + internet | Declarar finalidade: “ler carteirinha”. Plugin `mobile_scanner` pede CAMERA mesmo o Manifest principal só listar INTERNET |
| Idade / conteúdo | 18+ no checkout; cadastro | Checkout menciona 18 anos; cadastro “concorda com termos” **não abre documento** |

Google cruza **Data safety + política + comportamento do APK**. Termos de uso o Console não exige do mesmo jeito que a política, mas **LGPD e checkout** exigem aceite real.

---

Rascunhos LGPD/ANPD: [docs/legal/](./legal/README.md) (`politica-de-privacidade.md` e `termos-de-uso.md`). Preencher CNPJ/encarregado e publicar em https.

## 2. Termos e privacidade (o buraco)

### O que o código faz hoje

| Superfície | Comportamento |
|---|---|
| Cadastro | Checkbox obrigatório + Termos e Política no app |
| Pagamento | Link abre os Termos completos |
| Perfil → Privacidade e Dados | Abre os mesmos textos |
| Excluir minha conta | Orienta pedido ao encarregado (exclusão automática ainda não existe) |
| Exportação de dados (LGPD) | Pedido pelo e-mail do encarregado |
| URL pública | Rascunhos em `docs/legal/` — publicar em https e colar no Play Console |

Arquivos: `lib/features/profile/presentation/pages/privacy_data_page.dart`, `lib/features/plans/presentation/widgets/terms_bottom_sheet.dart`, `lib/features/auth/presentation/pages/register_page.dart`.

### O que a Play + LGPD exigem no mínimo

**1. Duas páginas https** (site da empresa ou landing `/privacidade` e `/termos`), abertas no navegador sem instalar o app.

**2. Política de privacidade** em português, com no mínimo:

- Controlador: razão social, CNPJ, e-mail de contato / encarregado
- Dados: nome, e-mail, CPF, telefone, dados de pagamento/assinatura, dependentes (nome/CPF), QR e validações no parceiro
- Finalidade: prestar o clube, cobrar assinatura, aplicar desconto, atender no balcão, prevenir fraude
- Compartilhamento: Supabase (hospedagem), Google (login), gateway de pagamento (Pix/cartão), **parceiro só o necessário na validação** (nome, se a assinatura vale, % do acordo)
- Base legal: execução de contrato + consentimento
- Retenção (incluindo obrigação fiscal de cobrança)
- Direitos: acesso, correção, exclusão, portabilidade
- Como pedir exclusão

**3. Termos de uso:**

- O que o Vitta Clube **é** (clube de desconto / fidelidade)
- O que **não é** (não é plano de saúde, não substitui SUS/convênio)
- Desconto no parceiro é aplicado **no caixa do estabelecimento**; o app autoriza, não integra PDV
- Dependente **não tem conta**; o titular opera o app e é responsável pelo cadastro
- Assinatura recorrente, cancelamento, 18+
- Código da recepcionista / indicação, se for usado na operação

**4. No app:**

- Cadastro: **checkbox obrigatório** + links que abrem as URLs
- Perfil: os mesmos links
- Exclusão que **funciona** (RPC/edge que anonimiza ou apaga o que a lei permite; financeiro pode reter comprovante de pagamento)

Sem o item 1 o Console bloqueia a publicação. Sem 2–4 o revisor ou a ANPD pegam depois.

---

## 3. Data safety (o que declarar)

Declarar **coleta**, **finalidade** (funcionalidade do app + pagamentos) e **compartilhamento** com processadores. Não marcar “não coleta dado pessoal”.

| Dado | Coleta | Notas |
|---|---|---|
| Nome, e-mail | Sim | Cadastro / Google Sign-In |
| CPF, telefone | Sim | Cadastro; CPF de dependente |
| Dados financeiros | Sim | Assinatura, Pix, status de pagamento |
| Identificadores | Sim | IDs Supabase/Google |
| Fotos / câmera | Uso da câmera para **ler QR**, não galeria (a menos que outro fluxo peça) |
| Localização | Não no MVP (não declarar GPS se o APK não pede) |

Criptografia em trânsito: HTTPS (Supabase). “Criptografado em trânsito” = sim. Não afirmar criptografia ponta a ponta.

Pode o usuário solicitar exclusão? Hoje **não** no app — ou implementa ou a resposta no formulário tem que ser “não” (pior para a loja e para a LGPD).

---

## 4. Bloqueios de loja vs. produto

### Bloqueia Play Console / rejeição fácil

- Trocar `applicationId` de `com.example.vita_clube` (ex.: `br.com.vittaclube.app`) e alinhar `google-services.json`
- Assinatura de **upload** (keystore), não debug
- Política + termos **publicados** e linkados
- Data safety preenchido com honestidade
- Conta Play, ficha, closed testing
- Build de prod: `-t lib/main_prod.dart` com URL/key de produção

### Bloqueia o negócio no dia 1 (não é o revisor da Play)

- Migrations de `partners` aplicadas em **produção** (`20260826000050` + `20260826000100`)
- Exclusão de conta real
- Aceite clicável no cadastro
- Câmera: prompt e justificativa no console

### Pode ir depois — não mentir na ficha

- Exportação LGPD completa
- iOS (`NSCameraUsageDescription` ainda falta no `Info.plist`)
- Sorteios, GPS, NFC — **não** colocar na descrição se não está no APK

Checklist de APK em [RELEASE_CLIENTE.md](./RELEASE_CLIENTE.md) (`key.properties`, `QR_SECRET`, flavors). O gradle atual ainda aponta signing debug — o doc de release e o `build.gradle.kts` precisam conversar antes do AAB.

---

## 5. Ordem até a produção (Play)

1. Textos de **Política** e **Termos** (clube de desconto, Pix recorrente, dependente sem conta, validação presencial).
2. Publicar as duas URLs no site.
3. App: checkbox + links no registro; perfil abre as mesmas URLs; exclusão chama backend.
4. Package id + signing de release + Data safety.
5. Closed testing com AAB/APK de **prod** (Supabase prod, tabela `partners` no ar).
6. Produção na Play.

O revisor da Play valida se vocês **avisam** que coletam CPF, cobram assinatura e usam câmera. Termos e privacidade são o primeiro entregável de loja, junto com o `applicationId` verdadeiro.

---

## 6. iOS (quando for a vez)

- `NSCameraUsageDescription` no `Info.plist` (hoje ausente)
- Privacy Nutrition Labels na App Store Connect (espelho do Data safety)
- Sign in with Apple se houver login social (regra da Apple quando existe Google Sign-In)

Não é bloqueio da primeira Play Store.
