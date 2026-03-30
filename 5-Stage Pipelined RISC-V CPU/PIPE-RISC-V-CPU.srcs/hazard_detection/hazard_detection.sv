`timescale 1ns / 1ps

module hazard_detection_unit(
    input logic [4:0] id_rs1, id_rs2, ex_rd,
    input logic [1:0] ex_write_back_source,
    
    output logic stall
);

    always_comb begin
        if ((ex_write_back_source == 2'b01) && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) begin
            stall = 1'b1;
        end
        else begin
            stall = 1'b0;
        end
    end
endmodule