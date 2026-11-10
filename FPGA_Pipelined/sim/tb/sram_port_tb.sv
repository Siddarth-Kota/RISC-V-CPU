`timescale 1ns / 1ps
module sram_port_tb;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;
    logic req_valid = 0, req_ready, req_write = 0;
    logic [31:0] req_addr = 0, req_wdata = 0;
    logic [3:0] req_be = 0;
    logic rsp_valid, rsp_ready = 0, busy;
    logic [31:0] rsp_data;
    wire en, read_enable;
    wire [9:0] addr;
    wire [31:0] wdata, ben, rdata;
    integer enables = 0;
    sram_port dut (
        .clk(clk), .rst_n(rst_n), .req_valid(req_valid), .req_ready(req_ready),
        .req_addr(req_addr), .req_wdata(req_wdata), .req_write(req_write), .req_be(req_be),
        .rsp_valid(rsp_valid), .rsp_ready(rsp_ready), .rsp_data(rsp_data), .busy(busy),
        .sram_en(en), .sram_read(read_enable), .sram_addr(addr),
        .sram_wdata(wdata), .sram_ben(ben), .sram_rdata(rdata)
    );
    cf_sram ram (.clk(clk), .en(en), .read_enable(read_enable), .addr(addr), .wdata(wdata), .ben(ben), .rdata(rdata));
    always @(posedge clk) if (rst_n && en) enables++;
    assert property (@(posedge clk) disable iff (!rst_n) rsp_valid && !rsp_ready |=> rsp_valid && $stable(rsp_data));
    assert property (@(posedge clk) disable iff (!rst_n) busy |-> !req_ready);
    // SRAM access follows request acceptance; it occurs while the adapter is busy.
    assert property (@(posedge clk) disable iff (!rst_n) req_valid && req_ready |=> en && busy);
    assert property (@(posedge clk) disable iff (!rst_n) en |=> !en);
    task automatic transaction(input bit wr, input logic [31:0] address, data, input logic [3:0] mask, input logic [31:0] expected);
        begin
            @(negedge clk);
            req_valid = 1; req_write = wr; req_addr = address; req_wdata = data; req_be = mask;
            do @(posedge clk); while (!req_ready);
            // The sender may change its payload after acceptance, before the
            // SRAM access. Only the adapter's saved request may drive the macro.
            #1;
            req_valid = 0;
            req_addr = 0; req_wdata = ~data; req_write = !wr; req_be = ~mask;
            wait (rsp_valid);
            // A returned response must survive arbitrary response backpressure.
            repeat (5) @(negedge clk);
            if (!wr && rsp_data !== expected) $fatal(1,"Read %h expected %h got %h",address,expected,rsp_data);
            rsp_ready = 1;
            @(negedge clk); rsp_ready = 0;
        end
    endtask
    initial begin
        repeat (3) @(negedge clk); rst_n = 1;
        transaction(1,32'hffc,32'h12345678,4'b1111,0);
        transaction(1,32'hffc,32'h00ab0000,4'b0100,0);
        transaction(0,32'hffc,0,4'b1111,32'h12ab5678);
        transaction(1,32'hffc,32'hcdef0000,4'b1100,0);
        transaction(0,32'hffc,0,4'b1111,32'hcdef5678);
        if (enables != 5) $fatal(1,"Duplicate SRAM enables %0d",enables);
        // Controller reset cancels responses but does not reset the SRAM array.
        @(negedge clk); rst_n = 0;
        repeat (2) @(negedge clk); rst_n = 1;
        transaction(0,32'hffc,0,4'b1111,32'hcdef5678);
        $display("PASS SRAM lane mapping, response retention, reset and single enables");
        $finish;
    end
    initial begin #20000; $fatal(1,"SRAM adapter timeout"); end
endmodule
