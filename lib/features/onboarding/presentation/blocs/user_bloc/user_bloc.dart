import 'dart:developer';
import 'package:consist/features/habit/domain/create_habit/repositories/habit_repository.dart';
import 'package:consist/features/onboarding/domain/entities/user_analytics_model.dart';
import 'package:consist/features/onboarding/domain/repository/user_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;
  final HabitRepository habitRepository;
  UserBloc({required this.userRepository, required this.habitRepository})
    : super(UserInitial()) {
    on<PageChangeEvent>(
      (event, emit) => emit(PageChangeState(pageIndex: event.pageIndex)),
    );
    on<ChooseAvatarEvent>(
      (event, emit) => emit(ChooseAvatarState(avatar: event.avatar)),
    );
    on<ProfileSetupEvent>((event, emit) async {
      emit(ProfileSetupLoadingState());
      try {
        final prefs = await SharedPreferences.getInstance();
        final result = await userRepository.setupUser(
          avatar: event.avatar,
          username: event.username,
        );
        await prefs.setString('userId', result);
        emit(ProfileSetupSuccessState());
      } catch (e) {
        emit(ProfileSetupErrorState(msg: 'Profile setup failed'));
      }
    });

    on<UserLoggedEvent>((event, emit) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs
            .setBool('isLogged', true)
            .then((value) => emit(UserLoggedState()));
      } catch (e) {
        log(e.toString());
      }
    });
    on<CheckUserLoginStatusEvent>((event, emit) async {
      emit(CheckUserLoginStatusLoadingState());
      try {
        final prefs = await SharedPreferences.getInstance();
        final isLogged = prefs.getBool('isLogged') ?? false;

        if (isLogged) {
          final result = await userRepository.checkAndUpdateDailyStats();
          if (result) {
            await Future.delayed(Duration(seconds: 2));
            emit(UserLoggedState());
          } else {
            emit(CheckUserLoginStatusErrorState(msg: 'Please try again'));
          }
        } else {
          final userId = prefs.getString('userId');
          if (userId != null && userId.isNotEmpty) {
            await Future.delayed(Duration(seconds: 2));
            emit(UserProfileCreatedState());
          } else {
            await Future.delayed(Duration(seconds: 2));
            emit(NewUserState());
          }
        }
      } catch (e) {
        log(e.toString());
        emit(CheckUserLoginStatusErrorState(msg: 'Please try again'));
      }
    });
    on<FetchUserProfileEvent>((event, emit) async {
      emit(FetchUserProfileLoadingState());
      try {
        final user = await userRepository.getCurrentUser();
        if (user != null) {
          emit(FetchUserProfileSuccessState(user: user));
        } else {
          emit(FetchUserProfileErrorState(msg: 'No user found'));
        }
      } catch (e) {
        emit(CheckUserLoginStatusErrorState(msg: 'Failed to fetch user'));
      }
    });
  }
}
