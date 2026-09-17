# Plano de implementação — MVP de fidelidade (dependentes + parceiros + validação no balcão)

**Status:** congelado para execução em goal de código posterior.  
**Este documento é a fonte da verdade do MVP de clube.** Não cobre PIX automático, reset de senha, sorteios nem landing page.  
**Papéis:** `user` (usuário/titular), dependente (sem conta), `parceiro`, `admin` (recepção), `financeiro` (superadmin).

---

## 1. Produto em uma frase

O cliente mostra a carteirinha → quem está no balcão (Vitta **ou** parceiro) lê no **próprio aparelho** → vê **quem é, se pode, qual % aplicar, quanto economiza em R$** (se houver valor) → confirma. O caixa do parceiro continua cobrando no PDV dele; o app só autoriza e registra.

O dependente **não tem login nem conta**. O titular opera o app e a carteirinha.

---

## 2. Regras comerciais (obrigatórias)

Estas regras são o resultado combinado. Implementação que as contradiga está fora do MVP.

1. **Um percentual de acordo por parceiro.** Campo vivo `partners.discount_percentage`. É o desconto que aquele estabelecimento oferece a membro Vita.
2. **Quem publica e edita o % vivo é só o financeiro (superadmin).** Combinado comercial (WhatsApp/visita) vira número no cadastro. Candidatura “Seja parceiro” pode *propor* um %, mas isso não vai ao ar até o financeiro gravar o acordo.
3. **O parceiro não auto-publica nem altera o % vivo.** No app dele não há campo editável de desconto do acordo. Ele honra o número e valida a carteirinha.
4. **Na clínica / recepção Vitta aplica-se o % do badge** (Bronze 10% … Diamante 30%, via `DiscountService` / badge do titular).
5. **No balcão do parceiro aplica-se o % do acordo daquele parceiro**, não o % do badge.
6. **Os dois percentuais não são somados (not stacked).** Não existe “Ouro 20% + lab 15% = 35%” neste MVP.
7. **Validador e membro vêem economia em R$** quando existe valor do ticket/pedido: original, %, economiza R$ X, a pagar R$ Y.
8. **Validação do parceiro acontece na tela do parceiro** (câmera no QR da carteirinha **ou** código curto do membro digitado). Caminho primário **não** é o usuário gerar OTP e digitar `LABSAUDE` / código do balcão.
9. **Dependente só é usável depois de `active`.** Cadastro nasce `pending`. Admin (recepção) aprova presencialmente na primeira visita, com documento. Financeiro pode aprovar também (já é permitido no use case), mas a operação do dia é do admin.
10. **Assinatura do titular em dia** é pré-requisito para QR de titular e de dependente. Inadimplente / sem assinatura → recusa clara nos dois validadores.

---

## 3. Quem faz o quê (atribuições)

| Papel | Login | Faz | Não faz |
|---|---|---|---|
| **Usuário / titular** | `user` | Paga, cadastra dependente, opera a carteirinha (escolhe titular ou dependente ativo), mostra QR/código no balcão, vê catálogo de parceiros com o % do acordo, vê histórico com economia em R$ | Não valida desconto sozinho; não é a tela de “ok” do caixa |
| **Dependente** | **sem conta / sem login** | Aparece no balcão com documento; o titular mostra a carteirinha no nome dele | Não instala o app, não tem senha |
| **Parceiro** | `parceiro` | Valida no **próprio** aparelho (scan ou código), vê identidade + % do acordo + economia se informar valor, confirma, consulta histórico do dia | Não muda o % vivo; CRUD de serviços de preço **não** é a porta da validação |
| **Admin (recepção)** | `admin` | Aprova/rejeita dependente `pending` **presencialmente**; scanner na Vitta (QR ou código do membro); informa valor da consulta; sistema aplica **% do badge** e registra consulta | Não publica o % de acordo do parceiro |
| **Financeiro (superadmin)** | `financeiro` | Publica e edita o **% vivo** do parceiro; cadastra/ativa/inativa parceiro; herda scanner e fila de dependentes se precisar; vê economia agregada | Não é o operador do balcão no dia a dia |

