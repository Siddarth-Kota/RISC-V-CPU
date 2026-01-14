`timescale 1ns / 1ps

module signextender_tb;

    logic [24:0] raw_src;
    logic [1:0] imm_source;
    logic [31:0] immediate;

    //debug
    logic [2:0] test_num = 0;

    //instantiate DUT
    signextender dut (
        .raw_src(raw_src),
        .imm_source(imm_source),
        .immediate(immediate)
    );

    //test logic
    initial begin
        $display("Starting Sign Extender Testbench...");

        test_num = 1;
        $display("--> Testing Positive Immediate (123)");
        raw_src = {12'd123, 13'b1_0101_0101_0101}; //I-type immediate = 123
        imm_source = 2'b00; //I-type
        #1;
        assert (immediate == 32'b0000_0000_0000_0000_0000_0000_0111_1011) else $error("Test %d Failed: Expected 123, got %d", test_num, immediate);
        assert (immediate == 32'd123) else $error("Test %d Failed: Expected 123, got %d", test_num, immediate);
        $display("--> Postive Immediate Test done");

        test_num = 2;
        
        $display("--> Testing Negative Immediate (-45)");
        raw_src = {-12'sd45, 13'b1_0101_0101_0101};
        imm_source = 2'b00; //I-type
        #1;
        assert (immediate == 32'b1111_1111_1111_1111_1111_1111_1101_0011) else $error("Test %d Failed: Expected -45, got %d", test_num, immediate);
        assert (signed'(immediate) == -45) else $error("Test %d Failed: Expected -45, got %d", test_num, immediate);
        $display("--> Negative Immediate Test done");

        $display("All tests done");
        $finish;
    end
endmodule
