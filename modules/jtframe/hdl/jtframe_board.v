/*  This file is part of JTFRAME.
    JTFRAME program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTFRAME program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTFRAME.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 25-9-2019 */

module jtframe_board #(parameter
    BUTTONS                 = 2, // the location of coin, 1P and pause will be set after these buttons
    // coin and start buttons will be mapped.
    GAME_INPUTS_ACTIVE_LOW  = 1'b1,
    COLORW                  = 4,
    SDRAMW                  = 22,
    VIDEO_WIDTH             = 384,
    VIDEO_HEIGHT            = 224,
    MISTER                  = 1,
    XOR_ROT                 = 0
)(
    output              rst,
    output              rst_n,
    output              game_rst,
    output              game_rst_n,
    output              sdram_init,
    // reset forcing signals:
    input               rst_req,
    input               pll_locked,

    input               clk_sys,
    input               clk_rom,
    input               clk_pico,

    input        [ 6:0] core_mod,
    // LED
    input               osd_shown,
    output              led,
    // Audio
    input  signed [15:0] snd_lin,  snd_rin,
    output signed [15:0] snd_lout, snd_rout,
    output        [ 7:0] snd_vol,
    input                snd_sample,
    input                snd_peak,
    // ROM access from game
    input  [SDRAMW-1:0] ba0_addr,ba1_addr,ba2_addr,ba3_addr,
    input         [3:0] ba_rd,   ba_wr,
    output        [3:0] ba_ack,  ba_rdy,  ba_dst,  ba_dok,
    input        [15:0] ba0_din, ba1_din, ba2_din, ba3_din,
    input        [ 1:0] ba0_dsn, ba1_dsn, ba2_dsn, ba3_dsn, // write mask

    output       [15:0] sdram_dout,
    // ROM programming
    input  [SDRAMW-1:0] prog_addr,
    input        [15:0] prog_data,
    input        [ 1:0] prog_dsn, prog_ba,
    input               prog_we,
    input               prog_rd,
    output              prog_dok,
    output              prog_rdy,
    output              prog_dst,
    output              prog_ack,
    input               ioctl_cart,
    input               dwnld_busy,
    input               ioctl_ram,
    // SDRAM interface
    inout    [15:0]     SDRAM_DQ,       // SDRAM Data bus 16 Bits
    output   [12:0]     SDRAM_A,        // SDRAM Address bus 13 Bits
    output              SDRAM_DQML,     // SDRAM Low-byte Data Mask
    output              SDRAM_DQMH,     // SDRAM High-byte Data Mask
    output              SDRAM_nWE,      // SDRAM Write Enable
    output              SDRAM_nCAS,     // SDRAM Column Address Strobe
    output              SDRAM_nRAS,     // SDRAM Row Address Strobe
    output              SDRAM_nCS,      // SDRAM Chip Select
    output   [1:0]      SDRAM_BA,       // SDRAM Bank Address
    output              SDRAM_CKE,      // SDRAM Clock Enable
    // keyboard
    input               ps2_kbd_clk,
    input               ps2_kbd_data,
    // UART
    input               uart_rx,
    output              uart_tx,
    // joystick
    input        [15:0] board_joystick1, board_joystick2, board_joystick3, board_joystick4,
    input        [ 3:0] board_start,     board_coin,
    input        [15:0] joyana_l1,       joyana_r1,       joyana_l2,       joyana_r2,
    output       [ 9:0] game_joystick1,  game_joystick2,  game_joystick3,  game_joystick4,
    output       [ 3:0] game_coin,       game_start,
    output              game_service,
    output              game_tilt,
    // keyboard
    input        [ 7:0] board_digit,
    input               board_reset, board_pause, board_tilt, board_test,
                        board_service, board_shift, board_ctrl, board_alt,
    // debug features
    input        [ 3:0] board_gfx,
    input               board_plus, board_minus,
    // Mouse & Paddle
    input        [ 8:0] bd_mouse_dx, bd_mouse_dy,
    output       [15:0] mouse_1p,    mouse_2p,
    output       [ 1:0] mouse_strobe,
    input        [ 7:0] bd_mouse_f,       // flags
    input               bd_mouse_idx,
    input               bd_mouse_st,

    input        [ 7:0] board_paddle_1, board_paddle_2,
    input        [ 8:0] spinner_1,      spinner_2,
    output       [ 7:0] game_paddle_1, game_paddle_2,
    output       [ 1:0] dial_x, dial_y,

    // DIP and OSD settings
    input        [63:0] status,
    input        [23:0] dipsw,
    output       [12:0] hdmi_arx, hdmi_ary,
    output       [ 1:0] rotate,
    output              rot_osdonly,

    output              enable_fm,
    output              enable_psg,

    output              dip_test,
    // non standard:
    output              dip_pause,
    inout               dip_flip,     // A change in dip_flip implies a reset if JTFRAME_FLIP_RESET is defined
    output        [1:0] dip_fxlevel,
    // input data recording
    input        [ 7:0] ioctl_din,
    output       [ 7:0] ioctl_merged,
    // Base video
    input        [ 1:0] osd_rotate,
    input  [COLORW-1:0] game_r, game_g, game_b,
    input               LHBL,
    input               LVBL,
    input               hs,
    input               vs,
    inout               pxl2_cen, pxl_cen,
    // Base video after OSD and Debugger
    output [3*COLORW-1:0] base_rgb,
    output              base_lhbl,
    output              base_lvbl,

    // ROM ioctl_rom (cheat engine)
    input               prog_cheat,
    input               prog_lock,
    input               ioctl_wr,
    input         [7:0] ioctl_dout,
    input        [12:0] ioctl_addr,

    // Cheat Engine
    input        [31:0] cheat,
    output       [ 7:0] st_addr,
    input        [ 7:0] st_dout,
    input        [ 7:0] target_info,
    input        [31:0] timestamp,
    // GFX enable
    output        [3:0] gfx_en,
    output        [5:0] snd_en,
    input         [5:0] snd_vu,
    output        [7:0] debug_bus,
    input         [7:0] debug_view
);

