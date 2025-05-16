import 'package:hive/hive.dart';

part 'server_model.g.dart';

@HiveType(typeId: 1)
class ServerModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String configId;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final bool isActive;

  ServerModel({
    required this.id,
    required this.name,
    required this.configId,
    this.description = '',
    this.isActive = false,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      configId: json['configId'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'configId': configId,
      'description': description,
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

}