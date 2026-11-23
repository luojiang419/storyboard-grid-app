import 'package:uuid/uuid.dart';

class VisionApiConfig {
  VisionApiConfig({
    String? id,
    required this.name,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isMiniMaxM3 => model.trim().toLowerCase() == 'minimax-m3';

  VisionApiConfig copyWith({
    String? name,
    String? baseUrl,
    String? apiKey,
    String? model,
  }) {
    return VisionApiConfig(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
  };

  factory VisionApiConfig.fromJson(Map<String, Object?> json) {
    return VisionApiConfig(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '未命名视觉模型',
      baseUrl: json['baseUrl']?.toString() ?? '',
      apiKey: json['apiKey']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
    );
  }
}
