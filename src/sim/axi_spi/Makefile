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
export TEST_NAME=$(notdir $(shell pwd))

# Source C files
export SOURCE_FILES=$(TEST_NAME).c

# Include makefile to start testcase
include $(TEST_DIR)/common.mk

# Simulation timeout
export SIM_TIMEOUT_NS= 2000000