/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Enhanced Colour Processor                       //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2003 Richard Herveille, OpenCores     //
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
// FILE NAME      : vga_colproc.v
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 2.0     2003        rherveille  Last OpenCores Release
// ------------------------------------------------------------------
// KEYWORDS : VGA_LCD OPENCORES
// ------------------------------------------------------------------
// PURPOSE  : Colour Processor
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : synchronous, active high
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : clut_offs_o 
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               : 
// -FHDR-------------------------------------------------------------


module vga_colproc (
  input             clk_i,              // master clock
  input             rst_i,              // synchronous reset

  input      [31:0] vdat_buffer_d_i,    // video memory data input

  input      [ 1:0] color_depth_i,      // color depth (8bpp, 16bpp, 24bpp)
  input             pseudo_color_i,     // pseudo color enabled (only for 8bpp color depth)

  input             vdat_buffer_empty_i,
  output reg        vdat_buffer_rreq_o, // pixel buffer read request

  input             rgb_fifo_full_i,
  output reg        rgb_fifo_wreq_o,
  output reg [ 7:0] r_o, g_o, b_o,      // pixel color information

  output reg        clut_req_o,         // clut request
  input             clut_ack_i,         // clut acknowledge
  output reg [ 7:0] clut_offs_o,        // clut offset
  input      [23:0] clut_q_i            // clut data in
);

  //---------------------------------------------
  // Constants
  //
  localparam IDLE        = 7'b000_0000, 
             FILL_BUF    = 7'b000_0001,
             BW_8BPP     = 7'b000_0010,
             COL_8BPP    = 7'b000_0100,
             COL_16BPP_A = 7'b000_1000,
             COL_16BPP_B = 7'b001_0000,
             COL_24BPP   = 7'b010_0000,
             COL_32BPP   = 7'b100_0000;

  //---------------------------------------------
  // Variables
  //
  reg [31:0] databuffer;
  reg [ 7:0] Ra, Ga, Ba;
  reg [ 1:0] cnt;

  reg [ 6:0] fsm_state;

  //---------------------------------------------
  // Module body
  //

  // store word from pixelbuffer / wishbone input
  always @(posedge clk_i)
    if (vdat_buffer_rreq_o) databuffer <= vdat_buffer_d_i;


  //
  // generate statemachine
  //
  // extract color information from data buffer
  always @(posedge clk_i)
    if (rst_i)
    begin
        fsm_state          <= IDLE;
        vdat_buffer_rreq_o <= 1'b0;
        rgb_fifo_wreq_o    <= 1'b0;
        clut_req_o         <= 1'b0;
        cnt                <=  'h3;
    end
    else
    begin
        //default values (strobe signals)
        vdat_buffer_rreq_o <= 1'b0;
        rgb_fifo_wreq_o    <= 1'b0;
        clut_req_o         <= 1'b0;

        //FSM
        case (fsm_state)
          // idle state
          IDLE       : begin
                           if (!rgb_fifo_full_i && !vdat_buffer_empty_i)
                           begin
                               fsm_state          <= FILL_BUF;
                               vdat_buffer_rreq_o <= 1'b1;
                           end

                           //when entering from 8bpp_pseudo_color_mode
                           if (clut_ack_i)
                           begin
                               rgb_fifo_wreq_o <= 1'b1;
                               cnt <= cnt -1;
                           end

                           r_o <= clut_q_i[23:16];
                           g_o <= clut_q_i[15: 8];
                           b_o <= clut_q_i[ 7: 0];
                       end

          // fill data buffer
          FILL_BUF   : begin
                           case (color_depth_i)
                             2'b00: fsm_state <= pseudo_color_i ? COL_8BPP : BW_8BPP;
                             2'b01: fsm_state <= COL_16BPP_A;
                             2'b10: fsm_state <= COL_24BPP;
                             2'b11: fsm_state <= COL_32BPP;
                           endcase

                           // when entering from 8bpp_pseudo_color_mode
                           if (clut_ack_i)
                           begin
                               rgb_fifo_wreq_o <= 1'b1;
                               cnt <= cnt -1;
                           end

                           r_o <= clut_q_i[23:16];
                           g_o <= clut_q_i[15: 8];
                           b_o <= clut_q_i[ 7: 0];
                       end

          // 8 bits per pixel black-white
          BW_8BPP    : begin
                           if (!rgb_fifo_full_i)
                           begin
                               if (~|cnt)
                               begin
                                   fsm_state          <= !vdat_buffer_empty_i ? FILL_BUF : IDLE;
                                   vdat_buffer_rreq_o <= ~vdat_buffer_empty_i;
                               end

                               rgb_fifo_wreq_o <= 1'b1;
                               cnt <= cnt -1;
                           end

                           r_o <= databuffer >> (cnt * 8);
                           g_o <= databuffer >> (cnt * 8);
                           b_o <= databuffer >> (cnt * 8);
                       end

          // 8 bits per pixel pseudo-colour
          COL_8BPP   : begin
                           if (~|cnt)
                           begin
                               if (!rgb_fifo_full_i && !vdat_buffer_empty_i)
                               begin
                                   fsm_state          <= FILL_BUF;
                                   vdat_buffer_rreq_o <= 1'b1;
                               end
                               else
                                   fsm_state <= IDLE;
                           end

                           if (clut_ack_i)
                           begin
                               rgb_fifo_wreq_o <= 1'b1;
                               cnt <= cnt -1;
                           end

                           r_o <= clut_q_i[23:16];
                           g_o <= clut_q_i[15: 8];
                           b_o <= clut_q_i[ 7: 0];

                           clut_req_o <= ~rgb_fifo_full_i || (cnt[1] ^ cnt[0]);
                       end

          // 16 bits per pixel
          COL_16BPP_A: if (!rgb_fifo_full_i)
                       begin
                           fsm_state <= COL_16BPP_B;

                           rgb_fifo_wreq_o <= 1'b1;
                           cnt <= cnt -1;

                           //RGB656
                           r_o <= {databuffer[31:27], 3'h0};
                           g_o <= {databuffer[26:21], 2'h0};
                           b_o <= {databuffer[20:16], 3'h0};
                        end

          COL_16BPP_B: if (!rgb_fifo_full_i)
                       begin
                           if (!vdat_buffer_empty_i)
                           begin
                               fsm_state          <= FILL_BUF;
                               vdat_buffer_rreq_o <= 1'b1;
                           end
                           else
                               fsm_state <= IDLE;

                           rgb_fifo_wreq_o <= 1'b1;
                           cnt <= cnt -1;

                           //RGB656
                           r_o <= {databuffer[15:11], 3'h0};
                           g_o <= {databuffer[10: 5], 2'h0};
                           b_o <= {databuffer[ 4: 0], 3'h0};
                       end

          // 24 bits per pixel
          COL_24BPP  : if (!rgb_fifo_full_i)
                       begin
                           if      (cnt == 2'h1      ) fsm_state <= COL_24BPP; // stay in current state
                           else if (!vdat_buffer_empty_i) fsm_state <= FILL_BUF;
                           else                           fsm_state <= IDLE;

                           if (cnt != 2'h1 && !vdat_buffer_empty_i) vdat_buffer_rreq_o <= 1'b1;

                           rgb_fifo_wreq_o <= 1'b1;
                           cnt <= cnt -1;

                           case (cnt)
                             2'b11: begin
                                       r_o <= databuffer[31:24];
                                       g_o <= databuffer[23:16];
                                       b_o <= databuffer[15: 8];
                                       Ra  <= databuffer[ 7: 0];
                                    end

                             2'b10: begin
                                        r_o <= Ra;
                                        g_o <= databuffer[31:24];
                                        b_o <= databuffer[23:16];
                                        Ra  <= databuffer[15: 8];
                                        Ga  <= databuffer[ 7: 0];
                                    end

                             2'b01: begin
                                        r_o <= Ra;
                                        g_o <= Ga;
                                        b_o <= databuffer[31:24];
                                        Ra  <= databuffer[23:16];
                                        Ga  <= databuffer[15: 8];
                                        Ba  <= databuffer[ 7: 0];
                                    end

                             2'b00: begin
                                        r_o <= Ra;
                                        g_o <= Ga;
                                        b_o <= Ba;
                                    end
                           endcase
                       end

          // 32 bits per pixel
          COL_32BPP  : if (!rgb_fifo_full_i)
                       begin
                           if (!vdat_buffer_empty_i)
                           begin
                               fsm_state          <= FILL_BUF;
                               vdat_buffer_rreq_o <= 1'b1;
                           end
                           else
                              fsm_state <= IDLE;

                           rgb_fifo_wreq_o <= 1'b1;
                           cnt <= cnt -1;

                           r_o <= databuffer[23:16];
                           g_o <= databuffer[15: 8];
                           b_o <= databuffer[ 7: 0];
                       end
        endcase
    end


  // assign clut offset
  assign clut_offs_o = databuffer >> (cnt * 8);

endmodule


