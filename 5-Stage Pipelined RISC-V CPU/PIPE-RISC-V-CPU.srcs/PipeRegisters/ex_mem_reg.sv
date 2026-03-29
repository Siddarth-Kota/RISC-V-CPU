`timescale 1ns / 1ps

module ex_mem_reg(
    input logic clk,
    input logic rst_n, //active low reset

    //EX stage inputs
    input logic RegWrite_in,
    input logic [1:0] MemtoReg_in,

    input logic MemWrite_in,

    input logic [2:0] func3_in,
    input logic [31:0] pc_plus_4_in,

    input logic [31:0] ALU_result_in, write_data_in, branch_target_in,
    input logic [4:0] rd_in,
    input logic [3:0] byte_enable_in,

    //MEM stage outputs
    output logic RegWrite_out,
    output logic [1:0] MemtoReg_out,

    output logic MemWrite_out,

    output logic [2:0] func3_out,
    output logic [31:0] pc_plus_4_out,
    
    output logic [31:0] ALU_result_out, write_data_out, branch_target_out,
    output logic [4:0] rd_out,
    output logic [3:0] byte_enable_out
    );

    always_ff @(posedge clk) begin : EX_MEM_REG
        if(!rst_n) begin
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 2'b00;
            MemWrite_out <= 1'b0;
            ALU_result_out <= 32'b0;
            write_data_out <= 32'b0;
            rd_out <= 5'b0;
            func3_out <= 3'b0;
            pc_plus_4_out <= 32'b0;
            branch_target_out <= 32'b0;
            byte_enable_out <= 4'b0;
        end
        else begin
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            MemWrite_out <= MemWrite_in;
            ALU_result_out <= ALU_result_in;
            write_data_out <= write_data_in;
            rd_out <= rd_in;
            func3_out <= func3_in;
            pc_plus_4_out <= pc_plus_4_in;
            branch_target_out <= branch_target_in;
            byte_enable_out <= byte_enable_in;
        end
    end
endmodule