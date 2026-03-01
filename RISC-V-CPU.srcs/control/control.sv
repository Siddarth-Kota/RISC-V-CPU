`timescale 1ns / 1ps

module control(
    input logic [6:0] op,
    input logic [2:0] func3,
    input logic [6:0] func7,
    input logic alu_zero,
    input logic alu_last_bit,

    output logic [3:0] alu_control,
    output logic [2:0] imm_source,
    output logic mem_write,
    output logic reg_write,
    output logic alu_source, //0 - register, 1 - immediate
    output logic [1:0] write_back_source, //0 - ALU result, 1 - Memory data
    output logic pc_source, //0 - pc+4, 1 - branch target
    output logic [1:0] second_add_source,
    output logic branch,
    output logic jump
    );

    import signal_pkg::*;

    //Main Decoder
    logic [1:0] alu_op;
    always_comb begin
        case (op)
            OPCODE_I_TYPE: begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                imm_source = IMM_I_TYPE;
                alu_op = 2'b00;
                alu_source = 1'b1;
                write_back_source = 2'b01;
                branch = 1'b0;
                jump = 1'b0;
            end
            OPCODE_I_TYPE_ALU: begin
                mem_write = 1'b0;
                imm_source = IMM_I_TYPE;
                alu_op = 2'b10;
                alu_source = 1'b1; //immediate
                write_back_source = 2'b00; //alu result
                branch = 1'b0;
                jump = 1'b0;
                if (func3 == 3'b001) begin
                    reg_write = (func7 == FUNC7_SLL_SRL) ? 1'b1 : 1'b0;
                end
                else if (func3 == 3'b101) begin
                    reg_write = (func7 == FUNC7_SLL_SRL || func7 == FUNC7_SRA) ? 1'b1 : 1'b0;
                end
                else begin
                    reg_write = 1'b1;
                end
            end
            OPCODE_S_TYPE: begin
                reg_write = 1'b0;
                mem_write = 1'b1;
                imm_source = IMM_S_TYPE;
                alu_op = 2'b00;
                alu_source = 1'b1;
                branch = 1'b0;
                jump = 1'b0;
            end
            OPCODE_R_TYPE : begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_op = 2'b10;
                alu_source = 1'b0;
                write_back_source = 2'b00;
                branch = 1'b0;
                jump = 1'b0;
            end
            OPCODE_B_TYPE : begin
                reg_write = 1'b0;
                mem_write = 1'b0;
                imm_source = IMM_B_TYPE;
                alu_op = 2'b01;
                alu_source = 1'b0;
                second_add_source = 2'b00;
                branch = 1'b1;
                jump = 1'b0;
            end
            OPCODE_J_TYPE, OPCODE_J_TYPE_JALR : begin
                reg_write = 1'b1;
                mem_write = 1'b0;
                write_back_source = 2'b10; //PC + 4
                branch = 1'b0;
                jump = 1'b1;
                if(op[3]) begin //Jal
                    second_add_source = 2'b00;
                    imm_source = IMM_J_TYPE;
                end
                else if(~op[3]) begin //Jalr
                    second_add_source = 2'b10;
                    imm_source = IMM_I_TYPE;
                end

            end
            OPCODE_U_TYPE_LUI, OPCODE_U_TYPE_AUIPC : begin
                reg_write = 1'b1;
                imm_source = IMM_U_TYPE;
                mem_write = 1'b0;
                write_back_source = 2'b11; //U-type immediate
                branch = 1'b0;
                jump = 1'b0;
                case(op[5])
                    1'b0: second_add_source = 2'b00; //AUIPC
                    1'b1: second_add_source = 2'b01; //LUI
                endcase
            end
            default: begin //Invalid instruction
                reg_write = 1'bx;
                mem_write = 1'bx;
                imm_source = 3'bxxx;
                alu_op = 2'bxx;
                alu_source = 1'bx;
                branch = 1'bx;
                jump = 1'bx;
                write_back_source = 2'bxx;
                second_add_source = 2'bxx;
                pc_source = 1'bx;
            end
        endcase
    end

    //ALU Decoder
    always_comb begin
        case (alu_op)
            ALU_OP_LOAD_STORE : alu_control = ALU_ADD;  
            ALU_OP_BRANCHES : begin
                case (func3)
                    FUNC3_BEQ, FUNC3_BNE : alu_control = ALU_SUB;
                    FUNC3_BLT, FUNC3_BGE : alu_control = ALU_SLT;
                    FUNC3_BLTU, FUNC3_BGEU : alu_control = ALU_SLTU;
                endcase
            end
            ALU_OP_MATH : begin //R-type and I-type ALU
                case(func3)
                    FUNC3_ADD_SUB : begin
                        if(op == OPCODE_R_TYPE) begin
                            alu_control = func7[5] ? ALU_SUB : ALU_ADD;
                        end
                        else begin //I-type ALU
                            alu_control = ALU_ADD;
                        end
                    end
                    FUNC3_SLL : alu_control = ALU_SLL; 
                    FUNC3_SLT : alu_control = ALU_SLT;
                    FUNC3_SLTU : alu_control = ALU_SLTU;
                    FUNC3_XOR : alu_control = ALU_XOR;
                    FUNC3_SRL_SRA : if(func7 == FUNC7_SLL_SRL) alu_control = ALU_SRL;
                                    else if(func7 == FUNC7_SRA) alu_control = ALU_SRA;
                                    else alu_control = 4'bxxxx; //Invalid
                    FUNC3_OR : alu_control = ALU_OR;
                    FUNC3_AND : alu_control = ALU_AND;
                endcase
            end
        endcase
    end

    //PC Source Logic
    logic assert_branch;
    always_comb begin : branch_logic_decode
        case(func3)
            FUNC3_BEQ: assert_branch = branch & alu_zero;
            FUNC3_BNE: assert_branch = branch & ~alu_zero;
            FUNC3_BLT, FUNC3_BLTU: assert_branch = alu_last_bit & branch;
            FUNC3_BGE, FUNC3_BGEU: assert_branch = ~alu_last_bit & branch;
            default: assert_branch = 1'b0;
        endcase
    end
    assign pc_source = (assert_branch & (op == OPCODE_B_TYPE)) | jump;
endmodule