`timescale 1ns / 1ps

module branch_predictor_tb;
    logic clk;
    logic rst_n; // Active low reset

    logic [31:0] if_pc;
    logic id_is_branch;
    logic [31:0] id_pc;
    logic id_actual_taken;
    logic [31:0] id_actual_target;

    logic predict_taken;
    logic [31:0] predicted_target;

    //Debug
    logic [3:0] test_num = 0;

    branch_predictor dut(
        .clk(clk),
        .rst_n(rst_n),
        .if_pc(if_pc),
        .id_is_branch(id_is_branch),
        .id_pc(id_pc),
        .id_actual_taken(id_actual_taken),
        .id_actual_target(id_actual_target),
        .predict_taken(predict_taken),
        .predicted_target(predicted_target)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        if_pc = 32'b0;
        id_is_branch = 1'b0;
        id_pc = 32'b0;
        id_actual_taken = 1'b0;
        id_actual_target = 32'b0;

        #10 
        rst_n = 1'b1;
        #10;

        $display("Starting Branch Predictor Testbench");

        $display("\n--> Test 0: Initial state");
        test_num = 0;
        if_pc = 32'h00001000; // Read Port looks at this address
        #1;
        assert (predict_taken == 1'b0) else $error("Test Failed: Initial predict_taken incorrect. Expected 0, got %b", predict_taken);
        assert (predicted_target == 32'b0) else $error("Test Failed: Initial predicted_target incorrect. Expected 0x00000000, got 0x%h", predicted_target);
        $display("Test 0 done.");

        $display("\n--> Test 1: After First Taken Branch");
        test_num = 1;
        @(posedge clk);
        #1;
        id_is_branch = 1'b1;
        id_pc = 32'h00001000;
        id_actual_taken = 1'b1;
        id_actual_target = 32'h00001040;
        
        @(posedge clk);
        #1;
        id_is_branch = 1'b0;
        
        assert (predict_taken == 1'b1) else $error("Test Failed: After first taken branch, predict_taken incorrect. Expected 1, got %b", predict_taken);
        assert (predicted_target == 32'h00001040) else $error("Test Failed: After first taken branch, predicted_target incorrect. Expected 0x00001040, got 0x%h", predicted_target);
        $display("Test 1 done.");

        $display("\n--> Test 2: After Second Taken Branch");
        test_num = 2;
        @(posedge clk);
        #1;
        id_is_branch = 1'b1;
        id_pc = 32'h00001000;
        id_actual_taken = 1'b1;
        id_actual_target = 32'h00001040;

        @(posedge clk);
        #1;
        id_is_branch = 1'b0;
        
        assert (predict_taken == 1'b1) else $error("Test Failed: After second taken branch, predict_taken incorrect. Expected 1, got %b", predict_taken);
        assert (predicted_target == 32'h00001040) else $error("Test Failed: After second taken branch, predicted_target incorrect. Expected 0x00001040, got 0x%h", predicted_target);
        $display("Test 2 done.");

        $display("\n--> Test 3: Branch Not Taken");
        test_num = 3;
        @(posedge clk);
        #1;
        id_is_branch = 1'b1;
        id_pc = 32'h00001000;
        id_actual_taken = 1'b0;
        id_actual_target = 32'h00001040;
        
        @(posedge clk);
        #1;
        id_is_branch = 1'b0;
        
        assert (predict_taken == 1'b0) else $error("Test Failed: After branch not taken, predict_taken incorrect. Expected 0, got %b", predict_taken);
        assert (predicted_target == 32'h00001040) else $error("Test Failed: After branch not taken, predicted_target incorrect. Expected 0x00001040, got 0x%h", predicted_target);
        $display("Test 3 done.");

        $display("\n--> Test 4: Second Branch Not Taken");
        test_num = 4;
        @(posedge clk);
        #1;
        id_is_branch = 1'b1;
        id_pc = 32'h00001000;
        id_actual_taken = 1'b0;
        id_actual_target = 32'h00001040;
        
        @(posedge clk);
        #1;
        id_is_branch = 1'b0;
        
        assert (predict_taken == 1'b0) else $error("Test Failed: After second branch not taken, predict_taken incorrect. Expected 0, got %b", predict_taken);
        assert (predicted_target == 32'h00001040) else $error("Test Failed: After second branch not taken, predicted_target incorrect. Expected 0x00001040, got 0x%h", predicted_target);
        $display("Test 4 done.");


        $display("\n--> Test 5: Different Instruction PC Check");
        test_num = 5;
        if_pc = 32'h00002000;
        #1;
        assert (predict_taken == 1'b0) else $error("Test Failed: Different PC check, predict_taken incorrect. Expected 0, got %b", predict_taken);
        assert (predicted_target == 32'b0) else $error("Test Failed: Different PC check, predicted_target incorrect. Expected 0x00000000, got 0x%h", predicted_target);
        $display("Test 5 done.");


        test_num = 0;
        $display("\nAll tests completed.\n");
        $finish;

    end
endmodule