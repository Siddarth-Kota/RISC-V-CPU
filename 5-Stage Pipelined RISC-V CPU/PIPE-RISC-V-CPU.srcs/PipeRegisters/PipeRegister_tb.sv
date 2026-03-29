`timescale 1ns / 1ps

module PipeRegister_tb;
    logic clk; 
    logic rst; // Active low reset
    
    // IF --> ID register signals
    logic [31:0] if_PC_in, if_instruction_in;
    logic [31:0] id_PC_out, id_instruction_out;

    // ID --> EX register signals
    logic id_RegWrite_in, id_MemRead_in, id_MemWrite_in, id_Branch_in, id_ALUSrc_in;
    logic [1:0] id_MemtoReg_in;
    logic [3:0] id_ALUOp_in;
    logic [31:0] id_rs1_data_in, id_rs2_data_in, id_imm_in;
    logic [4:0] id_rs1_in, id_rs2_in, id_rd_in;

    logic ex_RegWrite_out, ex_MemRead_out, ex_MemWrite_out, ex_Branch_out, ex_ALUSrc_out;
    logic [1:0] ex_MemtoReg_out;
    logic [3:0] ex_ALUOp_out;
    logic [31:0] ex_PC_out, ex_rs1_data_out, ex_rs2_data_out, ex_imm_out;
    logic [4:0] ex_rs1_out, ex_rs2_out, ex_rd_out;

    // EX --> MEM register signals
    logic ex_zero_in;
    logic [31:0] ex_alu_result_in, ex_rs2_data_in, ex_branch_target_in;

    logic mem_RegWrite_out, mem_MemRead_out, mem_MemWrite_out, mem_Branch_out, mem_zero_out;
    logic [1:0] mem_MemtoReg_out;
    logic [31:0] mem_alu_result_out, mem_rs2_data_out, mem_branch_target_out;
    logic [4:0] mem_rd_out;

    // MEM --> WB register signals
    logic mem_RegWrite_in;
    logic [1:0] mem_MemtoReg_in;
    logic [31:0] mem_read_data_in, mem_alu_result_in;
    logic [4:0] mem_rd_in;

    logic wb_RegWrite_out;
    logic [1:0] wb_MemtoReg_out;
    logic [31:0] wb_read_data_out, wb_alu_result_out;
    logic [4:0] wb_rd_out;

    // Instantiate the pipeline registers
    if_id_reg IF_ID (
        .clk(clk),
        .rst(rst),
        .PC_in(if_PC_in),
        .instruction_in(if_instruction_in),

        .PC_out(id_PC_out),
        .instruction_out(id_instruction_out)
    );

    id_ex_reg ID_EX (
        .clk(clk),
        .rst(rst),
        .RegWrite_in(id_RegWrite_in),
        .MemtoReg_in(id_MemtoReg_in),
        .MemRead_in(id_MemRead_in),
        .MemWrite_in(id_MemWrite_in),
        .Branch_in(id_Branch_in),
        .ALUSrc_in(id_ALUSrc_in),
        .ALUOp_in(id_ALUOp_in),
        .PC_in(id_PC_out),
        .read_data1_in(id_rs1_data_in),
        .read_data2_in(id_rs2_data_in),
        .imm_in(id_imm_in),
        .rs1_in(id_rs1_in),
        .rs2_in(id_rs2_in),
        .rd_in(id_rd_in),

        .RegWrite_out(ex_RegWrite_out),
        .MemtoReg_out(ex_MemtoReg_out),
        .MemRead_out(ex_MemRead_out),
        .MemWrite_out(ex_MemWrite_out),
        .Branch_out(ex_Branch_out),
        .ALUSrc_out(ex_ALUSrc_out),
        .ALUOp_out(ex_ALUOp_out),
        .PC_out(ex_PC_out),
        .read_data1_out(ex_rs1_data_out),
        .read_data2_out(ex_rs2_data_out),
        .imm_out(ex_imm_out),
        .rs1_out(ex_rs1_out),
        .rs2_out(ex_rs2_out),
        .rd_out(ex_rd_out)
    );

    ex_mem_reg EX_MEM (
        .clk(clk),
        .rst(rst),
        .RegWrite_in(ex_RegWrite_out),
        .MemtoReg_in(ex_MemtoReg_out),
        .MemRead_in(ex_MemRead_out),
        .MemWrite_in(ex_MemWrite_out),
        .Branch_in(ex_Branch_out),
        .zero_in(ex_zero_in),
        .ALU_result_in(ex_alu_result_in),
        .rs2_data_in(ex_rs2_data_in),
        .branch_target_in(ex_branch_target_in),
        .rd_in(ex_rd_out),

        .RegWrite_out(mem_RegWrite_out),
        .MemtoReg_out(mem_MemtoReg_out),
        .MemRead_out(mem_MemRead_out),
        .MemWrite_out(mem_MemWrite_out),
        .Branch_out(mem_Branch_out),
        .zero_out(mem_zero_out),
        .ALU_result_out(mem_alu_result_out),
        .rs2_data_out(mem_rs2_data_out),
        .branch_target_out(mem_branch_target_out),
        .rd_out(mem_rd_out)
    );

    mem_wb_reg MEM_WB (
        .clk(clk),
        .rst(rst),
        .RegWrite_in(mem_RegWrite_out),
        .MemtoReg_in(mem_MemtoReg_out),
        .read_data_in(mem_read_data_in),
        .ALU_result_in(mem_alu_result_in),
        .rd_in(mem_rd_out),

        .RegWrite_out(wb_RegWrite_out),
        .MemtoReg_out(wb_MemtoReg_out),
        .read_data_out(wb_read_data_out),
        .ALU_result_out(wb_alu_result_out),
        .rd_out(wb_rd_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        if_PC_in = 0;
        if_instruction_in = 0;
        
        id_RegWrite_in = 0; id_MemRead_in = 0; id_MemWrite_in = 0; id_Branch_in = 0; id_ALUSrc_in = 0;
        id_MemtoReg_in = 0;
        id_ALUOp_in = 0;
        id_rs1_data_in = 0; id_rs2_data_in = 0; id_imm_in = 0;
        id_rs1_in = 0; id_rs2_in = 0; id_rd_in = 0;

        ex_zero_in = 0; ex_alu_result_in = 0; ex_rs2_data_in = 0; ex_branch_target_in = 0;
        mem_read_data_in = 0;

        @(posedge clk); #0.1;

        $display("\n--> Applying reset");
        rst = 0;
        @(posedge clk); @(posedge clk); #0.1;

        $display("--> Testing Dummy Data with Reset Active");
        if_PC_in = 32'hFFFFFFFF;
        if_instruction_in = 32'hFFFFFFFF;
        id_RegWrite_in = 1;
        ex_alu_result_in = 32'hABABABAB;

        @(posedge clk); @(posedge clk); #0.1;

        assert(id_PC_out == 32'b0) else $error("IF/ID PC reset failed");
        assert(id_instruction_out == 32'h00000013) else $error("IF/ID instruction reset failed");
        assert(ex_RegWrite_out == 0) else $error("ID/EX RegWrite reset failed");
        assert(mem_alu_result_out == 32'b0) else $error("EX/MEM ALU result reset failed");
        assert(wb_read_data_out == 32'b0) else $error("MEM/WB read data reset failed"); 


        $display("--> Deasserting reset and applying test data");
        rst = 1;
        
        //IF Stage
        if_PC_in = 32'h00000004;
        if_instruction_in = 32'h00A02023;

        //ID Stage
        id_RegWrite_in = 1; id_MemRead_in = 0; id_MemtoReg_in = 2'b01; id_ALUSrc_in = 1;
        id_ALUOp_in = 4'b0010;
        id_rs1_data_in = 32'h11111111; id_imm_in = 32'h00000008; id_rd_in = 5'b01100;

        //EX Stage
        ex_alu_result_in = 32'h33333333; ex_branch_target_in = 32'h00000010;

        //MEM Stage
        mem_read_data_in = 32'h55555555; mem_alu_result_in = 32'h66666666;

        @(posedge clk); #0.1;

        //Check IF/ID outputs
        assert(id_PC_out == 32'h00000004) else $error("IF/ID PC output mismatch");
        assert(id_instruction_out == 32'h00A02023) else $error("IF/ID instruction output mismatch");
        //Check ID/EX outputs
        assert(ex_RegWrite_out == 1) else $error("ID/EX RegWrite output mismatch");
        assert(ex_rs1_data_out == 32'h11111111) else $error("ID/EX read_data1 output mismatch");
        //Check EX/MEM outputs
        assert(mem_alu_result_out == 32'h33333333) else $error("EX/MEM ALU result output mismatch");
        //Check MEM/WB outputs
        assert(wb_read_data_out == 32'h55555555) else $error("MEM/WB read data output mismatch");

        $display("--> Resetting after test");
        rst = 0;

        @(posedge clk); #0.1;

        assert(id_instruction_out == 32'h00000013) else $error("IF/ID instruction reset failed after test");
        assert(ex_rs1_data_out == 32'b0) else $error("ID/EX read_data1 reset failed after test");
        assert(wb_read_data_out == 32'b0) else $error("MEM/WB read data reset failed after test");
        
        $display("--> All tests complete\n");
        $finish;
    end
endmodule