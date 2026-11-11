import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'halfsizeX'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Compress to an exact size.'**
  String get tagline;

  /// No description provided for @tabCompress.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get tabCompress;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Make any video fit.'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a size. It works out the bitrate, drops the resolution, encodes twice.'**
  String get emptyBody;

  /// No description provided for @pickVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose video'**
  String get pickVideo;

  /// No description provided for @dropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop a video here'**
  String get dropHint;

  /// No description provided for @localOnly.
  ///
  /// In en, this message translates to:
  /// **'Local only. Nothing is uploaded.'**
  String get localOnly;

  /// No description provided for @localBadge.
  ///
  /// In en, this message translates to:
  /// **'Local · offline'**
  String get localBadge;

  /// No description provided for @pickHint.
  ///
  /// In en, this message translates to:
  /// **'MP4 · MOV · MKV · AVI · WebM'**
  String get pickHint;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @encoder.
  ///
  /// In en, this message translates to:
  /// **'Encoder'**
  String get encoder;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @targetSize.
  ///
  /// In en, this message translates to:
  /// **'Target size'**
  String get targetSize;

  /// No description provided for @platformPresets.
  ///
  /// In en, this message translates to:
  /// **'Platform presets'**
  String get platformPresets;

  /// No description provided for @codec.
  ///
  /// In en, this message translates to:
  /// **'Codec'**
  String get codec;

  /// No description provided for @preset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get preset;

  /// No description provided for @downscale.
  ///
  /// In en, this message translates to:
  /// **'Allow downscaling'**
  String get downscale;

  /// No description provided for @keepAudio.
  ///
  /// In en, this message translates to:
  /// **'Keep audio'**
  String get keepAudio;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Compress'**
  String get start;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @diagnosticsRun.
  ///
  /// In en, this message translates to:
  /// **'Check FFmpeg'**
  String get diagnosticsRun;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @upstream.
  ///
  /// In en, this message translates to:
  /// **'Upstream project'**
  String get upstream;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @ffmpegReady.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg ready'**
  String get ffmpegReady;

  /// No description provided for @ffmpegMissing.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg not found'**
  String get ffmpegMissing;

  /// No description provided for @ffmpegSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ffmpegSource;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in the next phase'**
  String get comingSoon;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'smaller'**
  String get saved;

  /// No description provided for @outputPath.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get outputPath;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @passOf.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get passOf;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get eta;

  /// No description provided for @warningAudioTracks.
  ///
  /// In en, this message translates to:
  /// **'Only the first audio track is kept.'**
  String get warningAudioTracks;

  /// No description provided for @warningSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles are not carried over.'**
  String get warningSubtitles;

  /// No description provided for @warningDownmix.
  ///
  /// In en, this message translates to:
  /// **'Audio is downmixed to stereo.'**
  String get warningDownmix;

  /// No description provided for @warningFpsCapped.
  ///
  /// In en, this message translates to:
  /// **'Frame rate is capped at 60 fps.'**
  String get warningFpsCapped;

  /// No description provided for @warningHdr.
  ///
  /// In en, this message translates to:
  /// **'HDR will be converted to SDR.'**
  String get warningHdr;

  /// No description provided for @warningAggressive.
  ///
  /// In en, this message translates to:
  /// **'This target is aggressive for the resolution.'**
  String get warningAggressive;

  /// No description provided for @warningNoDownscale.
  ///
  /// In en, this message translates to:
  /// **'Downscaling is off, so the target may be missed.'**
  String get warningNoDownscale;

  /// No description provided for @warningLowBitrate.
  ///
  /// In en, this message translates to:
  /// **'Very low bitrate. Try a larger target or H.265.'**
  String get warningLowBitrate;

  /// No description provided for @warningInfeasible.
  ///
  /// In en, this message translates to:
  /// **'This target is below the minimum for this duration.'**
  String get warningInfeasible;

  /// No description provided for @errorNotVideo.
  ///
  /// In en, this message translates to:
  /// **'This file is not a video.'**
  String get errorNotVideo;

  /// No description provided for @errorNoVideoStream.
  ///
  /// In en, this message translates to:
  /// **'No video stream found.'**
  String get errorNoVideoStream;

  /// No description provided for @errorNoDuration.
  ///
  /// In en, this message translates to:
  /// **'Could not read the duration.'**
  String get errorNoDuration;

  /// No description provided for @errorFfmpegMissing.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg was not found.'**
  String get errorFfmpegMissing;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorRenameFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not replace the output file.'**
  String get errorRenameFailed;

  /// No description provided for @errorEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg failed.'**
  String get errorEncodeFailed;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing…'**
  String get analyzing;

  /// No description provided for @compressing.
  ///
  /// In en, this message translates to:
  /// **'Compressing…'**
  String get compressing;

  /// No description provided for @chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get chooseAnother;

  /// No description provided for @fileInfo.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileInfo;

  /// No description provided for @resolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @videoBitrate.
  ///
  /// In en, this message translates to:
  /// **'Video bitrate'**
  String get videoBitrate;

  /// No description provided for @audioBitrate.
  ///
  /// In en, this message translates to:
  /// **'Audio bitrate'**
  String get audioBitrate;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @startOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get startOver;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @missedTarget.
  ///
  /// In en, this message translates to:
  /// **'The encoder could not reach the target.'**
  String get missedTarget;

  /// No description provided for @selectToBegin.
  ///
  /// In en, this message translates to:
  /// **'Select a video to begin.'**
  String get selectToBegin;

  /// No description provided for @targetTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Target is below the minimum.'**
  String get targetTooSmall;

  /// No description provided for @customSize.
  ///
  /// In en, this message translates to:
  /// **'Custom size'**
  String get customSize;

  /// No description provided for @invalidSize.
  ///
  /// In en, this message translates to:
  /// **'Cannot read that size.'**
  String get invalidSize;

  /// No description provided for @mode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get mode;

  /// No description provided for @modeSize.
  ///
  /// In en, this message translates to:
  /// **'Target size'**
  String get modeSize;

  /// No description provided for @modeCrf.
  ///
  /// In en, this message translates to:
  /// **'Quality (CRF)'**
  String get modeCrf;

  /// No description provided for @crfHint.
  ///
  /// In en, this message translates to:
  /// **'Lower CRF keeps more detail. 23 is balanced.'**
  String get crfHint;

  /// No description provided for @measuring.
  ///
  /// In en, this message translates to:
  /// **'Measuring quality…'**
  String get measuring;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualityIndistinguishable.
  ///
  /// In en, this message translates to:
  /// **'Indistinguishable'**
  String get qualityIndistinguishable;

  /// No description provided for @qualitySame.
  ///
  /// In en, this message translates to:
  /// **'Looks the same'**
  String get qualitySame;

  /// No description provided for @qualitySlight.
  ///
  /// In en, this message translates to:
  /// **'Slight softening'**
  String get qualitySlight;

  /// No description provided for @qualityVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible loss'**
  String get qualityVisible;

  /// No description provided for @qualityDegraded.
  ///
  /// In en, this message translates to:
  /// **'Clearly degraded'**
  String get qualityDegraded;

  /// No description provided for @qualityNone.
  ///
  /// In en, this message translates to:
  /// **'Not measured'**
  String get qualityNone;

  /// No description provided for @defaults.
  ///
  /// In en, this message translates to:
  /// **'Defaults'**
  String get defaults;

  /// No description provided for @defaultTarget.
  ///
  /// In en, this message translates to:
  /// **'Default target'**
  String get defaultTarget;

  /// No description provided for @defaultCodec.
  ///
  /// In en, this message translates to:
  /// **'Default codec'**
  String get defaultCodec;

  /// No description provided for @defaultPreset.
  ///
  /// In en, this message translates to:
  /// **'Default preset'**
  String get defaultPreset;

  /// No description provided for @outputDir.
  ///
  /// In en, this message translates to:
  /// **'Output folder'**
  String get outputDir;

  /// No description provided for @outputDirAuto.
  ///
  /// In en, this message translates to:
  /// **'Next to the source'**
  String get outputDirAuto;

  /// No description provided for @outputDirDownloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads/halfsizeX'**
  String get outputDirDownloads;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @presetFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get presetFast;

  /// No description provided for @presetMedium.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get presetMedium;

  /// No description provided for @presetSlow.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get presetSlow;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed'**
  String get elapsed;

  /// No description provided for @outputFile.
  ///
  /// In en, this message translates to:
  /// **'Output file'**
  String get outputFile;

  /// No description provided for @smaller.
  ///
  /// In en, this message translates to:
  /// **'smaller'**
  String get smaller;

  /// No description provided for @saveToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Save to Downloads'**
  String get saveToDownloads;

  /// No description provided for @qualityCheck.
  ///
  /// In en, this message translates to:
  /// **'Quality check (VMAF)'**
  String get qualityCheck;

  /// No description provided for @qualityCheckHint.
  ///
  /// In en, this message translates to:
  /// **'Measure quality after encoding. Slightly slower.'**
  String get qualityCheckHint;

  /// No description provided for @minimumNeeded.
  ///
  /// In en, this message translates to:
  /// **'This video needs at least {size}.'**
  String minimumNeeded(String size);

  /// No description provided for @raiseTarget.
  ///
  /// In en, this message translates to:
  /// **'Raise to {size}'**
  String raiseTarget(String size);

  /// No description provided for @encodeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Encode anyway'**
  String get encodeAnyway;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
