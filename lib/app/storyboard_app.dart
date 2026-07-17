import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/app_providers.dart';
import '../features/updater/domain/app_update_config.dart';
import '../features/settings/domain/app_settings.dart';
import 'app_theme.dart';
import '../features/projects/presentation/project_portal.dart';

class StoryboardApp extends ConsumerWidget {
  const StoryboardApp({
    super.key,
    this.enableWindowControls = true,
    this.initialTabIndex = 0,
    this.initialProjectIndexPath,
  });

  final bool enableWindowControls;
  final int initialTabIndex;
  final String? initialProjectIndexPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsController = ref.watch(settingsControllerProvider);
    return ValueListenableBuilder(
      valueListenable: settingsController,
      builder: (context, settings, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppUpdateConfig.windowTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themePreference.themeMode,
          home: ProjectPortal(initialProjectIndexPath: initialProjectIndexPath),
        );
      },
    );
  }
}

extension on AppThemePreference {
  ThemeMode get themeMode {
    return switch (this) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
  }
}
