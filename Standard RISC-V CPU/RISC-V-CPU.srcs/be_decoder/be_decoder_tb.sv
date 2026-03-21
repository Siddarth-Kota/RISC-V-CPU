`timescale 1ns / 1ps

module be_decoder_tb;

    //DUT signals
    logic [31:0] alu_result_address;
    logic [2:0] func3;
    logic [31:0] reg_read;
    
    logic [3:0] byte_enable;
    logic [31:0] data;

    //Debug
    logic [2:0] test_num = 0;

    //Instantiate DUT
    be_decoder dut (
        .alu_result_address(alu_result_address),
        .func3(func3),
        .reg_read(reg_read),
        
        .byte_enable(byte_enable),
        .data(data)
    );

    initial begin
        logic [31:0] test_word = 32'hAABBCC00;
        logic [31:0] reg_data;
        
        test_num = 1;
        $display("\n--> Test 1: SW");
        func3 = 3'b010; //SW
        for(int i = 0; i < 100; i++) begin
            reg_data = $urandom() & 32'hFFFFFFFF;
            reg_read = reg_data;
            for(int offset = 0; offset < 4; offset++) begin
                alu_result_address = test_word | offset;
                #1;
                assert (data == (reg_data & 32'hFFFFFFFF)) else $error("Test %d Failed: Expected data %h, got %h", test_num, reg_data, data);
                if(offset == 2'b00) begin
                    assert (byte_enable == 4'b1111) else $error("Test %d Failed: Expected byte_enable 1111, got %b", test_num, byte_enable);
                end
                else begin
                    assert (byte_enable == 4'b0000) else $error("Test %d Failed: Expected byte_enable 0000, got %b", test_num, byte_enable);
                end
            end
        end
        $display("SW Test done.");


        test_num = 2;
        $display("\n--> Test 2: SB");
        func3 = 3'b000; //SB
        for(int i = 0; i < 100; i++) begin
            reg_data = $urandom() & 32'hFFFFFFFF;
            reg_read = reg_data;
            for(int offset = 0; offset < 4; offset++) begin
                alu_result_address = test_word | offset;
                #1;
                if(offset == 2'b00) begin
                    assert (byte_enable == 4'b0001) else $error("Test %d Failed: Expected byte_enable 0001, got %b", test_num, byte_enable);
                    assert (data == (reg_data & 32'h000000FF)) else $error("Test %d Failed: Expected data %h, got %h", test_num, reg_data & 32'h000000FF, data);
                end
                else if(offset == 2'b01) begin
                    assert (data == ((reg_data & 32'h000000FF) << 8)) else $error("Test %d Failed: Expected data %h, got %h", test_num, (reg_data & 32'h000000FF) << 8, data);
                    assert (byte_enable == 4'b0010) else $error("Test %d Failed: Expected byte_enable 0010, got %b", test_num, byte_enable);
                end
                else if(offset == 2'b10) begin
                    assert (data == ((reg_data & 32'h000000FF) << 16)) else $error("Test %d Failed: Expected data %h, got %h", test_num, (reg_data & 32'h000000FF) << 16, data);
                    assert (byte_enable == 4'b0100) else $error("Test %d Failed: Expected byte_enable 0100, got %b", test_num, byte_enable);
                end
                else if(offset == 2'b11) begin
                    assert (data == ((reg_data & 32'h000000FF) << 24)) else $error("Test %d Failed: Expected data %h, got %h", test_num, (reg_data & 32'h000000FF) << 24, data);
                    assert (byte_enable == 4'b1000) else $error("Test %d Failed: Expected byte_enable 1000, got %b", test_num, byte_enable);
                end
            end
        end
        $display("SB Test done.");


        test_num = 3;
        $display("\n--> Test 3: SH");
        func3 = 3'b001; //SH
        for(int i = 0; i < 100; i++) begin
            reg_data = $urandom() & 32'hFFFFFFFF;
            reg_read = reg_data;
            for(int offset = 0; offset < 4; offset++) begin
                alu_result_address = test_word | offset;
                #1;
                if(offset == 2'b00) begin
                    assert (byte_enable == 4'b0011) else $error("Test %d Failed: Expected byte_enable 0011, got %b", test_num, byte_enable);
                    assert (data == (reg_data & 32'h0000FFFF)) else $error("Test %d Failed: Expected data %h, got %h", test_num, reg_data & 32'h0000FFFF, data);
                end
                else if(offset == 2'b10) begin
                    assert (data == ((reg_data & 32'h0000FFFF) << 16)) else $error("Test %d Failed: Expected data %h, got %h", test_num, (reg_data & 32'h0000FFFF) << 16, data);
                    assert (byte_enable == 4'b1100) else $error("Test %d Failed: Expected byte_enable 1100, got %b", test_num, byte_enable);
                end
                else begin
                    assert (byte_enable == 4'b0000) else $error("Test %d Failed: Expected byte_enable 0000, got %b", test_num, byte_enable);
                end
            end
        end
        $display("SH Test done.");


        test_num = 0;
        $display("\n--> All tests done.");
        $finish;
    end
endmodule