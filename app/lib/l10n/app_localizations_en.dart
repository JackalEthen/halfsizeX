// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'halfsizeX';

  @override
  String get tagline => 'Compress to an exact size.';

  @override
  String get tabCompress => 'Compress';

  @override
  String get tabSettings => 'Settings';

  @override
  String get emptyTitle => 'Make any video fit.';

  @override
  String get emptyBody =>
      'Pick a size. It works out the bitrate, drops the resolution, encodes twice.';

  @override
  String get pickVideo => 'Choose video';

  @override
  String get dropHint => 'Drop a video here';

  @override
  String get localOnly => 'Local only. Nothing is uploaded.';

  @override
  String get localBadge => 'Local · offline';

  @override
  String get pickHint => 'MP4 · MOV · MKV · AVI · WebM';

  @override
  String get custom => 'Custom';

  @override
  String get checking => 'Checking…';

  @override
  String get encoder => 'Encoder';

  @override
  String get filter => 'Filter';

  @override
  String get path => 'Path';

  @override
  String get targetSize => 'Target size';

  @override
  String get platformPresets => 'Platform presets';

  @override
  String get codec => 'Codec';

  @override
  String get preset => 'Preset';

  @override
  String get downscale => 'Allow downscaling';

  @override
  String get keepAudio => 'Keep audio';

  @override
  String get start => 'Compress';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get diagnostics => 'Diagnostics';

  @override
  String get diagnosticsRun => 'Check FFmpeg';

  @override
  String get about => 'About';

  @override
  String get upstream => 'Upstream project';

  @override
  String get license => 'License';

  @override
  String get version => 'Version';

  @override
  String get ffmpegReady => 'FFmpeg ready';

  @override
  String get ffmpegMissing => 'FFmpeg not found';

  @override
  String get ffmpegSource => 'Source';

  @override
  String get comingSoon => 'Coming in the next phase';

  @override
  String get openFolder => 'Open folder';

  @override
  String get result => 'Result';

  @override
  String get saved => 'smaller';

  @override
  String get outputPath => 'Output';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get share => 'Share';

  @override
  String get passOf => 'Pass';

  @override
  String get speed => 'Speed';

  @override
  String get eta => 'Remaining';

  @override
  String get warningAudioTracks => 'Only the first audio track is kept.';

  @override
  String get warningSubtitles => 'Subtitles are not carried over.';

  @override
  String get warningDownmix => 'Audio is downmixed to stereo.';

  @override
  String get warningFpsCapped => 'Frame rate is capped at 60 fps.';

  @override
  String get warningHdr => 'HDR will be converted to SDR.';

  @override
  String get warningAggressive =>
      'This target is aggressive for the resolution.';

  @override
  String get warningNoDownscale =>
      'Downscaling is off, so the target may be missed.';

  @override
  String get warningLowBitrate =>
      'Very low bitrate. Try a larger target or H.265.';

  @override
  String get warningInfeasible =>
      'This target is below the minimum for this duration.';

  @override
  String get errorNotVideo => 'This file is not a video.';

  @override
  String get errorNoVideoStream => 'No video stream found.';

  @override
  String get errorNoDuration => 'Could not read the duration.';

  @override
  String get errorFfmpegMissing => 'FFmpeg was not found.';

  @override
  String get errorCancelled => 'Cancelled.';

  @override
  String get errorRenameFailed => 'Could not replace the output file.';

  @override
  String get errorEncodeFailed => 'FFmpeg failed.';

  @override
  String get analyzing => 'Analyzing…';

  @override
  String get compressing => 'Compressing…';

  @override
  String get chooseAnother => 'Choose another';

  @override
  String get fileInfo => 'File';

  @override
  String get resolution => 'Resolution';

  @override
  String get estimated => 'Estimated';

  @override
  String get videoBitrate => 'Video bitrate';

  @override
  String get audioBitrate => 'Audio bitrate';

  @override
  String get warnings => 'Warnings';

  @override
  String get done => 'Done';

  @override
  String get startOver => 'Start over';

  @override
  String get openFile => 'Open file';

  @override
  String get missedTarget => 'The encoder could not reach the target.';

  @override
  String get selectToBegin => 'Select a video to begin.';

  @override
  String get targetTooSmall => 'Target is below the minimum.';

  @override
  String get customSize => 'Custom size';

  @override
  String get invalidSize => 'Cannot read that size.';

  @override
  String get mode => 'Mode';

  @override
  String get modeSize => 'Target size';

  @override
  String get modeCrf => 'Quality (CRF)';

  @override
  String get crfHint => 'Lower CRF keeps more detail. 23 is balanced.';

  @override
  String get measuring => 'Measuring quality…';

  @override
  String get quality => 'Quality';

  @override
  String get qualityIndistinguishable => 'Indistinguishable';

  @override
  String get qualitySame => 'Looks the same';

  @override
  String get qualitySlight => 'Slight softening';

  @override
  String get qualityVisible => 'Visible loss';

  @override
  String get qualityDegraded => 'Clearly degraded';

  @override
  String get qualityNone => 'Not measured';

  @override
  String get defaults => 'Defaults';

  @override
  String get defaultTarget => 'Default target';

  @override
  String get defaultCodec => 'Default codec';

  @override
  String get defaultPreset => 'Default preset';

  @override
  String get outputDir => 'Output folder';

  @override
  String get outputDirAuto => 'Next to the source';

  @override
  String get outputDirDownloads => 'Downloads/halfsizeX';

  @override
  String get reset => 'Reset';

  @override
  String get presetFast => 'Fast';

  @override
  String get presetMedium => 'Balanced';

  @override
  String get presetSlow => 'Quality';

  @override
  String get change => 'Change';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get outputFile => 'Output file';

  @override
  String get smaller => 'smaller';

  @override
  String get saveToDownloads => 'Save to Downloads';

  @override
  String get qualityCheck => 'Quality check (VMAF)';

  @override
  String get qualityCheckHint =>
      'Measure quality after encoding. Slightly slower.';

  @override
  String minimumNeeded(String size) {
    return 'This video needs at least $size.';
  }

  @override
  String raiseTarget(String size) {
    return 'Raise to $size';
  }

  @override
  String get encodeAnyway => 'Encode anyway';
}
