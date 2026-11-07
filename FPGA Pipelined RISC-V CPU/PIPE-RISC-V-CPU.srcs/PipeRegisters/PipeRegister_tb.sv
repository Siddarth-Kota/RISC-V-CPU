`timescale 1ns / 1ps

module PipeRegister_tb;
    logic clk; 
    logic rst_n; // Active low reset
    
    // IF --> ID register signals
    logic [31:0] if_PC_in, if_instruction_in;
    logic [31:0] id_PC_out, id_instruction_out;

    // ID --> EX register signals
    logic id_RegWrite_in, id_MemWrite_in, id_ALUSrc_in;
    logic [1:0] id_MemtoReg_in;
    logic [3:0] id_ALUOp_in;
    logic [2:0] id_func3_in;
    logic [31:0] id_pc_plus_4_in, id_branch_target_in, id_read_data1_in, id_read_data2_in, id_imm_in;
    logic [4:0] id_rs1_in, id_rs2_in, id_rd_in;

    logic ex_RegWrite_out, ex_MemWrite_out, ex_ALUSrc_out;
    logic [1:0] ex_MemtoReg_out;
    logic [3:0] ex_ALUOp_out;
    logic [2:0] ex_func3_out;
    logic [31:0] ex_pc_plus_4_out, ex_branch_target_out, ex_read_data1_out, ex_read_data2_out, ex_imm_out;
    logic [4:0] ex_rs1_out, ex_rs2_out, ex_rd_out;

    // EX --> MEM register signals
    logic [3:0] ex_byte_enable_in;
    logic [31:0] ex_alu_result_in, ex_write_data_in;

    logic mem_RegWrite_out, mem_MemWrite_out;
    logic [1:0] mem_MemtoReg_out;
    logic [2:0] mem_func3_out;
    logic [3:0] mem_byte_enable_out;
    logic [31:0] mem_pc_plus_4_out, mem_alu_result_out, mem_write_data_out, mem_branch_target_out;
    logic [4:0] mem_rd_out;

    // MEM --> WB register signals
    logic mem_read_valid_in;
    logic [31:0] mem_read_data_in;

    logic wb_RegWrite_out, wb_mem_read_valid_out;
    logic [1:0] wb_MemtoReg_out;
    logic [31:0] wb_read_data_out, wb_alu_result_out, wb_pc_plus_4_out, wb_branch_target_out;
    logic [4:0] wb_rd_out;

    // Instantiate IF_ID
    if_id_reg IF_ID (
        .clk(clk),
        .rst_n(rst_n), // Fixed port name
        .PC_in(if_PC_in),
        .instruction_in(if_instruction_in),
        .PC_out(id_PC_out),
        .instruction_out(id_instruction_out)
    );

    // Instantiate ID_EX
    id_ex_reg ID_EX (
        .clk(clk),
        .rst_n(rst_n),
        .RegWrite_in(id_RegWrite_in),
        .MemtoReg_in(id_MemtoReg_in),
        .MemWrite_in(id_MemWrite_in),
        .ALUSrc_in(id_ALUSrc_in),
        .ALUOp_in(id_ALUOp_in),
        .func3_in(id_func3_in),
        .pc_plus_4_in(id_pc_plus_4_in),
        .branch_target_in(id_branch_target_in),
        .read_data1_in(id_read_data1_in),
        .read_data2_in(id_read_data2_in),
        .imm_in(id_imm_in),
        .rs1_in(id_rs1_in),
        .rs2_in(id_rs2_in),
        .rd_in(id_rd_in),

        .RegWrite_out(ex_RegWrite_out),
        .MemtoReg_out(ex_MemtoReg_out),
        .MemWrite_out(ex_MemWrite_out),
        .ALUSrc_out(ex_ALUSrc_out),
        .ALUOp_out(ex_ALUOp_out),
        .func3_out(ex_func3_out),
        .pc_plus_4_out(ex_pc_plus_4_out),
        .branch_target_out(ex_branch_target_out),
        .read_data1_out(ex_read_data1_out),
        .read_data2_out(ex_read_data2_out),
        .imm_out(ex_imm_out),
        .rs1_out(ex_rs1_out),
        .rs2_out(ex_rs2_out),
        .rd_out(ex_rd_out)
    );

    // Instantiate EX_MEM
    ex_mem_reg EX_MEM (
        .clk(clk),
        .rst_n(rst_n),
        .RegWrite_in(ex_RegWrite_out),
        .MemtoReg_in(ex_MemtoReg_out),
        .MemWrite_in(ex_MemWrite_out),
        .func3_in(ex_func3_out),
        .pc_plus_4_in(ex_pc_plus_4_out),
        .ALU_result_in(ex_alu_result_in),
        .write_data_in(ex_write_data_in),
        .branch_target_in(ex_branch_target_out),
        .rd_in(ex_rd_out),
        .byte_enable_in(ex_byte_enable_in),

        .RegWrite_out(mem_RegWrite_out),
        .MemtoReg_out(mem_MemtoReg_out),
        .MemWrite_out(mem_MemWrite_out),
        .func3_out(mem_func3_out),
        .pc_plus_4_out(mem_pc_plus_4_out),
        .ALU_result_out(mem_alu_result_out),
        .write_data_out(mem_write_data_out),
        .branch_target_out(mem_branch_target_out),
        .rd_out(mem_rd_out),
        .byte_enable_out(mem_byte_enable_out)
    );

    // Instantiate MEM_WB
    mem_wb_reg MEM_WB (
        .clk(clk),
        .rst_n(rst_n),
        .RegWrite_in(mem_RegWrite_out),
        .MemtoReg_in(mem_MemtoReg_out),
        .mem_read_valid_in(mem_read_valid_in),
        .read_data_in(mem_read_data_in),
        .ALU_result_in(mem_alu_result_out),
        .pc_plus_4_in(mem_pc_plus_4_out),
        .branch_target_in(mem_branch_target_out),
        .rd_in(mem_rd_out),

        .RegWrite_out(wb_RegWrite_out),
        .MemtoReg_out(wb_MemtoReg_out),
        .mem_read_valid_out(wb_mem_read_valid_out),
        .read_data_out(wb_read_data_out),
        .ALU_result_out(wb_alu_result_out),
        .pc_plus_4_out(wb_pc_plus_4_out),
        .branch_target_out(wb_branch_target_out),
        .rd_out(wb_rd_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 1;

        if_PC_in = 0;
        if_instruction_in = 0;
        
        id_RegWrite_in = 0; id_MemWrite_in = 0; id_ALUSrc_in = 0;
        id_MemtoReg_in = 0;
        id_ALUOp_in = 0; id_func3_in = 0;
        id_pc_plus_4_in = 0; id_branch_target_in = 0;
        id_read_data1_in = 0; id_read_data2_in = 0; id_imm_in = 0;
        id_rs1_in = 0; id_rs2_in = 0; id_rd_in = 0;

        ex_byte_enable_in = 0; ex_alu_result_in = 0; ex_write_data_in = 0;
        
        mem_read_valid_in = 0; mem_read_data_in = 0;

        @(posedge clk); #0.1;

        $display("\n--> Applying reset");
        rst_n = 0;
        @(posedge clk); @(posedge clk); #0.1;

        $display("--> Testing Dummy Data with Reset Active");
        if_PC_in = 32'hFFFFFFFF;
        if_instruction_in = 32'hFFFFFFFF;
        id_RegWrite_in = 1;
        ex_alu_result_in = 32'hABABABAB;

        @(posedge clk); @(posedge clk); #0.1;

        assert(id_PC_out == 32'b0) else $error("IF/ID PC reset failed. Expected 0x00000000, got %h", id_PC_out);
        assert(id_instruction_out == 32'h00000013) else $error("IF/ID instruction reset failed. Expected 0x00000013, got %h", id_instruction_out);
        assert(ex_RegWrite_out == 0) else $error("ID/EX RegWrite reset failed. Expected 0, got %h", ex_RegWrite_out);
        assert(mem_alu_result_out == 32'b0) else $error("EX/MEM ALU result reset failed. Expected 0x00000000, got %h", mem_alu_result_out);
        assert(wb_read_data_out == 32'b0) else $error("MEM/WB read data reset failed. Expected 0x00000000, got %h", wb_read_data_out); 

        $display("--> Deasserting reset and applying test data");
        rst_n = 1;
        
        //IF Stage
        if_PC_in = 32'h00000004;
        if_instruction_in = 32'h00A02023;

        //ID Stage
        id_RegWrite_in = 1; id_MemtoReg_in = 2'b01; id_ALUSrc_in = 1;
        id_ALUOp_in = 4'b0010;
        id_read_data1_in = 32'h11111111; id_imm_in = 32'h00000008; id_rd_in = 5'b01100;

        //EX Stage
        ex_alu_result_in = 32'h33333333; ex_write_data_in = 32'h44444444; ex_byte_enable_in = 4'b1111;

        //MEM Stage
        mem_read_data_in = 32'h55555555; mem_read_valid_in = 1;

        @(posedge clk); #0.1;

        assert(id_PC_out == 32'h00000004) else $error("IF/ID PC output mismatch. Expected 0x00000004, got %h", id_PC_out);
        assert(id_instruction_out == 32'h00A02023) else $error("IF/ID instruction output mismatch. Expected 0x00A02023, got %h", id_instruction_out);

        assert(ex_RegWrite_out == 1) else $error("ID/EX RegWrite output mismatch. Expected 1, got %h", ex_RegWrite_out);
        assert(ex_read_data1_out == 32'h11111111) else $error("ID/EX read_data1 output mismatch. Expected 0x11111111, got %h", ex_read_data1_out);

        assert(mem_alu_result_out == 32'h33333333) else $error("EX/MEM ALU result output mismatch. Expected 0x33333333, got %h", mem_alu_result_out);

        //WB Stage
        assert(wb_read_data_out == 32'h55555555) else $error("MEM/WB read data output mismatch. Expected 0x55555555, got %h", wb_read_data_out);

        $display("--> Resetting after test");
        rst_n = 0;

        @(posedge clk); #0.1;

        assert(id_instruction_out == 32'h00000013) else $error("IF/ID instruction reset failed after test. Expected 0x00000013, got %h", id_instruction_out);
        assert(ex_read_data1_out == 32'b0) else $error("ID/EX read_data1 reset failed after test. Expected 0x0, got %h", ex_read_data1_out);
        assert(wb_read_data_out == 32'b0) else $error("MEM/WB read data reset failed after test. Expected 0x0, got %h", wb_read_data_out);
        
        $display("--> All tests complete\n");
        $finish;
    end
endmodule