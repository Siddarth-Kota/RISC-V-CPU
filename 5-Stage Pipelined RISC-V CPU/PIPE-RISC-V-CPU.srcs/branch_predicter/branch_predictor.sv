`timescale 1ns / 1ps

module branch_predictor (
    input logic clk,
    input logic rst_n, // Active low reset

    input  logic [31:0] if_pc,
    
    input logic id_is_branch,
    input logic [31:0] id_pc,
    input logic id_actual_taken,
    input logic [31:0] id_actual_target

    output logic predict_taken,
    output logic [31:0] predicted_target,
    );

    logic [31:0] btb_targets [63:0]; // 64-entry Branch Target Buffer
    logic [20:0] btb_tags [63:0]; // Upper 20 bits of PC as tag for BTB
    logic btb_valids [63:0]; // Valid bits for BTB entries
    logic [1:0] bht_states [63:0]; // 2-bit Branch History Table states
    /*  
        Strongly Not Taken = 00
        Weakly Not Taken = 01
        Weakly Taken = 10
        Strongly Taken = 11
    */

    logic [5:0] if_pc_index;
    assign if_pc_index = if_pc[7:2];
    logic [20:0] if_pc_tag;
    assign if_pc_tag = if_pc[31:11];

    always_comb begin
        predict_taken = 0;
        predicted_target = 32'b0;

        if(btb_valids[if_pc_index] && btb_tags[if_pc_index] == if_pc_tag) begin
            predicted_target = btb_targets[if_pc_index];
            predict_taken = bht_states[if_pc_index][1]; //Checks MSB for state 10 and 11 predict taken
        end
    end

    logic [5:0] id_pc_index;
    assign id_pc_index = id_pc[7:2];
    logic [20:0] id_pc_tag;
    assign id_pc_tag = id_pc[31:11];

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            for(int i = 0; i < 64; i++) begin
                btb_valids[i] <= 0;
                bht_states[i] <= 2'b01; // Initialize to weakly not taken
            end
        end
        else if (id_is_branch) begin
            if(id_actual_taken) begin
                if(bht_states[id_pc_index] != 2'b11) begin
                    bht_states[id_pc_index] <= bht_states[id_pc_index] + 1'b1; // Move towards strongly taken
                end
            end
            else begin
                if(bht_states[id_pc_index] != 2'b00) begin
                    bht_states[id_pc_index] <= bht_states[id_pc_index] - 1'b1; // Move towards strongly not taken
                end
            end
            if(id_actual_taken) begin
                btb_valids[id_pc_index] <= 1;
                btb_tags[id_pc_index] <= id_pc_tag;
                btb_targets[id_pc_index] <= id_actual_target;
            end
        end
    end
endmodule