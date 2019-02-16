#!/usr/bin/env bash
###
# @file shlogging.sh Test shlog utility.
#
# Copyright 2019 John Scott
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -euo pipefail

# Exit script due to unexpected error.
die() {
  local rc=$?
  echo "ERROR: $* (RC $rc)." >&2
  echo "Testing basic ShLogging functions FAILED!" >&2
  test $rc -gt 0 || rc=1
  exit $rc
}

# Direct verbose output to /dev/null...
exec 3>/dev/null

# Parse arguments...
while getopts :vx- OPT; do
	case $OPT in
		v)	exec 3>&2;;	# Redirect verbose output to stderr.
		x)	set -x;;	# Turn bash debugging on.
		-)	break;;		# No more options.

		:)	echo "ERROR: Required parameter for -$OPTARG missing." >&2; exit 64;;
		\?)	echo "ERROR: Invalid option -$OPTARG specified." >&2; exit 64;;
		*)	echo "ERROR: Option -$OPT not yet implemented." >&2; exit 64;;
	esac
done
shift $(( $OPTIND - 1 ))

echo Testing shlog command...

export SHLOG_FILE=/tmp/shlogging.log
unset SHLOG_SIZE
unset SHLOG_COUNT

rm -f $SHLOG_FILE* || die Log file setup

${0%/*}/../scripts/shlog -f $SHLOG_FILE ${0%/*}/shlogging.loop
echo Checking output of shlog:
LINE_STR="$(date -u +"^%a %b %d [0-9]{2}:[0-9]{2}:[0-9]{2} %Z %Y	`hostname`	`whoami`	[0-9]{1,5}	INFO	Loop count [0-9]$")"
grep -vE "$LINE_STR" $SHLOG_FILE && die "Found UNEXPECTED output in $SHLOG_FILE"

cat $SHLOG_FILE
echo Found expected output of shlog command.

echo Testing shlog command PASSED
exit 0
