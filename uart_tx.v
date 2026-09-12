module tx (
  parameter width = 8,
  parameter parity_en = 1,
  parameter parity_type = "ODD"
) (
  input wire tick,
  input wire clk,
  input wire rst_n,
  input wire tx_start,
  input wire [width-1:0] data_in,
  output reg data_out,
  output reg tx_done,
  output reg tx_busy
);

  localparam IDLE = 3'b000;
  localparam START = 3'b001;
  localparam DATA = 3'b010;
  localparam PARITY = 3'b100;
  localparam STOP = 3'b101;

  reg [2:0] state;
  reg [$clog2(width)-1:0] current_index;
  reg parity_bit; 
  reg [width-1:0] tx_shift_reg;
  reg [3:0] tick_count;

  wire parity_calc = (parity_type == "ODD") ? ~^data_in : ^data_in;

  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
      data_out <= 1'b1;
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
      state <= IDLE;
      current_index <= 0;
      parity_bit <= 1'b0;
      tx_shift_reg <= {width{1'b0}};
      tick_count <= 0;
    end else begin 
      tx_done <= 1'b0; 
      
      case(state)
        IDLE: begin
          tx_done <= 1'b0;
          tx_busy <= 1'b0;
          if (tx_start) begin 
            tx_busy <= 1'b1;
            parity_bit <= parity_calc;
            tx_shift_reg <= data_in;
            data_out <= 1'b1;
            tick_count <= 4'd0;
            state <= START;
          end 
        end 

        START: begin
          data_out <= 1'b0;
          if (tick) begin 
            if (tick_count == 4'd15) begin
              tick_count <= 4'd0;
              current_index <= 0;
              state <= DATA;
            end else begin 
              tick_count <= tick_count + 4'd1;
            end 
          end  
        end

        DATA: begin 
          data_out <= tx_shift_reg[0];
          if (tick) begin
            if (tick_count == 4'd15) begin 
              tick_count <= 4'd0;
              tx_shift_reg <= tx_shift_reg >> 1;
              if (current_index == width-1) begin 
                state <= (parity_en) ? PARITY : STOP;
              end else begin 
                current_index <= current_index + 1'b1;
              end 
            end else begin 
              tick_count <= tick_count + 4'd1;
            end 
          end 
        end 

        PARITY: begin
          data_out <= parity_bit;
          if (tick) begin 
            if (tick_count == 4'd15) begin 
              tick_count <= 4'd0;
              state <= STOP;
            end else begin 
              tick_count <= tick_count + 4'd1;
            end 
          end 
        end 

        STOP: begin
          data_out <= 1'b1;
          if (tick) begin 
            if (tick_count == 4'd15) begin 
              tick_count <= 4'd0;
              tx_done <= 1'b1;
              tx_busy <= 1'b0;
              state <= IDLE;
            end else begin 
              tick_count <= tick_count + 1;
            end 
          end 
        end 

        default: begin
          state <= IDLE;
        end 

      endcase 
    end 
  end 
endmodule


