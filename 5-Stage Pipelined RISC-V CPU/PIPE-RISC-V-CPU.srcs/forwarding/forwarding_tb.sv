`timescale 1ns / 1ps

module forwarding_unit_tb;
    logic [4:0] ex_rs1, ex_rs2, mem_rd, wb_rd;
    logic mem_reg_write, wb_reg_write;

    logic [1:0] forwardA;
    logic [1:0] forwardB;

    //debug
    logic [2:0] test_num = 0;

    forwarding dut (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .mem_rd(mem_rd),
        .wb_rd(wb_rd),
        .mem_reg_write(mem_reg_write),
        .wb_reg_write(wb_reg_write),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    initial begin
        $display("Running Forwarding Unit Tests");

        $display("\n--> Test 1: No Forwarding");
        test_num = 1;

        ex_rs1 = 5'b00001; ex_rs2 = 5'b00010; mem_rd = 5'b00011; wb_rd = 5'b00100;
        mem_reg_write = 0; wb_reg_write = 0; #10;
        assert (forwardA == 2'b00) else $error("Test 1 Failed: Expected forwardA=00, got %b", forwardA);
        assert (forwardB == 2'b00) else $error("Test 1 Failed: Expected forwardB=00, got %b", forwardB);
        
        $display("Test 1 done");


        $display("\n--> Test 2: Forwarding from MEM stage");
        test_num = 2;
        
        ex_rs1 = 5'b00001; ex_rs2 = 5'b00010; mem_rd = 5'b00001; wb_rd = 5'b00100;
        mem_reg_write = 1; wb_reg_write = 0; #10;
        assert (forwardA == 2'b01) else $error("Test 2 Failed: Expected forwardA=01, got %b", forwardA);
        assert (forwardB == 2'b00) else $error("Test 2 Failed: Expected forwardB=00, got %b", forwardB);

        $display("Test 2 done");


        $display("\n--> Test 3: Forwarding from WB stage");
        test_num = 3;
        
        ex_rs1 = 5'b00001; ex_rs2 = 5'b00010; mem_rd = 5'b00011; wb_rd = 5'b00010;
        mem_reg_write = 0; wb_reg_write = 1; #10;
        assert (forwardA == 2'b00) else $error("Test 3 Failed: Expected forwardA=00, got %b", forwardA);
        assert (forwardB == 2'b10) else $error("Test 3 Failed: Expected forwardB=10, got %b", forwardB);
        
        $display("Test 3 done");

        $display("\n--> Test 4: Forwarding from both MEM and WB stages (MEM should take priority)");
        test_num = 4;

        ex_rs1 = 5'b00001; ex_rs2 = 5'b00010; mem_rd = 5'b00001; wb_rd = 5'b00010;
        mem_reg_write = 1; wb_reg_write = 1; #10;
        assert (forwardA == 2'b01) else $error("Test 4 Failed: Expected forwardA=01, got %b", forwardA);
        assert (forwardB == 2'b10) else $error("Test 4 Failed: Expected forwardB=10, got %b", forwardB);

        $display("Test 4 done");

        $display("\nAll Forwarding Unit Tests Completed\n");
        $finish;
    end
endmodule