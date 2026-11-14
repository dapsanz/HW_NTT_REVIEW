`timescale 1ns / 1ps

module modular_butterfly (
    input  wire        mode,      // 0 = NTT (DIT), 1 = INTT (DIF)
    input  wire [15:0] din_a,
    input  wire [15:0] din_b,
    input  wire [15:0] zeta,
    output reg  [15:0] dout_a,
    output reg  [15:0] dout_b
);

    // ----------------------------------------------------
    // KYBER SPECIFIC CONSTANTS
    // ----------------------------------------------------
    localparam signed [15:0] QINV      = -16'sd3327;  // Kyber QINV (62209 unsigned)
    localparam signed [15:0] Q         =  16'sd3329;  // Kyber Prime
    localparam signed [15:0] BARRETT_V =  16'sd20159; // Kyber Barrett Constant ((1<<26) + Q/2)/Q
    localparam signed [31:0] BARR_BIAS =  32'sd33554432; // 1 << 25

    // Cast all inputs to signed for proper Two's Complement math
    wire signed [15:0] a_sig = din_a;
    wire signed [15:0] b_sig = din_b;
    wire signed [15:0] z_sig = zeta;

    // ====================================================
    // PATH 1: FORWARD NTT (Cooley-Tukey)
    // t = mont_reduce(b * zeta)
    // out_a = a + t;  out_b = a - t;
    // ====================================================
    wire signed [31:0] ntt_mult      = b_sig * z_sig;
    wire signed [15:0] ntt_mont_t    = $signed(ntt_mult[15:0]) * QINV; 
    wire signed [31:0] ntt_mont_prod = ntt_mont_t * Q;
    wire signed [31:0] ntt_mont_sub  = ntt_mult - ntt_mont_prod;
    wire signed [15:0] ntt_mont_res  = ntt_mont_sub[31:16]; 
    
    wire signed [15:0] ntt_out_a     = a_sig + ntt_mont_res;
    wire signed [15:0] ntt_out_b     = a_sig - ntt_mont_res;

    // ====================================================
    // PATH 2: INVERSE NTT (Gentleman-Sande)
    // out_a = barrett_reduce(a + b)
    // out_b = mont_reduce((b - a) * zeta)
    // ====================================================
    
    // INTT Addition Path (with Barrett Reduction)
    wire signed [15:0] intt_add      = a_sig + b_sig;
    wire signed [31:0] barr_t1       = intt_add * BARRETT_V;
    wire signed [31:0] barr_t2       = (barr_t1 + BARR_BIAS) >>> 26; 
    wire signed [15:0] barr_t3       = barr_t2[15:0] * Q;
    wire signed [15:0] intt_out_a    = intt_add - barr_t3;

    // INTT Subtraction Path (with Montgomery Reduction)
    wire signed [15:0] intt_sub       = b_sig - a_sig;
    wire signed [31:0] intt_mult      = intt_sub * z_sig;
    wire signed [15:0] intt_mont_t    = $signed(intt_mult[15:0]) * QINV; 
    wire signed [31:0] intt_mont_prod = intt_mont_t * Q;
    wire signed [31:0] intt_mont_sub  = intt_mult - intt_mont_prod;
    wire signed [15:0] intt_out_b     = intt_mont_sub[31:16];

    // ====================================================
    // OUTPUT MULTIPLEXER
    // ====================================================
    always @(*) begin
        if (mode == 1'b0) begin
            dout_a = ntt_out_a;
            dout_b = ntt_out_b;
        end else begin
            dout_a = intt_out_a;
            dout_b = intt_out_b;
        end
    end

endmodule
