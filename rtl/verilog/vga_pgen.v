/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Pixel Generator                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2001 Richard Herveille, OpenCores     //
//             Copyright (C) 2018 Roa Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////


// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : vga_pgen.v
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 2.0     2001        rherveille  Last OpenCores Release
// ------------------------------------------------------------------
// KEYWORDS : VGA_LCD OPENCORES                                 
// ------------------------------------------------------------------
// PURPOSE  : Pixel Generator
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME      RANGE  DESCRIPTION                 DEFAULT UNITS
//  LINE_FIFO_DEPTH  0+    Line FIFO depth             128
//  HAS_HWC0        [0,1]  Implement hardware cursor0  0
//  HAS_HWC1        [0,1]  Implement hardware cursor1  0
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : synchronous active high rst_i
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : clut_switch_o, clut_adr_o
//   Scan Methodology    : na
//   Instantiations      : vga_clkgen, vga_tgen, vga_colproc,
//                         vga_curproc, vga_fifo
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------

module vga_pgen #(
  parameter LINE_FIFO_DEPTH = 128,
  parameter HAS_HWC0        = 0,
  parameter HAS_HWC1        = 0
)
(
  input             clk_i,                // master clock
  input             ctrl_ven_i,           // Video enable signal

  input      [ 1:0] ctrl_cd_i,            // color depth setting
  input             ctrl_pc_i,            // pseudo color setting

  // horiontal timing settings
  input             ctrl_hsyncl_i,        // horizontal sync pulse polarization level (pos/neg)
  input      [ 7:0] thsync_i,             // horizontal sync pulse width (in pixels)
  input      [ 7:0] thgdel_i,             // horizontal gate delay (in pixels)
  input      [15:0] thgate_i,             // horizontal gate length (number of visible pixels per line)
  input      [15:0] thlen_i,              // horizontal length (number of pixels per line)

  // vertical timing settings
  input             ctrl_vsyncl_i,        // vertical sync pulse polarization level (pos/neg)
  input      [ 7:0] tvsync_i,             // vertical sync pulse width (in lines)
  input      [ 7:0] tvgdel_i,             // vertical gate delay (in lines)
  input      [15:0] tvgate_i,             // vertical gate length (number of visible lines in frame)
  input      [15:0] tvlen_i,              // vertical length (number of lines in frame)

  // composite signals
  input             ctrl_csyncl_i,        // composite sync pulse polarization level
  input             ctrl_blankl_i,        // blank signal polarization level

  // status outputs
  output reg        eoh_o,                // end of horizontal
  output reg        eov_o,                // end of vertical
  output reg        line_fifo_uvf_o,      // line FIFO underflow error
  output reg        resync_o,             // resync master bus interface

  // Pixel signals
  input      [31:0] fb_data_fifo_q_i,     //framebuffer fifo data
  input             fb_data_fifo_empty_i, //framebuffer fifo empty
  output            fb_data_fifo_rreq_o,  //framebuffer fifo read request
  input             fb_image_done_i,      //TODO: ??

  // Colour Lookup Table
  output reg        stat_acmp_i,          // active CLUT memory page
  output            clut_req_o,           // request access to CLUT
  output     [ 8:0] clut_adr_o,           // CLUT address
  input      [23:0] clut_q_i,             // data from CLUT
  input             clut_ack_i,           // CLUT access acknowledge
  input             ctrl_cbsw_i,          // enable clut bank switching
  output            clut_switch_o,        // clut memory bank-switch request: clut page switched (when enabled)

  // Hardware cursors
  input      [ 8:0] cursor_adr_i,         // cursor data address (from wbm)
  input             cursor0_en_i,         // enable hardware cursor0
  input             cursor0_res_i,        // cursor0 resolution
  input      [31:0] cursor0_xy_i,         // (x,y) address hardware cursor0
  output     [ 3:0] cc0_adr_o,            // cursor0 color registers address output
  input      [15:0] cc0_dat_i,            // cursor0 color registers data input
  input             cursor1_en_i,         // enable hardware cursor1
  input             cursor1_res_i,        // cursor1 resolution
  input      [31:0] cursor1_xy_i,         // (x,y) address hardware cursor1
  output     [ 3:0] cc1_adr_o,            // cursor1 color registers address output
  input      [15:0] cc1_dat_i,            // cursor1 color registers data input

  // pixel clock related outputs
  input             pclk_i,               // pixel clock in

  output reg        hsync_o,              // horizontal sync pulse
  output reg        vsync_o,              // vertical sync pulse
  output reg        csync_o,              // composite sync: Hsync OR Vsync (logical OR function)
  output reg        blank_o,              // blanking signal
  output reg [ 7:0] r_o, g_o, b_o         // RGB
);


  //---------------------------------------------
  // Module Body
  //

  //---------------------------------------------
  // Variables
  //

  //clk_i domain
  wire        sclr;                   // synchronous reset

  wire [23:0] color_proc_q;           // data from color processor
  wire        color_proc_wreq;
  wire [ 7:0] clut_offs;              // color lookup table offset

  reg         fb_image_done_dly, fb_image_done_dly2;

  wire [23:0] rgb_fifo_d,
              rgb_fifo_q;
  wire        rgb_fifo_empty,
              rgb_fifo_full,
              rgb_fifo_rreq,
              rgb_fifo_wreq;

  wire        line_fifo_full_wr,
              line_fifo_empty_rd,
              line_fifo_uvf;
  reg         line_fifo_uvf_toggle;
  reg  [ 2:0] line_fifo_uvf_toggle_clk_syncreg;
  reg         line_fifo_uvf_o_dly;
  wire        line_fifo_wclr;

  wire [ 7:0] r,g,b;


  //pclk_i domain
  reg  [ 1:0] sclr_pclk_syncreg;      // synchronize sclr to pclk_i domain
  wire        sclr_pclk;              // synchronous reset (pclk_i domain)

  wire        gate,
              eol,                    // end-of-line
              eof;                    // end-of-frame
  reg         eol_toggle,             // toggles when eol
              eof_toggle;             // toggles when eof

  reg  [ 2:0] eol_toggle_clk_syncreg, // synchronize eol to clk_i domain
              eof_toggle_clk_syncreg; // synchronize eof to clk_i domain


