#! /usr/bin/env nu

def main [
	in_file: string
	out_name: string
] {
	ffmpeg -f lavfi -i anullsrc -i $in_file -crf 35 -vcodec libx265 -vf fps=25,scale=-1:720 -ac 1 -c:a aac -b:a 96k -shortest $out_name -y
}
