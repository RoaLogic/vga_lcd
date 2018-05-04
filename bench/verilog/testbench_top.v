/////////////////////////////////////////////////////////////////////
////                                                             ////
////  Top Level Test Bench                                       ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/vga_lcd/   ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Rudolf Usselmann                         ////
////                    rudi@asics.ws                            ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: test_bench_top.v,v 1.10 2003-09-23 13:09:25 markom Exp $
//
//  $Date: 2003-09-23 13:09:25 $
//  $Revision: 1.10 $
//  $Author: markom $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.9  2003/08/22 07:12:31  rherveille
//               Enabled Fifo Underrun test
//
//               Revision 1.8  2003/05/07 14:39:19  rherveille
//               Added DVI tests
//
//               Revision 1.7  2003/05/07 09:45:28  rherveille
//               Numerous updates and added checks
//
//               Revision 1.6  2003/03/19 17:22:19  rherveille
//               Added WISHBONE revB.3 sanity checks
//
//               Revision 1.5  2003/03/19 12:20:53  rherveille
//               Changed timing section in VGA core, changed testbench accordingly.
//               Fixed bug in 'timing check' test.
//
//               Revision 1.4  2002/02/07 05:38:32  rherveille
//               Added wb_ack delay section to testbench
//
//
//
//
//

`timescale 1ns/10ps

module testbench_top;

reg		clk;
reg		rst;

parameter	LINE_FIFO_AWIDTH = 7;

wire		interrupt;
wire	[31:0]	wb_addr_o;
wire	[31:0]	wb_data_i;
wire	[31:0]	wb_data_o;
wire	[3:0]	wb_sel_o;
wire		wb_we_o;
wire		wb_stb_o;
wire		wb_cyc_o;
wire	[2:0]	wb_cti_o;
wire	[1:0]	wb_bte_o;
wire		wb_ack_i;
wire		wb_err_i;
wire	[31:0]	wb_addr_i;
wire	[31:0]	wbm_data_i;
wire	[3:0]	wb_sel_i;
wire		wb_we_i;
wire		wb_stb_i;
wire		wb_cyc_i;
wire		wb_ack_o;
wire		wb_rty_o;
wire		wb_err_o;
reg		pclk_i;
wire		pclk;
wire    	hsync;
wire		vsync;
wire		csync;
wire		blanc;
wire	[7:0]	red;
wire	[7:0]	green;
wire	[7:0]	blue;
wire		dvi_pclk_p_o;
wire		dvi_pclk_m_o;
wire		dvi_hsync_o;
wire		dvi_vsync_o;
wire		dvi_de_o;
wire	[11:0]	dvi_d_o;


wire vga_stb_i;
wire clut_stb_i;

reg		scen;

// Test Bench Variables
integer		wd_cnt;
integer		error_cnt;

// Misc Variables
reg	[31:0]	data;
reg	[31:0]	pattern;
reg		interrupt_warn;

integer		n;
integer		mode;

reg	[7:0]	thsync, thgdel;
reg	[15:0]	thgate, thlen;
reg	[7:0]	tvsync, tvgdel;
reg	[15:0]	tvgate, tvlen;
reg		hpol;
reg		vpol;
reg		cpol;
reg		bpol;
integer		p, l;
reg	[31:0]	pn;
reg	[31:0]	pra, paa, tmp;
reg	[23:0]	pd;
reg	[1:0]	cd;
reg		pc;
reg	[31:0]	vbase;
reg	[31:0]	cbase;
reg	[31:0]	vbara;
reg	[31:0]	vbarb;
reg	[7:0]	bank;

/////////////////////////////////////////////////////////////////////
//
// Defines
//

`define	CTRL		32'h0000_0000
`define	STAT		32'h0000_0004
`define	HTIM		32'h0000_0008
`define	VTIM		32'h0000_000c
`define	HVLEN		32'h0000_0010
`define	VBARA		32'h0000_0014
`define	VBARB		32'h0000_0018

`define USE_VC		1

parameter PCLK_C = 30;

/////////////////////////////////////////////////////////////////////
//
// Simulation Initialization and Start up Section
//

initial
   begin
	$timeformat (-9, 1, " ns", 12);
	$display("\n\n");
	$display("******************************************************");
	$display("* WISHBONE VGA/LCD Controller Simulation started ... *");
	$display("******************************************************");
	$display("\n");
`ifdef WAVES
  	$shm_open("waves");
	$shm_probe("AS",test,"AS");
	$display("INFO: Signal dump enabled ...\n\n");
`endif
	scen = 0;
	error_cnt = 0;
   	clk = 0;
	pclk_i = 0;
   	rst = 0;
	interrupt_warn=1;

   	repeat(20) @(posedge clk);
   	rst = 1;
   	repeat(20) @(posedge clk);

	// HERE IS WHERE THE TEST CASES GO ...
//	reg_test;
//	tim_test;
	pd1_test;
	pd2_test;
	ur_test;

   	repeat(10)	@(posedge clk);
   	$finish;
   end

/////////////////////////////////////////////////////////////////////
//
// Sync Monitor
//

`ifdef VGA_12BIT_DVI
sync_check #(PCLK_C) ucheck(
`else
sync_check #(PCLK_C) ucheck(
`endif
		.pclk(		pclk		),
		.rst(		rst		),
		.enable(	scen		),
		.hsync(		hsync		),
		.vsync(		vsync		),
		.csync(		csync		),
		.blanc(		blanc		),
		.hpol(		hpol		),
		.vpol(		vpol		),
		.cpol(		cpol		),
		.bpol(		bpol		),
		.thsync(	thsync		),
		.thgdel(	thgdel		),
		.thgate(	thgate		),
		.thlen(		thlen		),
		.tvsync(	tvsync		),
		.tvgdel(	tvgdel		),
		.tvgate(	tvgate		),
		.tvlen(		tvlen		) );