wire [23:0] cur1_q;
wire        cur1_wreq;



  wire ihsync, ivsync, icsync, iblank;


  //-----------------------------------
  // clk_i clock domain
  //

  // Reset pipeline when video not enabled
  assign sclr = ~ctrl_ven_i;


  //
  // Color Processor
  //
  vga_colproc color_proc (
    .clk_i                ( clk_i                ),
    .rst_i                ( sclr                 ),
    .color_depth_i        ( ctrl_cd_i            ),
    .pseudo_color_i       ( ctrl_pc_i            ),
    .frame_buffer_d_i     ( fb_data_fifo_q_i     ),
    .frame_buffer_empty_i ( fb_data_fifo_empty_i ),
    .frame_buffer_rreq_o  ( fb_data_fifo_rreq_o  ),
    .rgb_fifo_full_i      ( rgb_fifo_full        ),
    .rgb_fifo_wreq_o      ( color_proc_wreq      ),
    .r_o                  ( color_proc_q[23:16]  ),
    .g_o                  ( color_proc_q[15: 8]  ),
    .b_o                  ( color_proc_q[ 7: 0]  ),
    .clut_req_o           ( clut_req_o           ),
    .clut_ack_i           ( clut_ack_i           ),
    .clut_offs_o          ( clut_offs            ),
    .clut_q_i             ( clut_q_i             )
  );


  //
  // clut bank switch / cursor data delay2: Account for ColorProcessor DataBuffer delay
  always @(posedge clk_i)
    if      (sclr               ) fb_image_done_dly <= 1'b0;
    else if (fb_data_fifo_rreq_o) fb_image_done_dly <= fb_image_done_i;


  always @(posedge clk_i)
    if (sclr) fb_image_done_dly2 <= 1'b0;
    else      fb_image_done_dly2 <= fb_image_done_dly;


  // switch CLUT
  assign clut_switch_o = fb_image_done_dly2 & ~fb_image_done_dly;


  // select next clut when finished reading clut for current video bank (and bank switch enabled)
  always @(posedge clk_i)
    if      (sclr       ) stat_acmp_i <= 1'b0;
    else if (ctrl_cbsw_i) stat_acmp_i <= stat_acmp_i ^ clut_switch_o;  


  // generate clut-address
  assign clut_adr_o = {stat_acmp_i, clut_offs};


  //
  // Hardware Cursor 0
  //
  reg sddImDoneFifoQ, sdImDoneFifoQ;

