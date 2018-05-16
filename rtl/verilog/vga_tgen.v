/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Timing Generator                                //
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
// FILE NAME      : vga_tgen.v
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
// PURPOSE  : Horizontal and Vertical Timing Generator
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : synchronous active high rst_i
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : no 
//   Scan Methodology    : na
//   Instantiations      : vga_vtim
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------


module vga_tgen(
  input         clk_i,
  input         clk_ena_i,
  input         rst_i,

  // horizontal timing settings inputs
  input  [ 7:0] thsync_i, // horizontal sync pule width (in pixels)
  input  [ 7:0] thgdel_i, // horizontal gate delay
  input  [15:0] thgate_i, // horizontal gate (number of visible pixels per line)
  input  [15:0] thlen_i,  // horizontal length (number of pixels per line)

  // vertical timing settings inputs
  input  [ 7:0] tvsync_i, // vertical sync pule width (in pixels)
  input  [ 7:0] tvgdel_i, // vertical gate delay
  input  [15:0] tvgate_i, // vertical gate (number of visible pixels per line)
  input  [15:0] tvlen_i,  // vertical length (number of pixels per line)

  // outputs
  output        eol_o,    // end of line
  output        eof_o,    // end of frame
  output        gate_o,   // vertical AND horizontal gate (logical AND function)

  output        hsync_o,  // horizontal sync pulse
  output        vsync_o,  // vertical sync pulse
  output        csync_o,  // composite sync
  output        blank_o   // blank signal
);

  //---------------------------------------------
  // variable declarations
  //
  wire hgate, vgate;


  //---------------------------------------------
  // module body
  //

  // hookup horizontal timing generator
  vga_vtim htim_inst (
    .clk_i   ( clk_i     ),
    .ena_i   ( clk_ena_i ),
    .rst_i   ( rst_i     ),
    .tsync_i ( thsync_i  ),
    .tgdel_i ( thgdel_i  ),
    .tgate_i ( thgate_i  ),
    .tlen_i  ( thlen_i   ),
    .sync_o  ( hsync_o   ),
    .gate_o  ( hgate     ),
    .done_o  ( eol_o     )
  );


  // hookup vertical timing generator
  wire vclk_ena = eol_o & clk_ena_i;

  vga_vtim vtim_inst (
    .clk_i   ( clk_i    ),
    .ena_i   ( vclk_ena ),
    .rst_i   ( rst_i    ),
    .tsync_i ( tvsync_i ),
    .tgdel_i ( tvgdel_i ),
    .tgate_i ( tvgate_i ),
    .tlen_i  ( tvlen_i  ),
    .sync_o  ( vsync_o  ),
    .gate_o  ( vgate    ),
    .done_o  ( eof_o    )
  );


  // assign outputs
  assign gate_o  = hgate & vgate;
  assign csync_o = hsync_o | vsync_o;
  assign blank_o = ~gate_o;

endmodule
