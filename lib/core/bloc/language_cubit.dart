import 'package:bloc/bloc.dart';
import '../data/hive_database.dart';

enum AppLanguage { english, urdu }

class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit() : super(_loadLanguage());

  static AppLanguage _loadLanguage() {
    final saved = HiveDatabase.settingsBox.get('app_language') as String?;
    return saved == 'urdu' ? AppLanguage.urdu : AppLanguage.english;
  }

  void _saveLanguage(AppLanguage language) {
    HiveDatabase.settingsBox
        .put('app_language', language == AppLanguage.urdu ? 'urdu' : 'english');
  }

  void toggleLanguage() {
    final next =
        state == AppLanguage.english ? AppLanguage.urdu : AppLanguage.english;
    emit(next);
    _saveLanguage(next);
  }

  void setLanguage(AppLanguage language) {
    emit(language);
    _saveLanguage(language);
  }
}
