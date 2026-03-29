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

    //ID --> EX pipeline register
    logic [3:0] ex_alu_control;
    logic ex_mem_write, ex_reg_write, ex_alu_source;
    logic [1:0] ex_write_back_source;
    logic [2:0] ex_func3;
    logic [31:0] ex_pc_plus_4, ex_branch_target, ex_read_data1, ex_read_data2, ex_immediate;
    logic [4:0] ex_rs1, ex_rs2, ex_rd;
    logic [31:0] id_pc_plus_4;
    assign id_pc_plus_4 = id_PC + 4;


    id_ex_reg ID_EX_REG (
        .clk(clk),
        .rst_n(rst_n),

        .RegWrite_in(id_reg_write),
        .MemtoReg_in(id_write_back_source),
        .MemWrite_in(id_mem_write),
        .ALUSrc_in(id_alu_source),
        .ALUOp_in(id_alu_control),

        .func3_in(id_func3),
        .pc_plus_4_in(id_pc_plus_4),
        .branch_target_in(id_branch_target),

        .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2),
        .imm_in(id_immediate),

        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),

        //Outputs
        .RegWrite_out(ex_reg_write),
        .MemtoReg_out(ex_write_back_source),
        .MemWrite_out(ex_mem_write),
        .ALUSrc_out(ex_alu_source),
        .ALUOp_out(ex_alu_control),

        .func3_out(ex_func3),
        .pc_plus_4_out(ex_pc_plus_4),
        .branch_target_out(ex_branch_target),

        .read_data1_out(ex_read_data1),
        .read_data2_out(ex_read_data2),
        .imm_out(ex_immediate),

        .rs1_out(ex_rs1),
        .rs2_out(ex_rs2),
        .rd_out(ex_rd)
    );

    /*
     * ----------------------------
     * EX stage (Execution)
     * ----------------------------
     */

    //ALU
    logic [31:0] alu_operand2;
    logic [31:0] ex_alu_result;

    always_comb begin : ALUSrcSelect
        case (ex_alu_source)
            1'b0: alu_operand2 = ex_read_data2;
            1'b1: alu_operand2 = ex_immediate;
            default: alu_operand2 = ex_read_data2;
        endcase
    end

    ALU ALU (
        .operand1(ex_read_data1),
        .operand2(alu_operand2),
        .alu_control(ex_alu_control),

        .alu_result(ex_alu_result)
    );

    //Byte Enable Decoder
    logic [3:0] ex_mem_byte_enable;
    logic [31:0] ex_mem_write_data;

    be_decoder be_decode (
        .alu_result_address(ex_alu_result),
        .func3(ex_func3),
        .reg_read(ex_read_data2),

        .byte_enable(ex_mem_byte_enable),
        .data(ex_mem_write_data)
    );

    //EX --> MEM pipeline register
    logic mem_reg_write, mem_mem_write;
    logic [1:0] mem_write_back_source;
    logic [2:0] mem_func3;
    logic [31:0] mem_pc_plus_4, mem_branch_target, mem_alu_result, mem_write_data;
    logic [4:0] mem_rd;
    logic [3:0] mem_byte_enable;

    ex_mem_reg EX_MEM_REG (
        .clk(clk),
        .rst_n(rst_n),

        .RegWrite_in(ex_reg_write),
        .MemtoReg_in(ex_write_back_source),
        .MemWrite_in(ex_mem_write),

        .func3_in(ex_func3),
        .pc_plus_4_in(ex_pc_plus_4),

        .ALU_result_in(ex_alu_result),
        .write_data_in(ex_mem_write_data),
        .branch_target_in(ex_branch_target),
        .byte_enable_in(ex_mem_byte_enable),
        .rd_in(ex_rd),

        //Outputs
        .RegWrite_out(mem_reg_write),
        .MemtoReg_out(mem_write_back_source),
        .MemWrite_out(mem_mem_write),

        .func3_out(mem_func3),
        .pc_plus_4_out(mem_pc_plus_4),

        .ALU_result_out(mem_alu_result),
        .write_data_out(mem_write_data),
        .branch_target_out(mem_branch_target),
        .byte_enable_out(mem_byte_enable),
        .rd_out(mem_rd)
    );

    /*
     * ----------------------------
     * MEM stage (Memory Access)
     * ----------------------------
     */
     
    //Data Memory (read/write)
    logic [31:0] mem_read_raw;

    memory #(
        .mem_init("data_mem_test.hex")
    ) data_memory (
        .clk(clk),
        .rst_n(rst_n),
        .address({mem_alu_result[31:2], 2'b00}), //word-aligned addresses
        .write_data(mem_write_data),
        .write_enable(mem_mem_write),
        .byte_enable(mem_byte_enable),

        .read_data(mem_read_raw)
    );

    //Reader
    logic [31:0] mem_read_wb_data;
    logic mem_read_wb_valid;

    reader reader (
        .mem_data(mem_read_raw),
        .be_mask(mem_byte_enable),
        .func3(mem_func3),

        .wb_data(mem_read_wb_data),
        .wb_valid(mem_read_wb_valid)
    );

    //MEM --> WB pipeline register
    logic wb_reg_write_raw;
    logic [1:0] wb_write_back_source;
    logic [31:0] wb_pc_plus_4, wb_branch_target, wb_mem_read_data, wb_alu_result;
    logic wb_mem_read_valid;

    mem_wb_reg MEM_WB_REG (
        .clk(clk),
        .rst_n(rst_n),

        .RegWrite_in(mem_reg_write),
        .MemtoReg_in(mem_write_back_source),

        .mem_read_valid_in(mem_read_wb_valid),

        .mem_read_data_in(mem_read_wb_data),
        .ALU_result_in(mem_alu_result),
        .pc_plus_4_in(mem_pc_plus_4),
        .branch_target_in(mem_branch_target),
        .rd_in(mem_rd),

        //Outputs
        .RegWrite_out(wb_reg_write_raw),
        .MemtoReg_out(wb_write_back_source),

        .mem_read_valid_out(wb_mem_read_valid),

        .mem_read_data_out(wb_mem_read_data),
        .ALU_result_out(wb_alu_result),
        .pc_plus_4_out(wb_pc_plus_4),
        .branch_target_out(wb_branch_target),
        .rd_out(wb_write_address_final)
    );

    /*
     * ----------------------------
     * WB stage (Write Back)
     * ----------------------------
     */

    logic wb_valid;

    always_comb begin : WBSelect
        case(wb_write_back_source)
            2'b00: begin
                wb_write_data_final = wb_alu_result;
                wb_valid = 1'b1;
            end
            2'b01: begin
                wb_write_data_final = wb_mem_read_data;
                wb_valid = wb_mem_read_valid;
            end
            2'b10: begin
                wb_write_data_final = wb_pc_plus_4;
                wb_valid = 1'b1;
            end
            2'b11: begin
                wb_write_data_final = wb_branch_target;
                wb_valid = 1'b1;
            end
        endcase
    end

    assign wb_reg_write_final = wb_reg_write_raw & wb_valid;
endmodule