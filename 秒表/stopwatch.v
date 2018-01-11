module stopwatch(clk, key_reset, key_start_pause, key_display_stop,
                    hex0, hex1, hex2, hex3, hex4, hex5,
                    led0, led1, led2);
input        clk;  // 50 MHz clock
input        key_reset, key_start_pause, key_display_stop;  // buttons, 0 when pressed
output [6:0] hex0, hex1, hex2, hex3, hex4, hex5;  // digit display
output       led0, led1, led2;  // leds, on when 1

reg led0, led1, led2;
reg displaying;  // whether to update digits displayed
reg timing;  // whether timer is working

// digits to be displayed
reg [3:0] minute_display_high;
reg [3:0] minute_display_low;
reg [3:0] second_display_high;
reg [3:0] second_display_low;
reg [3:0] msecond_display_high;
reg [3:0] msecond_display_low;

// digits to record time
reg [3:0] minute_counter_high;
reg [3:0] minute_counter_low;
reg [3:0] second_counter_high;
reg [3:0] second_counter_low;
reg [3:0] msecond_counter_high;
reg [3:0] msecond_counter_low;

// from bianry digit to 7-seg display
sevenseg LED8_minute_display_high(minute_display_high, hex0);
sevenseg LED8_minute_display_low(minute_display_low, hex1);
sevenseg LED8_second_display_high(second_display_high, hex2);
sevenseg LED8_second_display_low(second_display_low, hex3);
sevenseg LED8_msecond_display_high(msecond_display_high, hex4);
sevenseg LED8_msecond_display_low(msecond_display_low, hex5);

// clock counter, increment every cycle, set to 0 when equals 500000 (10 ms has passed)
reg [31:0] clk_counter;

// eliminate vibration
reg reset_state;  // current state of the key
reg start_state;
reg display_state;
reg [8:0] counter_reset;  // how many cycles has the key been in a different state
reg [8:0] counter_start;  // the state gets fliped when counter is all '1's
reg [8:0] counter_display;

// let led indicate the real button signals
always @ (key_reset) begin
    led0 = key_reset;
end

always @ (key_start_pause) begin
    led1 = key_start_pause;
end

always @ (key_display_stop) begin
    led2 = key_display_stop;
end

// actual logic of stopwatch
always @ (posedge clk) begin
    if (clk) begin
        // eliminate vibration of key
        if (reset_state && !key_reset) begin  // state is about to change
            counter_reset = counter_reset + 1;
            if (counter_reset == 8'b11111111) begin  // signal has been in new state for long enough time
                counter_reset = 0;  // clear counter
                reset_state = ~reset_state;  // flip the state

                // reset stopwatch by setting all counters to 0
                minute_counter_high = 0;
                minute_counter_low = 0;
                second_counter_high = 0;
                second_counter_low = 0;
                msecond_counter_high = 0;
                msecond_counter_low = 0;
            end
        end else if (!reset_state && key_reset) begin
            counter_reset = counter_reset + 1;
            if (counter_reset == 8'b11111111) begin
                counter_reset = 0;
                reset_state = ~reset_state;
            end
        end else begin
            counter_reset = 0;  // in case of noise
        end

        if (start_state && !key_start_pause) begin
            counter_start = counter_start + 1;
            if (counter_start == 8'b11111111) begin
                counter_start = 0;
                start_state = ~start_state;
            end
        end else if (!start_state && key_start_pause) begin
            counter_start = counter_start + 1;
            if (counter_start == 8'b11111111) begin
                counter_start = 0;
                start_state = ~start_state;

                timing = !timing;
            end
        end else begin
            counter_start = 0;
        end

        if (display_state && !key_display_stop) begin
            counter_display = counter_display + 1;
            if (counter_display == 8'b11111111) begin
                counter_display = 0;
                display_state = ~display_state;
            end
        end else if (!display_state && key_display_stop) begin
            counter_display = counter_display + 1;
            if (counter_display == 8'b11111111) begin
                counter_display = 0;
                display_state = ~display_state;

                displaying = !displaying;
            end
        end else begin
            counter_display = 0;
        end

        // update display, if needed
        if (displaying) begin
            minute_display_high = minute_counter_high;
            minute_display_low = minute_counter_low;
            second_display_high = second_counter_high;
            second_display_low = second_counter_low;
            msecond_display_high = msecond_counter_high;
            msecond_display_low = msecond_counter_low;
        end

        // update clock counter, if needed
        if (timing) begin
            clk_counter = clk_counter + 1;

            // when 10 ms has passed, cascade update the counters
            if (clk_counter == 500000) begin
                clk_counter = 0;
                msecond_counter_low = msecond_counter_low + 1;

                if (msecond_counter_low == 10) begin
                    msecond_counter_low = 0;
                    msecond_counter_high = msecond_counter_high + 1;

                    if (msecond_counter_high == 10) begin
                        msecond_counter_high = 0;
                        second_counter_low = second_counter_low + 1;

                        if (second_counter_low == 10) begin
                            second_counter_low = 0;
                            second_counter_high = second_counter_high + 1;

                            if (second_counter_high == 6) begin
                                second_counter_high = 0;
                                minute_counter_low = minute_counter_low + 1;

                                if (minute_counter_low == 10) begin
                                    minute_counter_low = 0;
                                    minute_counter_high = minute_counter_high + 1;

                                    if (minute_counter_high == 10) begin
                                        minute_counter_high = 0;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
endmodule

// 4bit 的 BCD 码至 7 段 LED 数码管译码器模块
// 可供实例化共 6 个显示译码模块
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
