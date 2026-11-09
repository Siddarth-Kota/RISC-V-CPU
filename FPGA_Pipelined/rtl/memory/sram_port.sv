`timescale 1ns / 1ps

module sram_port (
    input logic clk, rst_n,
    input logic req_valid,
    input logic [31:0] req_addr, req_wdata,
    input logic req_write,
    input logic [3:0] req_be,
    input logic rsp_ready,
    input logic [31:0] sram_rdata,

    output logic req_ready,
    output logic rsp_valid,
    output logic [31:0] rsp_data,
    output logic busy,
    output logic sram_en, sram_read,
    output logic [9:0] sram_addr,
    output logic [31:0] sram_wdata, sram_ben
);
    logic access_pending;
    assign busy = access_pending || rsp_valid;
    assign req_ready = rst_n && !busy;
    assign sram_en = req_valid && req_ready;
    assign sram_read = !req_write;
    assign sram_addr = req_addr[11:2];
    assign sram_wdata = req_wdata;

    for (genvar lane = 0; lane < 4; lane++) begin : byte_lanes
        assign sram_ben[lane*8 +: 8] = {8{req_be[lane]}};
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            access_pending <= 0;
            rsp_valid <= 0;
            rsp_data <= 0;
        end else begin
            if (rsp_valid && rsp_ready) rsp_valid <= 0;
            access_pending <= sram_en;
            if (access_pending) begin
                rsp_valid <= 1;
                rsp_data <= sram_rdata;
            end
        end
    end
endmodule