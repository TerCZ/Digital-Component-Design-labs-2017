// ID stage
module pipeid(mwreg, mrn, ern, ewreg, em2reg, mm2reg, dpc4, inst,
              wrn, wdi, ealu, malu, mmo, wwreg, clock, resetn,
              bpc, jpc, pcsource, wpcir, dwreg, dm2reg, dwmem, daluc,
              daluimm, da, db, dimm, drn, dshift, djal);

    input        clock, resetn, em2reg, ewreg, mm2reg, mwreg, wwreg;
    input  [4:0] ern, mrn, wrn;
    input [31:0] dpc4, inst, ealu, malu, mmo, wdi;

    output        wpcir, dwreg, dm2reg, dwmem, daluimm, dshift, djal;
    output  [1:0] pcsource;
    output  [3:0] daluc;
    output  [4:0] drn;
    output [31:0] bpc, jpc, da, db, dimm;

    wire [5:0] op, func;
    assign func = inst[5:0];
    assign op = inst[31:26];

    wire [4:0] rs, rt, rd;
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];

    assign jpc = {dpc4[31:28], inst[25:0], 2'b00};

    wire [31:0] qa, qb;
    wire [1:0] fwda, fwdb;
    wire regrt;

    wire sext, rsrtequ;
    pipecu cu(mwreg, mrn, ern, ewreg, em2reg, mm2reg, rsrtequ, func, op, rs, rt, dwreg, dm2reg, dwmem, daluc,
              regrt, daluimm, fwda, fwdb, wpcir, sext, pcsource, dshift, djal);
    regfile rf(rs, rt, wdi, wrn, wwreg, ~clock, resetn, qa, qb);
    mux2x5 des_reg_no (rd, rt, regrt, drn);
    mux4x32 alu_a(qa, ealu, malu, mmo, fwda, da);
    mux4x32 alu_b(qb, ealu, malu, mmo, fwdb, db);

    wire [31:0] br_offset;
    wire [15:0] ext16;
    wire e;
    assign rsrtequ = da == db;
    assign e = sext & inst[15];
    assign ext16 = {16{e}};
    assign dimm = {ext16, inst[15:0]};
    assign br_offset = {dimm[29:0], 2'b00};
    assign bpc = dpc4 + br_offset;
endmodule // pipeid

module mux2x5(a0, a1, s, y);
    input [4:0] a0,a1;
    input       s;

    output [4:0] y;

    assign y = s ? a1 : a0;
endmodule

module pipecu(mwreg, mrn, ern, ewreg, em2reg, mm2reg, rsrtequ, func, op, rs, rt, dwreg, dm2reg, dwmem, daluc,
              regrt, daluimm, fwda, fwdb, wpcir, sext, pcsource, dshift, djal);
    input       mwreg, ewreg, em2reg, mm2reg, rsrtequ;
    input [4:0] mrn, ern, rs, rt;
    input [5:0] func, op;

    output           dwreg, dm2reg, dwmem, regrt, daluimm, sext, dshift, djal, wpcir;
    output     [1:0] pcsource;
    output reg [1:0] fwda, fwdb;
    output     [3:0] daluc;

    wire r_type = ~|op;
    wire i_add = r_type &  func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];          //100000
    wire i_sub = r_type &  func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] & ~func[0];          //100010
    wire i_and = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] & ~func[1] & ~func[0];          //100100
    wire i_or  = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] & ~func[1] &  func[0];          //100101
    wire i_xor = r_type &  func[5] & ~func[4] & ~func[3] &  func[2] &  func[1] & ~func[0];          //100110
    wire i_sll = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] & ~func[1] & ~func[0];          //000000
    wire i_srl = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] & ~func[0];          //000010
    wire i_sra = r_type & ~func[5] & ~func[4] & ~func[3] & ~func[2] &  func[1] &  func[0];          //000011
    wire i_jr  = r_type & ~func[5] & ~func[4] &  func[3] & ~func[2] & ~func[1] & ~func[0];          //001000

    wire i_addi = ~op[5] & ~op[4] &  op[3] & ~op[2] & ~op[1] & ~op[0]; //001000
    wire i_andi = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] & ~op[0]; //001100
    wire i_ori  = ~op[5] & ~op[4] &  op[3] &  op[2] & ~op[1] &  op[0]; //001101
    wire i_xori = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] & ~op[0]; //001110
    wire i_lw   =  op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //100011
    wire i_sw   =  op[5] & ~op[4] &  op[3] & ~op[2] &  op[1] &  op[0]; //101011
    wire i_beq  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] & ~op[0]; //000100
    wire i_bne  = ~op[5] & ~op[4] & ~op[3] &  op[2] & ~op[1] &  op[0]; //000101
    wire i_lui  = ~op[5] & ~op[4] &  op[3] &  op[2] &  op[1] &  op[0]; //001111

    wire i_j    = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] & ~op[0]; //000010
    wire i_jal  = ~op[5] & ~op[4] & ~op[3] & ~op[2] &  op[1] &  op[0]; //000011

    wire i_rs = i_add | i_sub | i_and | i_or | i_xor | i_jr | i_addi | i_andi | i_ori | i_xori |
                i_lw | i_sw | i_beq | i_bne;
    wire i_rt = i_add | i_sub | i_and | i_or | i_xor | i_sll | i_srl | i_sra | i_sw | i_beq | i_bne;

    assign wpcir = (~(ewreg & em2reg & (ern != 0) & (i_rs & (ern == rs) | i_rt & (ern == rt))));

    always @ (ewreg or mwreg or ern or mrn or em2reg or mm2reg or rs or rt) begin
        fwda = 2'b00;
        fwdb = 2'b00;

        if (ewreg & (ern != 0) & (ern == rs) & ~em2reg) begin
            fwda = 2'b01;
        end else if (mwreg & (mrn != 0) & (mrn == rs) & ~mm2reg) begin
            fwda = 2'b10;
        end else if (mwreg & (mrn != 0) & (mrn == rs) & mm2reg) begin
            fwda = 2'b11;
        end

        if (ewreg & (ern != 0) & (ern == rt) & ~em2reg) begin
            fwdb = 2'b01;
        end else if (mwreg & (mrn != 0) & (mrn == rt) & ~mm2reg) begin
            fwdb = 2'b10;
        end else if (mwreg & (mrn != 0) & (mrn == rt) & mm2reg) begin
            fwdb = 2'b11;
        end
    end

    assign pcsource[1] = i_jr | i_j | i_jal;
    assign pcsource[0] = (i_beq & rsrtequ) | (i_bne & ~rsrtequ) | i_j | i_jal ;

    wire i_wreg;
    assign i_wreg = i_add | i_sub | i_and | i_or   | i_xor  | i_sll | i_srl | i_sra | i_addi | i_andi | i_ori | i_xori | i_lw | i_lui  | i_jal;
    assign dwreg = i_wreg & wpcir;
    assign dwmem = i_sw & wpcir;

    assign daluc[3] = i_sra;
    assign daluc[2] = i_sub | i_or | i_srl | i_sra | i_ori | i_lui | i_beq | i_bne;
    assign daluc[1] = i_xor | i_sll | i_srl | i_sra | i_xori | i_lui;
    assign daluc[0] = i_or | i_sll | i_srl | i_sra | i_ori | i_and | i_andi;
    assign dshift   = i_sll | i_srl | i_sra ;

    assign daluimm  = i_addi | i_andi | i_ori | i_xori | i_lw | i_sw | i_lui;
    assign sext     = i_addi | i_lw | i_sw | i_beq | i_bne;
    assign dm2reg   = i_lw;
    assign regrt    = i_addi | i_andi | i_ori | i_xori | i_lw | i_lui;
    assign djal     = i_jal;
endmodule // pipecu
