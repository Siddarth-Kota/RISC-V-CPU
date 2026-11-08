`timescale 1ns / 1ps
module cpu_tb;
    logic clk = 0, rst_n = 0;
    always #5 clk = ~clk;
    logic iq, ir, iv, irdy, dq, dr, dv, drdy, dw;
    logic [31:0] ia, insn, da, wd, rd;
    logic [3:0] be;
    logic retire_valid, retire_we;
    logic [31:0] retire_pc, retire_instruction, retire_data;
    logic [4:0] retire_rd;
    integer i_writes, d_writes, i_requests, d_requests;
    integer cycles = 0, retired = 0, ref_stores = 0;
    integer redirects_pending = 0, fetch_stalls = 0, data_stalls = 0;
    integer discarded = 0, buffer_waits = 0;
    logic [31:0] ref_regs [0:31];
    logic [31:0] ref_mem [0:1023];
    logic [31:0] ref_pc = 0;
    string program_file;
    integer unused;
    localparam bit PREFETCH =
`ifdef TEST_PREFETCH
        1;
`else
        0;
`endif
    cpu #(.PREFETCH(PREFETCH)) dut (
        .clk(clk), .rst_n(rst_n),
        .imem_req_valid(iq), .imem_req_ready(ir), .imem_req_addr(ia),
        .imem_rsp_valid(iv), .imem_rsp_ready(irdy), .imem_rsp_data(insn),
        .dmem_req_valid(dq), .dmem_req_ready(dr), .dmem_req_addr(da),
        .dmem_req_write(dw), .dmem_req_wdata(wd), .dmem_req_be(be),
        .dmem_rsp_valid(dv), .dmem_rsp_ready(drdy), .dmem_rsp_data(rd),
        .retire_valid(retire_valid), .retire_pc(retire_pc), .retire_instruction(retire_instruction),
        .retire_reg_write(retire_we), .retire_rd(retire_rd), .retire_wdata(retire_data)
    );
    latency_memory #(.INSTRUCTION(1)) imem (
        .clk(clk), .rst_n(rst_n), .req_valid(iq), .req_ready(ir), .req_addr(ia),
        .req_write(1'b0), .req_wdata(32'b0), .req_be(4'b1111),
        .rsp_valid(iv), .rsp_ready(irdy), .rsp_data(insn), .writes(i_writes), .requests(i_requests)
    );
    latency_memory dmem (
        .clk(clk), .rst_n(rst_n), .req_valid(dq), .req_ready(dr), .req_addr(da),
        .req_write(dw), .req_wdata(wd), .req_be(be),
        .rsp_valid(dv), .rsp_ready(drdy), .rsp_data(rd), .writes(d_writes), .requests(d_requests)
    );
    // A blocked request may not be withdrawn or changed; responses must persist.
    assert property (@(posedge clk) disable iff (!rst_n) iq && !ir |=> iq && $stable(ia));
    assert property (@(posedge clk) disable iff (!rst_n) dq && !dr |=> dq && $stable({da,dw,wd,be}));
    assert property (@(posedge clk) disable iff (!rst_n) iv && !irdy |=> iv && $stable(insn));
    assert property (@(posedge clk) disable iff (!rst_n) dv && !drdy |=> dv && $stable(rd));
    assert property (@(posedge clk) disable iff (!rst_n) dut.mem_wait |=> $stable(dut.mem));

    initial begin
        program_file = "instr_mem_test.hex";
        unused = $value$plusargs("program=%s", program_file);
        for (int i = 0; i < 1024; i++) begin
            imem.mem_array[i] = 32'h00000013;
            dmem.mem_array[i] = 32'h10203040 ^ (i * 32'h01010101);
            ref_mem[i] = dmem.mem_array[i];
        end
        for (int i = 0; i < 32; i++) ref_regs[i] = 0;
        $readmemh(program_file, imem.mem_array);
        if ($test$plusargs("vcd")) begin
            $dumpfile("cpu.vcd");
            $dumpvars(0, cpu_tb);
        end
        repeat (3) @(negedge clk);
        rst_n = 1;
    end

    // Independent architectural interpreter: every retired PC, instruction and
    // register result must agree, regardless of latency or speculative fetches.
    task automatic check_retirement;
        logic [31:0] inst, a, b, imm, result, next_pc, addr, word_data;
        logic [6:0] op;
        logic [2:0] f3;
        logic [4:0] dest;
        logic writes_reg, taken;
        integer shift;
        begin
            inst = imem.mem_array[ref_pc >> 2];
            if (retire_pc !== ref_pc || retire_instruction !== inst)
                $fatal(1, "Retirement order: expected PC=%h inst=%h got PC=%h inst=%h", ref_pc, inst, retire_pc, retire_instruction);
            a = ref_regs[inst[19:15]];
            b = ref_regs[inst[24:20]];
            dest = inst[11:7];
            op = inst[6:0]; f3 = inst[14:12];
            result = 0; next_pc = ref_pc + 4; writes_reg = 1; taken = 0;
            case (op)
                7'h37: result = {inst[31:12],12'b0};
                7'h17: result = ref_pc + {inst[31:12],12'b0};
                7'h6f: begin
                    imm = {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};
                    result = next_pc; next_pc = ref_pc + imm;
                end
                7'h67: begin
                    result = next_pc; next_pc = (a + {{20{inst[31]}},inst[31:20]}) & 32'hfffffffe;
                end
                7'h63: begin
                    writes_reg = 0;
                    imm = {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};
                    case (f3)
                        0: taken = a == b;
                        1: taken = a != b;
                        4: taken = $signed(a) < $signed(b);
                        5: taken = $signed(a) >= $signed(b);
                        6: taken = a < b;
                        7: taken = a >= b;
                        default: $fatal(1,"Bad reference branch");
                    endcase
                    if (taken) next_pc = ref_pc + imm;
                end
                7'h03, 7'h23: begin
                    imm = op == 7'h03 ? {{20{inst[31]}},inst[31:20]} : {{20{inst[31]}},inst[31:25],inst[11:7]};
                    addr = a + imm;
                    shift = 8 * addr[1:0];
                    word_data = ref_mem[addr >> 2];
                    if (op == 7'h23) begin
                        writes_reg = 0; ref_stores++;
                        case (f3)
                            0: ref_mem[addr >> 2] = (word_data & ~(32'hff << shift)) | ((b & 32'hff) << shift);
                            1: ref_mem[addr >> 2] = (word_data & ~(32'hffff << shift)) | ((b & 32'hffff) << shift);
                            2: ref_mem[addr >> 2] = b;
                            default: $fatal(1,"Bad reference store");
                        endcase
                    end else begin
                        word_data = word_data >> shift;
                        case (f3)
                            0: result = {{24{word_data[7]}},word_data[7:0]};
                            1: result = {{16{word_data[15]}},word_data[15:0]};
                            2: result = word_data;
                            4: result = {24'b0,word_data[7:0]};
                            5: result = {16'b0,word_data[15:0]};
                            default: $fatal(1,"Bad reference load");
                        endcase
                    end
                end
                7'h13, 7'h33: begin
                    imm = {{20{inst[31]}},inst[31:20]};
                    if (op == 7'h13) b = imm;
                    case (f3)
                        0: result = (op == 7'h33 && inst[30]) ? a - b : a + b;
                        1: result = a << b[4:0];
                        2: result = $signed(a) < $signed(b);
                        3: result = a < b;
                        4: result = a ^ b;
                        5: begin
                            if (inst[30]) result = $signed(a) >>> b[4:0];
                            else result = a >> b[4:0];
                        end
                        6: result = a | b;
                        7: result = a & b;
                    endcase
                end
                default: $fatal(1,"Unsupported reference instruction %h",inst);
            endcase
            if (retire_we !== (writes_reg && dest != 0))
                $fatal(1,"Write enable mismatch PC=%h",ref_pc);
            if (writes_reg && dest != 0) begin
                if (retire_rd !== dest || retire_data !== result)
                    $fatal(1,"PC=%h x%0d expected %h got rd=%0d data=%h",ref_pc,dest,result,retire_rd,retire_data);
                ref_regs[dest] = result;
            end
            ref_pc = next_pc;
            retired++;
            // All workloads end with ADDI x31,x0,99; no younger store follows it.
            if (inst == 32'h06300f93) begin
                for (int i = 0; i < 1024; i++)
                    if (ref_mem[i] !== dmem.mem_array[i]) $fatal(1,"Memory mismatch word %0d: %h != %h",i,ref_mem[i],dmem.mem_array[i]);
                if (d_writes != ref_stores) $fatal(1,"Repeated/wrong-path stores: accepted=%0d retired=%0d",d_writes,ref_stores);
                if ($test$plusargs("coverage") && (redirects_pending == 0 || data_stalls == 0 || discarded == 0))
                    $fatal(1,"Required latency/redirect coverage missing");
                $display("PASS retired=%0d cycles=%0d CPI=%f stores=%0d redirects_pending=%0d discarded=%0d fetch_stalls=%0d data_stalls=%0d buffer_waits=%0d",retired,cycles,real'(cycles)/retired,d_writes,redirects_pending,discarded,fetch_stalls,data_stalls,buffer_waits);
                $finish;
            end
        end
    endtask
    always @(posedge clk) begin
        if (rst_n) begin
            cycles++;
            if (dut.redirect && (dut.fetch_pending || dut.offer_valid)) redirects_pending++;
            if (iq && !ir) fetch_stalls++;
            if (dut.mem_wait) data_stalls++;
            if (iv && !irdy) buffer_waits++;
            if (iv && irdy && (dut.pending_killed || dut.redirect)) discarded++;
            if (retire_valid) check_retirement();
            if (cycles > 50000) $fatal(1,"Timeout at reference PC=%h",ref_pc);
        end
    end
endmodule
