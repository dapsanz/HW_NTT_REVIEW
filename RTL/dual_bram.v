`timescale 1ns / 1ps
/*
 * From research paper "High-Performance Hardware Implementation of CRYSTALS-Dilithium"
 * by Luke Beckwith, Duc Tri Nguyen, Kris Gaj
 * at George Mason University, USA
 * https://eprint.iacr.org/2021/1451.pdf
*/
module dual_bram #(parameter WIDTH=96, LENGTH=1024, INIT_FILE="") (clka,clkb,ena,enb,wea,web,addra,addrb,dia,dib,doa,dob);
    input clka,clkb,ena,enb,wea,web;
    input [$clog2(LENGTH)-1:0] addra,addrb;
    input [WIDTH-1:0] dia,dib;
    output [WIDTH-1:0] doa,dob;
    reg[WIDTH-1:0] ram [LENGTH-1:0];
    reg[WIDTH-1:0] doa,dob;
    
    always @(posedge clka) begin if (ena)
        begin
            if (wea)
                ram[addra] <= dia;
                doa <= ram[addra];
            end
        end
        always @(posedge clkb) begin if (enb)
        begin
            if (web)
                ram[addrb] <= dib;
                dob <= ram[addrb];
        end
    end
    
    
    integer i;
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, ram);
        end else begin
            for (i = 0; i < LENGTH; i = i + 1)
                ram[i] = 0;
        end
    end
    
endmodule