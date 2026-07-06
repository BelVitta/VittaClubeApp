# Data Model: Aplicativo de Cartao Fidelidade em Saude

## UserProfile

Representa pessoa autenticada ou cadastrada.

**Fields**: id, name, email, phone, cpfMasked, role, status, createdAt,
updatedAt, consentStatus.

**Roles**: user, admin, financeiro/super_admin, parceiro.

**Validation**:

- email em formato valido;
- CPF e telefone mascarados para admin;
- role alteravel apenas por super admin;
- consentimento exigido para uso completo.

**Relationships**: possui Subscription, LoyaltyLevel, Consultations, Payments,
BenefitUsages, Notifications, Referrals.

## CommercialHomeContent

Conteudo da home publica/comercial.

**Fields**: hero, steps, benefits, planHighlights, levelHighlights,
professionalHighlights, partnerHighlights, drawHighlights, trustProofs, faqs,
contactInfo, seoMetadata, updatedAt.

**Validation**:

- nenhum campo visivel pode conter placeholder;
- CTA primario obrigatorio;
- contato oficial obrigatorio;
- SEO local obrigatorio quando indexavel.

## Plan

Oferta comercial de assinatura.

**Fields**: id, name, type, price, billingCycle, benefits, isActive, isFeatured,
transparencyNotes.

**Types**: monthly, semiannual, annual.

**Validation**:

- preco positivo;
- beneficios especificos;
- plano ativo precisa ter CTA e regras de cancelamento/carencia.

## Subscription

Assinatura de um cliente.

**Fields**: id, userId, planId, status, startedAt, renewsAt, cancelledAt,
gracePeriodEndsAt, paymentStatus.

**States**: pending, active, gracePeriod, overdue, cancelled.

**Transitions**:

- pending -> active apos confirmacao de pagamento;
- active -> overdue quando pagamento vence;
- overdue -> active apos regularizacao;
- active/overdue -> cancelled por cancelamento.

## LoyaltyLevel

Nivel de fidelidade do cliente.

**Fields**: level, discountPercent, monthlyConsultationLimit, requirements,
benefits, sortOrder.

**Levels**: bronze, prata, ouro, diamante.

**Validation**:

- desconto entre 0 e 100;
- limite mensal nao negativo;
- requisitos claros e exibiveis ao cliente.

## Specialty

Categoria de atendimento.

**Fields**: id, name, icon, isActive, sortOrder.

**Validation**:

- nome unico entre especialidades ativas;
- exclusao bloqueada quando houver profissionais vinculados.

## Professional

Especialista da rede.

**Fields**: id, name, specialtyIds, registry, photoUrl, bio, availableDays,
contactChannels, status.

**Validation**:

- nome e pelo menos uma especialidade obrigatorios;
- registro profissional exibido quando aplicavel;
- admin pode inativar, super admin pode excluir conforme regra.

## Consultation

Atendimento do cliente.

**Fields**: id, userId, professionalId, specialtyId, scheduledAt, status,
cancelReason, notes, createdBy, updatedAt.

**States**: requested, pending, confirmed, rescheduled, cancelled, completed,
noShow.

**Transitions**:

- requested/pending -> confirmed por admin;
- confirmed -> rescheduled com nova data;
- pending/confirmed -> cancelled com motivo;
- confirmed -> completed apos atendimento/validacao.

## Partner

Laboratorio, clinica, farmacia, otica ou parceiro.

**Fields**: id, profileId, name, category, code, address, phoneMasked, logoUrl,
isActive.

**Validation**:

- codigo unico;
- parceiro ativo possui ao menos um servico ou mensagem de indisponibilidade;
- dados sensiveis protegidos por role.

## PartnerService

Servico/exame/produto com desconto.

**Fields**: id, partnerId, name, description, originalPrice, discountedPrice,
discountPercent, isActive.

**Validation**:

- desconto coerente com precos;
- valores ausentes devem acionar contato, nao placeholder.

## PartnerValidation

Registro de uso de desconto em parceiro.

**Fields**: id, partnerId, userId, serviceId, userLevel, discountApplied,
validatedAt, validationMethod, status.

**States**: tokenGenerated, validated, expired, rejected.

## DigitalCard

Carteirinha do membro.

**Fields**: userId, displayName, membershipCode, level, subscriptionStatus,
qrPayload, generatedAt.

**Validation**:

- QR nao deve expor dados sensiveis;
- status deve mostrar aptidao de uso.

## Payment

Registro financeiro.

**Fields**: id, userId, subscriptionId, status, amount, method, dueAt, paidAt,
externalReference.

**States**: pending, paid, failed, overdue, refunded, cancelled.

**Security**:

- admin ve apenas status operacional;
- valores e relatorios apenas para super admin/financeiro.

## Draw

Sorteio promocional.

**Fields**: id, title, prize, rules, eligibleLevels, drawDate, status,
participantCount, winnerId, resultPublishedAt.

**States**: draft, scheduled, open, closed, executed, cancelled.

**Validation**:

- execucao apenas por super admin/financeiro;
- resultado precisa de registro auditavel.

## Coupon

Cupom promocional.

**Fields**: id, code, type, value, validFrom, validUntil, usageLimit,
eligibilityRules, status.

**Validation**:

- criacao/edicao apenas por super admin;
- aplicacao por admin somente para cupons ativos e elegiveis.

## Notification

Aviso para usuario ou operador.

**Fields**: id, recipientId, type, title, body, readAt, createdAt, actionUrl.

**Types**: payment, subscription, consultation, levelUpgrade, draw, benefit,
system.

## AuditLog

Registro de acoes sensiveis.

**Fields**: id, actorId, actorRole, action, entityType, entityId, metadata,
createdAt.

**Required for**: role changes, payment actions, coupon application, draw
execution, consultation cancellation/reschedule, partner validation changes,
plan price changes.
