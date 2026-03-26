`timescale 1ns / 1ps

module if_id_reg(
    input logic clk, 
    input logic rst, //active low reset
    input logic [31:0] PC_in, instruction_in,

    output logic [31:0] PC_out, instruction_out
    );

    always_ff @(posedge clk) begin : IF_ID_REG
        if(!rst) begin
            PC_out <= 32'b0;
            instruction_out <= 32'h00000013; //NOP
        end
        else begin
            PC_out <= PC_in;
            instruction_out <= instruction_in;
        end
    end
endmodule