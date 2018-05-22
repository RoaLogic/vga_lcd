/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Cycle Shared Memory                             //
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
// FILE NAME      : vga_csm_pb.v
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
// PURPOSE  : Cycle Shared Memory 
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  DWIDTH            0+     Number of data bits      32      bits
//  AWIDTH            0+     Number of address bits   8       bits
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : none
//   Clock Domains       : clk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : no 
//   Scan Methodology    : na
//   Instantiations      : generic_spram
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------

module vga_csm_pb #(
  DWIDTH = 32, // databus width
  AWIDTH = 8   // address bus width
)
(
  input                  clk_i,  // clock input

  // port0 connections
  input  [AWIDTH   -1:0] adr0_i, // address input
  input  [DWIDTH   -1:0] dat0_i, // data input
  output [DWIDTH   -1:0] dat0_o, // data output
  input                  we0_i,  // write enable input
  input                  req0_i, // access request input
  output                 ack0_o, // access acknowledge output

  // port1 connections
  input  [AWIDTH   -1:0] adr1_i, // address input
  input  [DWIDTH   -1:0] dat1_i, // data input
  output [DWIDTH   -1:0] dat1_o, // data output
  input                  we1_i,  // write enable input
  input                  req1_i, // access request input
  output                 ack1_o // access acknowledge output
);

  //---------------------------------------------
  // variable declarations
  //

  // multiplexor select signal
  wire acc0, acc1;
  reg  dacc0, dacc1;
  wire sel0, sel1;
  reg  ack0, ack1;
	
  // memory signal
  wire [AWIDTH -1:0] mem_adr;
  wire [DWIDTH -1:0] mem_d,
                     mem_q;
  wire               mem_we;


  //---------------------------------------------
  // module body
  //

  // generate multiplexor select signal
  assign acc0 = req0_i;
  assign acc1 = req1_i && !sel0;


  always@(posedge clk_i)
    begin
        dacc0 <= acc0 & ~ack0_o;
        dacc1 <= acc1 & ~ack1_o;
    end


  assign sel0 = acc0 & ~dacc0;
  assign sel1 = acc1 & ~dacc1;


  // mux memory ports
  assign mem_adr = sel0 ? adr0_i : adr1_i;
  assign mem_d   = sel0 ? dat0_i : dat1_i;
  assign mem_we  = sel0 ? req0_i & we0_i : req1_i & we1_i;


  // hookup generic synchronous single port memory
  generic_spram #(AWIDTH, DWIDTH) clut_mem(
    .clk ( clk_i   ),
    .rst ( 1'b0    ),       // no reset
    .ce  ( 1'b1    ),       // always enable memory
    .we  ( mem_we  ),
    .oe  ( 1'b1    ),       // always output data
    .addr( mem_adr ),
    .di  ( mem_d   ),
    .d_o ( mem_q   )
  );


  // generator output signals
  always@(posedge clk_i)
    begin
        ack0 <= sel0 & ~ack0_o;
        ack1 <= sel1 & ~ack1_o;
    end


  // assign DAT_O outputs
  assign dat0_o = mem_q;
  assign dat1_o = mem_q;


  // generate ack outputs
  assign ack0_o = (sel0 & we0_i) | ack0;
  assign ack1_o = (sel1 & we1_i) | ack1;
endmodule
