import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/config/supabase_config.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/primary_button.dart';
import '../../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../../domain/entities/partner_entity.dart';
import '../../../domain/entities/partner_service_entity.dart';
import '../../widgets/otp_display_widget.dart';
import '../../bloc/partner_checkin/partner_checkin_bloc.dart';
import '../../bloc/partner_checkin/partner_checkin_event.dart';
import '../../bloc/partner_checkin/partner_checkin_state.dart';

class PartnerCheckinPage extends StatelessWidget {
  final PartnerEntity partner;
  final PartnerServiceEntity service;

  const PartnerCheckinPage({
    super.key,
    required this.partner,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PartnerCheckinBloc>(),
      child: _PartnerCheckinView(partner: partner, service: service),
    );
  }
}

class _PartnerCheckinView extends StatefulWidget {
  final PartnerEntity partner;
  final PartnerServiceEntity service;

  const _PartnerCheckinView({
    required this.partner,
    required this.service,
  });

  @override
  State<_PartnerCheckinView> createState() => _PartnerCheckinViewState();
}

class _PartnerCheckinViewState extends State<_PartnerCheckinView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PartnerCheckinBloc, PartnerCheckinState>(
      listener: (context, state) {
        if (state.status == PartnerCheckinStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Erro na validacao'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      builder: (context, state) {
        return AdminPageScaffold(
          title: 'Check-in',
          subtitle: widget.service.name,
          allowedRoles: null,
          body: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PartnerCheckinState state) {
    // Step 3: Validated
    if (state.status == PartnerCheckinStatus.validated) {
      return _buildValidatedState(context);
    }

    // Step 2: Token generated - show OTP + code input
    if (state.status == PartnerCheckinStatus.tokenGenerated &&
        state.tokenValue != null &&
        state.expiresAt != null) {
      return _buildTokenState(context, state);
    }

    // Step 1: Initial - Generate token
    return _buildInitialState(context, state);
  }

  Widget _buildInitialState(BuildContext context, PartnerCheckinState state) {
    return Column(
      children: [
        const SizedBox(height: 32),
        // Service info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBEEF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.partner.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.service.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF6D7F95),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'R\$ ${widget.service.originalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFF9EAAB8),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'R\$ ${widget.service.discountedPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Instructions
        Text(
          'Gere um token para validar seu desconto.\nMostre o token ao atendente e digite\no codigo do parceiro.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF6D7F95),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: state.status == PartnerCheckinStatus.generatingToken
              ? 'Gerando...'
              : 'Gerar Token',
          onPressed: state.status == PartnerCheckinStatus.generatingToken
              ? null
              : () {
                  final userId = SupabaseConfig.client.auth.currentUser?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Faça login para gerar o token.'),
                      ),
                    );
                    return;
                  }
                  context.read<PartnerCheckinBloc>().add(
                        GenerateCheckinToken(userId),
                      );
                },
        ),
      ],
    );
  }

  Widget _buildTokenState(BuildContext context, PartnerCheckinState state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // OTP display
        OtpDisplayWidget(
          token: state.tokenValue!,
          expiresAt: state.expiresAt!,
          onExpired: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Token expirado! Gere um novo.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Partner code input
        Text(
          'Digite o codigo do parceiro',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: LABSAUDE',
              hintStyle: GoogleFonts.outfit(
                fontSize: 16,
                color: const Color(0xFF9EAAB8),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          text: state.status == PartnerCheckinStatus.validating
              ? 'Validando...'
              : 'Validar Desconto',
          onPressed: state.status == PartnerCheckinStatus.validating
              ? null
              : () {
                  final code = _codeController.text.trim();
                  if (code.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite o codigo do parceiro'),
                      ),
                    );
                    return;
                  }
                  final userId = SupabaseConfig.client.auth.currentUser?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Faça login para validar o desconto.'),
                      ),
                    );
                    return;
                  }
                  context.read<PartnerCheckinBloc>().add(
                        SubmitPartnerCode(
                          userId: userId,
                          token: state.tokenValue!,
                          partnerCode: code,
                          serviceId: widget.service.id,
                        ),
                      );
                },
        ),
      ],
    );
  }

  Widget _buildValidatedState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'DESCONTO VALIDADO',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Seu desconto foi registrado com sucesso!\nApresente esta tela ao atendente.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF6D7F95),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        // Discount summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Text(
                widget.service.name,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Economia: R\$ ${(widget.service.originalPrice - widget.service.discountedPrice).toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          text: 'Voltar',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
