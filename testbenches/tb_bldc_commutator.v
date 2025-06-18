`timescale 1ns / 1ps
`include "bldc_commutator.v"

`ifndef MAIN_CLOCK_PERIOD_NS
    `define MAIN_CLOCK_PERIOD_NS 16'10 // Default clock period in [ns] (10 [ns] = 100 MHz)
`endif

`ifndef STEP_DURATION_CYCLES
    `define STEP_DURATION_CYCLES 32'd1000 // Default step duration in clock cycles (1000 cycles = 100 [ms])    
`endif


module tb_bldc_commutator;

    // --- UUT Signals ---
    reg clk;
    reg reset_n;
    reg enable; // Master enable for motor operation
    reg use_hall; // 1: Use Hall sensors for closed-loop, 0
    reg [2:0] hall_sensors; // 3-bit Hall sensor inputs (H_C, H_B, H_A or H1, H2, H3)
    reg pwm_A; // PWM signal for Phase A (e.g., from pwm_generator_3phase)
    reg pwm_B; // PWM signal for Phase B    
    reg pwm_C; // PWM signal for Phase C
    reg direction; // Motor direction (0: Forward, 1: Reverse)
    reg [31:0] open_loop_step_duration; // Programmable duration (in clock cycles) for each step in open-loop mode

    
    // Outputs
    wire gate_H_A; // Gate drive signal for High-Side MOSFET of Phase A
    wire gate_L_A; // Gate drive signal for Low-Side MOSFET of Phase
    wire gate_H_B; // Gate drive signal for High-Side MOSFET of Phase B
    wire gate_L_B; // Gate drive signal for Low-Side MOSFET of Phase B
    wire gate_H_C; // Gate drive signal for High-Side MOSFET of Phase C
    wire gate_L_C; // Gate drive signal for Low-Side MOSFET of Phase C
    

    // --- UUT Parameters ---
    parameter STEP_DURATION_CYCLES = `STEP_DURATION_CYCLES; // Default step duration in clock cycles
    parameter MAIN_CLOCK_PERIOD_NS = `MAIN_CLOCK_PERIOD_NS; // Main clock period in nanoseconds
    

    // Instantiate the Unit Under Test (UUT)
    bldc_commutator uut (
        .clk(clk),
        .reset_n(reset_n),  
        .enable(enable),
        .use_hall(use_hall), // 1: Use Hall sensors for closed-loop, 0: Use open-loop commutation
        .hall_sensors(hall_sensors), // 3-bit Hall sensor inputs (H_C, H_B, H_A or H1, H2, H3)
        .pwm_A(1'b1), // Simulated 100% duty cycle PWM signal for Phase A
        .pwm_B(1'b1), // Simulated 100% duty cycle PWM signal for Phase B
        .pwm_C(1'b1), // Simulated 100% duty cycle PWM signal for Phase C
        .direction(direction), // Motor direction (0: Forward, 1: Reverse)
        .open_loop_step_duration(STEP_DURATION_CYCLES), // Programmable duration for each step in
        .gate_H_A(gate_H_A),
        .gate_L_A(gate_L_A),
        .gate_H_B(gate_H_B),
        .gate_L_B(gate_L_B),
        .gate_H_C(gate_H_C),
        .gate_L_C(gate_L_C)
    );

     // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(MAIN_CLOCK_PERIOD_NS / 2) clk = ~clk;
    end

    initial begin
        $dumpfile("./sim_output/tb_bldc_commutator.vcd");
        $dumpvars(0, tb_bldc_commutator);
        $display("Starting simulation...");

        // 1. Initialization
        enable = 1'b0;
        reset_n = 1'b0;
        direction = 1'b0; // Forward direction
        use_hall = 1'b0; // Start with open-loop commutation
        hall_sensors = 3'b000; // Initial Hall sensor state (not used in open-loop)

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycle

        // 2. Release reset and enable BLDC commutation
        reset_n = 1'b1;
        enable = 1'b1;
        
        #(STEP_DURATION_CYCLES * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps

        // 3. Reset and switch direction
        reset_n = 1'b0;
        direction = 1'b1; // Reverse direction

        #(MAIN_CLOCK_PERIOD_NS * 10); // Wait for 10 clock cycles
        // 4. De-assert reset to see reverse commutation
        reset_n = 1'b1;
        #(STEP_DURATION_CYCLES * 6 * MAIN_CLOCK_PERIOD_NS); // Wait for 6 steps in reverse  
    
        $display("Ending simulation...");
        $finish;
    end
endmodule
