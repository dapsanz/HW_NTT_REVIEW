`timescale 1ns / 1ps

module tb_ntt_kyber_kat();

    reg clk;
    reg rst;
    reg start;
    reg mode;
    wire done;

    // 16-Bit Memory Interfaces for Kyber
    wire [7:0]  addr_a, addr_b;
    wire        we_a, we_b;
    wire [15:0] dout_a, dout_b;
    reg  [15:0] din_a, din_b;
    
    wire [7:0]  addr_zeta;
    reg  [15:0] zeta;

    // Instantiate UUT
    ntt_engine uut (
        .clk(clk), .rst(rst), .start(start), .mode(mode), .done(done),
        .addr_a(addr_a), .addr_b(addr_b), .we_a(we_a), .we_b(we_b),
        .dout_a(dout_a), .dout_b(dout_b), .din_a(din_a), .din_b(din_b),
        .addr_zeta(addr_zeta), .zeta(zeta)
    );

    // 16-Bit Memory Arrays
    reg [15:0] poly_ram [0:255];
    reg [15:0] zeta_rom [0:127];
    reg [15:0] expected_ram [0:255]; 

    initial clk = 0;
    always #5 clk = ~clk;

    // RAM Logic
    always @(posedge clk) begin
        if (we_a === 1'b1) poly_ram[addr_a] <= dout_a; 
        if (we_b === 1'b1) poly_ram[addr_b] <= dout_b;
        din_a <= poly_ram[addr_a];
        din_b <= poly_ram[addr_b];
    end

    // ROM Logic
    always @(posedge clk) begin
        zeta <= zeta_rom[addr_zeta];
    end

    integer i = 0;
    integer errors = 0;
    
    // Cycle Counting Logic
    integer cycle_counter = 0;
    reg is_running = 0;

    always @(posedge clk) begin
        if (is_running) begin
            cycle_counter = cycle_counter + 1;
        end
    end

    initial begin
        // Test NTT
        $readmemh("ntt_poly_in.mem", poly_ram);
        $readmemh("zetas.mem", zeta_rom);
        $readmemh("ntt_expected_poly_out.mem", expected_ram);

        rst = 1; start = 0; mode = 0; // mode 0 = NTT
        #20;
        rst = 0;
        #20;
        
        $display("Starting Hardware Kyber NTT...");
        cycle_counter = 0;
        is_running = 1;
        
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1);
        is_running = 0;
        #20;
        
        $display("NTT Completed in %d cycles", cycle_counter);
        $display("Verifying against Kyber C reference...");
        for (i = 0; i < 256; i = i + 1) begin
            if (poly_ram[i] !== expected_ram[i]) begin
                $display("ERROR at index %d: Hardware = %04X, Expected = %04X", i, poly_ram[i], expected_ram[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("========================================");
            $display("NTT KAT PASSED");
            $display("========================================");
        end else begin
            $display("NTT KAT FAILED with %d errors.", errors);
        end
        
        // Test INTT
        $readmemh("intt_poly_in.mem", poly_ram);
        $readmemh("intt_expected_poly_out.mem", expected_ram);
        errors = 0;
        rst = 1; start = 0; mode = 1; // mode 1 = INTT
        #20;
        rst = 0;
        #20;
        
        $display("Starting Hardware Kyber INTT...");
        cycle_counter = 0;
        is_running = 1;
        
        start = 1;
        #10;
        start = 0;

        wait(done == 1'b1);
        is_running = 0;
        #20;
        
        $display("INTT Completed in %d cycles", cycle_counter);
        $display("Verifying against Kyber C reference...");
        for (i = 0; i < 256; i = i + 1) begin
            if (poly_ram[i] !== expected_ram[i]) begin
                $display("ERROR at index %d: Hardware = %04X, Expected = %04X", i, poly_ram[i], expected_ram[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("========================================");
            $display("INTT KAT PASSED");
            $display("========================================");
        end else begin
            $display("NTT KAT FAILED with %d errors.", errors);
        end

        $finish;
    end
endmodule