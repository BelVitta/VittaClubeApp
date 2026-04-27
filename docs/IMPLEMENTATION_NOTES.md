# Notas de implementação

> Registro curto do que foi construído, decisões-chave e onde mexer depois.
> Atualizado a cada nova implementação.

---

## WhatsApp — fluxo global com override por profissional

**Decisão**: número padrão da clínica Vita como fallback; profissionais de outras
clínicas podem ter número próprio no DB (`professionals.whatsapp_encrypted`).

**Fluxo**:
1. Usuário clica "Agendar via WhatsApp" em um `ProfessionalCard`.
2. App lê `professionals.whatsapp_encrypted` desse profissional no Supabase.
3. Tem número? Usa ele. Não tem? Usa `ClinicContacts.defaultWhatsappNumber`.
4. `WhatsAppLauncher.open()` abre `https://wa.me/{numero}?text={msg}` via `url_launcher`.

**Arquivos (a criar)**:
- `lib/core/config/clinic_contacts.dart` — constante com o número global.
- `lib/core/services/whatsapp_launcher.dart` — helper que decide número e abre o app.

**Pendente**:
- [ ] Confirmar se `url_launcher` está no `pubspec.yaml`.
- [ ] Número da clínica será configurado via tela de administrador (não hardcoded).

### Tela de Médicos — design Figma aplicado

**Fonte**: Figma node `74:3163` ("Lista de Medicos") de `nNc2umOfTeoX0itneDki1b`.

**Mudanças em `lib/features/professionals/presentation/pages/professionals_page.dart`**:
- Título trocado de "Profissionais" → **"Médicos"** (24px regular, #031535, alinhado à esquerda).
- Removido back button (página é acessada via bottom nav).
- Bell de notificação continua à direita (estilo circular azul translúcido).
- Filtro refeito: era campo grande redondo; agora é **chip pequeno** "Filtrar" (radius 10, border #EBEEF2, 12px text) com ícone `Icons.tune`. Mesmo comportamento (abre `SpecialtyFilterSheet`).
- Removido o helper local `_circleIconButton` que não é mais usado.
- Cards mantidos: `ProfessionalCard(isLarge: true)` já bate 1:1 com o `cardMedicoGrande` do Figma (bg #FFF, border #EBEEF2, radius 16, padding 16, avatar 90px #FFCD66, botão WhatsApp verde claro `rgba(163,255,172,0.15)` com texto `#34933e`).

**Pendente / diferenças anotadas**:
- Design Figma tem **5 ícones na bottom nav** (home, medic, card, **trophy/sorteios**, person); app atual tem só 4 SVGs. Adicionar trophy depois (precisa do SVG + registrar em `kAppBottomNavIcons` + ajustar todas as páginas que usam a bottom nav).
- Design mostra 1 card compacto (`cardMedico`, 44px avatar) ao final da lista — provavelmente só amostra do designer. Estou usando só o `cardMedicoGrande` para a lista toda.

---

### Admin — `clinic_settings` (implementado)

**Migration** `supabase/migrations/20260424_clinic_settings.sql`:
- Tabela `clinic_settings(key, value, updated_at)` + trigger `updated_at`.
- RLS: qualquer `authenticated` lê; `is_admin()` escreve/deleta.
- Seed `('default_whatsapp', '5585999000000')` (placeholder; admin substitui).

**App**:
- `lib/core/services/clinic_settings_service.dart` — cache em memória, `get/set/invalidate`.
- `lib/core/services/whatsapp_launcher.dart` — recebe número opcional,
  fallback no service, abre `wa.me/{num}?text={msg}` via `url_launcher`.
- `lib/features/admin/presentation/pages/clinic_settings/admin_clinic_settings_page.dart` —
  form simples com 1 input (WhatsApp) + Salvar.
- Dashboard admin ganhou card "Clínica" (ícone `settings_outlined`).
- `professionals_page.dart` conecta `onWhatsApp` do `ProfessionalCard` ao
  launcher com mensagem pré-preenchida (`Olá! Gostaria de agendar…`). Mostra
  SnackBar quando o número não está configurado ou o launch falha.
- `pubspec.yaml`: `url_launcher: ^6.3.1`.
- DI: `ClinicSettingsService` como lazy singleton.

**Rodar no Supabase** (SQL Editor):
- `supabase/migrations/20260424_clinic_settings.sql`.

**TODO**:
- Quando a lista de `professionals` deixar de ser mock, passar o número real
  (descriptografado de `whatsapp_encrypted`) em `ProfessionalCard.onWhatsApp`.

---

### Feature `consultation` — implementada (histórico de consultas)

Substitui a lista mockada em `home_page.dart`. Clean Arch completa em
`lib/features/consultation/`:

- `domain/entities/consultation_entity.dart` — `{id, title, subtitle,
  scheduledDate, status, professionalId, professionalName, specialtyName}`.
  **Sem `IconData`** (ícone fica na UI).
- `data/models/consultation_model.dart` — `fromJson` com join aninhado
  `professionals(specialties(name))`.
- `data/datasources/consultation_supabase_datasource.dart` —
  `select` em `consultations` filtrando por `user_id` do usuário logado,
  ordenado por `scheduled_date` desc, limit 20.
- `presentation/bloc/consultation_bloc.dart` — estados `Loading / Loaded /
  Error`.
- `home_page.dart` — `ConsultationBloc` no `MultiBlocProvider`,
  `_buildConsultationHistory()` agora renderiza `SkeletonBox` enquanto
  carrega, `EmptyConsultationState` se vazio, lista real em `Loaded`.
  Subtitle combina `specialtyName + subtitle` (fallback: `professionalName`).
- `lib/features/home/domain/entities/consultation_entity.dart` **deletado**
  (legado, não referenciado em mais nenhum lugar).

---
