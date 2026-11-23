import '../../settings/domain/app_settings.dart';
import '../../settings/domain/image_generation_api_config.dart';
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
    final active = settings.activeImageGenerationApiConfig;
    if (active != null) {
      final activeProtocol = switch (active.type) {
        ImageGenerationApiType.gemini => ImageGenerationProviderProtocol.gemini,
        ImageGenerationApiType.grsai => ImageGenerationProviderProtocol.grsai,
        ImageGenerationApiType.apiMart =>
          ImageGenerationProviderProtocol.apiMart,
      };
      if (activeProtocol != descriptor.protocol) {
        throw FormatException(
          '当前默认图片 API 卡片“${active.name}”与模型 $model 的服务商不匹配',
        );
      }
      return ImageGenerationProviderConnection(
        providerId: descriptor.providerId,
        providerLabel: providerLabel,
        protocol: descriptor.protocol,
        apiBaseUrl: active.baseUrl,
        apiKey: active.apiKey,
      );
    }
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