/////////////////////////////////////////////////////////////////////
//
// Video Data Monitor
//

/////////////////////////////////////////////////////////////////////
//
// WISHBONE revB.3 checker
//

wb_b3_check u_wb_check (
	.clk_i ( clk      ),
	.cyc_i ( wb_cyc_o ),
	.stb_i ( wb_stb_o ),
	.cti_i ( wb_cti_o ),
	.bte_i ( wb_bte_o ),
	.we_i  ( wb_we_o  ),
	.ack_i ( wb_ack_i ),
	.err_i ( wb_err_i ),
	.rty_i ( 1'b0     ) );


/////////////////////////////////////////////////////////////////////
//
// Watchdog Counter
//

always @(posedge clk)
	if(wb_cyc_i | wb_cyc_o | wb_ack_i | wb_ack_o | hsync)
	  wd_cnt <= 0;
	else
	  wd_cnt <= wd_cnt + 1;


always @(wd_cnt)
	if(wd_cnt>9000)
	   begin
		$display("\n\n*************************************\n");
		$display("ERROR: Watch Dog Counter Expired\n");
		$display("*************************************\n\n\n");
		$finish;
	   end


always @(posedge interrupt)
  if(interrupt_warn)
   begin
	$display("\n\n*************************************\n");
	$display("WARNING: Recieved Interrupt (%0t)", $time);
	$display("*************************************\n\n\n");
   end

always #2.4 clk = ~clk;
always #(PCLK_C/2) pclk_i = ~pclk_i;

  ///////////////////////////////////////////////////////////////////
  //
  // WISHBONE VGA/LCD IP Core
  //

  /** DUT
   */
  vga_enh_top #(
    1'b0,
    LINE_FIFO_AWIDTH
  )
  dut (
    .wb_clk_i     ( clk             ),
    .wb_rst_i     ( 1'b0            ),
    .rst_i        ( rst             ),
    .wb_inta_o    ( interrupt       ),

    //-- slave signals
    .wbs_adr_i    ( wb_addr_i[11:0] ),
    .wbs_dat_i    ( wb_data_i       ),
    .wbs_dat_o    ( wb_data_o       ),
    .wbs_sel_i    ( wb_sel_i        ),
    .wbs_we_i     ( wb_we_i         ),
    .wbs_stb_i    ( wb_stb_i        ),
    .wbs_cyc_i    ( wb_cyc_i        ),
    .wbs_ack_o    ( wb_ack_o        ),
    .wbs_rty_o    ( wb_rty_o        ),
    .wbs_err_o    ( wb_err_o        ),

    //-- master signals
    .wbm_adr_o    ( wb_addr_o[31:0] ),
    .wbm_dat_i    ( wbm_data_i      ),
    .wbm_sel_o    ( wb_sel_o        ),
    .wbm_we_o     ( wb_we_o         ),
    .wbm_stb_o    ( wb_stb_o        ),
    .wbm_cyc_o    ( wb_cyc_o        ),
    .wbm_cti_o    ( wb_cti_o        ),
    .wbm_bte_o    ( wb_bte_o        ),
    .wbm_ack_i    ( wb_ack_i        ),
    .wbm_err_i    ( wb_err_i        ),

    //-- VGA signals
    .clk_p_i      ( pclk_i          ),
`ifdef VGA_12BIT_DVI
    .dvi_pclk_p_o ( dvi_pclk_p_o    ),
    .dvi_pclk_m_o ( dvi_pclk_m_o    ),
    .dvi_hsync_o  ( dvi_hsync_o     ),
    .dvi_vsync_o  ( dvi_vsync_o     ),
    .dvi_de_o     ( dvi_de_o        ),
    .dvi_d_o      ( dvi_d_o         ),
`endif

    .clk_p_o      ( pclk            ),
    .hsync_pad_o  ( hsync           ),
    .vsync_pad_o  ( vsync           ),
    .csync_pad_o  ( csync           ),
    .blank_pad_o  ( blanc           ),
    .r_pad_o      ( red             ),
    .g_pad_o      ( green           ),
    .b_pad_o      ( blue            )
  );



wb_mast	m0(	.clk(		clk		),
		.rst(		rst		),
		.adr(		wb_addr_i	),
		.din(		wb_data_o	),
		.dout(		wb_data_i	),
		.cyc(		wb_cyc_i	),
		.stb(		wb_stb_i	),
		.sel(		wb_sel_i	),
		.we(		wb_we_i		),
		.ack(		wb_ack_o	),
		.err(		wb_err_o	),
		.rty(		1'b0		)
		);

wb_slv #(24) s0(.clk(		clk		),
		.rst(		rst		),
		.adr(		{1'b0, wb_addr_o[30:0]}	),
		.din(		32'h0		),
		.dout(		wbm_data_i	),
		.cyc(		wb_cyc_o	),
		.stb(		wb_stb_o	),
		.sel(		wb_sel_o	),
		.we(		wb_we_o		),
		.ack(		wb_ack_i	),
		.err(		wb_err_i	),
		.rty(				)
		);

`include "tests.v"

endmodule
