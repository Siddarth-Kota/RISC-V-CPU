`timescale 1ns / 1ps

module id_ex_reg(
    input logic clk,
    input logic rst_n, //active low reset

    //ID stage inputs
    input logic RegWrite_in,
    input logic [1:0] MemtoReg_in,

    input logic MemWrite_in,

    input logic ALUSrc_in,
    input logic [3:0] ALUOp_in,

    input logic [2:0] func3_in,
    input logic [31:0] pc_plus_4_in, branch_target_in,

    input logic [31:0] read_data1_in, read_data2_in, imm_in,

    input logic [4:0] rs1_in, rs2_in, rd_in,

    //EX stage outputs
    output logic RegWrite_out,
    output logic [1:0] MemtoReg_out,

    output logic MemWrite_out,

    output logic ALUSrc_out,
    output logic [3:0] ALUOp_out,

    output logic [2:0] func3_out,
    output logic [31:0] pc_plus_4_out, branch_target_out,

    output logic [31:0] read_data1_out, read_data2_out, imm_out,
    output logic [4:0] rs1_out, rs2_out, rd_out
    );

    always_ff @(posedge clk) begin : ID_EX_REG
        if(!rst_n) begin
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 2'b00;
            MemWrite_out <= 1'b0;
            ALUSrc_out <= 1'b0;
            ALUOp_out <= 4'b0000;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            imm_out <= 32'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            rd_out <= 5'b0;
            func3_out <= 3'b0;
            pc_plus_4_out <= 32'b0;
            branch_target_out <= 32'b0;
        end
        else begin
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemWrite_out <= MemWrite_in;
            ALUSrc_out <= ALUSrc_in;
            ALUOp_out <= ALUOp_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            imm_out <= imm_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            func3_out <= func3_in;
            pc_plus_4_out <= pc_plus_4_in;
            branch_target_out <= branch_target_in;
        end
    end
endmodule