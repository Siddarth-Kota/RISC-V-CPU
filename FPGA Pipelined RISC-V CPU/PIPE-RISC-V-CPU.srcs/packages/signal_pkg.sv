`timescale 1ns / 1ps

package signal_pkg;
    // INSTRUCTION OP CODES
    typedef enum logic [6:0] {
        OPCODE_R_TYPE         = 7'b0110011,
        OPCODE_I_TYPE_ALU     = 7'b0010011,
        OPCODE_I_TYPE         = 7'b0000011,
        OPCODE_S_TYPE         = 7'b0100011,
        OPCODE_B_TYPE         = 7'b1100011,
        OPCODE_U_TYPE_LUI     = 7'b0110111,
        OPCODE_U_TYPE_AUIPC   = 7'b0010111,
        OPCODE_J_TYPE         = 7'b1101111,
        OPCODE_J_TYPE_JALR    = 7'b1100111
    } opcode_t;

    //ALU DECODER OP CODES
    typedef enum logic [1:0] {
        ALU_OP_LOAD_STORE     = 2'b00,
        ALU_OP_BRANCHES       = 2'b01,
        ALU_OP_MATH           = 2'b10
    } alu_op_t;

    //R and I-type ALU funct3 codes
    typedef enum logic [2:0] {
        FUNC3_ADD_SUB         = 3'b000,
        FUNC3_SLL             = 3'b001,
        FUNC3_SLT             = 3'b010,
        FUNC3_SLTU            = 3'b011,
        FUNC3_XOR             = 3'b100,
        FUNC3_SRL_SRA         = 3'b101,
        FUNC3_OR              = 3'b110,
        FUNC3_AND             = 3'b111
    } funct3_t;

    //Branch funct3 codes
    typedef enum logic [2:0] {
        FUNC3_BEQ             = 3'b000,
        FUNC3_BNE             = 3'b001,
        FUNC3_BLT             = 3'b100,
        FUNC3_BGE             = 3'b101,
        FUNC3_BLTU            = 3'b110,
        FUNC3_BGEU            = 3'b111
    } branch_funct3_t;

    //Load/Store funct3 codes
    typedef enum logic [2:0] {
        FUNC3_WORD            = 3'b010,
        FUNC3_BYTE            = 3'b000,
        FUNC3_BYTE_U          = 3'b100,
        FUNC3_HALFWORD        = 3'b001,
        FUNC3_HALFWORD_U      = 3'b101
    } mem_funct3_t;

    //Shift funct7 codes
    typedef enum logic [6:0] {
        FUNC7_SLL_SRL         = 7'b0000000,
        FUNC7_SRA             = 7'b0100000
    } shifts_funct7_t;

    //R-type funct7 codes
    typedef enum logic [6:0] {
        FUNC7_ADD             = 7'b0000000,
        FUNC7_SUB             = 7'b0100000
    } rtype_funct7_t;

    //ALU CONTROL SIGNALS
    typedef enum logic [3:0] {
        ALU_ADD               = 4'b0000,
        ALU_SUB               = 4'b0001,
        ALU_AND               = 4'b0010,
        ALU_OR                = 4'b0011,
        ALU_SLL               = 4'b0100,
        ALU_SLT               = 4'b0101,
        ALU_SRL               = 4'b0110,
        ALU_SLTU              = 4'b0111,
        ALU_XOR               = 4'b1000,
        ALU_SRA               = 4'b1001
    } alu_control_t;

    //IMMEDIATE GENERATOR SOURCES
    typedef enum logic [2:0] {
        IMM_I_TYPE            = 3'b000,
        IMM_S_TYPE            = 3'b001,
        IMM_B_TYPE            = 3'b010,
        IMM_J_TYPE            = 3'b011,
        IMM_U_TYPE            = 3'b100
    } imm_source_t;
    
endpackage