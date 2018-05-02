/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//             O p e n C o r e s               `---'               //
//                                                                 //
//   VGA/LCD Core; Clock Generator                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2003 Richard Herveille, OpenCores     //
//             Copyright (C) 2018 ROA Logic BV                     //
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
// FILE NAME      : vga_clkgen.v
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
// PURPOSE  : Clock generation 
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  HAS_DVI           [0,1]  Implement DVI clocks?    1
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : syncronous, active high
//   Clock Domains       : pclk_i
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : no 
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               : This is a clock generator block, see note
// -FHDR-------------------------------------------------------------


// N O T E //////////////////////////////////////////////////////////
//                                                                 //
// !! SPECIAL LOGIC, USE PRECAUTION DURING SYNTHESIS AND LAYOUT !! //
//                                                                 //
// This is a clock generation circuit. Although all output clocks  //
// are generated synchronous to the input clock, special care must //
// be taken during synthesis and physical layout.                  //
//                                                                 //
// Alternatively replace this block with a technology specific     //
// implementation.                                                 //
//                                                                 //
/////////////////////////////////////////////////////////////////////


module vga_clkgen #(
  parameter HAS_DVI = 1
)
(
  // inputs & outputs
  input      pclk_i,       // pixel clock in
  input      rst_i,        // synchronous active high reset input

  output reg pclk_o,       // pixel clock out

  output reg dvi_pclk_p_o  // dvi cpclk+ output
  output reg dvi_pclk_n_o  // dvi cpclk- output

  output reg pclk_ena_o    // pixel clock enable output
);


//////////////////////////////////
//
// module body
//

  // These should be registers in or near IO buffers
  always @(posedge pclk_i)
    if (rst_i)
    begin
        dvi_pclk_p_o <= 1'b0;
        dvi_pclk_m_o <= 1'b0;
    end
    else
    begin
        dvi_pclk_p_o <= ~dvi_pclk_p_o;
        dvi_pclk_m_o <=  dvi_pclk_p_o;
    end

generate
  if (HAS_DVI == 1)
  begin
      // DVI circuit
      // pixel clock output is half of the pixel clock input

      always @(posedge pclk_i)
        if (rst_i) pclk_o <=  1'b0;
        else       pclk_o <= ~pclk_o;


      always @(posedge pclk_i)
        if (rst_i) pclk_ena_o <=  1'b1;
        else       pclk_ena_o <= ~pclk_ena_o;
  end
  else
  begin
      // No DVI circuit
      // Simply reroute the pixel input clock input

      always @* pclk_o     = pclk_i;
      always @* pclk_ena_o = 1'b1;
  end
endgenerate

endmodule

