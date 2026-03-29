`timescale 1ns / 1ps

module registers (
    input logic clk,
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
    always_ff @(posedge clk) begin
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

    //read (asynchronous) with internal forwarding
    always_comb begin
        if(write_enable && (write_address != 5'b00000) && (write_address == read_address1)) begin
            read_data1 = write_data; //forwarding for read port 1
        end
        else begin
            read_data1 = reg_array[read_address1]; //normal read for port 1
        end

        if(write_enable && (write_address != 5'b00000) && (write_address == read_address2)) begin
            read_data2 = write_data; //forwarding for read port 2
        end
        else begin
            read_data2 = reg_array[read_address2]; //normal read for port 2
        end
    end
endmodule