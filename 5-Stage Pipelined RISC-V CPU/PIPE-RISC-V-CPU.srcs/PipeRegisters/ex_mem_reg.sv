`timescale 1ns / 1ps

module ex_mem_reg(
    input logic clk,
    input logic rst, //active low reset

    //EX stage inputs
    input logic RegWrite_in,
    input logic [1:0] MemtoReg_in,

    input logic MemRead_in, MemWrite_in, Branch_in,

    input logic zero_in,
    input logic [31:0] ALU_result_in, rs2_data_in, branch_target_in,
    input logic [4:0] rd_in,

    //MEM stage outputs
    output logic RegWrite_out,
    output logic [1:0] MemtoReg_out,

    output logic MemRead_out, MemWrite_out, Branch_out,
    
    output logic zero_out,
    output logic [31:0] ALU_result_out, rs2_data_out, branch_target_out,
    output logic [4:0] rd_out
    );

    always_ff @(posedge clk) begin : EX_MEM_REG
        if(!rst) begin
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 2'b00;
            MemRead_out <= 1'b0;
            MemWrite_out <= 1'b0;
            Branch_out <= 1'b0;
            zero_out <= 1'b0;
            ALU_result_out <= 32'b0;
            rs2_data_out <= 32'b0;
            branch_target_out <= 32'b0;
            rd_out <= 5'b0;
        end
        else begin
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemRead_out <= MemRead_in;
            MemWrite_out <= MemWrite_in;
            Branch_out <= Branch_in;
            zero_out <= zero_in;
            ALU_result_out <= ALU_result_in;
            rs2_data_out <= rs2_data_in;
            branch_target_out <= branch_target_in;
            rd_out <= rd_in;
        end
    end
endmodule