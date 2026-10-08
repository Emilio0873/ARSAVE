import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/auth_state.dart';
import '../auth/login_screen.dart';
import 'admin_screen.dart';
import 'trash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.text = context.read<AuthState>().user?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    try {
      await context.read<AuthState>().updateName(_name.text.trim());
      if (!mounted) return;
      showAppSuccess(context, 'Profil enregistré.');
    } catch (e) {
      if (!mounted) return;
      showAppError(context, e);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthState>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final theme = context.watch<ThemeController>();
    final isAdmin = user?.role == 'admin';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Paramètres', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Thème, confidentialité et compte.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Text('Thème', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModeChoice(
                    label: 'Sombre',
                    icon: Icons.dark_mode_rounded,
                    selected: theme.themeId != 'light',
                    onTap: () => theme.setTheme('night'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeChoice(
                    label: 'Clair',
                    icon: Icons.light_mode_rounded,
                    selected: theme.themeId == 'light',
                    onTap: () => theme.setTheme('light'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Confidentialité', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SurfacePanel(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Miniatures des images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Déchiffre localement les images pour les afficher. Désactivez pour ne rien prévisualiser.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: theme.showThumbnails,
                    activeThumbColor: AppColors.white,
                    activeTrackColor: AppColors.teal,
                    onChanged: theme.setShowThumbnails,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.lock_rounded,
                    title: 'Protection sur l’appareil',
                    body:
                        'Vos fichiers sont protégés sur votre téléphone avant l’envoi.',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.visibility_off_rounded,
                    title: 'Confidentialité',
                    body:
                        'Personne d’autre ne peut ouvrir le contenu de vos fichiers sauvegardés.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Compte', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(user?.email ?? '—', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nom affiché',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveName,
                    child: const Text('Enregistrer le nom'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SurfacePanel(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppColors.mint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Corbeille',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              SurfacePanel(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppColors.mint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Espace administrateur',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.teal : AppColors.slate),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: selected ? AppColors.teal : AppColors.slate,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.mint, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
