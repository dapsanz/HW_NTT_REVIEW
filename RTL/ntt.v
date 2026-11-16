`timescale 1ns / 1ps

module ntt_engine (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        mode,      // 0 = NTT, 1 = INTT
    output reg         done,
    
    // RAM Interface
    output reg  [7:0]  addr_a,
    output reg  [7:0]  addr_b,
    output reg         we_a,
    output reg         we_b,
    output reg  [15:0] dout_a,
    output reg  [15:0] dout_b,
    input  wire [15:0] din_a,
    input  wire [15:0] din_b,
    
    // ROM Interface
    output reg  [7:0]  addr_zeta,
    input  wire [15:0] zeta
);

    localparam S_IDLE        = 4'd0;
    localparam S_OUTER_LOOP  = 4'd1;
    localparam S_INNER_READ  = 4'd2;
    localparam S_INNER_WAIT  = 4'd3;
    localparam S_INNER_CALC  = 4'd4;
    localparam S_INNER_PIPE  = 4'd5;
    localparam S_INNER_WRITE = 4'd6;
    localparam S_DONE        = 4'd7;

    reg [2:0] state;
    reg [7:0] len;
    reg [7:0] j_start;
    reg [7:0] j;
    reg [7:0] k; 
    
    wire [15:0] calc_out_a;
    wire [15:0] calc_out_b;

    wire scale = (mode == 1 && len == 8'd128);
    modular_butterfly u_math_core (
//        .scale(scale),
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .din_a(din_a),
        .din_b(din_b),
        .zeta(zeta),
        .dout_a(calc_out_a),
        .dout_b(calc_out_b)

    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done  <= 0;
            we_a  <= 0;
            we_b  <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    we_a <= 0;
                    we_b <= 0;
                    if (start) begin
                        if (mode == 0) begin
                            len <= 8'd128;
                            k   <= 8'd1;
                        end else begin
                            len <= 8'd2;
                            k   <= 8'd127; 
                        end
                        j_start <= 8'd0;
                        state   <= S_OUTER_LOOP;
                    end
                end
                S_OUTER_LOOP: begin
                    we_a <= 0;
                    we_b <= 0;
                    if (mode == 0 && len == 1 || mode == 1 && len == 0) begin
                        state <= S_DONE;
                    end else begin
                        j <= j_start;
                        addr_zeta <= k; 
                        state <= S_INNER_READ;
                    end
                end

                S_INNER_READ: begin
                    addr_a <= j;
                    addr_b <= j + len;
                    we_a   <= 0;
                    we_b   <= 0;
                    state  <= S_INNER_WAIT; 
                end

                S_INNER_WAIT: begin
                    state <= S_INNER_CALC;
                end

                S_INNER_CALC: begin
//                    dout_a <= calc_out_a;
//                    dout_b <= calc_out_b;
//                    state  <= S_INNER_WRITE;
                    state <= S_INNER_PIPE;
                end
                S_INNER_PIPE: begin
                    dout_a <= calc_out_a;
                    dout_b <= calc_out_b;
                    state  <= S_INNER_WRITE;
                end

                S_INNER_WRITE: begin
                    we_a <= 1;
                    we_b <= 1;
                    
                    if (j < j_start + len - 1) begin
                        j     <= j + 1;
                        state <= S_INNER_READ;
                    end else begin
                        k <= (mode == 0) ? k + 1 : k - 1;
                        if (j_start + 2 * len < 256) begin
                            j_start <= j_start + 2 * len;
                            state   <= S_OUTER_LOOP;
                        end else begin
                            j_start <= 8'd0;
                            len     <= (mode == 0) ? (len >> 1) : (len << 1);
                            state   <= S_OUTER_LOOP;
                        end
                    end
                end
                S_DONE: begin
                    we_a  <= 0;
                    we_b  <= 0;
                    done  <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule