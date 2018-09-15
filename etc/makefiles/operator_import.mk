#!/bin/sh
#
# Makefile for importing operator data.
#
# Copyright (c) 2018 Qualcomm Technologies, Inc.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted (subject to the limitations in the disclaimer below) provided that the
# following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this list of conditions
#   and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
#   and the following disclaimer in the documentation and/or other materials provided with the distribution.
# * Neither the name of Qualcomm Technologies, Inc. nor the names of its contributors may be used to endorse
#   or promote products derived from this software without specific prior written permission.
#
# NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED
# BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Variables are expected to be overriden when calling the makefile
DATA_HOME = /data/operator/
OPERATOR_ID = operator1
PROCESSING_DIR = $(DATA_HOME)/processing/$(OPERATOR_ID)/
INCOMING_DIR = $(DATA_HOME)/uploads/$(OPERATOR_ID)/ready_for_import

# Use COMMON_IMPORTER_ARGS to pass in general args valid for dirbs-import
COMMON_OPERATOR_ARGS =
# Use IMPORTER_ARGS to pass in extra args specific to operator type of dirbs-import
IMPORTER_ARGS =

# Global variables
LOCK_DIR = $(PROCESSING_DIR)/lock
LOCK_FILE = pid
PID = $(shell echo $$PPID)
CURRENT_TIME = $(shell eval date "+%Y.%m.%d-%H.%M.%S")
PROCESSED_FILE_NAME = /.processed

# ZIP variables
OPERATOR_ZIPS = $(shell find $(INCOMING_DIR) -print 2>/dev/null | grep -i '$(INCOMING_DIR).*.zip';)
OPERATOR_ZIPS_FILENAMES = $(notdir $(OPERATOR_ZIPS))

IMPORTED_CSVS_PROCESSED_FILES_BASE := $(addprefix $(PROCESSING_DIR),  $(basename $(OPERATOR_ZIPS_FILENAMES)))
IMPORTED_CSVS_PROCESSED_FILES := $(IMPORTED_CSVS_PROCESSED_FILES_BASE:=$(PROCESSED_FILE_NAME))

# Always run
.PHONY: lock unlock

all: lock $(IMPORTED_CSVS_PROCESSED_FILES) unlock

# Tries to make lock directory, if it can puts PID in a file within.
# Else checks to see if the process that made the lock directory is still running.
# If not it replaces the PID with its own.
# Otherwise exits
# This is a best effort lock it is possible for a process to jump in between checking the PID and writing the file.
lock:
	@if mkdir $(LOCK_DIR); \
	then \
		echo $(PID) > $(LOCK_DIR)/$(LOCK_FILE); \
	else \
		if kill -0 `cat $(LOCK_DIR)/$(LOCK_FILE)` 2> /dev/null;  \
		then \
			exit 3;\
		else \
			echo $(PID) > $(LOCK_DIR)/$(LOCK_FILE); \
		fi;\
	fi;

# Removes Lock directory
unlock:
	@rm -rf $(LOCK_DIR)

# Creates a working directory since we assume the ready_for_import is mounted read only
# Copies the zip file to the working directory so that it will be extracted there.
# Runs the importer preserving the exit code
# If successful moves the original zip up a level and adds a timestamp to it and removes the working directory
$(PROCESSING_DIR)%$(PROCESSED_FILE_NAME):$(INCOMING_DIR)/%.zip
	mkdir -p $(basename $@)/working_$(CURRENT_TIME)
	cp $< $(basename $@)/working_$(CURRENT_TIME)/$(notdir  $<)
	dirbs-import $(COMMON_IMPORTER_ARGS) operator $(IMPORTER_ARGS) $(OPERATOR_ID) $(basename $@)/working_$(CURRENT_TIME)/$(notdir  $<)
	mv $(basename $@)/working_$(CURRENT_TIME)/$(notdir  $<)  $(basename $@)/$(CURRENT_TIME)_$(notdir  $<)
	rm -rf $(basename $@)/working_$(CURRENT_TIME)
	touch $@
