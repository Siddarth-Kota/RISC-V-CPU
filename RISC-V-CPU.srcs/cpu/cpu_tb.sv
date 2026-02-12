`timescale 1ns / 1ps

module cpu_tb;

    logic clk;
    logic rst_n;

    //debug
    logic [4:0] test_num = 0;

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
        // int check_limit = 5;

        $readmemh("instr_mem_test.hex", expected_instr_mem);

        $display("Starting CPU TestBench");
        test_num = 0;
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

        $display("\n--> Testing I-type LW Instruction");
        test_num = 1;
        #0.1;
        assert (dut.registers.reg_array[18] == 32'hAFAFAFAF) else $error("LW Test Failed. Register x18: Expected AFAFAFAF, got %h", dut.registers.reg_array[18]);
        $display("I-type LW Instruction Test done");


        $display("\n--> Testing I-type SW Instruction");
        test_num = 2;
        assert (dut.data_memory.mem_array[3] == 32'hF2F2F2F2) else $error("SW Initial Value Test Failed. Memory[3]: Expected F2F2F2F2, got %h", dut.data_memory.mem_array[3]);
        @(posedge clk); #0.1;
        assert (dut.data_memory.mem_array[3] == 32'hAFAFAFAF) else $error("SW Final Value Test Failed. Memory[3]: Expected AFAFAFAF, got %h", dut.data_memory.mem_array[3]);
        $display("I-type SW Instruction Test done");


        $display("\n--> Testing R-type ADD Instruction");
        test_num = 3;
        expected = 32'hAFAFAFAF + 32'h12341234;
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[19] == 32'h12341234) else $error("R-type ADD Test Failed. Register x19: Expected 12341234, got %h", dut.registers.reg_array[19]);
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[20] == expected) else $error("R-type ADD Test Failed. Register x20: Expected %h, got %h", expected, dut.registers.reg_array[20]);
        $display("R-type ADD Instruction Test done");


        $display("\n--> Testing R-type AND Instruction");
        test_num = 4;
        expected = expected & 32'hAFAFAFAF;
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[21] == expected) else $error("R-type AND Test Failed. Register x21: Expected %h, got %h", expected, dut.registers.reg_array[21]);
        $display("R-type AND Instruction Test done");


        $display("\n--> Testing R-type OR Instruction");
        test_num = 5;
        expected = 32'h56785678 | 32'hBCBCBCBC;
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[5] == 32'h56785678) else $error("R-type OR Test Failed. Register x5: Expected 56785678, got %h", dut.registers.reg_array[5]);
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[6] == 32'hBCBCBCBC) else $error("R-type OR Test Failed. Register x6: Expected BCBCBCBC, got %h", dut.registers.reg_array[6]);
        @(posedge clk); #0.1;
        assert (dut.registers.reg_array[7] == expected) else $error("R-type OR Test Failed. Register x7: Expected %h, got %h", expected, dut.registers.reg_array[7]);
        $display("R-type OR Instruction Test done");


        $display("\n--> Testing B-type BEQ Instruction");
        test_num = 6;
        assert (dut.Instruction == 32'h00730663) else $error("BEQ Instruction Test Failed. Expected 00730663, got %h", dut.Instruction);
        
        @(posedge clk); #0.1; //Branch not taken
        assert (dut.Instruction == 32'h00802B03) else $error("BEQ Instruction Test Failed. Expected 00802B03, got %h", dut.Instruction);
        
        @(posedge clk); #0.1; //set Register x22
        assert (dut.registers.reg_array[22] == 32'hAFAFAFAF) else $error("BEQ Test Failed. Register x22: Expected AFAFAFAF, got %h", dut.registers.reg_array[22]);
        
        @(posedge clk); #0.1; //Branch taken
        assert (dut.Instruction == 32'h00002B03) else $error("BEQ Instruction Test Failed. Expected 00002B03, got %h", dut.Instruction);
        
        @(posedge clk); #0.1; //set Register x22 to new value
        assert (dut.registers.reg_array[22] == 32'hABABABAB) else $error("BEQ Test Failed. Register x22: Expected ABABABAB, got %h", dut.registers.reg_array[22]);
        
        @(posedge clk); #0.1; //Branch taken
        assert (dut.Instruction == 32'h00000663) else $error("BEQ Instruction Test Failed. Expected 00000663, got %h", dut.Instruction);
        
        @(posedge clk); #0.1; //Branch taken
        assert (dut.Instruction == 32'h00000013) else $error("BEQ Instruction Test Failed. Expected 00000013, got %h", dut.Instruction);
        $display("B-type BEQ Instruction Test done");


        $display("\n--> J-type JAL Instruction Test");
        test_num = 7;

        @(posedge clk); #0.1;
        assert (dut.Instruction == 32'h00C000EF) else $error("JAL Instruction Test Failed. Expected 00C000EF, got %h", dut.Instruction);
        assert (dut.pc == 32'h00000044) else $error("JAL Instruction Test Failed. PC Expected 00000044, got %h", dut.pc);
        
        @(posedge clk); #0.1; //jal x1 0xC
        assert (dut.Instruction == 32'hFFDFF0EF) else $error("JAL Instruction Test Failed. Expected FFDFF0EF, got %h", dut.Instruction);
        assert (dut.pc == 32'h00000050) else $error("JAL Instruction Test Failed. PC Expected 00000050, got %h", dut.pc);
        assert (dut.registers.reg_array[1] == 32'h00000048) else $error("JAL Instruction Test Failed. Register x1 Expected 00000048, got %h", dut.registers.reg_array[1]);

        @(posedge clk); #0.1; //jal x1 -0x4
        assert (dut.Instruction == 32'h00C000EF) else $error("JAL Instruction Test Failed. Expected 00C000EF, got %h", dut.Instruction);
        assert (dut.pc == 32'h0000004C) else $error("JAL Instruction Test Failed. PC Expected 0000004C, got %h", dut.pc);
        assert (dut.registers.reg_array[1] == 32'h00000054) else $error("JAL Instruction Test Failed. Register x1 Expected 00000054, got %h", dut.registers.reg_array[1]);

        @(posedge clk); #0.1; //jal x1 0xC
        assert (dut.Instruction == 32'h00C02383) else $error("JAL Instruction Test Failed. Expected 00C02383, got %h", dut.Instruction);
        assert (dut.pc == 32'h00000058) else $error("JAL Instruction Test Failed. PC Expected 00000058, got %h", dut.pc);
        assert (dut.registers.reg_array[1] == 32'h00000050) else $error("JAL Instruction Test Failed. Register x1 Expected 00000050, got %h", dut.registers.reg_array[1]);

        @(posedge clk); #0.1; //lw x7 0xC(x0)
        assert (dut.registers.reg_array[7] == 32'hAFAFAFAF) else $error("JAL Instruction Test Failed. Register x7 Expected AFAFAFAF, got %h", dut.registers.reg_array[7]);
        $display("J-type JAL Instruction Test done");


        $display("\n--> I-type ADDI Instruction Test");
        test_num = 8;
        assert(dut.Instruction == 32'h1AB38D13) else $error("ADDI Instruction Test Failed. Expected 1AB38D13, got %h", dut.Instruction);
        assert(dut.registers.reg_array[26] != 32'hAFAFB15A) else $error("ADDI Instruction Test Failed. Register x26 should not be AFAFB15A, got %h", dut.registers.reg_array[26]);
        @(posedge clk); #0.1; //addi x26 x7 0x1AB (positive immediate)
        assert(dut.Instruction == 32'hF2130C93) else $error("ADDI Instruction Test Failed. Expected F2130C93, got %h", dut.Instruction);
        assert(dut.registers.reg_array[26] == 32'hAFAFB15A) else $error("ADDI Instruction Test Failed. Register x26: Expected AFAFB15A, got %h", dut.registers.reg_array[26]);
        @(posedge clk); #0.1; //addi x25 x6 0xF21 (negative immediate)
        assert(dut.registers.reg_array[25] == 32'hBCBCBBDD) else $error("ADDI Instruction Test Failed. Register x25: Expected BCBCBBDD, got %h", dut.registers.reg_array[25]);
        $display("I-type ADDI Instruction Test done");


        $display("\n--> U-type AUIPC Instruction Test");
        test_num = 9;
        assert(dut.Instruction == 32'h1F1FA297) else $error("AUIPC Instruction Test Failed. Expected 1F1FA297, got %h", dut.Instruction);
        @(posedge clk); #0.1; //auipc x5 0x1F1FA
        assert(dut.registers.reg_array[5] == 32'h1F1FA064) else $error("AUIPC Instruction Test Failed. Register x5: Expected 1F1FA064, got %h", dut.registers.reg_array[5]);
        assert(dut.pc == 32'h00000068) else $error("AUIPC Instruction Test Failed. PC Expected 00000068, got %h", dut.pc);
        $display("U-type AUIPC Instruction Test done");


        $display("\n--> U-type LUI Instruction Test");
        test_num = 10;
        assert(dut.Instruction == 32'h2F2FA2B7) else $error("LUI Instruction Test Failed. Expected 2F2FA2B7, got %h", dut.Instruction);
        @(posedge clk); #0.1; //lui x5 0x2F2FA
        assert(dut.registers.reg_array[5] == 32'h2F2FA000) else $error("LUI Instruction Test Failed. Register x5: Expected 2F2FA000, got %h", dut.registers.reg_array[5]);
        $display("U-type LUI Instruction Test done");


        $display("\n--> I-type SLTI Instruction Test");
        test_num = 11;
        assert(dut.registers.reg_array[19] == 32'h12341234) else $error("SLTI Instruction Test Failed. Register x19: Expected 12341234, got %h", dut.registers.reg_array[19]);
        assert(dut.Instruction == 32'hFFF9AB93) else $error("SLTI Instruction Test Failed. Expected FFF9AB93, got %h", dut.Instruction);
        @(posedge clk); #0.1; //slti x23 x19 0xFFF (negative immediate)
        assert(dut.registers.reg_array[23] == 32'h00000000) else $error("SLTI Instruction Test Failed. Register x23: Expected 0, got %h", dut.registers.reg_array[23]);
        @(posedge clk); #0.1; //slti x23 x23 0x001 (positive immediate)
        assert(dut.registers.reg_array[23] == 32'h00000001) else $error("SLTI Instruction Test Failed. Register x23: Expected 1, got %h", dut.registers.reg_array[23]);
        $display("I-type SLTI Instruction Test done");

        
        $display("\n--> I-type SLTU Instruction Test");
        test_num = 12;
        assert(dut.Instruction == 32'hFFF9BB13) else $error("SLTU Instruction Test Failed. Expected FFF9BB13, got %h", dut.Instruction);
        @(posedge clk); #0.1; //sltu x22 x19 0xFFF
        assert(dut.registers.reg_array[22] == 32'h00000001) else $error("SLTU Instruction Test Failed. Register x22: Expected 1, got %h", dut.registers.reg_array[22]);
        @(posedge clk); #0.1; //sltu x22 x19 0x001
        assert(dut.registers.reg_array[22] == 32'h00000000) else $error("SLTU Instruction Test Failed. Register x22: Expected 0, got %h", dut.registers.reg_array[22]);
        $display("I-type SLTU Instruction Test done");

        
        $display("\n--> I-type XORI Instruction Test");
        test_num = 13;
        assert(dut.Instruction == 32'hAAA9C913) else $error("XORI Instruction Test Failed. Expected AAA9C913, got %h", dut.Instruction);
        @(posedge clk); #0.1; //xori x18 x19 0xAAA
        assert(dut.registers.reg_array[18] == 32'hEDCBE89E) else $error("XORI Instruction Test Failed. Register x18: Expected EDCBE89E, got %h", dut.registers.reg_array[18]);
        @(posedge clk); #0.1; //xori x19 x18 0x000
        assert(dut.registers.reg_array[19] == 32'hEDCBE89E) else $error("XORI Instruction Test Failed. Register x19: Expected EDCBE89E, got %h", dut.registers.reg_array[19]);
        $display("I-type XORI Instruction Test done");


        $display("\n--> I-type ORI Instruction Test");
        test_num = 14;
        assert(dut.Instruction == 32'h48F9E813) else $error("ORI Instruction Test Failed. Expected 48F9E813, got %h", dut.Instruction);
        @(posedge clk); #0.1; //ori x16 x19 0x48F
        assert(dut.registers.reg_array[16] == 32'hEDCBEC9F) else $error("ORI Instruction Test Failed. Register x16: Expected EDCBEC9F, got %h", dut.registers.reg_array[16]);
        @(posedge clk); #0.1; //ori x17 x19 0xF0F
        assert(dut.registers.reg_array[17] == 32'hFFFFFF9F) else $error("ORI Instruction Test Failed. Register x17: Expected FFFFFF9F, got %h", dut.registers.reg_array[17]);
        $display("I-type ORI Instruction Test done");


        $display("\n--> I-type ANDI Instruction Test");
        test_num = 15;
        assert(dut.Instruction == 32'h07F9FE13) else $error("ANDI Instruction Test Failed. Expected 07F9FE13, got %h", dut.Instruction);
        @(posedge clk); #0.1; //andi x28 x19 0x07F
        assert(dut.registers.reg_array[28] == 32'h0000001E) else $error("ANDI Instruction Test Failed. Register x28: Expected 0000001E, got %h", dut.registers.reg_array[28]);
        @(posedge clk); #0.1; //andi x29 x19 0x800
        assert(dut.registers.reg_array[29] == 32'hEDCBE800) else $error("ANDI Instruction Test Failed. Register x29: Expected EDCBE800, got %h", dut.registers.reg_array[29]);
        $display("I-type ANDI Instruction Test done");

        $display("\n--> CPU instruction tests complete");
        $finish;
    end
endmodule