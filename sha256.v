module sha256(clk, rst, message, hash_out);
    input  clk, rst;
    input  [511:0] message;
    output [255:0] hash_out;
    reg [6:0] round;
    wire [31:0] h0 = 32'h6A09E667, h1 = 32'hBB67AE85, h2 = 32'h3C6EF372, h3 = 32'hA54FF53A;
    wire [31:0] h4 = 32'h510E527F, h5 = 32'h9B05688C, h6 = 32'h1F83D9AB, h7 = 32'h5BE0CD19;
    reg [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;
    wire [31:0] a_d, b_d, c_d, d_d, e_d, f_d, g_d, h_d;
    wire [31:0] keyi, wordi;
    wire output_valid;

    assign output_valid = (round == 64);
    
    always @(*)
    begin
        if (output_valid) begin
            hash_out = {h0+a_q, h1+b_q, h2+c_q, h3+d_q, h4+e_q, h5+f_q, h6+g_q, h7+h_q};
        end
        else begin
            hash_out = 256'b0;
        end
    end

    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            a_q <= h0; b_q <= h1; c_q <= h2; d_q <= h3;
            e_q <= h4; f_q <= h5; g_q <= h6; h_q <= h7;
            round <= 0;
        end
        else begin
            a_q <= a_d; b_q <= b_d; c_q <= c_d; d_q <= d_d;
            e_q <= e_d; f_q <= f_d; g_q <= g_d; h_q <= h_d;
            round <= round + 1;
        end
    end

    sha256_mainloop sha256_mainloop0(
        .ki(keyi), .wi(wordi),
        .a_in(a_q), .b_in(b_q), .c_in(c_q), .d_in(d_q),
        .e_in(e_q), .f_in(f_q), .g_in(g_q), .h_in(h_q),
        .a_out(a_d), .b_out(b_d), .c_out(c_d), .d_out(d_d),
        .e_out(e_d), .f_out(f_d), .g_out(g_d), .h_out(h_d)
    );
    word_machine word_machine0(.clk(clk), .rst(rst), .message(message), .word(wordi));
    key_machine key_machine0(.clk(clk), .rst(rst), .key(keyi));
endmodule

module sha256_mainloop(ki, wi, a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in, a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out);
    input [31:0] ki, wi;
    input [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in;
    output [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out;
    wire [31:0] ch, maj, S0, S1, t1, t2;

    assign ch = ((e_in & f_in) ^ (~e_in & g_in));
    assign maj = (a_in & b_in) ^ (a_in & c_in) ^ (b_in & c_in);
    assign S0 = ({a_in[1:0], a_in[31:2]} ^ {a_in[12:0], a_in[31:13]} ^ {a_in[21:0], a_in[31:22]});
    assign S1 = ({e_in[5:0], e_in[31:6]} ^ {e_in[10:0], e_in[31:11]} ^ {e_in[24:0], e_in[31:25]});
    assign t1 = h_in + S1 + ch + ki + wi;
    assign t2 = S0 + maj;
    assign a_out = t1 + t2;
    assign b_out = a_in;
    assign c_out = b_in;
    assign d_out = c_in;
    assign e_out = d_in + t1;
    assign f_out = e_in;
    assign g_out = f_in;
    assign h_out = g_in;
endmodule

module word_machine(clk, rst, message, word);
    input clk, rst;
    input [511:0] message;
    output [31:0] word;
    wire [31:0] word_i_2, word_i_15, word_i_7, word_i_16, word_next, s0, s1;
    reg [511:0] wordstack_q;
    wire [511:0] wordstack_d;

    assign word_i_2 = wordstack_q[63:32];
    assign word_i_15 = wordstack_q[479:448];
    assign word_i_7 = wordstack_q[223:192];
    assign word_i_16 = wordstack_q[511:480];
    assign word_next = s1 + word_i_7 + s0 + word_i_16;
    assign s0 = ({word_i_15[6:0], word_i_15[31:7]} ^ {word_i_15[17:0], word_i_15[31:18]} ^ (word_i_15 >> 3));
    assign s1 = ({word_i_2[16:0], word_i_2[31:17]} ^ {word_i_2[18:0], word_i_2[31:19]} ^ (word_i_2 >> 10));
    assign wordstack_d = {wordstack_q[479:0], word_next};
    assign word = wordstack_q[511:480];

    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            wordstack_q <= message;
        end
        else begin
            wordstack_q <= wordstack_d;
        end
    end
endmodule

module key_machine(clk, rst, key);
    input clk, rst;
    output [31:0] key;
    reg [2047:0] key_q;
    wire [2047:0] key_d;

    assign key_d = {key_q[2015:0], key_q[2047:2016]};
    assign key = key_q[2047:2016];

    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            key_q <= {
                32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
                32'h3956c25b, 32'h59f111f1, 32'h923f82a4, 32'hab1c5ed5,
                32'hd807aa98, 32'h12835b01, 32'h243185be, 32'h550c7dc3,
                32'h72be5d74, 32'h80deb1fe, 32'h9bdc06a7, 32'hc19bf174,
                32'he49b69c1, 32'hefbe4786, 32'h0fc19dc6, 32'h240ca1cc,
                32'h2de92c6f, 32'h4a7484aa, 32'h5cb0a9dc, 32'h76f988da,
                32'h983e5152, 32'ha831c66d, 32'hb00327c8, 32'hbf597fc7,
                32'hc6e00bf3, 32'hd5a79147, 32'h06ca6351, 32'h14292967,
                32'h27b70a85, 32'h2e1b2138, 32'h4d2c6dfc, 32'h53380d13,
                32'h650a7354, 32'h766a0abb, 32'h81c2c92e, 32'h92722c85,
                32'ha2bfe8a1, 32'ha81a664b, 32'hc24b8b70, 32'hc76c51a3,
                32'hd192e819, 32'hd6990624, 32'hf40e3585, 32'h106aa070,
                32'h19a4c116, 32'h1e376c08, 32'h2748774c, 32'h34b0bcb5,
                32'h391c0cb3, 32'h4ed8aa4a, 32'h5b9cca4f, 32'h682e6ff3,
                32'h748f82ee, 32'h78a5636f, 32'h84c87814, 32'h8cc70208,
                32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
            };
        end
        else begin
            key_q <= key_d;
        end
    end
endmodule