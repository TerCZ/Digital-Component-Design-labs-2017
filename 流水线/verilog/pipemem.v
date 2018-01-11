module pipemem(write_enable, addr, datain, clock, mem_clock, dataout, io_in, io_out);
    input        clock, mem_clock, write_enable;
    input [12:0] io_in;
    input [31:0] addr, datain;

    output [31:0] dataout;
    output [44:0] io_out;

    wire        mem_write_enable, io_write_enable;
    wire [31:0] mem_dataout, io_dataout;

    assign mem_write_enable = write_enable & mem_clock & ~addr[7];
    assign io_write_enable  = write_enable & mem_clock &  addr[7];

    datamem dataram(addr[6:2], mem_clock, datain, mem_write_enable, mem_dataout);
    simple_io io(addr[6:2], mem_clock, datain, io_write_enable, io_dataout, io_in, io_out);

    assign dataout = addr[7] ? io_dataout : mem_dataout;
endmodule // pipemem

module simple_io (addr, clock, datain, write_enable, dataout, io_in, io_out);
    input        clock, write_enable;
    input [4:0]  addr;
    input [31:0] datain;
    input [12:0] io_in;

    output reg [31:0] dataout;
    output reg [44:0] io_out;

    reg  [1:0] operator;

    wire [2:0] buttons;
    assign buttons = io_in[12:10];

    wire [13:0] leds;
    sevenseg led0(datain[3:0], leds[6:0]);
    sevenseg led1(datain[7:4], leds[13:7]);

    always @ (posedge clock) begin
        io_out[44] = operator == 2'b10;
        io_out[43] = operator == 2'b01;
        io_out[42] = operator == 2'b00;

        // change operator
        if (buttons[0] == 0)
            operator = 2'b00;
        else if (buttons[1] == 0)
            operator = 2'b01;
        else if (buttons[2] == 0)
            operator = 2'b10;

        if (write_enable) begin
            case (addr)
                0: io_out[41:28] = leds;   // led hex4, hex5
                1: io_out[27:14] = leds;   // led hex2, hex3
                2: io_out[13:0] = leds;    // led hex0, hex1
                default: io_out = 0;       // all segs on
            endcase
        end

        case (addr)
            3: dataout = {27'b0, io_in[9:5]};    // switch 5-9
            4: dataout = {27'b0, io_in[4:0]};    // switch 0-4
            5: dataout = {30'b0, operator};      // operator, button 1-3
            default: dataout = 0;
        endcase
    end
endmodule //simple_io

module sevenseg(data, ledsegments);
    input [3:0] data;
    output [6:0] ledsegments;
    reg [6:0] ledsegments;
    always @ ( * ) begin
        // gfe_dcba, 7 ? LED ????????
        // 654_3210, DE1-SOC ????????, DE1-SOC ?????????????
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
            10: ledsegments = 7'b000_1000;
            11: ledsegments = 7'b000_0011;
            12: ledsegments = 7'b100_0110;
            13: ledsegments = 7'b010_0001;
            14: ledsegments = 7'b000_0110;
            15: ledsegments = 7'b000_1110;
            default: ledsegments = 7'b111_1111;  // 其它值时全灭。
        endcase
    end
endmodule