Hierarquia já documentada em `docs/PAPEIS_E_PERMISSOES.md` e `docs/feature/super_admin.md`: Financeiro > Admin > Usuario. Role `parceiro` é um quarto perfil operacional, só o estabelecimento.

---

## 4. Fluxo alvo por papel

### 4.1 Usuário (titular)

```
Assinatura em dia
  → Perfil: cadastra dependente (nome, CPF, nascimento, parentesco) → status Pendente
  → Texto: "Leve [Nome] na recepção Vitta com documento na primeira visita"
  → Depois de ativo: Carteirinha → seletor Titular | João (filho)
  → Mostrar QR (payload da pessoa selecionada) + código curto
  → % visível no contexto certo:
       na Vitta / home de benefícios do clube: % do badge
       no card do parceiro no catálogo: % do acordo daquele lab
  → No lab: mostra a tela; o caixa lê no aparelho do parceiro
  → Histórico: "Lab Saúde · você economizou R$ 37,50" (não só −R$ valor final)
```

### 4.2 Dependente (sem conta)

```
Não loga.
Titular cadastra → pending.
Admin confirma vínculo no balcão Vitta → active.
No parceiro ou na recepção, o titular escolhe o dependente na carteirinha.
Validador mostra: "Maria Silva · filha de João · CPF ***.***.***-12".
Se ainda pending / inactive: recusa "Dependente não liberado".
```

### 4.3 Parceiro (tela de validar)

Home do login `parceiro` = **Validar desconto**, não o grid de serviços.

```
Abre Validar
  → câmera no QR da carteirinha
  → fallback: "Digitar código do membro"
  → backend identifica titular ou dependente, checa assinatura e status
  → Resultado NO APARELHO DO PARCEIRO:
       Maria Silva · dependente de João
       Assinatura em dia
       Aplique 15%   ← % do acordo (financeiro), nunca o badge
       [opcional] Valor do pedido R$ 250
         Original R$ 250 | Desconto 15% | Cliente economiza R$ 37,50 | A pagar R$ 212,50
       [Confirmar] → grava partner_validations
  → Recusas: QR inválido, inadimplente, dependente pendente, já usado se houver regra de replay
  → Hoje: lista nome + economia R$ + horário
```

Serviços com preço cheio/Vita continuam no catálogo (marketing). Não são a unidade da validação no MVP: o caixa aplica o % no total do pedido.

### 4.4 Admin (recepção Vitta)

```
Fila Dependentes: aprova/rejeita pending (já existe AdminDependentsListPage).
Scanner QR (já existe AdminQrScannerPage):
  → lê carteirinha (UUID / código curto) OU QR de agendamento legado
  → identidade + % do badge (não o % de lab)
  → se aprovado: informa valor da consulta
  → preview: original | desconto X% | cliente economiza R$ Y | final R$ Z
  → Confirmar → consultations (original_value, discount_percentage, discount_amount, final_value)
Copy da recepção: "Cliente economiza", não "Você economiza".
```

### 4.5 Financeiro (superadmin)

```
Dashboard financeiro (não o catálogo do usuário):
  → Parceiros: CRUD estabelecimento
       nome, categoria, ativo, discount_percentage (obrigatório, 1–100)
  → Publicar % = o número que catálogo + validador do parceiro passam a mostrar
  → Editar % = imediato no app (MVP; fila de "solicitar mudança" é later)
  → Aprovar candidatura "Seja parceiro": só vira partner ativo depois de
       criar conta role=parceiro + gravar o % do acordo
  → Acesso operacional (herdado): scanner e fila de dependentes se precisar
  → Relatório simples: validações de parceiro no mês + soma de economia R$
```

Hoje o card “Parceiros” do `FinanceiroDashboardPage` abre `PartnersListPage` (vitrine do membro). Isso é gap: o superadmin precisa de **gestão do acordo**, não da lista pública.

---

## 5. Current vs target

