module pipeexe(ealuc, ealuimm, ea, eb, eimm, eshift, ern0, epc4, ejal, ern, ealu);
    input        ealuimm, eshift, ejal;
    input  [3:0] ealuc;
    input  [4:0] ern0;
    input [31:0] ea, eb, eimm, epc4;

    output  [4:0] ern;
    output [31:0] ealu;

    assign ern = ern0 | {5{ejal}};

    wire [31:0] epc8;
    assign epc8 = epc4 + 4;

    wire [31:0] sa;
    assign sa = {27'b0, eimm[10:6]};// {eimm[5:0], eimm[31:6]};

    wire [31:0] alua, alub, ealu0;
    wire z;
    mux2x32 alu_a(ea, sa, eshift, alua);
    mux2x32 alu_b(eb, eimm, ealuimm, alub);
    alu alu_xixi(alua, alub, ealuc, ealu0, z);

    mux2x32 result(ealu0, epc8, ejal, ealu);
endmodule // pipeexe

module alu(a, b, aluc, s, z);
    input [31:0] a,b;
    input  [3:0] aluc;

    output reg [31:0] s;
    output reg        z;

    always @ (a or b or aluc) begin
        casex (aluc)
            4'bx000: s = a + b;              //x000 ADD
            4'bx100: s = a - b;              //x100 SUB
            4'bx001: s = a & b;              //x001 AND
            4'bx101: s = a | b;              //x101 OR
            4'bx010: s = a ^ b;              //x010 XOR
            4'bx110: s = a << 16;            //x110 LUI: imm << 16bit
            4'b0011: s = b << a;             //0011 SLL: rd <- (rt << sa)
            4'b0111: s = b >> a;             //0111 SRL: rd <- (rt >> sa) (logical)
            4'b1111: s = $signed(b) >>> a;   //1111 SRA: rd <- (rt >> sa) (arithmetic)
            default: s = 0;
        endcase

        if (s == 0) begin
            z = 1;
        end else begin
            z = 0;
        end
    end
endmodule
