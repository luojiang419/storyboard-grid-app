enum AppThemePreference {
  system('跟随系统'),
  light('浅色'),
  dark('暗黑');

  const AppThemePreference(this.label);

  final String label;

  static AppThemePreference fromName(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

enum CutImageNumberPosition {
  topLeft('左上'),
  bottomLeft('左下'),
  topRight('右上'),
  bottomRight('右下'),
  center('中间');

  const CutImageNumberPosition(this.label);

  final String label;

  static CutImageNumberPosition fromName(String? value) {
    return CutImageNumberPosition.values.firstWhere(
      (position) => position.name == value,
      orElse: () => CutImageNumberPosition.topLeft,
    );
  }
}

enum UpdateDownloadMode {
  automatic('自动检测代理'),
  manual('手动代理'),
  direct('直连');

  const UpdateDownloadMode(this.label);

  final String label;

  static UpdateDownloadMode fromName(String? value) {
    return UpdateDownloadMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => UpdateDownloadMode.automatic,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.exportDirectory,
    required this.themePreference,
    required this.cutImageNumberEnabled,
    required this.cutImageNumberPosition,
    required this.cutImageNumberBackgroundOpacity,
    required this.cutImageNumberTextScale,
    this.storyboardCaptionNumberEnabled = true,
    required this.storyboardSummaryPageEnabled,
    required this.visionApiBaseUrl,
    required this.visionApiKey,
    required this.visionModel,
    required this.imageGenerationApiBaseUrl,
    required this.imageGenerationApiKey,
    this.imageGenerationGeminiApiBaseUrl =
        defaultImageGenerationGeminiApiBaseUrl,
    required this.imageGenerationGeminiApiKey,
    this.imageGenerationApiMartApiBaseUrl =
        defaultImageGenerationApiMartApiBaseUrl,
    this.imageGenerationApiMartApiKey = '',
    required this.imageGenerationModel,
    required this.updateReleaseApiUrl,
    required this.autoInstallUpdates,
    required this.updateDownloadMode,
    required this.updateManualProxyUrl,
  });

  static const defaultCutImageNumberBackgroundOpacity = 0.5;
  static const defaultCutImageNumberTextScale = 1.0;
  static const defaultImageGenerationApiMartApiBaseUrl =
      'https://api.apimart.ai';
  static const defaultImageGenerationGeminiApiBaseUrl =
      'https://www.shiying-api.com';

  final String exportDirectory;
  final AppThemePreference themePreference;
  final bool cutImageNumberEnabled;
  final CutImageNumberPosition cutImageNumberPosition;
  final double cutImageNumberBackgroundOpacity;
  final double cutImageNumberTextScale;
  final bool storyboardCaptionNumberEnabled;
  final bool storyboardSummaryPageEnabled;
  final String visionApiBaseUrl;
  final String visionApiKey;
  final String visionModel;
  final String imageGenerationApiBaseUrl;
  final String imageGenerationApiKey;
  final String imageGenerationGeminiApiBaseUrl;
  final String imageGenerationGeminiApiKey;
  final String imageGenerationApiMartApiBaseUrl;
  final String imageGenerationApiMartApiKey;
  final String imageGenerationModel;
  final String updateReleaseApiUrl;
  final bool autoInstallUpdates;
  final UpdateDownloadMode updateDownloadMode;
  final String updateManualProxyUrl;

  AppSettings copyWith({
    String? exportDirectory,
    AppThemePreference? themePreference,
    bool? cutImageNumberEnabled,
    CutImageNumberPosition? cutImageNumberPosition,
    double? cutImageNumberBackgroundOpacity,
    double? cutImageNumberTextScale,
    bool? storyboardCaptionNumberEnabled,
    bool? storyboardSummaryPageEnabled,
    String? visionApiBaseUrl,
    String? visionApiKey,
    String? visionModel,
    String? imageGenerationApiBaseUrl,
    String? imageGenerationApiKey,
    String? imageGenerationGeminiApiBaseUrl,
    String? imageGenerationGeminiApiKey,
    String? imageGenerationApiMartApiBaseUrl,
    String? imageGenerationApiMartApiKey,
    String? imageGenerationModel,
    String? updateReleaseApiUrl,
    bool? autoInstallUpdates,
    UpdateDownloadMode? updateDownloadMode,
    String? updateManualProxyUrl,
  }) {
    return AppSettings(
      exportDirectory: exportDirectory ?? this.exportDirectory,
      themePreference: themePreference ?? this.themePreference,
      cutImageNumberEnabled:
          cutImageNumberEnabled ?? this.cutImageNumberEnabled,
      cutImageNumberPosition:
          cutImageNumberPosition ?? this.cutImageNumberPosition,
      cutImageNumberBackgroundOpacity:
          cutImageNumberBackgroundOpacity ??
          this.cutImageNumberBackgroundOpacity,
      cutImageNumberTextScale:
          cutImageNumberTextScale ?? this.cutImageNumberTextScale,
      storyboardCaptionNumberEnabled:
          storyboardCaptionNumberEnabled ?? this.storyboardCaptionNumberEnabled,
      storyboardSummaryPageEnabled:
          storyboardSummaryPageEnabled ?? this.storyboardSummaryPageEnabled,
      visionApiBaseUrl: visionApiBaseUrl ?? this.visionApiBaseUrl,
      visionApiKey: visionApiKey ?? this.visionApiKey,
      visionModel: visionModel ?? this.visionModel,
      imageGenerationApiBaseUrl:
          imageGenerationApiBaseUrl ?? this.imageGenerationApiBaseUrl,
      imageGenerationApiKey:
          imageGenerationApiKey ?? this.imageGenerationApiKey,
      imageGenerationGeminiApiBaseUrl:
          imageGenerationGeminiApiBaseUrl ??
          this.imageGenerationGeminiApiBaseUrl,
      imageGenerationGeminiApiKey:
          imageGenerationGeminiApiKey ?? this.imageGenerationGeminiApiKey,
      imageGenerationApiMartApiBaseUrl:
          imageGenerationApiMartApiBaseUrl ??
          this.imageGenerationApiMartApiBaseUrl,
      imageGenerationApiMartApiKey:
          imageGenerationApiMartApiKey ?? this.imageGenerationApiMartApiKey,
      imageGenerationModel: imageGenerationModel ?? this.imageGenerationModel,
      updateReleaseApiUrl: updateReleaseApiUrl ?? this.updateReleaseApiUrl,
      autoInstallUpdates: autoInstallUpdates ?? this.autoInstallUpdates,
      updateDownloadMode: updateDownloadMode ?? this.updateDownloadMode,
      updateManualProxyUrl: updateManualProxyUrl ?? this.updateManualProxyUrl,
    );
  }
}
