module simple_io (addr, clock, data_in, write_enable, data_out, io_bus_in, io_bus_out);
    input [3:0]  addr;
	 input [31:0] data_in;
	 input        clock, write_enable;
	 input [12:0]  io_bus_in;
    output reg [31:0] data_out;
	 output reg [44:0] io_bus_out;

	 wire [2:0] buttons;
	 reg  [1:0] operator;
	 assign buttons = io_bus_in[12:10];
	 
    wire [13:0] leds;
    sevenseg led0(data_in[3:0], leds[6:0]);
	 sevenseg led1(data_in[7:4], leds[13:7]);
	 
    always @ (posedge clock) begin
        io_bus_out[44] = operator == 2'b10;
		  io_bus_out[43] = operator == 2'b01;
		  io_bus_out[42] = operator == 2'b00;
		  
		  // change operator
		  if (!buttons[0])
				operator = 2'b00;
		  else if (!buttons[1])
				operator = 2'b01;
		  else if (!buttons[2])
				operator = 2'b10;
		  
		  if (write_enable) begin
            case (addr)
                0: io_bus_out[13:0] = leds;     // led hex0, hex1
                1: io_bus_out[27:14] = leds;   // led hex2, hex3
                2: io_bus_out[41:28] = leds;   // led hex4, hex5
                default: io_bus_out = 0;  // all segs on
            endcase
        end

        case (addr)
            3: data_out = {27'b0, io_bus_in[4:0]};    // switch 0-4
            4: data_out = {27'b0, io_bus_in[9:5]};    // switch 5-9
            5: data_out = {30'b0, operator};          // operator
				default: data_out = 0;
        endcase
    end
endmodule //simple_ i_addr, data_in, write_enable, sdata_out
