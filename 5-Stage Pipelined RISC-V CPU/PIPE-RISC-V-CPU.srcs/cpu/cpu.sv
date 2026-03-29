`timescale 1ns / 1ps

module cpu(
    input logic clk,
    input logic rst_n //active low reset
    );

    import signal_pkg::*;

    /*
     * ----------------------------
     * IF stage (Instruction Fetch)
     * ----------------------------
     */
    logic [31:0] if_PC, if_next_PC, if_instruction, if_pc_plus_4;

    logic id_pc_source;
    logic [31:0] id_branch_target;

    assign if_pc_plus_4 = if_PC + 4;

    always_comb begin : pcSelect
        case (id_pc_source)
            1'b0: if_next_PC = if_pc_plus_4; //next instruction
            1'b1: if_next_PC = id_branch_target; //branch taken
        endcase
    end

    always_ff @(posedge clk) begin : pcUpdate
        if(!rst_n) begin
            if_PC <= 32'b0;
        end
        else begin
            if_PC <= if_next_PC;
        end
    end

    //Instruction Memory (read-only)
    memory #(
        .mem_init("instr_mem_test.hex")
    ) instruction_memory (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(1'b0),
        .address(if_PC),
        .write_data(32'b0),
        .byte_enable(4'b0000),
        
        .read_data(if_instruction)
    );

    //IF --> ID pipeline register
    logic [31:0] id_PC, id_instruction;

    if_id_reg IF_ID_REG (
        .clk(clk),
        .rst_n(rst_n),
        .PC_in(if_PC),
        .instruction_in(if_instruction),

        .PC_out(id_PC),
        .instruction_out(id_instruction)
    );

    /*
     * ----------------------------
     * ID stage (Instruction Decode)
     * ----------------------------
     */

    //decode instruction fields
    logic [6:0] id_opcode = id_instruction[6:0];
    logic [4:0] id_rd = id_instruction[11:7];
    logic [2:0] id_func3 = id_instruction[14:12];
    logic [4:0] id_rs1 = id_instruction[19:15];
    logic [4:0] id_rs2 = id_instruction[24:20];
    logic [6:0] id_func7 = id_instruction[31:25];

    logic [31:0] id_read_data1, id_read_data2;

    logic wb_reg_write_final = 1'b0;
    logic [4:0] wb_write_address_final = 5'b0;
    logic [31:0] wb_write_data_final = 32'b0;

    //register file
    registers registers (
        .clk(clk),
        .rst_n(rst_n),

        .read_address1(id_rs1),
        .read_address2(id_rs2),

        .read_data1(id_read_data1),
        .read_data2(id_read_data2),

        .write_enable(wb_reg_write_final),
        .write_data(wb_write_data_final),
        .write_address(wb_write_address_final)
    );

    //Sign Extender
    logic [31:0] id_immediate;
    logic [2:0] id_imm_source;

    signextender signextender (
        .raw_src(id_instruction[31:7]),
        .imm_source(id_imm_source),

        .immediate(id_immediate)
    );

    //ID stage Early Branch Compare
    logic id_alu_zero;
    logic id_alu_last_bit;

    always_comb begin : IDBranchCompare
        id_alu_zero = (id_read_data1 == id_read_data2);
        if(id_func3 == FUNC3_BLTU || id_func3 == FUNC3_BGEU) begin
            id_alu_last_bit = (id_read_data1 < id_read_data2); //unsigned
        end
        else begin
            id_alu_last_bit = ($signed(id_read_data1) < $signed(id_read_data2)); //signed
        end
    end

    //Control Unit
    logic [3:0] id_alu_control;
    logic id_mem_write, id_reg_write, id_alu_source;
    logic [1:0] id_write_back_source, id_second_add_source;
    logic id_branch, id_jump;

    control control_unit (
        .op(id_opcode),
        .func3(id_func3),
        .func7(id_func7),
        .alu_zero(id_alu_zero),
        .alu_last_bit(id_alu_last_bit),

        .alu_control(id_alu_control),
        .imm_source(id_imm_source),
        .mem_write(id_mem_write),
        .reg_write(id_reg_write),
        .alu_source(id_alu_source),
        .write_back_source(id_write_back_source),
        .pc_source(id_pc_source), //Sends control signal to IF stage for branch decision
        .second_add_source(id_second_add_source),

        .branch(id_branch),
        .jump(id_jump)
    );

    //ID stage Early Branch Adder
    always_comb begin : IDTargetBaseSelect
        case (id_second_add_source)
            2'b00: id_branch_target = id_PC + id_immediate; // Branches, JAL, AUIPC
            2'b01: id_branch_target = id_immediate; // LUI
            2'b10: id_branch_target = id_read_data1 + id_immediate; // JALR
            default: id_branch_target = id_PC + id_immediate;
        endcase
    end
endmodule