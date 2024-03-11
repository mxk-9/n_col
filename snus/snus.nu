#! /usr/bin/env nu

# Used with the -d key
def backup_name_date [
  basename: string
] {
  let dt = date now | date to-table
  let dt = $"(($dt.year).0)-(($dt.month).0)-(($dt.day).0)_(($dt.hour).0)_(($dt.minute).0)"
  return ( [ $basename $dt ] | str join "_")
}

# Base copying command
def copy [
  target: list<string>
  dest: list<string>
] {
    # $target | zip $dest | each { |x| ls $"($x.0)" } # debug
    $dest | each { |x| mkdir $x }
    $target | zip $dest | each { |x| cp -rfvpu ...(ls $x.0 | each {|n| $n.name}) $x.1 }
}

# Simple NUshell Sync
def main [
  --config (-c): string # Read custom config. If not specified, the default config is used
  --backup (-b) # Make a backup
  --date (-d) # Used with -b. If specified, the Current date will be added to the name of the backup folder at the end
  --force (-f) # Used with -b and WITHOUT -d. Re-creates a backup
  --restore (-r) # Restore a backup
] {
  mut cfg = $config
  if ($config == null) {
    $cfg = "config.json"
  }
  let obj_cfg = open $cfg

  mut dst = (
    $obj_cfg | get folders_to_sync | columns | each {
      |x| [($obj_cfg | get backup_path) $x] | path join
    }
  )
  let trg = ($obj_cfg | get folders_to_sync | values)

  if ($backup) {
    if ($date) {
      $dst = ($dst | each { |x| backup_name_date $x })
    }

    if ($force and (not $date)) {
      $dst | each { |x| rm -rfi $x }
    }

    copy $trg $dst
  } else if ($restore) {
    copy $dst $trg
  }

}
