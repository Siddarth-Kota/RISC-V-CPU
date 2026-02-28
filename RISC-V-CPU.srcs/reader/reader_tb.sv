`timescale 1ns / 1ps

module reader_tb;

    //DUT signals
    logic [31:0] mem_data;
    logic [3:0] be_mask;
    logic [2:0] func3;

    logic [31:0] wb_data;
    logic valid;

    //Debug
    logic [3:0] test_num = 0;

    //Instantiate DUT
    reader dut (
        .mem_data(mem_data),
        .be_mask(be_mask),
        .func3(func3),

        .wb_data(wb_data),
        .valid(valid)
    );

    initial begin
        logic [31:0] mem_val;

        test_num = 1;
        $display("\n--> Test 1: LW");
        func3 = 3'b010; //LW
        #1;
        be_mask = 4'b1111; //All bytes
        for(int i = 0; i < 100; i++) begin
            mem_val = $urandom() & 32'hFFFFFFFF;
            mem_data = mem_val;
            #1;
            assert(wb_data == mem_val) else $error("Test %d Failed: Expected %h, got %h", test_num, mem_val, wb_data);
        end
        $display("LW Test done.");

        test_num = 2;
        $display("\n--> Test 2: Reader Invalid");
        func3 = 3'b001; //LH
        mem_val = $urandom() & 32'hFFFFFFFF;
        for(int i = 0; i < 16; i++) begin
            be_mask = i;
            #1;
            if(i == 0) begin
                assert(valid == 0) else $error("Test %d Failed: Expected valid 0, got %b", test_num, valid);
            end 
            else begin
                assert(valid == 1) else $error("Test %d Failed: Expected valid 1, got %b", test_num, valid);
            end
        end
        $display("Reader Invalid Test done.");

        $display("\nAll tests completed.");
        $finish;
    end 
endmodule