`timescale 1ns / 1ps

module id_ex_reg(
    input logic clk,
    input logic rst, //active low reset

    //ID stage inputs
    input logic RegWrite_in,
    input logic [1:0] MemtoReg_in,

    input logic MemRead_in, MemWrite_in, Branch_in,

    input logic ALUSrc_in,
    input logic [3:0] ALUOp_in,

    input logic [31:0] PC_in, read_data1_in, read_data2_in, imm_in,

    input logic [4:0] rs1_in, rs2_in, rd_in,

    //EX stage outputs
    output logic RegWrite_out,
    output logic [1:0] MemtoReg_out,

    output logic MemRead_out, MemWrite_out, Branch_out,

    output logic ALUSrc_out,
    output logic [3:0] ALUOp_out,

    output logic [31:0] PC_out, read_data1_out, read_data2_out, imm_out,
    output logic [4:0] rs1_out, rs2_out, rd_out
    );

    always_ff @(posedge clk) begin : ID_EX_REG
        if(!rst) begin
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 2'b00;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
            Branch_out <= 1'b0;
            ALUSrc_out <= 1'b0;
            ALUOp_out <= 4'b0000;
            PC_out <= 32'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            imm_out <= 32'b0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            rd_out <= 5'b0;
        end
        else begin
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            Branch_out <= Branch_in;
            ALUSrc_out <= ALUSrc_in;
            ALUOp_out <= ALUOp_in;
            PC_out <= PC_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            imm_out <= imm_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
        end
    end
endmodule