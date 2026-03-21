`timescale 1ns / 1ps

module registers (
    input logic clk, //positive edge clock
    input logic rst_n, //active low reset

    //reads
    input logic [4:0] read_address1,
    input logic [4:0] read_address2,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2,

    //writes
    input logic write_enable, //allow write when high
    input logic [31:0] write_data,
    input logic [4:0] write_address
);

    reg [31:0] reg_array [0:31]; //register array (5-bit addresses)

    //write
    always @(posedge clk) begin
        //reset registers
        if(rst_n == 1'b0) begin
            for(int i = 0; i < 32; i++) begin
                reg_array[i] <= 32'b0;
            end
        end
        //write protection for x0
        else if (write_enable == 1'b1 && write_address != 5'b00000) begin
            reg_array[write_address] <= write_data;
        end
    end

    //read (asynchronous)
    always_comb begin
        read_data1 = reg_array[read_address1];
        read_data2 = reg_array[read_address2];
    end
endmodule