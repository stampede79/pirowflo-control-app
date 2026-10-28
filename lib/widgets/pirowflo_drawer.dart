import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PiRowFloDrawer extends StatelessWidget {
  final int selectedPage;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onSettings;
  final VoidCallback onHeartRateTest;

  final VoidCallback onTestWorkout;

  const PiRowFloDrawer({
    super.key,
    required this.selectedPage,
    required this.onSelectPage,
    required this.onSettings,
    required this.onHeartRateTest,
    required this.onTestWorkout,
  });

  Future<PackageInfo> _packageInfo() {
    return PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      child: Column(
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/rowing_background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18000000),
                        Color(0x22000000),
                        Color(0xAA083B4C),
                      ],
                    ),
                  ),
                ),
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.rowing, color: Colors.white, size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'PiRow Coach',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dein Rudertraining',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
              children: [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  title: 'Übersicht',
                  selected: selectedPage == 0,
                  onTap: () => onSelectPage(0),
                ),
                _DrawerItem(
                  icon: Icons.rowing,
                  selectedIcon: Icons.rowing,
                  title: 'Training',
                  selected: selectedPage == 1,
                  onTap: () => onSelectPage(1),
                ),
                _DrawerItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  title: 'Coach',
                  selected: selectedPage == 2,
                  onTap: () => onSelectPage(2),
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  selectedIcon: Icons.bar_chart,
                  title: 'Statistiken',
                  selected: selectedPage == 3,
                  onTap: () => onSelectPage(3),
                ),
                _DrawerItem(
                  icon: Icons.tune_outlined,
                  selectedIcon: Icons.tune,
                  title: 'Steuerung',
                  selected: selectedPage == 4,
                  onTap: () => onSelectPage(4),
                ),
                _DrawerItem(
                  icon: Icons.favorite_outline,
                  selectedIcon: Icons.favorite,
                  title: 'HF-Sensor testen',
                  selected: false,
                  onTap: onHeartRateTest,
                ),
                _DrawerItem(
                  icon: Icons.science_outlined,
                  selectedIcon: Icons.science,
                  title: 'Testtraining',
                  selected: false,
                  onTap: onTestWorkout,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Divider(),
                ),

                _DrawerItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  title: 'Einstellungen',
                  selected: false,
                  onTap: onSettings,
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                children: [
                  Icon(
                    Icons.water,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      'Row. Flow. Repeat.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                  FutureBuilder<PackageInfo>(
                    future: _packageInfo(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      return Text(
                        'v${snapshot.data!.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: selected
                          ? primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
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
