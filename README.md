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

`aresample=cheby=0:out_sample_fmt=dblp:out_sample_rate=192000:precision=33:cutoff=0.91:resampler=soxr`
```
*cheby 
chebyshev filter, Value 0 or 1, default 0, Chebyshev useful for different ratio
e.g sampling rate 192KHz on 48KHz Hardware or 44,1KHz on 48KHz Hardware and so on,
enabled if your condition like that. *tentative depending on your situation,
mostly default 0 is enough
	
*out_sample_fmt
sample format for output you can use 
Integer "s16" "s32"
Packed Floating-Point "flt" "dbl" 
Planar "s16p" "s32p" "fltp" "dblp"

*out_sample_rate
sample rate for output you can use 
samplerate 8000, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000 an so on
https://en.wikipedia.org/wiki/Sampling_(signal_processing)

*precision
{"precision", "set soxr resampling precision (in bits)",
  OFFSET(precision), AV_OPT_TYPE_DOUBLE, {.dbl=20.0}, 15.0, 33.0, PARAM},
based on source minimum 15 and maximum 33

*cutoff
Documentation said Default value is 0.91 with soxr
but see the source
soxr_quality_spec_t q_spec = soxr_quality_spec((int)((precision-2)/4), (SOXR_HI_PREC_CLOCK|SOXR_ROLLOFF_NONE)*!!cheby);
     q_spec.precision = precision;
#if !defined SOXR_VERSION /* Deprecated @ March 2013: */
     q_spec.bw_pc = cutoff? FFMAX(FFMIN(cutoff,.995),.8)*100 : q_spec.bw_pc;
#else
     q_spec.passband_end = cutoff? FFMAX(FFMIN(cutoff,.995),.8) : q_spec.passband_end;
#endif
that's meaning minimum 0.8 * 100 = 80% and maximum 0.995 * 100 = 99.5%
whatever you put it's always 0dB before Nyquist,
you can set cut off 0.8 Up to 0.995 manually or leave it at default

```

`[Highshelf=frequency=16000:gain=-7.0:transform=zdf:width=0.707:width_type=q]`
`[tiltshelf=frequency=14000:gain=-7.0:transform=zdf:width=0.707:width_type=q]`
`[lowshelf=frequency=180:gain=7.5:transform=zdf:width=0.707:width_type=q]`

```

Highshelf: gain plus
							 =============
		   					//
						   //
===========================

Highshelf: gain min
===========================	
	    				   \\
			  				\\
			  				  =============
```

```
Tiltshelf: gain plus
					        =============
		   			       //
						  //
			  =============
		     //
			//
============= 

Tiltshelf: gain min
=============
		   	\\
			  \\
			   =============
		  				   \\
						    \\
							 ============= 
```


```
Lowshelf: gain plus
=============	
	    	\\
			  \\
			  	===========================


Lowshelf: gain min
			    ===========================
		      //
			 //
=============
```

```
*frequency
frequency value is start from minimum 3000 to maksimum 999999

*gain
based on documentation ±20 dB while in the source there's no limit,
with transform zdf tiltshelf usable at ±15–20 dB, lowshelf and highshelf maybe still usable ±30–40 dB

*transform
math logic being used to create the IIR (Infinite Impulse Response) filter
 "di" (Direct Form I) standard default usable for double precision, 4 state (2 input and 2 output) not good fo high precision

 "dii" (Direct Form II) same like "di" but more efficient compute, 2 state but still not good for high pecision

 "tdi" (Transposed "di") more stable than di but still not good at high precision

"tdii" (Transposed "dii")more stable than dii, can handle float 16-32bit

 "latt" (Lattice) more complex filter structure known for its stability
	but for single filter like lowshelf isn't worth

 "svf" (State-Variable Filter) versatile filter structure that can be used to model classic analog filters,
	giving a distinctive, resonant sound often found in synthesizers, music production, creating a "vintage" sound

 "zdf" (Zero-Delay Feedback) a modern, advanced technique designed to prevent artifacts distortion
	and maintain stability, particularly when creating filters with high resonance. preferable than others

Summary :
	"di" and "dii" not clean stay away
	"tdi" "tdii" efficient but still not clean
	"latt" Good but small improvement
	"svf" Good for high frequency
	"zdf" Very Good stable with high-resonance filters to avoid unwanted artifacts.

*width_type and *width
both mutually cotinuous, you should determine widht type at first then you can fill width

1. width_type=q — The "Sharpness" Unit
Q stands for Quality factor. Think of it as a sharpness dial.
then width =
Low Q (0.3–0.7) = smooth, gentle, wide transition. Like slowly fading one thing into another.
High Q (2–10) = sharp, narrow, precise. Like a hard cut.
default is 0.5 i think still too wider so i'am use butterworth 0.707 smooth without ripple
	lowshelf=frequency=200:gain=4:width_type=q:width=0.707

2. width_type=o — The "Octave" Unit
our ears naturally hear pitch in octaves (like piano keys — each octave doubles the frequency).
width=2 = affects a wide 2-octave range around your frequency
width=1 = affects a 1-octave range (standard)
width=0.3 = very narrow, only a small slice of frequencies
		lowshelf=frequency=180:gain=5:width_type=o:width=1

3. width_type=h — The "Hertz" Unit
This sets the width as a direct frequency range in Hz. Simple and literal.
width=200 on a 1000Hz filter ffects from 900Hz to 1100Hz (±100Hz around center)
Works best when you know exactly which frequencies in Hz you want to affect,
take a times for trial and error
		equalizer=frequency=1000:gain=3:width_type=h:width=200
The catch: the same Hz width feels very different at different frequencies.
200Hz bandwidth at 400Hz feels wide,
but 200Hz bandwidth at 10000Hz feels extremely narrow — because our ears work logarithmically.

4. width_type=k — Same as Hertz but in Kilohertz
Exactly the same as h but the number is in kHz instead of Hz.
Useful for high frequencies so you don't have to write big numbers.
		highshelf=frequency=8000:gain=-2:width_type=k:width=4
means 4kHz = 4000Hz bandwidth. Same as writing width_type=h:width=4000.


5. width_type=s — The "Slope" Unit (shelf filters only)
This one is unique to shelf filters (lowshelf, highshelf, tiltshelf).
Instead of controlling how wide the affected area is,
it controls how steep the shelf edge is — like the angle of a ramp.
width=1.0 = steepest possible clean ramp. Sharp shelf edge.
width=0.5 = gentler, more gradual slope
width above 1.0 = too steep, causes a small bump/dip at the edge (usually unwanted)
		lowshelf=frequency=200:gain=4:width_type=slope:width=1

Quick comparison using the same filter goal —
"warm up the bass" recommendation frequency 150-180:
- lowshelf=frequency=180:gain=4:width_type=q:width=0.707   ← smooth, no bumps
- lowshelf=frequency=180:gain=4:width_type=o:width=1       ← one octave wide
- lowshelf=frequency=180:gain=4:width_type=s:width=0.9     ← gentle ramp

```


