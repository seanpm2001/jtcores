/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 22-3-2022 */

module jtngp_game(
    `include "jtframe_game_ports.inc" // see $JTFRAME/hdl/inc/jtframe_game_ports.inc
);

wire [20:1] cpu_addr;
wire [15:0] cha_dout, obj_dout, scr1_dout, scr2_dout, regs_dout;
wire [15:0] cpu_dout, gfx_dout, shd_dout, flash0_dout;
wire [ 7:0] snd_latch, main_latch,
            st_video, st_main, st_snd;
wire [ 1:0] cpu_we, shd_we;
reg  [ 7:0] st_mux;
reg  [ 2:0] cart_size;
wire        gfx_cs,
            flash0_cs, flash0_rdy, flash0_ok;
wire        snd_ack, snd_nmi, snd_irq, snd_en, snd_rstn;
wire        hirq, virq, main_int5;

wire signed [ 7:0] snd_dacl, snd_dacr;

assign debug_view = st_mux;
assign game_led   = 0;

assign rom_addr = cpu_addr[15:1];
assign dip_flip = 0;

`ifdef CARTSIZE initial cart_size=`CARTSIZE; `endif

always @(posedge clk) begin
    if( prog_ba==1 && !ioctl_ram && ioctl_wr )
        cart_size <= ioctl_addr[21] ? 3'b100 :
                     ioctl_addr[20] ? 3'b010 :
                     ioctl_addr[19] ? 3'b001 : 3'b0;
end

always @(posedge clk) begin
    case( debug_bus[7:6] )
        0: st_mux <= st_video;
        1: st_mux <= st_main;
        2: st_mux <= st_snd;
        3: case( debug_bus[5:4] )
            0: st_mux <= snd_latch;
            1: st_mux <= main_latch;
            2: st_mux <= { 5'd0, snd_nmi, snd_irq, snd_rstn };
            default: st_mux <= 0;
        endcase
    endcase
end

jtngp_main u_main(
    .rst        ( rst24     ),
    .clk        ( clk24     ),
    .clk_rom    ( clk       ),
    .rtc_cen    ( rtc_cen   ),
    .cen12      ( cen12     ),
    .cen6       ( cen6      ),
    .phi1_cen   ( phi1_cen  ),

    // interrupt sources
    .lvbl       ( LVBL      ),
    // player inputs
    .joystick1  ( joystick1 ),
    .start_button(start_button[0]),
    .pwr_button ( coin_input[0]),
    // Bus access
    .cpu_addr   ( cpu_addr  ),
    .cpu_dout   ( cpu_dout  ),
    .gfx_dout   ( gfx_dout  ),
    .we         ( cpu_we    ),
    .shd_we     ( shd_we    ),
    .shd_dout   ( shd_dout  ),
    .gfx_cs     ( gfx_cs    ),

    // Sound
    .snd_nmi    ( snd_nmi   ),
    .snd_irq    ( snd_irq   ),
    .snd_rstn   ( snd_rstn  ),
    .snd_en     ( snd_en    ),
    .snd_ack    ( snd_ack   ),
    .snd_dacl   ( snd_dacl  ),
    .snd_dacr   ( snd_dacr  ),
    .main_int5  ( main_int5 ),
    .snd_latch  ( snd_latch ),
    .main_latch ( main_latch),

    // Cartridge
    .flash0_cs  ( flash0_cs ),
    .flash0_rdy ( flash0_rdy),
    .flash0_dout(flash0_dout),
    .flash1_cs  (           ),

    // Firmware access
    .rom_data   ( rom_data  ),
    .rom_cs     ( rom_cs    ),
    .rom_ok     ( rom_ok    ),

    // NVRAM
    .ioctl_addr ( ioctl_addr[13:0]),
    .ioctl_dout ( ioctl_dout),
    .ioctl_wr   ( ioctl_wr  ),
    .ioctl_din  ( ioctl_din ),
    .ioctl_ram  ( ioctl_ram ),
    // Debug
    .debug_bus  ( debug_bus ),
    .st_dout    ( st_main   )
);

jtngp_flash u_flash(
    .rst        ( rst24     ),
    .clk        ( clk24     ),

    .dev_type   ( cart_size ),
    // interface to CPU
    .cpu_addr   ( cpu_addr  ),
    .cpu_cs     ( flash0_cs ),
    .cpu_we     ( cpu_we    ),
    .cpu_dout   ( cpu_dout  ),
    .cpu_din    (flash0_dout),
    .rdy        ( flash0_rdy),      // rdy / ~bsy pin
    .cpu_ok     ( flash0_ok ),   // read data available

    // interface to SDRAM
    .cart_addr  ( cart0_addr),
    .cart_we    ( cart0_we  ),
    .cart_cs    ( cart0_cs  ),
    .cart_ok    ( cart0_ok  ),
    .cart_data  ( cart0_data),
    .cart_dsn   ( cart0_dsn ),
    .cart_din   ( cart0_din )
);
/* verilator tracing_off */
jtngp_snd u_snd(
    .rstn       ( snd_rstn  ),
    .clk        ( clk24     ),
    .cen3       ( cen3      ),

    .snd_en     ( snd_en    ),
    .snd_dacl   ( snd_dacl  ),
    .snd_dacr   ( snd_dacr  ),

    .main_addr  (cpu_addr[11:1]),
    .main_dout  ( cpu_dout  ),
    .main_din   ( shd_dout  ),
    .main_we    ( shd_we    ),
    .main_int5  ( main_int5 ),
    .snd_latch  ( snd_latch ),
    .main_latch ( main_latch),
    .irq_ack    ( snd_ack   ),
    .nmi        ( snd_nmi   ),
    .irq        ( snd_irq   ),

    .sample     ( sample    ),
    .snd_l      ( snd_left  ),
    .snd_r      ( snd_right ),
    // Debug
    .debug_bus  ( debug_bus ),
    .st_dout    ( st_snd    )
);
/* verilator tracing_off */
jtngp_video u_video(
    .rst        ( rst       ),
    .clk        ( clk       ),
    .clk24      ( clk24     ),
    .pxl_cen    ( pxl_cen   ),
    .pxl2_cen   ( pxl2_cen  ),
    .video_cen  ( {vcen6, vcen12} ),

    .status     ( status    ),

    // CPU
    .cpu_addr   (cpu_addr[13:1]),
    .cpu_dout   ( cpu_dout  ),
    .cpu_din    ( gfx_dout  ),
    .we         ( cpu_we    ),
    .gfx_cs     ( gfx_cs    ),

    .hirq       ( hirq      ),
    .virq       ( virq      ),

    .HS         ( HS        ),
    .VS         ( VS        ),
    .LHBL       ( LHBL      ),
    .LVBL       ( LVBL      ),
    .red        ( red       ),
    .green      ( green     ),
    .blue       ( blue      ),
    .gfx_en     ( gfx_en    ),
    // Debug
    .debug_bus  ( debug_bus ),
    .st_dout    ( st_video  )
);

endmodule