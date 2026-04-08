`timescale 1ns / 1ps

package debug_pkg;

    import signal_pkg::*;

    function automatic string get_inst_name(input logic [31:0] inst);
        logic [6:0] opcode;
        logic [2:0] func3;
        
        if (inst === 32'h00000013 || inst === 32'bx) return "NOP";
        
        opcode = inst[6:0];
        func3 = inst[14:12];

        case(opcode)
            7'b1100011: begin //B-type
                case(func3)
                    FUNC3_BEQ: return "BEQ";
                    FUNC3_BNE: return "BNE";
                    FUNC3_BLT: return "BLT";
                    FUNC3_BGE: return "BGE";
                    FUNC3_BLTU: return "BLTU";
                    FUNC3_BGEU: return "BGEU";
                    default: return "B-TYPE";
                endcase
            end
            OPCODE_J_TYPE: return "JAL";
            OPCODE_J_TYPE_JALR: return "JALR";
            OPCODE_I_TYPE: return "I-TYPE";
            OPCODE_S_TYPE: return "S-TYPE";
            OPCODE_I_TYPE_ALU: return "I-ALU";
            OPCODE_R_TYPE: return "R-TYPE";
            OPCODE_U_TYPE_LUI: return "LUI";
            OPCODE_U_TYPE_AUIPC: return "AUIPC";
            default: return "UNKNOWN";
        endcase
    endfunction

    function automatic logic is_branch_or_jump(input logic [31:0] inst);
        logic [6:0] opcode;
        if (inst === 32'bx) return 1'b0;
        opcode = inst[6:0];
        return (opcode == OPCODE_B_TYPE) || (opcode == OPCODE_J_TYPE) || (opcode == OPCODE_J_TYPE_JALR);
    endfunction
endpackage