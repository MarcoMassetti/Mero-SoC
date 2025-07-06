# Reading procedures file
source $::env(TEST_DIR)/procedures.tcl

# Loading waves format only in gui mode and if wave file is present
if {[batch_mode] == 0} {
	add log -r /*
	add log sim:/cpu_top_tb/DUT/inst_cpu/inst_register_file/registers
	add log sim:/cpu_top_tb/DUT/inst_ram_wrapper/inst_ram/mem

	if {[batch_mode] == 0 && [file exist wave.do]} {
		do wave.do
	}
}

# Always use hex format
radix -hexadecimal
# Add unit to simulation time
formatTime +nodefunit

echo "\n\nSimulation Start\n"

#load_code

# Run until trap is issued or until timeout
run_until_break 2000ms

# Print register file content
report_rf

# Compare register file cotent with expected result
compare_rf_content

# Exit simulation if in batch mode
if {[batch_mode] == 1} {
	exit
}
