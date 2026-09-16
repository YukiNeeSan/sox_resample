# mpv SoXr Upsampler

An mpv Lua script that automatically upsamples audio using FFmpeg SoXr.

### Features

* Configurable upsampling multiplier
* Auto skip HE-AAC/HE-AACv2 detection
* Configurable sample rate
* Custom FFmpeg audio filter chain

### Optional
### * Install FFmpeg / `ffprobe`

Copy the `.lua` file to:
```text
Windows: %APPDATA%\mpv\scripts\
Linux: ~/.config/mpv/scripts/
```

### adjustable

set max multiplier :

```lua
local UPSAMPLE_MULTIPLIER = 64
```

set maximum output sample rate target: e.g. 768Khz

```lua
target_sr = math.min(target_sr, 768000)
```

The audio chain string format can also be customized directly in the script.
See the [FFmpeg documentation](https://ffmpeg.org/ffmpeg-filters.html) for filter parameters.
```
        "aresample=cheby=0:out_sample_fmt=dblp:out_sample_rate=%d:" ..
        "precision=33:resampler=soxr," ..
--	 	#"tiltshelf=frequency=14000:gain=3.0:transform=zdf:width=0.707:width_type=q," ..
		"lowshelf=frequency=180:gain=7.5:transform=zdf:width=0.707:width_type=q," .. --#(Frequency bass/lowshelf both Music and Movies = 150-180)
--      "stereowiden=crossfeed=0.20:delay=30:drymix=1.0:feedback=0.30," ..
		"dynaudnorm=coupling=0:framelen=200:gausssize=31:maxgain=20.0:peak=0.959," .. --#(framelen for Movies = 350-500, Music = 200-300, compromise both music and movies 150-200, Android mobile = 75-150), Peak = 0.95 or lower
		"volume=-4.0dB:precision=double," ..
        "aexciter=amount=1:blend=4:ceil=9999:drive=8.5:freq=2000:level_in=1:level_out=1:listen=0", -- #coloration music / musical film you can enable or disable just add/remove "--" before parameter

```
### Notes

HE-AAC/HE-AACv2 is detected with `ffprobe` and skipped automatically.
[Installation Guide](https://github.com/nghiencuuthuoc/FFmpeg-Full-Installation-Guide-for-Windows-11)

## License

MIT License — Copyright © 2026 YukiNeeSan
