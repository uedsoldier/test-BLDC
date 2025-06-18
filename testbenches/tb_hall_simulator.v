`timescale 1ns / 1ps
`include "hall_sensor_simulator.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 16'10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef SIM_SPEED_DURATION
    `define SIM_SPEED_DURATION 32'd100000 // Default speed duration for Hall sequence changes (100,000 clock cycles)    
`endif

`ifndef STROBE_PULSE_DURATION
    `define STROBE_PULSE_DURATION 16'd100 // Default strobe pulse duration in clock cycles (100 cycles) 
`endif

module tb_hall_simulator;

    // --- UUT Signals ---
    reg clk;
    reg reset_n;
    reg enable_sim; // Enable the Hall simulation
    reg sim_direction; // 0: Forward sequence, 1: Reverse sequence
    reg [31:0] sim_speed_duration; // Controls how fast the Hall sequence changes (32-bit for extended range)
    reg [15:0] strobe_pulse_duration; // Strobe high duration in clock cycles

    
    // Outputs
    wire [2:0] simulated_hall; // Simulated Hall sensor outputs
    wire hall_sample_strobe; // Strobe signal for logic analyzer

    // --- UUT Parameters ---
    parameter SIM_SPEED_DURATION = `SIM_SPEED_DURATION; // PWM period in clock cycles
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds
    

    // Instantiate the Unit Under Test (UUT)
    hall_sensor_simulator uut (
        .clk(clk),
        .reset_n(reset_n),
        .enable_sim(enable_sim),
        .sim_direction(sim_direction),
        .sim_speed_duration(sim_speed_duration),
        .strobe_pulse_duration(strobe_pulse_duration),
        .simulated_hall(simulated_hall)
    );

     // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("./sim_output/tb_hall_simulator.vcd");
        $dumpvars(0, tb_hall_simulator);
        $display("Starting simulation...");

        // 1. Initialization
        enable_sim = 1'b0;
        reset_n = 1'b0;
        sim_speed_duration = SIM_SPEED_DURATION; // Set speed duration
        strobe_pulse_duration = `STROBE_PULSE_DURATION; // Set strobe pulse duration
        #(MAIN_CLOCK_PERIOD_NS * 1); // Wait for 1 clock cycle

        // 2. Release reset and enable PWM generation
        sim_direction = 1'b0; // Forward sequence
        reset_n = 1'b1;
        enable_sim = 1'b1;
        
        #(SIM_SPEED_DURATION * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 Hall periods

        // 3. Change to reverse sequence
        sim_direction = 1'b1; // Reverse sequence
        #(SIM_SPEED_DURATION * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 Hall periods
    
        $display("Ending simulation...");
        $finish;
    end
endmodule
