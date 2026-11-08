`timescale 1ns / 1ps
module cpu_sram_system_tb;
    logic clk = 0, rst_n = 0, core_rst_n = 0;
    always #5 clk = ~clk;
    logic host_req_valid = 0, host_instruction = 0, host_write = 0, host_req_ready;
    logic [31:0] host_addr = 0, host_wdata = 0;
    logic [3:0] host_be = 4'b1111;
    logic host_rsp_valid, host_rsp_ready = 0, memory_idle;
    logic [31:0] host_rsp_data;
    logic retire_valid, retire_reg_write;
    logic [31:0] retire_pc, retire_instruction, retire_wdata;
    logic [4:0] retire_rd;
    integer retired = 0, cycles = 0;
    cpu_sram_system dut (.*);
    task automatic host_access(input bit instruction_port, wr, input logic [31:0] address, data, input logic [31:0] expected);
        begin
            @(negedge clk);
            host_instruction = instruction_port; host_write = wr;
            host_addr = address; host_wdata = data; host_req_valid = 1;
            do @(posedge clk); while (!host_req_ready);
            @(negedge clk); host_req_valid = 0;
            wait (host_rsp_valid);
            repeat (3) @(negedge clk);
            if (!wr && host_rsp_data !== expected) $fatal(1,"Host read expected %h got %h",expected,host_rsp_data);
            host_rsp_ready = 1;
            @(negedge clk); host_rsp_ready = 0;
        end
    endtask
    initial begin
        repeat (3) @(negedge clk); rst_n = 1;
        // Full instruction initialization goes through the public host interface.
        host_access(1,1,0,32'hfff00093,0);  // ADDI x1,x0,-1
        host_access(1,1,4,32'h00100123,0);  // SB x1,2(x0)
        host_access(1,1,8,32'h00002103,0);  // LW x2,0(x0)
        host_access(1,1,12,32'h00110193,0); // ADDI x3,x2,1
        host_access(1,1,16,32'h06300f93,0); // completion marker
        host_access(1,1,20,32'h0000006f,0); // JAL x0,0
        host_access(0,1,0,32'h12345678,0);
        host_access(0,0,0,0,32'h12345678);
        host_access(1,0,8,0,32'h00002103);
        wait (memory_idle);
        @(negedge clk); core_rst_n = 1;
    end
    always @(posedge clk) begin
        if (core_rst_n) cycles++;
        if (retire_valid) begin
            if (retire_pc !== retired*4) $fatal(1,"SRAM system retirement order PC=%h",retire_pc);
            case (retired)
                0: if (!retire_reg_write || retire_rd != 1 || retire_wdata !== 32'hffffffff) $fatal(1,"ADDI failed");
                1: if (retire_reg_write) $fatal(1,"Store wrote a register");
                2: if (!retire_reg_write || retire_rd != 2 || retire_wdata !== 32'h12ff5678) $fatal(1,"SRAM byte lanes/load failed");
                3: if (!retire_reg_write || retire_rd != 3 || retire_wdata !== 32'h12ff5679) $fatal(1,"Dependent load failed");
                4: begin
                    if (!retire_reg_write || retire_rd != 31 || retire_wdata != 99) $fatal(1,"Completion failed");
                    $display("PASS SRAM system host loading, byte store and dependent load retired=%0d cycles=%0d",retired+1,cycles);
                    $finish;
                end
                default: $fatal(1,"Unexpected retirement");
            endcase
            retired++;
        end
    end
    initial begin #50000; $fatal(1,"SRAM system timeout"); end
endmodule
