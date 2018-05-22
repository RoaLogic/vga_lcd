/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Cursor Color Registers                          //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2002 Richard Herveille, OpenCores     //
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
// FILE NAME      : vga_cur_cregs.v
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
// PURPOSE  : Cursor Color Registers 
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : none
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : no 
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------

module vga_cur_cregs (
  input             clk_i,         // master clock input

  // host interface
  input             hsel_i,        // host select input
  input      [ 2:0] hadr_i,        // host address input
  input             hwe_i,         // host write enable input
  input      [31:0] hdat_i,        // host data in
  output reg [31:0] hdat_o,        // host data out
  output reg        hack_o,        // host acknowledge out

  // cursor processor interface
  input      [ 3:0] cadr_i,        // cursor address in
  output reg [15:0] cdat_o         // cursor data out
);

  //---------------------------------------------
  // variable declarations
  //
  reg  [31:0] cregs [7:0];  // color registers
  wire [31:0] temp_cdat;


  //---------------------------------------------
  // module body
  //


  // Host Interface
  always@(posedge clk_i)
    if (hsel_i && hwe_i) cregs[hadr_i] <= hdat_i;


  always@(posedge clk_i)
    hdat_o <= cregs[hadr_i];


  always@(posedge clk_i)
    hack_o <= hsel_i & ~hack_o;


  // Cursor Processor Interface
  assign temp_cdat = cregs[ cadr_i[3:1] ];


  always@(posedge clk_i)
    cdat_o <= cadr_i[0] ? temp_cdat[31:16] : temp_cdat[15:0];

endmodule

