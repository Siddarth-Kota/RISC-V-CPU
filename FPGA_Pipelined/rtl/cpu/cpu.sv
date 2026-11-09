`timescale 1ns / 1ps
`default_nettype none // Require explicit signal declarations to catch typos.

module cpu #(
    parameter bit PREDICT = 1'b1,
    parameter bit PREFETCH = 1'b0
)(
    input logic clk, rst_n,
    input logic imem_req_ready,
    input logic imem_rsp_valid,
    input logic [31:0] imem_rsp_data,
    input  logic dmem_req_ready,
    input  logic dmem_rsp_valid,
    input  logic [31:0] dmem_rsp_data,

    output logic imem_req_valid,
    output logic [31:0] imem_req_addr,
    output logic imem_rsp_ready,
    output logic dmem_req_valid,
    output logic [31:0] dmem_req_addr,
    output logic dmem_req_write,
    output logic [31:0] dmem_req_wdata,
    output logic [3:0] dmem_req_be,
    output logic dmem_rsp_ready,
    output logic retire_valid,
    output logic [31:0] retire_pc, retire_instruction,
    output logic retire_reg_write,
    output logic [4:0] retire_rd,
    output logic [31:0] retire_wdata
);

    import signal_pkg::*;

    /*
     * ------------------------------------------------------------
     * Pipeline payload types and shared signals
     * ------------------------------------------------------------
     */

    // A valid bit distinguishes an instruction from an empty pipeline entry.
    typedef struct packed {
        logic valid;
        logic [31:0] pc, instruction;
        logic predicted_taken;
        logic [31:0] predicted_target;
    } decode_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, instruction, a, b, immediate, target;
        logic [4:0] rs1, rs2, rd;
        logic [2:0] func3;
        logic [3:0] alu_control;
        logic alu_source, reg_write, mem_write;
        logic [1:0] wb_source;
    } execute_t;

    typedef struct packed {
        logic valid;
        logic [31:0] pc, instruction, alu_result, target, store_data;
        logic [4:0] rd;
        logic [2:0] func3;
        logic [3:0] be;
        logic reg_write, mem_write;
        logic [1:0] wb_source;
    } memory_t;

    typedef struct packed {
        logic valid, reg_write;
        logic [31:0] pc, instruction, data;
        logic [4:0] rd;
    } writeback_t;

    decode_t id, fetch_buffer;
    execute_t ex;
    memory_t mem;
    writeback_t wb;

    // Offer state holds a blocked request; pending state tracks an accepted one.
    logic [31:0] fetch_pc, offer_pc, offer_target;
    logic offer_valid, offer_taken, offer_killed;
    logic fetch_pending, pending_killed;
    logic [31:0] pending_pc, pending_target;
    logic pending_taken;
    logic predict_taken_raw, predict_taken;
    logic [31:0] predicted_target;
    logic [31:0] id_a, id_b, id_imm, id_target;
    logic [2:0] imm_source;
    logic [3:0] alu_control;
    logic mem_write, reg_write, alu_source, pc_source, branch, jump;
    logic [1:0] wb_source, target_source;
    logic op1_lt_op2, hazard_stall, id_fire, redirect, mispredict;
    logic [31:0] recovery_pc;
    logic [31:0] ex_a, ex_b, ex_result, store_data;
    logic [3:0] byte_enable;
    logic data_pending, mem_access, mem_complete, mem_wait;
    logic [31:0] load_data, mem_result;
    logic load_valid, mem_forward, buffer_consume;

    /*
     * ------------------------------------------------------------
     * IF stage (Instruction Fetch and Prediction)
     * ------------------------------------------------------------
     */

    branch_predictor branch_predictor (
        .clk(clk), .rst_n(rst_n), .if_pc(fetch_pc),
        .id_is_branch(id_fire && (branch || jump)), .id_pc(id.pc),
        .id_actual_taken(pc_source), .id_actual_target(id_target),
        .predict_taken(predict_taken_raw), .predicted_target(predicted_target)
    );
    assign predict_taken = PREDICT && predict_taken_raw;

    assign buffer_consume = !mem_wait && (!id.valid || !hazard_stall);

    // Registered request offers remain stable even when a redirect occurs while
    // ready is low. Such an offer must still be accepted, then drained and killed.
    assign imem_req_valid = rst_n && offer_valid;
    assign imem_req_addr = offer_pc;
    assign imem_rsp_ready = rst_n && fetch_pending && !fetch_buffer.valid;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            fetch_pc <= 0;
            offer_valid <= 0;
            offer_pc <= 0;
            offer_target <= 0;
            offer_taken <= 0;
            offer_killed <= 0;
            fetch_pending <= 0;
            pending_pc <= 0;
            pending_target <= 0;
            pending_taken <= 0;
            pending_killed <= 0;
            fetch_buffer <= '0;
        end else begin
            if (!offer_valid && !fetch_pending && (!fetch_buffer.valid || PREFETCH)) begin
                offer_valid <= 1;
                offer_pc <= fetch_pc;
                offer_taken <= predict_taken;
                offer_target <= predicted_target;
                offer_killed <= redirect;
                fetch_pc <= predict_taken ? predicted_target : fetch_pc + 32'd4;
            end
            // Save the accepted fetch's PC and prediction until its response returns.
            if (imem_req_valid && imem_req_ready) begin
                offer_valid <= 0;
                fetch_pending <= 1;
                pending_pc <= offer_pc;
                pending_taken <= offer_taken;
                pending_target <= offer_target;
                pending_killed <= offer_killed || redirect;
            end
            if (buffer_consume) fetch_buffer.valid <= 0;
            if (imem_rsp_valid && imem_rsp_ready) begin
                fetch_pending <= 0;
                fetch_buffer.valid <= !pending_killed && !redirect;
                fetch_buffer.pc <= pending_pc;
                fetch_buffer.instruction <= imem_rsp_data;
                fetch_buffer.predicted_taken <= pending_taken;
                fetch_buffer.predicted_target <= pending_target;
            end
            if (redirect) begin
                fetch_pc <= recovery_pc;
                fetch_buffer.valid <= 0;
                if (offer_valid) offer_killed <= 1;
                if (fetch_pending) pending_killed <= 1;
            end
        end
    end

    /*
     * ------------------------------------------------------------
     * ID stage (Instruction Decode and Early Branch Resolution)
     * ------------------------------------------------------------
     */

    registers registers (
        .clk(clk), .rst_n(rst_n),
        .read_address1(id.instruction[19:15]), .read_address2(id.instruction[24:20]),
        .read_data1(id_a), .read_data2(id_b),
        .write_enable(retire_reg_write), .write_address(wb.rd), .write_data(wb.data)
    );

    signextender signextender (
        .raw_src(id.instruction[31:7]), .imm_source(imm_source), .immediate(id_imm)
    );

    assign op1_lt_op2 = (id.instruction[14:12] == FUNC3_BLTU || id.instruction[14:12] == FUNC3_BGEU) ? (id_a < id_b) : ($signed(id_a) < $signed(id_b));

    control control_unit (
        .op(id.instruction[6:0]), .func3(id.instruction[14:12]), .func7(id.instruction[31:25]),
        .op_equal(id_a == id_b), .op1_lt_op2(op1_lt_op2),
        .alu_control(alu_control), .imm_source(imm_source), .mem_write(mem_write),
        .reg_write(reg_write), .alu_source(alu_source), .write_back_source(wb_source),
        .pc_source(pc_source), .second_add_source(target_source), .branch(branch), .jump(jump)
    );

    always_comb begin
        case (target_source)
            2'b01: id_target = id_imm;
            2'b10: id_target = (id_a + id_imm) & 32'hfffffffe; // JALR clears bit 0.
            default: id_target = id.pc + id_imm;
        endcase
    end

    hazard_detection hazard_detection_unit (
        .id_opcode(id.instruction[6:0]), .id_rs1(id.instruction[19:15]), .id_rs2(id.instruction[24:20]),
        .ex_rd(ex.rd), .ex_reg_write(ex.valid && ex.reg_write),
        .ex_write_back_source(ex.valid ? ex.wb_source : 2'b00),
        .mem_rd(mem.rd), .mem_reg_write(mem.valid && mem.reg_write), .stall(hazard_stall)
    );

    // Resolve and train only when ID advances, not while an instruction is held.
    assign id_fire = id.valid && !hazard_stall && !mem_wait;
    assign mispredict = (id.predicted_taken != pc_source) || (pc_source && id.predicted_target != id_target);
    assign recovery_pc = pc_source ? id_target : id.pc + 32'd4;
    assign redirect = id_fire && mispredict;

    /*
     * ------------------------------------------------------------
     * EX stage (Forwarding, ALU and Store Alignment)
     * ------------------------------------------------------------
     */

    assign mem_forward = mem.valid && mem.reg_write && (mem.wb_source != 2'b01 || mem_complete);
    // MEM overrides WB when both match; a pending load cannot forward yet.
    always_comb begin
        ex_a = ex.a;
        ex_b = ex.b;
        if (wb.valid && wb.reg_write && wb.rd != 0 && wb.rd == ex.rs1) ex_a = wb.data;
        if (wb.valid && wb.reg_write && wb.rd != 0 && wb.rd == ex.rs2) ex_b = wb.data;
        if (mem_forward && mem.rd != 0 && mem.rd == ex.rs1) ex_a = mem_result;
        if (mem_forward && mem.rd != 0 && mem.rd == ex.rs2) ex_b = mem_result;
    end
    ALU ALU (
        .operand1(ex_a), .operand2(ex.alu_source ? ex.immediate : ex_b),
        .alu_control(ex.alu_control), .alu_result(ex_result)
    );
    be_decoder be_decode (
        .alu_result_address(ex_result), .func3(ex.func3), .reg_read(ex_b),
        .byte_enable(byte_enable), .data(store_data)
    );

    /*
     * ------------------------------------------------------------
     * MEM stage (Data Requests and Load Result Selection)
     * ------------------------------------------------------------
     */

    // MEM is the transaction holding register: destination, size, byte lanes and
    // writeback selection remain attached to the request until its response.
    assign mem_access = mem.valid && (mem.mem_write || mem.wb_source == 2'b01) && |mem.be;
    // Once accepted, suppress the request until its response completes the access.
    assign dmem_req_valid = rst_n && mem_access && !data_pending;
    assign dmem_req_addr = {mem.alu_result[31:2], 2'b00};
    assign dmem_req_write = mem.mem_write;
    assign dmem_req_wdata = mem.store_data;
    assign dmem_req_be = mem.be;
    assign dmem_rsp_ready = rst_n && data_pending;
    assign mem_complete = data_pending && dmem_rsp_valid;
    assign mem_wait = mem_access && !mem_complete;
    always_ff @(posedge clk) begin
        if (!rst_n) data_pending <= 0;
        else begin
            if (dmem_req_valid && dmem_req_ready) data_pending <= 1;
            if (dmem_rsp_valid && dmem_rsp_ready) data_pending <= 0;
        end
    end
    reader reader (
        .mem_data(dmem_rsp_data), .be_mask(mem.be), .func3(mem.func3),
        .wb_data(load_data), .valid(load_valid)
    );
    always_comb begin
        case (mem.wb_source)
            2'b01: mem_result = load_data;
            2'b10: mem_result = mem.pc + 32'd4;
            2'b11: mem_result = mem.target;
            default: mem_result = mem.alu_result;
        endcase
    end
    /*
     * ------------------------------------------------------------
     * WB stage (Retirement and Register Writeback)
     * ------------------------------------------------------------
     */

    assign retire_valid = rst_n && wb.valid;
    assign retire_pc = wb.pc;
    assign retire_instruction = wb.instruction;
    assign retire_reg_write = retire_valid && wb.reg_write && wb.rd != 0;
    assign retire_rd = wb.rd;
    assign retire_wdata = wb.data;

    /*
     * ------------------------------------------------------------
     * Pipeline Register Updates (ID -> EX -> MEM -> WB)
     * ------------------------------------------------------------
     */

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            id <= '0;
            ex <= '0;
            mem <= '0;
            wb <= '0;
        end else begin
            // WB always drains once, even while the upstream pipeline is held.
            wb.valid <= 0;
            if (!mem_wait) begin
                // MEM -> WB: latch the completed instruction and selected result.
                wb.valid <= mem.valid;
                wb.pc <= mem.pc;
                wb.instruction <= mem.instruction;
                wb.rd <= mem.rd;
                wb.reg_write <= mem.reg_write && (mem.wb_source != 2'b01 || load_valid);
                wb.data <= mem_result;

                // EX -> MEM: carry access metadata together with the address/data.
                mem.valid <= ex.valid;
                mem.pc <= ex.pc;
                mem.instruction <= ex.instruction;
                mem.alu_result <= ex_result;
                mem.target <= ex.target;
                mem.rd <= ex.rd;
                mem.func3 <= ex.func3;
                mem.be <= byte_enable;
                mem.store_data <= store_data;
                mem.reg_write <= ex.reg_write;
                mem.mem_write <= ex.mem_write;
                mem.wb_source <= ex.wb_source;

                // ID -> EX: a dependency stall injects an invalid entry.
                ex.valid <= id_fire;
                ex.pc <= id.pc;
                ex.instruction <= id.instruction;
                ex.a <= id_a;
                ex.b <= id_b;
                ex.immediate <= id_imm;
                ex.target <= id_target;
                ex.rs1 <= id.instruction[19:15];
                ex.rs2 <= id.instruction[24:20];
                ex.rd <= id.instruction[11:7];
                ex.func3 <= id.instruction[14:12];
                ex.alu_control <= alu_control;
                ex.alu_source <= alu_source;
                ex.reg_write <= reg_write;
                ex.mem_write <= mem_write;
                ex.wb_source <= wb_source;

                // IF -> ID: hold on dependencies; discard younger work on redirect.
                if (buffer_consume) id <= fetch_buffer;
                if (redirect) id.valid <= 0;
            end else begin
                // Capture bypassed operands before WB drains during a long wait.
                ex.a <= ex_a;
                ex.b <= ex_b;
            end
        end
    end
endmodule
`default_nettype wire
