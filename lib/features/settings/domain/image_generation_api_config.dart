import 'package:uuid/uuid.dart';

enum ImageGenerationApiType {
  grsai('GRSai'),
  gemini('Gemini'),
  apiMart('APIMart');

  const ImageGenerationApiType(this.label);
  final String label;
}

class ImageGenerationApiConfig {
  ImageGenerationApiConfig({
    String? id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final ImageGenerationApiType type;
  final String baseUrl;
  final String apiKey;
  final String model;

  ImageGenerationApiConfig copyWith({
    String? name,
    ImageGenerationApiType? type,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) => ImageGenerationApiConfig(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    baseUrl: baseUrl ?? this.baseUrl,
    apiKey: apiKey ?? this.apiKey,
    model: model ?? this.model,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
  };

  factory ImageGenerationApiConfig.fromJson(Map<String, Object?> json) =>
      ImageGenerationApiConfig(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '未命名图片生成 API',
        type: ImageGenerationApiType.values.firstWhere(
          (type) => type.name == json['type']?.toString(),
          orElse: () => ImageGenerationApiType.grsai,
        ),
        baseUrl: json['baseUrl']?.toString() ?? '',
        apiKey: json['apiKey']?.toString() ?? '',
        model: json['model']?.toString() ?? '',
      );
}
