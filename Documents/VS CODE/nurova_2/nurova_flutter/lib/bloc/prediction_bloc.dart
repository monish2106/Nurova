import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/prediction_model.dart';
import '../services/api_service.dart';

// Events
abstract class PredictionEvent {}
class FetchPredictionEvent extends PredictionEvent {
  final Map<String, dynamic> features;
  FetchPredictionEvent(this.features);
}
class FetchPersonalityEvent extends PredictionEvent {
  final List<Map<String, dynamic>> history;
  FetchPersonalityEvent(this.history);
}

// States
abstract class PredictionState {}
class PredictionInitial extends PredictionState {}
class PredictionLoading extends PredictionState {}
class PredictionLoaded extends PredictionState {
  final PredictionModel prediction;
  final PersonalityModel? personality;
  PredictionLoaded(this.prediction, {this.personality});
}
class PredictionError extends PredictionState {
  final String message;
  PredictionError(this.message);
}

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  PredictionModel? _lastPrediction;
  PersonalityModel? _lastPersonality;

  PredictionBloc() : super(PredictionInitial()) {
    on<FetchPredictionEvent>(_onFetchPrediction);
    on<FetchPersonalityEvent>(_onFetchPersonality);
  }

  Future<void> _onFetchPrediction(
      FetchPredictionEvent e, Emitter<PredictionState> emit) async {
    emit(PredictionLoading());
    try {
      final prediction = await ApiService.predictDistraction(e.features);
      _lastPrediction = prediction;
      emit(PredictionLoaded(prediction, personality: _lastPersonality));
    } catch (err) {
      // Fallback to local calculation if API unavailable
      _lastPrediction = _localPredict(e.features);
      emit(PredictionLoaded(_lastPrediction!, personality: _lastPersonality));
    }
  }

  Future<void> _onFetchPersonality(
      FetchPersonalityEvent e, Emitter<PredictionState> emit) async {
    try {
      final personality = await ApiService.getPersonality(e.history);
      _lastPersonality = personality;
      if (_lastPrediction != null) {
        emit(PredictionLoaded(_lastPrediction!, personality: personality));
      }
    } catch (_) {
      _lastPersonality = _localPersonality(e.history);
      if (_lastPrediction != null) {
        emit(PredictionLoaded(_lastPrediction!, personality: _lastPersonality));
      }
    }
  }

  PredictionModel _localPredict(Map<String, dynamic> f) {
    // Simple heuristic fallback
    double risk = 0.3;
    final screenTime = (f['screen_time'] as num?)?.toDouble() ?? 3;
    final mood = (f['mood_score'] as num?)?.toDouble() ?? 5;
    final hour = (f['time_of_day'] as num?)?.toDouble() ?? 12;

    if (screenTime > 8) risk += 0.25;
    if (screenTime > 12) risk += 0.2;
    if (mood < 4) risk += 0.15;
    if (hour > 22 || hour < 5) risk += 0.2;
    risk = risk.clamp(0.0, 0.99);

    String action;
    if (risk > 0.75) action = 'HIGH_RISK';
    else if (risk > 0.45) action = 'MEDIUM_RISK';
    else action = 'LOW_RISK';

    return PredictionModel(riskProbability: risk, action: action);
  }

  PersonalityModel _localPersonality(List<Map<String, dynamic>> history) {
    return PersonalityModel(
      cluster: 'ProcrastinationBinger',
      traits: ['Delays tasks', 'High social media use', 'Bursts of productivity'],
      emoji: '📱',
    );
  }
}
