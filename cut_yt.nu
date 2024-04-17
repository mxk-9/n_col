#! /usr/bin/env nu

# Simple utility to make an fragment from the video, uses yt-dlp
def main [
from: string # begin of fragment
to: string # end of fragment
link: string # link to youtube video
] {
	yt-dlp --external-downloader ffmpeg --external-downloader-args $"ffmpeg_i: -ss ($from) -to ($to)" $link
}
