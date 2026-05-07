import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bci.dart';
import 'app_localizations_bm.dart';
import 'app_localizations_ff.dart';
import 'app_localizations_fr.dart';

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
    Locale('bci'),
    Locale('bm'),
    Locale('ff'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'AgroSmart'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @parcelles.
  ///
  /// In fr, this message translates to:
  /// **'Parcelles'**
  String get parcelles;

  /// No description provided for @sensors.
  ///
  /// In fr, this message translates to:
  /// **'Capteurs'**
  String get sensors;

  /// No description provided for @alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// No description provided for @marketplace.
  ///
  /// In fr, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @weather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get weather;

  /// No description provided for @weatherForecast.
  ///
  /// In fr, this message translates to:
  /// **'Prévisions météo'**
  String get weatherForecast;

  /// No description provided for @weatherAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes météorologiques'**
  String get weatherAlerts;

  /// No description provided for @temperature.
  ///
  /// In fr, this message translates to:
  /// **'Température'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get humidity;

  /// No description provided for @rainfall.
  ///
  /// In fr, this message translates to:
  /// **'Précipitations'**
  String get rainfall;

  /// No description provided for @wind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get wind;

  /// No description provided for @training.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get training;

  /// No description provided for @library.
  ///
  /// In fr, this message translates to:
  /// **'Bibliothèque'**
  String get library;

  /// No description provided for @myProgress.
  ///
  /// In fr, this message translates to:
  /// **'Ma progression'**
  String get myProgress;

  /// No description provided for @watchVideo.
  ///
  /// In fr, this message translates to:
  /// **'Regarder la vidéo'**
  String get watchVideo;

  /// No description provided for @downloadPDF.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le PDF'**
  String get downloadPDF;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get inProgress;

  /// No description provided for @formations.
  ///
  /// In fr, this message translates to:
  /// **'Formations'**
  String get formations;

  /// No description provided for @formationsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Modules de formation agricole'**
  String get formationsSubtitle;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @culture.
  ///
  /// In fr, this message translates to:
  /// **'Cultures'**
  String get culture;

  /// No description provided for @soil.
  ///
  /// In fr, this message translates to:
  /// **'Sol'**
  String get soil;

  /// No description provided for @irrigation.
  ///
  /// In fr, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @diseases.
  ///
  /// In fr, this message translates to:
  /// **'Maladies'**
  String get diseases;

  /// No description provided for @nutrition.
  ///
  /// In fr, this message translates to:
  /// **'Nutrition'**
  String get nutrition;

  /// No description provided for @beginner.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get advanced;

  /// No description provided for @chat.
  ///
  /// In fr, this message translates to:
  /// **'Messagerie'**
  String get chat;

  /// No description provided for @community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get community;

  /// No description provided for @forum.
  ///
  /// In fr, this message translates to:
  /// **'Forum'**
  String get forum;

  /// No description provided for @messages.
  ///
  /// In fr, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @newMessage.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau message'**
  String get newMessage;

  /// No description provided for @sendMessage.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get sendMessage;

  /// No description provided for @payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get payments;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get paymentMethod;

  /// No description provided for @orangeMoney.
  ///
  /// In fr, this message translates to:
  /// **'Orange Money'**
  String get orangeMoney;

  /// No description provided for @mtnMoney.
  ///
  /// In fr, this message translates to:
  /// **'MTN Money'**
  String get mtnMoney;

  /// No description provided for @moovMoney.
  ///
  /// In fr, this message translates to:
  /// **'Moov Money'**
  String get moovMoney;

  /// No description provided for @payNow.
  ///
  /// In fr, this message translates to:
  /// **'Payer maintenant'**
  String get payNow;

  /// No description provided for @paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get paymentFailed;

  /// No description provided for @groupPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Achats groupés'**
  String get groupPurchases;

  /// No description provided for @joinGroup.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get joinGroup;

  /// No description provided for @createGroup.
  ///
  /// In fr, this message translates to:
  /// **'Créer un groupe'**
  String get createGroup;

  /// No description provided for @participants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @objective.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get objective;

  /// No description provided for @saving.
  ///
  /// In fr, this message translates to:
  /// **'Économie'**
  String get saving;

  /// No description provided for @gamification.
  ///
  /// In fr, this message translates to:
  /// **'Récompenses'**
  String get gamification;

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @badges.
  ///
  /// In fr, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @leaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboard;

  /// No description provided for @achievements.
  ///
  /// In fr, this message translates to:
  /// **'Accomplissements'**
  String get achievements;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get level;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @noDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get noDataAvailable;

  /// No description provided for @tryAgain.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get tryAgain;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;
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
      <String>['bci', 'bm', 'ff', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bci':
      return AppLocalizationsBci();
    case 'bm':
      return AppLocalizationsBm();
    case 'ff':
      return AppLocalizationsFf();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
