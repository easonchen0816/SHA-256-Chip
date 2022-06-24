module sha256(clk, rst, load, message_8, hash_out_16);
    input  clk, rst, load;
    input [7:0] message_8;
    output [15:0] hash_out_16;

    reg [15:0] hash_out_16;
    reg [255:0] hash_out;
    reg [511:0] message_pre;
    reg [9:0] round;
    wire [31:0] h0 = 32'h6A09E667, h1 = 32'hBB67AE85, h2 = 32'h3C6EF372, h3 = 32'hA54FF53A;
    wire [31:0] h4 = 32'h510E527F, h5 = 32'h9B05688C, h6 = 32'h1F83D9AB, h7 = 32'h5BE0CD19;
    reg [31:0] a_q, b_q, c_q, d_q, e_q, f_q, g_q, h_q;
    wire [31:0] a_d, b_d, c_d, d_d, e_d, f_d, g_d, h_d;
    wire [31:0] keyi1, wordi1, keyi2, wordi2;
    wire output_valid;
    wire input_valid;
    wire pre_mainloop;
    wire mainloop_valid;
    wire operate_valid;
    reg complete;
    integer i;

    assign output_valid = (round > 97 && round <= 113);
    assign input_valid = load ? 1 : ( round >= 64 ? 0 : input_valid);
    assign mainloop_valid = ( round > 64 && round <= 96 );
    assign pre_mainloop = ( round == 64 );
    assign pre_output = ( round == 97 );
    assign operate_valid = load ? 1 : (complete ? 0 : operate_valid);

    always @(posedge clk or posedge rst)begin
        if (rst) begin
            complete <= 0;
        end
        else if (round == 113) begin
            complete <= 1;
        end
        else begin
            complete <= complete;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            message_pre <= 0;
        end
        else if (input_valid) begin
            for (i = 7; i >= 0; i = i - 1) begin
                message_pre[504 - round * 8 + i] <= message_8[i];
            end
        end
        else if (complete) begin
            message_pre <= 0;
        end
        else begin
            message_pre <= message_pre;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_q <= 0; b_q <= 0; c_q <= 0; d_q <= 0;
            e_q <= 0; f_q <= 0; g_q <= 0; h_q <= 0;
        end
        else if (input_valid) begin
            a_q <= 0; b_q <= 0; c_q <= 0; d_q <= 0;
            e_q <= 0; f_q <= 0; g_q <= 0; h_q <= 0;
        end
        else if (pre_mainloop) begin
            a_q <= h0; b_q <= h1; c_q <= h2; d_q <= h3;
            e_q <= h4; f_q <= h5; g_q <= h6; h_q <= h7;
        end
        else if (mainloop_valid) begin
            a_q <= a_d; b_q <= b_d; c_q <= c_d; d_q <= d_d;
            e_q <= e_d; f_q <= f_d; g_q <= g_d; h_q <= h_d;
        end
        else if (complete) begin
            a_q <= 0; b_q <= 0; c_q <= 0; d_q <= 0;
            e_q <= 0; f_q <= 0; g_q <= 0; h_q <= 0;
        end
        else begin
            a_q <= a_q; b_q <= b_q; c_q <= c_q; d_q <= d_q;
            e_q <= e_q; f_q <= f_q; g_q <= g_q; h_q <= h_q;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_out_16 <= 0;
        end
        else if (output_valid) begin
            hash_out_16[15:0] <= hash_out[1823 - 16 * round -:16];
        end
        else if (complete) begin
            hash_out_16 <= 0;
        end
        else begin
            hash_out_16 <= 0;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            round <= 0;
        end
        else if (operate_valid) begin
            round <= round + 1;
        end
        else if (complete) begin
            round <= 0;
        end
        else begin
            round <= round;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_out <= 0;
        end
        else if (pre_output) begin
            hash_out <= {h0+a_q, h1+b_q, h2+c_q, h3+d_q, h4+e_q, h5+f_q, h6+g_q, h7+h_q};
        end
        else if (complete) begin
            hash_out <= 0;
        end
        else begin
            hash_out <= hash_out;
        end
    end

    sha256_mainloop sha256_mainloop0(
        .ki1(keyi1), .wi1(wordi1), .ki2(keyi2), .wi2(wordi2),
        .a_in(a_q), .b_in(b_q), .c_in(c_q), .d_in(d_q),
        .e_in(e_q), .f_in(f_q), .g_in(g_q), .h_in(h_q),
        .a_out(a_d), .b_out(b_d), .c_out(c_d), .d_out(d_d),
        .e_out(e_d), .f_out(f_d), .g_out(g_d), .h_out(h_d)
    );
    word_machine word_machine0(.clk(clk), .rst(rst), .input_valid(input_valid), .pre_mainloop(pre_mainloop), .mainloop_valid(mainloop_valid), .complete(complete), .message(message_pre), .word1(wordi1), .word2(wordi2));
    key_machine key_machine0(.clk(clk), .rst(rst), .input_valid(input_valid), .pre_mainloop(pre_mainloop), .mainloop_valid(mainloop_valid), .complete(complete), .key1(keyi1), .key2(keyi2));
endmodule

