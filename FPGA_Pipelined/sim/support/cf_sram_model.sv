`timescale 1ns / 1ps
// Local functional substitute for the technology macro. This is NOT a vendor
// timing model. Compile either this file OR the vendor views, never both.
module CF_SRAM_1024x32 (
    output logic [31:0] DO,
    output wire ScanOutCC,
    input logic [9:0] AD,
    input logic [31:0] BEN, DI,
    input logic CLKin, EN, R_WB,
    input logic ScanInCC, ScanInDL, ScanInDR, SM, TM, WLBI, WLOFF,
    input logic vpwrac, vpwrpc
);
    logic [31:0] memory [0:1023];
    assign ScanOutCC = 1'b0;
    always @(posedge CLKin) begin
        if (EN && !SM && !TM && !WLBI && !WLOFF && vpwrac && vpwrpc) begin
            if (R_WB) DO <= memory[AD];
            else begin
                for (int b = 0; b < 32; b++)
                    if (BEN[b]) memory[AD][b] <= DI[b];
            end
        end
    end
endmodule
