module baud_gen(
  input wire clk,
  input wire reset,
  output wire tick
);
  reg [8:0] counter_reg = 0;
  assign tick = (counter_reg == 325);
  always @(posedge clk or posedge reset) begin 
    if (reset) begin
      counter_reg <= 0;
    end else if (tick) begin 
      counter_reg <= 0;
    else counter_reg <= counter_reg + 1;
  end
endmodule 
