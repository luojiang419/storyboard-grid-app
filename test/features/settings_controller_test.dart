import 'dart:io';

import 'package:storyboard_grid_app/core/database/app_database.dart';
import 'package:storyboard_grid_app/core/services/app_directories.dart';
import 'package:storyboard_grid_app/features/settings/application/settings_controller.dart';
import 'package:storyboard_grid_app/features/settings/data/settings_repository.dart';
import 'package:storyboard_grid_app/features/settings/domain/app_settings.dart';
import 'package:storyboard_grid_app/features/settings/domain/vision_api_config.dart';
import 'package:test/test.dart';

void main() {
  test('编号滑块预览只更新内存且拖动结束值才持久化', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);

    controller.previewCutImageNumberBackgroundOpacity(0.35);
    controller.previewCutImageNumberTextScale(1.4);

    expect(controller.value.cutImageNumberBackgroundOpacity, 0.35);
    expect(controller.value.cutImageNumberTextScale, 1.4);
    var restored = repository.load();
    expect(
      restored.cutImageNumberBackgroundOpacity,
      AppSettings.defaultCutImageNumberBackgroundOpacity,
    );
    expect(
      restored.cutImageNumberTextScale,
      AppSettings.defaultCutImageNumberTextScale,
    );

    await controller.setCutImageNumberBackgroundOpacity(
      controller.value.cutImageNumberBackgroundOpacity,
    );
    await controller.setCutImageNumberTextScale(
      controller.value.cutImageNumberTextScale,
    );

    restored = repository.load();
    expect(restored.cutImageNumberBackgroundOpacity, 0.35);
    expect(restored.cutImageNumberTextScale, 1.4);
  });

  test('文本框编号开关会持久化', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);

    expect(controller.value.storyboardCaptionNumberEnabled, isTrue);
    await controller.setStoryboardCaptionNumberEnabled(false);

    expect(controller.value.storyboardCaptionNumberEnabled, isFalse);
    expect(repository.load().storyboardCaptionNumberEnabled, isFalse);
  });

  test('APIMart地址和Key独立持久化且不覆盖GRSai配置', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);

    await controller.setImageGenerationApiKey('grsai-key');
    await controller.setImageGenerationApiMartSettings(
      baseUrl: 'https://api.apimart.ai/v1/images/generations/',
      apiKey: 'apimart-key',
    );

    final restored = repository.load();
    expect(restored.imageGenerationApiKey, 'grsai-key');
    expect(restored.imageGenerationApiMartApiBaseUrl, 'https://api.apimart.ai');
    expect(restored.imageGenerationApiMartApiKey, 'apimart-key');
  });

  test('APIMart文档地址不会被误保存为接口地址', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);

    await expectLater(
      controller.setImageGenerationApiMartSettings(
        baseUrl: 'https://docs.apimart.ai/cn',
        apiKey: 'apimart-key',
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(contains('文档地址'), contains('api.apimart.ai')),
        ),
      ),
    );
    expect(
      repository.load().imageGenerationApiMartApiBaseUrl,
      AppSettings.defaultImageGenerationApiMartApiBaseUrl,
    );
  });

  test('Gemini地址和Key独立持久化且不覆盖GRSai配置', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);

    await controller.setImageGenerationGrsaiSettings(
      baseUrl: 'https://grsai.example',
      apiKey: 'grsai-key',
    );
    await controller.setImageGenerationGeminiSettings(
      baseUrl: 'https://www.shiying-api.com',
      apiKey: 'gemini-key',
    );

    final restored = repository.load();
    expect(restored.imageGenerationApiBaseUrl, 'https://grsai.example');
    expect(restored.imageGenerationApiKey, 'grsai-key');
    expect(
      restored.imageGenerationGeminiApiBaseUrl,
      'https://www.shiying-api.com',
    );
    expect(restored.imageGenerationGeminiApiKey, 'gemini-key');
  });

  test('视觉 API 卡片可新增、选择默认并持久化', () async {
    final root = await Directory.systemTemp.createTemp('settings_controller_');
    addTearDown(() => root.delete(recursive: true));

    final directories = await AppDirectories.create(executableDirectory: root);
    final database = await AppDatabase.open(directories.databaseFile);
    addTearDown(database.dispose);
    final repository = SettingsRepository(database, directories);
    final controller = SettingsController(
      repository: repository,
      initialSettings: repository.load(),
    );
    addTearDown(controller.dispose);
    final regular = VisionApiConfig(
      id: 'regular',
      name: '常规模型',
      baseUrl: 'https://vision.example',
      apiKey: 'regular-key',
      model: 'vision-model',
    );
    final minimax = VisionApiConfig(
      id: 'minimax',
      name: 'MiniMax M3',
      baseUrl: 'https://api.minimaxi.com',
      apiKey: 'minimax-key',
      model: 'MiniMax-M3',
    );

    await controller.saveVisionApiConfigs(
      configs: [regular, minimax],
      activeConfigId: minimax.id,
    );

    final restored = repository.load();
    expect(restored.visionApiConfigs, hasLength(2));
    expect(restored.activeVisionApiConfig?.id, minimax.id);
    expect(restored.visionApiBaseUrl, 'https://api.minimaxi.com');
    expect(restored.visionApiKey, 'minimax-key');
    expect(restored.visionModel, 'MiniMax-M3');
  });
}
