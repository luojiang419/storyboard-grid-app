import 'dart:io';

import 'package:storyboard_grid_app/core/database/app_database.dart';
import 'package:storyboard_grid_app/core/services/app_directories.dart';
import 'package:storyboard_grid_app/features/settings/data/settings_repository.dart';
import 'package:storyboard_grid_app/features/settings/domain/vision_api_config.dart';
import 'package:storyboard_grid_app/features/storyboard/application/storyboard_controller.dart';
import 'package:test/test.dart';

void main() {
  test('只有 MiniMax-M3 视觉配置使用 200 路并发', () async {
    final root = await Directory.systemTemp.createTemp('vision_concurrency_');
    addTearDown(() => root.delete(recursive: true));
    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final settings = SettingsRepository(database, directories).load();
    final minimax = VisionApiConfig(
      id: 'minimax',
      name: 'MiniMax M3',
      baseUrl: 'https://api.minimaxi.com',
      apiKey: 'test-key',
      model: 'MiniMax-M3',
    );

    expect(
      visionImageAnalysisConcurrency(
        settings.copyWith(
          visionApiConfigs: [minimax],
          activeVisionApiConfigId: minimax.id,
        ),
      ),
      StoryboardController.maxMiniMaxVisionConcurrency,
    );
    expect(visionImageAnalysisConcurrency(settings), 1);
  });
}
