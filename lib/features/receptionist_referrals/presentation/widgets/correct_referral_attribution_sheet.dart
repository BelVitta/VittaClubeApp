import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../admin/presentation/widgets/admin_dropdown_field.dart';
import '../../domain/entities/receptionist_referral_entity.dart';
import '../bloc/receptionist_referrals_admin_bloc.dart';
import '../bloc/receptionist_referrals_admin_event.dart';

/// Correção manual de atribuição (financeiro). O servidor (RPC
/// correct_receptionist_referral) é quem de fato garante que só financeiro
/// pode executar e que ninguém atribui a indicação a si mesmo - esta tela é
/// só a UI, a regra de negócio vive no banco.
class CorrectReferralAttributionSheet extends StatefulWidget {
  final ReceptionistReferralEntity referral;
  final ReceptionistReferralsAdminBloc bloc;

  const CorrectReferralAttributionSheet({
    super.key,
    required this.referral,
    required this.bloc,
  });

  @override
  State<CorrectReferralAttributionSheet> createState() =>
      _CorrectReferralAttributionSheetState();
}

class _CorrectReferralAttributionSheetState
    extends State<CorrectReferralAttributionSheet> {
  final _reasonController = TextEditingController();
  String? _selectedReceptionistId;
  List<Map<String, dynamic>> _receptionists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReceptionists();
  }

  Future<void> _loadReceptionists() async {
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('id, name')
          .eq('role', 'admin')
          .order('name');
      setState(() {
        _receptionists = (data as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Corrigir atribuição',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Indicado: ${widget.referral.referredUserName}',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: const Color(0xFF6D7F95)),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor))
            else
              AdminDropdownField(
                label: 'Nova recepcionista',
                value: _selectedReceptionistId,
                items: _receptionists
                    .map((r) => DropdownItem(
                          id: r['id'] as String,
                          displayName: r['name'] as String,
                        ))
                    .toList(),
                onChanged: (item) =>
                    setState(() => _selectedReceptionistId = item?.id),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: AppTheme.inputDecoration(label: 'Motivo da correção'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _selectedReceptionistId == null ||
                        _reasonController.text.trim().isEmpty
                    ? null
                    : () {
                        widget.bloc.add(CorrectReferralAttributionRequested(
                          referralId: widget.referral.id,
                          newReceptionistId: _selectedReceptionistId!,
                          reason: _reasonController.text.trim(),
                        ));
                        Navigator.of(context).pop();
                      },
                child: Text(
                  'Confirmar correção',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
