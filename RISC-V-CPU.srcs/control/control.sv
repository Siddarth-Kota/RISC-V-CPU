`timescale 1ns / 1ps

module control(
    input logic [6:0] op,
    input logic [2:0] func3,
    input logic [6:0] func7,
    input logic alu_zero,

    output logic [2:0] alu_control,
    output logic [1:0] imm_source,
    output logic mem_write,
    output logic reg_write,
    output logic alu_source, //0 - register, 1 - immediate
    output logic write_back_source //0 - ALU result, 1 - Memory data
    );

    //Main Decoder
    logic [1:0] alu_op;
    always_comb begin
        case (op)
            7'b0000011: begin //I-type
                reg_write = 1'b1;
                mem_write = 1'b0;
                imm_source = 2'b0;
                alu_op = 2'b00;
                alu_source = 1'b1;
                write_back_source = 1'b1;
            end
            7'b0100011: begin //S-type
                reg_write = 1'b0;
                mem_write = 1'b1;
                imm_source = 2'b01;
                alu_op = 2'b00;
                alu_source = 1'b1;
            end
            7'b0110011 : begin //R-type
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_op = 2'b10;
                alu_source = 1'b0;
                write_back_source = 1'b0;
            end
            default: begin
                reg_write = 1'b0;
                mem_write = 1'b0;
                imm_source = 2'b00;
                alu_op = 2'b00;
            end
        endcase
    end

    //ALU Decoder
    always_comb begin
        case (alu_op)
            2'b00 : alu_control = 3'b000; //LW,SW: ADD
            2'b10 : begin
                case(func3)
                    3'b000 : alu_control = 3'b000; //ADD
                    3'b111 : alu_control = 3'b011; //AND
                    default: alu_control = 3'b111;
                endcase
            end
            default: alu_control = 3'b111;
        endcase
    end
endmodule