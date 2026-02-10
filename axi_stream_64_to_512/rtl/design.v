
`timescale 1ns / 1ps

module width_conv_64_512 # (
    parameter integer C_S00_AXIS_TDATA_WIDTH = 64,
    parameter integer C_M00_AXIS_TDATA_WIDTH = 512,
    parameter integer NUM_OF_BEATS = C_M00_AXIS_TDATA_WIDTH / C_S00_AXIS_TDATA_WIDTH
  )
  (
    input wire aclk,
    input wire aresetn,                 // active low

    // DMA ----> collector    ---- From DMA 64-bit to 64-bit side collector
    input wire [C_S00_AXIS_TDATA_WIDTH-1:0] S_AXIS_TDATA,
    input wire        S_AXIS_TVALID,    // active high
    input wire        S_AXIS_TLAST,     // active high
    output wire       S_AXIS_TREADY,    // active high

    // collector ---> LDPC    ---- From 512-bit side collector to LDPC 512-bit
    output wire [C_M00_AXIS_TDATA_WIDTH-1:0] M_AXIS_TDATA,
    output wire         M_AXIS_TVALID,  // active high
    output wire         M_AXIS_TLAST,   // active high
    input wire          M_AXIS_TREADY   // active high
  );

  localparam integer IDLE = 0,
             COLLECT = 1,
             SEND_OUTPUT = 2;

  // internal registers
  reg [63:0]  buffer [0:7];
  reg [2:0]   count;
  reg         m_tvalid, m_tlast;
  // reg         m_tlast;
  reg [1:0]   curr_state, next_state;
  reg last_beat_seen;
  integer i;
  reg [511:0] data_to_send_on_M_TDATA;
  wire AXIS_HANDSHAKE;

  assign AXIS_HANDSHAKE = S_AXIS_TVALID && S_AXIS_TREADY;

  // I/O Port Connections
  assign M_AXIS_TDATA  = data_to_send_on_M_TDATA;
  assign M_AXIS_TLAST  = M_AXIS_TVALID && m_tlast;
  assign M_AXIS_TVALID = m_tvalid;
  assign S_AXIS_TREADY = (curr_state == IDLE || curr_state==COLLECT);

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
          next_state = S_AXIS_TLAST ? SEND_OUTPUT : COLLECT;
        else
          next_state = IDLE;
      end

      COLLECT:
      begin
        if(S_AXIS_TVALID && (count==7 || S_AXIS_TLAST))
          next_state = SEND_OUTPUT;
        else
          next_state = COLLECT;
      end

      SEND_OUTPUT:
      begin
        if(M_AXIS_TREADY)
          next_state = IDLE;
        else
          next_state = SEND_OUTPUT;
      end

      default:
        next_state = 'hx;
    endcase
  end

  // Sequential last_beat_seen logic
  always@(posedge aclk)
  begin
    if(!aresetn)
      last_beat_seen <= 0;
    else
    begin
      case(curr_state)
        IDLE:
        begin
          m_tlast <= 0;
          if(S_AXIS_TVALID)
          begin
            last_beat_seen <= S_AXIS_TLAST;
          end
        end

        COLLECT:
        begin
          if(S_AXIS_TVALID)
          begin
            last_beat_seen <= S_AXIS_TLAST;
          end
        end

        SEND_OUTPUT:
        begin
          m_tlast <= last_beat_seen;
          if(M_AXIS_TREADY && last_beat_seen)  // Do not need to check M_AXIS_TVALID as we are already driving it to 1 in this state
            last_beat_seen <= 1'b0;
        end
      endcase
    end
  end

  // Sequential count logic
  always@(posedge aclk)
  begin
    if(!aresetn)
      count<=0;
    else
    begin
      case(curr_state)
        IDLE:
        begin
          if(AXIS_HANDSHAKE && !S_AXIS_TLAST)
            count <= count + 1;
          else
            count <= count;
        end

        COLLECT:
        begin
          if(AXIS_HANDSHAKE && !S_AXIS_TLAST)
            count <= count + 1;
          else
            count <= count;
        end

        SEND_OUTPUT:
        begin
          count <= 0;
        end
      endcase
    end
  end

  // Sequential buffer logic
  always@(posedge aclk)
  begin
    if(!aresetn)
      for(i=0; i<=NUM_OF_BEATS; i=i+1)
        buffer[i] <= 0;
    else
    begin
      case(curr_state)
        IDLE:
        begin
          for(i=0; i<=NUM_OF_BEATS; i=i+1)
            buffer[i] <= 0;
          if(AXIS_HANDSHAKE)
            buffer[count] <= S_AXIS_TDATA;
          else
            buffer[count] <= buffer[count];
        end

        COLLECT:
        begin
          if(AXIS_HANDSHAKE)
            buffer[count] <= S_AXIS_TDATA;
          else
            buffer[count] <= buffer[count];
        end
      endcase
    end
  end

  // Sequential m_tvalid logic
  always@(posedge aclk)
  begin
    if(!aresetn)
    begin
      m_tvalid <= 0;
      data_to_send_on_M_TDATA <= 0;
    end
    else
    begin
      case(curr_state)
        SEND_OUTPUT:
        begin
          m_tvalid <= 1;
          data_to_send_on_M_TDATA <= {buffer[7],buffer[6],buffer[5],buffer[4],buffer[3],buffer[2],buffer[1],buffer[0]};
        end
        default:
        begin
          m_tvalid <= 0;
          data_to_send_on_M_TDATA <= data_to_send_on_M_TDATA;
        end
      endcase
    end
  end

endmodule
