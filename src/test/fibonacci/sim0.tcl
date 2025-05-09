source $::env(TEST_DIR)/procedures.tcl

if {[batch_mode] == 0 && [file exist wave.do]} {
	do wave.do
}

radix -hexadecimal
formatTime +nodefunit
#add log -r *

echo "\n\nSimulation Start\n"

#load_code

run_until_break 1000ns

report_rf

compare_rf_content

if {[batch_mode] == 1} {
	exit
}
