/*  This file is part of JTKCPU.
    JTKCPU program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTKCPU program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTKCPU.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 14-4-2023 */

module jt053260 (
    input                    rst,
    input                    clk,
    input                    cen,
    // Main CPU interface
    input                    ma0,
    input                    mrdnw,
    input                    mcs,
    input             [ 7:0] mdout,
    output reg        [ 7:0] mdin,
    // Sound CPU control
    input             [ 5:0] addr,
    input                    wr_n,
    input                    rd_n,
    input                    cs,
    input             [ 7:0] din,
    output reg        [ 7:0] dout,
    // input YM2151
    // input                    stb1,
    // input                    aux1,
    // ROM access for channel A
    output            [20:0] roma_addr,
    input             [ 7:0] roma_data,
    output                   roma_cs,

    output            [20:0] romb_addr,
    input             [ 7:0] romb_data,
    output                   romb_cs,

    output            [20:0] romc_addr,
    input             [ 7:0] romc_data,
    output                   romc_cs,

    output            [20:0] romd_addr,
    input             [ 7:0] romd_data,
    output                   romd_cs,

    output reg signed [11:0] snd_l,
    output reg signed [11:0] snd_r,
    output                   sample,
    input             [ 7:0] debug_bus
    // slots unconnected
    // input               st1,
    // input               st2,
    // input               aux2,
    // output              rdnwp,
    // output              tim2,
    // output              cen_e,    // M6809 clock
    // output              cen_q     // M6809 clock
);
    reg    [ 7:0] pm2s[0:1];
    reg    [ 7:0] ps2m[0:1];

    reg    [ 3:0] keyon, mode;
    wire   [ 3:0] over, mmr_we;
    reg    [ 3:0] adpcm_en, loop;
    reg    [ 2:0] ch0_pan, ch1_pan, ch2_pan, ch3_pan;

    wire          ch0_sample, ch1_sample, ch2_sample, ch3_sample;
    wire signed [9:0] ch0_snd_l, ch1_snd_l, ch2_snd_l, ch3_snd_l,
                      ch0_snd_r, ch1_snd_r, ch2_snd_r, ch3_snd_r;

    reg    [ 6:0] pan0_l, pan0_r, pan1_l, pan1_r,
                  pan2_l, pan2_r, pan3_l, pan3_r;
    wire          mmr_en;

    assign sample = |{ch0_sample,ch1_sample,ch2_sample,ch3_sample};
    assign mmr_en = addr[5:3]>=1 && addr[5:3]<=4;
    assign mmr_we = {4{ cs & ~wr_n & mmr_en }} &
                    { addr[5:3]==4, addr[5:3]==3, addr[5:3]==2, addr[5:3]==1 };

    function [11:0] acc( input [9:0] c0, c1, c2, c3 );
        acc = { {2{c0[9]}}, c0 } + { {2{c1[9]}}, c1 } + { {2{c2[9]}}, c2 } + { {2{c3[9]}}, c3 };
    endfunction

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            snd_l   <= 0;
            snd_r   <= 0;
        end else begin
            if( mode[1] ) begin
                snd_l <= acc( ch0_snd_l, ch1_snd_l, ch2_snd_l, ch3_snd_l );
                snd_r <= acc( ch0_snd_r, ch1_snd_r, ch2_snd_r, ch3_snd_r );
            end else if(cen) begin // fade out
                snd_l <= snd_l >>> 1;
                snd_r <= snd_r >>> 1;
            end
        end
    end

    // Interface with main CPU
    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            pm2s[0] <= 0;
            pm2s[1] <= 0;
        end else if(mcs) begin
            mdin <= ps2m[ma0];
            if ( !mrdnw ) pm2s[ma0] <= mdout;
        end
    end

    // Interface with sound CPU
    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            ps2m[0]   <= 0; ps2m[1]    <= 0;
            ch0_pan <= 0; ch1_pan <= 0; ch2_pan <= 0; ch3_pan <= 0;
            keyon  <= 4'hF; loop <= 0; mode    <= 0; adpcm_en <=0;
            dout <= 0;
        end else begin
            if( cs ) begin
                if ( !wr_n ) begin
                    case ( addr )
                        2,3:   ps2m[addr[0]] <= din;
                        6'h28: keyon <= din[3:0];
                        6'h2A: { adpcm_en, loop } <= din;
                        6'h2C: { ch1_pan, ch0_pan } <= din[5:0];
                        6'h2D: { ch3_pan, ch2_pan } <= din[5:0];
                        6'h2F: mode <= din[3:0];
                        default: ;
                    endcase
                end
                if (!rd_n) case ( addr )
                    0,1:     dout <= pm2s[addr[0]];
                    6'h29:   dout <= {4'd0,~over};
                    6'h2E:   dout <= mode[0] ? roma_data : 8'd0;
                    default: dout <= 0;
                endcase
            end
        end
    end

    function [6:0] pan_dec_l( input [2:0] code );
        case ( code )
            3'b001:  pan_dec_l = 7'b1111111;
            3'b010:  pan_dec_l = 7'b1110100;
            3'b011:  pan_dec_l = 7'b1101000;
            3'b100:  pan_dec_l = 7'b1011010;
            3'b101:  pan_dec_l = 7'b1001001;
            3'b110:  pan_dec_l = 7'b0110100;
            3'b111:  pan_dec_l = 7'b0000000;
            default: pan_dec_l = 0;
        endcase
    endfunction

    function [6:0] pan_dec_r( input [2:0] code);
        case ( code )
            3'b001:  pan_dec_r = 7'b0000000;
            3'b010:  pan_dec_r = 7'b0110100;
            3'b011:  pan_dec_r = 7'b1001001;
            3'b100:  pan_dec_r = 7'b1011010;
            3'b101:  pan_dec_r = 7'b1101000;
            3'b110:  pan_dec_r = 7'b1110100;
            3'b111:  pan_dec_r = 7'b1111111;
            default: pan_dec_r = 0;
        endcase
    endfunction

    always @* begin
        pan0_l = pan_dec_l( ch0_pan );
        pan0_r = pan_dec_r( ch0_pan );
        pan1_l = pan_dec_l( ch1_pan );
        pan1_r = pan_dec_r( ch1_pan );
        pan2_l = pan_dec_l( ch2_pan );
        pan2_r = pan_dec_r( ch2_pan );
        pan3_l = pan_dec_l( ch3_pan );
        pan3_r = pan_dec_r( ch3_pan );
    end

    jt053260_channel u_ch0(
        .rst      ( rst         ),
        .clk      ( clk         ),
        .cen      ( cen         ),

        // MMR
        .addr     ( addr[2:0]   ),
        .din      ( din         ),
        .we       ( mmr_we[0]   ),

        .pan_l    ( pan0_l      ),
        .pan_r    ( pan0_r      ),
        .keyon    ( keyon[0]    ),
        .loop     ( loop[0]     ),
        .sample   ( ch0_sample  ),
        .over     ( over[0]     ),

        .rom_addr ( roma_addr   ),
        .rom_data ( roma_data   ),
        .rom_cs   ( roma_cs     ),
        .adpcm_en ( adpcm_en[0] ),
        .snd_l    ( ch0_snd_l   ),
        .snd_r    ( ch0_snd_r   ),
        .debug_bus( debug_bus   )
    );

    jt053260_channel u_ch1(
        .rst      ( rst         ),
        .clk      ( clk         ),
        .cen      ( cen         ),

        // MMR
        .addr     ( addr[2:0]   ),
        .din      ( din         ),
        .we       ( mmr_we[1]   ),

        .pan_l    ( pan1_l      ),
        .pan_r    ( pan1_r      ),
        .keyon    ( keyon[1]    ),
        .loop     ( loop[1]     ),
        .sample   ( ch1_sample  ),
        .over     ( over[1]     ),

        .rom_addr ( romb_addr   ),
        .rom_data ( romb_data   ),
        .rom_cs   ( romb_cs     ),
        .adpcm_en ( adpcm_en[1] ),
        .snd_l    ( ch1_snd_l   ),
        .snd_r    ( ch1_snd_r   ),
        .debug_bus( debug_bus   )
    );

    jt053260_channel u_ch2(
        .rst      ( rst         ),
        .clk      ( clk         ),
        .cen      ( cen         ),

        // MMR
        .addr     ( addr[2:0]   ),
        .din      ( din         ),
        .we       ( mmr_we[2]   ),

        .pan_l    ( pan2_l      ),
        .pan_r    ( pan2_r      ),
        .keyon    ( keyon[2]    ),
        .loop     ( loop[2]     ),
        .sample   ( ch2_sample  ),
        .over     ( over[2]     ),

        .rom_addr ( romc_addr   ),
        .rom_data ( romc_data   ),
        .rom_cs   ( romc_cs     ),
        .adpcm_en ( adpcm_en[2] ),
        .snd_l    ( ch2_snd_l   ),
        .snd_r    ( ch2_snd_r   ),
        .debug_bus( debug_bus   )
    );

    jt053260_channel u_ch3(
        .rst      ( rst         ),
        .clk      ( clk         ),
        .cen      ( cen         ),

        // MMR
        .addr     ( addr[2:0]   ),
        .din      ( din         ),
        .we       ( mmr_we[3]   ),

        .pan_l    ( pan3_l      ),
        .pan_r    ( pan3_r      ),
        .keyon    ( keyon[3]    ),
        .loop     ( loop[3]     ),
        .sample   ( ch3_sample  ),
        .over     ( over[3]     ),

        .rom_addr ( romd_addr   ),
        .rom_data ( romd_data   ),
        .rom_cs   ( romd_cs     ),
        .adpcm_en ( adpcm_en[3] ),
        .snd_l    ( ch3_snd_l   ),
        .snd_r    ( ch3_snd_r   ),
        .debug_bus( debug_bus   )
    );

