import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_model.dart';
import '../services/api_service.dart';

class RecommendationState {
  final RecommendationSet? recommendations;
  final bool isLoading;
  final String? error;

  RecommendationState({this.recommendations, this.isLoading = false, this.error});
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final ApiService _api = ApiService();

  RecommendationNotifier() : super(RecommendationState());

  Future<void> fetchRecommendations({
    required int moodScore,
    List<String>? feelings,
    List<String>? activities,
    String? category,
  }) async {
    state = RecommendationState(isLoading: true);
    try {
      final response = await _api.getRecommendations({
        'moodScore': moodScore,
        'feelings': feelings,
        'activities': activities,
        'category': category,
      });
      final recs = RecommendationSet.fromJson(response.data['recommendations']);
      state = RecommendationState(recommendations: recs);
    } catch (e) {
      state = RecommendationState(error: 'Failed to load recommendations');
    }
  }
}

final recommendationProvider = StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier();
});
