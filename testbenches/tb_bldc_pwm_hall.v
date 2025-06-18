`timescale 1ns / 1ps
`include "bldc_commutator.v"
`include "pwm_generator_3phase.v"
`include "hall_sensor_simulator.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 16'10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef PWM_PERIOD
    `define PWM_PERIOD 16'd1000 // Default PWM period in clock cycles ( 1000 = 100 [kHz])
`endif

`ifndef DUTY
    `define DUTY 16'd500 // Default duty cycle all phases (50% for a 1000 clock cycle period)
`endif

`ifndef HALL_SENSOR_PERIOD_CLK
    `define HALL_SENSOR_PERIOD_CLK 32'd100000 // Default speed duration for Hall sequence changes (100,000 clock cycles)    
`endif

`ifndef SENSOR_STROBE_DURATION_CLK
    `define SENSOR_STROBE_DURATION_CLK 16'd100 // Default strobe pulse duration in clock cycles (100 cycles) 
`endif

module tb_bldc_pwm_hall;

    // General parameters
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds

    // General inputs
    reg clk; // Main clock signal
    reg reset_n; // Active low reset signal

    // --- UUT Signals ---

    // BLDC parameters

    // BLDC Commutator Inputs
    reg bldc_enable; // Master enable for motor operation
    reg bldc_use_hall; // 1: Use Hall sensors for closed-loop, 0: Use open-loop commutation

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

    // Hall Sensor Simulation Parameters
    parameter HALL_SENSOR_PERIOD_CLK = `HALL_SENSOR_PERIOD_CLK; // Speed duration for Hall sequence changes
    parameter SENSOR_STROBE_DURATION_CLK = `SENSOR_STROBE_DURATION_CLK; // Strobe pulse duration in clock cycles

    // Hall Sensor Simulation Inputs
    reg hall_enable_sim; // Enable signal for Hall sensor simulation
    reg hall_sim_direction; // Direction for Hall sensor simulation (0: Forward, 1: Reverse)
    reg [31:0] hall_sim_speed_duration; // Speed duration for Hall sensor simulation
    reg [15:0] hall_sim_strobe_pulse_duration; // Strobe pulse duration for Hall sensor simulation

    // Hall Sensor Simulation Outputs
    wire [2:0] hall_simulated_hall; // Simulated Hall sensor outputs
    wire hall_sample_strobe; // Strobe signal for logic analyzer

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
        .hall_sensors(hall_simulated_hall),
        .pwm_A(pwm_a), // Use PWM signals from the PWM generator
        .pwm_B(pwm_b),
        .pwm_C(pwm_c),
        .direction(bldc_direction),
        .open_loop_step_duration(bldc_open_loop_step_duration), 
        .gate_H_A(bldc_gate_H_A),
        .gate_L_A(bldc_gate_L_A),
        .gate_H_B(bldc_gate_H_B),
        .gate_L_B(bldc_gate_L_B),
        .gate_H_C(bldc_gate_H_C),
        .gate_L_C(bldc_gate_L_C)
    );

    // Instantiate the Hall sensor simulator
    hall_sensor_simulator hall_sensor_simulator_i (
        .clk(clk),
        .reset_n(reset_n),
        .enable_sim(hall_enable_sim),
        .sim_direction(hall_sim_direction),
        .sim_speed_duration(hall_sim_speed_duration),
        .strobe_pulse_duration(hall_sim_strobe_pulse_duration),
        .simulated_hall(hall_simulated_hall),
        .hall_sample_strobe(hall_sample_strobe)
    );
        
    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    // -- Test stimulus generation --
    initial begin
        $dumpfile("./sim_output/tb_bldc_pwm_hall.vcd");
        $dumpvars(0, tb_bldc_pwm_hall);
        $display("Starting simulation...");

        // 1. Initialization
        bldc_enable = 1'b0; // Disable BLDC commutation initially
        reset_n = 1'b0;
        bldc_direction = 1'b0; // Forward direction
        bldc_use_hall = 1'b1; // Start with closed-loop commutation using Hall sensors
        bldc_open_loop_step_duration = 32'd0; // closed-loop mode, so step duration is not used
        pwm_enable = 1'b0; // Disable PWM initially
        hall_enable_sim = 1'b0; // Disable Hall sensor simulation initially
        hall_sim_direction = 1'b0; // Forward direction for Hall simulation
        hall_sim_speed_duration = HALL_SENSOR_PERIOD_CLK; // Set speed duration for Hall simulation
        hall_sim_strobe_pulse_duration = SENSOR_STROBE_DURATION_CLK; // Set strobe pulse duration for Hall simulation

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles

        // 2. Release reset and enable BLDC commutation with Hall sensors disabled
        reset_n = 1'b1;
        bldc_enable = 1'b1; // Enable BLDC commutation
        pwm_enable = 1'b1; // Enable PWM generation
        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles

        // 3. Enable Hall sensor simulation
        hall_enable_sim = 1'b1;
        #(HALL_SENSOR_PERIOD_CLK * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps

        // // 3. Reset and switch direction
        // reset_n = 1'b0;
        // bldc_direction = 1'b1; // Reverse direction

        // #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles
        // // 4. De-assert reset to see reverse commutation
        // reset_n = 1'b1;
        // #(HALL_SENSOR_PERIOD_CLK * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps in reverse  
    
        $display("Ending simulation...");
        $finish;
    end



endmodule
    
    

