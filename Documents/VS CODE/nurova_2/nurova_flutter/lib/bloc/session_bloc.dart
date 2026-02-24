import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/session_model.dart';
import '../services/api_service.dart';

// Events
abstract class SessionEvent {}
class StartSessionEvent extends SessionEvent {}
class TickSessionEvent extends SessionEvent {}
class UpdateMoodEvent extends SessionEvent { final int mood; UpdateMoodEvent(this.mood); }
class EndSessionEvent extends SessionEvent {}

// States
abstract class SessionState {}
class SessionInitial extends SessionState {}
class SessionRunning extends SessionState {
  final SessionModel session;
  SessionRunning(this.session);
}
class SessionEnded extends SessionState {
  final SessionModel session;
  SessionEnded(this.session);
}

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  Timer? _ticker;
  DateTime? _startTime;
  int _moodScore = 5;

  SessionBloc() : super(SessionInitial()) {
    on<StartSessionEvent>(_onStart);
    on<TickSessionEvent>(_onTick);
    on<UpdateMoodEvent>(_onMood);
    on<EndSessionEvent>(_onEnd);
  }

  void _onStart(StartSessionEvent e, Emitter<SessionState> emit) {
    _startTime = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => add(TickSessionEvent()));
    emit(SessionRunning(_buildSession()));
  }

  void _onTick(TickSessionEvent e, Emitter<SessionState> emit) {
    emit(SessionRunning(_buildSession()));
  }

  void _onMood(UpdateMoodEvent e, Emitter<SessionState> emit) {
    _moodScore = e.mood;
    if (state is SessionRunning) emit(SessionRunning(_buildSession()));
  }

  void _onEnd(EndSessionEvent e, Emitter<SessionState> emit) {
    _ticker?.cancel();
    emit(SessionEnded(_buildSession()));
  }

  SessionModel _buildSession() {
    final duration = DateTime.now().difference(_startTime ?? DateTime.now());
    final hours = duration.inHours + (duration.inMinutes % 60) / 60.0;
    return SessionModel(
      startTime: _startTime ?? DateTime.now(),
      currentDuration: duration,
      screenTimeHours: hours + 2.5, // simulate daily total
      moodScore: _moodScore,
      timeOfDay: DateTime.now().hour.toDouble(),
    );
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    return super.close();
  }
}
