`timescale 1ns / 1ps

module testbench();
  parameter integer C_S00_AXIS_TDATA_WIDTH = 512;
  parameter integer C_M00_AXIS_TDATA_WIDTH = 64;

  reg aclk;
  reg aresetn;

  // LDPC ----> collector    ---- From 512-bit LDPC to 512-bit side collector
  reg [C_S00_AXIS_TDATA_WIDTH-1:0] S_AXIS_TDATA;
  reg        S_AXIS_TVALID;    // active high
  reg        S_AXIS_TLAST;     // active high
  wire       S_AXIS_TREADY;    // active high

  // collector ---> DMA    ---- From 64-bit side collector to 64-bit DMA
  wire [C_M00_AXIS_TDATA_WIDTH-1:0] M_AXIS_TDATA;
  wire         M_AXIS_TVALID;  // active high
  wire         M_AXIS_TLAST;   // active high
  reg          M_AXIS_TREADY;   // active high

  width_conv_512_64 dut (
                      .aclk(aclk),
                      .aresetn(aresetn),
                      .S_AXIS_TDATA(S_AXIS_TDATA),
                      .S_AXIS_TVALID(S_AXIS_TVALID),
                      .S_AXIS_TREADY(S_AXIS_TREADY),
                      .S_AXIS_TLAST(S_AXIS_TLAST),
                      .M_AXIS_TDATA(M_AXIS_TDATA),
                      .M_AXIS_TVALID(M_AXIS_TVALID),
                      .M_AXIS_TREADY(M_AXIS_TREADY),
                      .M_AXIS_TLAST(M_AXIS_TLAST)
                    );

  integer i;

  task send_data;
    input [C_S00_AXIS_TDATA_WIDTH-1:0] data;
    input last;
    begin
//      #1;

      S_AXIS_TDATA  <= data;
      S_AXIS_TVALID <= 1;
      S_AXIS_TLAST  <= last;

      @(posedge aclk);
      while(!S_AXIS_TREADY)
        @(posedge aclk);

//      #1;

      S_AXIS_TVALID <= 0;
      S_AXIS_TLAST  <= 0;

    end
  endtask

  always #5 aclk = ~aclk;

  initial
  begin
//      M_AXIS_TREADY = 1;
   $display("**************       This is the Module Log *************************");

    aclk = 0;
    aresetn = 1;
    S_AXIS_TDATA  = 0;
    S_AXIS_TLAST  = 0;
    S_AXIS_TVALID = 0;

    repeat(2) @(posedge aclk)
      aresetn = 0;

    @(posedge aclk);
    aresetn = 1;


    @(posedge aclk);
//    M_AXIS_TREADY = 1;

//    send_data({
//                {8{8'd7}},
//                {8{8'd6}},
//                {8{8'd5}},
//                {8{8'd4}},
//                {8{8'd3}},
//                {8{8'd2}},
//                {8{8'd1}},
//                {8{8'd16}}
//              }, 0);
//              @(posedge aclk);
//    send_data({
//                {8{8'd15}},
//                {8{8'd14}},
//                {8{8'd13}},
//                {8{8'd12}},
//                {8{8'd11}},
//                {8{8'd10}},
//                {8{8'd9}},
//                {8{8'd8}}
//              }, 1'b1);
    @(posedge aclk);
    send_data(512'h3F3E3D3C3B3A393837363534333231302F2E2D2C2B2A292827262524232221201F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100,0);
    
    @(posedge aclk);
    send_data(512'h00000000000000000000000000000000000000000000000000000000000000001F1E1D1C1B1A191817161514131211100F0E0D0C0B0A09080706050403020100,1);
    
    #200;
    $display("Simulation Finished");
    $finish;
  end

  initial
  begin
  @(posedge aclk);
  M_AXIS_TREADY <= 1;
  #130;
  M_AXIS_TREADY <= 0;
  #10;
  M_AXIS_TREADY <= 1;
//  repeat(5) @(posedge aclk);
////    #55;
//    M_AXIS_TREADY = 1;
  end
endmodule