`ifdef JTFRAME_BA0_AUTOPRECH
    localparam BA0_AUTOPRECH = `JTFRAME_BA0_AUTOPRECH;
`else
    localparam BA0_AUTOPRECH = 0;
`endif

`ifdef JTFRAME_BA1_AUTOPRECH
    localparam BA1_AUTOPRECH = `JTFRAME_BA1_AUTOPRECH;
`else
    localparam BA1_AUTOPRECH = 0;
`endif

`ifdef JTFRAME_BA2_AUTOPRECH
    localparam BA2_AUTOPRECH = `JTFRAME_BA2_AUTOPRECH;
`else
    localparam BA2_AUTOPRECH = 0;
`endif

`ifdef JTFRAME_BA3_AUTOPRECH
    localparam BA3_AUTOPRECH = `JTFRAME_BA3_AUTOPRECH;
`else
    localparam BA3_AUTOPRECH = 0;
`endif
    localparam SDRAM_SHIFT = `JTFRAME_SHIFT ^^ `JTFRAME_180SHIFT;

// sdram bank lengths
localparam
`ifdef JTFRAME_BA0_LEN
    BA0_LEN                 = `JTFRAME_BA0_LEN,
`else
    BA0_LEN                 = 32,
`endif

`ifdef JTFRAME_BA1_LEN
    BA1_LEN                 = `JTFRAME_BA1_LEN,
`else
    BA1_LEN                 = 32,
`endif

`ifdef JTFRAME_BA2_LEN
    BA2_LEN                 = `JTFRAME_BA2_LEN,
`else
    BA2_LEN                 = 32,
`endif

`ifdef JTFRAME_BA3_LEN
    BA3_LEN                 = `JTFRAME_BA3_LEN,
`else
    BA3_LEN                 = 32,
`endif
    PROG_LEN = 32;

wire         osd_pause;
wire         debug_plus, debug_minus, key_shift, key_ctrl, key_alt,
             vol_up,   vol_down;
wire         key_reset, key_pause, key_test, rot_control;
wire         game_pause, soft_rst, game_test;
wire         cheat_led, pre_pause;

wire   [9:0] key_joy1, key_joy2, key_joy3, key_joy4;
wire   [7:0] key_digit;
wire   [3:0] key_start, key_coin, key_gfx;
wire   [5:0] key_snd;
wire   [1:0] sensty, frame_blank;
wire         key_service, key_tilt;
wire         locked;
wire         autofire0, dial_raw_en, dial_reverse, snd_mode;

wire [COLORW-1:0] crdts_r, crdts_g, crdts_b,
                  dbg_r, dbg_g, dbg_b;

