import '../../settings/domain/app_settings.dart';
import 'image_generation_model_catalog.dart';

class ImageGenerationProviderResolver {
  const ImageGenerationProviderResolver._();

  static ImageGenerationProviderConnection resolve({
    required AppSettings settings,
    required String model,
  }) {
    final descriptor = ImageGenerationCatalog.descriptorFor(model);
    if (descriptor == null) {
      throw FormatException('不支持的图片生成模型：$model');
    }

    final providerLabel = ImageGenerationCatalog.providerLabelFor(model);
    return switch (descriptor.protocol) {
      ImageGenerationProviderProtocol.gemini =>
        ImageGenerationProviderConnection(
          providerId: descriptor.providerId,
          providerLabel: providerLabel,
          protocol: descriptor.protocol,
          apiBaseUrl: settings.imageGenerationGeminiApiBaseUrl,
          apiKey: settings.imageGenerationGeminiApiKey,
        ),
      ImageGenerationProviderProtocol.grsai =>
        ImageGenerationProviderConnection(
          providerId: descriptor.providerId,
          providerLabel: providerLabel,
          protocol: descriptor.protocol,
          apiBaseUrl: settings.imageGenerationApiBaseUrl,
          apiKey: settings.imageGenerationApiKey,
        ),
      ImageGenerationProviderProtocol.apiMart =>
        ImageGenerationProviderConnection(
          providerId: descriptor.providerId,
          providerLabel: providerLabel,
          protocol: descriptor.protocol,
          apiBaseUrl: settings.imageGenerationApiMartApiBaseUrl,
          apiKey: settings.imageGenerationApiMartApiKey,
        ),
    };
  }
}
