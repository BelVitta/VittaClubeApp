/// Controla a exibição do banner promocional de "sem plano" na sessão atual
/// do app. Singleton em memória (via get_it): troca de aba não reabre o modal,
/// mas fechar e reabrir o app permite mostrar de novo.
class NoPlanPromoController {
  bool shownThisSession = false;

  bool get canShow => !shownThisSession;

  void markShown() {
    shownThisSession = true;
  }

  /// Útil em testes.
  void reset() {
    shownThisSession = false;
  }
}
