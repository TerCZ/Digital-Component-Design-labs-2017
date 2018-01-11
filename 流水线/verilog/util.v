module mux2x32 (a0, a1, s, y);
    input [31:0] a0,a1;
    input        s;

    output [31:0] y;

    assign y = s ? a1 : a0;
endmodule

module mux4x32 (a0, a1, a2, a3, s, y);
    input [31:0] a0, a1, a2, a3;
    input  [1:0] s;

    output reg [31:0] y;

    always @ ( * ) begin
        case (s)
            2'b00: y = a0;
            2'b01: y = a1;
            2'b10: y = a2;
            2'b11: y = a3;
        endcase
    end
endmodule
