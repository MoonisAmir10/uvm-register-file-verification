vlib work
vlog -f src_files.list -mfcu +cover +define+SIM
vsim -voptargs=+acc work.RegisterFile_top -classdebug -uvmcontrol=all -cover +UVM_NO_RELNOTES +UVM_VERBOSITY=UVM_DEBUG

add wave -color red 		sim:/RegisterFile_top/RegisterFileif/clk
add wave -color cyan 		sim:/RegisterFile_top/RegisterFileif/RegWrite
add wave -color cyan 		sim:/RegisterFile_top/RegisterFileif/addr
add wave					sim:/RegisterFile_top/RegisterFileif/write_data
add wave					sim:/RegisterFile_top/RegisterFileif/read_data
add wave					sim:/RegisterFile_top/RegisterFileif/valid
add wave -color gold 		sim:/RegisterFile_top/DUT/rxtx0
add wave -color gold 		sim:/RegisterFile_top/DUT/rxtx1
add wave -color gold 		sim:/RegisterFile_top/DUT/rxtx2
add wave -color gold 		sim:/RegisterFile_top/DUT/rxtx3
add wave -color gold 		sim:/RegisterFile_top/DUT/ctrl
add wave -color gold 		sim:/RegisterFile_top/DUT/divider
add wave -color gold 		sim:/RegisterFile_top/DUT/ss

.vcop Action toggleleafnames

coverage save RegisterFile_coverage.ucdb -onexit

run -all

# Report code coverage specifically for DUT (instance name 'DUT' within 'RegisterFile_top')
coverage report -code bcefst -detail -output code_coverage_DUT.txt 

# Report specific functional covergroup instance
# The path uvm_test_top.env.agt.monitor is the UVM hierarchy.
# The covergroup instance is named 'RegisterFile_CG' within that monitor instance.
coverage report -detail -cvg -output functional_coverage.txt /RegisterFile_monitor_pkg/RegisterFile_monitor/RegisterFile_CG

# General summary report (often good to have)
vcover report RegisterFile_coverage.ucdb -details -all -output coverage_report_summary.txt

#quit -sim