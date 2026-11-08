package RegisterFile_monitor_pkg;
	import shared_pkg::*;
	import uvm_pkg::*;
	import RegisterFile_seq_item_pkg::*;
	`include "uvm_macros.svh"

	class RegisterFile_monitor extends uvm_monitor;
		`uvm_component_utils(RegisterFile_monitor)
		virtual RegisterFile_if RegisterFile_vif;
		RegisterFile_seq_item rsp_seq_item; // This item will be sampled
		uvm_analysis_port #(RegisterFile_seq_item) mon_ap;

        // Functional Coverage Group
        covergroup RegisterFile_CG with function sample(RegisterFile_seq_item trans);
            option.per_instance = 1;
            option.name = "MonitorCoverageInstance"; 

            // Coverpoint for register addresses accessed
            cp_addr : coverpoint trans.addr {
                bins rxtx0_access = {rxtx0_addr};
                bins rxtx1_access = {rxtx1_addr};
                bins rxtx2_access = {rxtx2_addr};
                bins rxtx3_access = {rxtx3_addr};
                bins ctrl_access  = {ctrl_addr};
                bins div_access   = {divider_addr};
                bins ss_access    = {ss_addr};
            }

            // Coverpoint for operation type (Read/Write)
            cp_reg_write : coverpoint trans.RegWrite {
                bins read_op  = {0};
                bins write_op = {1};
            }

            // Coverpoint for a specific field in a register, e.g., char_len in ss_addr
            // This requires sampling the data value when the address is ss_addr
            cp_ss_char_len : coverpoint trans.write_data[6:0] iff (trans.addr == ss_addr && trans.RegWrite == 1) {
                bins len_0_7   = {[0:7]};    // Example: cover lengths 0 to 7
                bins len_8_15  = {[8:15]};
                bins len_max   = {7'h7F};    // Max char_len (7 bits)  i.e., 7'b111_1111
            }
            
            // Coverpoint for valid signal status
            cp_valid_state : coverpoint trans.valid {
                bins op_valid = {1};
                //bins op_not_valid = {0}; 
            }

            // Cross coverage example: Read vs Write for each address
            cross_addr_rw : cross cp_addr, cp_reg_write;

        endgroup : RegisterFile_CG

		function new(string name = "RegisterFile_monitor", uvm_component parent = null);
			super.new(name, parent);
            // Instantiate the covergroup
            RegisterFile_CG = new();
		endfunction : new

		function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			mon_ap = new("mon_ap", this);
		endfunction : build_phase

		task run_phase(uvm_phase phase);
			super.run_phase(phase);
			forever begin
                // Create a new item for each transaction observed
                rsp_seq_item = RegisterFile_seq_item::type_id::create("rsp_seq_item_mon");
				@(negedge RegisterFile_vif.clk); // Sample on the falling edge after signals stabilize
				
                // Capture bus signals into the sequence item
				rsp_seq_item.RegWrite = RegisterFile_vif.RegWrite;
				rsp_seq_item.addr = RegisterFile_vif.addr;
				rsp_seq_item.write_data = RegisterFile_vif.write_data;
				rsp_seq_item.read_data = RegisterFile_vif.read_data;
				rsp_seq_item.valid = RegisterFile_vif.valid;
				
                // Sample the covergroup with the populated transaction item
                // Only sample if the transaction is considered valid/complete by the interface
                if (RegisterFile_vif.valid) begin 
				    RegisterFile_CG.sample(rsp_seq_item);
                end

				mon_ap.write(rsp_seq_item);
				`uvm_info("run_phase", rsp_seq_item.convert2string_stimulus(), UVM_NONE)
			end
		endtask : run_phase
		
	endclass : RegisterFile_monitor
	
endpackage : RegisterFile_monitor_pkg