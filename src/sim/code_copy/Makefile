# Find top directory of the project
export TOP_DIR := $(shell \
  d=$$(pwd); \
  while [ "$$d" != "/" ] && [ ! -e "$$d/base.mk" ]; do \
    d=$$(dirname "$$d"); \
  done; \
  if [ -n "$$d" ] && [ -e "$$d/base.mk" ]; then echo "$$d"; else echo "."; fi \
)

# Include makefile with base constants definitions
include $(TOP_DIR)/base.mk

# Path of the testcase
export CURRENT_DIR=$(shell pwd)

# Name of the testcase
export SOURCE_FILE_NAME=$(notdir $(shell pwd))

# Include makefile to start testcase
include $(TEST_DIR)/common.mk
