`define clk_freq 25000000
`define player_move_interval (`clk_freq / 100)
`define screen_h 480
`define screen_w 640
`define core_size 15

module game (clk, reset_n, up_n, down_n, left_n, right_n,
             out_r, out_g, out_b, sync_h, sync_v, blank_n, scores);

    input clk, reset_n, up_n, down_n, left_n, right_n;

    output        sync_h, sync_v, blank_n;
    output  [7:0] out_r, out_g, out_b;
    output [19:0] scores;

    // controls
    wire [9:0] player_r, player_c, target_r, target_c, ghost_r, ghost_c;
    wire player_face_left, ghost_face_left;
    wire touch_target, game_over;

    player_control player_control_inst (clk, reset_n, game_over, up_n, down_n, left_n, right_n,
                                        player_r, player_c, player_face_left);
    target_control target_control_inst (clk, reset_n, game_over, touch_target, target_r, target_c, scores);
    ghost_control ghost_control_inst (clk, reset_n, game_over, scores, player_r, player_c, ghost_r, ghost_c, ghost_face_left);

    collision_detect detect_targt (player_r, player_c, target_r, target_c, touch_target);
    collision_detect detect_ghost (player_r, player_c, ghost_r, ghost_c, game_over);

    // display
    wire [9:0] row_i, col_i;  // the pixel data to be sent
    wire [1:0] at;
    wire is_player, is_target, is_ghost;  // whether this pixel is special
    wire [7:0] player_img_r, player_img_g, player_img_b,
               target_img_r, target_img_g, target_img_b,
               ghost_img_r, ghost_img_g, ghost_img_b,
               bg_img_r, bg_img_g, bg_img_b;

    assign at[0] = is_player | is_ghost;
    assign at[1] = is_target | is_ghost;

    vga_gen vga_gen_inst(clk, reset_n, row_i, col_i, sync_h, sync_v, blank_n);
    player_img player_img_inst(clk, row_i, col_i, player_r, player_c, player_face_left, is_player,
                               player_img_r, player_img_g, player_img_b);
    target_img target_img_inst(clk, row_i, col_i, target_r, target_c, is_target, target_img_r, target_img_g, target_img_b);
    ghost_img ghost_img_inst(clk, row_i, col_i, ghost_r, ghost_c, ghost_face_left, is_ghost,
                             ghost_img_r, ghost_img_g, ghost_img_b);
    bg_img bg_img_inst(clk, game_over, row_i, col_i, bg_img_r, bg_img_g, bg_img_b);

    // 0=background, 1=player, 2=target, 3=ghost
    mux4x8 color_r (bg_img_r, player_img_r, target_img_r, ghost_img_r, at, out_r);
    mux4x8 color_g (bg_img_g, player_img_g, target_img_g, ghost_img_g, at, out_g);
    mux4x8 color_b (bg_img_b, player_img_b, target_img_b, ghost_img_b, at, out_b);
endmodule // game

module collision_detect (p1_r, p1_c, p2_r, p2_c, collided);
    input [9:0] p1_r, p1_c, p2_r, p2_c;
    output collided;
    assign collided = (p1_r > p2_r ? p1_r - p2_r < `core_size : p2_r - p1_r < `core_size) &&
                      (p1_c > p2_c ? p1_c - p2_c < `core_size : p2_c - p1_c < `core_size);
endmodule

module random_pixel_1 (clk, reset_n, row_i, col_i);
    input clk, reset_n;

    output reg [9:0] row_i, col_i;

    reg [19:0] latent;

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset
            latent = 20'd810275;
        end else begin  // or move elements and produce new target
            latent <= {latent[18:0], latent[19] ^ latent[0]};
            row_i <= 30 + (latent[9:0] % (`screen_h - 2 * 30));
            col_i <= 30 + (latent[19:10] % (`screen_w - 2 * 30));
        end
    end
endmodule

module random_pixel_2 (clk, reset_n, row_i, col_i);
    input clk, reset_n;

    output reg [9:0] row_i, col_i;

    reg [19:0] latent;

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset
            latent = 20'd772372;
        end else begin  // or move elements and produce new target
            latent <= {latent[18:0], latent[19] ^ latent[0]};
            row_i <= 30 + (latent[9:0] % (`screen_h - 2 * 30));
            col_i <= 30 + (latent[19:10] % (`screen_w - 2 * 30));
        end
    end
endmodule

module player_control (clk, reset_n, game_over, up_n, down_n, left_n, right_n, player_r, player_c, player_face_left);
    input clk, reset_n, game_over, up_n, down_n, left_n, right_n;

    output reg       player_face_left;
    output reg [9:0] player_r, player_c;  // center of player, player size is 9x9

    reg [31:0] clk_counter;

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset
            player_face_left <= 0;
            player_r <= `screen_h / 2;
            player_c <= `screen_w / 2;
            clk_counter <= 0;
        end else begin  // or move elements and produce new target
            if (!game_over) begin  // only response when game is on
                clk_counter <= clk_counter + 1;
                if (clk_counter >= `player_move_interval) begin
                    clk_counter <= 0;

                    // move player
                    if (up_n == 0 && player_r > `core_size / 2) begin
                        player_r <= player_r - 1;
                    end
                    if (down_n == 0 && player_r < `screen_h - `core_size / 2 - 1) begin
                        player_r <= player_r + 1;
                    end
                    if (left_n == 0 && player_c > `core_size / 2) begin
                        player_c <= player_c - 1;
                        player_face_left <= 1;
                    end
                    if (right_n == 0 && player_c < `screen_w - `core_size / 2 - 1) begin
                        player_c <= player_c + 1;
                        player_face_left <= 0;
                    end
                end
            end
        end
    end
endmodule // player_control

module target_control (clk, reset_n, game_over, touch_target, target_r, target_c, scores);
    input clk, reset_n, game_over, touch_target;

    output reg [9:0] target_r, target_c;  // center of target, target size is 9x9
    output reg [19:0] scores;

    wire [9:0] rand_r, rand_c;

    random_pixel_2 random_pixel_2_inst (clk, reset_n, rand_r, rand_c);

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset
            scores <= 0;
            target_r <= rand_r;
            target_c <= rand_c;
        end else begin  // or move elements and produce new target
            if (!game_over) begin  // only response when game is on
                // score
                if (touch_target) begin
                    scores <= scores + 1;
                    target_r <= rand_r;
                    target_c <= rand_c;
                end
            end
        end
    end
endmodule // target_control

module ghost_control (clk, reset_n, game_over, scores, player_r, player_c, ghost_r, ghost_c, ghost_face_left);
    input       clk, reset_n, game_over;
    input [9:0] player_r, player_c;
    input [19:0] scores;

    output reg       ghost_face_left;
    output reg [9:0] ghost_r, ghost_c;  // center of ghost, ghost size is 9x9

    reg [31:0] clk_counter_4_ghost, clk_counter_4_time, time_elapsed;
    wire [9:0] rand_r, rand_c;
    wire [15:0] sqrt_of_scores;
    wire [31:0] unlimited = `clk_freq / (32'd10 + 32'd11 * sqrt_of_scores);
    wire [31:0] limit = `player_move_interval / 1.4;
    wire [31:0] move_interval = unlimited > limit ? unlimited : limit;

    random_pixel_1 random_pixel_1_inst (clk, reset_n, rand_r, rand_c);
    sqrt sqrt_inst({12'd0, scores}, sqrt_of_scores, remainder);

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset
            ghost_r <= rand_r;
            ghost_c <= rand_c;
            ghost_face_left <= 0;

            clk_counter_4_ghost <= 0;
            clk_counter_4_time <= 0;
            time_elapsed <= 0;
        end else begin  // or move elements and produce new target
            if (!game_over) begin  // only response when game is on
                clk_counter_4_time <= clk_counter_4_time + 1;
                if (clk_counter_4_time >= 31'd25000000) begin
                    clk_counter_4_time <= 0;
                    time_elapsed <= time_elapsed + 1;
                end

                clk_counter_4_ghost <= clk_counter_4_ghost + 1;
                if (clk_counter_4_ghost >= move_interval) begin
                    clk_counter_4_ghost <= 0;

                    // move player
                    if (ghost_r > player_r && ghost_r > `core_size / 2) begin
                        ghost_r <= ghost_r - 1;
                    end
                    if (ghost_r < player_r && ghost_r < `screen_h - `core_size / 2 - 1) begin
                        ghost_r <= ghost_r + 1;
                    end
                    if (ghost_c > player_c && ghost_c > `core_size / 2) begin
                        ghost_c <= ghost_c - 1;
                        ghost_face_left <= 1;
                    end
                    if (ghost_c < player_c && ghost_c < `screen_w - `core_size / 2 - 1) begin
                        ghost_c <= ghost_c + 1;
                        ghost_face_left <= 0;
                    end
                end
            end
        end
    end
endmodule // ghost_control

module vga_gen (clk, reset_n, row_i, col_i, sync_h, sync_v, blank_n);
    input clk, reset_n;

    output           sync_h, sync_v, blank_n;
    output reg [9:0] row_i, col_i;

    parameter integer visible_area_h = 640;
    parameter integer front_porch_h = 16;
    parameter integer sync_pulse_h = 96;
    parameter integer back_porch_h = 48;
    parameter integer whole_line_h = 800;

    parameter integer visible_area_v= 480;
    parameter integer front_porch_v= 10;
    parameter integer sync_pulse_v= 2;
    parameter integer back_porch_v= 33;
    parameter integer whole_line_v = 525;

    // sync/blank signals
    assign sync_v = ~(row_i >= visible_area_v + front_porch_v && row_i < visible_area_v + front_porch_v + sync_pulse_v);
    assign sync_h = ~(col_i >= visible_area_h + front_porch_h && col_i < visible_area_h + front_porch_h + sync_pulse_h);
    assign blank_n = row_i < visible_area_v && col_i < visible_area_h;

    always @ (posedge clk) begin
        if (reset_n == 0) begin  // reset_n is avtive-low
            row_i <= 0; col_i <= 0;
        end else begin // update output index
            col_i = col_i + 1;
            if (col_i == whole_line_h) begin  // begin new line
                col_i = 0;
                row_i = row_i + 1;
                if (row_i == whole_line_v) begin  // begin new frame
                    row_i = 0;
                end
            end
        end
    end
endmodule

module region_detect (pixel_r, pixel_c, target_r, target_c, in_region, rel_r, rel_c);
    input [9:0] pixel_r, pixel_c, target_r, target_c;

    output       in_region;
    output [3:0] rel_r, rel_c;

    assign in_region = (pixel_r > target_r ? pixel_r - target_r < `core_size / 2 + 1 : target_r - pixel_r < `core_size / 2 + 1) &&
                       (pixel_c > target_c ? pixel_c - target_c < `core_size / 2 + 1 : target_c - pixel_c < `core_size / 2 + 1);
    assign rel_r = pixel_r - target_r + `core_size / 2;
    assign rel_c = pixel_c - target_c + `core_size / 2;
endmodule

module player_img (clk, row_i, col_i, player_r, player_c, player_face_left, is_player, color_r, color_g, color_b);
    input       clk, player_face_left;
    input [9:0] row_i, col_i, player_r, player_c;

    output       is_player;
    output [7:0] color_r, color_g, color_b;

    wire [3:0] rel_r, rel_c;
    wire [3:0] rel_c_rev = `core_size - 1 - rel_c;

    wire [7:0] index = player_face_left ? rel_r * `core_size + rel_c_rev : rel_r * `core_size + rel_c;

    region_detect player_detect(row_i, col_i, player_r, player_c, is_player, rel_r, rel_c);
    player_img_rom img_mem (index, ~clk, {color_r, color_g, color_b});
endmodule

module target_img (clk, row_i, col_i, target_r, target_c, is_target, color_r, color_g, color_b);
    input       clk;
    input [9:0] row_i, col_i, target_r, target_c;

    output       is_target;
    output [7:0] color_r, color_g, color_b;

    wire [3:0] rel_r, rel_c;
    wire [7:0] index = rel_r * `core_size + rel_c;
    region_detect target_detect(row_i, col_i, target_r, target_c, is_target, rel_r, rel_c);
    target_img_rom img_mem (index, ~clk, {color_r, color_g, color_b});
endmodule

module ghost_img (clk, row_i, col_i, ghost_r, ghost_c, ghost_face_left, is_ghost, color_r, color_g, color_b);
    input       clk, ghost_face_left;
    input [9:0] row_i, col_i, ghost_r, ghost_c;

    output       is_ghost;
    output [7:0] color_r, color_g, color_b;

    wire [3:0] rel_r, rel_c;
    wire [3:0] rel_c_rev = `core_size - 1 - rel_c;
    wire [7:0] index = ghost_face_left ? rel_r * `core_size + rel_c_rev : rel_r * `core_size + rel_c;
    region_detect ghost_detect(row_i, col_i, ghost_r, ghost_c, is_ghost, rel_r, rel_c);
    ghost_img_rom img_mem (index, ~clk, {color_r, color_g, color_b});
endmodule

module bg_img (clk, game_over, row_i, col_i, color_r, color_g, color_b);
    input       clk, game_over;
    input [9:0] row_i, col_i;

    output [7:0] color_r, color_g, color_b;

    parameter integer bg_pattern_size = 100;
    parameter integer over_pattern_size = 151;

    wire [6:0] bg_row = row_i % bg_pattern_size;
    wire [6:0] bg_col = col_i % bg_pattern_size;
    wire [13:0] bg_index = bg_row * bg_pattern_size + bg_col;

    wire overwrite = game_over &
                     (row_i > `screen_h / 2 ? row_i - `screen_h / 2 < over_pattern_size / 2 + 1 : `screen_h / 2 - row_i < over_pattern_size / 2 + 1) &&
                     (col_i > `screen_w / 2 ? col_i - `screen_w / 2 < over_pattern_size / 2 + 1 : `screen_w / 2 - col_i < over_pattern_size / 2 + 1);
    wire [7:0] over_row = row_i - `screen_h / 2 + over_pattern_size / 2;
    wire [7:0] over_col = col_i - `screen_w / 2 + over_pattern_size / 2;
    wire [14:0] over_index = over_row * over_pattern_size + over_col;

    wire [7:0] bg_r, bg_g, bg_b, over_r, over_g, over_b;

    assign color_r = overwrite ? over_r : bg_r;
    assign color_g = overwrite ? over_g : bg_g;
    assign color_b = overwrite ? over_b : bg_b;

    bg_img_rom bg_img_rom_inst (bg_index, ~clk, {bg_r, bg_g, bg_b});
    game_over_img_rom game_over_img_rom_inst (over_index, ~clk, {over_r, over_g, over_b});
endmodule // bg_img

module mux4x8 (src_0, src_1, src_2, src_3, s, y);
    input [7:0] src_0, src_1, src_2, src_3;
    input [1:0] s;

    output reg [7:0] y;

    always @ ( * ) begin
        case (s)
            2'b00: y = src_0;
            2'b01: y = src_1;
            2'b10: y = src_2;
            2'b11: y = src_3;
        endcase
    end
endmodule // mux4x8
