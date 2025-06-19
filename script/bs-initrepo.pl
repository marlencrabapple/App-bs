#!/usr/bin/perl

use utf8;
use v5.40;

use IPC::Run3;
use Getopt::Long;


#repobase=/bs/repo/penny-linux/universe
#for target in /bs/target/*;
#   local repoarr=($target/{-{staging,testing},})
#  for repotarget in "$repobase"/{-{staging,testing},}/"os/$(basename "$target")"; do
#  mkdir -p "$repotarget"
#  repo-add -s -k"$BS_GPG_PUBID"  "$dir/$(basename "$dir").db.tar.zst"
#done;

