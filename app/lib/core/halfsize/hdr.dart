String? hdrKind(String? transfer) {
  final value = (transfer ?? '').toLowerCase();
  if (value == 'smpte2084' || value == 'pq') return 'pq';
  if (value == 'arib-std-b67' || value == 'hlg') return 'hlg';
  return null;
}

String toneMapFilter(String? transfer) {
  final kind = hdrKind(transfer);
  final trc = kind == 'pq' ? 'smpte2084' : 'arib-std-b67';
  final npl = kind == 'pq' ? 1000 : 100;
  return [
    'format=yuv420p10le',
    'setparams=color_trc=$trc:color_primaries=bt2020:colorspace=bt2020nc',
    'zscale=t=linear:npl=$npl',
    'format=gbrpf32le',
    'zscale=p=bt709:t=linear',
    'tonemap=tonemap=hable:desat=0',
    'zscale=t=bt709:m=bt709:r=tv',
    'format=yuv420p',
  ].join(',');
}
