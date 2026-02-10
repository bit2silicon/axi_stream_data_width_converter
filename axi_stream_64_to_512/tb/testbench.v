`timescale 1ns / 1ps

module width_conv_64_512_tb();
  parameter integer C_S00_AXIS_TDATA_WIDTH = 64;
  parameter integer C_M00_AXIS_TDATA_WIDTH = 512;

  reg aclk;
  reg aresetn;

  // DMA ----> collector    ---- From DMA to 64-bit side collector
  reg [63:0] S_AXIS_TDATA;
  reg        S_AXIS_TVALID;    // active high
  reg        S_AXIS_TLAST;     // active high
  wire       S_AXIS_TREADY;    // active high

  // collector ---> LDPC    ---- From 512-bit side collector to LDPC
  wire [511:0] M_AXIS_TDATA;
  wire         M_AXIS_TVALID;  // active high
  wire         M_AXIS_TLAST;   // active high
  reg          M_AXIS_TREADY;   // active high

  reg last;
  width_conv_64_512 dut (
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

  // blocking assignments & robust handshake: use these replacements in your TB

  task send_data;
    input [63:0] data;
    input last;
    begin
      // drive inputs immediately
//      #1;
      S_AXIS_TDATA  <= data;
      S_AXIS_TLAST  <= last;
      S_AXIS_TVALID <= 1;

      // wait until DUT accepts (handshake)
      @(posedge aclk);
      while (!S_AXIS_TREADY)
        @(posedge aclk);

      // handshake happened this cycle; drop TVALID (and TLAST)
//      #1;
      S_AXIS_TVALID <= 0;
      S_AXIS_TLAST  <= 0;

    end
  endtask

  integer i;
  always #5 aclk = ~aclk;

//  initial
//  begin
//    #245;
//    M_AXIS_TREADY <= 0;
//    #40;
//    M_AXIS_TREADY <= 1;
//  end

  initial
  begin
    // Initial values
    aclk=0;
    // S_AXIS_TDATA  = 0;
    S_AXIS_TVALID = 0;
    S_AXIS_TLAST  = 0;
    M_AXIS_TREADY = 0;
    last=0;

    // Reset pulse
    repeat (1) @(posedge aclk);
    aresetn <= 0;

    @(posedge aclk);
    aresetn <= 1;
    M_AXIS_TREADY <= 1;

    // @(posedge aclk);
    $display("\n ********   TEST-1: 15 beats ********");
//    for(i=0; i<20; i=i+1)
//    begin
//      // $display("Sending beat %0d...", i);
//      send_data(64'd0 + i,(i==19));
//    end

    // for(i=0; i<3; i=i+1)
    // begin
    //   if(i==2)
    //     last=1;
    //   send_data(64'hA0000000 + i,last);
    // end
    
    send_data(64'h0706050403020100,0);
    send_data(64'h0F0E0D0C0B0A0908,0);
    send_data(64'h1716151413121110,0);
    send_data(64'h1F1E1D1C1B1A1918,0);
    send_data(64'h2726252423222120,0);
    send_data(64'h2F2E2D2C2B2A2928,0);
    send_data(64'h3736353433323130,0);
    send_data(64'h3F3E3D3C3B3A3938,0);
    send_data(64'h4746454443424140,0);
    send_data(64'h4F4E4D4C4B4A4948,0);
    send_data(64'h5756555453525150,0);
    send_data(64'h5F5E5D5C5B5A5958,1);
    

    #50;
    $display("Simulation is finished");
    $finish;

  end

endmodule

