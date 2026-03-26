`timescale 1ns / 1ps

module mem_wb_reg(
    input logic clk,
    input logic rst, //active low reset

    //MEM stage inputs
    input logic RegWrite_in,
    input logic [1:0] MemtoReg_in,

    input logic [31:0] read_data_in, ALU_result_in,

    input logic [4:0] rd_in,

    //WB stage outputs
    output logic RegWrite_out,
    output logic [1:0] MemtoReg_out,

    output logic [31:0] read_data_out, ALU_result_out,

    output logic [4:0] rd_out
    );

    always_ff @(posedge clk) begin : MEM_WB_REG
        if(!rst) begin
            RegWrite_out <= 1'b0;
            MemtoReg_out <= 2'b00;
            read_data_out <= 32'b0;
            ALU_result_out <= 32'b0;
            rd_out <= 5'b0;
        end
        else begin
            RegWrite_out <= RegWrite_in;
            MemtoReg_out <= MemtoReg_in;
            read_data_out <= read_data_in;
            ALU_result_out <= ALU_result_in;
            rd_out <= rd_in;
        end
    end
endmodule