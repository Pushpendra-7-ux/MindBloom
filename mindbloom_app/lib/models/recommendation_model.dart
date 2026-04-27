class Recommendation {
  final String title;
  final String? author;
  final String? duration;
  final String? frequency;
  final String description;
  final String icon;

  Recommendation({
    required this.title,
    this.author,
    this.duration,
    this.frequency,
    required this.description,
    this.icon = 'book',
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? '',
      author: json['author'],
      duration: json['duration'],
      frequency: json['frequency'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'book',
    );
  }
}

class RecommendationSet {
  final List<Recommendation> books;
  final List<Recommendation> physical;
  final List<Recommendation> mindSpirit;
  final List<Recommendation> lifestyle;
  final String summary;

  RecommendationSet({
    required this.books,
    required this.physical,
    required this.mindSpirit,
    required this.lifestyle,
    required this.summary,
  });

  factory RecommendationSet.fromJson(Map<String, dynamic> json) {
    return RecommendationSet(
      books: (json['books'] as List? ?? []).map((e) => Recommendation.fromJson(e)).toList(),
      physical: (json['physical'] as List? ?? []).map((e) => Recommendation.fromJson(e)).toList(),
      mindSpirit: (json['mindSpirit'] as List? ?? []).map((e) => Recommendation.fromJson(e)).toList(),
      lifestyle: (json['lifestyle'] as List? ?? []).map((e) => Recommendation.fromJson(e)).toList(),
      summary: json['summary'] ?? '',
    );
  }
}
