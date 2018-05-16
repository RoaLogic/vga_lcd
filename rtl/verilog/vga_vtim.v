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
// FILE NAME      : vga_vtim.v
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
// PURPOSE  : Timing Generator
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
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :
// -FHDR-------------------------------------------------------------


module vga_vtim (
  input             clk_i,   // master clock
  input             ena_i,   // count enable
  input             rst_i,   // synchronous active high reset

  input      [ 7:0] tsync_i, // sync duration
  input      [ 7:0] tgdel_i, // gate delay
  input      [15:0] tgate_i, // gate length
  input      [15:0] tlen_i,  // line time / frame time

  output reg        sync_o,  // synchronization pulse
  output reg        gate_o,  // gate
  output reg        done_o   // done with line/frame
);

  //---------------------------------------------
  // Constants
  //
  localparam [1:0] SYNC = 2'b00,
                   GDEL = 2'b01,
                   GATE = 2'b11,
                   LEN  = 2'b10;

  //---------------------------------------------
  // Variables
  //
  reg  [ 1:0] fsm_state;

  reg  [15:0] cnt,      cnt_len;
  wire [15:0] cnt_nxt,  cnt_len_next;
  wire        cnt_done, cnt_len_done;


  //---------------------------------------------
  // module body
  //

  assign {cnt_done,    cnt_nxt    } = {1'b0, cnt    } -1;
  assign {cnt_len_done,cnt_len_nxt} = {1'b0, cnt_len} -1;


  // State Machine
  always @(posedge clk_i)
    if (rst_i)
    begin
        fsm_state <= SYNC;
        cnt       <= tsync_i;
        cnt_len   <= tlen_i;
        sync_o    <= 1'b0;
        gate_o    <= 1'b0;
        done_o    <= 1'b0;
    end
    else if (ena_i)
    begin
       cnt     <= cnt_nxt;
       cnt_len <= cnt_len_nxt;
       done_o  <= 1'b0;

       case (fsm_state)
         SYNC: if (cnt_done)
               begin
                   fsm_state <= GDEL;
                   cnt       <= tgdel_i;
                   sync_o    <= 1'b0;
               end

         GDEL: if (cnt_done)
               begin
                   fsm_state <= GATE;
                   cnt       <= tgate_i;
                   gate_o    <= 1'b1;
               end

         GATE: if (cnt_done)
               begin
                   fsm_state <= LEN;
                   gate_o    <= 1'b0;
               end

         LEN : if (cnt_len_done)
               begin
                   fsm_state <= SYNC;
                   cnt       <= tsync_i;
                   cnt_len   <= tlen_i;
                   sync_o    <= 1'b1;
                   done_o    <= 1'b1;
               end
       endcase
   end

endmodule
