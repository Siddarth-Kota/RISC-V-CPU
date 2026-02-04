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
        $display("--> Testing Positive I-type Immediate (123)");
        raw_src = {12'd123, 13'b1_0101_0101_0101}; //I-type immediate = 123
        imm_source = 2'b00; //I-type
        #1;
        assert (immediate == 32'b0000_0000_0000_0000_0000_0000_0111_1011) else $error("Test %d Failed: Expected 123, got %d", test_num, immediate);
        assert (immediate == 32'd123) else $error("Test %d Failed: Expected 123, got %d", test_num, immediate);
        $display("Postive I-type Immediate Test done");

        test_num = 2;
        
        $display("--> Testing Negative I-type Immediate (-45)");
        raw_src = {-12'sd45, 13'b1_0101_0101_0101};
        imm_source = 2'b00; //I-type
        #1;
        assert (immediate == 32'b1111_1111_1111_1111_1111_1111_1101_0011) else $error("Test %d Failed: Expected -45, got %d", test_num, immediate);
        assert (signed'(immediate) == -45) else $error("Test %d Failed: Expected -45, got %d", test_num, immediate);
        $display("Negative I-type Immediate Test done");

        test_num = 3;
        $display("--> Testing S-type Immediate");
        imm_source = 2'b01; //S-type
        for (int i = 0; i < 100; i++) begin
            logic [11:0] rand_imm = $urandom();
            raw_src = {rand_imm[11:5],13'hAFAF,rand_imm[4:0]}; //S-type immediate
            #1;
            assert (immediate == {{20{rand_imm[11]}}, rand_imm}) else $error("Test %d Failed: Expected %d, got %d", test_num, {{20{rand_imm[11]}}, rand_imm}, immediate);
        end
        $display("S-type Immediate Test done");

        test_num = 4;
        $display("--> Testing B-type Immediate");
        imm_source = 2'b10; //B-type
        for (int i = 0; i < 100; i++) begin
            logic [12:0] random_imm = $urandom() & 13'h1FFE; //make sure LSB is 0
            raw_src = 32'(random_imm[12]) << 24 | 32'(random_imm[11]) << 0 | 32'(random_imm[10:5]) << 18 | 32'(random_imm[4:1]) << 1;
            #1;
            assert (immediate == {{19{random_imm[12]}}, random_imm}) else $error("Test %d Failed: Expected %d, got %d", test_num, {{19{random_imm[12]}}, random_imm}, immediate);
        end
        $display("B-type Immediate Test done");

        test_num = 5;
        $display("--> Testing J-type Immediate");
        imm_source = 2'b11; //J-type
        for (int i = 0; i < 100; i++) begin
            logic [20:0] random_imm = $urandom() & 21'h1FFFFE; //make sure LSB is 0
            raw_src = 32'(random_imm[20]) << 24 | 32'(random_imm[19:12]) << 5 | 32'(random_imm[11]) << 13 | 32'(random_imm[10:1]) << 14;
            #1;
            assert (immediate == {{11{random_imm[20]}}, random_imm}) else $error("Test %d Failed: Expected %d, got %d", test_num, {{11{random_imm[20]}}, random_imm}, immediate);
        end
        $display("J-type Immediate Test done");
        
        $display("All tests done");
        $finish;
    end
endmodule
