import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/services/app_directories.dart';
import '../../updater/domain/app_update_config.dart';
import '../domain/app_settings.dart';
import '../domain/vision_api_config.dart';
import '../domain/image_generation_api_config.dart';

class SettingsRepository {
  const SettingsRepository(
    this._database,
    this._directories, {
    String? visionDefaultsText,
    String? imageGenerationDefaultsText,
  }) : _visionDefaultsText = visionDefaultsText,
       _imageGenerationDefaultsText = imageGenerationDefaultsText;

  final AppDatabase _database;
  final AppDirectories _directories;
  final String? _visionDefaultsText;
  final String? _imageGenerationDefaultsText;

  static const _exportDirectoryKey = 'exportDirectory';
  static const _themePreferenceKey = 'themePreference';
  static const _cutImageNumberEnabledKey = 'cutImageNumberEnabled';
  static const _cutImageNumberPositionKey = 'cutImageNumberPosition';
  static const _cutImageNumberBackgroundOpacityKey =
      'cutImageNumberBackgroundOpacity';
  static const _cutImageNumberTextScaleKey = 'cutImageNumberTextScale';
  static const _storyboardCaptionNumberEnabledKey =
      'storyboardCaptionNumberEnabled';
  static const _storyboardSummaryPageEnabledKey =
      'storyboardSummaryPageEnabled';
  static const _visionApiBaseUrlKey = 'visionApiBaseUrl';
  static const _visionApiKeyKey = 'visionApiKey';
  static const _visionModelKey = 'visionModel';
  static const _visionApiConfigsKey = 'visionApiConfigs';
  static const _activeVisionApiConfigIdKey = 'activeVisionApiConfigId';
  static const _imageGenerationApiBaseUrlKey = 'imageGenerationApiBaseUrl';
  static const _imageGenerationApiKeyKey = 'imageGenerationApiKey';
  static const _imageGenerationGeminiApiBaseUrlKey =
      'imageGenerationGeminiApiBaseUrl';
  static const _imageGenerationGeminiApiKeyKey = 'imageGenerationGeminiApiKey';
  static const _imageGenerationApiMartApiBaseUrlKey =
      'imageGenerationApiMartApiBaseUrl';
  static const _imageGenerationApiMartApiKeyKey =
      'imageGenerationApiMartApiKey';
  static const _imageGenerationModelKey = 'imageGenerationModel';
  static const _imageGenerationApiConfigsKey = 'imageGenerationApiConfigs';
  static const _activeImageGenerationApiConfigIdKey =
      'activeImageGenerationApiConfigId';
  static const _updateReleaseApiUrlKey = 'updateReleaseApiUrl';
  static const _autoInstallUpdatesKey = 'autoInstallUpdates';
  static const _updateDownloadModeKey = 'updateDownloadMode';
  static const _updateManualProxyUrlKey = 'updateManualProxyUrl';
  static const _downloadedUpdateVersionKey = 'downloadedUpdateVersion';
  static const _pendingUpdateVersionKey = 'pendingUpdateVersion';
  static const _pendingUpdateInstallerPathKey = 'pendingUpdateInstallerPath';
  static const _dismissedUpdatePromptVersionKey =
      'dismissedUpdatePromptVersion';