generate
  if (HAS_HWC1 != 0)
  begin
	wire       cursor1_ld_strb;
	reg        scursor1_en;
	reg        scursor1_res;
	reg [31:0] scursor1_xy;

	assign cursor1_ld_strb = fb_image_done_dly2 & ~fb_image_done_dly;

	always @(posedge clk_i)
	  if (sclr)
	    scursor1_en <= #1 1'b0;
	  else if (cursor1_ld_strb)
	    scursor1_en <= cursor1_en_i;

	always @(posedge clk_i)
	  if (cursor1_ld_strb)
	    scursor1_xy <= cursor1_xy_i;

	always @(posedge clk_i)
	  if (cursor1_ld_strb)
	    scursor1_res <= cursor1_res_i;

	vga_curproc hw_cursor1 (
		.clk           ( clk_i           ),
		.rst_i         ( sclr            ),
		.Thgate        ( thgate_i        ),
		.Tvgate        ( tvgate_i        ),
		.idat          ( color_proc_q    ),
		.idat_wreq     ( color_proc_wreq ),
		.cursor_xy     ( scursor1_xy     ),
		.cursor_res    ( scursor1_res    ),
		.cursor_en     ( scursor1_en     ),
		.cursor_wadr   ( cursor_adr_i      ),
		.cursor_we     ( cursor1_we      ),
		.cursor_wdat   ( dat_i           ),
		.cc_adr_o      ( cc1_adr_o       ),
		.cc_dat_i      ( cc1_dat_i       ),
		.rgb_fifo_wreq ( cur1_wreq       ),
		.rgb           ( cur1_q          )
	);

        if (HAS_HWC0 == 1)
        begin
            // generate additional signals for Hardware Cursor0 (if enabled)
            always @(posedge clk_i)
              if (cur1_wreq)
              begin
                  sdImDoneFifoQ  <= fb_image_done_dly;
                  sddImDoneFifoQ <= sdImDoneFifoQ;
              end
        end
  end
  else // HAS_HWC1 == 0
  begin
      // Hardware Cursor1 disabled, generate pass-through signals
      assign cur1_wreq = color_proc_wreq;
      assign cur1_q    = color_proc_q;
      assign cc1_adr_o = 4'h0;


      if (HAS_HWC0 != 0)
      begin
          // generate additional signals for Hardware Cursor0 (if enabled)
          always @*
            begin
                assign sdImDoneFifoQ  = fb_image_done_dly;
                assign sddImDoneFifoQ = fb_image_done_dly2;
            end
      end
  end
endgenerate


