`timescale 1ns / 1ps

module cpu_tb;

    logic clk;
    logic rst_n;

    //debug
    logic [2:0] test_num = 0;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #0.5 clk = ~clk;
    end

    logic [31:0] expected_instr_mem [0:255];

    task cpu_reset();
        begin
            rst_n = 0;
            @(negedge clk);
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    initial begin
        int check_limit = 5;

        $readmemh("instr_mem_test.hex", expected_instr_mem);

        $display("Starting CPU TestBench");
        test_num = 1;
        $display("testing the CPU Initializing");

        cpu_reset();
        assert (dut.pc == 32'h00000000) else $error("PC Init Failed. Expected 0, got %h", dut.pc);
        
        for(int i = 0; i < check_limit; i++) begin
            if(expected_instr_mem[i] == 32'bx) begin
                $display("Reached end of hex file at index %0d", i);
                break;
            end
            //test DUT instruction vs expected memory
            assert(dut.Instruction == expected_instr_mem[i]) else $error("Instruction Wrong at index %0d. Expected %h, got %h", i, expected_instr_mem[i], dut.Instruction);
            @(posedge clk);
        end
        $display("CPU initialization test complete");

        test_num = 2;
        $display("Running CPU instruction tests");
        cpu_reset();
        @(posedge clk);
        assert (dut.registers.reg_array[18] == 32'hDDAAEEFF) else $error("LW Test Failed. Register x18: Expected DDAAEEFF, got %h", dut.registers.reg_array[18]);

        $display("CPU instruction tests complete");
        $finish;
    end
endmodule