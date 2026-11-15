`timescale 1ns / 1ps

module ntt_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        mode,
    output wire        done,
    
    input  wire        we,
    input  wire [7:0]  addr,
    input  wire [15:0] din,
    output wire [15:0] dout
);

    wire [7:0]  addr_a, addr_b, addr_zeta;
    wire        we_a, we_b;
    wire [15:0] dout_a, dout_b; 
    wire [15:0] din_a, din_b;   
    wire [15:0] zeta;

    wire        mux_we_a   = we ? 1'b1 : we_a;
    wire [7:0]  mux_addr_a = we ? addr : addr_a;
    wire [15:0] mux_din_a  = we ? din : dout_a;

    assign dout = din_a; 

    dual_bram #(
        .WIDTH(16),
        .LENGTH(256),
        .INIT_FILE("") 
    ) poly_ram_inst (
        .clka(clk),
        .clkb(clk),
        .ena(1'b1),
        .enb(1'b1),
        .wea(mux_we_a),
        .web(we_b),
        .addra(mux_addr_a),
        .addrb(addr_b),
        .dia(mux_din_a),
        .dib(dout_b),
        .doa(din_a),
        .dob(din_b)
    );

    dual_rom #(
        .WIDTH(16),
        .LENGTH(128),
        .INIT_FILE("zetas.mem")
    ) zeta_rom_inst (
        .clk(clk),
        .en(1'b1),
        .addra(addr_zeta),
        .addrb(8'd0),
        .doa(zeta),
        .dob()
    );

    ntt_engine u_engine (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .done(done),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .we_a(we_a),
        .we_b(we_b),
        .dout_a(dout_a),
        .dout_b(dout_b),
        .din_a(din_a),
        .din_b(din_b),
        .addr_zeta(addr_zeta),
        .zeta(zeta)
    );

endmodule