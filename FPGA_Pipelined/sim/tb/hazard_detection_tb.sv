`timescale 1ns / 1ps

module hazard_detection_tb;
    logic [6:0] id_opcode;
    logic [4:0] id_rs1, id_rs2, ex_rd, mem_rd;
    logic [1:0] ex_write_back_source;
    logic ex_reg_write, mem_reg_write;

    logic stall;

    //debug
    logic [2:0] test_num;

    hazard_detection dut (
        .id_opcode(id_opcode),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .ex_rd(ex_rd),
        .ex_write_back_source(ex_write_back_source),
        .ex_reg_write(ex_reg_write),
        .mem_reg_write(mem_reg_write),
        .mem_rd(mem_rd),

        .stall(stall)
    );

    initial begin

        $display("\nStarting Hazard Detection Unit TestBench");
        test_num = 0;

        test_num = 1;
        $display("\n--> Test %0d: No Hazard", test_num);
        id_opcode = 7'b0000000; //R-type
        id_rs1 = 5'd1; id_rs2 = 5'd2; ex_rd = 5'd3; mem_rd = 5'd4;
        ex_write_back_source = 2'b00; ex_reg_write = 0; mem_reg_write = 0;
        #10;
        assert(stall == 0) else $error("Test 1 Failed");
        $display("Test %0d Complete\n", test_num);

        test_num = 2;
        $display("\n--> Test %0d: Load-Use Hazard", test_num);
        id_opcode = 7'b0000000; //R-type
        id_rs1 = 5'd3; id_rs2 = 5'd0; ex_rd = 5'd3; mem_rd = 5'd4;
        ex_write_back_source = 2'b01; ex_reg_write = 1; mem_reg_write = 0;
        #10;
        assert(stall == 1) else $error("Test 2 Failed");
        $display("Test %0d Complete\n", test_num);


        test_num = 3;
        $display("\n--> Test %0d: Branch Hazard", test_num);
        id_opcode = 7'b1100011; //B-type
        id_rs1 = 5'd3; id_rs2 = 5'd4; ex_rd = 5'd3; mem_rd = 5'd4;
        ex_write_back_source = 2'b00; ex_reg_write = 1; mem_reg_write = 1;
        #10;
        assert(stall == 1) else $error("Test 3 Failed");
        $display("Test %0d Complete\n", test_num);


        test_num = 4;    
        $display("\n--> Test %0d: JALR Hazard", test_num);
        id_opcode = 7'b1100111; //J-type JALR
        id_rs1 = 5'd3; id_rs2 = 5'd0; ex_rd = 5'd3; mem_rd = 5'd4;
        ex_write_back_source = 2'b00; ex_reg_write = 1; mem_reg_write = 1;
        #10;
        assert(stall == 1) else $error("Test 4 Failed");
        $display("Test %0d Complete\n", test_num);


        test_num = 0;
        $display("\nAll Tests Completed\n");
        $finish;
    end
endmodule