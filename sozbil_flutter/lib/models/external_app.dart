class ExternalAppModel {
  final int id;
  final String name;
  final String description;
  final String? logoUrl;
  final String iosUrl;
  final String androidUrl;

  const ExternalAppModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.iosUrl,
    required this.androidUrl,
  });

  factory ExternalAppModel.fromJson(Map<String, dynamic> j) => ExternalAppModel(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        description: j['description'] ?? '',
        logoUrl: j['logo_url'],
        iosUrl: j['ios_url'] ?? '',
        androidUrl: j['android_url'] ?? '',
      );
}