generate
  if (HAS_HWC0 != 0)
  begin
      wire cursor0_ld_strb;
      reg scursor0_en;
      reg scursor0_res;
      reg [31:0] scursor0_xy;

      assign cursor0_ld_strb = sddImDoneFifoQ & !sdImDoneFifoQ;

      always @(posedge clk_i)
        if      (sclr           ) scursor0_en <= 1'b0;
        else if (cursor0_ld_strb) scursor0_en <= cursor0_en_i;

      always @(posedge clk_i)
        if (cursor0_ld_strb) scursor0_xy <= cursor0_xy_i;

      always @(posedge clk_i)
        if (cursor0_ld_strb) scursor0_res <= cursor0_res_i;

      vga_curproc hw_cursor0 (
        .clk           ( clk_i         ),
        .rst_i         ( sclr          ),
        .Thgate        ( thgate_i      ),
        .Tvgate        ( tvgate_i      ),
        .idat          ( ssel1_q       ),
        .idat_wreq     ( ssel1_wreq    ),
        .cursor_xy     ( scursor0_xy   ),
        .cursor_en     ( scursor0_en   ),
        .cursor_res    ( scursor0_res  ),
        .cursor_wadr   ( cursor_adr_i    ),
        .cursor_we     ( cursor0_we    ),
        .cursor_wdat   ( dat_i         ),
        .cc_adr_o      ( cc0_adr_o     ),
        .cc_dat_i      ( cc0_dat_i     ),
        .rgb_fifo_wreq ( rgb_fifo_wreq ),
        .rgb           ( rgb_fifo_d    )
      );
  end
  else // HAS_HWC0 == 0
  begin
      // Hardware Cursor0 disabled, generate pass-through signals
      assign rgb_fifo_wreq = cur1_wreq;
      assign rgb_fifo_d    = cur1_q;
      assign cc0_adr_o     = 4'h0;
  end
