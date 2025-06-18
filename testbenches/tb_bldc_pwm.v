`timescale 1ns / 1ps
`include "bldc_commutator.v"
`include "pwm_generator_3phase.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 16'10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef STEP_DURATION_CYCLES
    `define STEP_DURATION_CYCLES 32'd1000 // Default step duration in clock cycles (1000 cycles = 100 [ms])    
`endif

`ifndef PWM_PERIOD
    `define PWM_PERIOD 16'd1000 // Default PWM period in clock cycles ( 1000 = 100 [kHz])
`endif

`ifndef DUTY
    `define DUTY 16'd500 // Default duty cycle all phases (50% for a 1000 clock cycle period)
`endif

module tb_bldc_pwm;

    // General parameters
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds

    // General inputs
    reg clk; // Main clock signal
    reg reset_n; // Active low reset signal

    // --- UUT Signals ---

    // BLDC parameters
    parameter STEP_DURATION_CYCLES = `STEP_DURATION_CYCLES; // Default step duration in clock cycles

    // BLDC Commutator Inputs
    reg bldc_enable; // Master enable for motor operation
    reg bldc_use_hall; // 1: Use Hall sensors for closed-loop, 0: Use open-loop commutation
    reg [2:0] bldc_hall_sensors; // 3-bit Hall sensor inputs (H_C, H_B, H_A or H1, H2, H3)

    reg bldc_direction; // Motor direction (0: Forward, 1: Reverse)
    reg [31:0] bldc_open_loop_step_duration; // Programmable duration (in clock cycles) for each step in open-loop mode

    // BLDC outputs
    wire bldc_gate_L_A; // Gate drive signal for Low-Side MOSFET of Phase A
    wire bldc_gate_H_A; // Gate drive signal for High-Side MOSFET of Phase A
    wire bldc_gate_H_B; // Gate drive signal for High-Side MOSFET of Phase B
    wire bldc_gate_L_B; // Gate drive signal for Low-Side MOSFET of Phase B
    wire bldc_gate_H_C; // Gate drive signal for High-Side MOSFET of Phase C
    wire bldc_gate_L_C; // Gate drive signal for Low-Side MOSFET of Phase C
    
    // PWM parameters
    parameter PWM_PERIOD = `PWM_PERIOD; // PWM period in clock cycles
    parameter DUTY = `DUTY; // Duty cycle for phase A

    // PWM Generator Inputs
    reg pwm_enable; // Enable signal for PWM generator

    // PWM Generator Outputs
    wire pwm_a; // PWM signal for Phase A
    wire pwm_b; // PWM signal for Phase B
    wire pwm_c; // PWM signal for Phase C

    // Instantiate the PWM generator
    pwm_generator_3phase pwm_generator_3phase_i (
        .clk(clk),
        .reset_n(reset_n),
        .enable(pwm_enable),
        .pwm_period(PWM_PERIOD),
        .duty_a(DUTY),
        .duty_b(DUTY),
        .duty_c(DUTY),
        .pwm_a(pwm_a),
        .pwm_b(pwm_b),
        .pwm_c(pwm_c)
    );

    // Instantiate the BLDC commutator
    bldc_commutator bldc_commutator_i (
        .clk(clk),
        .reset_n(reset_n),
        .enable(bldc_enable),
        .use_hall(bldc_use_hall),
        .hall_sensors(bldc_hall_sensors),
        .pwm_A(pwm_a), // Use PWM signals from the PWM generator
        .pwm_B(pwm_b),
        .pwm_C(pwm_c),
        .direction(bldc_direction),
        .open_loop_step_duration(STEP_DURATION_CYCLES),
        .gate_H_A(bldc_gate_H_A),
        .gate_L_A(bldc_gate_L_A),
        .gate_H_B(bldc_gate_H_B),
        .gate_L_B(bldc_gate_L_B),
        .gate_H_C(bldc_gate_H_C),
        .gate_L_C(bldc_gate_L_C)
    );
        
    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    // -- Test stimulus generation --
    initial begin
        $dumpfile("./sim_output/tb_bldc_pwm.vcd");
        $dumpvars(0, tb_bldc_pwm);
        $display("Starting simulation...");

        // 1. Initialization
        bldc_enable = 1'b0; // Disable BLDC commutation initially
        reset_n = 1'b0;
        bldc_direction = 1'b0; // Forward direction
        bldc_use_hall = 1'b0; // Start with open-loop commutation
        bldc_hall_sensors = 3'b000; // Initial Hall sensor state (not used in open-loop)
        bldc_open_loop_step_duration = STEP_DURATION_CYCLES; // Set step duration

        pwm_enable = 1'b0; // Disable PWM initially

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycle

        // 2. Release reset and enable BLDC commutation
        reset_n = 1'b1;
        bldc_enable = 1'b1; // Enable BLDC commutation
        pwm_enable = 1'b1; // Enable PWM generation
        
        #(STEP_DURATION_CYCLES * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps

        // 3. Reset and switch direction
        reset_n = 1'b0;
        bldc_direction = 1'b1; // Reverse direction

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles
        // 4. De-assert reset to see reverse commutation
        reset_n = 1'b1;
        #(STEP_DURATION_CYCLES * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps in reverse  
    
        $display("Ending simulation...");
        $finish;
    end



endmodule
    
    

