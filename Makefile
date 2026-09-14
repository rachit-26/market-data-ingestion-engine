# Default to Icarus Verilog as the simulator
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# List ALL the .sv files that make up your hardware
VERILOG_SOURCES += $(PWD)/parser.sv $(PWD)/order_book.sv $(PWD)/top_level.sv

# The name of your top-level module
TOPLEVEL = top_level

# The name of your Python file (without the .py)
MODULE = test_system

# Turn on assertion checking (only used by simulators that support it)
EXTRA_ARGS += --assert

# Include the Cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim