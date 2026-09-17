import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../admin/presentation/widgets/admin_page_scaffold.dart';
import '../../domain/entities/partner_entity.dart';
import '../../domain/usecases/partner/update_partner_usecase.dart';

class FinanceiroPartnerFormPage extends StatefulWidget {
  final PartnerEntity partner;

  const FinanceiroPartnerFormPage({super.key, required this.partner});

  @override
  State<FinanceiroPartnerFormPage> createState() =>
      _FinanceiroPartnerFormPageState();
}

class _FinanceiroPartnerFormPageState extends State<FinanceiroPartnerFormPage> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _percent;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.partner.name);
    _address = TextEditingController(text: widget.partner.address);
    _percent = TextEditingController(
      text: widget.partner.discountPercentage.toStringAsFixed(0),
    );
    _isActive = widget.partner.isActive;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pct = double.tryParse(_percent.text.replaceAll(',', '.')) ?? -1;
    if (pct < 0 || pct > 100) {
      setState(() => _error = 'Informe um percentual entre 0 e 100.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await sl<UpdatePartnerUseCase>()(
      widget.partner.copyWith(
        name: _name.text.trim(),
        address: _address.text.trim(),
        isActive: _isActive,
        discountPercentage: pct,
      ),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Acordo do parceiro',
      subtitle:
          'Só o financeiro publica o % vivo. O parceiro não altera este número.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nome'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Endereço'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _percent,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Desconto do acordo (%)',
              helperText: 'Este % aparece no catálogo e no validador do caixa.',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Parceiro ativo',
              style: GoogleFonts.outfit(color: AppTheme.primaryColor),
            ),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          PrimaryButton(
            text: _saving ? 'Salvando...' : 'Publicar acordo',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
