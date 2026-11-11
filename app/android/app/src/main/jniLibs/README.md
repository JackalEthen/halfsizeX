# Android FFmpeg binaries

`arm64-v8a` and `armeabi-v7a` are built locally from FFmpeg 8.1.3 with
x264, x265 4.1, zimg 3.0.6 and libvmaf 3.0.0, GPL configuration. `zscale` and `tonemap`
are available, so HDR PQ/HLG sources are converted to SDR BT.709.

`x86_64` is still the older yearsyan `v8.1.3-r1` build: it has `tonemap`
but no `zscale`, so HDR is rejected on that ABI.

| ABI | libffmpeg.so SHA-256 | libffprobe.so SHA-256 |
|---|---|---|
| arm64-v8a | `5B578872CDBA4B1F43747B61FA5945CACFD5D288D7F1453E30F7AF0EDE449383` | `8763EEF5BE4C0A9A078B1CA7D33F8328437D530D2394A568B1B8BE6EF04575B6` |
| armeabi-v7a | `E5996AD74B527CC18D38D69660990860EFF7C10236747272385BBA7AF96CFF63` | `C2166CB4F2EEE41447600BC232C3D6695FD2735C39DDBF3BC9A12F0AE4F7670A` |

Layout:

```
<abi>/libffmpeg.so    <- bin/ffmpeg
<abi>/libffprobe.so   <- bin/ffprobe
```

They are packaged as native libs and executed from `applicationInfo.nativeLibraryDir`
(Android 10+ W^X safe). `android:extractNativeLibs="true"` keeps the files on disk.

The 32-bit ARM build disables x264/x265 assembly because its relocations are
not PIC-safe with Android PIE + lld. arm64 keeps assembly.

To replace them, keep the same names and ensure a static PIE build with
`libx264`, `libx265`, `libzimg`, `libvmaf`, `zscale`, `tonemap`, `aac`.