endmodule

////////////////////////////////////////////////////////////////////////////////
module jt053260_channel(
    input                    rst,
    input                    clk,
    input                    cen,
    // MMR interface
    input             [ 2:0] addr,
    input             [ 7:0] din,
    input                    we,

    input                    keyon,
    input                    loop,
    input                    adpcm_en,
    input             [ 6:0] pan_l, pan_r,
    input             [ 7:0] rom_data,

    output reg        [20:0] rom_addr,
    output reg               rom_cs,
    output reg signed [ 9:0] snd_l,
    output reg signed [ 9:0] snd_r,
    output                   over,
    output                   sample,
    input             [ 7:0] debug_bus
);
    // MMR
    reg         [ 7:0] mmr[0:7];
    wire        [20:0] start;
    wire        [15:0] length;
    wire        [11:0] pitch;
    wire        [ 6:0] volume;

    reg         [16:0] cnt;
    reg         [15:0] inc;
    reg         [11:0] pitch_cnt;
    reg  signed [ 9:0] pre_snd;
    reg         [ 8:0] kadpcm;
    reg                adpcm_cnt, cnt_up;
    wire signed [17:0] mul_l;
    wire signed [17:0] mul_r;

    wire        [12:0] nx_pitch_cnt;
    wire signed [ 7:0] svl, svr;
    wire        [ 6:0] vol_l, vol_r;
    wire        [ 3:0] nibble;

    assign start  = { mmr[6][4:0], mmr[5], mmr[4] };
    assign length = { mmr[3], mmr[2] };
    assign pitch  = { mmr[1][3:0], mmr[0] };
    assign volume = { mmr[7][6:0] };

    assign nx_pitch_cnt = {1'd0, pitch_cnt } + 13'd1;
    assign nibble       = adpcm_cnt ? rom_data[7:4] : rom_data[3:0];
    assign sample       = nx_pitch_cnt[12] & cen;
    assign vol_l        = volume | pan_l;
    assign vol_r        = volume | pan_r;
    assign svl          = {1'b0, vol_l};
    assign svr          = {1'b0, vol_r};
    assign mul_l        = pre_snd * svl;
    assign mul_r        = pre_snd * svr;
    assign over         = cnt[16] & keyon;

    always @* begin
        case ( nibble )
            4'h0: kadpcm =  9'd0;
            4'h1: kadpcm =  9'd1;
            4'h2: kadpcm =  9'd2;
            4'h3: kadpcm =  9'd4;
            4'h4: kadpcm =  9'd8;
            4'h5: kadpcm =  9'd16;
            4'h6: kadpcm =  9'd32;
            4'h7: kadpcm =  9'd64;
            4'h8: kadpcm = -9'd128;
            4'h9: kadpcm = -9'd64;
            4'hA: kadpcm = -9'd32;
            4'hB: kadpcm = -9'd16;
            4'hC: kadpcm = -9'd8;
            4'hD: kadpcm = -9'd4;
            4'hE: kadpcm = -9'd2;
            4'hF: kadpcm = -9'd1;
        endcase
    end

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            mmr[0] <= 0; mmr[1] <= 0; mmr[2] <= 0; mmr[3] <= 0;
            mmr[4] <= 0; mmr[5] <= 0; mmr[6] <= 0; mmr[7] <= 0;
        end else begin
            if( we ) mmr[addr] <= din;
        end
    end

    always @(posedge clk) begin
        snd_l <= mul_l[17-:10];
        snd_r <= mul_r[17-:10];
        if( !keyon ) begin
            snd_l <= 0;
            snd_r <= 0;
        end
    end

    always @(posedge clk, posedge rst) begin
        if( rst ) begin
            rom_addr  <= 0;
            cnt       <= 0;
            adpcm_cnt <= 0;
            pitch_cnt <= 0;
            rom_cs    <= 0;
            cnt_up    <= 0;
        end else begin
            cnt_up <= 0;
            rom_cs <= 1;
            if( cnt_up ) cnt <= cnt - 1'd1;
            if( !keyon ) begin
                rom_addr  <= start+21'd1; // skip first byte for ADPCM
                cnt       <= {1'd0, length};
                adpcm_cnt <= 0;
                pre_snd   <= pre_snd>>>1; // fade out
                rom_cs    <= 0;
                pitch_cnt <= pitch;
                cnt_up    <= 0;
            end else if( cen ) begin
                // ROM address increment and sample cnt decrement
                if( !cnt[16] && nx_pitch_cnt[12] ) begin
                    adpcm_cnt <= ~adpcm_cnt;
                    if( adpcm_cnt || !adpcm_en ) begin
                        rom_addr <= rom_addr + 1'd1;
                        cnt_up <= 1;
                        if( cnt==0 && loop ) begin
                            rom_addr <= start;
                            cnt      <= {1'd0, length};
                            cnt_up   <= 0;
                        end
                    end
                end
                pitch_cnt <= nx_pitch_cnt[12] ? pitch : nx_pitch_cnt[11:0];
                pre_snd <= adpcm_en ? pre_snd + kadpcm : { rom_data, 2'd0 };
            end
        end
    end

endmodule