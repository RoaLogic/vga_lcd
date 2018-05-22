/////////////////////////////////////////////////////////////////////
////                                                             ////
////  VGA/LCD Test Library                                       ////
////                                                             ////
////  Authors: Rudolf Usselmann, Richard Herveille               ////
////           rudi@asics.ws                                     ////
////                                                             ////
////                                                             ////
////  Original at: http://www.opencores.org/cores/vga_lcd        ////
////  Latest at  : https://github.com/RoaLogic/vga_lcd           ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2001 Rudolf Usselmann                         ////
////                    rudi@asics.ws                            ////
//// Copyright (C) 2018 Richard Herveille                        ////
////                    www.roalogic.com                         ////
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


task show_errors;
begin
    $display("\n");
    $display("     +--------------------+");
    $display("     |  Total ERRORS: %0d   |", error_cnt);
    $display("     +--------------------+");
end
endtask


/* Register Test
 * reg_test
 */
task check;
  input [31:0] addr;
  input [31:0] edata;
  input [31:0] mask;
  input [39:0] name;

  reg [31:0] data;

  begin
      m0.wb_rd1( addr, 4'hf, data );
      if(( (data & mask) != (edata & mask)) | ((^data) === 1'bx) )
      begin
          $display("ERROR: %s Reg: Value Mismatch. Expected %h, Got %h (%0t)",
            name, edata & mask, data, $time);
          error_cnt = error_cnt + 1;
      end
  end
endtask

task reg_test;
  reg [31:0] data;
  reg [31:0] pattern;
  integer    n;

  begin
      $display("\n\n");
      $display("-------------------------------------------------");
      $display("- Register Test                                 -");
      $display("-------------------------------------------------\n");

      // Check reset Values
      $display("Testing Reset Values ...");
      check( `CTRL,  0, 32'h0000_ffff, "CTRL ");
      check( `STAT,  0, 32'h0000_0073, "STAT ");
      check( `HTIM,  0, 32'hffff_ffff, "HTIM ");
      check( `VTIM,  0, 32'hffff_ffff, "VTIM ");
      check( `HVLEN, 0, 32'hffff_ffff, "HVLEN");
      check( `VBARA, 0, 32'hffff_ffff, "VBARA");
      check( `VBARB, 0, 32'hffff_ffff, "VBARB");

      $display("Testing Pattern R/W ...");
      for(n=0; n<6; n=n+1)
      begin
          case(n)
             0: pattern = 32'h0000_0000;
             1: pattern = 32'hffff_ffff;
             2: pattern = 32'haaaa_aaaa;
             3: pattern = 32'h5555_5555;
             4: pattern = 32'hcccc_cccc;
             5: pattern = 32'h3333_3333;
          endcase

          m0.wb_wr1( `CTRL, 4'hf, pattern );
          check( `CTRL,  pattern, 32'hffff_ff9f, "CTRL ");

          m0.wb_wr1( `HTIM, 4'hf, pattern );
          check( `HTIM,  pattern, 32'hffff_ffff, "HTIM ");

          m0.wb_wr1( `VTIM, 4'hf, pattern );
          check( `VTIM,  pattern, 32'hffff_ffff, "VTIM ");

          m0.wb_wr1( `HVLEN, 4'hf, pattern );
          check( `HVLEN, pattern, 32'hffff_ffff, "HVLEN");

          m0.wb_wr1( `VBARA, 4'hf, pattern );
          check( `VBARA, pattern, 32'hffff_fffc, "VBARA");

          m0.wb_wr1( `VBARB, 4'hf, pattern );
          check( `VBARB, pattern, 32'hffff_fffc, "VBARB");
      end

      repeat(10) @(posedge clk);

      show_errors;
      $display("-------------------------------------------");
      $display("- Register Test DONE ...                  -");
      $display("-------------------------------------------\n\n");
  end
endtask






/* Timing Test
 * tim_test
 */
task tim_test;
  integer mode;

  begin
      $display("\n\n");
      $display("-------------------------------------------------");
      $display("- Timing Test                                   -");
      $display("-------------------------------------------------\n");

      s0.fill_mem(0);

      repeat(10) @(posedge clk);

      m0.wb_wr1( `VBARA, 4'hf, 0 );
      m0.wb_wr1( `VBARB, 4'hf, 0 );


      mode = 2;
      for(mode=0;mode<6;mode=mode+1)
      begin
          // reset core
          scen = 0;
          m0.wb_wr1( `CTRL,  4'hf, 32'h0000_0000);
          repeat(10) @(posedge clk);

          $display("Mode: %0d", mode);

          case(mode)
            0: begin
                   thsync = 0;
                   thgdel = 0;
                   thgate = 319; // gate = 320
                   thlen  = 345;

                   tvsync = 0;
                   tvgdel = 0;
                   tvgate = 239; // vgate = 240
                   tvlen  = 245;

                   hpol = 0;
                   vpol = 0;
                   cpol = 0;
                   bpol = 0;
               end
            1: begin
                   thsync = 18;
                   thgdel = 18;
                   thgate = 319; // gate = 320
                   thlen  = 390;

                   tvsync = 18;
                   tvgdel = 18;
                   tvgate = 239; // vgate = 240
                   tvlen  = 290;

                   hpol = 1;
                   vpol = 0;
                   cpol = 0;
                   bpol = 0;
               end
            2: begin
                   thsync = 1;
                   thgdel = 1;
                   thgate = 639; // hgate = 640
                   thlen  = 644;

                   tvsync = 1;
                   tvgdel = 1;
                   tvgate = 479; // vgate = 480
                   tvlen  = 484;

                   hpol = 0;
                   vpol = 1;
                   cpol = 0;
                   bpol = 0;
               end
            3: begin
                   thsync = 0;
                   thgdel = 2;
                   thgate = 799; // hgate = 800
                   thlen  = 804;

                   tvsync = 0;
                   tvgdel = 2;
                   tvgate = 599; // vgate = 600
                   tvlen  = 604;

                   hpol = 0;
                   vpol = 0;
                   cpol = 1;
                   bpol = 0;
               end
            4: begin
                   thsync = 3;
                   thgdel = 2;
                   thgate = 799; // hgate = 800
                   thlen  = 807;

                   tvsync = 2;
                   tvgdel = 2;
                   tvgate = 599; // vgate = 600
                   tvlen  = 606;

                   hpol = 0;
                   vpol = 0;
                   cpol = 0;
                   bpol = 1;
               end
            5: begin
                   thsync = 6;
                   thgdel = 2;
                   thgate = 799; // hgate = 800
                   thlen = 810;

                   tvsync = 4;
                   tvgdel = 2;
                   tvgate = 599; // vgate = 600
                   tvlen = 608;

                   hpol = 1;
                   vpol = 1;
                   cpol = 1;
                   bpol = 1;
               end
          endcase

          //Program registers and enable video
          m0.wb_wr1( `HTIM,  4'hf, {thsync, thgdel, thgate} );
          m0.wb_wr1( `VTIM,  4'hf, {tvsync, tvgdel, tvgate} );
          m0.wb_wr1( `HVLEN, 4'hf, {thlen, tvlen} );
          m0.wb_wr1( `CTRL,  4'hf, {
                     16'h0,
                     bpol,
                     cpol,
                     vpol,
                     hpol,
                     1'b0, // PC
                     2'h0, // CD
                     2'h0, // VBL
                     2'h0, // Reserved
                     5'h01 // Bank Switch, INT, VideoEn
                     }
          );

          repeat(2) @(posedge vsync);
          scen = 1;
          repeat(4) @(posedge vsync);
      end //next mode

      scen = 0;
      repeat(10) @(posedge clk);

      show_errors;
      $display("-------------------------------------------------");
      $display("- Timing Test DONE ...                          -");
      $display("-------------------------------------------------\n\n");
  end
endtask



/** Pixel Data Test 1
 * pd1_test
 */
task pd1_test;
  integer    mode;
  integer    n, p, l;
  reg [31:0] pn;
  reg [31:0] pra,
             paa,
             tmp;
  reg [23:0] pd;
  reg [ 1:0] cd;    //color depth
  reg        pc;    //pseudo color
  reg [31:0] data;
  reg [31:0] cbar;
  reg [ 7:0] vbl;
  reg [ 5:0] delay;

  begin
      $display("\n\n");
      $display("---------------------------------------------------");
      $display("- Pixel Data Test 1                               -");
      $display("---------------------------------------------------\n");

      m0.wb_wr1( `VBARA, 4'hf, 0 );
      m0.wb_wr1( `VBARB, 4'hf, 123456 );

      cbar = 32'h0000_0800;

      thsync = 0;
      thgdel = 0;
      thgate = 320;
      thlen  = 345;

      tvsync = 0;
      tvgdel = 0;
      tvgate = 240;
      tvlen  = 245;

      thsync = 39;
      thgdel = 124;
      thgate = 646;
      thlen  = 832;

      tvsync = 2;
      tvgdel = 25;
      tvgate = 484;
      tvlen  = 520;

      thsync = 6;
      thgdel = 20;
      thgate = 319;
      thlen  = 390;

      tvsync = 1;
      tvgdel = 8;
      tvgate = 239;
      tvlen  = 280;

      hpol = 0;
      vpol = 0;
      cpol = 0;
      bpol = 0;

      m0.wb_wr1( `HTIM,  4'hf, {thsync, thgdel, thgate} );
      m0.wb_wr1( `VTIM,  4'hf, {tvsync, tvgdel, tvgate} );
      m0.wb_wr1( `HVLEN, 4'hf, {thlen , tvlen} );

      mode  = 0;
      vbl   = 1;
      delay = 1;

      for(delay=0; delay<6; delay=delay+1)
      begin
          s0.set_delay(delay);

          for(vbl=0; vbl <4;vbl=vbl+1 )
          for(mode=0;mode<4;mode=mode+1)
          begin
              // -------------------------------
              // Turn Off VGA before Mode Change

              m0.wb_wr1( `CTRL,  4'hf, {
                         16'h0,   // Reserved
                         bpol,
                         cpol,
                         vpol,
                         hpol,
                         pc,      // PC
                         cd,	  // CD
                         2'h0,    // VBL
                         1'b0,    // CBSWE
                         1'b0,    // VBSWE
                         1'b0,    // CBSIE
                         1'b0,    // VBSIE
                         1'b0,    // HIE
                         1'b0,    // VIE
                         1'b0     // Video Enable
                         }
              );

              //fill video memory
              s0.fill_mem(1);


`ifdef USE_VC
              // Fill internal Color Lookup Table
              repeat(10) @(posedge clk);
              for(n=0;n<512;n=n+1)
              begin
                  data = s0.mem[ cbar[31:2] + n];
                  m0.wb_wr1( 32'h0000_0800 + (n*4), 4'hf, data );
              end
              repeat(10) @(posedge clk);
`endif

              //set mode options
              case(mode)
                0: begin          //24bpp
                       cd = 2'h2;
                       pc = 1'b0;
                   end
                1: begin          //8bpp BW
                       cd = 2'h0;
                       pc = 1'b0;
                   end
                2: begin          //8bpp pseudo-color
                       cd = 2'h0;
                       pc = 1'b1;
                   end
                3: begin          //16bpp
                       cd = 2'h1;
                       pc = 1'b0;
                   end
                4: begin          //32bpp
                       cd = 2'h3;
                       pc = 1'b0;
                   end
              endcase


              // -------------------------------
              // Turn VGA back On ...
              m0.wb_wr1( `CTRL,  4'hf, {
                         16'h0,   // Reserved
                         bpol,
                         cpol,
                         vpol,
                         hpol,
                         pc,      // PC
                         cd,      // CD
                         vbl[1:0],// VBL
                         1'b0,    // Reserved
                         1'b0,    // CBSWE
                         1'b0,    // VBSWE
                         1'b0,    // BSIE
                         1'b0,    // HIE
                         1'b0,    // VIE
                         1'b1     // Video Enable
                         }
              );

              $display("VBL: %0d, Mode: %0d", vbl, mode);
              repeat(2) @(posedge vsync);

              for(l=0;l<tvgate  ;l=l+1)  //for each line
              for(p=0;p<thgate+1;p=p+1) //for each pixel
              begin
                  while(blanc) @(posedge pclk);  // wait for viewable data

                  //$display("pixel=%0d, line=%0d, (%0t)",p,l,$time);

                  // Depending on Mode, determine pixel data
                  // pixel number = line * (thgate + 1) + p
                  pn = l * (thgate + 1) + p;

                  case(mode)
                    0: begin //24bpp
                           pra = pn[31:2] * 3; // Pixel relative Address
                           paa = pra + 0;      // Pixel Absolute Address

                           // Pixel Data
                           case(pn[1:0])
                             0: begin
                                    tmp = s0.mem[paa];
                                    pd = tmp[31:8];
                                end
                             1: begin
                                    tmp = s0.mem[paa];
                                    pd[23:16] = tmp[7:0];
                                    tmp = s0.mem[paa+1];
                                    pd[15:0] = tmp[31:16];
                                end
                             2: begin
                                    tmp = s0.mem[paa+1];
                                    pd[23:8] = tmp[15:0];
                                    tmp = s0.mem[paa+2];
                                    pd[7:0] = tmp[31:24];
                                end
                             3: begin
                                    tmp = s0.mem[paa+2];
                                    pd = tmp[23:0];
                                end
                           endcase
                       end

                    1: begin // 8 bit/pixel grayscale mode
                           pra = pn[31:2]; // Pixel relative Address
                           paa = pra + 0;  // Pixel Absolute Address

                           // Pixel Data
                           case(pn[1:0])
                             0: begin
                                    tmp = s0.mem[paa];
                                    pd = { tmp[31:24], tmp[31:24], tmp[31:24] };
                                end
                             1: begin
                                    tmp = s0.mem[paa];
                                    pd = { tmp[23:16], tmp[23:16], tmp[23:16] };
                                end
                             2: begin
                                    tmp = s0.mem[paa];
                                    pd = { tmp[15:8], tmp[15:8], tmp[15:8] };
                                end
                             3: begin
                                    tmp = s0.mem[paa];
                                    pd = { tmp[7:0], tmp[7:0], tmp[7:0] };
                                end
                           endcase
                       end

                    2: begin // 8 bit/pixel Pseudo Color mode
                           pra = pn[31:2]; // Pixel relative Address
                           paa = pra + 0;  // Pixel Absolute Address

                           //Pixel Data
                           case(pn[1:0])
                             0: begin
                                    tmp = s0.mem[paa];
                                    tmp = s0.mem[cbar[31:2] + tmp[31:24]];
                                    pd = tmp[23:0];
                                end
                             1: begin
                                    tmp = s0.mem[paa];
                                    tmp = s0.mem[cbar[31:2] + tmp[23:16]];
                                    pd = tmp[23:0];
                                end
                             2: begin
                                    tmp = s0.mem[paa];
                                    tmp = s0.mem[cbar[31:2] + tmp[15:8]];
                                    pd = tmp[23:0];
                                end
                             3: begin
                                    tmp = s0.mem[paa];
                                    tmp = s0.mem[cbar[31:2] + tmp[7:0]];
                                    pd = tmp[23:0];
                                end
                           endcase
                       end

                    3: begin // 16 bit/pixel mode
                           pra = pn[31:1]; // Pixel relative Address
                           paa = pra + 0;  // Pixel Absolute Address

                           //Pixel Data
                           case(pn[0])
                             0: begin
                                    tmp = s0.mem[paa];
                                    tmp[15:0] = tmp[31:16];
                                    pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
                                end
                             1: begin
                                    tmp = s0.mem[paa];
                                    pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
                                end
                           endcase
                       end

                    4: begin // 32 bit/pixel mode
                           pra = pn;       // Pixel relative Address
                           paa = pra + 0;  // Pixel Absolute Address

                           //Pixel Data
                           tmp = s0.mem[paa];
                           pd = tmp[23:0];
                       end

                  endcase


                  //Check Results
                  if(pd !== {red, green, blue} )
                  begin
                      $display("ERROR: Pixel Data Mismatch: Expected: %h, Got: %h %h %h",
                                pd, red, green, blue);
                      $display("       pixel=%0d, line=%0d, (%0t)",p,l,$time);
                      error_cnt = error_cnt + 1;
                      if(error_cnt > 10) $stop;
                  end

                  @(posedge pclk);
              end //next p/l
          end //next vbl/mode
      end //next delay

      show_errors;
      $display("-------------------------------------------------");
      $display("- Pixel Data Test 1 DONE ...                    -");
      $display("-------------------------------------------------\n\n");

  end
endtask


/** Pixel Data Test 2
 * pd2_test
 *
 * The new video timing generator generates a V/HSYNC at the end of the
 * timing interval. Therefore this test is slightly different than the
 * one found on OpenCores
 */
task pd2_test;
  integer    mode;
  integer    p, l;
  reg [31:0] pn;
  reg [31:0] pra, paa, tmp;
  reg [23:0] pd;
  reg [ 1:0] cd;
  reg        pc;
  reg [31:0] cbar;
  reg [31:0] vbase;
  reg [31:0] cbase;
  reg [31:0] vbara;
  reg [31:0] vbarb;
  reg [ 7:0] bank, vbl;
  reg [ 5:0] delay;

  begin
      $display("\n\n");
      $display("---------------------------------------------------");
      $display("- Pixel Data Test 2                               -");
      $display("---------------------------------------------------\n");

      s0.fill_mem(1);

      repeat(10) @(posedge clk);

      vbara = 32'h0000_0000;
      vbarb = 32'h0040_0000;
      cbar  = 32'h0000_0800;

      m0.wb_wr1( `VBARA, 4'hf, vbara );
      m0.wb_wr1( `VBARB, 4'hf, vbarb );

      thsync = 6;
      thgdel = 20;
      thgate = 319;
      thlen = 390;

      tvsync = 1;
      tvgdel = 8;
      tvgate = 239;
      tvgate = 240;
      tvlen = 280;

      hpol = 0;
      vpol = 0;
      cpol = 0;
      bpol = 0;

      m0.wb_wr1( `HTIM,  4'hf, {thsync, thgdel, thgate} );
      m0.wb_wr1( `VTIM,  4'hf, {tvsync, tvgdel, tvgate} );
      m0.wb_wr1( `HVLEN, 4'hf, {thlen, tvlen} );


`ifdef USE_VC
      // Fill internal Color Lookup Table
      repeat(10) @(posedge clk);

      for(n=0;n<512;n=n+1)
      begin
          data = s0.mem[ cbar[31:2] + n];
          m0.wb_wr1( 32'h0000_0800 + (n*4), 4'hf, data );
      end

      repeat(10) @(posedge clk);
`endif


      vbl   = 3;
      mode  = 0;
      delay = 2;

      for (delay=0; delay<6; delay=delay+1)
      begin
          s0.set_delay(delay);

          for(vbl=0; vbl<4; vbl=vbl+1)
          for(mode=0;mode<=4;mode=mode+1)
          begin
              //turn off VGA before mode change
              m0.wb_wr1( `CTRL,  4'hf, 32'h0);

              repeat(100) @(posedge clk);

              case(mode)
                0: begin //24bpp
                       cd = 2'h2;
                       pc = 1'b0;
                   end
                1: begin //8bpp BW
                       cd = 2'h0;
                       pc = 1'b0;
                   end
                2: begin //8bpp pseudo-color
                       cd = 2'h0;
                       pc = 1'b1;
                   end
                3: begin //16bpp
                       cd = 2'h1;
                       pc = 1'b0;
                   end
                4: begin //32bpp
                       cd = 2'h3;
                       pc = 1'b0;
                   end
              endcase

              bank = 0;
              for(bank=0; bank<2; bank=bank+1)
              begin
                  //Write configuration + set Bank/Clut switch
                  m0.wb_wr1( `CTRL,  4'hf, {
                             16'h0,   // Reserved
                             bpol,
                             cpol,
                             vpol,
                             hpol,
                             pc,      // PC
                             cd,      // CD
                             vbl[1:0],// VBL
                             1'b1,    // CBSWE
                             1'b1,    // VBSWE
                             1'b0,    // CBSIE
                             1'b0,    // VBSIE
                             1'b0,    // HIE
                             1'b0,    // VIE
                             1'b1     // Video Enable
                             }
                  );


                  $display("VBL: %0d, Mode: %0d Screen: %0d", vbl, mode, bank);
                  @(posedge vsync);

                  error_cnt=0;
                  for(l=0; l<tvgate;   l=l+1) //for each line
                  for(p=0; p<thgate+1; p=p+1) //for each pixel
                  begin
                      while(blanc) @(posedge pclk);  // wait for viewable data

                      //$display("pixel=%0d, line=%0d, (%0t)",p,l,$time);

                      if (!bank[0]) vbase = vbarb[31:2];
                      else         vbase = vbara[31:2];

                      if (!bank[0]) cbase = cbar | 32'h0000_0400;
                      else         cbase = cbar;

                      // Depending on Mode, determine pixel data
                      // pixel number = line * (thgate + 1) + p
                      pn = l * (thgate + 1) + p;

                      case(mode)
                        0: begin //24bpp
                               pra = pn[31:2] * 3; // Pixel relative Address
                               paa = pra + vbase;  // Pixel Absolute Address

                               // Pixel Data
                               case(pn[1:0])
                                 0: begin
                                       tmp = s0.mem[paa];
                                       pd  = tmp[31:8];
                                    end
                                 1: begin
                                        tmp       = s0.mem[paa];
                                        pd[23:16] = tmp[ 7: 0];
                                        tmp       = s0.mem[paa+1];
                                        pd[15: 0] = tmp[31:16];
                                    end
                                 2: begin
                                        tmp      = s0.mem[paa+1];
                                        pd[23:8] = tmp[15: 0];
                                        tmp      = s0.mem[paa+2];
                                        pd[ 7:0] = tmp[31:24];
                                    end
                                 3: begin
                                        tmp = s0.mem[paa+2];
                                        pd  = tmp[23:0];
                                    end
                               endcase
                           end


                        1: begin //8bpp Grayscale
                               pra = pn[31:2];    // Pixel relative Address
                               paa = pra + vbase; // Pixel Absolute Address

                               case(pn[1:0])
                                 0: begin
                                        tmp = s0.mem[paa];
                                        pd = { tmp[31:24], tmp[31:24], tmp[31:24] };
                                    end
                                 1: begin
                                        tmp = s0.mem[paa];
                                        pd = { tmp[23:16], tmp[23:16], tmp[23:16] };
                                    end
                                 2: begin
                                        tmp = s0.mem[paa];
                                        pd = { tmp[15:8], tmp[15:8], tmp[15:8] };
                                 end
                                 3: begin
                                        tmp = s0.mem[paa];
                                        pd = { tmp[7:0], tmp[7:0], tmp[7:0] };
                                    end
                               endcase
                           end

                        2: begin //8bpp Pseudo Color
                               pra = pn[31:2];    // Pixel relative Address
                               paa = pra + vbase; // Pixel Absolute Address

                               case(pn[1:0])
                                 0: begin
                                        tmp = s0.mem[paa];
                                        tmp = s0.mem[cbase[31:2] + tmp[31:24]];
                                        pd  = tmp[23:0];
                                    end
                                 1: begin
                                        tmp = s0.mem[paa];
                                        tmp = s0.mem[cbase[31:2] + tmp[23:16]];
                                        pd  = tmp[23:0];
                                    end
                                 2: begin
                                        tmp = s0.mem[paa];
                                        tmp = s0.mem[cbase[31:2] + tmp[15:8]];
                                        pd  = tmp[23:0];
                                    end
                                 3: begin
                                        tmp = s0.mem[paa];
                                        tmp = s0.mem[cbase[31:2] + tmp[7:0]];
                                        pd  = tmp[23:0];
                                    end
                               endcase
                           end

                        3: begin //16bpp
                               pra = pn[31:1];    // Pixel relative Address
                               paa = pra + vbase; // Pixel Absolute Address

                               case(pn[0])
                                 0: begin
                                        tmp = s0.mem[paa];
                                        tmp[15:0] = tmp[31:16];
                                        pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
                                    end
                                 1: begin
                                        tmp = s0.mem[paa];
                                        pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
                                    end
                               endcase
                           end

                        4: begin //32bpp
                               pra = pn[31:0];    // Pixel relative Address
                               paa = pra + vbase; // Pixel Absolute Address

                               tmp = s0.mem[paa];
                               pd = tmp[23:0];
                           end
                      endcase

                      // compare RGB values
                      if(pd !== {red, green, blue} )
                      begin
                          $display("ERROR: Pixel Data Mismatch: Expected: %h, Got: %h %h %h",
                            pd, red, green, blue);
                          $display("       pixel=%0d, line=%0d @%0t", p, l, $time);

                          error_cnt = error_cnt + 1;

                          if(error_cnt > 10) $stop;
                      end

                      @(posedge pclk);

                  end //next p/l
              end //next bank
          end //next mode/vbl
      end //next delay

      show_errors;
      $display("-------------------------------------------------");
      $display("- Pixel Data Test 2 DONE ...                    -");
      $display("-------------------------------------------------\n\n");
  end
endtask


/* FIFO Underrun test
 * ur_test
 */
task ur_test;
  integer mode;
  integer n, p, l;
  reg [31:0] pn;
  reg [31:0] pra, paa, tmp;
  reg [23:0] pd;
  reg [ 1:0] cd;
  reg        pc;
  reg [31:0] cbar;
  reg [31:0] data;
  reg [ 7:0] vbl;

  begin
      $display("\n\n");
      $display("-------------------------------------------------");
      $display("- FIFO Underrun Test 1                          -");
      $display("-------------------------------------------------\n");

s0.delay=15;
interrupt_warn = 0;

m0.wb_wr1( `VBARA, 4'hf, 0 );
m0.wb_wr1( `VBARB, 4'hf, 123456 );

cbar = 32'h0000_0800;

thsync = 6;
thgdel = 20;
thgate = 319;
thlen = 390;

tvsync = 1;
tvgdel = 8;
tvgate = 239;
tvlen = 280;

hpol = 0;
vpol = 0;
cpol = 0;
bpol = 0;

m0.wb_wr1( `HTIM,  4'hf, {thsync, thgdel, thgate} );
m0.wb_wr1( `VTIM,  4'hf, {tvsync, tvgdel, tvgate} );
m0.wb_wr1( `HVLEN, 4'hf, {thlen, tvlen} );

mode = 0;

// -------------------------------
// Turn Off VGA before Mode Change
m0.wb_wr1( `CTRL,  4'hf, 32'h0000_0000);

s0.fill_mem(1);

      // Fill internal Color Lookup Table
      repeat(10) @(posedge clk);
      for(n=0;n<512;n=n+1)
      begin
          data = s0.mem[ cbar[31:2] + n];
          m0.wb_wr1( 32'h0000_0800 + (n*4), 4'hf, data );
      end
      repeat(10) @(posedge clk);

      case(mode)
        0: begin
               cd = 2'h2;
               pc = 1'b0;
           end
        1: begin
               cd = 2'h0;
               pc = 1'b0;
           end
        2: begin
               cd = 2'h0;
               pc = 1'b1;
           end
        3: begin
               cd = 2'h1;
               pc = 1'b0;
           end
      endcase

      // -------------------------------
      // Turn VGA back On ...
      m0.wb_wr1( `CTRL,  4'hf, {
                 16'h0,// Reserved
                 bpol,
                 cpol,
                 vpol,
                 hpol,
                 pc,   // PC
                 cd,   // CD
                 2'b00,// VBL
                 1'b0, // Reserved
                 1'b0, // CBSWE
                 1'b0, // VBSWE
                 1'b0, // BSIE
                 1'b0, // HIE
                 1'b0, // VIE
                 1'b1  // Video Enable
                 }
      );

      while(!interrupt) @(posedge clk);
      m0.wb_rd1( `STAT,  4'hf, data);
      if(data[1] !== 1'b1)
      begin
          $display("ERROR: Did not get Line FIFO Interrupt @%0t", $time);
      end

      show_errors;
      $display("-------------------------------------------------");
      $display("- FIFO Underrun Test DONE ...                   -");
      $display("-------------------------------------------------\n\n");

      m0.wb_wr1( `CTRL,  4'hf, 32'h0000_0000);
      interrupt_warn = 1;
      s0.delay=1;
      repeat(10) @(posedge clk);
  end
endtask




//////////////////////////////////////
//
// DVI test section
//
task dvi_pd_test;

integer		mode;
integer		n, p, l;
reg	[ 2:0]	dvi_odf;
reg	[31:0]	pn;
reg	[31:0]	pra, paa, tmp;
reg	[23:0]	pd;
reg	[11:0]	pda, pdb;
reg	[ 1:0]	cd;
reg		pc;
reg	[31:0]	data;
reg	[31:0]	cbar;
reg	[ 7:0]	vbl;
reg	[ 5:0]	delay;

begin

$display("\n\n");
$display("*****************************************************");
$display("*** DVI Pixel Data Test                           ***");
$display("*****************************************************\n");

	m0.wb_wr1( `VBARA, 4'hf, 0 );
	m0.wb_wr1( `VBARB, 4'hf, 123456 );

	cbar = 32'h0000_0800;

	thsync = 0;
	thgdel = 0;
	thgate = 320;
	thlen = 345;

	tvsync = 0;
	tvgdel = 0;
	tvgate = 240;
	tvlen = 245;

	thsync = 39;
	thgdel = 124;
	thgate = 646;
	thlen = 832;

	tvsync = 2;
	tvgdel = 25;
	tvgate = 484;
	tvlen = 520;

	thsync = 6;
	thgdel = 20;
	thgate = 319;
	thlen = 390;

	tvsync = 1;
	tvgdel = 8;
	tvgate = 239;
	tvlen = 280;

	hpol = 0;
	vpol = 0;
	cpol = 0;
	bpol = 0;

	m0.wb_wr1( `HTIM,  4'hf, {thsync, thgdel, thgate} );
	m0.wb_wr1( `VTIM,  4'hf, {tvsync, tvgdel, tvgate} );
	m0.wb_wr1( `HVLEN, 4'hf, {thlen, tvlen} );

// Choose mode, vbl, and delay
// These should have been tested & verified by previous tests
mode  = 3;
vbl   = 4;
delay = 0;
s0.set_delay(delay);

for(dvi_odf=0; dvi_odf<4;dvi_odf=dvi_odf +1)
   begin
	// -------------------------------
	// Turn Off VGA before Mode Change

	m0.wb_wr1( `CTRL,  4'hf, {
				2'h0,	// Reserved
				dvi_odf[1:0],
				12'h0,	// Reserved
				bpol,
				cpol,
				vpol,
				hpol,
				pc,	// PC
				cd,	// CD
				2'h0,	// VBL
				1'b0,	// CBSWE
				1'b0,	// VBSWE
				1'b0,	// CBSIE
				1'b0,	// VBSIE
				1'b0,	// HIE
				1'b0,	// VIE
				1'b0	// Video Enable
				});

	s0.fill_mem(1);

	`ifdef USE_VC
	// Fill internal Color Lookup Table
	repeat(10)	@(posedge clk);
	for(n=0;n<512;n=n+1)
	   begin
	       //m0.wb_rd1( 32'h0002_0000 + (n*4), 4'hf, data );
	       data = s0.mem[ cbar[31:2] + n];
	       m0.wb_wr1( 32'h0000_0800 + (n*4), 4'hf, data );
	   end
	repeat(10)	@(posedge clk);
	`endif

	case(mode)
	   0:
	     begin
		cd = 2'h2;
		pc = 1'b0;
	     end
	   1:
	     begin
		cd = 2'h0;
		pc = 1'b0;
	     end
	   2:
	     begin
		cd = 2'h0;
		pc = 1'b1;
	     end
	   3:
	     begin
		cd = 2'h1;
		pc = 1'b0;
	     end
	endcase

	//repeat(50) @(posedge clk);

	// -------------------------------
	// Turn VGA back On ...
	m0.wb_wr1( `CTRL,  4'hf, {
				2'h0,	// Reserved
				dvi_odf[1:0],
				12'h0,	// Reserved
				bpol,
				cpol,
				vpol,
				hpol,
				pc,	// PC
				cd,	// CD
				2'h0,	// VBL
				1'b0,	// CBSWE
				1'b0,	// VBSWE
				1'b0,	// CBSIE
				1'b0,	// VBSIE
				1'b0,	// HIE
				1'b0,	// VIE
				1'b1	// Video Enable
				});

	$display("DVI output data format: %0h", dvi_odf);
	repeat(2) @(posedge vsync);

	// For Each Line
	for(l=0;l<tvgate;l=l+1)
	// For each Pixel
	for(p=0;p<thgate+1;p=p+1)
	   begin
		while(dvi_de_o == 1'b0) @(pclk);  // wait for viewable data

		//$display("pixel=%0d, line=%0d, (%0t)",p,l,$time);

		// Depending on Mode, determine pixel data
		// pixel number = line * (thgate + 1) + p
		pn = l * (thgate + 1) + p;

		//
		// Get the correct pixel data
		case(mode)
		   0:	// 24 bit/pixel mode
		   begin
			pra = pn[31:2] * 3;	// Pixel relative Address
			paa = pra + 0;		// Pixel Absolute Address

			// Pixel Data
			case(pn[1:0])
			   0:
			     begin
				tmp = s0.mem[paa];
				pd = tmp[31:8];
			     end
			   1:
			     begin
				tmp = s0.mem[paa];
				pd[23:16] = tmp[7:0];
				tmp = s0.mem[paa+1];
				pd[15:0] = tmp[31:16];
			     end
			   2:
			     begin
				tmp = s0.mem[paa+1];
				pd[23:8] = tmp[15:0];
				tmp = s0.mem[paa+2];
				pd[7:0] = tmp[31:24];
			     end
			   3:
			     begin
				tmp = s0.mem[paa+2];
				pd = tmp[23:0];
			     end
			endcase
		   end

		   1:	// 8 bit/pixel grayscale mode
		   begin
			pra = pn[31:2];		// Pixel relative Address
			paa = pra + 0;		// Pixel Absolute Address
			case(pn[1:0])
			   0:
			     begin
				tmp = s0.mem[paa];
				pd = { tmp[31:24], tmp[31:24], tmp[31:24] };
			     end
			   1:
			     begin
				tmp = s0.mem[paa];
				pd = { tmp[23:16], tmp[23:16], tmp[23:16] };
			     end
			   2:
			     begin
				tmp = s0.mem[paa];
				pd = { tmp[15:8], tmp[15:8], tmp[15:8] };
			     end
			   3:
			     begin
				tmp = s0.mem[paa];
				pd = { tmp[7:0], tmp[7:0], tmp[7:0] };
			     end
			endcase
		   end

		   2:	// 8 bit/pixel Pseudo Color mode
		   begin
			pra = pn[31:2];		// Pixel relative Address
			paa = pra + 0;		// Pixel Absolute Address
			case(pn[1:0])
			   0:
			     begin
				tmp = s0.mem[paa];
				tmp = s0.mem[cbar[31:2] + tmp[31:24]];
				pd = tmp[23:0];
			     end
			   1:
			     begin
				tmp = s0.mem[paa];
				tmp = s0.mem[cbar[31:2] + tmp[23:16]];
				pd = tmp[23:0];
			     end
			   2:
			     begin
				tmp = s0.mem[paa];
				tmp = s0.mem[cbar[31:2] + tmp[15:8]];
				pd = tmp[23:0];
			     end
			   3:
			     begin
				tmp = s0.mem[paa];
				tmp = s0.mem[cbar[31:2] + tmp[7:0]];
				pd = tmp[23:0];
			     end
			endcase
		   end

		   3:	// 16 bit/pixel mode
		   begin
			pra = pn[31:1];		// Pixel relative Address
			paa = pra + 0;		// Pixel Absolute Address
			case(pn[0])
			   0:
			     begin
				tmp = s0.mem[paa];
				tmp[15:0] = tmp[31:16];
				pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
			     end
			   1:
			     begin
				tmp = s0.mem[paa];
				pd = {tmp[15:11], 3'h0, tmp[10:5], 2'h0, tmp[4:0], 3'h0};
			     end
			endcase
		   end

		endcase

		//
		// convert pixel data in DVI output format
		case (dvi_odf)
		   2'b00:
		      begin
			  pda = pd[11:0];
			  pdb = pd[23:12];
		      end

		   2'b01:
		      begin
			  pda = {pd[12:10],pd[7:3],pd[8],pd[2:0]};
			  pdb = {pd[23:19],pd[15:13],pd[18:16],pd[9]};
		      end

		   2'b10:
		      begin
			  pda = {pd[12:10],pd[7:3],4'h0};
			  pdb = {pd[23:19],pd[15:13],4'h0};
		      end

		   2'b11:
		      begin
			  pda = {pd[13:11],pd[7:3],4'h0};
			  pdb = {1'b0,pd[23:19],pd[15:14],4'h0};
		      end
		endcase

		//
		// verify pixel data

`ifdef VGA_12BIT_DVI

		// rising edge data
		if (pda !== dvi_d_o)
		   begin
			$display("ERROR: Pixel Data Mismatch: Expected: %h, Got: %h",
				pda, dvi_d_o);
			$display("       pixel=%0d, line=%0d, (%0t)",p,l,$time);
			error_cnt = error_cnt + 1;
			if(error_cnt > 10) $stop;
		   end

		@(negedge pclk);

		// falling edge data
		if (pdb !== dvi_d_o)
		   begin
			$display("ERROR: Pixel Data Mismatch: Expected: %h, Got: %h",
				pdb, dvi_d_o);
			$display("       pixel=%0d, line=%0d, (%0t)",p,l,$time);
			error_cnt = error_cnt + 1;
			if(error_cnt > 10) $stop;
		   end
		@(posedge pclk);
`else

		// compare data
		if ({pdb, pda} !== dvi_d_o)
		   begin
			$display("ERROR: Pixel Data Mismatch: Expected: %h, Got: %h",
				{pdb, pda}, dvi_d_o);
			$display("       pixel=%0d, line=%0d, (%0t)",p,l,$time);
			error_cnt = error_cnt + 1;
			if(error_cnt > 10) $stop;
		   end

		repeat (2) @(negedge pclk);
`endif
	   end
   end

show_errors;
$display("*****************************************************");
$display("*** Test DONE ...                                 ***");
$display("*****************************************************\n\n");

end
endtask
