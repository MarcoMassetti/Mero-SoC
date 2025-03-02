radix -hexadecimal

set input_file "/media/marco/Data_L/EDA/openlane2/my_designs/cpu/firmware/main.bin"

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
	#echo "$addr: $data"
	incr addr
	
	set bin_data [read $fp 4]
}

#echo $cmd
eval $cmd
close $fp

