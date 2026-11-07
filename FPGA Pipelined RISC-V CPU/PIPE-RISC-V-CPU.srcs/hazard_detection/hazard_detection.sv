`timescale 1ns / 1ps

module hazard_detection(
    input logic [6:0] id_opcode,
    input logic [4:0] id_rs1, id_rs2, ex_rd, mem_rd,
    input logic [1:0] ex_write_back_source,
    input logic ex_reg_write, mem_reg_write,
    
    output logic stall
    );  

    import signal_pkg::*;

    //Load-Use Hazard Detection
    logic load_use_stall;
    assign load_use_stall = ex_write_back_source == 2'b01 && (ex_rd != 0) && (ex_rd == id_rs1 || ex_rd == id_rs2);

    //Early Branch Hazard Detection
    logic branch_stall;
    assign branch_stall = id_opcode == OPCODE_B_TYPE && (
        (ex_reg_write  && (ex_rd != 0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) ||
        (mem_reg_write && (mem_rd != 0) && ((mem_rd == id_rs1) || (mem_rd == id_rs2)))
    );

    //Early Jump Hazard (JALR) Detection
    logic jalr_stall;
    assign jalr_stall = id_opcode == OPCODE_J_TYPE_JALR && (
        (ex_reg_write  && (ex_rd != 0) && (ex_rd == id_rs1)) ||
        (mem_reg_write && (mem_rd != 0) && (mem_rd == id_rs1))
    );

    assign stall = load_use_stall || branch_stall || jalr_stall;
endmodule