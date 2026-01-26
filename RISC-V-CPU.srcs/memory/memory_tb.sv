`timescale 1ns / 1ps

module memory_tb;
    //Params
    parameter integer WORDS = 64;
    parameter CLK_PERIOD = 10; //10ns clock period

    //Debug
    logic [2:0] test_num = 0;

    //DUT signals
    logic clk;
    logic rst_n;
    logic write_enable;
    logic [31:0] address;
    logic [31:0] write_data;
    logic [31:0] read_data;

    //Instantiate DUT
    memory #(
        .WORDS(WORDS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    //Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //test logic
    initial begin
        test_num = 1;
        //reset
        rst_n = 0;
        write_enable = 0;
        address = 0;
        write_data = 0;

        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        @(posedge clk);

        //check 0 after reset
        $display("Checking memory reset...");
        for(int i = 0; i < WORDS; i = i + 1) begin
            address = i * 4;
            @(posedge clk) #1;
            assert (read_data === 32'b0) else $error("Test Failed: Memory not reset (0) at address %0d", address);
        end
        $display("Memory reset check done.");

        //write and read test
        test_num = 2;
        $display("Starting write and read test...");
        write_and_check(0, 32'hDEADBEEF);
        write_and_check(4, 32'hCAFEBABE);
        write_and_check(8, 32'h12345678);
        write_and_check(12, 32'hFFFFFFFF);
        $display("Write and read test done.");

        //write to multiple addresses
        test_num = 3;
        $display("Starting multiple address write and read test...");
        //write
        for(int i = 4; i < 40; i = i + 4) begin
            @(negedge clk);
            write_enable = 1;
            address = i;
            write_data = i * 3;
            @(posedge clk);
        end
        @(negedge clk);
        write_enable = 0;
        @(posedge clk);

        //read
        for(int i = 4; i < 40; i = i + 4) begin
            address = i;
            @(posedge clk) #1;
            assert (read_data === (i * 3)) else $error("Test Failed: Data mismatch at address %0d. Expected: %0h, Got: %0h", address, (i * 3), read_data);
        end
        $display("Multiple address write and read test done.");
        $display("All tests done.");
        $finish;
    end

    task write_and_check(input logic [31:0] addr, input logic [31:0] data);
        begin
            //write
            @(posedge clk);
            write_enable = 1;
            address = addr;
            write_data = data;

            
            @(posedge clk);
            write_enable = 0;
            
            //read
            @(posedge clk) #1;
            assert (read_data === data) else $error("Test Failed: Data mismatch at address %0d. Expected: %0h, Got: %0h", addr, data, read_data);
        end
    endtask
endmodule
