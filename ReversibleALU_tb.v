`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2025 15:54:22
// Design Name: 
// Module Name: ReversibleALU_tb
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
module ReversibleALU_tb;

    // Testbench signals
    reg clk;
    reg [31:0] A, B;
    reg [3:0] opcode;
    wire [31:0] result;
    wire [31:0] crc_out;

    // Instantiate the ALU module
    ReversibleALU uut (
        .clk(clk),
        .A(A),
        .B(B),
        .opcode(opcode),
        .result(result),
        .crc_out(crc_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test stimulus
    initial begin
        // Monitor signals
        $monitor("Time: %0t | A: %h | B: %h | Opcode: %b | Result: %h | CRC: %h", 
                  $time, A, B, opcode, result, crc_out);

        // Test addition
        A = 32'h00000015;      // A = 21
        B = 32'h0000000A;      // B = 10
        opcode = 4'b0000;       // Addition
        #20;

        // Test subtraction
        opcode = 4'b0001;       // Subtraction
        #20;

        // Test multiplication
        A = 32'h00000003;      // A = 3
        B = 32'h00000004;      // B = 4
        opcode = 4'b0010;       // Multiplication
        #20;

        // Test division
        A = 32'h00000010;      // A = 16
        B = 32'h00000004;      // B = 4
        opcode = 4'b0011;       // Division
        #20;

        // Test invalid opcode (default case)
        opcode = 4'b1111;       // Invalid operation
        #20;

        // Test with larger values
        A = 32'hFFFFFFFF;      // Max 32-bit value
        B = 32'h00000002;      // B = 2
        opcode = 4'b0000;       // Addition
        #20;

        // Test CRC computation (result from previous operation)
        opcode = 4'b0100;       // CRC generation
        #20;

        // Finish simulation
        $finish;
    end
endmodule
