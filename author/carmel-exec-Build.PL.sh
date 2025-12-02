#!/usr/bin/env bash

(
  set -x
  logdir="${LOGPATH:-./}"
  logfile="$logdir/carmel-exec-perl-Build.PL-$(date +%s).log"
  carmel exec perl Build.PL 2>&1 | tee -a $logfile
  carmel exec ./Build build 2>&1 | tee -a $logfile
  echo -e "◯ All output written to '$logfile'."
)
