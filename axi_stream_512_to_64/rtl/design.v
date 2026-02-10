`timescale 1ns / 1ps

module design #(
    parameter integer C_S00_AXIS_TDATA_WIDTH = 512,
    parameter integer C_M00_AXIS_TDATA_WIDTH = 64,
    parameter integer NUM_OF_BEATS = C_M00_AXIS_TDATA_WIDTH / C_S00_AXIS_TDATA_WIDTH
  )
  (
    input wire aclk,
    input wire aresetn,                 // active low

    // LDPC ----> collector    ---- From 512-bit LDPC to 512-bit side collector
    input wire [C_S00_AXIS_TDATA_WIDTH-1:0] S_AXIS_TDATA,
    input wire        S_AXIS_TVALID,    // active high
    input wire        S_AXIS_TLAST,     // active high
    output wire       S_AXIS_TREADY,    // active high

    // collector ---> DMA    ---- From 64-bit side collector to 64-bit DMA
    output wire [C_M00_AXIS_TDATA_WIDTH-1:0] M_AXIS_TDATA,
    output wire         M_AXIS_TVALID,  // active high
    output wire         M_AXIS_TLAST,   // active high
    input wire          M_AXIS_TREADY   // active high
  );

  localparam IDLE = 0, SEND_OUTPUT = 1;

  reg [C_M00_AXIS_TDATA_WIDTH-1:0] data_to_send_on_M_TDATA;
  reg                              last_beat_seen;
  reg                              m_tvalid;
  reg                              m_tlast;
  reg                              curr_state;
  reg                              next_state;
  reg [2:0]                        count;
  reg [C_M00_AXIS_TDATA_WIDTH-1:0] buffer [0:7];
  wire                             AXIS_HANDSHAKE;
  integer                          i;

  assign M_AXIS_TDATA  = data_to_send_on_M_TDATA;
  assign M_AXIS_TLAST  = M_AXIS_TVALID && m_tlast && (curr_state==0);
  assign M_AXIS_TVALID = m_tvalid;
  assign S_AXIS_TREADY = (curr_state == IDLE);

  assign AXIS_HANDSHAKE = S_AXIS_TVALID && S_AXIS_TREADY;

  // Sequential State Register
  always@(posedge aclk)
  begin
    if(!aresetn)
      curr_state <= IDLE;
    else
      curr_state <= next_state;
  end

  // Combinational Next State Logic
  always@(*)
  begin
    case(curr_state)
      IDLE:
      begin
        if(AXIS_HANDSHAKE)
          next_state = SEND_OUTPUT;
        else
          next_state = IDLE;
      end

      SEND_OUTPUT:
      begin
        if(count<7)
          next_state = SEND_OUTPUT;
        else
          next_state = IDLE;
      end

      default:
        next_state = 'hx;
    endcase
  end

  // Sequential data_to_send_on_M_TDATA Logic
  always@(posedge aclk)
  begin
    if(!aresetn)
    begin
      m_tvalid <= 0;
      data_to_send_on_M_TDATA <= 0;
    end
    else
    case(curr_state)
      SEND_OUTPUT:
      begin
        m_tvalid <= 1;
        data_to_send_on_M_TDATA <= buffer[count];
      end
      default:
      begin
        m_tvalid <= 0;
        data_to_send_on_M_TDATA <= 'h0;
      end
    endcase
  end

  // Sequential count Logic
  always@(posedge aclk)
  begin
    if(!aresetn)
      count <= 0;
    else
    case(curr_state)
      SEND_OUTPUT:
      begin
        if(M_AXIS_TREADY && (count<7))
          count <= count + 1;
        else
          count <= count;
      end
      default:
        count <= 0;
    endcase
  end

  // Sequential buffer Logic
  always@(posedge aclk)
  begin
    if(!aresetn)
      for(i = 0; i < 8; i = i + 1)
        buffer[i] <= 0;
    else
    case(curr_state)
      IDLE:
      begin
        if(AXIS_HANDSHAKE)
        begin
          //   buffer[0] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(0+1)-1: 0*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[1] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(1+1)-1: 1*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[2] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(2+1)-1: 2*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[3] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(3+1)-1: 3*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[4] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(4+1)-1: 4*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[5] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(5+1)-1: 5*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[6] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(6+1)-1: 6*C_M00_AXIS_TDATA_WIDTH];
          //   buffer[7] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*(7+1)-1: 7*C_M00_AXIS_TDATA_WIDTH];
          $display("Hey time = %0t, and AXIS Handshake happened now",$time);
          for(i=0; i<8; i=i+1)
            buffer[i] <= S_AXIS_TDATA[C_M00_AXIS_TDATA_WIDTH*i+:C_M00_AXIS_TDATA_WIDTH];
          // This means width*(i+1):i*width] - supported in Verilog 2001
        end
      end
      //   default:
      //     for(i=0; i<8; i=i+1)
      //       buffer[i]<=0;
    endcase
  end

  // Sequential last_beat_seen logic
  always@(posedge aclk)
  begin
    if(!aresetn)
    begin
      last_beat_seen <= 0;
      m_tlast <= 0;
    end
    else
    begin
      case(curr_state)
        IDLE:
        begin
        $display("IDLE at %0t: s_tdata = 0x%0h m_tdata=0x%0h, s_tvalid=%0b, s_tlast=%0b, lastbeatseen = %0b count=%0d",$time,S_AXIS_TDATA,M_AXIS_TDATA,S_AXIS_TVALID,S_AXIS_TLAST,last_beat_seen,count);
          if(count==7)
            m_tlast <= 0;
          if(S_AXIS_TVALID)
          begin
          $display("At %0t hey tvalid is high and curr state is IDLE",$time);
            last_beat_seen <= S_AXIS_TLAST;
          end
        end

        SEND_OUTPUT:
        begin
          if(m_tlast==0)
            m_tlast <= last_beat_seen;
          if(M_AXIS_TREADY && last_beat_seen)  // Do not need to check M_AXIS_TVALID as we are already driving it to 1 in this state
            begin
            last_beat_seen <= 1'b0;
            $display("At %0t hey lastbeat seen and maxistready is high and curr state is SEND_OUTPUT", $time);
            end
        end
      endcase
    end
  end
  
endmodule
