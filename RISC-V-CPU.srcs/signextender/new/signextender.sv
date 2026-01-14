`timescale 1ns / 1ps

module signextender (
        input logic [24:0] raw_src, 
        input logic [1:0] imm_source, //00: I-type, 01: S-type, 10: B-type
        output logic [31:0] immediate
    );

    logic [11:0] gathered_imm;

    always_comb begin
        case (imm_source)
            1'b00: gathered_imm = raw_src[24:13]; //I-type
            default: gathered_imm = 12'b0;
        endcase
    end

    assign immediate = {{20{gathered_imm[11]}}, gathered_imm}; //sign-extend to 32 bits
endmodule
