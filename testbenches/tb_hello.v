`timescale 1ns / 1ps
`include "hello.v"

module hello_tb;

    // Inputs
    reg a;

    // Outputs
    wire b;

    // Instantiate the Unit Under Test (UUT)
    hello uut (
        .a (a),
        .b (b)
    );

    initial begin
        $dumpfile("./sim_output/tb_hello.vcd");
        $dumpvars(0, hello_tb);
        $display("Starting simulation...");

        a = 0;

        #10; // Wait for 10 time units
        $display("Input a = %b, Output b = %b", a, b);

        a = 1;
        #10; // Wait for another 10 time units
        $display("Input a = %b, Output b = %b", a, b);

    
        $display("Ending simulation...");
    end
endmodule