  AppSettings load() {
    final visionDefaults = _loadVisionDefaults();
    final imageGenerationDefaults = _loadImageGenerationDefaults();
    final visionBaseUrl = _getSettingWithImportedDefault(
      _visionApiBaseUrlKey,
      visionDefaults.baseUrl,
    );
    final visionApiKey = _getSettingWithImportedDefault(
      _visionApiKeyKey,
      visionDefaults.apiKey,
    );
    final visionModel = _getSettingWithImportedDefault(
      _visionModelKey,
      visionDefaults.model,
    );
    final visionConfigs = _loadVisionApiConfigs(
      baseUrl: visionBaseUrl,
      apiKey: visionApiKey,
      model: visionModel,
    );
    final activeVisionConfigId = _activeVisionConfigId(visionConfigs);
    final imageModel = _getSettingWithImportedDefault(
      _imageGenerationModelKey,
      imageGenerationDefaults.model,
    );
    final imageConfigs = _loadImageGenerationApiConfigs(
      model: imageModel,
      grsaiBaseUrl: _getSettingWithImportedDefault(
        _imageGenerationApiBaseUrlKey,
        imageGenerationDefaults.baseUrl,
      ),
      grsaiApiKey: _getSettingWithImportedDefault(
        _imageGenerationApiKeyKey,
        imageGenerationDefaults.apiKey,
      ),
      geminiBaseUrl:
          _database.getSetting(_imageGenerationGeminiApiBaseUrlKey) ??
          AppSettings.defaultImageGenerationGeminiApiBaseUrl,
      geminiApiKey: _database.getSetting(_imageGenerationGeminiApiKeyKey) ?? '',
      apiMartBaseUrl:
          _database.getSetting(_imageGenerationApiMartApiBaseUrlKey) ??
          AppSettings.defaultImageGenerationApiMartApiBaseUrl,
      apiMartApiKey:
          _database.getSetting(_imageGenerationApiMartApiKeyKey) ?? '',
    );
    final activeImageConfigId = _activeImageGenerationConfigId(imageConfigs);
    return AppSettings(
      exportDirectory:
          _database.getSetting(_exportDirectoryKey) ??
          _directories.exports.path,
      themePreference: AppThemePreference.fromName(
        _database.getSetting(_themePreferenceKey),
      ),
      cutImageNumberEnabled:
          _database.getSetting(_cutImageNumberEnabledKey) == 'true',
      cutImageNumberPosition: CutImageNumberPosition.fromName(
        _database.getSetting(_cutImageNumberPositionKey),
      ),
      cutImageNumberBackgroundOpacity: _getDoubleSetting(
        _cutImageNumberBackgroundOpacityKey,
        AppSettings.defaultCutImageNumberBackgroundOpacity,
      ),
      cutImageNumberTextScale: _getDoubleSetting(
        _cutImageNumberTextScaleKey,
        AppSettings.defaultCutImageNumberTextScale,
        min: 0.7,
        max: 1.6,
      ),
      storyboardCaptionNumberEnabled:
          _database.getSetting(_storyboardCaptionNumberEnabledKey) != 'false',
      storyboardSummaryPageEnabled:
          _database.getSetting(_storyboardSummaryPageEnabledKey) != 'false',
      visionApiBaseUrl: visionBaseUrl,
      visionApiKey: visionApiKey,
      visionModel: visionModel,
      visionApiConfigs: visionConfigs,
      activeVisionApiConfigId: activeVisionConfigId,
      imageGenerationApiBaseUrl: _getSettingWithImportedDefault(
        _imageGenerationApiBaseUrlKey,
        imageGenerationDefaults.baseUrl,
      ),
      imageGenerationApiKey: _getSettingWithImportedDefault(
        _imageGenerationApiKeyKey,
        imageGenerationDefaults.apiKey,
      ),
      imageGenerationGeminiApiBaseUrl:
          _database.getSetting(_imageGenerationGeminiApiBaseUrlKey) ??
          AppSettings.defaultImageGenerationGeminiApiBaseUrl,
      imageGenerationGeminiApiKey:
          _database.getSetting(_imageGenerationGeminiApiKeyKey) ?? '',
      imageGenerationApiMartApiBaseUrl:
          _database.getSetting(_imageGenerationApiMartApiBaseUrlKey) ??
          AppSettings.defaultImageGenerationApiMartApiBaseUrl,
      imageGenerationApiMartApiKey:
          _database.getSetting(_imageGenerationApiMartApiKeyKey) ?? '',
      imageGenerationModel: imageModel,
      imageGenerationApiConfigs: imageConfigs,
      activeImageGenerationApiConfigId: activeImageConfigId,
      updateReleaseApiUrl:
          _database.getSetting(_updateReleaseApiUrlKey) ??
          AppUpdateConfig.defaultReleaseRepositoryUrl,
      autoInstallUpdates:
          _database.getSetting(_autoInstallUpdatesKey) == 'true',
      updateDownloadMode: UpdateDownloadMode.fromName(
        _database.getSetting(_updateDownloadModeKey),
      ),
      updateManualProxyUrl:
          _database.getSetting(_updateManualProxyUrlKey) ??
          'http://127.0.0.1:7890',
    );
  }

