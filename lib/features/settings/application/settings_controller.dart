import 'package:flutter/foundation.dart';

import '../data/settings_repository.dart';
import '../domain/api_endpoint_normalizer.dart';
import '../domain/app_settings.dart';
import '../domain/vision_api_config.dart';
import '../domain/image_generation_api_config.dart';

class SettingsController extends ValueNotifier<AppSettings> {
  SettingsController({
    required SettingsRepository repository,
    required AppSettings initialSettings,
  }) : _repository = repository,
       super(initialSettings);

  final SettingsRepository _repository;

  Future<void> setExportDirectory(String path) async {
    final next = value.copyWith(exportDirectory: path);
    _repository.save(next);
    value = next;
  }

  Future<void> setThemePreference(AppThemePreference preference) async {
    final next = value.copyWith(themePreference: preference);
    _repository.save(next);
    value = next;
  }

  Future<void> setCutImageNumberEnabled(bool enabled) async {
    final next = value.copyWith(cutImageNumberEnabled: enabled);
    _repository.save(next);
    value = next;
  }

  Future<void> setCutImageNumberPosition(
    CutImageNumberPosition position,
  ) async {
    final next = value.copyWith(cutImageNumberPosition: position);
    _repository.save(next);
    value = next;
  }

  Future<void> setCutImageNumberBackgroundOpacity(double opacity) async {
    final next = value.copyWith(cutImageNumberBackgroundOpacity: opacity);
    _repository.save(next);
    value = next;
  }

  void previewCutImageNumberBackgroundOpacity(double opacity) {
    value = value.copyWith(cutImageNumberBackgroundOpacity: opacity);
  }

  Future<void> setCutImageNumberTextScale(double scale) async {
    final next = value.copyWith(cutImageNumberTextScale: scale);
    _repository.save(next);
    value = next;
  }

  void previewCutImageNumberTextScale(double scale) {
    value = value.copyWith(cutImageNumberTextScale: scale);
  }

  Future<void> setStoryboardCaptionNumberEnabled(bool enabled) async {
    final next = value.copyWith(storyboardCaptionNumberEnabled: enabled);
    _repository.save(next);
    value = next;
  }

  Future<void> setStoryboardSummaryPageEnabled(bool enabled) async {
    final next = value.copyWith(storyboardSummaryPageEnabled: enabled);
    _repository.save(next);
    value = next;
  }

  Future<void> setVisionApiBaseUrl(String baseUrl) async {
    await setVisionSettings(
      baseUrl: baseUrl,
      apiKey: value.visionApiKey,
      model: value.visionModel,
    );
  }

  Future<void> setVisionApiKey(String apiKey) async {
    await setVisionSettings(
      baseUrl: value.visionApiBaseUrl,
      apiKey: apiKey,
      model: value.visionModel,
    );
  }

  Future<void> setVisionModel(String model) async {
    await setVisionSettings(
      baseUrl: value.visionApiBaseUrl,
      apiKey: value.visionApiKey,
      model: model,
    );
  }

