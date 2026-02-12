`timescale 1ns / 1ps

module control(
    input logic [6:0] op,
    input logic [2:0] func3,
    input logic [6:0] func7,
    input logic alu_zero,

    output logic [3:0] alu_control,
    output logic [2:0] imm_source,
    output logic mem_write,
    output logic reg_write,
    output logic alu_source, //0 - register, 1 - immediate
    output logic [1:0] write_back_source, //0 - ALU result, 1 - Memory data
    output logic pc_source, //0 - pc+4, 1 - branch target
    output logic second_add_source,
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
                reg_write = 1'b1;
                mem_write = 1'b0;
                imm_source = 3'b000;
                alu_op = 2'b10;
                alu_source = 1'b1; //immediate
                write_back_source = 2'b00; //alu result
                branch = 1'b0;
                jump = 1'b0;
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
                second_add_source = 1'b0;
                branch = 1'b1;
                jump = 1'b0;
            end
            7'b1101111 : begin //J-type
                reg_write = 1'b1;
                imm_source = 3'b011;
                mem_write = 1'b0;
                write_back_source = 2'b10; //PC + 4
                second_add_source = 1'b0;
                branch = 1'b0;
                jump = 1'b1;
            end
            7'b0110111, 7'b0010111 : begin //U-type
                reg_write = 1'b1;
                imm_source = 3'b100;
                mem_write = 1'b0;
                write_back_source = 2'b11; //U-type immediate
                branch = 1'b0;
                jump = 1'b0;
                case(op[5])
                    1'b0: second_add_source = 1'b0; //AUIPC
                    1'b1: second_add_source = 1'b1; //LUI
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
            2'b00 : alu_control = 3'b000; //LW,SW: ADD
            2'b10 : begin //R-type and I-type ALU
                case(func3)
                    3'b000 : alu_control = 4'b0000; //ADD
                    3'b111 : alu_control = 4'b0010; //AND
                    3'b110 : alu_control = 4'b0011; //OR
                    3'b010 : alu_control = 4'b0101; //SLTI
                    3'b011 : alu_control = 4'b0111; //SLTU
                    3'b100 : alu_control = 4'b1000; //XORI
                endcase
            end
            2'b01 : alu_control = 4'b0001; //BEQ: SUB
        endcase
    end

    //PC Source Logic
    logic assert_branch;
    assign assert_branch = branch & alu_zero;
    assign pc_source = (assert_branch & (op == 7'b1100011)) | jump;
endmodule