| Ponto | Current (código hoje) | Target (este MVP) |
|---|---|---|
| Quem valida no parceiro | Usuário gera token e **digita código do balcão** (`LABSAUDE`); tela verde no celular do cliente | Parceiro lê QR/código **na tela dele** |
| Tela Validar do parceiro | Não existe. Dashboard = serviços + histórico + “meu código” | Home = Validar desconto + histórico do dia |
| RPC `validate_member_qr` | Recusa se `role <> 'admin'` | Aceita `admin`, `financeiro` e `parceiro` (parceiro grava validação de estabelecimento, não consulta de clínica) |
| `partners.discount_percentage` | **Não existe coluna** | Um % por parceiro, só financeiro escreve |
| Qual % no lab | Check-in usa preço do **serviço** (original vs discounted); badge não entra | % do acordo do parceiro |
| Qual % na Vitta | Scanner + `ConsultationValueSheet` usam % do badge; economia em R$ já calcula | Manter; copy “cliente economiza”; histórico do titular também mostra economia |
| Carteirinha | Só titular; QR = `profile.id`; sem seletor de dependente; sem % | Seletor titular/dependente ativo; QR da pessoa; instrução de mostrar no caixa |
| Dependente | Cadastro + fila admin + QR de **agendamento** (`validate_dependent_qr`) | Continua aprovação presencial; uso no clube = carteirinha da pessoa, não obrigar agendar para ter QR |
| Catálogo parceiro | Preços por serviço e `-%` calculado; CTA gera token | Mostra o % do acordo no card; CTA “Mostre a carteirinha no caixa”; esconder token+código como porta da frente |
| Financeiro × parceiros | Abre a lista pública | CRUD + % vivo |
| Histórico carteirinha | `−R$ finalValue` (parece cobrança) | Economia em R$ (consulta e validação de parceiro) |
| Empilhamento | Implícito/confuso (badge vs preço de serviço) | **Not stacked** — clínica = badge; parceiro = acordo |

### Gaps atuais a fechar no goal de código (não neste documento)

- RPC `validate_member_qr` ainda é admin-only (`supabase/migrations/20260605000200_validate_member_qr_rpc.sql`).
- Tabela `partners` não tem coluna `discount_percentage`.
- Carteirinha não tem switch de dependente (`CardPage` / `QrCodeSheet`).
- Não há tela de Validar no perfil `parceiro`.
- `BeneficiarySelector` só entra em `ConsultationSchedulePage` (agendamento), não na carteirinha.
- Financeiro não tem formulário de % do acordo.

---

## 6. MVP vs later

### Entra no MVP

- Dependente: cadastro → pending → aprovação presencial admin → ativo na carteirinha do titular.
- Validador admin (Vitta): scan/código, % badge, valor, economia R$, grava consulta.
- Validador parceiro: scan/código no aparelho do parceiro, % acordo, valor opcional, economia R$, grava `partner_validations`.
- Financeiro publica/edita o % vivo.
- Catálogo do usuário com o mesmo % que o validador.
- Esconder da navegação do usuário o check-in token + código do balcão como caminho principal (pode deixar código morto; não é a porta).
- Copy alinhada nos três lados.

### Fora do MVP (later)

- GPS, NFC, QR rotativo no tablet do lab, confirmação WhatsApp.
- Token + `LABSAUDE` / OTP de dois fatores como caminho primário.
- Parceiro auto-servir mudança do % vivo (solicitar 15%→20% com fila) — sem financeiro não publica.
- Fila de aprovação admin **por exame/preço** de `partner_services`.
- Somar badge + acordo.
- Dependente com conta própria.
- Integração com PDV/laboratório (o desconto no caixa deles continua manual).
- Agendamento de consulta do dependente como requisito para usar parceiro.

Serviços com preço (hemograma R$ 80 → R$ 68) podem permanecer como vitrine; não bloqueiam e não passam por aprovação por item.

---

## 7. Telas e dados (contrato para o goal de código)

### 7.1 Schema

