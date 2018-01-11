module scores_to_hex (scores, hex0, hex1, hex2, hex3, hex4, hex5);
    input [19:0] scores;
    output [6:0] hex0, hex1, hex2, hex3, hex4, hex5;

    wire [3:0] num0, num1, num2, num3, num4, num5;
    assign num0 = scores % 10;
    assign num1 = (scores / 10) % 10;
    assign num2 = (scores / 100) % 10;
    assign num3 = (scores / 1000) % 10;
    assign num4 = (scores / 10000) % 10;
    assign num5 = (scores / 100000) % 10;
    sevenseg sevenseg_inst0(num0, hex0);
    sevenseg sevenseg_inst1(num1, hex1);
    sevenseg sevenseg_inst2(num2, hex2);
    sevenseg sevenseg_inst3(num3, hex3);
    sevenseg sevenseg_inst4(num4, hex4);
    sevenseg sevenseg_inst5(num5, hex5);

endmodule // scores_to_hex

module sevenseg(data, ledsegments);
    input [3:0] data;
    output [6:0] ledsegments;
    reg [6:0] ledsegments;
    always @ ( * )
        // gfe_dcba, 7 段 LED 数码管的位段编号
        // 654_3210, DE1-SOC 板上的信号位编号, DE1-SOC 板上的数码管为共阳极接法。
        case(data)
            0: ledsegments = 7'b100_0000;
            1: ledsegments = 7'b111_1001;
            2: ledsegments = 7'b010_0100;
            3: ledsegments = 7'b011_0000;
            4: ledsegments = 7'b001_1001;
            5: ledsegments = 7'b001_0010;
            6: ledsegments = 7'b000_0010;
            7: ledsegments = 7'b111_1000;
            8: ledsegments = 7'b000_0000;
            9: ledsegments = 7'b001_0000;
            default: ledsegments = 7'b111_1111;  // 其它值时全灭。
        endcase
endmodule  // stopwatch
