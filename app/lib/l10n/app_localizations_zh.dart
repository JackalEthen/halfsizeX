// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'halfsizeX';

  @override
  String get tagline => '压到指定大小。';

  @override
  String get tabCompress => '压缩';

  @override
  String get tabSettings => '设置';

  @override
  String get emptyTitle => '把视频压到指定大小。';

  @override
  String get emptyBody => '选个数字，剩下的交给它：算码率、降分辨率、两遍编码。';

  @override
  String get pickVideo => '选择视频';

  @override
  String get dropHint => '把视频拖到这里';

  @override
  String get localOnly => '全部在本机完成，文件不会上传。';

  @override
  String get localBadge => '本地 · 不上传';

  @override
  String get pickHint => 'MP4 · MOV · MKV · AVI · WebM';

  @override
  String get custom => '自定义';

  @override
  String get checking => '检查中…';

  @override
  String get encoder => '编码器';

  @override
  String get filter => '滤镜';

  @override
  String get path => '路径';

  @override
  String get targetSize => '目标大小';

  @override
  String get platformPresets => '平台预设';

  @override
  String get codec => '编码';

  @override
  String get preset => '预设';

  @override
  String get downscale => '允许降分辨率';

  @override
  String get keepAudio => '保留音频';

  @override
  String get start => '开始压缩';

  @override
  String get cancel => '取消';

  @override
  String get settingsTitle => '设置';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get diagnostics => '诊断';

  @override
  String get diagnosticsRun => '检查 FFmpeg';

  @override
  String get about => '关于';

  @override
  String get upstream => '原项目';

  @override
  String get license => '许可证';

  @override
  String get version => '版本';

  @override
  String get ffmpegReady => 'FFmpeg 可用';

  @override
  String get ffmpegMissing => '未找到 FFmpeg';

  @override
  String get ffmpegSource => '来源';

  @override
  String get comingSoon => '下一阶段实现';

  @override
  String get openFolder => '打开文件夹';

  @override
  String get result => '结果';

  @override
  String get saved => '更小';

  @override
  String get outputPath => '输出';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get share => '分享';

  @override
  String get passOf => '第';

  @override
  String get speed => '速度';

  @override
  String get eta => '剩余';

  @override
  String get warningAudioTracks => '只保留第一条音轨。';

  @override
  String get warningSubtitles => '字幕不会保留。';

  @override
  String get warningDownmix => '音频会下混为立体声。';

  @override
  String get warningFpsCapped => '帧率上限为 60 fps。';

  @override
  String get warningHdr => 'HDR 会转换为 SDR。';

  @override
  String get warningAggressive => '这个目标对当前分辨率偏激进。';

  @override
  String get warningNoDownscale => '已关闭降分辨率，可能达不到目标。';

  @override
  String get warningLowBitrate => '码率很低，试试更大的目标或 H.265。';

  @override
  String get warningInfeasible => '目标低于该时长的最低大小。';

  @override
  String get errorNotVideo => '这个文件不是视频。';

  @override
  String get errorNoVideoStream => '没有找到视频流。';

  @override
  String get errorNoDuration => '读不到时长。';

  @override
  String get errorFfmpegMissing => '没有找到 FFmpeg。';

  @override
  String get errorCancelled => '已取消。';

  @override
  String get errorRenameFailed => '无法替换输出文件。';

  @override
  String get errorEncodeFailed => 'FFmpeg 执行失败。';

  @override
  String get analyzing => '分析中…';

  @override
  String get compressing => '压缩中…';

  @override
  String get chooseAnother => '换一个';

  @override
  String get fileInfo => '文件';

  @override
  String get resolution => '分辨率';

  @override
  String get estimated => '预计';

  @override
  String get videoBitrate => '视频码率';

  @override
  String get audioBitrate => '音频码率';

  @override
  String get warnings => '提示';

  @override
  String get done => '完成';

  @override
  String get startOver => '重新开始';

  @override
  String get openFile => '打开文件';

  @override
  String get missedTarget => '编码器没能压到目标大小。';

  @override
  String get selectToBegin => '选择一个视频开始。';

  @override
  String get targetTooSmall => '目标低于最低大小。';

  @override
  String get customSize => '自定义大小';

  @override
  String get invalidSize => '读不懂这个大小。';

  @override
  String get mode => '模式';

  @override
  String get modeSize => '目标大小';

  @override
  String get modeCrf => '画质优先 (CRF)';

  @override
  String get crfHint => 'CRF 越低细节越多，23 比较均衡。';

  @override
  String get measuring => '正在检测画质…';

  @override
  String get quality => '画质';

  @override
  String get qualityIndistinguishable => '几乎无差别';

  @override
  String get qualitySame => '观感一致';

  @override
  String get qualitySlight => '轻微变软';

  @override
  String get qualityVisible => '可见损失';

  @override
  String get qualityDegraded => '明显劣化';

  @override
  String get qualityNone => '未检测';

  @override
  String get defaults => '默认值';

  @override
  String get defaultTarget => '默认目标';

  @override
  String get defaultCodec => '默认编码';

  @override
  String get defaultPreset => '默认预设';

  @override
  String get outputDir => '输出目录';

  @override
  String get outputDirAuto => '源文件旁边';

  @override
  String get outputDirDownloads => '下载/halfsizeX';

  @override
  String get reset => '重置';

  @override
  String get presetFast => '快速';

  @override
  String get presetMedium => '均衡';

  @override
  String get presetSlow => '高画质';

  @override
  String get change => '更改';

  @override
  String get elapsed => '耗时';

  @override
  String get outputFile => '输出文件';

  @override
  String get smaller => '更小';

  @override
  String get saveToDownloads => '保存到下载';

  @override
  String get qualityCheck => '质量校验（VMAF）';

  @override
  String get qualityCheckHint => '编码后测画质，稍慢。';

  @override
  String minimumNeeded(String size) {
    return '这个视频最低需要 $size。';
  }

  @override
  String raiseTarget(String size) {
    return '提高到 $size';
  }

  @override
  String get encodeAnyway => '仍然编码';
}
