import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garante que strings de UI em `lib/**/presentation/**`, `lib/shared/**`
/// e mensagens de usuário em `lib/core/services/**` não regridam a grafia
/// PT-BR sem acento (ex.: "codigo", "voce", "beneficios").
///
/// Chaves técnicas puras (`clinica`, `cartao_credito`, status de API) são
/// ignoradas quando a string inteira é um identificador snake/lowercase.
void main() {
  test('UI strings não contêm ortografia PT-BR sem acento comum', () {
    final roots = [
      Directory('lib/features'),
      Directory('lib/shared'),
      Directory('lib/core/services'),
      Directory('lib/core/error'),
    ];

    final badWord = RegExp(
      r'\b('
      r'voce|Voce|codigo|Codigo|beneficios|Beneficios|beneficio|Beneficio|'
      r'indicacao|Indicacao|indicacoes|Indicacoes|validacao|Validacao|'
      r'validacoes|servico|Servico|servicos|Servicos|'
      r'niveis|Niveis|historico|Historico|informacoes|Informacoes|'
      r'notificacao|Notificacao|notificacoes|Notificacoes|'
      r'descricao|Descricao|operacao|Operacao|titulo|Titulo|'
      r'usuario|Usuario|usuarios|Usuarios|obrigatorio|Obrigatorio|'
      r'invalido|Invalido|botao|Botao|premio|Premio|elegiveis|auditavel|'
      r'recepcao|beneficiario|creditos|carencia|Carencia|excluido|'
      r'aparecerao|endereco|Endereco|disponiveis|disponivel|Disponivel|'
      r'saude|Saude|funcoes|Funcoes|metodo|Metodo|exibicao|Exibicao|'
      r'expiracao|Expiracao|inscricoes|Inscricoes|visao|Visao|'
      r'relatorios|Relatorios|laboratorio|Laboratorio|'
      r'inscricao|Inscricao|Inicio|'
      // residual found by verification audit
      r'Transparencia|transparencia|Indice|indice|'
      r'execucao|Execucao|deterministico|verificavel|'
      r'Minimo|minimo|maximo|Maximo|'
      r'sao|Sao|tambem|Tambem|atraves|'
      r'possivel|Possivel|necessario|Necessario|indisponivel|'
      r'concluido|Concluido|atencao|Atencao|configuracoes|Configuracoes|'
      r'selecao|Selecao|opcao|Opcao|situacao|Situacao|'
      r'cancelacao|Cancelacao|confirmacao|Confirmacao|'
      r'autenticacao|Autenticacao|autorizacao|permissoes|Permissoes|'
      r'atualizacao|Atualizacao|observacao|Observacao|'
      r'localizacao|Localizacao|avaliacao|Avaliacao|'
      r'periodo|Periodo|basico|Basico|publico|Publico|'
      r'unico|Unico|unica|Unica|ultimo|Ultimo|'
      r'proprio|propria|cartao|Cartao|credito|debito|'
      r'precos|metricas|seguranca|numero|Numero|razao|Razao|'
      r'pagina|Pagina|medico|Medico|medicos|Medicos|medicas|'
      r'funcao|Funcao|irreversivel|selecionara'
      r')\b',
    );

    final stringLiteral = RegExp(r'''(['"])([^'"\\]{3,})\1''');
    final technicalKey = RegExp(r'^[a-z0-9_./\-]+$');

    final offenders = <String>[];

    for (final root in roots) {
      if (!root.existsSync()) continue;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Só presentation em features; services/error/shared inteiros.
        final path = entity.path.replaceAll('\\', '/');
        if (path.contains('/features/') &&
            !path.contains('/presentation/') &&
            !path.contains('/core/services/') &&
            !path.endsWith('_repository_impl.dart') &&
            !path.contains('/domain/usecases/')) {
          // Ainda assim olhamos usecases/repos com Failure messages.
          if (!path.contains('repository_impl') &&
              !path.contains('usecase')) {
            continue;
          }
        }

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Comentários de documentação não são UI — mas se a linha também
          // tem string literal, ainda validamos a literal.
          for (final match in stringLiteral.allMatches(line)) {
            final content = match.group(2)!;
            if (technicalKey.hasMatch(content)) continue;
            if (content.startsWith('http') || content.startsWith('assets/')) {
              continue;
            }
            if (badWord.hasMatch(content)) {
              offenders.add('$path:${i + 1}: "$content"');
            }
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Strings de UI com ortografia incorreta:\n'
          '${offenders.take(40).join('\n')}'
          '${offenders.length > 40 ? '\n... (+${offenders.length - 40})' : ''}',
    );
  });
}
