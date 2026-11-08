# Makefile for UVM Register File Verification
# Supports ModelSim / QuestaSim / VCS flows

VSIM ?= vsim
VLOG ?= vlog
VOPT ?= vopt
VCOVER ?= vcover

TOP_MODULE = RegisterFile_top
FILE_LIST = src_files.list
DO_SCRIPT = run_RegisterFile.do
COV_DB = RegisterFile_coverage.ucdb

.PHONY: all sim sim_gui coverage clean help

all: sim

sim:
	@echo "--- Compiling RTL and UVM Testbench ---"
	$(VLOG) -f $(FILE_LIST) -mfcu +cover +define+SIM
	@echo "--- Running Simulation (Batch Mode) ---"
	$(VSIM) -c -do $(DO_SCRIPT)

sim_gui:
	@echo "--- Running Simulation (GUI Mode) ---"
	$(VLOG) -f $(FILE_LIST) -mfcu +cover +define+SIM
	$(VSIM) -voptargs=+acc work.$(TOP_MODULE) -classdebug -uvmcontrol=all -cover -do $(DO_SCRIPT)

coverage:
	@echo "--- Generating Detailed Coverage Reports ---"
	$(VCOVER) report $(COV_DB) -details -all -output reports/coverage_report_summary.txt

clean:
	@echo "--- Cleaning simulation artifacts ---"
	rm -rf work/ transcript vsim.wlf *.ucdb *.vstf certe_dump.xml
	rm -f code_coverage_DUT.txt functional_coverage.txt coverage_report_summary.txt

help:
	@echo "Targets:"
	@echo "  make sim       : Compile and run simulation in batch mode"
	@echo "  make sim_gui   : Open simulation in QuestaSim GUI with waveforms"
	@echo "  make coverage  : Generate text coverage reports"
	@echo "  make clean     : Remove simulation artifacts and temporary files"
