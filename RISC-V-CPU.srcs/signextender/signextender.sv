`timescale 1ns / 1ps

module signextender (
        input logic [24:0] raw_src, 
        input logic [1:0] imm_source,

        output logic [31:0] immediate
    );

    always_comb begin
        case (imm_source)
            2'b00: immediate = {{20{raw_src[24]}}, raw_src[24:13]}; //I-type
            2'b01: immediate = {{20{raw_src[24]}}, raw_src[24:18], raw_src[4:0]}; //S-type
            2'b10: immediate = {{20{raw_src[24]}}, raw_src[0],raw_src[23:18],raw_src[4:1],1'b0}; //B-type
            2'b11: immediate = {{12{raw_src[24]}},raw_src[12:5],raw_src[13],raw_src[23:14],1'b0}; //J-type
            default: immediate = 12'b0;
        endcase
    end
endmodule
