`timescale 1ns / 1ps

module tb_ntt_top();

    reg clk;
    reg rst;
    reg start;
    reg mode;
    wire done;

    reg         we;
    reg  [7:0]  addr;
    reg  [15:0] din;
    wire [15:0] dout;

    ntt_top uut (
        .clk(clk), .rst(rst), .start(start), .mode(mode), .done(done),
        .we(we), .addr(addr), .din(din), .dout(dout)
    );

    reg [15:0] expected_ram [0:255]; 

    initial clk = 0;
    always #5 clk = ~clk;

    integer i = 0;
    integer errors = 0;
    
    integer cycle_counter = 0;
    reg is_running = 0;

    always @(posedge clk) begin
        if (is_running) begin
            cycle_counter = cycle_counter + 1;
        end
    end

    initial begin
        we = 0; addr = 0; din = 0;

        // Test NTT
        // Load
        $readmemh("ntt_poly_in.mem", uut.poly_ram_inst.ram);
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
            // Read 
            if (uut.poly_ram_inst.ram[i] !== expected_ram[i]) begin
                $display("ERROR at index %d: Hardware = %04X, Expected = %04X", i, uut.poly_ram_inst.ram[i], expected_ram[i]);
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
        //Load
        $readmemh("intt_poly_in.mem", uut.poly_ram_inst.ram);
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
            if (uut.poly_ram_inst.ram[i] !== expected_ram[i]) begin
                $display("ERROR at index %d: Hardware = %04X, Expected = %04X", i, uut.poly_ram_inst.ram[i], expected_ram[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) begin
            $display("========================================");
            $display("INTT KAT PASSED");
            $display("========================================");
        end else begin
            $display("INTT KAT FAILED with %d errors.", errors);
        end

        $finish;
    end
endmodule