`timescale 1ns / 1ps
// Verification-only, synchronous memory with independently delayed acceptance
// and responses. Writes occur once at request acceptance; stores return an ack.
module latency_memory #(
    parameter integer WORDS = 1024,
    parameter bit INSTRUCTION = 0
)(
    input logic clk, rst_n,
    input logic req_valid,
    output logic req_ready,
    input logic [31:0] req_addr, req_wdata,
    input logic req_write,
    input logic [3:0] req_be,
    output logic rsp_valid,
    input logic rsp_ready,
    output logic [31:0] rsp_data,
    output integer writes, requests
);
    logic [31:0] mem_array [0:WORDS-1];
    logic pending;
    logic [31:0] saved_data;
    integer countdown, delay_max, backpressure, cycles;
    integer unused;
    initial begin
        delay_max = 0;
        backpressure = 0;
        if (INSTRUCTION) unused = $value$plusargs("imem_delay=%d", delay_max);
        else unused = $value$plusargs("dmem_delay=%d", delay_max);
        unused = $value$plusargs("backpressure=%d", backpressure);
    end
    assign req_ready = rst_n && !pending && !rsp_valid &&
                       (!backpressure || (cycles % 5 == 4));
    always @(posedge clk) begin
        if (!rst_n) begin
            pending <= 0;
            rsp_valid <= 0;
            rsp_data <= 0;
            saved_data <= 0;
            countdown <= 0;
            cycles <= 0;
            writes <= 0;
            requests <= 0;
        end else begin
            cycles <= cycles + 1;
            if (rsp_valid && rsp_ready) rsp_valid <= 0;
            if (pending) begin
                if (countdown == 0) begin
                    pending <= 0;
                    rsp_valid <= 1;
                    rsp_data <= saved_data;
                end else countdown <= countdown - 1;
            end
            if (req_valid && req_ready) begin
                if (req_addr[1:0] != 0 || req_addr[31:2] >= WORDS)
                    $fatal(1, "Invalid memory request %h", req_addr);
                requests <= requests + 1;
                if (req_write) begin
                    writes <= writes + 1;
                    for (int b = 0; b < 4; b++)
                        if (req_be[b]) mem_array[req_addr[31:2]][b*8 +: 8] <= req_wdata[b*8 +: 8];
                end
                if (delay_max == 0) begin
                    rsp_valid <= 1;
                    rsp_data <= mem_array[req_addr[31:2]];
                end else begin
                    pending <= 1;
                    countdown <= $urandom_range(delay_max, 0);
                    saved_data <= mem_array[req_addr[31:2]];
                end
            end
        end
    end
endmodule
