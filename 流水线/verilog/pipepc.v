// 程序计数器模块，是最前面一级 IF 流水段的输入。
module pipepc(npc, wpcir, clock, resetn, pc);
    input        clock, resetn, wpcir;
    input [31:0] npc;

    output reg [31:0] pc;

    always @ (posedge clock or negedge resetn)
        if (resetn == 0) begin
            pc = 0;
        end else if (wpcir == 1) begin
            pc = npc;
    end
endmodule // pipepc
