#!/usr/bin/env bash
###
# @file indent.sh Test the ShLogLevel output control.
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
  echo Testing logging indentation FAILED! >&2
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

echo Testing ShLogging indentation...
source ${0%/*}/../scripts/shloglib.sh || die "Sourcing shloglib.sh failed"

export SHLOG_FILE=/tmp/shlog.log
unset SHLOG_SIZE
unset SHLOG_COUNT

rm -f $SHLOG_FILE* || die Log file setup failure,

ShLogLevel ALL >/dev/null 2>&1

for i in "" "  " "    " "      " "        "; do
  ShLogEnter Test $$ >/tmp/$$.out 2>&1 || die ShLogEnter unexpected return code
  test "`cat /tmp/$$.out`" = "$i->Test $$" || die "ShLogEnter unexpected indentation '`cat /tmp/$$.out`'"
done

test "`ShLogError Test $$ 2>&1`"   == "          ERROR: Test $$"   || die ShLogError unexpected output
test "`ShLogWarning Test $$ 2>&1`" == "          WARNING: Test $$" || die ShLogWarning unexpected output
test "`ShLogNotice Test $$ 2>&1`"  == "          NOTICE: Test $$"  || die ShLogWarning unexpected output
test "`ShLogInfo Test $$ 2>&1`"    == "          Test $$"          || die ShLogInfo unexpected output
test "`ShLogConfig Test $$ 2>&1`"  == "          Test $$"          || die ShLogConfig unexpected output
test "`ShLogDebug Test $$ 2>&1`"   == "          Test $$"          || die ShLogDebug unexpected output
test "`ShLogFine Test $$ 2>&1`"    == "          Test $$"          || die ShLogFine unexpected output
test "`ShLogFiner Test $$ 2>&1`"   == "          Test $$"          || die ShLogFiner unexpected output
test "`ShLogFinest Test $$ 2>&1`"  == "          Test $$"          || die ShLogFinest unexpected output
  
for i in "        " "      " "    " "  " ""; do
  ShLogLeave Test $$ >/tmp/$$.out 2>&1 || die ShLogLeave unexpected return code
  test "`cat /tmp/$$.out`" = "$i<-Test $$" || die "ShLogLeave unexpected indentation '`cat /tmp/$$.out`'"
done

rm /tmp/$$.out || die Removing $$.out failed

cat $SHLOG_FILE
echo Testing Shlogging indentation PASSED.
