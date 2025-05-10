# Load binary file into testbench ram
proc load_code {} {
	set input_file "$::env(OBJ_DIR)/$::env(SOURCE_FILE_NAME).bin"
	set mem_path "sim:/cpu_top_tb/inst_ram_wrapper/inst_ram/mem"

	set cmd "change"
	set addr 0

	set fp [open $input_file r]
	fconfigure $fp -translation binary

	set bin_data [read $fp 4]
	while {[string length $bin_data] != 0} {
		binary scan $bin_data i data
		set data [format "%x" $data]
		append cmd " $mem_path\($addr) $data"
		incr addr
		
		set bin_data [read $fp 4]
	}
	eval $cmd
	close $fp
}

# Run until trap is issued or until timeout
proc run_until_break {max_time} {
	onbreak resume
	
	set trap_path  "sim:/trap_s"
	set rf_path "sim:/cpu_top_tb/DUT/inst_cpu/inst_register_file/registers"
	
	when -label trap "$trap_path'EVENT and $trap_path=1 and ($rf_path\(17)==a or $rf_path\(17)==5d)" {
		nowhen trap
		nowhen timeout
		echo "Detected trap at [expr ($now * 1.0) / [scaleTime 1ns 1]] ns"
		stop
	}
	
	when -label timeout "\$now > $max_time" {
		nowhen timeout
		echo "TIMEOUT at [expr ($now * 1.0) / [scaleTime 1ns 1]] ns"
		stop
	}
	
	run -all	
}

# Print register file content
proc report_rf {} {
	set output_file "$::env(OUTPUT_DIR)/$::env(SOURCE_FILE_NAME)_rf_dut.txt"
	set rf_path "sim:/cpu_top_tb/DUT/inst_cpu/inst_register_file/registers"
	
	set fp [open $output_file w]  
	
	puts $fp "===== register values"
	echo "===== register values"
	for {set i 0} {$i < 32} {incr i} {
		set val [examine -dec sim:/cpu_top_tb/DUT/inst_cpu/inst_register_file/registers($i)]
		puts $fp "x$i:	$val	(0x[format %08x $val])"
		echo "x$i:	$val	(0x[format %08x $val])"

	}
	puts $fp ""
	echo ""
	close $fp	
}

# Compare register file cotent with expected result
proc compare_rf_content {} {
	if {[catch {exec diff $::env(OUTPUT_DIR)/$::env(SOURCE_FILE_NAME)_rf_dut.txt $::env(OUTPUT_DIR)/$::env(SOURCE_FILE_NAME)_rf_golden.txt} fid]} {
		add message -noident -severity error "RF content differs\n$::errorInfo"
	} else {
		add message -noident -severity note "RF content matches"
	}
}
