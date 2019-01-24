###
# @file Makefile The UNIX makefile for the ShLogger log rotation utility.
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
.PHONY: all clean shlogger
all: shlogger
	@echo Completed make all

# Determine platform....
UNAME = $(shell uname)
PLATFORM = unknown
ifeq ($(UNAME), AIX)
  # IBM AIX...
  PLATFORM=aix

  CC  = xlC_r
  LD  = xlC_r

  ALL_CCFLAGS  = -g -qstaticinline -qrtti=all -qtemplateregistry=./obj/template.reg
  ALL_LDFLAGS  =
endif

ifeq ($(UNAME), CYGWIN_NT-5.1)
  # Cygwin on Windows.
  PLATFORM = cygwin

  CC  = gcc
  LD  = gcc

  ALL_CCFLAGS  = -g
  ALL_LDFLAGS  = -lstdc++
endif

ifeq ($(UNAME), Linux)
  # Linux.
  PLATFORM = Linux

  CC  = g++
  LD  = g++

  ALL_CCFLAGS  = -g
  ALL_LDFLAGS  = -lstdc++
endif

ifeq ($(UNAME), Darwin)
  # Linux.
  PLATFORM = Darwin

  CC  = g++
  LD  = g++

  ALL_CCFLAGS  = -g
  ALL_LDFLAGS  = -lstdc++
endif

ifeq ($(PLATFORM), unknown)
  # Unknown platform so we need to stop.
  $(error Unknown UNIX platform $(UNAME))
endif

# Directories...
SRCDIR = .
OBJDIR = ./obj
BINDIR = ./bin

# Compiler flags...
INCPATHS = -I.
LIBPATHS =
LIBRARIES = $(LIB_PTHREAD)

CCFLAGS = $(ALL_CCFLAGS) $(INCPATHS)
LDFLAGS = $(ALL_LDFLAGS) $(LIBPATHS) $(LIBRARIES)

# Compilation Units...
TARGET  = $(BINDIR)/shlogger

OBJECTS = $(OBJDIR)/shlogger.o \
          $(OBJDIR)/shlogrot.o

# Build Rules...
clean:
	rm -fr $(OBJDIR)
	rm -fr $(BINDIR)
	@echo Completed make clean

shlogger: $(TARGET)
	cp $(TARGET) ../scripts
	@echo Completed make shlogger

# Build directories...
$(OBJDIR) $(BINDIR):
	if [ ! -d $@ ]; then mkdir $@; fi

# Sources...
$(TARGET): $(BINDIR) $(OBJDIR) $(OBJECTS)
	$(LD) -o $@ $(OBJECTS) $(LDFLAGS)

$(OBJECTS): $(OBJDIR)/%.o: $(SRCDIR)/%.cpp $(SRCDIR)/shlogrot.h
	$(CC) -c -o $@ $(CCFLAGS) $<
