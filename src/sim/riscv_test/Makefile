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

# Include makefile to start testcase
include $(TEST_DIR)/common.mk

# Simulation timeout
export SIM_TIMEOUT_NS=1000000

# Do not use default CRT0
CRT0=

# Add extra gcc options
OPTS+=-DTEST_FUNC_NAME=$(TEST_NAME) -DTEST_FUNC_TXT='"$(TEST_NAME)"' -DTEST_FUNC_RET=$(TEST_NAME)_ret -DMY_TEST_$(TEST_NAME)

# Add source assembly files
SOURCE_FILES=start.S ./S/$(TEST_NAME).S