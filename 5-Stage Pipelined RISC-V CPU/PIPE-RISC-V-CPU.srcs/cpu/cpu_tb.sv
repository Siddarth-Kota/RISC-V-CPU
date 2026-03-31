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
            inst_EX  <= dut.hazard_stall ? 32'h00000013 : dut.id_instruction;
            inst_MEM <= inst_EX;
            inst_WB  <= inst_MEM;

            pc_EX    <= dut.hazard_stall ? 32'hxxxxxxxx : dut.id_PC;
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
            $display("ID  | PC = 0x%08h | Hex: 0x%08h --> [%s] | rs1=0x%02d rs2=0x%02d rd=0x%02d imm=0x%08h", dut.id_PC, dut.id_instruction, id_str, dut.id_rs1, dut.id_rs2, dut.id_rd, dut.id_immediate);
            $display("EX  | PC = 0x%08h | Hex: 0x%08h --> [%s] | alu_result = 0x%08h", pc_EX, inst_EX, ex_str, dut.ex_alu_result);
            $display("MEM | PC = 0x%08h | Hex: 0x%08h --> [%s] | alu_pass/address = 0x%08h | write_data = 0x%08h | read_data = 0x%08h", pc_MEM, inst_MEM, mem_str, dut.mem_alu_result, dut.mem_write_data, dut.mem_read_wb_data);    
            $display("WB  | PC = 0x%08h | Hex: 0x%08h --> [%s] | reg_write_data = 0x%08h", pc_WB, inst_WB, wb_str, dut.wb_write_data_final);
            if (dut.hazard_stall) begin
                if (dut.hazard_detection_unit.load_use_stall) begin
                    $display(" >>> STATUS: DATA HAZARD (Load-Use)! ID stage needs data from a Load in EX. Stalling.");
                end
                else if (dut.hazard_detection_unit.jalr_stall) begin
                    $display(" >>> STATUS: EARLY JUMP HAZARD (JALR)! ID stage needs target data from EX/MEM. Stalling.");
                end
                else if (dut.hazard_detection_unit.branch_stall) begin
                    $display(" >>> STATUS: EARLY BRANCH HAZARD (B-Type)! ID stage needs compare data from EX/MEM. Stalling.");
                end
                else begin
                    $display(" >>> STATUS: HAZARD DETECTED! Pipeline Stalled.");
                end
            end
            if(dut.if_flush) begin
                $display(" >>> STATUS: Control Hazard Detected (Branch/Jump Taken)! Flushing IF stage.");
            end
            if (dut.forwardA != 2'b00 && ex_str == "ACTIVE") begin
                $display(" >>> STATUS: Forwarding to rs1 from %s stage", (dut.forwardA == 2'b10) ? "MEM" : "WB");
            end
            if (dut.forwardB != 2'b00 && ex_str == "ACTIVE" && dut.ex_alu_source == 1'b0) begin
                $display(" >>> STATUS: Forwarding to rs2 from %s stage", (dut.forwardB == 2'b10) ? "MEM" : "WB");
            end
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
        cpu_reset();

        repeat(4) @(posedge clk); #0.1;
        
        test_num = 1;
        $display("\n--> Test %0d: U-type Instruction (LUI)", test_num);
        @(posedge clk); #0.1; //LUI x1, 0x1
        assert(dut.registers.reg_array[1] == 32'h00001000) else $error("Test %0d Failed: LUI did not write correct value to x1. Expected 0x00001000, got 0x%08h", test_num, dut.registers.reg_array[1]);
        $display("Test %0d Complete\n", test_num);

        test_num = 2;
        $display("\n--> Test %0d: U-type Instruction (AUIPC)", test_num);
        @(posedge clk); #0.1; //AUIPC x2, 0x1
        assert(dut.registers.reg_array[2] == 32'h00001004) else $error("Test %0d Failed: AUIPC did not write correct value to x2. Expected 0x00001004, got 0x%08h", test_num, dut.registers.reg_array[2]);
        $display("Test %0d Complete\n", test_num);

        test_num = 3;
        $display("\n--> Test %0d: I-type Instruction (ADDI)", test_num);
        @(posedge clk); #0.1; //ADDI x3, x0, -1
        assert(dut.registers.reg_array[3] == 32'hFFFFFFFF) else $error("Test %0d Failed: ADDI did not write correct value to x3. Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[3]);
        $display("Test %0d Complete\n", test_num);

        test_num = 4;
        $display("\n--> Test %0d: I-type Instruction (SLTI)", test_num);
        @(posedge clk); #0.1; //SLTI x4, x3, 1
        assert(dut.registers.reg_array[4] == 32'h00000001) else $error("Test %0d Failed: SLTI did not write correct value to x4. Expected 0x00000001, got 0x%08h", test_num, dut.registers.reg_array[4]);
        $display("Test %0d Complete\n", test_num);

        test_num = 5;
        $display("\n--> Test %0d: I-type Instruction (SLTIU)", test_num);
        @(posedge clk); #0.1; //SLTIU x5, x3, 1
        assert(dut.registers.reg_array[5] == 32'h00000000) else $error("Test %0d Failed: SLTIU did not write correct value to x5. Expected 0x00000000, got 0x%08h", test_num, dut.registers.reg_array[5]);
        $display("Test %0d Complete\n", test_num);

        test_num = 6;
        $display("\n--> Test %0d: I-type Instruction (XORI)", test_num);
        @(posedge clk); #0.1; //XORI x6, x3, -1
        assert(dut.registers.reg_array[6] == 32'h00000000) else $error("Test %0d Failed: XORI did not write correct value to x6. Expected 0x00000000, got 0x%08h", test_num, dut.registers.reg_array[6]);
        $display("Test %0d Complete\n", test_num);

        test_num = 7;
        $display("\n--> Test %0d: I-type Instruction (ORI)", test_num);
        @(posedge clk); #0.1; //ORI x7, x3, 0
        assert(dut.registers.reg_array[7] == 32'hFFFFFFFF) else $error("Test %0d Failed: ORI did not write correct value to x7. Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[7]);
        $display("Test %0d Complete\n", test_num);

        test_num = 8;
        $display("\n--> Test %0d: I-type Instruction (ANDI)", test_num);
        @(posedge clk); #0.1; //ANDI x8, x3, 1
        assert(dut.registers.reg_array[8] == 32'h00000001) else $error("Test %0d Failed: Expected 0x00000001, got 0x%08h", test_num, dut.registers.reg_array[8]);
        $display("Test %0d Complete\n", test_num);

        test_num = 9;
        $display("\n--> Test %0d: I-type Instruction (SLLI)", test_num);
        @(posedge clk); #0.1; //SLLI x9, x3, 1
        assert(dut.registers.reg_array[9] == 32'hFFFFFFFE) else $error("Test %0d Failed: Expected 0xFFFFFFFE, got 0x%08h", test_num, dut.registers.reg_array[9]);
        $display("Test %0d Complete\n", test_num);

        test_num = 10;
        $display("\n--> Test %0d: I-type Instruction (SRLI)", test_num);
        @(posedge clk); #0.1; //SRLI x10, x3, 1
        assert(dut.registers.reg_array[10] == 32'h7FFFFFFF) else $error("Test %0d Failed: Expected 0x7FFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[10]);
        $display("Test %0d Complete\n", test_num);

        test_num = 11;
        $display("\n--> Test %0d: I-type Instruction (SRAI)", test_num);
        @(posedge clk); #0.1; //SRAI x11, x3, 1
        assert(dut.registers.reg_array[11] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[11]);
        $display("Test %0d Complete\n", test_num);

        test_num = 12;
        $display("\n--> Test %0d: R-type Instruction (ADD)", test_num);
        @(posedge clk); #0.1; //ADD x12, x3, x4
        assert(dut.registers.reg_array[12] == 32'h00000000) else $error("Test %0d Failed: Expected 0x00000000, got 0x%08h", test_num, dut.registers.reg_array[12]);
        $display("Test %0d Complete\n", test_num);

        test_num = 13;
        $display("\n--> Test %0d: R-type Instruction (SUB)", test_num);
        @(posedge clk); #0.1; //SUB x13, x3, x4
        assert(dut.registers.reg_array[13] == 32'hFFFFFFFE) else $error("Test %0d Failed: Expected 0xFFFFFFFE, got 0x%08h", test_num, dut.registers.reg_array[13]);
        $display("Test %0d Complete\n", test_num);

        test_num = 14;
        $display("\n--> Test %0d: R-type Instruction (SLL)", test_num);
        @(posedge clk); #0.1; //SLL x14, x3, x4
        assert(dut.registers.reg_array[14] == 32'hFFFFFFFE) else $error("Test %0d Failed: Expected 0xFFFFFFFE, got 0x%08h", test_num, dut.registers.reg_array[14]);
        $display("Test %0d Complete\n", test_num);

        test_num = 15;
        $display("\n--> Test %0d: R-type Instruction (SLT)", test_num);
        @(posedge clk); #0.1; //SLT x15, x3, x4
        assert(dut.registers.reg_array[15] == 32'h00000001) else $error("Test %0d Failed: Expected 0x00000001, got 0x%08h", test_num, dut.registers.reg_array[15]);
        $display("Test %0d Complete\n", test_num);

        test_num = 16;
        $display("\n--> Test %0d: R-type Instruction (SLTU)", test_num);
        @(posedge clk); #0.1; //SLTU x16, x3, x4
        assert(dut.registers.reg_array[16] == 32'h00000000) else $error("Test %0d Failed: Expected 0x00000000, got 0x%08h", test_num, dut.registers.reg_array[16]);
        $display("Test %0d Complete\n", test_num);

        test_num = 17;
        $display("\n--> Test %0d: R-type Instruction (XOR)", test_num);
        @(posedge clk); #0.1; //XOR x17, x3, x4
        assert(dut.registers.reg_array[17] == 32'hFFFFFFFE) else $error("Test %0d Failed: Expected 0xFFFFFFFE, got 0x%08h", test_num, dut.registers.reg_array[17]);
        $display("Test %0d Complete\n", test_num);

        test_num = 18;
        $display("\n--> Test %0d: R-type Instruction (SRL)", test_num);
        @(posedge clk); #0.1; //SRL x18, x3, x4
        assert(dut.registers.reg_array[18] == 32'h7FFFFFFF) else $error("Test %0d Failed: Expected 0x7FFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[18]);
        $display("Test %0d Complete\n", test_num);

        test_num = 19;
        $display("\n--> Test %0d: R-type Instruction (SRA)", test_num);
        @(posedge clk); #0.1; //SRA x19, x3, x4
        assert(dut.registers.reg_array[19] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[19]);
        $display("Test %0d Complete\n", test_num);

        test_num = 20;
        $display("\n--> Test %0d: R-type Instruction (OR)", test_num);
        @(posedge clk); #0.1; //OR x20, x3, x4
        assert(dut.registers.reg_array[20] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[20]);
        $display("Test %0d Complete\n", test_num);

        test_num = 21;
        $display("\n--> Test %0d: R-type Instruction (AND)", test_num);
        @(posedge clk); #0.1; //AND x21, x3, x4
        assert(dut.registers.reg_array[21] == 32'h00000001) else $error("Test %0d Failed: Expected 0x00000001, got 0x%08h", test_num, dut.registers.reg_array[21]);
        $display("Test %0d Complete\n", test_num);

        test_num = 22;
        $display("\n--> Test %0d: S-type Instruction (SW)", test_num);
        @(posedge clk); #0.1; //SW x3, 0(x0)
        assert(dut.data_memory.mem_array[0] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected mem[0] = 0xFFFFFFFF, got 0x%08h", test_num, dut.data_memory.mem_array[0]);
        $display("Test %0d Complete\n", test_num);

        test_num = 23;
        $display("\n--> Test %0d: S-type Instruction (SH)", test_num);
        @(posedge clk); #0.1; //SH x3, 4(x0)
        assert((dut.data_memory.mem_array[1] & 32'h0000FFFF) == 32'h0000FFFF) else $error("Test %0d Failed: Expected mem[1] bottom half = 0xFFFF, got 0x%08h", test_num, dut.data_memory.mem_array[1]);
        $display("Test %0d Complete\n", test_num);

        test_num = 24;
        $display("\n--> Test %0d: S-type Instruction (SB)", test_num);
        @(posedge clk); #0.1; //SB x3, 8(x0)
        assert((dut.data_memory.mem_array[2] & 32'h000000FF) == 32'h000000FF) else $error("Test %0d Failed: Expected mem[2] bottom byte = 0xFF, got 0x%08h", test_num, dut.data_memory.mem_array[2]);
        $display("Test %0d Complete\n", test_num);

        test_num = 25;
        $display("\n--> Test %0d: I-type Instruction (LW)", test_num);
        @(posedge clk); #0.1; //LW x22, 0(x0)
        assert(dut.registers.reg_array[22] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[22]);
        $display("Test %0d Complete\n", test_num);

        test_num = 26;
        $display("\n--> Test %0d: I-type Instruction (LH - Sign Ext)", test_num);
        @(posedge clk); #0.1; //LH x23, 4(x0)
        assert(dut.registers.reg_array[23] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[23]);
        $display("Test %0d Complete\n", test_num);

        test_num = 27;
        $display("\n--> Test %0d: I-type Instruction (LB - Sign Ext)", test_num);
        @(posedge clk); #0.1; //LB x24, 8(x0)
        assert(dut.registers.reg_array[24] == 32'hFFFFFFFF) else $error("Test %0d Failed: Expected 0xFFFFFFFF, got 0x%08h", test_num, dut.registers.reg_array[24]);
        $display("Test %0d Complete\n", test_num);

        test_num = 28;
        $display("\n--> Test %0d: I-type Instruction (LHU - Zero Ext)", test_num);
        @(posedge clk); #0.1; //LHU x25, 4(x0)
        assert(dut.registers.reg_array[25] == 32'h0000FFFF) else $error("Test %0d Failed: Expected 0x0000FFFF, got 0x%08h", test_num, dut.registers.reg_array[25]);
        $display("Test %0d Complete\n", test_num);

        test_num = 29;
        $display("\n--> Test %0d: I-type Instruction (LBU - Zero Ext)", test_num);
        @(posedge clk); #0.1; //LBU x26, 8(x0)
        assert(dut.registers.reg_array[26] == 32'h000000FF) else $error("Test %0d Failed: Expected 0x000000FF, got 0x%08h", test_num, dut.registers.reg_array[26]);
        $display("Test %0d Complete\n", test_num);

        test_num = 30;
        $display("\n--> Test %0d: B-type Instruction (BEQ - Not Taken)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] == 32'd77) else $error("Test %0d Failed: Fallthrough failed! Expected 77, got %0d", test_num, dut.registers.reg_array[29]);
        $display("Test %0d Complete\n", test_num);

        test_num = 31;
        $display("\n--> Test %0d: B-type Instruction (BEQ - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BEQ didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 32;
        $display("\n--> Test %0d: B-type Instruction (BNE - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BNE didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 33;
        $display("\n--> Test %0d: B-type Instruction (BLT - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BLT didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 34;
        $display("\n--> Test %0d: B-type Instruction (BGE - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BGE didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 35;
        $display("\n--> Test %0d: B-type Instruction (BLTU - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BLTU didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 36;
        $display("\n--> Test %0d: B-type Instruction (BGEU - Taken Flush Check)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[29] != 32'd101) else $error("Test %0d Failed: BGEU didn't flush correctly! x29 was overwritten.", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 37;
        $display("\n--> Test %0d: J-type Instruction (JAL)", test_num);
        repeat(2) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[27] == 32'h000000B0) else $error("Test %0d Failed", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 38;
        $display("\n--> Test %0d: I-type Instruction (JALR)", test_num);
        repeat(4) @(posedge clk); #0.1; 
        assert(dut.registers.reg_array[28] == 32'h000000B8) else $error("Test %0d Failed", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 39;
        $display("\n--> Test %0d: Final Execution Survival Check", test_num);
        @(posedge clk); #0.1; //ADDI x31, x0, 99
        assert(dut.registers.reg_array[31] == 32'd99) else $error("Test %0d Failed", test_num);
        $display("Test %0d Complete\n", test_num);

        test_num = 0;
        $display("\nCPU Pipelined TestBench Complete\n");
        $finish;
    end
endmodule