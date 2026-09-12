module baud_gen #(
  parameter sys_clk = 1000000,
  parameter baud_rate = 115200,
  parameter oversample = 16
) (
  input wire clk, 
  input wire rst_n,
  output wire tick
); 
 
  localparam max_count = (sys_clk + (baud_rate * over_sample / 2)) / (baud_rate * over_sample);
  localparam width = (max_count > 1) ? $clog2(max_count) : 1;
  reg [width-1:0] counter;

  always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin 
      tick <= 0;
      counter <= 0;
    end else begin 
      if (counter >= (max_count-1)) begin 
        tick  <= 1'd1;
        counter <= {width{1'b0}};
      end else begin
        tick <= 1'b0;
        counter <= counter + 1'b1;
      end
    end 
  end
endmodule