  void save(AppSettings settings) {
    _database
      ..setSetting(_exportDirectoryKey, settings.exportDirectory)
      ..setSetting(_themePreferenceKey, settings.themePreference.name)
      ..setSetting(
        _cutImageNumberEnabledKey,
        settings.cutImageNumberEnabled.toString(),
      )
      ..setSetting(
        _cutImageNumberPositionKey,
        settings.cutImageNumberPosition.name,
      )
      ..setSetting(
        _cutImageNumberBackgroundOpacityKey,
        settings.cutImageNumberBackgroundOpacity.toStringAsFixed(2),
      )
      ..setSetting(
        _cutImageNumberTextScaleKey,
        settings.cutImageNumberTextScale.toStringAsFixed(2),
      )
      ..setSetting(
        _storyboardCaptionNumberEnabledKey,
        settings.storyboardCaptionNumberEnabled.toString(),
      )
      ..setSetting(
        _storyboardSummaryPageEnabledKey,
        settings.storyboardSummaryPageEnabled.toString(),
      )
      ..setSetting(_visionApiBaseUrlKey, settings.visionApiBaseUrl)
      ..setSetting(_visionApiKeyKey, settings.visionApiKey)
      ..setSetting(_visionModelKey, settings.visionModel)
      ..setSetting(
        _visionApiConfigsKey,
        jsonEncode(
          settings.visionApiConfigs.map((config) => config.toJson()).toList(),
        ),
      )
      ..setSetting(
        _activeVisionApiConfigIdKey,
        settings.activeVisionApiConfig?.id ?? '',
      )
      ..setSetting(
        _imageGenerationApiBaseUrlKey,
        settings.imageGenerationApiBaseUrl,
      )
      ..setSetting(_imageGenerationApiKeyKey, settings.imageGenerationApiKey)
      ..setSetting(
        _imageGenerationGeminiApiBaseUrlKey,
        settings.imageGenerationGeminiApiBaseUrl,
      )
      ..setSetting(
        _imageGenerationGeminiApiKeyKey,
        settings.imageGenerationGeminiApiKey,
      )
      ..setSetting(
        _imageGenerationApiMartApiBaseUrlKey,
        settings.imageGenerationApiMartApiBaseUrl,
      )
      ..setSetting(
        _imageGenerationApiMartApiKeyKey,
        settings.imageGenerationApiMartApiKey,
      )
      ..setSetting(_imageGenerationModelKey, settings.imageGenerationModel)
      ..setSetting(
        _imageGenerationApiConfigsKey,
        jsonEncode(
          settings.imageGenerationApiConfigs
              .map((config) => config.toJson())
              .toList(),
        ),
      )
      ..setSetting(
        _activeImageGenerationApiConfigIdKey,
        settings.activeImageGenerationApiConfig?.id ?? '',
      )
      ..setSetting(_updateReleaseApiUrlKey, settings.updateReleaseApiUrl)
      ..setSetting(
        _autoInstallUpdatesKey,
        settings.autoInstallUpdates.toString(),
      )
      ..setSetting(_updateDownloadModeKey, settings.updateDownloadMode.name)
      ..setSetting(_updateManualProxyUrlKey, settings.updateManualProxyUrl);
  }

  AppSettings defaults() {
    final visionDefaults = _loadVisionDefaults();
    final imageGenerationDefaults = _loadImageGenerationDefaults();
    final visionConfig = VisionApiConfig(
      id: 'default-vision-api',
      name: '默认视觉模型',
      baseUrl: visionDefaults.baseUrl,
      apiKey: visionDefaults.apiKey,
      model: visionDefaults.model,
    );
    return AppSettings(
      exportDirectory: _directories.exports.path,
      themePreference: AppThemePreference.system,
      cutImageNumberEnabled: false,
      cutImageNumberPosition: CutImageNumberPosition.topLeft,
      cutImageNumberBackgroundOpacity:
          AppSettings.defaultCutImageNumberBackgroundOpacity,
      cutImageNumberTextScale: AppSettings.defaultCutImageNumberTextScale,
      storyboardCaptionNumberEnabled: true,
      storyboardSummaryPageEnabled: true,
      visionApiBaseUrl: visionDefaults.baseUrl,
      visionApiKey: visionDefaults.apiKey,
      visionModel: visionDefaults.model,
      visionApiConfigs: [visionConfig],
      activeVisionApiConfigId: visionConfig.id,
      imageGenerationApiBaseUrl: imageGenerationDefaults.baseUrl,
      imageGenerationApiKey: imageGenerationDefaults.apiKey,
      imageGenerationGeminiApiBaseUrl:
          AppSettings.defaultImageGenerationGeminiApiBaseUrl,
      imageGenerationGeminiApiKey: '',
      imageGenerationApiMartApiBaseUrl:
          AppSettings.defaultImageGenerationApiMartApiBaseUrl,
      imageGenerationApiMartApiKey: '',
      imageGenerationModel: imageGenerationDefaults.model,
      updateReleaseApiUrl: AppUpdateConfig.defaultReleaseRepositoryUrl,
      autoInstallUpdates: false,
      updateDownloadMode: UpdateDownloadMode.automatic,
      updateManualProxyUrl: 'http://127.0.0.1:7890',
    );
  }

