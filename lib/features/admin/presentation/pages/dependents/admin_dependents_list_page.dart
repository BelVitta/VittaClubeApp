import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../dependents/domain/entities/pending_dependent_entity.dart';
import '../../../../dependents/domain/usecases/approve_dependent_usecase.dart';
import '../../../../dependents/domain/usecases/get_pending_dependents_usecase.dart';
import '../../../../dependents/domain/usecases/reject_dependent_usecase.dart';
import '../../widgets/admin_list_item.dart';
import '../../widgets/admin_page_scaffold.dart';

/// Fila de aprovação presencial de dependentes (ver docs/feature/dependentes.md
/// RN-03). Sem verificação documental — o admin confirma o vínculo
/// pessoalmente (ex: na primeira visita do dependente) antes de aprovar.
class AdminDependentsListPage extends StatefulWidget {
  const AdminDependentsListPage({super.key});

  @override
  State<AdminDependentsListPage> createState() =>
      _AdminDependentsListPageState();
}

class _AdminDependentsListPageState extends State<AdminDependentsListPage> {
  late Future<List<PendingDependentEntity>> _future;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PendingDependentEntity>> _load() async {
    final result = await sl<GetPendingDependentsUseCase>()();
    return result.fold((failure) => throw failure.message, (items) => items);
  }

  void _reload() {
    setState(() => _future = _load());
  }

  Future<void> _approve(PendingDependentEntity item) async {
    setState(() => _processing.add(item.dependent.id));
    final result = await sl<ApproveDependentUseCase>()(
      dependentId: item.dependent.id,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar: ${failure.message}')),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.dependent.name} aprovado(a).')),
        );
        _reload();
      },
    );
    if (mounted) setState(() => _processing.remove(item.dependent.id));
  }

  Future<void> _reject(PendingDependentEntity item) async {
    final reason = await _askRejectionReason(item.dependent.name);
    if (reason == null) return;

    setState(() => _processing.add(item.dependent.id));
    final result = await sl<RejectDependentUseCase>()(
      dependentId: item.dependent.id,
      reason: reason,
    );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar: ${failure.message}')),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.dependent.name} rejeitado(a).')),
        );
        _reload();
      },
    );
    if (mounted) setState(() => _processing.remove(item.dependent.id));
  }

  Future<String?> _askRejectionReason(String dependentName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rejeitar $dependentName'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo (opcional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().isEmpty
                  ? 'Rejeitado pela recepção'
                  : controller.text.trim(),
            ),
            child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: 'Dependentes pendentes',
      subtitle: 'Aprove presencialmente após confirmar o vínculo',
      body: FutureBuilder<List<PendingDependentEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar: ${snapshot.error}',
                style: GoogleFonts.outfit(color: const Color(0xFF6D7F95)),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Nenhum dependente aguardando aprovação.',
                style: GoogleFonts.outfit(color: const Color(0xFF6D7F95)),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PendingDependentCard(
                        item: item,
                        processing: _processing.contains(item.dependent.id),
                        onApprove: () => _approve(item),
                        onReject: () => _reject(item),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _PendingDependentCard extends StatelessWidget {
  final PendingDependentEntity item;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingDependentCard({
    required this.item,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dependent = item.dependent;
    return AdminListItem(
      title: dependent.name,
      subtitle: '${dependent.relationship} de ${item.holderName} · '
          'nascido(a) em ${DateFormat('dd/MM/yyyy').format(dependent.birthDate)}\n'
          'Titular: ${item.holderEmail}',
      trailing: processing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Rejeitar',
                ),
                IconButton(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, color: Color(0xFF249689)),
                  tooltip: 'Aprovar',
                ),
              ],
            ),
    );
  }
}
