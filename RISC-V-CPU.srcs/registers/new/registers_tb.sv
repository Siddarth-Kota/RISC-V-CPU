`timescale 1ns / 1ps

module registers_tb;

    //params
    parameter CLK_PERIOD = 10; //10ns clock period

    //debug
    logic [2:0] test_num = 0;

    //DUT signals
    logic clk;
    logic rst_n;
    logic [4:0] read_address1;
    logic [4:0] read_address2;
    logic [31:0] read_data1;
    logic [31:0] read_data2;
    logic write_enable;
    logic [31:0] write_data;
    logic [4:0] write_address;

    //shadow register array for verification
    logic [31:0] shadow_regs [0:31];
    
    //Instantiate DUT
    registers dut (
        .clk(clk),
        .rst_n(rst_n),
        .read_address1(read_address1),
        .read_address2(read_address2),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .write_enable(write_enable),
        .write_data(write_data),
        .write_address(write_address)
    );

    //Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //test logic
    initial begin
        //reset
        rst_n = 0;
        write_enable = 0;
        write_data = 0;
        read_address1 = 0;
        read_address2 = 0;
        write_address = 0;
        
        for(int i = 0; i < 32; i++) begin
            shadow_regs[i] = 32'b0;
        end

        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        @(posedge clk) #1;

        test_num = 1;
        $display("Checking registers reset...");
        for(int i = 0; i < 32; i++) begin
            #1
            read_address1 = i;
            read_address2 = i;
            #1;
            assert (read_data1 === 32'b0) else $error("Test Failed: Register not reset (1) at address %0d", i);
            assert (read_data2 === 32'b0) else $error("Test Failed: Register not reset (2) at address %0d", i);
        end
        $display("-->  Registers reset check done.");

        test_num = 2;
        $display("Starting random write and read test...");
        for(int i = 0; i < 1000; i++) begin
            //generate random addresses and data
            automatic logic [4:0] rand_addr1 = $urandom_range(1,31);
            automatic logic [4:0] rand_addr2 = $urandom_range(1,31);
            automatic logic [4:0] rand_addrw = $urandom_range(1,31);
            automatic logic [31:0] write_value = $urandom;
            
            //reads (async)
            #1;
            read_address1 = rand_addr1;
            read_address2 = rand_addr2;
            #1;

            //verify data against shadow
            assert (read_data1 === shadow_regs[rand_addr1]) else $error("Test Failed: Register not reset (1) at address %0d", rand_addr1);
            assert (read_data2 === shadow_regs[rand_addr2]) else $error("Test Failed: Register not reset (2) at address %0d", rand_addr2);
            
            //write (sync)
            @(negedge clk);
            write_enable = 1;
            write_address = rand_addrw;
            write_data = write_value;
            @(posedge clk);
            shadow_regs[rand_addrw] = write_value; //update shadow
            @(negedge clk);
            write_enable = 0;
        end
        $display("-->  Registers reset check done.");

        //x0 write protection test
        test_num = 3;
        $display("Starting x0 write protection test...");
        #1;
        @(negedge clk);
        write_enable = 1;
        write_address = 5'b00000; //x0
        write_data = 32'hFFFFFFFF;
        @(posedge clk);
        shadow_regs[0] = 32'b0; //x0 should remain 0
        @(negedge clk);
        write_enable = 0;

        //read back x0
        #1;
        read_address1 = 5'b00000;
        #1;
        assert (read_data1 === 32'b0) else $error("Test Failed: x0 write protection failed.");
        $display("-->  x0 write protection test done.");
        $display("All tests completed.");
        $finish;
    end 
endmodule