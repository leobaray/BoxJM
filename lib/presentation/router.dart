import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import 'pages/budget_detail_page.dart';
import 'pages/home_page.dart';
import 'pages/main_shell.dart';
import 'pages/new_budget_page.dart';
import 'pages/services_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: '/services',
            builder: (_, __) => const ServicesPage(),
          ),
          GoRoute(
            path: '/new',
            builder: (_, __) => const NewBudgetPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/budget/:id',
        builder: (_, state) =>
            BudgetDetailPage(budgetId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/budget/:id/edit',
        builder: (_, state) =>
            NewBudgetPage(editingBudgetId: state.pathParameters['id']),
      ),
    ],
    errorBuilder: (context, state) => _NotFoundPage(
      path: state.uri.toString(),
      onHome: () => context.go('/'),
    ),
  );
});

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.path, required this.onHome});
  final String path;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('BOX JM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 24),
                const Icon(Icons.help_outline,
                    size: 80, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('Página não encontrada',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                Text(path,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onHome,
                  icon: const Icon(Icons.home, color: Colors.white),
                  label: const Text('Voltar ao início'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