  Future<void> setVisionSettings({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) async {
    final active =
        value.activeVisionApiConfig ??
        VisionApiConfig(
          name: '默认视觉模型',
          baseUrl: value.visionApiBaseUrl,
          apiKey: value.visionApiKey,
          model: value.visionModel,
        );
    final configs = value.visionApiConfigs
        .map(
          (config) => config.id == active.id
              ? active.copyWith(
                  baseUrl: baseUrl.trim(),
                  apiKey: apiKey.trim(),
                  model: model.trim(),
                )
              : config,
        )
        .toList();
    final next = value.copyWith(
      visionApiConfigs: configs.isEmpty
          ? [
              active.copyWith(
                baseUrl: baseUrl.trim(),
                apiKey: apiKey.trim(),
                model: model.trim(),
              ),
            ]
          : configs,
      activeVisionApiConfigId: active.id,
    );
    _repository.save(next);
    value = next;
  }

  Future<void> saveVisionApiConfigs({
    required List<VisionApiConfig> configs,
    required String activeConfigId,
  }) async {
    if (configs.isEmpty) {
      throw ArgumentError.value(configs, 'configs', '至少保留一张视觉 API 卡片');
    }
    if (!configs.any((config) => config.id == activeConfigId)) {
      throw ArgumentError.value(
        activeConfigId,
        'activeConfigId',
        '默认视觉 API 卡片不存在',
      );
    }
    final next = value.copyWith(
      visionApiConfigs: List.unmodifiable(configs),
      activeVisionApiConfigId: activeConfigId,
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationApiBaseUrl(String baseUrl) async {
    final next = value.copyWith(imageGenerationApiBaseUrl: baseUrl.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationApiKey(String apiKey) async {
    final next = value.copyWith(imageGenerationApiKey: apiKey.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationGeminiApiKey(String apiKey) async {
    final next = value.copyWith(imageGenerationGeminiApiKey: apiKey.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationGeminiApiBaseUrl(String baseUrl) async {
    final next = value.copyWith(
      imageGenerationGeminiApiBaseUrl: baseUrl.trim(),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationApiMartApiKey(String apiKey) async {
    final next = value.copyWith(imageGenerationApiMartApiKey: apiKey.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationApiMartApiBaseUrl(String baseUrl) async {
    final next = value.copyWith(
      imageGenerationApiMartApiBaseUrl:
          ApiEndpointNormalizer.normalizeApiMartBaseUrl(baseUrl),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationGrsaiSettings({
    required String baseUrl,
    required String apiKey,
  }) async {
    final next = value.copyWith(
      imageGenerationApiBaseUrl: baseUrl.trim(),
      imageGenerationApiKey: apiKey.trim(),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationGeminiSettings({
    required String baseUrl,
    required String apiKey,
  }) async {
    final next = value.copyWith(
      imageGenerationGeminiApiBaseUrl: baseUrl.trim(),
      imageGenerationGeminiApiKey: apiKey.trim(),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationApiMartSettings({
    required String baseUrl,
    required String apiKey,
  }) async {
    final next = value.copyWith(
      imageGenerationApiMartApiBaseUrl:
          ApiEndpointNormalizer.normalizeApiMartBaseUrl(baseUrl),
      imageGenerationApiMartApiKey: apiKey.trim(),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationModel(String model) async {
    final next = value.copyWith(imageGenerationModel: model.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> saveImageGenerationApiConfigs({
    required List<ImageGenerationApiConfig> configs,
    required String activeConfigId,
  }) async {
    if (configs.isEmpty ||
        !configs.any((config) => config.id == activeConfigId)) {
      throw ArgumentError('请至少保留一张有效的图片生成 API 卡片');
    }
    final active = configs.firstWhere((config) => config.id == activeConfigId);
    final next = value.copyWith(
      imageGenerationApiConfigs: List.unmodifiable(configs),
      activeImageGenerationApiConfigId: active.id,
      imageGenerationModel: active.model,
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setImageGenerationSettings({
    required String baseUrl,
    required String grsaiApiKey,
    String? geminiBaseUrl,
    required String geminiApiKey,
    String? apiMartBaseUrl,
    String? apiMartApiKey,
    required String model,
  }) async {
    final next = value.copyWith(
      imageGenerationApiBaseUrl: baseUrl.trim(),
      imageGenerationApiKey: grsaiApiKey.trim(),
      imageGenerationGeminiApiBaseUrl: geminiBaseUrl?.trim(),
      imageGenerationGeminiApiKey: geminiApiKey.trim(),
      imageGenerationApiMartApiBaseUrl: apiMartBaseUrl == null
          ? null
          : ApiEndpointNormalizer.normalizeApiMartBaseUrl(apiMartBaseUrl),
      imageGenerationApiMartApiKey: apiMartApiKey?.trim(),
      imageGenerationModel: model.trim(),
    );
    _repository.save(next);
    value = next;
  }

  Future<void> setUpdateReleaseApiUrl(String apiUrl) async {
    final next = value.copyWith(updateReleaseApiUrl: apiUrl.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> setAutoInstallUpdates(bool enabled) async {
    final next = value.copyWith(autoInstallUpdates: enabled);
    _repository.save(next);
    value = next;
  }

  Future<void> setUpdateDownloadMode(UpdateDownloadMode mode) async {
    final next = value.copyWith(updateDownloadMode: mode);
    _repository.save(next);
    value = next;
  }

  Future<void> setUpdateManualProxyUrl(String proxyUrl) async {
    final next = value.copyWith(updateManualProxyUrl: proxyUrl.trim());
    _repository.save(next);
    value = next;
  }

  Future<void> resetToDefaults() async {
    final next = _repository.defaults();
    _repository.save(next);
    value = next;
  }
}