module sha256_mainloop(ki1, wi1, ki2, wi2, a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in, a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out);
    input [31:0] ki1, wi1, ki2, wi2;
    input [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in;
    output [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out;
    wire [31:0] ch1, maj1, S01, S11, t11, t21;
    wire [31:0] ch2, maj2, S02, S12, t12, t22;
    wire [31:0] a_m, b_m, c_m, d_m, e_m, f_m, g_m, h_m;

    assign ch1 = ((e_in & f_in) ^ (~e_in & g_in));
    assign maj1 = (a_in & b_in) ^ (a_in & c_in) ^ (b_in & c_in);
    assign S01 = ({a_in[1:0], a_in[31:2]} ^ {a_in[12:0], a_in[31:13]} ^ {a_in[21:0], a_in[31:22]});
    assign S11 = ({e_in[5:0], e_in[31:6]} ^ {e_in[10:0], e_in[31:11]} ^ {e_in[24:0], e_in[31:25]});
    assign t11 = h_in + S11 + ch1 + ki1 + wi1;
    assign t21 = S01 + maj1;
    assign a_m = t11 + t21;
    assign b_m = a_in;
    assign c_m = b_in;
    assign d_m = c_in;
    assign e_m = d_in + t11;
    assign f_m = e_in;
    assign g_m = f_in;
    assign h_m = g_in;

    assign ch2 = ((e_m & f_m) ^ (~e_m & g_m));
    assign maj2 = (a_m & b_m) ^ (a_m & c_m) ^ (b_m & c_m);
    assign S02 = ({a_m[1:0], a_m[31:2]} ^ {a_m[12:0], a_m[31:13]} ^ {a_m[21:0], a_m[31:22]});
    assign S12 = ({e_m[5:0], e_m[31:6]} ^ {e_m[10:0], e_m[31:11]} ^ {e_m[24:0], e_m[31:25]});
    assign t12 = h_m + S12 + ch2 + ki2 + wi2;
    assign t22 = S02 + maj2;
    assign a_out = t12 + t22;
    assign b_out = a_m;
    assign c_out = b_m;
    assign d_out = c_m;
    assign e_out = d_m + t12;
    assign f_out = e_m;
    assign g_out = f_m;
    assign h_out = g_m;
endmodule

module word_machine(clk, rst, input_valid, pre_mainloop, mainloop_valid, complete, message, word1, word2);
    input clk, rst;
    input input_valid, pre_mainloop, mainloop_valid, complete;
    input [511:0] message;
    output [31:0] word1, word2;
    wire [31:0] word_i_2, word_i_15, word_i_7, word_i_16, word_next1, s01, s11;
    wire [31:0] word_i_1, word_i_14, word_i_6, word_next2, s02, s12;
    reg [511:0] wordstack_q;
    wire [511:0] wordstack_d;

    assign word_i_2 = wordstack_q[63:32];
    assign word_i_15 = wordstack_q[479:448];
    assign word_i_7 = wordstack_q[223:192];
    assign word_i_16 = wordstack_q[511:480];
    assign word_next1 = s11 + word_i_7 + s01 + word_i_16;
    assign s01 = ({word_i_15[6:0], word_i_15[31:7]} ^ {word_i_15[17:0], word_i_15[31:18]} ^ (word_i_15 >> 3));
    assign s11 = ({word_i_2[16:0], word_i_2[31:17]} ^ {word_i_2[18:0], word_i_2[31:19]} ^ (word_i_2 >> 10));
    assign word1 = wordstack_q[511:480];

    assign word_i_1 = wordstack_q[31:0];
    assign word_i_14 = wordstack_q[447:416];
    assign word_i_6 = wordstack_q[191:160];
    assign word_next2 = s12 + word_i_6 + s02 + word_i_15;
    assign s02 = ({word_i_14[6:0], word_i_14[31:7]} ^ {word_i_14[17:0], word_i_14[31:18]} ^ (word_i_14 >> 3));
    assign s12 = ({word_i_1[16:0], word_i_1[31:17]} ^ {word_i_1[18:0], word_i_1[31:19]} ^ (word_i_1 >> 10));
    assign word2 = wordstack_q[479:448];

    assign wordstack_d = {wordstack_q[447:0], word_next1, word_next2};
    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            wordstack_q <= 0;
        end
        else if (input_valid) begin
            wordstack_q <= 0;
        end
        else if (pre_mainloop) begin
            wordstack_q <= message;
        end
        else if (mainloop_valid) begin
            wordstack_q <= wordstack_d;
        end
        else if (complete) begin
            wordstack_q <= wordstack_d;
        end
        else begin
            wordstack_q <= wordstack_q;
        end
    end
endmodule

module key_machine(clk, rst, input_valid, pre_mainloop, complete, mainloop_valid, key1, key2);
    input clk, rst;
    input input_valid, pre_mainloop, mainloop_valid, complete;
    output [31:0] key1, key2;
    reg [2047:0] key_q;
    wire [2047:0] key_d;

    assign key_d = {key_q[1983:0], key_q[2047:2016], key_q[2015:1984]};
    assign key1 = key_q[2047:2016];
    assign key2 = key_q[2015:1984];

    always @(posedge clk or posedge rst)
    begin
        if (rst) begin
            key_q <= 0;
        end
        else if (input_valid) begin
            key_q <= 0;
        end
        else if (pre_mainloop) begin
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
        else if (mainloop_valid) begin
            key_q <= key_d;
        end
        else if (complete) begin
            key_q <= 0;
        end
        else begin
            key_q <= key_q;
        end
    end
endmodule