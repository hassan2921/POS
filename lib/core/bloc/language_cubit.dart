import 'package:bloc/bloc.dart';

enum AppLanguage { english, urdu }

class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit() : super(AppLanguage.english);

  void toggleLanguage() {
    emit(state == AppLanguage.english ? AppLanguage.urdu : AppLanguage.english);
  }

  void setLanguage(AppLanguage language) {
    emit(language);
  }
}
