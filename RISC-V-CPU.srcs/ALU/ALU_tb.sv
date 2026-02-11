`timescale 1ns / 1ps

module ALU_tb;

    logic [2:0] alu_control;
    logic [31:0] operand1;
    logic [31:0] operand2;
    logic [31:0] alu_result;
    logic zero;

    //debug
    logic [2:0] test_num = -1;
    logic [31:0] expected;

    ALU dut (
        .alu_control(alu_control),
        .operand1(operand1),
        .operand2(operand2),
        .alu_result(alu_result),
        .zero(zero)
    );

    //test logic
    initial begin
        $display("Starting ALU Testbench...");
        
        //default case test
        $display("Test 0: default case"); //should output 0
        test_num = 0;
        alu_control = 3'b111; //undefined operation
        operand1 = $urandom();
        operand2 = $urandom();
        #1
        $display("Result of %d + %d = %d with control %d", operand1, operand2, alu_result, alu_control);
        assert (zero === 1'b1) else $error("Test Failed: Zero flag not set correctly for default case.");
        assert (alu_result === 32'b0) else $error("Test Failed: ALU result not zero for default case.");
        $display("Test 0 done.");

        //ADD operation test
        $display("--> Test 1: ADD operation");
        test_num = 1;
        alu_control = 3'b000; //ADD
        for(int i = 0; i < 1000; i++) begin
            operand1 = $urandom();
            operand2 = $urandom();
            expected = operand1 + operand2;
            #1;
            assert (alu_result === expected) else $error("Test Failed: ADD operation incorrect for operands %0d and %0d. Expected %0d, got %0d", operand1, operand2, expected, alu_result);
        end
        $display("Test 1 done.");

        //AND operation test
        $display("--> Test 2: AND operation");
        test_num = 2;
        alu_control = 3'b010; //AND
        for(int i = 0; i < 1000; i++) begin
            operand1 = $urandom();
            operand2 = $urandom();
            expected = operand1 & operand2;
            #1;
            assert (alu_result === expected) else $error("Test Failed: AND operation incorrect for operands %0d and %0d. Expected %0d, got %0d", operand1, operand2, expected, alu_result);
        end
        $display("Test 2 done.");

        //OR operation test
        $display("--> Test 3: OR operation");
        test_num = 3;
        alu_control = 3'b011; //OR
        for(int i = 0; i < 1000; i++) begin
            operand1 = $urandom();
            operand2 = $urandom();
            expected = operand1 | operand2;
            #1;
            assert (alu_result === expected) else $error("Test Failed: OR operation incorrect for operands %0d and %0d. Expected %0d, got %0d", operand1, operand2, expected, alu_result);
        end
        $display("Test 3 done.");

        //SUB operation test
        $display("--> Test 4: SUB operation");
        test_num = 4;
        alu_control = 3'b001; //SUB
        for(int i = 0; i < 1000; i++) begin
            operand1 = $urandom();
            operand2 = $urandom();
            expected = operand1 + (~operand2 + 1'b1);
            #1
            assert (alu_result === expected) else $error("Test Failed: SUB operation incorrect for operands %0d and %0d. Expected %0d, got %0d", operand1, operand2, expected, alu_result);
        end
        $display("Test 4 done.");

        //SLTI operation test
        $display("--> Test 5: SLTI operation");
        test_num = 5;
        alu_control = 3'b101; //SLTI
        for(int i = 0; i < 1000; i++) begin
            operand1 = $urandom();
            operand2 = $urandom();
            expected = ($signed(operand1) < $signed(operand2)) ? 32'b1 : 32'b0;
            #1;
            assert (alu_result === expected) else $error("Test Failed: SLTI operation incorrect for operands %0d and %0d. Expected %0d, got %0d", $signed(operand1), $signed(operand2), expected, alu_result);
        end
        $display("Test 5 done.");


        test_num = 0;
        //end of tests
        $display("All tests completed.");
        $finish;
    end
endmodule
