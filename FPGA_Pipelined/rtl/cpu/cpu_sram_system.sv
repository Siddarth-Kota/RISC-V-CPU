`timescale 1ns / 1ps

module cpu_sram_system #(
    parameter bit PREDICT = 1'b1,
    parameter bit PREFETCH = 1'b0
)(
    input logic clk, rst_n, core_rst_n,
    input logic host_req_valid, host_instruction, host_write,
    input logic [31:0] host_addr, host_wdata,
    input logic [3:0] host_be,
    input logic host_rsp_ready,

    output logic host_rsp_valid,
    output logic host_req_ready,
    output logic [31:0] host_rsp_data,
    output logic memory_idle,
    output logic retire_valid,
    output logic [31:0] retire_pc, retire_instruction,
    output logic retire_reg_write,
    output logic [4:0] retire_rd,
    output logic [31:0] retire_wdata
);
    logic i_req, i_ready, i_rsp, i_rsp_ready;
    logic [31:0] i_addr, i_data;
    logic d_req, d_ready, d_rsp, d_rsp_ready, d_write;
    logic [31:0] d_addr, d_data, d_wdata;
    logic [3:0] d_be;
    logic host_pending, host_port;
    logic [1:0] port_ready, port_rsp, port_busy, port_rsp_ready;
    wire [31:0] port_data [0:1];
    logic host_mode;
    
    assign host_mode = !core_rst_n;
    assign host_req_ready = rst_n && host_mode && !host_pending && port_ready[host_instruction ? 0 : 1];
    assign host_rsp_valid = host_pending && port_rsp[host_port];
    assign host_rsp_data = port_data[host_port];
    assign memory_idle = !host_pending && !(|port_busy);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            host_pending <= 0;
            host_port <= 0;
        end else begin
            if (host_req_valid && host_req_ready) begin
                host_pending <= 1;
                host_port <= !host_instruction;
            end
            if (host_rsp_valid && host_rsp_ready) host_pending <= 0;
        end
    end

    assign i_ready = !host_mode && port_ready[0];
    assign d_ready = !host_mode && port_ready[1];
    assign i_rsp = !host_mode && port_rsp[0];
    assign d_rsp = !host_mode && port_rsp[1];
    assign i_data = port_data[0];
    assign d_data = port_data[1];
    assign port_rsp_ready[0] = host_mode ? (host_pending && !host_port && host_rsp_ready) : i_rsp_ready;
    assign port_rsp_ready[1] = host_mode ? (host_pending && host_port && host_rsp_ready) : d_rsp_ready;

    cpu #(.PREDICT(PREDICT), .PREFETCH(PREFETCH)) core (
        .clk(clk), .rst_n(rst_n && core_rst_n),
        .imem_req_valid(i_req), .imem_req_ready(i_ready), .imem_req_addr(i_addr),
        .imem_rsp_valid(i_rsp), .imem_rsp_ready(i_rsp_ready), .imem_rsp_data(i_data),
        .dmem_req_valid(d_req), .dmem_req_ready(d_ready), .dmem_req_addr(d_addr),
        .dmem_req_write(d_write), .dmem_req_wdata(d_wdata), .dmem_req_be(d_be),
        .dmem_rsp_valid(d_rsp), .dmem_rsp_ready(d_rsp_ready), .dmem_rsp_data(d_data),
        .retire_valid(retire_valid), .retire_pc(retire_pc), .retire_instruction(retire_instruction),
        .retire_reg_write(retire_reg_write), .retire_rd(retire_rd), .retire_wdata(retire_wdata)
    );

    for (genvar p = 0; p < 2; p++) begin : memories
        wire en, read_enable;
        wire [9:0] addr;
        wire [31:0] wdata, ben, rdata;
        wire host_select = host_mode && (host_instruction == (p == 0));
        sram_port adapter (
            .clk(clk), .rst_n(rst_n),
            .req_valid(host_mode ? (host_select && host_req_valid && !host_pending) : (p == 0 ? i_req : d_req)),
            .req_ready(port_ready[p]),
            .req_addr(host_mode ? host_addr : (p == 0 ? i_addr : d_addr)),
            .req_write(host_mode ? host_write : (p == 0 ? 1'b0 : d_write)),
            .req_wdata(host_mode ? host_wdata : (p == 0 ? 32'b0 : d_wdata)),
            .req_be(host_mode ? host_be : (p == 0 ? 4'b1111 : d_be)),
            .rsp_valid(port_rsp[p]), .rsp_ready(port_rsp_ready[p]), .rsp_data(port_data[p]), .busy(port_busy[p]),
            .sram_en(en), .sram_read(read_enable), .sram_addr(addr),
            .sram_wdata(wdata), .sram_ben(ben), .sram_rdata(rdata)
        );
        cf_sram ram (.clk(clk), .en(en), .read_enable(read_enable), .addr(addr), .wdata(wdata), .ben(ben), .rdata(rdata));
    end
endmodule
