`timescale 1ns / 1ps

module ALU (
    input logic [3:0] alu_control,
    input logic [31:0] operand1,
    input logic [31:0] operand2,

    output logic [31:0] alu_result,
    output logic zero,
    output logic last_bit
    );

    always_comb begin
        case(alu_control)
            4'b0000 : alu_result = operand1 + operand2; //ADD
            4'b0001 : alu_result = operand1 + (~operand2 + 1'b1); //SUB
            4'b0010 : alu_result = operand1 & operand2; //AND
            4'b0011 : alu_result = operand1 | operand2; //OR
            4'b0100 : alu_result = operand1 << operand2[4:0]; //SLL
            4'b0101 : alu_result = {31'b0, $signed(operand1) < $signed(operand2)}; //SLT
            4'b0110 : alu_result = operand1 >> operand2[4:0]; //SRL
            4'b0111 : alu_result = {31'b0, operand1 < operand2}; //SLTU
            4'b1001 : alu_result = $signed(operand1) >>> operand2[4:0]; //SRA
            4'b1000 : alu_result = operand1 ^ operand2; //XOR
            default: alu_result = 32'b0;
        endcase
    end

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0; //set zero flag
    assign last_bit = alu_result[0];
endmodule
