`timescale 1ns / 1ps

package debug_pkg;

    import signal_pkg::*;

    function automatic string get_inst_name(input logic [31:0] inst);
        logic [6:0] opcode;
        logic [2:0] func3;
        logic [6:0] func7; // NEW: Need func7 to tell ADD from SUB, and SRL from SRA
        
        if (inst === 32'h00000013 || inst === 32'bx) return "NOP";
        
        opcode = inst[6:0];
        func3  = inst[14:12];
        func7  = inst[31:25];

        case(opcode)
            OPCODE_B_TYPE: begin 
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
            OPCODE_R_TYPE: begin
                case(func3)
                    FUNC3_ADD_SUB: return (func7 == FUNC7_SUB) ? "SUB" : "ADD";
                    FUNC3_SLL: return "SLL";
                    FUNC3_SLT: return "SLT";
                    FUNC3_SLTU: return "SLTU";
                    FUNC3_XOR: return "XOR";
                    FUNC3_SRL_SRA: return (func7 == FUNC7_SRA) ? "SRA" : "SRL";
                    FUNC3_OR: return "OR";
                    FUNC3_AND: return "AND";
                    default: return "R-TYPE";
                endcase
            end
            OPCODE_I_TYPE_ALU: begin
                case(func3)
                    FUNC3_ADD_SUB: return "ADDI";
                    FUNC3_SLL: return "SLLI";
                    FUNC3_SLT: return "SLTI";
                    FUNC3_SLTU: return "SLTIU";
                    FUNC3_XOR: return "XORI";
                    FUNC3_SRL_SRA: return (func7 == FUNC7_SRA) ? "SRAI" : "SRLI";
                    FUNC3_OR: return "ORI";
                    FUNC3_AND: return "ANDI";
                    default: return "I-ALU";
                endcase
            end
            OPCODE_I_TYPE: begin
                case(func3)
                    FUNC3_BYTE: return "LB";
                    FUNC3_HALFWORD: return "LH";
                    FUNC3_WORD: return "LW";
                    FUNC3_BYTE_U: return "LBU";
                    FUNC3_HALFWORD_U: return "LHU";
                    default: return "LOAD";
                endcase
            end
            OPCODE_S_TYPE: begin
                case(func3)
                    FUNC3_BYTE: return "SB";
                    FUNC3_HALFWORD: return "SH";
                    FUNC3_WORD: return "SW";
                    default: return "STORE";
                endcase
            end
            OPCODE_J_TYPE:       return "JAL";
            OPCODE_J_TYPE_JALR:  return "JALR";
            OPCODE_U_TYPE_LUI:   return "LUI";
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