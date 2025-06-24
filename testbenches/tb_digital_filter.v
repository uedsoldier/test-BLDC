`timescale 1ns / 1ps
`include "digital_input_filter.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef FILTER_LEN
    `define FILTER_LEN 100 // Default filter length after reset
`endif



module tb_digital_filter;

    // General parameters
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds

    // General inputs
    reg clk; // Main clock signal
    reg reset_n; // Active low reset signal


    // --- UUT Signals ---

    // Digital Input Filter parameters
    parameter FILTER_LEN = `FILTER_LEN; 
    
    // Digital Input Filter Inputs
    reg noisy_in; // Noisy input signal
    reg [31:0] filter_len_in; // Filter length value
    reg load_filter_len; // Pulse to load new filter length

    // Digital Input Filter outputs
    wire filtered_out; // Filtered (debounced) output
    wire filtered_out_n; // Inverted filtered output 


    // Instantiate the PWM generator
    digital_input_filter digital_input_filter_i (
        .clk(clk),                           // Clock signal
        .reset_n(reset_n),                   // Active-low reset
        .noisy_in(noisy_in),                 // Noisy input signal
        .filter_len_in(filter_len_in),       // Filter length value (from AXI or other module)
        .load_filter_len(load_filter_len),   // Pulse to load new filter length (not used in this test)
        .filtered_out(filtered_out),         // Filtered (debounced) output
        .filtered_out_n(filtered_out_n)      // Inverted filtered output
    );


        
    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    // -- Test stimulus generation --
    initial begin
        $dumpfile("./sim_output/tb_digital_filter.vcd");
        $dumpvars(0, tb_digital_filter);
        $display("Starting simulation...");

        // 1. Initialization
        reset_n = 1'b0; // Assert reset
        noisy_in = 1'b0; // Initialize noisy input to low
        filter_len_in = FILTER_LEN; // Set filter length to default value
        load_filter_len = 1'b0; // No load filter length pulse

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycle

        // 2. Release reset
        reset_n = 1'b1; // Release reset
        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles

        // 3. Load filter length
        load_filter_len = 1'b1; // Pulse to load new filter length
        #(MAIN_CLOCK_PERIOD_NS * 2); // Wait for 2 clock cycles
        load_filter_len = 1'b0; // Clear load filter length pulse

        // 4. Apply noisy input signal
        noisy_in = 1'b1; // Set noisy input to high
        #(MAIN_CLOCK_PERIOD_NS * (FILTER_LEN + 100)); // Wait for FILTER_LEN + 100 clock cycles

        // 5. Change noisy input to low
        noisy_in = 1'b0; // Set noisy input to low
        #(MAIN_CLOCK_PERIOD_NS * (FILTER_LEN + 100)); // Wait for FILTER_LEN + 100 clock cycles
        
    
        $display("Ending simulation...");
        $finish;
    end

endmodule
    
    

