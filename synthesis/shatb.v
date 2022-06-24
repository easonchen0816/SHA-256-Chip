`timescale 1ns/10ps
`define CYCLE 20
module tb();
reg clk, rst;
reg [511:0] message;
wire [255:0] hashout;
initial begin     
     $dumpfile("sha256.fsdb");
     $dumpvars;   	 
     clk=1'b0;
     rst=1'b0;
     message = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
     #1 rst = 1'b1;
     #5 rst = 1'b0;
     #2000 $finish;
end

always begin
  #(`CYCLE/2) clk=~clk;
end

sha256 #(.message_bit(512)) sha256 (.clk(clk), .rst(rst), .message(message), .hash_out(hashout));
endmodule
