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
    typedef enum logic [1:0] {IDLE, ISSUE, CAPTURE, RESPONSE} state_t;
    state_t state;
    logic [9:0] request_addr;
    logic [31:0] request_wdata;
    logic [3:0] request_be;
    logic request_read;

    assign busy = (state != IDLE);
    assign req_ready = rst_n && !busy;
    assign rsp_valid = rst_n && (state == RESPONSE);

    // Accept at rising edge N, issue to the SRAM at N+1, capture data at N+2.
    // Request fields stay saved even if the sender changes them after acceptance.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
            request_addr <= 0;
            request_wdata <= 0;
            request_be <= 0;
            request_read <= 1;
            rsp_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (req_valid && req_ready) begin
                        request_addr <= req_addr[11:2];
                        request_wdata <= req_wdata;
                        request_be <= req_be;
                        request_read <= !req_write;
                        state <= ISSUE;
                    end
                end
                ISSUE: state <= CAPTURE;
                CAPTURE: begin
                    rsp_data <= sram_rdata;
                    state <= RESPONSE;
                end
                RESPONSE: if (rsp_ready) state <= IDLE;
                default: state <= IDLE;
            endcase
        end
    end

    // Change macro pins only on falling edges, leaving setup/hold time around
    // the SRAM's rising edge. These half-cycle paths must be checked in STA.
    // Keep reset asserted across both clock edges before the first request.
    always_ff @(negedge clk) begin
        if (!rst_n) begin
            sram_en <= 0;
            sram_read <= 1;
            sram_addr <= 0;
            sram_wdata <= 0;
            sram_ben <= 0;
        end else begin
            sram_en <= (state == ISSUE);
            if (state == ISSUE) begin
                sram_addr <= request_addr;
                sram_read <= request_read;
                sram_wdata <= request_wdata;
                for (int lane = 0; lane < 4; lane++)
                    sram_ben[lane*8 +: 8] <= {8{request_be[lane]}};
            end
        end
    end
endmodule
