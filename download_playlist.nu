#! /usr/bin/env nu

# Downloads a file and thumbnail and return it's name
def download_file [u: string] {
  yt-dlp -x --audio-format mp3 --write-thumbnail $u
  let cover = (ls *.webp).name.0

  ffmpeg -i $cover cover.jpg
  rm $cover
  return (ls *.mp3).name.0
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

  ffmpeg -i $fname -ss $begin -to $end $"($ord) - ($name).mp3"
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

# Script downloads "video-playlist" and split into songs. Scipt requires ffmpeg and yt-dlp
def main [
  --timelapses (-t): list<string> # A list of time points, where the song ends
  --songnames (-s): list<string> # A list of song names
  --url (-u): string # URL of youtube video
  --json (-j): string # A JSON file containing a list of recordings in the format "song title" : "its end time". But fisrt element is always "00_Link_to_video" : "_youtube_link_"
  --reorder (-r) # For the correct result, you need to be in same folder as the songs. Takes first to character, which is numbers and renames with new order along song names
] {
  mut names = []
  mut times = []
  mut local_url = ""

  if ($reorder) {
    reorder
    exit
  }

  if (($timelapses != null) and ($songnames != null)) {
    if ($timelapses | length) != ($songnames | length) {
      print $"timelapses: ($timelapses)\nsongnames: ($songnames)"
      return 1
    }

    $names = $songnames
    $times = $timelapses
  }

  if ($json != null) {
    $local_url = (open $json | get 00_Link_to_video)
    $names = (open $json | columns | drop nth 0)
    $times = (open $json | values | drop nth 0)
  } else {
    $local_url = $url
  }

  # Перед циклом добавляем 00:00:00 в начало списка
  let times = ($times | insert 0 "00:00")

  if ($url == null and $json == null) {
    print "URL is not specify, run ./download_playlist.nu --help"
    return 1
  }

  let fname = (download_file $local_url)

  # Мы идём по именованиям
  $names | enumerate | each { |n|
    split_ffmpeg $fname ($times | get $n.index) ($times | get ($n.index + 1)) $n.item ($n.index + 1)
  }

  add_cover

  rm $fname
}
