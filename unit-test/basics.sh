#!/usr/bin/env bash
###
# @file basics.sh Test basic ShLogging functions.
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

echo Testing basic ShLogging functions...
source ${0%/*}/../scripts/shloglib.sh || die Sourcing shloglib.sh failed.

export SHLOG_FILE=/tmp/shlog.log
unset SHLOG_SIZE
unset SHLOG_COUNT

rm -f $SHLOG_FILE* || die Log file setup

ShLogLevel all 1>/tmp/$$.out 2>&1 || die ShLogLevel all failed.
test "`cat /tmp/$$.out`" == "Logging level ALL" || die ShLogLevel all unexpected output
test $SHLOG_LEVEL -eq 5 || die ShLogLevel all unexpected SHLOG_LEVEL value $SHLOG_LEVEL
rm /tmp/$$.out || die Removing $$.out failed

test "`ShLogError Test $$ 2>&1`"   == "ERROR: Test $$"		|| die ShLogError Test unexpected output
test "`ShLogWarning Test $$ 2>&1`" == "WARNING: Test $$"	|| die ShLogWarning Test unexpected output
test "`ShLogNotice Test $$ 2>&1`"  == "NOTICE: Test $$"		|| die ShLogWarning Test unexpected output
test "`ShLogInfo Test $$ 2>&1`"    == "Test $$"				|| die ShLogInfo Test unexpected output
test "`ShLogConfig Test $$ 2>&1`"  == "Test $$"				|| die ShLogConfig Test unexpected output
test "`ShLogDebug Test $$ 2>&1`"   == "Test $$"				|| die ShLogDebug Test unexpected output
test "`ShLogFine Test $$ 2>&1`"    == "Test $$"				|| die ShLogFine Test unexpected output
test "`ShLogFiner Test $$ 2>&1`"   == "Test $$"				|| die ShLogFiner Test unexpected output
test "`ShLogEnter Test $$ 2>&1`"   == "->Test $$"			|| die ShLogEnter Test unexpected output
test "`ShLogLeave Test $$ 2>&1`"   == "<-Test $$"			|| die ShLogLeave Test unexpected output
test "`ShLogFinest Test $$ 2>&1`"  == "Test $$"				|| die ShLogFinest Test unexpected output

echo -n Checking contents of log file $SHLOG_FILE...
LINE_STR="$(date -u +"^%a %b %e [0-9]{2}:[0-9]{2}:[0-9]{2} %Z %Y	`hostname`	`whoami`	[0-9]{1,5}	[A-Z]{4,7}	.+$")"
grep -vE "$LINE_STR" $SHLOG_FILE && die "Found UNEXPECTED output in $SHLOG_FILE"
echo OK.

cat $SHLOG_FILE
echo Testing basic ShLogging functions PASSED.
exit 0
