import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('gu'),
    Locale('hi')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Grahvani'**
  String get appName;

  /// Home screen greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Chart screen title
  ///
  /// In en, this message translates to:
  /// **'Birth Chart'**
  String get birthChart;

  /// Dasha tab label
  ///
  /// In en, this message translates to:
  /// **'Dashas'**
  String get dashas;

  /// Chart tab label
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get chart;

  /// AI chat button tooltip
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAI;

  /// PDF export button tooltip
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPDF;

  /// Ayanamsa selector tooltip
  ///
  /// In en, this message translates to:
  /// **'Switch Ayanamsa'**
  String get switchAyanamsa;

  /// Sade Sati button tooltip
  ///
  /// In en, this message translates to:
  /// **'Sade Sati Tracker'**
  String get sadeSatiTracker;

  /// Notifications screen title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Mark all notifications read button
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// Clear all notifications
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// Kundali Milan screen title
  ///
  /// In en, this message translates to:
  /// **'Kundali Milan'**
  String get kundaliMilan;

  /// Profile picker placeholder
  ///
  /// In en, this message translates to:
  /// **'Select person'**
  String get selectPerson;

  /// Varshaphal screen title
  ///
  /// In en, this message translates to:
  /// **'Varshaphal'**
  String get varshaphal;

  /// Solar Return subtitle
  ///
  /// In en, this message translates to:
  /// **'Solar Return'**
  String get solarReturn;

  /// Synastry screen title
  ///
  /// In en, this message translates to:
  /// **'Synastry'**
  String get synastry;

  /// Voice AI screen title
  ///
  /// In en, this message translates to:
  /// **'Voice AI'**
  String get voiceAI;

  /// Voice AI idle hint
  ///
  /// In en, this message translates to:
  /// **'Tap the mic and ask anything about your chart'**
  String get tapMicToAsk;

  /// Voice AI listening state
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// Voice AI processing state
  ///
  /// In en, this message translates to:
  /// **'Grahvani AI is thinking…'**
  String get processing;

  /// Voice AI speaking state
  ///
  /// In en, this message translates to:
  /// **'Speaking response…'**
  String get speaking;

  /// Upgrade/premium button
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// Paywall title
  ///
  /// In en, this message translates to:
  /// **'Unlock Grahvani Premium'**
  String get unlockPremium;

  /// Monthly subscription option
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// Yearly subscription option
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// Paywall fine print
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. No hidden fees.'**
  String get cancelAnytime;

  /// North Indian chart style toggle
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get northStyle;

  /// South Indian chart style toggle
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get southStyle;

  /// Varshaphal annual chart tab
  ///
  /// In en, this message translates to:
  /// **'Annual Chart'**
  String get annualChart;

  /// Varshaphal predictions tab
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get predictions;

  /// Synastry aspects tab
  ///
  /// In en, this message translates to:
  /// **'Aspects'**
  String get aspects;

  /// Synastry charts tab
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// Profiles screen title
  ///
  /// In en, this message translates to:
  /// **'Birth Profiles'**
  String get birthProfiles;

  /// Add profile FAB label
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfile;

  /// Consent screen title
  ///
  /// In en, this message translates to:
  /// **'Your Privacy, Our Promise'**
  String get consentTitle;

  /// First person in Kundali Milan
  ///
  /// In en, this message translates to:
  /// **'Person 1'**
  String get person1;

  /// Second person in Kundali Milan
  ///
  /// In en, this message translates to:
  /// **'Person 2'**
  String get person2;

  /// Kundali Milan total score label
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalScore;

  /// Synastry harmonious aspect
  ///
  /// In en, this message translates to:
  /// **'Harmonious'**
  String get harmonious;

  /// Synastry tense aspect
  ///
  /// In en, this message translates to:
  /// **'Tense'**
  String get tense;

  /// Synastry key aspects heading
  ///
  /// In en, this message translates to:
  /// **'Key Aspects'**
  String get keyAspects;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
