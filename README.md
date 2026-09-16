# mpv SoXr Upsampler

An mpv Lua script that automatically upsamples audio using FFmpeg SoXr.
# suggestion 
1. force SoX [(libsoxr)](https://ffmpeg.org/doxygen/8.1/soxr__resample_8c_source.html) as the default [software resampler](https://ffmpeg.org/ffmpeg-resampler.html) in mpv.conf for precision

`--audio-swresample-o=cheby=0,out_sample_fmt=dblp,precision=33,resampler=soxr`

2. Keep [audio pitch correction](https://mpv.io/manual/master/#options-audio-pitch-correction)
  
`--audio-pitch-correction=yes`

3. [Volume](https://mpv.io/manual/master/#options-volume) Settings
You can adjust these settings manually, but change gain settings carefully.

```ini
volume=40
volume-gain-min=-150.0 #
volume-gain-max=113.0
#volume-gain=<db>
volume-max=1000.0
```

* **`volume=`** — Initial volume when mpv starts. This is the main setting to adjust.
* **`volume-gain-min=`** — Lowest allowed gain. `-150.0` does **not** mean completely silent.
* **`volume-gain-max=`** — Maximum allowed gain. If `113.0` is not enough, increase it **gradually** and test by listening. Do not jump straight to `150.0`.
* **`volume-gain=`** — Manual gain in dB. **Use caution:** incorrect values can make the audio extremely loud and affect the behavior of other volume settings. I recommend leaving it at default or don't use it
* **`volume-max=`** — Maximum limit of the normal volume control. `1000.0` does **not** mean the audio is automatically louder; it only removes the normal volume limit. With the SoXR script, it generally has little effect on loudness unless the volume is actually raised.

**For normal use, adjust only `volume=` `volume-gain-max=` `volume-max=`. Leave the other settings unchanged unless you specifically need to tune gain.**


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
See the [FFmpeg documentation](https://ffmpeg.org/ffmpeg-filters.html) for another filter parameters.
```
        "aresample=cheby=0:out_sample_fmt=dblp:out_sample_rate=%d:" ..
        "precision=33:resampler=soxr," ..

--	 	#"tiltshelf=frequency=14000:gain=3.0:transform=zdf:width=0.707:width_type=q," ..
		"lowshelf=frequency=180:gain=7.5:transform=zdf:width=0.707:width_type=q," ..
--			#(Frequency bass/lowshelf both Music and Movies = 150-180)

--      "stereowiden=crossfeed=0.20:delay=30:drymix=1.0:feedback=0.30," ..
--			#stereo effect for music

		"dynaudnorm=coupling=0:framelen=200:gausssize=31:maxgain=20.0:peak=0.959," ..
--			#(framelen for Movies = 350-500, Music = 200-300, compromise both music and movies 150-200, Android mobile = 75-150), Peak = 0.95 or lower

		"volume=-4.0dB:precision=double," ..
--			pre-amp -4dB just for safe margin berfore processing by aexciter filter

        "aexciter=amount=1:blend=4:ceil=9999:drive=8.5:freq=2000:level_in=1:level_out=1:listen=0",
-- 			#coloration music / musical film you can enable or disable just add/remove "--" before parameter

```
### Notes

HE-AAC/HE-AACv2 is detected with `ffprobe` and skipped automatically.
[Installation Guide](https://github.com/nghiencuuthuoc/FFmpeg-Full-Installation-Guide-for-Windows-11)

## License

MIT License — Copyright © 2026 YukiNeeSan
