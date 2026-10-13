
module rx #(
  parameter width = 8,
  parameter parity_en = 1,
  parameter parity_type = "ODD"
) (
  input wire tick,
  input wire clk,
  input wire rst_n,
  input wire rx_in,
  output reg [width-1:0] data_out,
  output reg rx_done,
  output reg rx_busy,
  output reg parity_error,
  output reg framing_error
);

  localparam IDLE   = 3'b000;
  localparam START  = 3'b001;
  localparam DATA   = 3'b010;
  localparam PARITY = 3'b011;
  localparam STOP   = 3'b100;

  reg [2:0] state;
  reg [3:0] tick_count;
  reg [$clog2(width)-1:0] current_index;
  reg [width-1:0] rx_shift_reg;
  reg parity_bit;

  wire parity_calc = (parity_type == "ODD") ? ~^rx_shift_reg : ^rx_shift_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      data_out <= 0;
      rx_done <= 0;
      rx_busy <= 0;
      parity_error <= 0;
      framing_error <= 0;
      tick_count <= 0;
      current_index <= 0;
      rx_shift_reg <= 0;
      parity_bit <= 0;
    end else begin
      rx_done <= 0;
      parity_error <= 0;
      framing_error <= 0;

      case (state)
        IDLE: begin
          rx_busy <= 0;
          tick_count <= 0;
          if (!rx_in) begin
            rx_busy <= 1;
            state <= START;
          end
        end

        START: begin
          if (tick) begin
            if (tick_count == 4'd7) begin
              tick_count <= 0;
              if (!rx_in) begin
                current_index <= 0;
                state <= DATA;
              end else begin
                state <= IDLE;
                rx_busy <= 0;
              end
            end else begin
              tick_count <= tick_count + 1'b1;
            end
          end
        end

        DATA: begin
          if (tick) begin
            if (tick_count == 4'd15) begin
              tick_count <= 0;
              rx_shift_reg[current_index] <= rx_in;

              if (current_index == width-1) begin
                if (parity_en)
                  state <= PARITY;
                else
                  state <= STOP;
              end else begin
                current_index <= current_index + 1'b1;
              end
            end else begin
              tick_count <= tick_count + 1'b1;
            end
          end
        end

        PARITY: begin
          if (tick) begin
            if (tick_count == 4'd15) begin
              tick_count <= 0;
              parity_bit <= rx_in;
              if (rx_in != parity_calc)
                parity_error <= 1;
              state <= STOP;
            end else begin
              tick_count <= tick_count + 1'b1;
            end
          end
        end

        STOP: begin
          if (tick) begin
            if (tick_count == 4'd15) begin
              tick_count <= 0;
              data_out <= rx_shift_reg;
              rx_done <= 1;
              rx_busy <= 0;
              if (!rx_in)
                framing_error <= 1;
              state <= IDLE;
            end else begin
              tick_count <= tick_count + 1'b1;
            end
          end
        end

        default: begin
          state <= IDLE;
          rx_busy <= 0;
        end
      endcase
    end
  end

endmodule