endgenerate


  //
  // RGB buffer
  // Temporary station between clk_i domain and pclock_i domain
  // The cursor_processor pipelines introduce a delay between the color
  // processor's rgb_fifo_wreq and the rgb_fifo_full signals. To compensate
  // for this we double the rgb_fifo.
  wire [4:0] rgb_fifo_nword;

  vga_fifo #(4, 24) rgb_fifo (
    .clk    ( clk_i          ),
    .aclr   ( 1'b1           ),
    .sclr   ( sclr           ),
    .d      ( rgb_fifo_d     ),
    .wreq   ( rgb_fifo_wreq  ),
    .q      ( rgb_fifo_q     ),
    .rreq   ( rgb_fifo_rreq  ),
    .empty  ( rgb_fifo_empty ),
    .nword  ( rgb_fifo_nword ),
    .full   ( ),
    .aempty ( ),
    .afull  ( )
  );

  assign rgb_fifo_full = rgb_fifo_nword[3]; // actually half full
  assign rgb_fifo_rreq = ~line_fifo_full_wr & ~rgb_fifo_empty;



  //-----------------------------------
  // pclk_i clock domain
  //

  // synchronize timing/control settings; from clk_i domain to pclk_i domain
  always @(posedge pclk_i)
    sclr_pclk_syncreg <= {sclr_pclk_syncreg[0], sclr};

  assign sclr_pclk = sclr_pclk_syncreg[1];


  //
  // hookup line-fifo
  // Cross clock domains ... from clk_i to pclk_i
  assign line_fifo_wclr = sclr | resync_o;

  vga_fifo_dc #(7, 24) line_fifo (
    .wclk  ( clk_i              ),
    .wclr  ( line_fifo_wclr     ),
    .wreq  ( rgb_fifo_rreq      ), //write to line FIFO when reading from RGB FIFO
    .d     ( rgb_fifo_q         ),
    .full  ( line_fifo_full_wr  ),

    .rclk  ( pclk_i             ),
    .rclr  ( 1'b0               ),
    .rreq  ( gate               ),
    .q     ( {r,g,b}            ),
    .empty ( line_fifo_empty_rd )
  );


  // line FIFO exception (under-flow)
  assign line_fifo_uvf = line_fifo_empty_rd & gate;


  // register RGB outputs
  always @(posedge pclk_i)
  begin
      r_o <= r;
      g_o <= g;
      b_o <= b;
  end


  //
  // Timing generator
  //
  // th*_i signals are in the clk_i domain, but these are considered
  // pseudo static; ie. they hold their value long before they're used
  vga_tgen vtgen_inst(
    .clk_i     ( pclk_i      ),
    .rst_i     ( sclr_pclk   ),
    .clk_ena_i ( 1'b1        ),
    .thsync_i  ( thsync_i    ),
    .thgdel_i  ( thgdel_i    ),
    .thgate_i  ( thgate_i    ),
    .thlen_i   ( thlen_i     ),
    .tvsync_i  ( tvsync_i    ),
    .tvgdel_i  ( tvgdel_i    ),
    .tvgate_i  ( tvgate_i    ),
    .tvlen_i   ( tvlen_i     ),
    .eol_o     ( eol         ),
    .eof_o     ( eof         ),
    .gate_o    ( gate        ),
    .hsync_o   ( ihsync      ),
    .vsync_o   ( ivsync      ),
    .csync_o   ( icsync      ),
    .blank_o   ( iblank      )
  );


  //ctrl_*l_i signals are in the clk_i domain, but these are considered
  //pseudo static; ie. they hold their value long before they're used
  reg hsync, vsync, csync, blank;
  always @(posedge pclk_i)
    begin
        hsync   <= ihsync ^ ctrl_hsyncl_i;
        vsync   <= ivsync ^ ctrl_vsyncl_i;
        csync   <= icsync ^ ctrl_csyncl_i;
        blank   <= iblank ^ ctrl_blankl_i;

        hsync_o <= hsync;
        vsync_o <= vsync;
        csync_o <= csync;
        blank_o <= blank;
    end


  //
  // and back to the clk_i domain again
  //

  //generate toggling versions of eol/eof/line_fifo_uvf
  always @(posedge pclk_i)
    if      (sclr_pclk) eol_toggle <= 1'b0;
    else if (eol      ) eol_toggle <= ~eol_toggle;

  always @(posedge pclk_i)
    if      (sclr_pclk) eof_toggle <= 1'b0;
    else if (eof      ) eof_toggle <= ~eof_toggle; 

  always @(posedge pclk_i)
    if      (sclr_pclk    ) line_fifo_uvf_toggle <= 1'b0;
    else if (line_fifo_uvf) line_fifo_uvf_toggle <= ~line_fifo_uvf_toggle;


  //cross toggling eof/eol/line_fifo_uvf from pclk_i to clk_i domain
  always @(posedge clk_i)
    begin
         eol_toggle_clk_syncreg <= {eol_toggle_clk_syncreg[1:0], eol_toggle};
         eof_toggle_clk_syncreg <= {eof_toggle_clk_syncreg[1:0], eof_toggle};

         line_fifo_uvf_toggle_clk_syncreg <= {line_fifo_uvf_toggle_clk_syncreg[1:0], line_fifo_uvf_toggle};
    end


  //convert toggling eol/eof/line_fifo_uvf into strobe
  always @(posedge clk_i)
    if (sclr)
    begin
        eoh_o           <= 1'b0;
        eov_o           <= 1'b0;
        line_fifo_uvf_o <= 1'b0;
    end
    else
    begin
        eoh_o           <= eol_toggle_clk_syncreg          [2] ^ eol_toggle_clk_syncreg          [1];
        eov_o           <= eof_toggle_clk_syncreg          [2] ^ eol_toggle_clk_syncreg          [1];
        line_fifo_uvf_o <= line_fifo_uvf_toggle_clk_syncreg[2] ^ line_fifo_uvf_toggle_clk_syncreg[1];
    end


  // generate resync_o
  // reset bus-interface master when line fifo underruns.
  // This will cause a glitch in the image (1 frame),
  // but prevents corrupting the entire screen
  always @(posedge clk_i)
    if (sclr) line_fifo_uvf_o_dly <= 1'b0;
    else      line_fifo_uvf_o_dly <= line_fifo_uvf_o;


  always @(posedge clk_i)
    if (sclr) resync_o <= 1'b0;
    else      resync_o <= line_fifo_uvf_o & ~line_fifo_uvf_o_dly;

endmodule

