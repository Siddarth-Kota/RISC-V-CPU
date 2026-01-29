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

        //Debug
        logic [2:0] test_num = 0;

        control dut (
            .op(op),
            .func3(func3),
            .func7(func7),
            .alu_zero(alu_zero),
            .alu_control(alu_control),
            .imm_source(imm_source),
            .mem_write(mem_write),
            .reg_write(reg_write)
        );

        task set_default_vals();
            begin
                op = 7'bxxxxxxxx;
                func3 = 3'bxxx;
                func7 = 7'bxxxxxxxx;
                alu_zero = 1'bx;
                #1;
                $display("Set Inputs to X");
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
            $display("LW Instruction Test done");
            
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
            $display("SW Instruction Test done");

            #10;
            $display("All tests completed");
            $finish;
        end
endmodule
