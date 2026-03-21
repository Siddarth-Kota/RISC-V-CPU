`timescale 1ns / 1ps

module memory #(
    parameter integer WORDS = 256,
    parameter string mem_init = ""
) (
    input logic clk, //positive edge clock
    input logic rst_n, //active low reset
    input logic write_enable, //allow write when high
    input logic [31:0] address,
    input logic [31:0] write_data,
    input logic [3:0] byte_enable,

    output logic [31:0] read_data
    );

    reg [31:0] mem_array [0:WORDS-1]; //memory array (32-bit)

    //initialize memory from file if provided
    initial begin
        if (mem_init != "") begin
            $readmemh(mem_init, mem_array);
        end
    end

    always @(posedge clk) begin
        //reset memory
        if(rst_n == 1'b0 && mem_init == "") begin
            for(int i = 0; i < WORDS; i = i + 1) begin
                mem_array[i] <= 32'b0;
            end
        end
        else if (write_enable) begin
            if(address[1:0] != 2'b00 || (address[31:2] >= WORDS)) begin
                $display("ERROR: Misaligned or out-of-bounds address: %h", address);
            end
            else begin
                for (int i = 0; i < 4; i++) begin
                    if(byte_enable[i]) begin
                        mem_array[address[31:2]][i*8 +: 8] <= write_data[i*8 +: 8];
                    end
                end
            end
        end
    end

    //read (asynchronous)
    always_comb begin
        read_data = mem_array[address[31:2]];
    end
endmodule