`[stereowiden=crossfeed=0.20:delay=30:drymix=1.0:feedback=0.30]`
```
sepaaration stereo effect for audio, i keep drmix 1.0 for natural vocal reason to prevent sounds become harsh metallic
https://ffmpeg.org/ffmpeg-filters.html#stereowiden
```

`[dynaudnorm=coupling=0:framelen=200:gausssize=31:maxgain=20.0:peak=0.959]`
```
1. coupling=0
0 lets each channel adjust independently, improve microdetail

2. framelen. range 10 to 8000
framelen for Movies = 350-500, Music = 200-300, compromise both music and movies 150-200, Android mobile = 75-150)
the filter analyzes at once in miliseconds before deciding how much to adjust the volume
1. 10–100ms = Good for spoken word or podcast, Can feel unnatural on music volume changes too aggressively.
2. 150–300ms = Good for music and musical film
3. 350–500ms (default: 500) — the most natural for movies and dynamic music.
4. 500–8000ms — very slow reaction. Almost like a one-time volume adjustment rather than dynamic normalization.
   Useful if you just want to bring a track to a consistent average level without affecting moment-to-moment dynamics at all.

3. gausssize
smoothing the volume adjustment decisions.
3–9 — very little smoothing. Can feel slightly jerky on dynamic material.
11–31 (default: 31) — natural, smooth transitions between loud and quiet sections.
51–101 — very smooth. Volume changes happen very gradually, almost imperceptibly.
101–301 — extremely smooth. Approaches a fixed gain rather than dynamic normalization.

4. maxgain. Range: 1.0 to 100.0 (as a multiplier)
the gain factors will smoothly approach the threshold value, but never exceed that value,
default 10 but you can go higher if sounds too low, doesn't make sound very loud.

5. peak
Target ceiling — the loudest any single moment is allowed to reach after normalization
1.0 Theoretically maximum loudness but leaves zero room for error risks clipping.
0.95 (default) Leaves a safe 5% headroom buffer for filters
0.8–0.9 — noticeably quieter output but generous headroom. Good multiple stages using filter
0.5 — half volume target. Rarely needed unless your downstream processing adds a lot of energy.

```

`[volume=-4.0dB:precision=double]`
```
pre-amp -4dB just for safe margin berfore processing by aexciter filter
precision = fixed (8-bit fixed-point), float (32-bit floating-point), double (64-bit floating-point)
```

`[aexciter=amount=1:blend=3:ceil=9999:drive=8.5:freq=2000:level_in=1:level_out=1:listen=0]`
```
#coloration music / musical film to produce high sound that is not present in the original signal without
raises the upper end of an audio signal without simply raising the higher frequencies.
TLDR; mimicking HiRes Audio for Fun Listening more "crisp" or "brilliant" sound.

1. amount 
amount of harmonics added to original signal range 0-64 default is 1,
has experimented 1 is enough.

2. blend
octave of newly created harmonics -10 up to 10
2 or 3 is enough

3. ceil
upper frequency limit of producing harmonics 9999 to 20000
9999 meaning frequency is unlimited

4. drive
amount of newly created harmonics. Range is from 0.1 to 10. Default value is 8.5.

5. freq
lower frequency limit of producing harmonics in Hz minimum 2000, maximum 12000

6. level_in
set input volume audio before processing, 1 is enough for general usage

7. level_out
set output volume audio after processing, 1 is enough for general usage

8. listen=0
you can change into 0 or 1 to hear the different
```

### Notes

using `ffprobe` autoskip sox_resample when HE-AAC/HE-AACv2 format is detected  
low sound quality due to the removal of high frequencies caused by poor design codec
[Installation Guide](https://github.com/nghiencuuthuoc/FFmpeg-Full-Installation-Guide-for-Windows-11)

## License

MIT License — Copyright © 2026 YukiNeeSan
