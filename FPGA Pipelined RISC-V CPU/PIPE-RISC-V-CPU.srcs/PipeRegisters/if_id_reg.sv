`timescale 1ns / 1ps

module if_id_reg(
    input logic clk, 
    input logic rst_n, //active low reset
    input logic [31:0] PC_in, instruction_in,
    input logic predict_taken_in,
    input logic [31:0] predicted_target_in,

    output logic [31:0] PC_out, instruction_out,
    output logic predict_taken_out,
    output logic [31:0] predicted_target_out
    );

    always_ff @(posedge clk) begin : IF_ID_REG
        if(!rst_n) begin
            PC_out <= 32'b0;
            instruction_out <= 32'h00000013; //NOP
            predict_taken_out <= 1'b0;
            predicted_target_out <= 32'b0;
        end
        else begin
            PC_out <= PC_in;
            instruction_out <= instruction_in;
            predict_taken_out <= predict_taken_in;
            predicted_target_out <= predicted_target_in;
        end
    end
endmodule