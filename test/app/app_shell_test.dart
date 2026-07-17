import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storyboard_grid_app/app/app_shell.dart';
import 'package:storyboard_grid_app/app/app_theme.dart';
import 'package:storyboard_grid_app/core/database/app_database.dart';
import 'package:storyboard_grid_app/core/providers/app_providers.dart';
import 'package:storyboard_grid_app/core/services/app_directories.dart';
import 'package:storyboard_grid_app/features/onboarding/data/onboarding_repository.dart';
import 'package:storyboard_grid_app/features/settings/application/settings_controller.dart';
import 'package:storyboard_grid_app/features/settings/data/settings_repository.dart';
import 'package:storyboard_grid_app/features/updater/application/updater_controller.dart';
import 'package:storyboard_grid_app/features/updater/data/updater_service.dart';
import 'package:storyboard_grid_app/features/updater/domain/app_update_config.dart';

void main() {
  testWidgets('新增设计分镜图后会迁移旧保存页签索引', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late final Directory root;
    late final AppDirectories directories;
    late final AppDatabase database;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('app_shell_');
      directories = await AppDirectories.create(executableDirectory: root);
      database = await AppDatabase.open(directories.databaseFile);
      database
        ..setSetting('appShellSelectedTabIndex', '0')
        ..setSetting('updateReleaseApiUrl', '');
    });
    final repository = SettingsRepository(database, directories);
    final settingsController = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    final updaterController = _NoopUpdaterController(
      settingsController: settingsController,
      settingsRepository: repository,
      directories: directories,
    );
    addTearDown(() async {
      updaterController.dispose();
      settingsController.dispose();
      database.dispose();
      await root.delete(recursive: true);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDirectoriesProvider.overrideWithValue(directories),
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(repository),
          settingsControllerProvider.overrideWithValue(settingsController),
          updaterControllerProvider.overrideWithValue(updaterController),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const AppShell(enableWindowControls: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('设计分镜图'), findsOneWidget);
    expect(find.text('图片任务'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-shell-bottom-tabs')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('grid-cut-inspector-actions')),
      findsOneWidget,
    );
    final bottomTabsCenter = tester.getCenter(
      find.byKey(const ValueKey('app-shell-bottom-tabs')),
    );
    final bottomTabsRect = tester.getRect(
      find.byKey(const ValueKey('app-shell-bottom-tabs')),
    );
    final cutActionsRect = tester.getRect(
      find.byKey(const ValueKey('grid-cut-inspector-actions')),
    );
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(bottomTabsCenter.dx, closeTo(logicalWidth / 2, 0.5));
    expect(cutActionsRect.bottom, lessThan(bottomTabsRect.top));
    expect(database.getSetting('appShellSelectedTabIndex'), '1');
    expect(database.getSetting('appShellSelectedTabIndexVersion'), '2');

    await tester.tap(find.byKey(const ValueKey('app-shell-tab-设置')));
    await tester.pumpAndSettle();

    expect(find.text('外观'), findsOneWidget);
    expect(database.getSetting('appShellSelectedTabIndex'), '4');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('工程入口会并入底部统一导航并可触发返回首页', (tester) async {
    var closeInvoked = false;
    late final Directory root;
    late final AppDirectories directories;
    late final AppDatabase database;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('app_shell_project_');
      directories = await AppDirectories.create(executableDirectory: root);
      database = await AppDatabase.open(directories.databaseFile);
      database.setSetting('updateReleaseApiUrl', '');
    });
    final repository = SettingsRepository(database, directories);
    final settingsController = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    final updaterController = _NoopUpdaterController(
      settingsController: settingsController,
      settingsRepository: repository,
      directories: directories,
    );
    addTearDown(() async {
      updaterController.dispose();
      settingsController.dispose();
      database.dispose();
      await root.delete(recursive: true);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDirectoriesProvider.overrideWithValue(directories),
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(repository),
          settingsControllerProvider.overrideWithValue(settingsController),
          updaterControllerProvider.overrideWithValue(updaterController),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: AppShell(
            enableWindowControls: false,
            projectName: '测试工程',
            onCloseProject: () async {
              closeInvoked = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('查看使用教程'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-help-action')),
      findsOneWidget,
    );

    expect(find.byKey(const ValueKey('app-shell-bottom-tabs')), findsOneWidget);
    expect(find.text('测试工程'), findsOneWidget);
    expect(find.text('${AppUpdateConfig.windowTitle} — 测试工程'), findsOneWidget);
    expect(find.byKey(const ValueKey('close-project-to-home')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('close-project-to-home')))
          .height,
      40,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('app-shell-tab-设计分镜图'))).height,
      40,
    );

    await tester.tap(find.byKey(const ValueKey('close-project-to-home')));
    await tester.pump();

    expect(closeInvoked, isTrue);

    final regularHeight = tester
        .getSize(find.byKey(const ValueKey('app-shell-bottom-tabs')))
        .height;
    tester.view.physicalSize = const Size(720, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('app-shell-bottom-tabs')))
          .height,
      greaterThan(regularHeight),
    );
  });

  testWidgets('首次进入工程显示引导且重播不会污染页面记忆', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late final Directory root;
    late final AppDirectories directories;
    late final AppDatabase database;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('app_shell_onboarding_');
      directories = await AppDirectories.create(executableDirectory: root);
      database = await AppDatabase.open(directories.databaseFile);
      OnboardingRepository.initializeInstallation(
        database: database,
        isFreshInstall: true,
      );
      database.setSetting('updateReleaseApiUrl', '');
    });
    final repository = SettingsRepository(database, directories);
    final settingsController = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    final updaterController = _NoopUpdaterController(
      settingsController: settingsController,
      settingsRepository: repository,
      directories: directories,
    );
    addTearDown(() async {
      updaterController.dispose();
      settingsController.dispose();
      database.dispose();
      await root.delete(recursive: true);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDirectoriesProvider.overrideWithValue(directories),
          appDatabaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(repository),
          settingsControllerProvider.overrideWithValue(settingsController),
          updaterControllerProvider.overrideWithValue(updaterController),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const AppShell(enableWindowControls: false, initialTabIndex: 3),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('onboarding-overlay')), findsOneWidget);
    expect(find.text('从一个创意，到完整故事板'), findsOneWidget);
    expect(database.getSetting('appShellSelectedTabIndex'), isNull);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 240));
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('把组合图拆成独立镜头'), findsOneWidget);
    expect(database.getSetting('appShellSelectedTabIndex'), isNull);

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byKey(const ValueKey('onboarding-overlay')), findsNothing);
    expect(
      database.getSetting(OnboardingRepository.completedVersionKey),
      '${OnboardingRepository.currentVersion}',
    );

    await tester.tap(find.byKey(const ValueKey('app-shell-tab-导出故事板')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(database.getSetting('appShellSelectedTabIndex'), '3');

    await tester.tap(find.byKey(const ValueKey('show-onboarding-help')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(database.getSetting('appShellSelectedTabIndex'), '3');

    await tester.tap(find.byKey(const ValueKey('onboarding-skip')));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.byKey(const ValueKey('onboarding-overlay')), findsNothing);
    expect(database.getSetting('appShellSelectedTabIndex'), '3');

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _NoopUpdaterController extends UpdaterController {
  _NoopUpdaterController({
    required super.settingsController,
    required super.settingsRepository,
    required AppDirectories directories,
  }) : super(
         service: UpdaterService(directories: directories),
         exitApplication: (_) {},
       );

  @override
  Future<void> beginStartupFlow() async {}
}
