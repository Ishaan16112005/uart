module uart_tx(
  input wire clk,
  input wire reset,
  input wire tx_tick, // to count the 16 bits 
  input wire tx_start, // symbol for start
  input wire [7:0] tx_data,
  output reg tx_line, 
  output reg tx_busy
);
  localparam [1:0] idle = 2'b00;
  localparam [1:0] start = 2'b01;
  localparam [1:0] data = 2'b10;
  localparam [1:0] stop = 2'b11;

  reg [1:0] state_reg, next_state;
  reg [3:0] s_reg, s_next;
  reg [2:0] n_reg, n_next;
  reg [7:0] b_reg, b_next;
  reg       tx_reg, tx_next;
  
  always @(posedge clk or posedge reset) begin 
    if (reset) begin 
      state_reg <= idle;
      s_reg <= 0;
      n_reg <= 0;
      b_reg <= 0;
      tx_reg = 1'b1;
    end else begin 
      state_reg <= next_state;
      s_reg <= s_next;
      n_reg <= n_next;
      b_reg <= b_next;
      tx_reg <= tx_next;
    end
  end
  
  always @(*) begin 
    next_state = state_reg;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;
    tx_next = tx_reg;
    tx_busy = 1'b1;

    case (state_reg) 
      idle : begin 
        tx_busy = 1'b0;
        tx_next = 1'b1;
        if (tx_start) begin
          s_next = 0;
          next_state = start;
          b_next = tx_data;
        end
      end
      start : begin 
        tx_next = 1'b0;
        if (tx_tick) begin 
          if(s_reg ==15 ) begin 
            s_next = 0;
            n_next = 0;
            next_state = data;
          end else begin 
            s_next = s_reg + 1'b1;
          end
        end
      end
      data :  begin
        tx_next = b_reg[0];
        if (tx_tick) begin 
          if (s_reg == 15) begin 
            s_reg = 0;
            b_next = b_reg >> 1;
            if (n_reg == 7) begin 
              next_state = stop;
            end else begin 
              n_next = n_reg + 1'b1;
            end
            else begin 
              s_next = s_reg + 1'b1;
            end
          end
      end
      stop : begin
        tx_next = 1'b1;
        if (tx_tick) begin
          if (s_reg == 15) begin 
            s_next = 0;
            next_state = idle;
          end else begin 
            s_next = s_reg + 1;
          end
        end
      end
    endcase
  end 

  always @(*) begin 
    tx_line = tx_reg;
  end 
endmodule
