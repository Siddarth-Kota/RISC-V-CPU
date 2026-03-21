`timescale 1ns / 1ps

module signextender (
        input logic [24:0] raw_src, 
        input logic [2:0] imm_source,

        output logic [31:0] immediate
    );

    import signal_pkg::*;

    always_comb begin
        case (imm_source)
            IMM_I_TYPE: immediate = {{20{raw_src[24]}}, raw_src[24:13]};
            IMM_S_TYPE: immediate = {{20{raw_src[24]}}, raw_src[24:18], raw_src[4:0]};
            IMM_B_TYPE: immediate = {{20{raw_src[24]}}, raw_src[0],raw_src[23:18],raw_src[4:1],1'b0};
            IMM_J_TYPE: immediate = {{12{raw_src[24]}},raw_src[12:5],raw_src[13],raw_src[23:14],1'b0};
            IMM_U_TYPE: immediate = {raw_src[24:5], 12'b0};
            default: immediate = 12'b0;
        endcase
    end
endmodule
