`timescale 1ns / 1ps

module forwarding (
    input  logic [4:0] ex_rs1, ex_rs2, mem_rd, wb_rd,
    input  logic mem_reg_write, wb_reg_write,

    output logic [1:0] forwardA,
    output logic [1:0] forwardB
    );

    // rs1 forwarding logic
    always_comb begin
        if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == ex_rs1)) begin
            forwardA = 2'b01; // Forward from MEM stage
        end 
        else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs1)) begin
            forwardA = 2'b10; // Forward from WB stage
        end 
        else begin
            forwardA = 2'b00; // Use Normal EX stage value
        end
    end

    // rs2 forwarding logic
    always_comb begin
        if (mem_reg_write && (mem_rd != 5'b0) && (mem_rd == ex_rs2)) begin
            forwardB = 2'b01; // Forward from MEM stage
        end 
        else if (wb_reg_write && (wb_rd != 5'b0) && (wb_rd == ex_rs2)) begin
            forwardB = 2'b10; // Forward from WB stage
        end 
        else begin
            forwardB = 2'b00; // Use Normal EX stage value
        end
    end
endmodule