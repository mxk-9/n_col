#! /usr/bin/env nu

# TODO: show output from yt-dlp
# TODO: 00 instead of 00_Link_to_video
# TODO: try to parse episodes from video(yt-dlp)

# Script downloads "video-playlist" and split into songs. Scipt requires ffmpeg and yt-dlp
def main [
	--json (-j): string # A JSON file containing a list of recordings in the format "song title" : "its end time". But fisrt element is always "00_Link_to_video" : "_youtube_link_"
	--edit (-e) # Using with -j
	--reorder (-r) # For the correct result, you need to be in same folder as the songs. Takes first to character, which is numbers and renames with new order along song names
	--multiple_covers (-m) # If there are different covers on each track in the video playlist, then this key will extract each cover and fill it separately on the corresponding track, works with --edit
] {
	if ($reorder) {
		reorder
		exit
	}

	mut names = []
	mut times = []
	mut local_url = ""

	if ($json != null) {
		$local_url = (open $json | get 00_Link_to_video)
		$names = (open $json | columns | drop nth 0)
		$times = (open $json | values | drop nth 0)
	} else {
		print "./download_playlist.nu --help"
	}

	# Перед циклом добавляем 00:00:00 в начало списка
	let times = ($times | insert 0 "00:00")

	let fname = (download_file $local_url)
	# Мы идём по именованиям
	$names | enumerate | each { |n|
		split_ffmpeg $fname ($times | get $n.index) ($times | get ($n.index + 1)) $n.item ($n.index + 1)
	}

	if ($multiple_covers != null) {
		extract_covers $fname $times $names $edit
		add_multiple_covers $names
	} else if ($edit and $multiple_covers == null) {
		gimp cover.jpg
		print "Press ENTER to continue..."
		input
		add_cover
	} else {
		add_cover
	}

	rm $fname
}

# Downloads a file and thumbnail and return it's name
def download_file [u: string] {
	yt-dlp $u
	return (ls *webm).name.0
}

def str_ord [n: int] {
	mut ord = $"($n)"
	if (($ord | str length) != 2) {
		$ord = $"0($ord)"
	}
	return $ord
}

# Extracts a song
def split_ffmpeg [
	fname: string
	begin: string
	end: string
	name: string
	order: int
] {
	mut ord = $"($order)"
	if (($ord | str length) != 2) {
		$ord = $"0($ord)"
	}

	ffmpeg -i $fname -ss $begin -to $end $"($ord) - ($name).mp3" -y
}

def add_cover [] {
	ls *.mp3 | each { |x| ffmpeg -i $x.name -i "cover.jpg" -c copy -map 0 -map 1 ($x.name | str replace '.mp3' '_w_cover.mp3') }

	ls *_w_cover.mp3 | each { |x| mv -v $x.name ($x.name | str replace '_w_cover.mp3' '.mp3')}

	rm cover.jpg
}

def reorder [] {
	let old_names = (ls *.mp3 | each { |x| $x.name})

	let files = ((ls *.mp3 | each { |x| ($x.name | split row " " | drop nth 0)}) | enumerate)

	let new_names = ($files | each { |x| [(str_ord ($x.index + 1)) ($x.item | str join " ")] | str join " "})

	$old_names | zip $new_names | each { |x| if ($x.0 != $x.1) { mv -f $x.0 $x.1 } }
}

def extract_covers [
	ifile: string
	timelines: list<string>
	names: list<string>
	edit: bool
] {
	$timelines | zip $names | each {|x|
		let covername = $"($x.1)_cover.jpeg"
		let currtime = ($x.0 | split row ":") # Надо забирать на одну секунду раньше?
		mut Time = { hours: 0, minutes: 0, seconds: 0 }
		while ($currtime | length) > 0 {
			
		}

		ffmpeg -i $ifile -ss $x.0 -frames:v 1 $covername -y
		if $edit {
			gimp $covername
			print "Press Enter to continue..."
			input
		}
	}	
}

def add_multiple_covers [
	names: list<string>
] {
	$names | each {|x|
		let covername = (ls $x | get name | find cover.jpeg | ansi strip).0
		let songname = (ls $x | get name | find mp3 | ansi strip).0
		ffmpeg -i $songname -i $covername -c copy -map 0 -map 1 ($songname | str replace '.mp3' '_covered.mp3')
		print $"($covername)"
	}

	ls *_covered.mp3 | get name | each {|x| mv -v $x ($x | str replace '_covered' '')}
}
