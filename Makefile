###
# @file Makefile The UNIX makefile for the shlog package.
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

# Default to build changes.
.PHONY: all clean shlogger test-all install
all: shlogger
	@echo Completed make all

# Determine platform....
UNAME = $(shell uname)
PLATFORM = unknown
ifeq ($(UNAME), AIX)
  # IBM AIX...
  PLATFORM=aix

  TARG_DIR=$(DESTDIR)/usr/local/bin
endif

ifeq ($(UNAME), CYGWIN_NT-5.1)
  # Cygwin on Windows.
  PLATFORM = cygwin

  TARG_DIR=$(DESTDIR)/usr/local/bin
endif

ifeq ($(UNAME), Linux)
  # Linux.
  PLATFORM = Linux

  TARG_DIR=$(DESTDIR)/usr/local/bin
endif

ifeq ($(UNAME), Darwin)
  # Linux.
  PLATFORM = Darwin

  TARG_DIR=$(DESTDIR)/usr/local/bin
endif

ifeq ($(PLATFORM), unknown)
  # Unknown platform so we need to stop.
  $(error Unknown UNIX platform $(UNAME))
endif

# Build Rules...
clean:
	make -C shlogger clean
	@echo Completed make clean

shlogger:
	make -C shlogger all
	@echo Completed make shlogger

test-all:
	unit-test/all.sh

install: shlogger
	echo mkdir -p $(TARG_DIR)
	install -C scripts/shlog scripts/shlogger scripts/shloglib.sh $(TARG_DIR)
