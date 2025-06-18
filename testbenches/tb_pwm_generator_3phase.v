`timescale 1ns / 1ps
`include "pwm_generator_3phase.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 16'10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef PWM_PERIOD
    `define PWM_PERIOD 16'd1000 // Default PWM period in clock cycles ( 1000 = 100 [kHz])
`endif

`ifndef DUTY_A
    `define DUTY_A 16'd500 // Default duty cycle for phase A (50% for a 1000 clock cycle period)
`endif

`ifndef DUTY_B
    `define DUTY_B 16'd300 // Default duty cycle for phase B (30% for a 1000 clock cycle period)  
`endif

`ifndef DUTY_C
    `define DUTY_C 16'd200 // Default duty cycle for phase C (20% for a 1000 clock cycle period)  
`endif

module tb_pwm_generator_3phase;

    // --- UUT Signals ---
    reg clk;
    reg reset_n;
    reg enable;

    
    // Outputs
    wire pwm_a;
    wire pwm_b;
    wire pwm_c;

    // --- UUT Parameters ---
    parameter PWM_PERIOD = `PWM_PERIOD; // PWM period in clock cycles
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds
    

    // Instantiate the Unit Under Test (UUT)
    pwm_generator_3phase uut (
        .clk(clk),
        .reset_n(reset_n),
        .enable(enable),
        .pwm_period(PWM_PERIOD),
        .duty_a(`DUTY_A),
        .duty_b(`DUTY_B),
        .duty_c(`DUTY_C),
        .pwm_a(pwm_a),
        .pwm_b(pwm_b),
        .pwm_c(pwm_c)
    );

     // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("./sim_output/tb_pwm_generator_3phase.vcd");
        $dumpvars(0, tb_pwm_generator_3phase);
        $display("Starting simulation...");

        // 1. Initialization
        enable = 1'b0;
        reset_n = 1'b0;
        #(MAIN_CLOCK_PERIOD_NS * 1); // Wait for 1 clock cycle

        // 2. Release reset and enable PWM generation
        reset_n = 1'b1;
        enable = 1'b1;
        #(PWM_PERIOD * 10 * MAIN_CLOCK_PERIOD_NS); // Wait for 10 PWM periods

    
        $display("Ending simulation...");
        $finish;
    end
endmodule
