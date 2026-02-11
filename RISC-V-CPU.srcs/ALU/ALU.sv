`timescale 1ns / 1ps

module ALU (
    input logic [2:0] alu_control,
    input logic [31:0] operand1,
    input logic [31:0] operand2,

    output logic [31:0] alu_result,
    output logic zero
    );

    always_comb begin
        case(alu_control)
            3'b000 : alu_result = operand1 + operand2; //ADD
            3'b010 : alu_result = operand1 & operand2; //AND
            3'b011 : alu_result = operand1 | operand2; //OR
            3'b001 : alu_result = operand1 + (~operand2 + 1'b1); //SUB
            3'b101 : alu_result = {31'b0, $signed(operand1) < $signed(operand2)}; //SLTI
            3'b111 : alu_result = {31'b0, operand1 < operand2}; //SLTU
            default: alu_result = 32'b0;
        endcase
    end

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0; //set zero flag
endmodule
