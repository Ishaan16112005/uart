module baud_gen #(
  parameter sys_clk = 1000000000,
  parameter baud_rate = 115200,
  parameter over_sample = 16
) (
  input wire clk,
  input wire rst_n,
  output wire tick
);

  localparam max_count = (sys_clk /(baud_rate * over_sample));

  reg ($clog2(max_count) -1 : 0) counter;

  always @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin 
      counter <= 0;
      tick <= 1'b0;
    end else begin 
      if (counter <= (max_count -1)) begin 
        counter <= 0;
        tick <= 1'b1;
      end else begin 
        counter <= counter + 1;
        tick <= 1'b0;
      end
    end
  end

endmodule 
