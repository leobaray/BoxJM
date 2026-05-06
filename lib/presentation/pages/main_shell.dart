import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/ignition_dock.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0 = /  (orçamentos), 1 = /services, fab = /new
  int _index = 0;
  bool _fabActive = false;

  static const _tabPaths = ['/', '/services'];
  static const _fabPath = '/new';

  static const _items = <DockItem>[
    DockItem(
      label: 'Orçamentos',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
    ),
    DockItem(
      label: 'Catálogo',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    if (location == _fabPath) {
      if (!_fabActive) setState(() => _fabActive = true);
      return;
    }
    final newIndex = _tabPaths.indexOf(location);
    if (newIndex != -1 && (newIndex != _index || _fabActive)) {
      setState(() {
        _index = newIndex;
        _fabActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // Ambient glow no canto superior esquerdo — brasa do cockpit.
          Positioned(
            top: -80,
            left: -80,
            width: 320,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.halo(AppColors.ignition, alpha: 0.10),
                ),
              ),
            ),
          ),
          // SafeArea só no topo — consome o padding da status bar uma
          // única vez. Os SafeArea das páginas filhas ficam no-op (já sem
          // top padding no MediaQuery), evitando que o banner empurre o
          // conteúdo pela altura da status bar somada à sua própria.
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                const ConnectivityBanner(),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: IgnitionDock(
        items: _items,
        index: _fabActive ? -1 : _index,
        onTap: (i) {
          if (_fabActive || i != _index) context.go(_tabPaths[i]);
        },
        onFabTap: () {
          if (_fabActive) {
            context.go(_tabPaths[_index]);
          } else {
            context.go(_fabPath);
          }
        },
        fabIcon: Icons.add_rounded,
        fabLabel: 'Novo orçamento',
        fabActive: _fabActive,
      ),
    );
  }
}
