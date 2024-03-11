#! /usr/bin/env nu

# Downloads a file and thumbnail and return it's name
def download_file [u: string] {
  yt-dlp -x --audio-format mp3 --write-thumbnail $u
  let cover = (ls *.webp).name.0

  ffmpeg -i $cover cover.jpg
  rm $cover
  return (ls *.mp3).name.0
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

# ToDo
def add_cover [] {}

# Script downloads "video-playlist" and split into songs. Scipt requires ffmpeg and yt-dlp
def main [
  --timelapses (-t): list<string> # A list of time points, where the song ends
  --songnames (-s): list<string> # A list of song names
  --url (-u): string # URL of youtube video
  --json (-j): string # A JSON file containing a list of recordings in the format "song title" : "its end time"
  --reorder (-r) # ToDo: Requires --json or --songnames. Takes first to character, which is numbers and renames with new order along song names
] {
  mut names = []
  mut times = []

  if (($timelapses != null) and ($songnames != null)) {
    if ($timelapses | length) != ($songnames | length) {
      print $"timelapses: ($timelapses)\nsongnames: ($songnames)"
      return 1
    }

    $names = $songnames
    $times = $timelapses
  }

  if ($json != null) {
    $names = (open $json | columns)
    $times = (open $json | values)
  }

  # Перед циклом добавляем 00:00:00 в начало списка
  let times = ($times | insert 0 "00:00")

  if ($url == null) {
    print "URL is not specify, run ./download_playlist.nu --help"
    return 1
  }

  let fname = (download_file $url)

  # Мы идём по именованиям
  $names | enumerate | each { |n|
    split_ffmpeg $fname ($times | get $n.index) ($times | get ($n.index + 1)) $n.item ($n.index + 1)
  }
}
