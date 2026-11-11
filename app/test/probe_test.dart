import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/halfsize/probe.dart';

const _rotatedHdr = '''
{
  "format": {
    "format_name": "mov,mp4,m4a,3gp,3g2,mj2",
    "duration": "8.0",
    "size": "23200000",
    "bit_rate": "23200000"
  },
  "streams": [
    {
      "codec_type": "video",
      "codec_name": "h264",
      "profile": "High",
      "width": 1920,
      "height": 1080,
      "avg_frame_rate": "30/1",
      "r_frame_rate": "30/1",
      "pix_fmt": "yuv420p",
      "bit_rate": "20000000",
      "color_transfer": "smpte2084",
      "side_data_list": [{"rotation": -90}]
    },
    {
      "codec_type": "audio",
      "codec_name": "aac",
      "channels": 2,
      "sample_rate": "48000",
      "bit_rate": "128000"
    }
  ]
}
''';

void main() {
  test('rotation swaps the axes and PQ is detected', () {
    final info = parseProbeJson(_rotatedHdr, file: 'in.mp4');
    expect(info.duration, 8);
    expect(info.sizeBytes, 23200000);
    expect(info.video.width, 1080);
    expect(info.video.height, 1920);
    expect(info.video.rotation, 90);
    expect(info.video.fps, 30);
    expect(info.video.hdr, true);
    expect(info.video.hdrTransfer, 'pq');
    expect(info.audioTracks, 1);
    expect(info.subtitleTracks, 0);
    expect(info.audio!.channels, 2);
  });

  test('attached cover art is skipped', () {
    const json = '''
    {
      "format": {"format_name": "mp4", "duration": "2"},
      "streams": [
        {"codec_type": "video", "width": 600, "height": 600,
         "avg_frame_rate": "0/1", "disposition": {"attached_pic": 1}},
        {"codec_type": "video", "width": 1280, "height": 720,
         "avg_frame_rate": "25/1"}
      ]
    }
    ''';
    final info = parseProbeJson(json, file: 'cover.mp4');
    expect(info.video.width, 1280);
    expect(info.video.height, 720);
    expect(info.video.fps, 25);
  });

  test('non-video demuxers are rejected', () {
    const json = '''
    {"format": {"format_name": "tty"}, "streams": []}
    ''';
    expect(
      () => parseProbeJson(json, file: 'notes.txt'),
      throwsA(isA<FormatException>()),
    );
  });

  test('a file without a video stream is rejected', () {
    const json = '''
    {"format": {"format_name": "mp3", "duration": "3"},
     "streams": [{"codec_type": "audio", "channels": 2}]}
    ''';
    expect(
      () => parseProbeJson(json, file: 'song.mp3'),
      throwsA(isA<FormatException>()),
    );
  });
}
