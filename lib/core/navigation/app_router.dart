import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:category_manager/core/navigation/bottom_navigation.dart';
import 'package:category_manager/features/auth/data/providers/auth_providers.dart';
import 'package:category_manager/features/auth/presentation/login_screen.dart';
import 'package:category_manager/features/auth/presentation/splash_screen.dart';

class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});
  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  late final Timer _timer;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();
    final user = ref.watch(authProvider).asData?.value;
    return user == null ? const LoginScreen() : HomeScreen(user: user);
  }
}
