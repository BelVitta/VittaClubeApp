import 'package:flutter/material.dart';

/// Chave global do navigator — deep links de auth/pagamento.
class AppNavigator {
  AppNavigator._();

  static final key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;

  static BuildContext? get context => key.currentContext;
}
