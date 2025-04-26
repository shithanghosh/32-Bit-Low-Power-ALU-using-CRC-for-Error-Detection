`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:46:20
// Design Name: 
// Module Name: ReversibleALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Peres Gate Module
module PeresGate(input a, b, c, output x, y, z);
    assign x = a;
    assign y = a ^ b;
    assign z = (a & b) ^ c;
endmodule

// Fredkin Gate Module
module FredkinGate(input a, b, c, output x, y, z);
    assign x = a;
    assign y = (~a & c) | (a & b);
    assign z = (a & c) | (~a & b);
endmodule

// Arithmetic Modules
module ReversibleAddSub(
    input [31:0] A, B,
    input sub,
    output [31:0] result
);
    wire [32:0] carry;
    assign carry[0] = sub;
    
    generate
        genvar i;
        for(i=0; i<32; i=i+1) begin: addsub
            PeresGate pg(
                .a(A[i]),
                .b(B[i] ^ sub),
                .c(carry[i]),
                .x(), 
                .y(result[i]),
                .z(carry[i+1])
            );
        end
    endgenerate
endmodule

module ReversibleMultiplier(
    input [31:0] A, B,
    output [31:0] result
);
    wire [63:0] temp_res;
    reg [63:0] accum;
    integer i;
    
    always @(*) begin
        accum = 64'b0;
        for(i=0; i<32; i=i+1) begin
            if(B[i]) begin
                accum = accum + (A << i);
            end
        end
    end
    
    // Reversible implementation using Fredkin gates
    generate
        genvar j;
        for(j=0; j<32; j=j+1) begin: mul
            FredkinGate fg(
                .a(accum[j+31]),
                .b(1'b0),
                .c(1'b0),
                .x(),
                .y(result[j]),
                .z()
            );
        end
    endgenerate
endmodule

module ReversibleDivider(
    input [31:0] dividend,
    input [31:0] divisor,
    output [31:0] quotient
);
    wire [31:0] rem;
    integer i;
    
    generate
        genvar k;
        for(k=31; k>=0; k=k-1) begin: div
            wire cout;
            ReversibleAddSub sub(
                .A({rem[30:0], dividend[k]}),
                .B(divisor),
                .sub(1'b1),
                .result({rem, quotient[k]})
            );
        end
    endgenerate
endmodule

// CRC-32 Module
module CRC32(
    input [31:0] data,
    output reg [31:0] crc
);
    parameter POLY = 32'hEDB88320;
    
    integer i;
    always @(*) begin
        crc = data;
        for(i=0; i<32; i=i+1) begin
            crc = (crc[31] == 1'b1) ? 
                (crc << 1) ^ POLY : 
                (crc << 1);
        end
    end
endmodule

// Main ALU Module with Clock Gating
module ReversibleALU(
    input clk,                      // Main clock
    input [31:0] A, B,              // 32-bit operands
    input [3:0] opcode,             // Operation code
    output reg [31:0] result,       // ALU result
    output [31:0] crc_out           // CRC output
);
    wire [31:0] add_sub_result, mul_result, div_result;

    // Clock gating signals
    wire clk_addsub, clk_mul, clk_div, clk_crc;
    
    // Clock gating instances
    ClockGating cg_addsub(.clk(clk), .enable(opcode == 4'b0000 || opcode == 4'b0001), .gated_clk(clk_addsub));
    ClockGating cg_mul   (.clk(clk), .enable(opcode == 4'b0010), .gated_clk(clk_mul));
    ClockGating cg_div   (.clk(clk), .enable(opcode == 4'b0011), .gated_clk(clk_div));
    ClockGating cg_crc   (.clk(clk), .enable(opcode != 4'b1111), .gated_clk(clk_crc));

    // Instantiating ALU operation modules with clock gating
    ReversibleAddSub addsub(
        .A(A), .B(B), .sub(opcode[0]), 
        .result(add_sub_result)
    );

    ReversibleMultiplier mul(
        .A(A), .B(B), 
        .result(mul_result)
    );

    ReversibleDivider div(
        .dividend(A), .divisor(B), 
        .quotient(div_result)
    );

    CRC32 crc(
        .data(result), 
        .crc(crc_out)
    );

    // ALU operation selection logic
    always @(*) begin
        case(opcode)
            4'b0000: result = add_sub_result;    // Addition
            4'b0001: result = add_sub_result;    // Subtraction
            4'b0010: result = mul_result;        // Multiplication
            4'b0011: result = div_result;        // Division
            default: result = 32'b0;
        endcase
    end
endmodule