  String? downloadedUpdateVersion() {
    return _database.getSetting(_downloadedUpdateVersionKey);
  }

  String? pendingUpdateVersion() {
    return _database.getSetting(_pendingUpdateVersionKey);
  }

  String? pendingUpdateInstallerPath() {
    return _database.getSetting(_pendingUpdateInstallerPathKey);
  }

  String? dismissedUpdatePromptVersion() {
    return _database.getSetting(_dismissedUpdatePromptVersionKey);
  }

  void setDownloadedUpdateVersion(String versionTag) {
    _database.setSetting(_downloadedUpdateVersionKey, versionTag);
  }

  void setPendingUpdate({
    required String versionTag,
    required String installerPath,
  }) {
    _database
      ..setSetting(_pendingUpdateVersionKey, versionTag)
      ..setSetting(_pendingUpdateInstallerPathKey, installerPath);
  }

  void clearPendingUpdate() {
    _database
      ..setSetting(_pendingUpdateVersionKey, '')
      ..setSetting(_pendingUpdateInstallerPathKey, '');
  }

  void setDismissedUpdatePromptVersion(String versionTag) {
    _database.setSetting(_dismissedUpdatePromptVersionKey, versionTag);
  }

  void clearDismissedUpdatePromptVersion() {
    _database.setSetting(_dismissedUpdatePromptVersionKey, '');
  }

  String _getSettingWithImportedDefault(String key, String defaultValue) {
    final value = _database.getSetting(key);
    if (value != null) {
      return value;
    }
    if (defaultValue.isNotEmpty) {
      _database.setSetting(key, defaultValue);
    }
    return defaultValue;
  }

  double _getDoubleSetting(
    String key,
    double defaultValue, {
    double min = 0,
    double max = 1,
  }) {
    final value = double.tryParse(_database.getSetting(key) ?? '');
    return (value ?? defaultValue).clamp(min, max).toDouble();
  }

