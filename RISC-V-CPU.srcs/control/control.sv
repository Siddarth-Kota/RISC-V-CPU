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

    //Main Decoder
    logic [1:0] alu_op;
    always_comb begin
        case (op)
            7'b0000011: begin //I-type
                reg_write = 1'b1;
                mem_write = 1'b0;
                imm_source = 3'b000;
                alu_op = 2'b00;
                alu_source = 1'b1;
                write_back_source = 2'b01;
                branch = 1'b0;
                jump = 1'b0;
            end
            7'b0010011: begin //I-type ALU
                mem_write = 1'b0;
                imm_source = 3'b000;
                alu_op = 2'b10;
                alu_source = 1'b1; //immediate
                write_back_source = 2'b00; //alu result
                branch = 1'b0;
                jump = 1'b0;
                if (func3 == 3'b001) begin
                    reg_write = (func7 == 7'b0000000) ? 1'b1 : 1'b0; //SLLI valid only if func7 is 0000000
                end
                else if (func3 == 3'b101) begin
                    reg_write = (func7 == 7'b0000000 || func7 == 7'b0100000) ? 1'b1 : 1'b0; //SRLI/SRAI valid only if func7 is 0000000 or 0100000
                end
                else begin
                    reg_write = 1'b1;
                end
            end
            7'b0100011: begin //S-type
                reg_write = 1'b0;
                mem_write = 1'b1;
                imm_source = 3'b001;
                alu_op = 2'b00;
                alu_source = 1'b1;
                branch = 1'b0;
                jump = 1'b0;
            end
            7'b0110011 : begin //R-type
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_op = 2'b10;
                alu_source = 1'b0;
                write_back_source = 2'b00;
                branch = 1'b0;
                jump = 1'b0;
            end
            7'b1100011 : begin //B-type
                reg_write = 1'b0;
                mem_write = 1'b0;
                imm_source = 3'b010;
                alu_op = 2'b01;
                alu_source = 1'b0;
                second_add_source = 2'b00;
                branch = 1'b1;
                jump = 1'b0;
            end
            7'b1101111, 7'b1100111 : begin //J-type + JALR
                reg_write = 1'b1;
                mem_write = 1'b0;
                write_back_source = 2'b10; //PC + 4
                branch = 1'b0;
                jump = 1'b1;
                if(op[3]) begin //Jal
                    second_add_source = 2'b00;
                    imm_source = 3'b011;
                end
                else if(~op[3]) begin //Jalr
                    second_add_source = 2'b10;
                    imm_source = 3'b000;
                end

            end
            7'b0110111, 7'b0010111 : begin //U-type
                reg_write = 1'b1;
                imm_source = 3'b100;
                mem_write = 1'b0;
                write_back_source = 2'b11; //U-type immediate
                branch = 1'b0;
                jump = 1'b0;
                case(op[5])
                    1'b0: second_add_source = 2'b00; //AUIPC
                    1'b1: second_add_source = 2'b01; //LUI
                endcase
            end
            default: begin
                reg_write = 1'b0;
                mem_write = 1'b0;
                imm_source = 3'b000;
                alu_op = 2'b00;
                alu_source = 1'b0;
                branch = 1'b0;
                jump = 1'b0;
                write_back_source = 2'b00;
            end
        endcase
    end

    //ALU Decoder
    always_comb begin
        case (alu_op)
            2'b00 : alu_control = 4'b0000; //LW,SW: ADD
            2'b10 : begin //R-type and I-type ALU
                case(func3)
                    3'b000 : begin
                        if(op == 7'b0110011) begin //R-type
                            alu_control = func7[5] ? 4'b0001 : 4'b0000; //SUB : ADD
                        end
                        else begin //I-type ALU
                            alu_control = 4'b0000; //ADDI
                        end
                    end
                    3'b001 : alu_control = 4'b0100; //SLL
                    3'b010 : alu_control = 4'b0101; //SLT
                    3'b011 : alu_control = 4'b0111; //SLTU
                    3'b100 : alu_control = 4'b1000; //XOR
                    3'b101 : if(func7 == 7'b0000000) alu_control = 4'b0110; //SRL
                             else if(func7 == 7'b0100000) alu_control = 4'b1001; //SRA
                             else alu_control = 4'bxxxx; //Invalid
                    3'b110 : alu_control = 4'b0011; //OR
                    3'b111 : alu_control = 4'b0010; //AND
                endcase
            end
            2'b01 : begin
                case (func3)
                    3'b000, 3'b001 : alu_control = 4'b0001; //BEQ, BNE
                    3'b100, 3'b101 : alu_control = 4'b0101; //BLT, BGE
                    3'b110, 3'b111 : alu_control = 4'b0111; //BLTU, BGEU
                endcase
            end
        endcase
    end

    //PC Source Logic
    logic assert_branch;

    always_comb begin : branch_logic_decode
        case(func3)
            3'b000: assert_branch = branch & alu_zero; //BEQ
            3'b001: assert_branch = branch & ~alu_zero; //BNE
            3'b100, 3'b110: assert_branch = alu_last_bit & branch; //BLT, BLTU
            3'b101, 3'b111: assert_branch = ~alu_last_bit & branch; //BGE, BGEU
            default: assert_branch = 1'b0;
        endcase
    end
    assign pc_source = (assert_branch & (op == 7'b1100011)) | jump;
endmodule