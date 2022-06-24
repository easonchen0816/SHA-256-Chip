`timescale 1ns/10ps
`define CYCLE 50
module tb();
reg clk, rst; 
reg [511:0]message;
wire hashout;
initial begin     
     $dumpfile("sha256.fsdb");
     $dumpvars;   	  
     clk=1'b0;
     rst=1'b0;
     message = {
  256'h6162638000000000000000000000000000000000000000000000000000000000,
  256'h0000000000000000000000000000000000000000000000000000000000000018
};
     #1 rst=1'b1;
     #5 rst=1'b0;
     #(300*`CYCLE) $finish;
end

always begin
  #(`CYCLE/2) clk=~clk;
end

sha sha256(clk, rst, message, hashout);
endmodule
