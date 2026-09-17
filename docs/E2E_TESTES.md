# Roteiro E2E — Vitta Clube (esta versão)

Testar no **mesmo ambiente** (staging ou prod com migrations aplicadas, inclusive `partners`). Preferir **celular físico** por causa da câmera. Quatro contas reais: membro, admin (recepção), financeiro, parceiro.

Sorteios: o CRUD existe e **vai ser de verdade** nesta versão — incluir no roteiro quando o fluxo de sortear estiver ligado; até lá, só conferir que a tela abre sem dado fake de KPI.

Motivos de cancelamento: **só o financeiro** cadastra. A recepção não vê o card.

---

## Contas e pré-requisitos

| Papel | `profiles.role` | Para que serve o teste |
|---|---|---|
| Membro | `user` | Cadastro, plano, carteirinha, dependente, catálogo |
| Recepção | `admin` | Código de indicação, fila de dependente, scanner, ranking |
| Financeiro | `financeiro` | % do parceiro, planos, motivos, métricas **do banco** |
| Parceiro | `parceiro` + linha em `partners` | Validar QR no aparelho do estabelecimento |

Antes de começar:

- [ ] `supabase db push` (ou script de staging/prod) com `20260826000050`, `20260826000100`, `20260827000100`
- [ ] Financeiro publicou um % de acordo no lab de teste (ex.: 15%)
- [ ] Recepcionista tem `receptionist_code` (gerado ao virar `admin`)

---

## 1. Membro (`user`)

1. Instalar o app de **staging/prod**, não `main_dev` (dev é mock).
2. Criar conta e-mail/senha. Campo **Código de quem te indicou**: usar o código da recepção.
3. Aceite de termos: hoje ainda pode estar fraco (`TODO`) — anotar se o link abre documento de verdade.
4. Completar CPF/telefone se o app pedir.
5. Home abre (não painel admin).
6. Assinar plano até `subscriptions.status = active` (Pix ou cartão do ambiente).
7. Carteirinha: nome real, **Mostrar QR**, código de 8 dígitos.
8. Perfil → Dependentes: cadastrar um (nome, CPF, nascimento, parentesco) → status **Pendente**.
9. Parceiros: o lab de teste mostra **o mesmo %** que o financeiro publicou. CTA não é token/`LABSAUDE`.
10. Google Sign-In (se testar): **não** pede código da recepção — indicação não deve ser atribuída.

**Falha típica:** cadastro com código errado ainda cria conta, mas ranking não conta.

---

## 2. Recepção (`admin`)

1. Login → painel operacional (não Home de membro).
2. **Código de indicação:** hoje só aparece se o financeiro abrir o usuário admin e copiar. No balcão, anotar se a recepcionista consegue ver o código sem essa ajuda (gap conhecido).
3. Dependentes: aprovar o cadastro pendente **com a pessoa e o documento na frente**. Recusar outro com motivo.
4. Scanner: ler QR do **titular** → % da **patente** (badge), não do lab. Informar valor da consulta → “Cliente economiza R$ …”.
5. No app do titular, escolher o dependente **já ativo** na carteirinha e escanear de novo → nome do dependente na tela da recepção.
6. Dependente ainda pendente: validação deve recusar.
7. Titular inadimplente: recusar QR.
8. Ranking Indicações: mês atual. Indicação no mês do cadastro; conversão só na **primeira** `active`. Renovar não soma de novo.
9. Quem indicou: lista pending/converted. **Não** deve editar atribuição (só financeiro).
10. Confirmar que **não** há card Motivos de cancelamento neste painel.
11. Sorteios: abrir a lista (CRUD). Quando o sorteio real estiver ligado, completar: criar → inscrever elegíveis → sortear → ver ganhador.

---

## 3. Parceiro (`parceiro`)

1. Login → Painel Parceiro (não Home, não admin).
2. Card “Como funciona” visível.
3. **Validar desconto**: câmera no QR da carteirinha **no aparelho do parceiro**.
4. Resultado: nome (titular ou dependente), assinatura ok, **% do acordo** (15%, não o ouro do membro).
5. Opcional: valor do pedido → original, %, economia R$, a pagar.
6. Confirmar → entra no histórico do dia.
7. Fallback: “Digitar código do membro” (8 dígitos).
8. Recusas: QR inválido, inadimplente, dependente pendente.
9. Serviços: catálogo de preços (vitrine); **não** é a porta da validação.
10. Parceiro **não** edita o % do acordo.

---

## 4. Financeiro (`financeiro`)

1. Login → dashboard financeiro.
2. Métricas do mês: receita (pagamentos `aprovado` no mês), membros ativos, inadimplentes, cancelamentos — **números do banco**, não 12.450 / 247. Se não houver dado, pode ser zero, nunca vitrine.
3. Parceiros: editar lab, publicar 15% → no app do membro e no validador do parceiro aparece 15%. Mudar para 20% e repetir.
4. Planos / badges: alterar preço ou % de patente **não** muda o % do lab.
5. Motivos Canc.: criar/editar/excluir. Recepção não tem esse card.
6. Equipe: promover alguém a `admin` gera `receptionist_code`. Copiar o código.
7. Quem indicou (via painel operacional): corrigir atribuição com motivo; não atribuir a si mesmo.
8. Faturamento: lista de pagamentos reais.
9. Atalho Painel Administrativo: abre operação da recepção (herança). Ranking de indicações **não** é para financeiro (RPC recusa `role != admin`).

---

## 5. Cruzamentos (quebram na rua)

| Caso | Esperado |
|---|---|
| Dois scans do mesmo QR em seguida | Sem débito duplo indevido; recusa ou replay claro |
| Titular escolhe dependente pendente na carteirinha | Parceiro/admin recusam |
| Lab 15% + membro Ouro 20% | No lab vale **15%**. Na Vitta vale **20%**. Não somar |
| Código de recepção inválido no signup | Conta cria; ranking não credita |
| Segunda assinatura da mesma pessoa | Sem nova conversão de recepção |
| Métricas financeiro com mês sem pagamento | Receita R$ 0,00 — não número inventado |

---

## 6. Loja / legal (não é fluxo de clube, mas barra publicação)

1. Cadastro abre **política e termos** em URL https (hoje TODO).
2. Excluir conta **apaga ou anonimiza** de verdade (hoje o botão não faz).
3. AAB com `applicationId` que **não** é `com.example.vita_clube`.
4. Assinatura de upload, não debug.
5. Data safety declara CPF, pagamento, câmera.

Ver [PLAY_STORE_E_PRIVACIDADE.md](./PLAY_STORE_E_PRIVACIDADE.md).

---

## 7. iPhone no E2E

APK da Play **não instala no iPhone**. Opções:

- **TestFlight** (caminho do cliente): build iOS no Mac → App Store Connect → convite. Ver secção abaixo.
- Cabo + Mac na mesa de vocês (`flutter run -t lib/main_staging.dart`).

Sem TestFlight, o cliente iOS não participa deste roteiro no aparelho dele.

---

## 8. TestFlight é pago?

**O TestFlight em si não cobra por app nem por testador** (limite alto de externos, internos até 100).

O que é pago:

- **Apple Developer Program**: cerca de **US$ 99 / ano** por conta (pessoa ou empresa). Sem isso não sobe build para TestFlight nem para a App Store.
- Mac (ou CI com Mac) para gerar o `.ipa`.
- Conta Play é **outra** (taxa única da Google), não substitui a Apple.

Resumo: Android testa com APK/internal testing da Play. iPhone do cliente = Developer Apple + TestFlight. Não existe atalho de “manda o APK no WhatsApp” para iOS.
