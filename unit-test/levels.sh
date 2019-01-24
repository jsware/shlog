#!/usr/bin/env bash
###
# @file levels.sh Test the ShLogLevel output control.
#
# Copyright 2016 John Scott
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
  echo "ERROR: $* (RC $rc)" >&2
  echo Testing ShLogLevel output control FAILED! >&2
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

echo Testing ShLogLevel output control...
source ${0%/*}/../scripts/shloglib.sh || die "Sourcing shloglib.sh failed"

export SHLOG_FILE=/tmp/shlog.log
unset SHLOG_SIZE
unset SHLOG_COUNT

rm -f $SHLOG_FILE* || die Log file setup failure,

for l in Error Warning Notice Info Config Debug Fine Finer Finest; do
  ShLogLevel $l >/tmp/$$.out 2>&1
  nz=1

  for k in Error Warning Notice Info Config Debug Fine Finer Finest; do
    out=`ShLog$k Test 2>&1`

    if [ $nz -eq 1 ]; then
      test "-n '$out'" || die ShLog$k did not output as expected.
    else
      test "-z '$out'" || die ShLog$k output unexpectedly.
    fi

    if [ "$k" == "$l" ]; then
      nz=0
    fi
  done
done

rm /tmp/$$.out || die Removing $$.out failed

cat $SHLOG_FILE
echo Testing ShLogLevel output control PASSED.
