`timescale 1ns / 1ps

module control_tb();
        //inputs
        logic [6:0] op;
        logic [2:0] func3;
        logic [6:0] func7;
        logic alu_zero;

        //outputs
        logic [2:0] alu_control;
        logic [1:0] imm_source;
        logic mem_write;
        logic reg_write;
        logic alu_source;
        logic [1:0] write_back_source;
        logic pc_source;
        logic branch;
        logic jump;

        //Debug
        logic [3:0] test_num = 0;

        control dut (
            .op(op),
            .func3(func3),
            .func7(func7),
            .alu_zero(alu_zero),
            .alu_control(alu_control),
            .imm_source(imm_source),
            .mem_write(mem_write),
            .reg_write(reg_write),
            .alu_source(alu_source),
            .write_back_source(write_back_source),
            .pc_source(pc_source),
            .branch(branch),
            .jump(jump)
        );

        task set_default_vals();
            begin
                op = 7'bxxxxxxxx;
                func3 = 3'bxxx;
                func7 = 7'bxxxxxxxx;
                alu_zero = 1'bx;
                #1;
                $display("\n- Set Inputs to X");
            end
        endtask

        initial begin
            $display("Starting Control Unit Testbench");
            test_num = 1;
            set_default_vals();
            #1;
            op = 7'b0000011; // lw
            #1;
            $display("Test LW Instruction:");
            assert (alu_control === 3'b000) else $error("Assertion failed: alu_control != 000 (Got %b)", alu_control);
            assert (imm_source  === 2'b00)  else $error("Assertion failed: imm_source != 00 (Got %b)", imm_source);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 1 (Got %b)", mem_write);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (alu_source   === 1'b1)   else $error("Assertion failed: alu_source != 1 (Got %b)", alu_source);
            assert (write_back_source   === 2'b01)   else $error("Assertion failed: write_back_source != 1 (Got %b)", write_back_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> LW Instruction Test done");
            
            test_num = 2;
            set_default_vals();
            #1;
            op = 7'b0100011; // sw
            #1;
            $display("Test SW Instruction:");
            assert (alu_control === 3'b000) else $error("Assertion failed: alu_control != 000 (Got %b)", alu_control);
            assert (imm_source  === 2'b01)  else $error("Assertion failed: imm_source != 01 (Got %b)", imm_source);
            assert (mem_write   === 1'b1)   else $error("Assertion failed: mem_write != 1 (Got %b)", mem_write);
            assert (reg_write   === 1'b0)   else $error("Assertion failed: reg_write != 0 (Got %b)", reg_write);
            assert (alu_source   === 1'b1)   else $error("Assertion failed: alu_source != 1 (Got %b)", alu_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> SW Instruction Test done");

            test_num = 3;
            set_default_vals();
            #1;
            op = 7'b0010011; // I-type ALU
            func3 = 3'b000; // ADDI
            #1;
            $display("Test I-type ALU (ADDI) Instruction:");
            assert (alu_control === 3'b000) else $error("Assertion failed: alu_control != 000 (Got %b)", alu_control);
            assert (imm_source  === 2'b00)  else $error("Assertion failed: imm_source != 00 (Got %b)", imm_source);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (alu_source   === 1'b1)   else $error("Assertion failed: alu_source != 1 (Got %b)", alu_source);
            assert (write_back_source   === 2'b00)   else $error("Assertion failed: write_back_source != 0 (Got %b)", write_back_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> I-type ALU (ADDI) Instruction Test done");
            

            test_num = 4;
            set_default_vals();
            #1;
            op = 7'b0110011; // R-type ADD
            func3 = 3'b000;
            #1;
            $display("Test R-type ADD Instruction:");
            assert (alu_control === 3'b000) else $error("Assertion failed: alu_control != 000 (Got %b)", alu_control);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (alu_source   === 1'b0)   else $error("Assertion failed: alu_source != 0 (Got %b)", alu_source);
            assert (write_back_source   === 2'b00)   else $error("Assertion failed: write_back_source != 0 (Got %b)", write_back_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> R-type ADD Instruction Test done");

            test_num = 5;
            set_default_vals();
            #1;
            op = 7'b0110011; // R-type AND
            func3 = 3'b111;
            #1;
            $display("Test R-type AND Instruction:");
            assert (alu_control === 3'b010) else $error("Assertion failed: alu_control != 010 (Got %b)", alu_control);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (alu_source   === 1'b0)   else $error("Assertion failed: alu_source != 0 (Got %b)", alu_source);
            assert (write_back_source   === 2'b00)   else $error("Assertion failed: write_back_source != 0 (Got %b)", write_back_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> R-type AND Instruction Test done");

            test_num = 6;
            set_default_vals();
            #1;
            op = 7'b0110011; // R-type OR
            func3 = 3'b110;
            #1;
            $display("Test R-type OR Instruction:");
            assert (alu_control === 3'b011) else $error("Assertion failed: alu_control != 011 (Got %b)", alu_control);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (alu_source   === 1'b0)   else $error("Assertion failed: alu_source != 0 (Got %b)", alu_source);
            assert (write_back_source   === 2'b00)   else $error("Assertion failed: write_back_source != 0 (Got %b)", write_back_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            $display("--> R-type OR Instruction Test done");

            test_num = 7;
            set_default_vals();
            #1;
            op = 7'b1100011; // B-type BEQ
            func3 = 3'b000;
            alu_zero = 1'b0;
            #1;
            $display("Test B-type BEQ Instruction (Not Taken):");
            assert (imm_source  === 2'b10)  else $error("Assertion failed: imm_source != 10 (Got %b)", imm_source);
            assert (alu_control === 3'b001) else $error("Assertion failed: alu_control != 001 (Got %b)", alu_control);
            assert (reg_write   === 1'b0)   else $error("Assertion failed: reg_write != 0 (Got %b)", reg_write);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (alu_source   === 1'b0)   else $error("Assertion failed: alu_source != 0 (Got %b)", alu_source);
            assert (pc_source   === 1'b0)   else $error("Assertion failed: pc_source != 0 (Got %b)", pc_source);
            assert (branch   === 1'b1)   else $error("Assertion failed: branch != 1 (Got %b)", branch);
            $display("--> B-type BEQ Instruction Test (Not Taken) done");

            test_num = 8;
            set_default_vals();
            #1;
            op = 7'b1100011; // B-type BEQ
            func3 = 3'b000;
            alu_zero = 1'b1;
            #1;
            $display("Test B-type BEQ Instruction (Taken):");
            assert (pc_source   === 1'b1)   else $error("Assertion failed: pc_source != 1 (Got %b)", pc_source);
            $display("--> B-type BEQ Instruction Test (Taken) done");

            test_num = 9;
            set_default_vals();
            #1;
            op = 7'b1101111; // J-type JAL
            #1;
            $display("Test J-type JAL Instruction:");
            assert (imm_source  === 2'b11)  else $error("Assertion failed: imm_source != 11 (Got %b)", imm_source);
            assert (reg_write   === 1'b1)   else $error("Assertion failed: reg_write != 1 (Got %b)", reg_write);
            assert (mem_write   === 1'b0)   else $error("Assertion failed: mem_write != 0 (Got %b)", mem_write);
            assert (write_back_source   === 2'b10)   else $error("Assertion failed: write_back_source != 10 (Got %b)", write_back_source);
            assert (pc_source   === 1'b1)   else $error("Assertion failed: pc_source != 1 (Got %b)", pc_source);
            assert (jump   === 1'b1)   else $error("Assertion failed: jump != 1 (Got %b)", jump);
            assert (branch   === 1'b0)   else $error("Assertion failed: branch != 0 (Got %b)", branch);
            $display("--> J-type JAL Instruction Test done");

            test_num = 0;
            #10;
            $display("All tests completed");
            $finish;
        end
endmodule
