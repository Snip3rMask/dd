class EpisodeItem {
  final int id;
  final int number;
  final int number2;
  final bool filler;
  final String title;
  final String embedUrl;
  final String hlsUrl;
  final String language;
  final String langName;

  const EpisodeItem({
    required this.id,
    required this.number,
    this.number2 = 0,
    this.filler = false,
    this.title = '',
    this.embedUrl = '',
    this.hlsUrl = '',
    this.language = '',
    this.langName = '',
  });

  String get label {
    if (number2 > 0 && number2 != number) {
      return '$number-$number2';
    }
    return number.toString();
  }

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    return EpisodeItem(
      id: json['id'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
      number2: json['number2'] as int? ?? 0,
      filler: json['filler'] as bool? ?? false,
      title: json['title']?.toString() ?? '',
      embedUrl: json['embed_url']?.toString() ?? '',
      hlsUrl: json['hls_url']?.toString() ?? '',
      language: json['language']?.toString() ?? '',
      langName: json['lang_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'number2': number2,
        'filler': filler,
        'title': title,
        'embed_url': embedUrl,
        'hls_url': hlsUrl,
        'language': language,
        'lang_name': langName,
      };
}
