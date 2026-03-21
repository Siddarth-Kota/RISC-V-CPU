`timescale 1ns / 1ps

module ALU (
    input logic [3:0] alu_control,
    input logic [31:0] operand1,
    input logic [31:0] operand2,

    output logic [31:0] alu_result,
    output logic zero,
    output logic last_bit
    );

    import signal_pkg::*;

    always_comb begin
        case(alu_control)
            ALU_ADD : alu_result = operand1 + operand2;
            ALU_SUB : alu_result = operand1 + (~operand2 + 1'b1);
            ALU_AND : alu_result = operand1 & operand2;
            ALU_OR : alu_result = operand1 | operand2;
            ALU_SLL : alu_result = operand1 << operand2[4:0];
            ALU_SLT : alu_result = {31'b0, $signed(operand1) < $signed(operand2)};
            ALU_SRL : alu_result = operand1 >> operand2[4:0];
            ALU_SLTU : alu_result = {31'b0, operand1 < operand2};
            ALU_SRA : alu_result = $signed(operand1) >>> operand2[4:0];
            ALU_XOR : alu_result = operand1 ^ operand2;
            default: alu_result = 32'b0;
        endcase
    end

    assign zero = (alu_result == 32'b0) ? 1'b1 : 1'b0; //set zero flag
    assign last_bit = alu_result[0];
endmodule
