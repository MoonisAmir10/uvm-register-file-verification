package RegisterFile_reg_seq_pkg;
	import shared_pkg::*;
	import uvm_pkg::*;
	import RegisterFile_block_pkg::*;
	import RegisterFile_seq_item_pkg::*; // Though not directly used here, good for context
	`include "uvm_macros.svh"

	class RegisterFile_reg_seq extends uvm_reg_sequence;
	
	/*-------------------------------------------------------------------------------
	-- Interface, port, fields
	-------------------------------------------------------------------------------*/
		RegisterFile_block reg_model;
		// 'data' is inherited from uvm_reg_sequence and can be used for random values.
		// We'll use a local 'rand uvm_reg_data_t temp_wdata' for clarity in loops.
		rand uvm_reg_data_t temp_wdata; 

		uvm_reg_data_t   read_val;
		uvm_reg_data_t   peek_val;
		uvm_reg_data_t   mirrored_val;
 		uvm_status_e     status;		// Return status
	
	/*-------------------------------------------------------------------------------
	-- UVM Factory register
	-------------------------------------------------------------------------------*/
		// Provide implementations of virtual methods such as get_type_name and create
		`uvm_object_utils(RegisterFile_reg_seq)
	
	/*-------------------------------------------------------------------------------
	-- Functions
	-------------------------------------------------------------------------------*/
		// Constructor
		function new(string name = "RegisterFile_reg_seq");
			super.new(name);
		endfunction : new

 		task body();
 			uvm_reg regs[$];
 			uvm_reg_data_t test_patterns[] = {
 				32'h0000_0000,
 				32'hFFFF_FFFF,
 				32'hAAAA_AAAA,
 				32'h5555_5555,
 				32'h1234_5678,
 				32'hFEDC_BA98
 			};
			string reg_name;
			uvm_reg_data_t current_wdata;


 			if (reg_model == null) begin
 				`uvm_fatal(get_type_name(), "Register model handle is null")
 				return;
 			end

 			`uvm_info(get_type_name(), "Starting comprehensive register access test sequence", UVM_MEDIUM)

			// Get all registers from the model
			reg_model.get_registers(regs);

			// Iterate through each register in the model
			foreach (regs[i]) begin
				uvm_reg rg = regs[i];
				reg_name = rg.get_full_name();

				`uvm_info(get_type_name(), $sformatf("Testing register: %s", reg_name), UVM_MEDIUM)

				// Test Case 1: Predefined patterns
				`uvm_info(get_type_name(), $sformatf("[%s] Running predefined patterns test", reg_name), UVM_LOW)
				foreach (test_patterns[p_idx]) begin
					current_wdata = test_patterns[p_idx];
					`uvm_info(get_type_name(), $sformatf("[%s] Writing pattern 0x%h via Front-Door", reg_name, current_wdata), UVM_DEBUG)
					
					// Front-Door Write
					rg.write(status, current_wdata, .parent(this));
					if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] FD Write status not OK for pattern 0x%h", reg_name, current_wdata))

					// Front-Door Read
					rg.read(status, read_val, .parent(this));
					if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] FD Read status not OK after writing 0x%h", reg_name, current_wdata))
					if (read_val != current_wdata) begin
						`uvm_error(get_type_name(), $sformatf("[%s] FD Read data mismatch! Wrote:0x%h, Read:0x%h", reg_name, current_wdata, read_val))
					end

					// Back-Door Peek
					rg.peek(status, peek_val);
					if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] BD Peek status not OK after writing 0x%h", reg_name, current_wdata))
					if (peek_val != current_wdata) begin
						`uvm_error(get_type_name(), $sformatf("[%s] BD Peek data mismatch! Wrote:0x%h, Peeked:0x%h", reg_name, current_wdata, peek_val))
					end
					
					// Check Mirrored Value (should be updated by predictor after FD write/read)
					mirrored_val = rg.get_mirrored_value();
					if (mirrored_val != current_wdata) begin
						`uvm_error(get_type_name(), $sformatf("[%s] Mirrored value mismatch! Expected:0x%h, Mirrored:0x%h", reg_name, current_wdata, mirrored_val))
					end
				end

				// Test Case 2: Random value via Front-Door
				`uvm_info(get_type_name(), $sformatf("[%s] Running random Front-Door write/read test", reg_name), UVM_LOW)
				if (!this.randomize(temp_wdata)) `uvm_fatal(get_type_name(), "Failed to randomize temp_wdata")
				current_wdata = temp_wdata[REG_WIDTH-1:0];

				`uvm_info(get_type_name(), $sformatf("[%s] Writing random data 0x%h via Front-Door", reg_name, current_wdata), UVM_DEBUG)
				rg.write(status, current_wdata, .parent(this));
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] FD Random Write status not OK for data 0x%h", reg_name, current_wdata))

				rg.read(status, read_val, .parent(this));
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] FD Random Read status not OK after writing 0x%h", reg_name, current_wdata))
				if (read_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] FD Random Read data mismatch! Wrote:0x%h, Read:0x%h", reg_name, current_wdata, read_val))

				rg.peek(status, peek_val);
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] BD Random Peek status not OK after writing 0x%h", reg_name, current_wdata))
				if (peek_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] BD Random Peek data mismatch! Wrote:0x%h, Peeked:0x%h", reg_name, current_wdata, peek_val))
				
				mirrored_val = rg.get_mirrored_value();
				if (mirrored_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] Mirrored value mismatch after random FD write! Expected:0x%h, Mirrored:0x%h", reg_name, current_wdata, mirrored_val))


				// Test Case 3: Random value via Back-Door Poke, then Front-Door Read
				`uvm_info(get_type_name(), $sformatf("[%s] Running random Back-Door poke / Front-Door read test", reg_name), UVM_LOW)
				if (!this.randomize(temp_wdata)) `uvm_fatal(get_type_name(), "Failed to randomize temp_wdata")
				current_wdata = temp_wdata[REG_WIDTH-1:0];

				`uvm_info(get_type_name(), $sformatf("[%s] Poking random data 0x%h via Back-Door", reg_name, current_wdata), UVM_DEBUG)
				rg.poke(status, current_wdata); 
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] BD Poke status not OK for data 0x%h", reg_name, current_wdata))
				
				mirrored_val = rg.get_mirrored_value();
                if (mirrored_val != current_wdata) begin
                    `uvm_warning(get_type_name(), $sformatf("[%s] Mirrored value mismatch immediately after BD poke! Expected:0x%h, Mirrored:0x%h. This can happen if predictor isn't configured for BD or if poke doesn't update mirror directly. Forcing update.", reg_name, current_wdata, mirrored_val))
                end

				rg.read(status, read_val, .parent(this)); // Front-Door Read
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] FD Read status not OK after poking 0x%h", reg_name, current_wdata))
				if (read_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] FD Read data mismatch after BD poke! Poked:0x%h, Read:0x%h", reg_name, current_wdata, read_val))

				rg.peek(status, peek_val); // BD Peek to confirm DUT state
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), $sformatf("[%s] BD Peek status not OK after BD poke for 0x%h", reg_name, current_wdata))
				if (peek_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] BD Peek data mismatch after BD poke! Poked:0x%h, Peeked:0x%h", reg_name, current_wdata, peek_val))

				mirrored_val = rg.get_mirrored_value();
				if (mirrored_val != current_wdata) `uvm_error(get_type_name(), $sformatf("[%s] Mirrored value mismatch after BD poke & FD read! Expected:0x%h, Mirrored:0x%h", reg_name, current_wdata, mirrored_val))

				`uvm_info(get_type_name(), $sformatf("Finished testing register: %s", reg_name), UVM_MEDIUM)
				#10; // Small delay between register tests
			end
			   
			   // Test Case 4: Field-level access (demonstration using ss_reg)
			  `uvm_info(get_type_name(), "Running field-level access test on reg_model.ss_reg.char_len", UVM_MEDIUM)
			  if (reg_model.ss_reg != null && reg_model.ss_reg.char_len != null) begin
				uvm_reg_data_t original_ss_val, expected_ss_val;
				uvm_reg_field char_len_field = reg_model.ss_reg.char_len;
				int char_len_lsb = char_len_field.get_lsb_pos();
				int char_len_width = char_len_field.get_n_bits();
				uvm_reg_data_t char_len_val;
                uvm_reg_data_t field_mask;
				uvm_reg_data_t val_to_write_to_field;
                uvm_reg_data_t dut_val_read_before_modify;
                uvm_reg_data_t dut_val_read_after_modify;
                uvm_reg_data_t calculated_expected_val_after_modify;
                uvm_reg_data_t field_val_from_dut_after_modify;

				// Back-door field poke
				char_len_val = 'hf;
				reg_model.ss_reg.peek(status, original_ss_val); 
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] BD Peek for original_ss_val failed")

				`uvm_info(get_type_name(), $sformatf("[ss_reg field test] Poking char_len field with 0x%h", char_len_val), UVM_DEBUG)
				char_len_field.poke(status, char_len_val);
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] BD char_len.poke status not OK")


                // Calculate expected_ss_val using masking and shifting
                field_mask = ((1'b1 << char_len_width) - 1) << char_len_lsb; // Creates a mask like 0.01110..0
                expected_ss_val = (original_ss_val & ~field_mask) | ((char_len_val << char_len_lsb) & field_mask);


				reg_model.ss_reg.peek(status, peek_val);
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] BD Peek after char_len.poke status not OK")
				if (peek_val != expected_ss_val) `uvm_error(get_type_name(), $sformatf("[ss_reg field test] BD Peek mismatch after char_len.poke! Expected:0x%h, Peeked:0x%h", expected_ss_val, peek_val))
				
				mirrored_val = reg_model.ss_reg.get_mirrored_value();
				if (mirrored_val != expected_ss_val) `uvm_error(get_type_name(), $sformatf("[ss_reg field test] Mirrored value mismatch after char_len.poke! Expected:0x%h, Mirrored:0x%h", expected_ss_val, mirrored_val))

				// Front-door field write
				val_to_write_to_field = 'ha;

				`uvm_info(get_type_name(), $sformatf("[ss_reg field test] Intending to write 0x%h to char_len field (RMW style)", val_to_write_to_field), UVM_DEBUG)

                // 1. Read the current state of the full register from DUT.
                //    This also updates the model's desired and mirrored values to match the DUT.
                reg_model.ss_reg.mirror(status, .parent(this)); // UVM_CHECK reads DUT and compares with mirror
                if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] ss_reg.mirror() failed initially")
                
                dut_val_read_before_modify = reg_model.ss_reg.get_mirrored_value(); // Get value that's now synced with DUT
                `uvm_info(get_type_name(), $sformatf("[ss_reg field test] DUT ss_reg value before RMW (via mirror): 0x%h", dut_val_read_before_modify), UVM_DEBUG);

                // 2. Calculate what the full register *should* be after modifying only the target field.
                field_mask = ((1'b1 << char_len_width) - 1) << char_len_lsb;
                calculated_expected_val_after_modify = (dut_val_read_before_modify & ~field_mask) | ((val_to_write_to_field << char_len_lsb) & field_mask);
                `uvm_info(get_type_name(), $sformatf("[ss_reg field test] Calculated expected full DUT value after RMW: 0x%h", calculated_expected_val_after_modify), UVM_DEBUG);

                // 3. Set the desired value for ONLY the target field in the model.
                //    Since other fields in the model are now synced with HW (due to mirror()),
                //    setting this one field will result in the overall desired value being `calculated_expected_val_after_modify`.
                char_len_field.set(val_to_write_to_field);

                // 4. Update the hardware. This will write the model's new desired value.
                reg_model.ss_reg.update(status, .parent(this));
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] ss_reg.update() for RMW failed")

                // 5. Read back the full register value from the DUT to confirm.
				reg_model.ss_reg.read(status, dut_val_read_after_modify, .parent(this));
				if (status != UVM_IS_OK) `uvm_error(get_type_name(), "[ss_reg field test] FD Read after ss_reg.update() for RMW failed")
                `uvm_info(get_type_name(), $sformatf("[ss_reg field test] Actual full DUT value after RMW (read back): 0x%h", dut_val_read_after_modify), UVM_DEBUG);

                // 6. Compare the read-back DUT value with the calculated expected value.
				if (dut_val_read_after_modify != calculated_expected_val_after_modify) begin
                    `uvm_error(get_type_name(), $sformatf("[ss_reg field test] Full register value mismatch after RMW! Expected:0x%h, Got_from_DUT:0x%h",
                                                            calculated_expected_val_after_modify, dut_val_read_after_modify))
                end

                // 7. Verify the mirrored value of the field and the full register (should match DUT)
                if (char_len_field.get_mirrored_value() != val_to_write_to_field) begin
                    `uvm_error(get_type_name(), $sformatf("[ss_reg field test] Mirrored field value mismatch after RMW! Expected_field:0x%h, Mirrored_field:0x%h",
                                                            val_to_write_to_field, char_len_field.get_mirrored_value()))
                end
                if (reg_model.ss_reg.get_mirrored_value() != dut_val_read_after_modify) begin
                    `uvm_error(get_type_name(), $sformatf("[ss_reg field test] Full mirrored register value mismatch after RMW! Expected_to_match_DUT_read:0x%h, Mirrored_full:0x%h",
                                                            dut_val_read_after_modify, reg_model.ss_reg.get_mirrored_value()))
                end

			end else begin
				`uvm_warning(get_type_name(), "Could not run field-level test on ss_reg.char_len (reg or field not found).")
			end

 			`uvm_info(get_type_name(), "Finished comprehensive register access test sequence", UVM_MEDIUM)
 		endtask : body

	endclass : RegisterFile_reg_seq

endpackage : RegisterFile_reg_seq_pkg