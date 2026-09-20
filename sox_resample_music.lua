-- ====================================================================================
-- MIT License
--
-- Copyright (C) 2026 [https://github.com/YukiNeeSan]
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
-- ====================================================================================
-- Don't boost manually High Frequency range too much in tiltshelf/highshelf
-- Not all funtion describe so RTFM (Read The Fking Manual) FFmpeg filters
-- https://ffmpeg.org/ffmpeg-filters.html#toc-Audio-Filters
-- https://ffmpeg.org/ffmpeg-resampler.html#Resampler-Options
-- https://ffmpeg.org/doxygen/8.0/dir_07c4be17d34b4a7a38dbd1b8cb6b1e6c.html
-- https://ffmpeg.org/doxygen/7.1/dir_07c4be17d34b4a7a38dbd1b8cb6b1e6c.html
-- ------------------------------------------------------------------------------------

local mp = require "mp"
local msg = require "mp.msg"

local UPSAMPLE_MULTIPLIER = 32   --  multiplier samplerate (ex:2, 3, 4, 5, 6, 7, 8, 9, 10, etc) it's up to you
-- reference
-- if 48000 x2=96000 x4=192000 x8=384000 x16=768000 x32=1536000 x64=3072000 x128=6144000 x256=12288000 x512=24576000 x1024=49152000 x2048=98304000 x4096=196608000 x8192=393216000
-- if 44100 x2=88200 x4=176400 x8=352800 x16=705600 x32=1411200 x64=2822400 x128=5644800 x256=11289600 x512=22579200 x1024=45158400 x2048=90316800 x4096=180633600 x8192=361267200
-- if  8000 x2=16000 x4= 32000 x8= 64000 x16=128000 x32= 256000 x64= 512000 etc
-- same for other samplerate 11025, 12000, 16000, 22050, 24000, 32000

local MAX_RETRIES = 15
local RETRY_DELAY = 0.2

local applied = false
----------------------------------------------------------
-- Detect stupd HE-AAC using ffprobe, you should install/download manually
-- https://ffmpeg.org/download.html
-- https://ffmpeg.org/ffprobe.html
-- https://evermeet.cx/ffmpeg/
-- https://github.com/nghiencuuthuoc/FFmpeg-Full-Installation-Guide-for-Windows-11
-- https://www.gyan.dev/ffmpeg/builds/
-- https://github.com/BtbN/FFmpeg-Builds/releases

----------------------------------------------------------
local function is_he_aac()
    local path = mp.get_property("path")
    if not path then
        return false
    end
	
	local ffprobe = mp.get_property("options/ffprobe") or "ffprobe"
    local res = mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = {
            ffprobe,
            "-v", "error",
            "-select_streams", "a:0",
            "-show_entries", "stream=index,profile",
            "-of", "default=noprint_wrappers=1:nokey=1",
            path
        }
    })

    if not res or res.status ~= 0 or not res.stdout then
        return false
    end

    local profile = res.stdout:lower()

    if profile:find("he%-aac") or
       profile:find("he%-aacv2") or
       profile:find("aac lc sbr") or
       profile:find("spectral band replication") or
       profile:find("sbr") then

        msg.info("stupid HE-AAC detected (" .. profile:gsub("\n","") .. ")")
        return true
    end

    return false
end
----------------------------------------------------------

local function try_insert_soxr(attempt)

    if applied then
        return
    end

    local sr = mp.get_property_number("audio-params/samplerate")

    if not sr or sr <= 0 then
        if attempt < MAX_RETRIES then
            mp.add_timeout(RETRY_DELAY, function()
                try_insert_soxr(attempt + 1)
            end)
        end
        return
    end
------------------------------------------------------
-- Skip the dumb metalic robotic HE-AACv1/v2 codec
------------------------------------------------------
if is_he_aac() then
    mp.osd_message("Hell nah HE-AACv1_v2 detected - SoXr skipped", 3)
    msg.info("Skipping SoXr because audio is dumb codec.")

    mp.commandv("script-message", "soxr-ready")
    return
end
------------------------------------------------------
	
    local target_sr = math.floor(sr * UPSAMPLE_MULTIPLIER)
	-- caps samplerate max limit depending in your speaker/set-up/cans capability, too lazy write upsampling manually
			target_sr = math.min(target_sr, 192000) --(ex: 88200, 96000, 192000, 384000, 768000 and so on)
			-- 
			
    if sr == target_sr then
    mp.commandv("script-message", "soxr-ready")
    return
end

    local chain = string.format(
        "aresample=cheby=0:out_sample_fmt=dblp:out_sample_rate=%d:" ..
        "precision=33:resampler=soxr," ..
--	 	#"tiltshelf=frequency=2000:gain=-1.0:transform=zdf:width=0.707:width_type=q," ..
		"lowshelf=frequency=180:gain=7.5:transform=zdf:width=0.707:width_type=q," .. --#(Frequency bass/lowshelf both Music and Movies = 150-180)
		"stereowiden=crossfeed=0.20:delay=30:drymix=1.0:feedback=0.30," ..
		"dynaudnorm=coupling=0:framelen=200:gausssize=31:maxgain=20.0:peak=0.959," .. --#(framelen for Movies = 350-500, Music = 200-300, compromise both music and movies 150-200, Android mobile = 75-150), Peak = 0.95 or lower
		"volume=-4.0dB:precision=double," ..
        "aexciter=amount=1:blend=3:ceil=9999:drive=8.5:freq=2000:level_in=1:level_out=1:listen=0", -- #coloration music / musical film you can enable or disable just add/remove "--" before parameter
--		#"surround=chl_in=stereo:chl_out=7.1:win_func=gauss",   --# upmix source into surround
		-- #win_func=bhann / gauss / hamming / lanczos / hanning / hann / rect / sine / bartlett / dolph / welch 
		-- #and the rest are experimental blackman/flattop/bharris/bnuttall/nuttall/tukey/cauchy/parzen/poisson/bohman/kaiser 
        target_sr
    )

mp.commandv("af", "set", chain)
applied = true
mp.commandv("script-message", "soxr-ready")

    mp.osd_message(
        string.format("SoXr %d → %d Hz", sr, target_sr),
        3
    )

    msg.info(string.format("SoXr applied: %d → %d Hz", sr, target_sr))
end

mp.register_event("file-loaded", function()
    applied = false
    try_insert_soxr(0)
end)
