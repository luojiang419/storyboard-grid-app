import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/projects/application/project_service.dart';
import '../../features/projects/data/legacy_project_migrator.dart';
import '../../features/projects/data/project_catalog_repository.dart';
import '../../features/projects/data/project_operations_service.dart';
import '../../features/updater/application/updater_controller.dart';
import '../../features/updater/data/updater_service.dart';
import '../database/app_database.dart';
import '../services/app_directories.dart';
import '../services/workspace_directories.dart';

final globalDatabaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('全局数据库尚未初始化');
});

final appDirectoriesProvider = Provider<AppDirectories>((ref) {
  throw StateError('AppDirectories 尚未初始化');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(projectDatabaseProvider);
}, dependencies: [projectDatabaseProvider]);

final projectDatabaseProvider = Provider<AppDatabase>((ref) {
  return ref.watch(globalDatabaseProvider);
}, dependencies: []);

final projectDirectoriesProvider = Provider<WorkspaceDirectories>((ref) {
  return ref.watch(appDirectoriesProvider);
}, dependencies: []);

final currentProjectNameProvider = Provider<String>(
  (ref) => '项目',
  dependencies: [],
);

final projectCatalogRepositoryProvider = Provider<ProjectCatalogRepository>((
  ref,
) {
  return ProjectCatalogRepository(ref.watch(globalDatabaseProvider));
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(catalog: ref.watch(projectCatalogRepositoryProvider));
});

final projectOperationsServiceProvider = Provider<ProjectOperationsService>((
  ref,
) {
  return ProjectOperationsService(
    catalog: ref.watch(projectCatalogRepositoryProvider),
  );
});

final legacyProjectMigratorProvider = Provider<LegacyProjectMigrator>((ref) {
  return LegacyProjectMigrator(
    appDirectories: ref.watch(appDirectoriesProvider),
    globalDatabase: ref.watch(globalDatabaseProvider),
    catalog: ref.watch(projectCatalogRepositoryProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw StateError('SettingsRepository 尚未初始化');
});

final settingsControllerProvider = Provider<SettingsController>((ref) {
  throw StateError('SettingsController 尚未初始化');
});

final updaterServiceProvider = Provider<UpdaterService>((ref) {
  return UpdaterService(directories: ref.watch(appDirectoriesProvider));
});

final updaterControllerProvider = Provider<UpdaterController>((ref) {
  final controller = UpdaterController(
    settingsController: ref.watch(settingsControllerProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
    service: ref.watch(updaterServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
