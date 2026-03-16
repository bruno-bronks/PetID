import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'PetID'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bom dia!'**
  String get dashboardTitle;

  /// No description provided for @myPets.
  ///
  /// In pt, this message translates to:
  /// **'Meus Pets'**
  String get myPets;

  /// No description provided for @addPet.
  ///
  /// In pt, this message translates to:
  /// **'Novo Pet'**
  String get addPet;

  /// No description provided for @editPet.
  ///
  /// In pt, this message translates to:
  /// **'Editar Pet'**
  String get editPet;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @petName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do Pet'**
  String get petName;

  /// No description provided for @species.
  ///
  /// In pt, this message translates to:
  /// **'Espécie'**
  String get species;

  /// No description provided for @breed.
  ///
  /// In pt, this message translates to:
  /// **'Raça'**
  String get breed;

  /// No description provided for @sex.
  ///
  /// In pt, this message translates to:
  /// **'Sexo'**
  String get sex;

  /// No description provided for @weight.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get weight;

  /// No description provided for @birthDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de Nascimento'**
  String get birthDate;

  /// No description provided for @castrated.
  ///
  /// In pt, this message translates to:
  /// **'Castrado'**
  String get castrated;

  /// No description provided for @notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get notes;

  /// No description provided for @vaccines.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas'**
  String get vaccines;

  /// No description provided for @medications.
  ///
  /// In pt, this message translates to:
  /// **'Medicamentos'**
  String get medications;

  /// No description provided for @documents.
  ///
  /// In pt, this message translates to:
  /// **'Documentos'**
  String get documents;

  /// No description provided for @veterinarians.
  ///
  /// In pt, this message translates to:
  /// **'Veterinários'**
  String get veterinarians;

  /// No description provided for @biometry.
  ///
  /// In pt, this message translates to:
  /// **'Biometria'**
  String get biometry;

  /// No description provided for @info.
  ///
  /// In pt, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @records.
  ///
  /// In pt, this message translates to:
  /// **'Prontuário'**
  String get records;

  /// No description provided for @upcomingVaccines.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas Pendentes'**
  String get upcomingVaccines;

  /// No description provided for @overdueVaccines.
  ///
  /// In pt, this message translates to:
  /// **'Vacinas Atrasadas'**
  String get overdueVaccines;

  /// No description provided for @lostPets.
  ///
  /// In pt, this message translates to:
  /// **'Pets Perdidos'**
  String get lostPets;

  /// No description provided for @aiAssistant.
  ///
  /// In pt, this message translates to:
  /// **'PetID AI Assistant'**
  String get aiAssistant;

  /// No description provided for @askAi.
  ///
  /// In pt, this message translates to:
  /// **'Dúvidas sobre o seu pet? Pergunte à nossa inteligência artificial!'**
  String get askAi;

  /// No description provided for @howToGetThere.
  ///
  /// In pt, this message translates to:
  /// **'Como chegar'**
  String get howToGetThere;

  /// No description provided for @addToWallet.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao Wallet'**
  String get addToWallet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
