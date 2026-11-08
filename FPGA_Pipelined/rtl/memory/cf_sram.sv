`timescale 1ns / 1ps
// Technology binding only. Vendor HDL, Liberty/DB and LEF stay in the local PDK.
module cf_sram (
    input logic clk, en, read_enable,
    input logic [9:0] addr,
    input logic [31:0] wdata, ben,
    output wire [31:0] rdata
);
    CF_SRAM_1024x32 macro_mem (
        .CLKin(clk), .EN(en), .R_WB(read_enable), .AD(addr), .DI(wdata), .BEN(ben), .DO(rdata),
        .ScanOutCC(), .ScanInCC(1'b0), .ScanInDL(1'b0), .ScanInDR(1'b0),
        .SM(1'b0), .TM(1'b0), .WLBI(1'b0), .WLOFF(1'b0),
        .vpwrac(1'b1), .vpwrpc(1'b1)
    );
endmodule
