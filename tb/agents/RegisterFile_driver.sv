
package RegisterFile_driver_pkg;
	import shared_pkg::*;
	import uvm_pkg::*;
	import RegisterFile_seq_item_pkg::*;
	`include "uvm_macros.svh"

	class RegisterFile_driver extends uvm_driver #(RegisterFile_seq_item);
		`uvm_component_utils(RegisterFile_driver);

		virtual RegisterFile_if RegisterFile_vif;

		function new(string name = "RegisterFile_driver", uvm_component parent = null);
			super.new(name, parent);
		endfunction : new

		task run_phase(uvm_phase phase);
			super.run_phase(phase);
			forever begin
				RegisterFile_seq_item req; // Use the item from get_next_item
				seq_item_port.get_next_item(req);

				// Drive phase
				RegisterFile_vif.RegWrite   = req.RegWrite;
				RegisterFile_vif.addr       = req.addr;
				if (req.RegWrite) begin // Only drive write_data if it's a write
				    RegisterFile_vif.write_data = req.write_data;
				end else begin
                end

				@(negedge RegisterFile_vif.clk); // DUT processes and outputs data/valid

				// Capture response phase (for reads or if DUT provides status for writes)
				if (!req.RegWrite) begin // It was a READ
					req.read_data = RegisterFile_vif.read_data;
				end
				req.valid = RegisterFile_vif.valid; // Capture valid for both read and write

				seq_item_port.item_done(); // Now item_done uses the item with updated read_data
				`uvm_info("run_phase", req.convert2string_stimulus(), UVM_NONE)
			end
		endtask : run_phase
		
	endclass : RegisterFile_driver
	
endpackage : RegisterFile_driver_pkg