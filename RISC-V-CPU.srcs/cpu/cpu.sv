`timescale 1ns / 1ps

module cpu (
    input logic clk,
    input logic rst_n
);

    // Program Counter
    reg [31:0] pc;
    logic [31:0] pc_next;

    always_comb begin : pcSelect
        case (pc_source)
            1'b1 : pc_next = pc + immediate; //branch taken
            default : pc_next = pc + 4; //next instruction
        endcase
    end

    always @(posedge clk) begin
        if (rst_n == 0) begin
            pc <= 32'b0;
        end else begin
            pc <= pc_next;
        end
    end

    // Instruction Memory
    wire [31:0] Instruction;

    memory #(
        .mem_init("instr_mem_test.hex")
    ) instruction_memory (
        .clk(clk),
        .rst_n(rst_n),
        .write_enable(1'b0),
        .address(pc),
        .write_data(32'b0),
        
        .read_data(Instruction)
    );

    // Control
    logic [6:0] op;
    assign op = Instruction[6:0];
    logic [2:0] func3;
    assign func3 = Instruction[14:12];
    logic [6:0] func7;
    assign func7 = Instruction[31:25];
    wire alu_zero;

    wire [2:0] alu_control;
    wire [1:0] imm_source;
    wire mem_write;
    wire reg_write;
    wire alu_source;
    wire write_back_source;
    wire pc_source;

    control control_unit (
        .op(op),
        .func3(func3),
        .func7(func7),
        .alu_zero(alu_zero),
        
        .alu_control(alu_control),
        .imm_source(imm_source),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .alu_source(alu_source),
        .write_back_source(write_back_source),

        .pc_source(pc_source)   
    );

    //RegFile
    logic [4:0] rs1, rs2, rd;
    assign rs1 = Instruction[19:15];
    assign rs2 = Instruction[24:20];
    assign rd = Instruction[11:7];
    wire [31:0] reg_data1, reg_data2;
    
    logic [31:0] write_data;
    always_comb begin : wbSelect
        case (write_back_source)
            1'b1 : write_data = mem_read;
            default : write_data = alu_result;
        endcase
    end

    registers registers (
        .clk(clk),
        .rst_n(rst_n),

        .read_address1(rs1),
        .read_address2(rs2),

        .read_data1(reg_data1),
        .read_data2(reg_data2),

        .write_enable(reg_write),
        .write_data(write_data),
        .write_address(rd)
    );

    //Sign Extend
    logic [24:0] raw_src;
    assign raw_src = Instruction[31:7];
    wire [31:0] immediate;

    signextender sign_extender (
        .raw_src(raw_src),
        .imm_source(imm_source),
        
        .immediate(immediate)
    );

    //ALU
    wire [31:0] alu_result;
    logic [31:0] alu_op2;

    always_comb begin : alu_source_select
        case (alu_source)
            1'b1 : alu_op2 = immediate;
            default : alu_op2 = reg_data2;
        endcase
    end

    ALU alu_inst(
        .alu_control(alu_control),
        .operand1(reg_data1),
        .operand2(alu_op2),
        
        .alu_result(alu_result),
        .zero(alu_zero)
    );

    //Data Memory
    wire [31:0] mem_read;

    memory #(
        .mem_init("data_mem_test.hex")
    ) data_memory (
        .clk(clk),
        .rst_n(1'b1),
        .write_enable(mem_write),
        .address(alu_result),
        .write_data(reg_data2),

        .read_data(mem_read)
    );

endmodule