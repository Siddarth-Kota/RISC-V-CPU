`timescale 1ns / 1ps

module cpu_tb;

    logic clk;
    logic rst_n;

    //debug
    logic [2:0] test_num = 0;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #0.5 clk = ~clk;
    end

    logic [31:0] expected_instr_mem [0:255];
    logic [31:0] expected;

    task cpu_reset();
        begin
            rst_n = 0;
            @(negedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    initial begin
        int check_limit = 5;

        $readmemh("instr_mem_test.hex", expected_instr_mem);

        $display("Starting CPU TestBench");
        test_num = 1;
        // $display("testing the CPU Initializing");

        // cpu_reset();
        // assert (dut.pc == 32'h00000000) else $error("PC Init Failed. Expected 0, got %h", dut.pc);
        
        // for(int i = 0; i < check_limit; i++) begin
        //     if(expected_instr_mem[i] == 32'bx) begin
        //         $display("Reached end of hex file at index %0d", i);
        //         break;
        //     end
        //     //test DUT instruction vs expected memory
        //     assert(dut.Instruction == expected_instr_mem[i]) else $error("Instruction Wrong at index %0d. Expected %h, got %h", i, expected_instr_mem[i], dut.Instruction);
        //     @(posedge clk);
        // end
        // $display("CPU initialization test complete");

        $display("Running CPU instruction tests");
        cpu_reset();

        test_num = 2;
        $display("--> Testing LW Instruction");
        @(posedge clk);
        assert (dut.registers.reg_array[18] == 32'hAFAFAFAF) else $error("LW Test Failed. Register x18: Expected AFAFAFAF, got %h", dut.registers.reg_array[18]);
        $display("LW Instruction Test done");

        test_num = 3;
        $display("--> Testing SW Instruction");
        assert (dut.data_memory.mem_array[3] == 32'hF2F2F2F2) else $error("SW Initial Value Test Failed. Memory[3]: Expected F2F2F2F2, got %h", dut.data_memory.mem_array[3]);
        @(posedge clk);
        #0.1;
        assert (dut.data_memory.mem_array[3] == 32'hAFAFAFAF) else $error("SW Final Value Test Failed. Memory[3]: Expected AFAFAFAF, got %h", dut.data_memory.mem_array[3]);
        $display("SW Instruction Test done");

        test_num = 4;
        $display("--> Testing R-type ADD Instruction");
        expected = 32'hAFAFAFAF + 32'h12341234;
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[19] == 32'h12341234) else $error("R-type ADD Test Failed. Register x19: Expected 12341234, got %h", dut.registers.reg_array[19]);
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[20] == expected) else $error("R-type ADD Test Failed. Register x20: Expected %h, got %h", expected, dut.registers.reg_array[20]);
        $display("R-type ADD Instruction Test done");

        test_num = 5;
        $display("--> Testing R-type AND Instruction");
        expected = expected & 32'hAFAFAFAF;
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[21] == expected) else $error("R-type AND Test Failed. Register x21: Expected %h, got %h", expected, dut.registers.reg_array[21]);
        $display("R-type AND Instruction Test done");

        test_num = 6;
        $display("--> Testing R-type OR Instruction");
        expected = 32'h56785678 | 32'hBCBCBCBC;
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[5] == 32'h56785678) else $error("R-type OR Test Failed. Register x5: Expected 56785678, got %h", dut.registers.reg_array[5]);
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[6] == 32'hBCBCBCBC) else $error("R-type OR Test Failed. Register x6: Expected BCBCBCBC, got %h", dut.registers.reg_array[6]);
        @(posedge clk);
        #0.1;
        assert (dut.registers.reg_array[7] == expected) else $error("R-type OR Test Failed. Register x7: Expected %h, got %h", expected, dut.registers.reg_array[7]);
        $display("R-type OR Instruction Test done");

        $display("Testing B-type BEQ Instruction");
        test_num = 7;

        assert (dut.Instruction == 32'h00730663) else $error("BEQ Instruction Test Failed. Expected 00730663, got %h", dut.Instruction);
        
        @(posedge clk); //Branch not taken
        #0.1;
        assert (dut.Instruction == 32'h00802B03) else $error("BEQ Instruction Test Failed. Expected 00802B03, got %h", dut.Instruction);
        
        @(posedge clk); //set Register x22
        #0.1;
        assert (dut.registers.reg_array[22] == 32'hAFAFAFAF) else $error("BEQ Test Failed. Register x22: Expected AFAFAFAF, got %h", dut.registers.reg_array[22]);
        
        @(posedge clk); //Branch taken
        #0.1;
        assert (dut.Instruction == 32'h00002B03) else $error("BEQ Instruction Test Failed. Expected 00002B03, got %h", dut.Instruction);
        
        @(posedge clk); //set Register x22 to new value
        #0.1;
        assert (dut.registers.reg_array[22] == 32'hABABABAB) else $error("BEQ Test Failed. Register x22: Expected ABABABAB, got %h", dut.registers.reg_array[22]);
        
        @(posedge clk); //Branch taken
        #0.1;
        assert (dut.Instruction == 32'h00000663) else $error("BEQ Instruction Test Failed. Expected 00000663, got %h", dut.Instruction);
        
        @(posedge clk); //Branch taken
        #0.1;
        assert (dut.Instruction == 32'h00000013) else $error("BEQ Instruction Test Failed. Expected 00000013, got %h", dut.Instruction);
        
        $display("B-type BEQ Instruction Test done");


        $display("CPU instruction tests complete");
        $finish;
    end
endmodule