wire [ 3:0] bax_rd, bax_wr, bax_ack;
wire [15:0] bax_din;
wire [ 1:0] bax_dsn;
wire [ 3:0] bax_rdy, bax_dst;
wire [SDRAMW-1:0] bax_addr;

wire LHBLs;

assign autofire0 = `ifdef JTFRAME_AUTOFIRE0 status[18] `else 0 `endif;
assign sensty    = status[33:32]; // MiST should drive these pins
assign dial_raw_en  = core_mod[3];
assign dial_reverse = core_mod[4];
assign frame_blank  = core_mod[6:5];

assign base_rgb  = { dbg_r, dbg_g, dbg_b };

`ifdef JTFRAME_PXLCLK
    jtframe_pxlcen u_pxlcen(
        .clk        ( clk_rom   ),
        .pxl_cen    ( pxl_cen   ),
        .pxl2_cen   ( pxl2_cen  )
    );
`endif

reg rom_rst=0;

always @(posedge clk_rom) begin
    if(!dwnld_busy) rom_rst <= 0;
    else if(ioctl_wr&&!ioctl_cart) rom_rst <= 1;
end

jtframe_reset u_reset(
    .clk_sys    ( clk_sys       ),
    .clk_rom    ( clk_rom       ),
    .pxl_cen    ( pxl_cen       ),

    .sdram_init ( sdram_init    ),
    .ioctl_rom  ( rom_rst       ),
    .dip_flip   ( dip_flip      ),
    .soft_rst   ( soft_rst      ),
    .rst_req    ( rst_req       ),
    .pll_locked ( pll_locked    ),

    .rst        ( rst           ),
    .rst_n      ( rst_n         ),
    .game_rst   ( game_rst      ),
    .game_rst_n ( game_rst_n    )
);

wire       vu_peak;
wire [1:0] led_peak = { 1'b1, vu_peak | snd_peak };

jtframe_led u_led(
    .rst        ( rst           ),
    .clk        ( clk_sys       ),
    .LVBL       ( LVBL          ),
    .ioctl_rom  ( dwnld_busy    ),
    .osd_shown  ( osd_shown     ),
    .gfx_en     ( gfx_en        ),
    .game_led   ( led_peak      ),
    .cheat_led  ( cheat_led     ),
    .led        ( led           )
);

`ifdef JTFRAME_CREDITS
    wire invert_inputs = GAME_INPUTS_ACTIVE_LOW[0];
    wire toggle = |(game_start ^ {4{invert_inputs}});
    reg  fast_scroll, show_credits;
    wire hide_credits;


    assign hide_credits = `ifdef JTFRAME_CREDITS_HIDEVERT core_mod[0] `else 0 `endif ;

    always @(posedge clk_sys) begin
        fast_scroll  <= |({game_joystick1[3:0], game_joystick2[3:0]} ^ {8{invert_inputs}});
`ifndef JTFRAME_CREDITS_AON
        show_credits <= (locked | ~dip_pause) & ~hide_credits `ifdef MISTER & ~status[12] `endif;