  List<VisionApiConfig> _loadVisionApiConfigs({
    required String baseUrl,
    required String apiKey,
    required String model,
  }) {
    final raw = _database.getSetting(_visionApiConfigsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final configs = decoded
              .whereType<Map>()
              .map(
                (item) => VisionApiConfig.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where((config) => config.id.trim().isNotEmpty)
              .toList();
          if (configs.isNotEmpty) {
            return configs;
          }
        }
      } on FormatException {
        // 损坏的配置会回退到旧版单配置，并在下次保存时被修复。
      }
    }
    return [
      VisionApiConfig(
        id: 'migrated-vision-api',
        name: '默认视觉模型',
        baseUrl: baseUrl,
        apiKey: apiKey,
        model: model,
      ),
    ];
  }

  String _activeVisionConfigId(List<VisionApiConfig> configs) {
    final saved = _database.getSetting(_activeVisionApiConfigIdKey) ?? '';
    return configs.any((config) => config.id == saved)
        ? saved
        : configs.first.id;
  }

  List<ImageGenerationApiConfig> _loadImageGenerationApiConfigs({
    required String model,
    required String grsaiBaseUrl,
    required String grsaiApiKey,
    required String geminiBaseUrl,
    required String geminiApiKey,
    required String apiMartBaseUrl,
    required String apiMartApiKey,
  }) {
    final raw = _database.getSetting(_imageGenerationApiConfigsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final configs = decoded
              .whereType<Map>()
              .map(
                (item) => ImageGenerationApiConfig.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList();
          if (configs.isNotEmpty) return configs;
        }
      } on FormatException {
        // 损坏的卡片配置会回退到旧版单配置。
      }
    }
    return [
      ImageGenerationApiConfig(
        id: 'migrated-image-api',
        name: '默认图片生成',
        type: ImageGenerationApiType.grsai,
        baseUrl: grsaiBaseUrl,
        apiKey: grsaiApiKey,
        model: model,
      ),
    ];
  }

  String _activeImageGenerationConfigId(
    List<ImageGenerationApiConfig> configs,
  ) {
    final saved =
        _database.getSetting(_activeImageGenerationApiConfigIdKey) ?? '';
    return configs.any((config) => config.id == saved)
        ? saved
        : configs.first.id;
  }

  _VisionApiDefaults _loadVisionDefaults() {
    final text = _visionDefaultsText ?? _readVisionDefaultsFile();
    if (text == null || text.trim().isEmpty) {
      return const _VisionApiDefaults.empty();
    }
    return _VisionApiDefaults.fromText(text);
  }

  _ImageGenerationApiDefaults _loadImageGenerationDefaults() {
    final text =
        _imageGenerationDefaultsText ?? _readImageGenerationDefaultsFile();
    if (text == null || text.trim().isEmpty) {
      return const _ImageGenerationApiDefaults.defaults();
    }
    return _ImageGenerationApiDefaults.fromText(text);
  }

  String? _readVisionDefaultsFile() {
    final candidates = [
      File(p.join(Directory.current.path, 'docs', '视觉模型api.md')),
      File(p.join(_directories.executableDirectory.path, 'docs', '视觉模型api.md')),
      File(
        p.join(
          _directories.executableDirectory.parent.path,
          'docs',
          '视觉模型api.md',
        ),
      ),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }
    return null;
  }

  String? _readImageGenerationDefaultsFile() {
    final candidates = [
      File(p.join(Directory.current.path, 'docs', 'api key.md')),
      File(p.join(_directories.executableDirectory.path, 'docs', 'api key.md')),
      File(
        p.join(
          _directories.executableDirectory.parent.path,
          'docs',
          'api key.md',
        ),
      ),
    ];
    for (final file in candidates) {
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    }
    return null;
  }
}

class _VisionApiDefaults {
  const _VisionApiDefaults({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  const _VisionApiDefaults.empty() : baseUrl = '', apiKey = '', model = '';

  final String baseUrl;
  final String apiKey;
  final String model;

  factory _VisionApiDefaults.fromText(String text) {
    return _VisionApiDefaults(
      baseUrl: _readValue(text, 'url'),
      apiKey: _readValue(text, 'key'),
      model: _readValue(text, '模型'),
    );
  }

  static String _readValue(String text, String key) {
    final pattern = RegExp(
      '^\\s*$key\\s*[:：]\\s*(.+?)\\s*\$',
      multiLine: true,
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }
}

class _ImageGenerationApiDefaults {
  const _ImageGenerationApiDefaults({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  const _ImageGenerationApiDefaults.defaults()
    : baseUrl = 'https://grsai.dakka.com.cn',
      apiKey = '',
      model = 'nano-banana-fast';

  final String baseUrl;
  final String apiKey;
  final String model;

  factory _ImageGenerationApiDefaults.fromText(String text) {
    final defaults = const _ImageGenerationApiDefaults.defaults();
    final section = _builtinSection(text, 'builtin-grsai-image');
    if (section == null || section.trim().isEmpty) {
      return defaults;
    }
    final url =
        _readFirstValue(section, const ['请求地址', 'url', '地址']) ??
        defaults.baseUrl;
    final key = _VisionApiDefaults._readValue(section, 'key');
    final model =
        _readFirstValue(section, const ['模型', 'model']) ?? defaults.model;
    return _ImageGenerationApiDefaults(
      baseUrl: url.trim().isEmpty ? defaults.baseUrl : url.trim(),
      apiKey: key,
      model: model.trim().isEmpty ? defaults.model : model.trim(),
    );
  }

  static String? _builtinSection(String text, String id) {
    final start = text.indexOf('`$id`');
    if (start < 0) {
      return null;
    }
    final afterStart = text.substring(start);
    final next = RegExp(r'\n\s*\d+\.\s+`').firstMatch(afterStart);
    if (next == null || next.start == 0) {
      return afterStart;
    }
    return afterStart.substring(0, next.start);
  }

  static String? _readFirstValue(String text, List<String> keys) {
    for (final key in keys) {
      final value = _VisionApiDefaults._readValue(text, key);
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