- `partners.discount_percentage NUMERIC(5,2) NOT NULL` com check 0–100 (produção: > 0 para ativo).
- RLS: `SELECT` do % para usuário autenticado em parceiro `is_active`; `UPDATE` do % só `is_financeiro()`.
- Candidatura: campo opcional `proposed_discount_percentage` (não é o vivo).
- `partner_validations`: além do que já existe, persistir `discount_percentage`, `original_value` (nullable), `savings_amount` (economia R$), `beneficiary_type`, `dependent_id` nullable, `member_name`.
- QR de dependente na carteirinha: ou payload assinado distinguível do UUID do titular, ou o validador aceita código curto do titular + escolha já feita no QR (preferência: payload da carteirinha identifica o beneficiário para o scanner não perguntar “quem é”).

### 7.2 RPCs / autorização

- `validate_member_qr` (e validação por código curto): ator `admin` \| `financeiro` \| `parceiro`.
- Se ator é `parceiro`, não abre `ConsultationValueSheet`; abre confirmação de acordo + insert em `partner_validations`.
- Se ator é `admin`/`financeiro` na Vitta: fluxo atual de consulta + % badge.
- Recusar parceiro validando consulta de clínica e admin gravando `partner_validations` no lab (contexto pelo role + partner_id do profile).

### 7.3 App

| Tela | Dono | Mudança |
|---|---|---|
| `CardPage` + `QrCodeSheet` | titular | Seletor de beneficiário; copy de balcão |
| `DependentsPage` | titular | Já existe; reforçar texto pending → recepção Vitta |
| `PartnersListPage` / detalhe | titular | % do acordo no card; sem CTA de token como primário |
| Nova `ParceiroValidatePage` | parceiro | Câmera + código + resultado + economia R$ |
| `ParceiroDashboardPage` | parceiro | Validar como ação principal; serviços viram secundário; remover “informar código ao cliente” como operação |
| `AdminQrScannerPage` + `ConsultationValueSheet` | admin / financeiro | Manter; copy cliente economiza |
| `AdminDependentsListPage` | admin / financeiro | Manter |
| Nova gestão de parceiros | **financeiro** | CRUD + % vivo; não reusar `PartnersListPage` |
| `FinanceiroDashboardPage` | financeiro | Card Parceiros aponta para gestão, não vitrine |

---

## 8. Ordem de implementação (goal de código seguinte)

1. Schema: `discount_percentage` + RLS financeiro + campos de economia em `partner_validations`.
2. RPC: ator `parceiro`/`financeiro` em `validate_member_qr` / código curto; ramificar persistência (consulta vs partner_validation).
3. Tela Validar do parceiro (scan + código + resultado com % acordo e economia R$).
4. Carteirinha: seletor titular/dependente ativo + QR da pessoa.
5. Catálogo do usuário e gestão financeiro do % (mesmo número nos três lados).
6. Histórico do titular com economia R$; copy admin “cliente economiza”.
7. Esconder token + código do balcão da porta da frente.

Verificação humana depois do código: um titular com dependente ativo, um admin na recepção, um parceiro no caixa, um financeiro mudando 15%→20% e vendo catálogo + validador atualizarem juntos.

---

## 9. Relação com docs antigos

| Doc | Uso daqui pra frente |
|---|---|
| `docs/feature/dependentes.md` | Regras de pending/cota/CPF **na clínica** continuam. Uso em parceiro passa a ser carteirinha, não só QR de agendamento. |
| `docs/feature_parceiro_plan.md` | Histórico. Token + código de dois fatores **não** é o MVP. |
| `docs/PARCEIROS_VALIDACAO.md` | Catálogo de opções. MVP = opção “usuário mostra QR, atendente valida no aparelho dele” (scan ou código), equivalente à recepção. |
| `docs/sdd-qr-validation-flow.md` | Fluxo **clínica** (badge + valor da consulta). Complementar, não substitui este plano. |
| `docs/PAPEIS_E_PERMISSOES.md` / `docs/feature/super_admin.md` | Financeiro = superadmin; passa a ser o dono do % de acordo do parceiro. |

---

## 10. Fora deste plano

Implementar UI do validador, migration do %, RPC e switch da carteirinha **não** é entrega deste documento. GPS/NFC/QR rotativo, empilhar percentuais, auto-serviço de % pelo parceiro e fila de preço por exame estão explicitamente fora.