`endif
    end

    // To do: HS and VS should actually be delayed inside jtframe_credits too
    jtframe_credits #(
        .PAGES  ( `JTFRAME_CREDITS_PAGES ),
        .COLW   ( COLORW                 ),
        .BLKPOL (      0                 ) // 0 for active low signals
    ) u_credits(
        .rst        ( rst           ),
        .clk        ( clk_sys       ),
        .pxl_cen    ( pxl_cen       ),

        // input image
        .HB         ( LHBLs         ),
        .VB         ( LVBL          ),
        .rgb_in     ( { game_r, game_g, game_b } ),
        `ifdef JTFRAME_CREDITS_NOROTATE
            .rotate ( 2'd0          ),
        `else
            .rotate ( locked ? 2'd0 : { rotate[1], core_mod[0] }  ),
        `endif
        .toggle     ( toggle        ),
        .fast_scroll( fast_scroll   ),

        `ifdef JTFRAME_CHEAT
            // Cheat CPU can control the video
            .vram_din   ( vram_dout  ),
            .vram_dout  ( vram_din   ),
            .vram_addr  ( vram_addr  ),
            .vram_we    ( vram_we    ),
            .vram_ctrl  ( vram_ctrl  ),
            .enable     ( vram_ctrl[0] | show_credits ),
        `else
            .vram_din   ( 8'h0  ),
            .vram_dout  (       ),
            .vram_addr  ( 8'h0  ),
            .vram_we    ( 1'b0  ),
            .vram_ctrl  ( 3'b0  ),
            `ifdef JTFRAME_CREDITS_AON
                .enable ( 1'b1          ),
            `else
                .enable ( show_credits  ),
            `endif
        `endif

        // output image
        .HB_out     ( base_lhbl      ),
        .VB_out     ( base_lvbl      ),
        .rgb_out    ( {crdts_r, crdts_g, crdts_b } )
    );
`else
    assign { crdts_r, crdts_g, crdts_b } = { game_r, game_g, game_b };
    assign { base_lhbl, base_lvbl    } = { LHBLs, LVBL };
`endif

`ifndef SIMULATION
jtframe_keyboard u_keyboard(
    .clk         ( clk_sys       ),
    .rst         ( rst           ),
    // ps2 interface
    .ps2_clk     ( ps2_kbd_clk   ),
    .ps2_data    ( ps2_kbd_data  ),
    // decoded keys
    .key_joy1    ( key_joy1      ),
    .key_joy2    ( key_joy2      ),
    .key_joy3    ( key_joy3      ),
    .key_joy4    ( key_joy4      ),
    .key_start   ( key_start     ),
    .key_coin    ( key_coin      ),
    .key_reset   ( key_reset     ),
    .key_test    ( key_test      ),
    .key_pause   ( key_pause     ),
    .key_service ( key_service   ),
    .key_tilt    ( key_tilt      ),
    .key_digit   ( key_digit     ),

    .shift       ( key_shift     ),
    .ctrl        ( key_ctrl      ),
    .alt         ( key_alt       ),
    .key_gfx     ( key_gfx       ),
    .key_snd     ( key_snd       ),
    .vol_up      ( vol_up        ),
    .vol_down    ( vol_down      ),
    .debug_plus  ( debug_plus    ),
    .debug_minus ( debug_minus   )
);

    `ifndef JTFRAME_RELEASE
        wire [7:0] sys_info;
        // wire       flip_info = dip_flip & ~core_mod[0]; // Do not flip the debug display for vertical games
        wire       flip_info = 0;

        jtframe_debug #(.COLORW(COLORW)) u_debug(
            .clk         ( clk_sys       ),
            .rst         ( rst           ),

            .shift       ( key_shift   | board_shift ),
            .ctrl        ( key_ctrl    | board_ctrl  ),
            .alt         ( key_alt     | board_alt   ),
            .key_snd     ( key_snd                   ),
            .key_gfx     ( key_gfx     | board_gfx   ),
            .key_digit   ( key_digit   | board_digit ),
            .debug_plus  ( debug_plus  | board_plus  ),
            .debug_minus ( debug_minus | board_minus ),
            .board_gfx   ( board_gfx     ),

            // overlay the value on video
            .pxl_cen     ( pxl_cen       ),
            .dip_flip    ( flip_info     ),
            .rin         ( crdts_r       ),
            .gin         ( crdts_g       ),
            .bin         ( crdts_b       ),
            .lhbl        ( base_lhbl     ),
            .lvbl        ( base_lvbl     ),
            .rout        ( dbg_r         ),
            .gout        ( dbg_g         ),
            .bout        ( dbg_b         ),

            .gfx_en      ( gfx_en        ),
            .snd_en      ( snd_en        ),
            .snd_vol     ( snd_vol       ),
            .snd_mode    ( snd_mode      ),
            .debug_bus   ( debug_bus     ),
            .debug_view  ( debug_view    ),
            .sys_info    ( sys_info      ),
            .target_info ( target_info   )
        );

        jtframe_sys_info u_info(
            .rst_sys    ( game_rst      ),
            .clk        ( clk_sys       ),
            .dip_pause  ( dip_pause     ),
            .dip_flip   ( dip_flip      ),
            .game_led   ( led_peak      ),
            .LVBL       ( LVBL          ),
            .core_mod   ( core_mod      ),
            // sound
            .sample     ( snd_sample    ),
            .snd_en     ( snd_en        ),
            .snd_vu     ( snd_vu        ),
            .snd_l      ( snd_lin       ),
            .snd_r      ( snd_rin       ),
            .snd_vol    ( snd_vol       ),
            .snd_mode   ( snd_mode      ),
            .vu_peak    ( vu_peak       ),

            .dial_x     ( dial_x        ),
            .ba_rdy     ( bax_rdy       ),
            .dipsw      ( dipsw[23:0]   ),
            // IOCTL
            .ioctl_rom  ( dwnld_busy     ),
            .ioctl_ram  ( ioctl_ram     ),
            .ioctl_cart ( ioctl_cart    ),
            // mouse
            .mouse_f    ( bd_mouse_f    ),
            .mouse_dx   ( bd_mouse_dx   ),
            .mouse_dy   ( bd_mouse_dy   ),
            .st_addr    ( debug_bus     ),
            .st_dout    ( sys_info      )
        );
    `else
        assign gfx_en    = 4'b1111;
        assign snd_en    = 6'h3f;
        assign debug_bus =  0;
        assign vu_peak   =  0;
        assign dbg_r = crdts_r;
        assign dbg_g = crdts_g;
        assign dbg_b = crdts_b;
    `endif
`else
    `ifndef JTFRAME_SIM_GFXEN
    `define JTFRAME_SIM_GFXEN 4'hf
    `endif
    assign key_joy4    = 10'h0;
    assign key_joy3    = 10'h0;
    assign key_joy2    = 10'h0;
    assign key_joy1    = 10'h0;
    assign key_start   = 2'd0;
    assign key_coin    = 2'd0;
    assign key_reset   = 1'b0;
    assign key_pause   = 1'b0;
    assign key_service = 1'b0;
    assign key_tilt    = 1'b0;
    assign key_test    = 1'b0;
    assign gfx_en      = `JTFRAME_SIM_GFXEN;
    assign debug_bus   = 0;
    assign key_gfx     = 0;
    assign dbg_r       = crdts_r;
    assign dbg_g       = crdts_g;
    assign dbg_b       = crdts_b;
`endif

jtframe_volume u_volume(
    .rst            ( game_rst        ),
    .clk            ( clk_sys         ),
    .vs             ( vs              ),
    .peak           ( snd_peak        ),
    .up             ( vol_up          ),
    .down           ( vol_down        ),
    .vol            ( snd_vol         )
);

// crop software-drawn black frames around the image
jtframe_short_blank #(
    .WIDTH      ( VIDEO_WIDTH     ),
    .HEIGHT     ( VIDEO_HEIGHT    )
) u_short_blank (
    .clk        ( clk_sys         ),
    .pxl_cen    ( pxl_cen         ),
    .LHBL       ( LHBL            ),
    .LVBL       ( LVBL            ),
    .v_en       ( 1'b0            ),
    .h_en       ( frame_blank[0]  ),
    .wide       ( frame_blank[1]  ),
    .HS         ( hs              ),
    .hb_out     ( LHBLs           ),
    .vb_out     (                 )
);

jtframe_inputs #(
    .BUTTONS   ( BUTTONS                ),
    .ACTIVE_LOW( GAME_INPUTS_ACTIVE_LOW )
) u_inputs(
    .rst            ( game_rst        ),
    .clk            ( clk_sys         ),
    .vs             ( vs              ),
    .LHBL           ( LHBLs           ),
    .ioctl_rom      ( dwnld_busy      ),
    .rot_ccw        ( rotate[1]       ),
    .autofire0      ( autofire0       ),
    .dial_raw_en    ( dial_raw_en     ),
    .dial_reverse   ( dial_reverse    ),
    .sensty         ( sensty          ),

    .soft_rst       ( soft_rst        ),

    .board_joy1     ( board_joystick1 ),
    .board_joy2     ( board_joystick2 ),
    .board_joy3     ( board_joystick3 ),
    .board_joy4     ( board_joystick4 ),
    .board_start    ( board_start     ),
    .board_coin     ( board_coin      ),

    .key_joy1       ( key_joy1        ),
    .key_joy2       ( key_joy2        ),
    .key_joy3       ( key_joy3        ),
    .key_joy4       ( key_joy4        ),
    .key_start      ( key_start       ),
    .key_coin       ( key_coin        ),
    .key_service    ( key_service | board_service ),
    .key_tilt       ( key_tilt    | board_tilt    ),
    .key_pause      ( key_pause   | board_pause   ),
    .key_test       ( key_test    | board_test    ),
    .osd_pause      ( osd_pause       ),
    .key_reset      ( key_reset | board_reset     ),
    .rot_control    ( rot_control     ),

    .game_joy1      ( game_joystick1  ),
    .game_joy2      ( game_joystick2  ),
    .game_joy3      ( game_joystick3  ),
    .game_joy4      ( game_joystick4  ),
    .game_coin      ( game_coin       ),
    .game_start     ( game_start      ),
    .game_service   ( game_service    ),
    .game_tilt      ( game_tilt       ),
    .game_test      ( game_test       ),
    .locked         ( locked          ),

    // Mouse & Paddle
    .bd_mouse_dx    ( bd_mouse_dx     ),
    .bd_mouse_idx   ( bd_mouse_idx    ),
    .bd_mouse_dy    ( bd_mouse_dy     ),
    .bd_mouse_f     ( bd_mouse_f      ),
    .bd_mouse_st    ( bd_mouse_st     ),

    .board_paddle_1 ( board_paddle_1  ),
    .board_paddle_2 ( board_paddle_2  ),
    .game_paddle_1  ( game_paddle_1   ),
    .game_paddle_2  ( game_paddle_2   ),
    .mouse_1p       ( mouse_1p        ),
    .mouse_2p       ( mouse_2p        ),
    .mouse_strobe   ( mouse_strobe    ),
    .spinner_1      ( spinner_1       ),
    .spinner_2      ( spinner_2       ),
    .dial_x         ( dial_x          ),
    .dial_y         ( dial_y          ),

    // Input recording
    .dip_pause      ( dip_pause       ),
    .ioctl_lock     ( prog_lock       ),
    .ioctl_addr     ( ioctl_addr      ),
    .ioctl_dout     ( ioctl_dout      ),
    .ioctl_din      ( ioctl_din       ),
    .ioctl_merged   ( ioctl_merged    ),
    .ioctl_wr       ( ioctl_wr        ),

    .debug_bus      ( debug_bus       ),
    // Simulation helpers
    .game_pause     ( game_pause      )
);

jtframe_dip #(.XOR_ROT(XOR_ROT)) u_dip(
    .clk        ( clk_sys       ),
    .status     ( status        ),
    .core_mod   ( core_mod      ),
    .game_pause ( game_pause    ),
    .hdmi_arx   ( hdmi_arx      ),
    .hdmi_ary   ( hdmi_ary      ),
    .rotate     ( rotate        ),
    .rot_control( rot_control   ),
    .rot_osdonly( rot_osdonly   ),
    .enable_fm  ( enable_fm     ),
    .enable_psg ( enable_psg    ),
    .osd_pause  ( osd_pause     ),
    .osd_shown  ( osd_shown     ),
    .game_test  ( game_test     ),
    .dip_test   ( dip_test      ),
    .dip_pause  ( pre_pause     ),
    .dip_flip   ( dip_flip      ),
    .dip_fxlevel( dip_fxlevel   )
);

`ifdef JTFRAME_CHEAT
    wire       cheat_rd, cheat_ack, cheat_dst, cheat_rdy, cheat_wr;
    // jtframe_credits video control
    wire [7:0] vram_dout, vram_din;
    wire [9:0] vram_addr;
    wire       vram_we;
    wire [2:0] vram_ctrl;

    jtframe_cheat #(
        .AW         (  SDRAMW   )
    ) u_cheat(
        .rst        ( game_rst  ),
        .clk_pico   ( clk_pico  ),
        .clk_rom    ( clk_rom   ),

        .LVBL       ( LVBL      ),
        .status     ( status    ),

        // From/to game
        .game_addr  ( ba0_addr  ),
        .game_rd    ( ba_rd[0]  ),
        .game_wr    ( ba_wr[0]  ),
        .game_din   ( ba0_din   ),
        .game_din_m ( ba0_dsn   ),
        .game_ack   ( cheat_ack ),
        .game_dst   ( cheat_dst ),
        .game_rdy   ( cheat_rdy ),

        // From/to SDRAM bank 0
        .ba0_addr   ( bax_addr  ),
        .ba0_rd     ( cheat_rd  ),
        .ba0_wr     ( cheat_wr  ),
        .ba0_dst    ( bax_dst[0]),
        .ba0_rdy    ( bax_rdy[0]),
        .ba0_ack    ( bax_ack[0]),
        .ba0_din    ( bax_din   ),
        .ba0_din_m  ( bax_dsn   ),
        .data_read  ( sdram_dout),

        .flags      ( cheat     ),
        .joy1       ( game_joystick1[7:0] ),
        .joy2       ( game_joystick2[7:0] ),
        .joyana_l1  ( joyana_l1 ),
        .joyana_r1  ( joyana_r1 ),
        .joyana_l2  ( joyana_l2 ),
        .joyana_r2  ( joyana_r2 ),

        .led        ( cheat_led ),
        .locked     ( locked    ),
        .timestamp  ( timestamp ),

        .pause_in   ( pre_pause ),
        .pause_out  ( dip_pause ),

        // Game module
        .st_addr    ( st_addr   ),
        .st_dout    ( st_dout   ),
        .debug_bus  ( debug_bus ),

        // UART
        .uart_rx    ( uart_rx   ),
        .uart_tx    ( uart_tx   ),

        // Video
        .vram_addr  ( vram_addr ),
        .vram_din   ( vram_din  ),
        .vram_dout  ( vram_dout ),
        .vram_we    ( vram_we   ),
        .vram_ctrl  ( vram_ctrl ),

        // Program
        .prog_en    ( prog_cheat),
        .prog_addr  ( ioctl_addr[7:0] ),
        .prog_wr    ( ioctl_wr  ),
        .prog_data  ( ioctl_dout)
    );
    assign bax_rd = { ba_rd[3:1], cheat_rd };
    assign bax_wr = { ba_wr[3:1], cheat_wr };
    assign ba_ack = { bax_ack[3:1], cheat_ack };
    assign ba_rdy = { bax_rdy[3:1], cheat_rdy };
    assign ba_dst = { bax_dst[3:1], cheat_dst };
    // always enable credits for compilations with JTFRAME_CHEAT
    `define JTFRAME_CREDITS
`else
    assign bax_rd    = ba_rd;
    assign bax_wr    = ba_wr;
    assign bax_din   = ba0_din;
    assign bax_dsn   = ba0_dsn;
    assign bax_addr  = ba0_addr;
    assign ba_ack    = bax_ack;
    assign ba_rdy    = bax_rdy;
    assign ba_dst    = bax_dst;
    assign uart_tx   = 1; // no signal out
    assign cheat_led = 0;
    assign dip_pause = pre_pause;
    assign st_addr   = debug_bus;
`endif

// Audio
// `ifdef JTFRAME_SND48K
//     wire cen48;
//     jtframe_frac_cen #(.W(1),.WC(11)) u_cen48k(
//         .clk        ( clk48     ),
//         .n          ( 11'd1     ),         // numerator
//         .m          ( 11'd1024  ),         // denominator
//         .cen        ( cen48     ),
//         .cenb       (           )
//     );

//     jtframe_fir #(
//         .KMAX   ( 75            ),
//         .COEFFS ( "fir20k.hex"  )
//     ) u_fir(
//         .rst        ( rst       ),
//         .clk        ( clk48     ),
//         .sample     ( cen48     ),
//         .l_in       ( snd_lin   ),
//         .r_in       ( snd_rin   ),
//         .l_out      ( snd_lout  ),
//         .r_out      ( snd_rout  )
//     );
// `else
    // bypass the sound signals if the interpolator is not used
    assign snd_rout = snd_rin;
    assign snd_lout = snd_lin;
// `endif


`ifdef SIMULATION
    integer fsnd;
    initial begin
        fsnd=$fopen("sound.raw","wb");
    end
    always @(posedge snd_sample) begin
        $fwrite(fsnd,"%u", {snd_lin, snd_rin});
    end
`endif

// support for 48MHz
// Above 64MHz HF should be 1. SHIFTED depends on whether the SDRAM
// clock is shifted or not.
// Writting on each bank must be selectively enabled with macros
// in order to ease the placing of the SDRAM data signals in pad registers
// MiSTer can place them in the pads if only one bank is used for writting
// Not placing them in pads may create timing problems, especially at 96MHz
// ie, the core may compile correctly but data transfer may fail.
jtframe_sdram64 #(
    .AW           ( SDRAMW        ),
    .BA0_LEN      ( BA0_LEN       ),
    .BA1_LEN      ( BA1_LEN       ),
    .BA2_LEN      ( BA2_LEN       ),
    .BA3_LEN      ( BA3_LEN       ),
    .BA0_AUTOPRECH( BA0_AUTOPRECH ),
    .BA1_AUTOPRECH( BA1_AUTOPRECH ),
    .BA2_AUTOPRECH( BA2_AUTOPRECH ),
    .BA3_AUTOPRECH( BA3_AUTOPRECH ),
`ifdef JTFRAME_BA1_WEN
    .BA1_WEN      ( 1             ), `endif
`ifdef JTFRAME_BA2_WEN
    .BA2_WEN      ( 1             ), `endif
`ifdef JTFRAME_BA3_WEN
    .BA3_WEN      ( 1             ), `endif
    .PROG_LEN     ( PROG_LEN      ),
    .MISTER       ( MISTER        ),
`ifdef JTFRAME_SDRAM96
    .HF(1),
    .SHIFTED(0)
`else
    .HF(0),
    .SHIFTED      ( SDRAM_SHIFT   )
`endif
) u_sdram(
    .rst        ( rst           ),
    .clk        ( clk_rom       ), // 96MHz = 32 * 6 MHz -> CL=2
    .init       ( sdram_init    ),

    .ba0_addr   ( bax_addr      ),
    .ba1_addr   ( ba1_addr      ),
    .ba2_addr   ( ba2_addr      ),
    .ba3_addr   ( ba3_addr      ),

    .rd         ( bax_rd        ),
    .wr         ( bax_wr        ),
    .ba0_din    ( bax_din       ),
    .ba0_dsn    ( bax_dsn       ),
    .ba1_din    ( ba1_din       ),
    .ba1_dsn    ( ba1_dsn       ),
    .ba2_din    ( ba2_din       ),
    .ba2_dsn    ( ba2_dsn       ),
    .ba3_din    ( ba3_din       ),
    .ba3_dsn    ( ba3_dsn       ),

    .rdy        ( bax_rdy       ),
    .ack        ( bax_ack       ),
    .dok        ( ba_dok        ),
    .dst        ( bax_dst       ),

    // ROM-load interface
    .prog_en    ( dwnld_busy | ioctl_cart ),
    .prog_addr  ( prog_addr     ),
    .prog_ba    ( prog_ba       ),
    .prog_rd    ( prog_rd       ),
    .prog_wr    ( prog_we       ),
    .prog_din   ( prog_data     ),
    .prog_dsn   ( prog_dsn      ),
    .prog_rdy   ( prog_rdy      ),
    .prog_dst   ( prog_dst      ),
    .prog_dok   ( prog_dok      ),
    .prog_ack   ( prog_ack      ),
    // SDRAM interface
    .sdram_dq   ( SDRAM_DQ      ),
`ifdef VERILATOR // to avoid a warning
    .sdram_din  (               ),
`endif
    .sdram_a    ( SDRAM_A       ),
    .sdram_dqml ( SDRAM_DQML    ),
    .sdram_dqmh ( SDRAM_DQMH    ),
    .sdram_nwe  ( SDRAM_nWE     ),
    .sdram_ncas ( SDRAM_nCAS    ),
    .sdram_nras ( SDRAM_nRAS    ),
    .sdram_ncs  ( SDRAM_nCS     ),
    .sdram_ba   ( SDRAM_BA      ),
    .sdram_cke  ( SDRAM_CKE     ),

    // Common signals
    .dout       ( sdram_dout    ),
    .rfsh       ( ~LHBLs        )
);

`ifdef SIMULATION
    jtframe_romrq_rdy_check u_rdy_check(
        .rst       ( rst        ),
        .clk       ( clk_rom    ),
        .ba_rd     ( ba_rd      ),
        .ba_wr     ( ba_wr      ),
        .ba_ack    ( ba_ack     ),
        .ba_rdy    ( ba_rdy     )
    );

    `ifdef JTFRAME_SDRAM_STATS
    jtframe_sdram_stats_sim #(.AW(SDRAMW)) u_stats_sim(
        .rst        ( rst           ),
        .clk        ( clk_rom       ),
        // SDRAM interface
        .sdram_a    ( SDRAM_A       ),
        .sdram_ba   ( SDRAM_BA      ),
        .sdram_nwe  ( SDRAM_nWE     ),
        .sdram_ncas ( SDRAM_nCAS    ),
        .sdram_nras ( SDRAM_nRAS    ),
        .sdram_ncs  ( SDRAM_nCS     )
    );
    `endif
`endif

endmodule
