source $::env(TEST_DIR)/procedures.tcl

if {[batch_mode] == 0 && [file exist wave.do]} {
	do wave.do
}

radix -hexadecimal
formatTime +nodefunit
add log -r *
add log sim:/cpu_top_tb/DUT/inst_cpu/inst_register_file/registers
add log sim:/cpu_top_tb/inst_ram_wrapper/inst_ram/mem

echo "\n\nSimulation Start\n"

#load_code

run_until_break 10000ns

report_rf

compare_rf_content

if {[batch_mode] == 1} {
	exit
}
