`timescale 1ns / 1ps

module modular_butterfly (
    input  wire         clk,      // For pipeling
    input  wire         rst,  
    
    input  wire        mode,      // 0 = NTT (DIT), 1 = INTT (DIF)
//    input  wire        scale,
    input  wire [15:0] din_a,
    input  wire [15:0] din_b,
    input  wire [15:0] zeta,
    output reg  [15:0] dout_a,
    output reg  [15:0] dout_b
);

    // ----------------------------------------------------
    // KYBER SPECIFIC CONSTANTS
    // ----------------------------------------------------
    localparam signed [15:0] QINV      = -16'sd3327;     // Kyber QINV (62209 unsigned)
    localparam signed [15:0] Q         =  16'sd3329;     // Kyber Prime
    localparam signed [15:0] BARRETT_V =  16'sd20159;    // Kyber Barrett Constant ((1<<26) + Q/2)/Q
    localparam signed [31:0] BARR_BIAS =  32'sd33554432; // 1 << 25

    // Cast all inputs to signed for proper Two's Complement math
    wire signed [15:0] a_sig = din_a;
    wire signed [15:0] b_sig = din_b;
    wire signed [15:0] z_sig = zeta;
    
    // Optimization 2: Shared Resources for NTT / INTT . Xing & Li, HOPE
    wire signed [15:0] mont_in   = (mode == 1'b0) ? b_sig : (b_sig - a_sig);
    wire signed [31:0] shared_mult = mont_in * z_sig;
    
    // ====================================================
    // Optimization 4 - 2 Stage Pipeline
    // ====================================================
    reg signed [31:0] reg_shared_mult;
    reg signed [15:0] reg_a_sig;
    reg signed [15:0] reg_b_sig;
    reg               reg_mode;
    
    always @(posedge clk) begin
        if (rst) begin
            reg_shared_mult <= 0;
            reg_a_sig       <= 0;
            reg_b_sig       <= 0;
            reg_mode        <= 0;
        end else begin
            reg_shared_mult <= shared_mult;
            reg_a_sig       <= a_sig;
            reg_b_sig       <= b_sig;
            reg_mode        <= mode;
        end 
    end

    wire signed [15:0] m_low      = reg_shared_mult[15:0];

    // End of Pipeline - 2 Cycle //
    
    // ====================================================
    //  Optimization 2 & 3: Shared Resources / Shift and Adds for Mult with Q/QINV
    // ====================================================
//    wire signed [15:0] m_low      = shared_mult[15:0];
    wire signed [15:0] shared_t   = m_low - (m_low <<< 8) - (m_low <<< 10) - (m_low <<< 11); //(QINV = -3327 = -(2^11 + 2^10 + 2^8 - 1)) 
    wire signed [31:0] t_ext      = {{16{shared_t[15]}}, shared_t};
    wire signed [31:0] shared_prod = (t_ext <<< 11) + (t_ext <<< 10) + (t_ext <<< 8) + t_ext; //(Q = 3329 = 2^11 + 2^10 + 2^8 + 1)
    
//    wire signed [15:0] shared_t    = $signed(shared_mult[15:0]) * QINV; //Obsolote
//    wire signed [31:0] shared_prod = shared_t * Q; //Obsolote
//    wire signed [31:0] shared_sub  = shared_mult - shared_prod;
    wire signed [31:0] shared_sub  = reg_shared_mult - shared_prod; // for pipeline
    wire signed [15:0] shared_res  = shared_sub[31:16];
    
    wire signed [15:0] shared_add  = a_sig + ((mode == 1'b0) ? shared_res : b_sig);
    wire signed [15:0] ntt_b_comb     = a_sig - shared_res;  
    wire signed [15:0] intt_unscaled_a = (shared_add >= 16'sd3329) ? (shared_add - 16'sd3329) : shared_add;
    wire signed [15:0] intt_unscaled_b = shared_res;
    
     // ====================================================
    // OPTIMIZATION 1: INTT SCALING - Zhang et Al
    // ====================================================   
    wire signed [15:0] intt_scaled_a = intt_unscaled_a[0] ? ((intt_unscaled_a >>> 1) + 16'sd1665) : (intt_unscaled_a >>> 1);
    wire signed [15:0] intt_scaled_b = intt_unscaled_b[0] ? ((intt_unscaled_b >>> 1) + 16'sd1665) : (intt_unscaled_b >>> 1);
    
    wire signed [15:0] intt_out_a = intt_scaled_a;
    wire signed [15:0] intt_out_b = intt_scaled_b;
    
    wire signed [15:0] ntt_out_a   = shared_add; //pipeline output
    wire signed [15:0] ntt_out_b   = ntt_b_comb; //pipeline output
    
//    wire signed [15:0] ntt_out_a     = a_sig + shared_res;
//    wire signed [15:0] ntt_out_b     = ntt_b_comb;  
            
    
// OBSOLOTE - 2 Path method, muxed output. Optimizied Above (Optimization 2)
//    // ====================================================
//    // PATH 1: FORWARD NTT (Cooley-Tukey)
//    // t = mont_reduce(b * zeta)
//    // out_a = a + t;  out_b = a - t;
//    // ====================================================
//    wire signed [31:0] ntt_mult      = b_sig * z_sig;
//    wire signed [15:0] ntt_mont_t    = $signed(ntt_mult[15:0]) * QINV; 
//    wire signed [31:0] ntt_mont_prod = ntt_mont_t * Q;
//    wire signed [31:0] ntt_mont_sub  = ntt_mult - ntt_mont_prod;
//    wire signed [15:0] ntt_mont_res  = ntt_mont_sub[31:16]; 
    
//    wire signed [15:0] ntt_out_a     = a_sig + ntt_mont_res;
//    wire signed [15:0] ntt_out_b     = a_sig - ntt_mont_res;

//    // ====================================================
//    // PATH 2: INVERSE NTT (Gentleman-Sande)
//    // out_a = barrett_reduce(a + b)
//    // out_b = mont_reduce((b - a) * zeta)
//    // ====================================================
    
//    // INTT Addition Path (with Barrett Reduction)
//    wire signed [15:0] intt_add      = a_sig + b_sig;
//    wire signed [31:0] barr_t1       = intt_add * BARRETT_V;
//    wire signed [31:0] barr_t2       = (barr_t1 + BARR_BIAS) >>> 26; 
//    wire signed [15:0] barr_t3       = barr_t2[15:0] * Q;
//    wire signed [15:0] intt_unscaled_a = intt_add - barr_t3;

//    // INTT Subtraction Path (with Montgomery Reduction)
//    wire signed [15:0] intt_sub       = b_sig - a_sig;
//    wire signed [31:0] intt_mult      = intt_sub * z_sig;
//    wire signed [15:0] intt_mont_t    = $signed(intt_mult[15:0]) * QINV; 
//    wire signed [31:0] intt_mont_prod = intt_mont_t * Q;
//    wire signed [31:0] intt_mont_sub  = intt_mult - intt_mont_prod;
//    wire signed [15:0] intt_unscaled_b = intt_mont_sub[31:16];
    
    
// OBSOLOTE - OPTIMIZED ABOVE
//    // Montgomery Multiplication by 1441 for Port A
//    wire signed [31:0] scale_mult_a      = intt_unscaled_a * 16'sd1441;
//    wire signed [15:0] scale_mont_t_a    = $signed(scale_mult_a[15:0]) * QINV;
//    wire signed [31:0] scale_mont_prod_a = scale_mont_t_a * Q;
//    wire signed [15:0] scale_out_a       = (scale_mult_a - scale_mont_prod_a) >>> 16;

//    // Montgomery Multiplication by 1441 for Port B
//    wire signed [31:0] scale_mult_b      = intt_unscaled_b * 16'sd1441;
//    wire signed [15:0] scale_mont_t_b    = $signed(scale_mult_b[15:0]) * QINV;
//    wire signed [31:0] scale_mont_prod_b = scale_mont_t_b * Q;
//    wire signed [15:0] scale_out_b       = (scale_mult_b - scale_mont_prod_b) >>> 16;

//    // Multiplex the output: Only apply the scale on the final stage
//    wire signed [15:0] intt_out_a = scale ? scale_out_a : intt_unscaled_a;
//    wire signed [15:0] intt_out_b = scale ? scale_out_b : intt_unscaled_b;

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
