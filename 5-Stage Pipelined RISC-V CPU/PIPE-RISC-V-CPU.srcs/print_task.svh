task printPipeline();
    begin
        string if_str, id_str, ex_str, mem_str, wb_str;
        string if_name, id_name, ex_name, mem_name, wb_name;
        
        if_str  = (dut.if_instruction === 32'h00000013 || dut.if_instruction === 32'bx) ? "NOP" : "ACTIVE";
        id_str  = (dut.id_instruction === 32'h00000013 || dut.id_instruction === 32'bx) ? "NOP" : "ACTIVE";
        ex_str  = (inst_EX === 32'h00000013 || inst_EX === 32'bx) ? "NOP" : "ACTIVE";
        mem_str = (inst_MEM === 32'h00000013 || inst_MEM === 32'bx) ? "NOP" : "ACTIVE";
        wb_str  = (inst_WB === 32'h00000013 || inst_WB === 32'bx) ? "NOP" : "ACTIVE";

        if_name = get_inst_name(dut.if_instruction);
        id_name = get_inst_name(dut.id_instruction);
        ex_name = get_inst_name(inst_EX);
        mem_name = get_inst_name(inst_MEM);
        wb_name = get_inst_name(inst_WB);

        $display("\n---------------------------------------------------------------------------------------------------");
        $display("Time: %0t | Clock Cycles: %0d" , $time, $time/10 + 1);
        $display("IF  | PC = 0x%08h | Hex: 0x%08h --> [%6s] | [%6s] |", dut.if_PC, dut.if_instruction, if_str, if_name);
        $display("ID  | PC = 0x%08h | Hex: 0x%08h --> [%6s] | [%6s] | rs1=0x%02d rs2=0x%02d rd=0x%02d imm=0x%08h", dut.id_PC, dut.id_instruction, id_str, id_name, dut.id_rs1, dut.id_rs2, dut.id_rd, dut.id_immediate);
        $display("EX  | PC = 0x%08h | Hex: 0x%08h --> [%6s] | [%6s] | alu_result = 0x%08h", pc_EX, inst_EX, ex_str, ex_name, dut.ex_alu_result);
        $display("MEM | PC = 0x%08h | Hex: 0x%08h --> [%6s] | [%6s] | alu_pass/address = 0x%08h | write_data = 0x%08h | read_data = 0x%08h", pc_MEM, inst_MEM, mem_str, mem_name, dut.mem_alu_result, dut.mem_write_data, dut.mem_read_wb_data);    
        $display("WB  | PC = 0x%08h | Hex: 0x%08h --> [%6s] | [%6s] | reg_write_data = 0x%08h", pc_WB, inst_WB, wb_str, wb_name, dut.wb_write_data_final);
        
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
        
        if (if_str == "ACTIVE" && !dut.hazard_stall) begin
            if (is_branch_or_jump(dut.if_instruction)) begin
                $write(" >>> PREDICTION (IF): Saw %s at [PC: 0x%08h]. Predictor guesses %s.", 
                    if_name, dut.if_PC, dut.if_predict_taken ? "TAKEN" : "NOT TAKEN");
                if (dut.if_predict_taken) begin
                    $write(" Redirecting next fetch to 0x%08h\n", dut.if_predicted_target);
                end
                else begin
                    $write("\n");
                end
            end
            else if (dut.if_predict_taken) begin
                $display(" >>> PREDICTION (IF): PHANTOM! Predictor guessed TAKEN for non-branch %s at [PC: 0x%08h]. Redirecting to 0x%08h", if_name, dut.if_PC, dut.if_predicted_target);
            end
        end

        if ((dut.id_branch || dut.id_jump) && id_str == "ACTIVE" && !dut.hazard_stall) begin
            if (dut.id_mispredict) begin
                $display(" >>> RESOLUTION (ID): MISPREDICT on %s [PC: 0x%08h]! Guessed %s, but actual is %s. Flushing IF and recovering PC to 0x%08h", 
                    id_name, dut.id_PC,
                    dut.id_predict_taken ? "TAKEN" : "NOT TAKEN",
                    dut.id_pc_source ? "TAKEN" : "NOT TAKEN",
                    dut.id_recovery_target);
            end else begin
                $display(" >>> RESOLUTION (ID): CORRECT PREDICTION on %s [PC: 0x%08h]! Guessed %s. 0-cycle penalty achieved.", 
                    id_name, dut.id_PC,
                    dut.id_predict_taken ? "TAKEN" : "NOT TAKEN");
            end
        end 
        else if (dut.id_mispredict && id_str == "ACTIVE") begin
            $display(" >>> RESOLUTION (ID): PHANTOM MISPREDICT! Guessed TAKEN on %s [PC: 0x%08h]. Flushing IF and recovering PC to 0x%08h", id_name, dut.id_PC, dut.id_recovery_target);
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