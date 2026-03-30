`timescale 1ns / 1ps

module cpu_tb;

    logic clk;
    logic rst_n;

    //debug
    logic [5:0] test_num = 0;

    cpu dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Pipeline stage tracking
    logic [31:0] inst_EX, inst_MEM, inst_WB;
    logic [31:0] pc_EX, pc_MEM, pc_WB;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            inst_EX  <= 32'h00000013;
            inst_MEM <= 32'h00000013;
            inst_WB  <= 32'h00000013;
            pc_EX    <= 32'h00000000;
            pc_MEM   <= 32'h00000000;
            pc_WB    <= 32'h00000000;
        end 
        else begin
            inst_EX  <= dut.id_instruction;
            inst_MEM <= inst_EX;
            inst_WB  <= inst_MEM;

            pc_EX    <= dut.id_PC;
            pc_MEM   <= pc_EX;
            pc_WB    <= pc_MEM;
        end
    end

    task cpu_reset();
        begin
            rst_n = 0;
            @(negedge clk);
            rst_n = 1;
        end
    endtask

    task printPipeline();
        begin
            string if_str, id_str, ex_str, mem_str, wb_str;
            
            if_str  = (dut.if_instruction === 32'h00000013 || dut.if_instruction === 32'bx) ? "NOP   " : "ACTIVE";
            id_str  = (dut.id_instruction === 32'h00000013 || dut.id_instruction === 32'bx) ? "NOP   " : "ACTIVE";
            ex_str  = (inst_EX === 32'h00000013 || inst_EX === 32'bx) ? "NOP   " : "ACTIVE";
            mem_str = (inst_MEM === 32'h00000013 || inst_MEM === 32'bx) ? "NOP   " : "ACTIVE";
            wb_str  = (inst_WB === 32'h00000013 || inst_WB === 32'bx) ? "NOP   " : "ACTIVE";

            $display("\n---------------------------------------------------------------------------------------------------");
            $display("Time: %0t | Clock Cycles: %0d" , $time, $time/10 + 1);
            $display("IF  | PC = 0x%08h | Hex: 0x%08h --> [%s]", dut.if_PC, dut.if_instruction, if_str);
            $display("ID  | PC = 0x%08h | Hex: 0x%08h --> [%s] | rs1=0x%02h rs2=0x%02h rd=0x%02h imm=0x%08h", dut.id_PC, dut.id_instruction, id_str, dut.id_rs1, dut.id_rs2, dut.id_rd, dut.id_immediate);
            $display("EX  | PC = 0x%08h | Hex: 0x%08h --> [%s] | alu_result = 0x%08h", pc_EX, inst_EX, ex_str, dut.ex_alu_result);
            $display("MEM | PC = 0x%08h | Hex: 0x%08h --> [%s] | addr = 0x%08h | write_data = 0x%08h | read_data = 0x%08h", pc_MEM, inst_MEM, mem_str, dut.mem_alu_result, dut.mem_write_data, dut.mem_read_wb_data);    
            $display("WB  | PC = 0x%08h | Hex: 0x%08h --> [%s] | reg_write_data = 0x%08h", pc_WB, inst_WB, wb_str, dut.wb_write_data_final);
            $display("---------------------------------------------------------------------------------------------------\n");
        end
    endtask

    always @(posedge clk) begin
        if(rst_n) begin
            #0.2;
            printPipeline();
        end
    end

    initial begin
        $display("Starting Pipelined CPU TestBench");
        test_num = 0;

        $display("Running Hazard-Free Pipeline instruction tests");
        cpu_reset();

        repeat(4) @(posedge clk); #0.1;


        $display("\n--> Test 1: I-type ADDI Instruction (x1 = 0x111)");
        test_num = 1;

        @(posedge clk); #0.1;
        
        assert (dut.registers.reg_array[1] == 32'h00000111) else $error("ADDI Test 1 Failed. Expected 00000111, got %h", dut.registers.reg_array[1]);
        $display("Test 1 done");

        $display("\n--> Test 2: I-type ADDI Instruction (x2 = 0x222)");
        test_num = 2;
        
        @(posedge clk); #0.1;

        assert (dut.registers.reg_array[2] == 32'h00000222) else $error("ADDI Test 2 Failed. Expected 00000222, got %h", dut.registers.reg_array[2]);
        $display("Test 2 done");
    

        $display("\n--> Test 3: R-type ADD Instruction (x3 = x1 + x2)");
        test_num = 3;
        
        @(posedge clk); #0.1;

        assert (dut.registers.reg_array[3] == 32'h00000333) else $error("ADD Test 3 Failed. Expected 00000333, got %h", dut.registers.reg_array[3]);
        $display("Test 3 done");


        $display("\n--> Test 4: S-type SW Instruction (mem[3] = x3)");
        test_num = 4;
        
        @(posedge clk); #0.1;

        assert (dut.data_memory.mem_array[3] == 32'h00000333) else $error("SW Test 4 Failed. Expected 00000333, got %h", dut.data_memory.mem_array[3]);
        $display("Test 4 done");


        $display("\n--> Test 5: I-type LW Instruction (x4 = mem[3])");
        test_num = 5;
        
        @(posedge clk); #0.1;
        
        assert (dut.registers.reg_array[4] == 32'h00000333) else $error("LW Test 5 Failed. Expected 00000333, got %h", dut.registers.reg_array[4]);
        $display("Test 5 done");

        test_num = 0;
        $display("\n--> CPU instruction tests complete\n");
        $finish;
    end
endmodule