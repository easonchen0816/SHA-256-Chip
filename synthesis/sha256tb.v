`timescale 1ns/10ps
`define CYCLE 20
module tb();
reg clk, rst, ld;
reg [7:0] message;
wire [15:0] hashout;
initial begin     
     $dumpfile("sha256.fsdb");
     $dumpvars;   	 
     clk = 1'b0;
     rst = 1'b0;
     ld = 1'b0;
     message = 8'd0;
     #1 rst = 1'b1;
     #5 rst = 1'b0;
     #2 ld = 1'b1;
        message = 8'h61;
     #4 ld = 1'b0;
     #(`CYCLE-4) message = 8'h62;
     #(`CYCLE) message = 8'h63;
     #(`CYCLE) message = 8'h80;
     #(`CYCLE) message = 8'h00;
     #(`CYCLE*59) message = 8'h18;
     #(`CYCLE*60) $finish;
end

always begin
  #(`CYCLE/2) clk=~clk;
end

sha256 sha256(.clk(clk), .rst(rst), .load(ld), .message_8(message), .hash_out_16(hashout));
endmodule