// IF/ID 流水线寄存器
module pipeir(pc4, ins, wpcir, clock, resetn, dpc4, inst);
    input        clock, resetn, wpcir;
    input [31:0] pc4, ins;

    output reg [31:0] dpc4, inst;

    always @ (posedge clock or negedge resetn)
        if (resetn == 0) begin
            dpc4 = 0;
            inst = 0;
        end else if (wpcir == 1) begin
            dpc4 = pc4;
            inst = ins;
    end
endmodule // pipeir
