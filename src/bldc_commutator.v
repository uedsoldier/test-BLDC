module bldc_commutator (
    input  wire        clk,          // Clock signal
    input  wire        reset_n,      // Asynchronous reset (active low)
    input  wire        enable,       // Master enable for motor operation

    input  wire        use_hall,     // 1: Use Hall sensors for closed-loop, 0: Use open-loop commutation
    input  wire [2:0]  hall_sensors, // 3-bit Hall sensor inputs (H_C, H_B, H_A or H1, H2, H3)

    input  wire        pwm_A,        // PWM signal for Phase A (e.g., from pwm_generator_3phase)
    input  wire        pwm_B,        // PWM signal for Phase B
    input  wire        pwm_C,        // PWM signal for Phase C

    input  wire        direction,    // Motor direction (0: Forward, 1: Reverse)

    input  wire [31:0] open_loop_step_duration, // Programmable duration (in clock cycles) for each step in open-loop mode

    output reg          gate_H_A,    // Gate drive signal for High-Side MOSFET of Phase A
    output reg          gate_L_A,    // Gate drive signal for Low-Side MOSFET of Phase A
    output reg          gate_H_B,    // Gate drive signal for High-Side MOSFET of Phase B
    output reg          gate_L_B,    // Gate drive signal for Low-Side MOSFET of Phase B
    output reg          gate_H_C,    // Gate drive signal for High-Side MOSFET of Phase C
    output reg          gate_L_C     // Gate drive signal for Low-Side MOSFET of Phase C
);

    // --- Commutation Step Definitions ---
    // These parameters define the 6 electrical commutation steps.
    // The comments indicate which phases are energized (e.g., A+ B- means Phase A positive, Phase B negative).
    parameter STEP_1 = 3'd0; // A+ B-
    parameter STEP_2 = 3'd1; // A+ C-
    parameter STEP_3 = 3'd2; // B+ C-
    parameter STEP_4 = 3'd3; // B+ A-
    parameter STEP_5 = 3'd4; // C+ A-
    parameter STEP_6 = 3'd5; // C+ B-

    reg [2:0] step;      // Current active commutation step
    reg [31:0] counter;  // Counter used for timing step advancements in open-loop mode

    // --- Hall Sensor Decoding Function ---
    // This function maps the 3-bit Hall sensor input to the corresponding
    // commutation step, adjusting the mapping based on the desired direction.
    function [2:0] decode_hall;
        input [2:0] h;         // Current Hall sensor readings
        input       dir_in;    // Desired motor direction (0: Forward, 1: Reverse)
        begin
            if (dir_in == 0) begin // Forward direction mapping
                // Maps Hall pattern to the step that should be active for forward rotation
                case (h)
                    3'b001: decode_hall = STEP_6;
                    3'b101: decode_hall = STEP_5;
                    3'b100: decode_hall = STEP_4;
                    3'b110: decode_hall = STEP_3;
                    3'b010: decode_hall = STEP_2;
                    3'b011: decode_hall = STEP_1;
                    default: decode_hall = STEP_1; // Fallback for invalid Hall states
                endcase
            end else begin // Reverse direction mapping
                // Maps Hall pattern to the step that should be active for reverse rotation
                case (h)
                    3'b001: decode_hall = STEP_1;
                    3'b101: decode_hall = STEP_6;
                    3'b100: decode_hall = STEP_5;
                    3'b110: decode_hall = STEP_4;
                    3'b010: decode_hall = STEP_3;
                    3'b011: decode_hall = STEP_2;
                    default: decode_hall = STEP_1; // Fallback for invalid Hall states
                endcase
            end
        end
    endfunction

    // --- Synchronous State Control Logic ---
    // This block updates the current commutation step and the internal counter.
    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 1'b0) begin
            // On reset, initialize to the first step and clear the counter.
            step <= STEP_1;
            counter <= 32'd0;
        end else if (enable) begin
            // Only operate if the module is enabled.
            if (use_hall) begin
                // Closed-loop mode: step is determined by Hall sensors and desired direction.
                step <= decode_hall(hall_sensors, direction);
            end else begin
                // Open-loop mode: step advances based on a fixed-time counter.
                counter <= counter + 32'd1;
                // When counter reaches the programmable duration, advance to the next step.
                if (counter == open_loop_step_duration) begin
                    counter <= 32'd0; // Reset counter for the next step
                    if (direction == 0) begin // Forward progression
                        step <= step + 3'd1;
                        if (step == STEP_6) step <= STEP_1; // Wrap around from STEP_6 to STEP_1
                    end else begin // Reverse progression
                        step <= step - 3'd1;
                        if (step == STEP_1) step <= STEP_6; // Wrap around from STEP_1 to STEP_6
                    end
                end
            end
        end
    end

    // --- Combinational Output Logic for Gate Drives ---
    // This block generates the actual gate drive signals (INH_X, INL_X).
    // It's a combinational block, so outputs react immediately to input changes (clk, reset_n, enable, step, pwm_X).
    always @(*) begin
        if (reset_n == 1'b0) begin
            // Priority 1: If reset is active, force all gate outputs to 0 (safe state).
            gate_H_A = 0; gate_L_A = 0;
            gate_H_B = 0; gate_L_B = 0;
            gate_H_C = 0; gate_L_C = 0;
        end else if (!enable) begin
            // Priority 2: If module is not enabled, force all gate outputs to 0.
            gate_H_A = 0; gate_L_A = 0;
            gate_H_B = 0; gate_L_B = 0;
            gate_H_C = 0; gate_L_C = 0;
        end else begin
            // If enabled and not in reset, generate PWM based on current step.
            // Default all gates to 0 before the case statement to ensure no latches are inferred.
            gate_H_A = 0; gate_L_A = 0;
            gate_H_B = 0; gate_L_B = 0;
            gate_H_C = 0; gate_L_C = 0;

            // Activate specific high-side and low-side gates based on the current step.
            // The PWM signal directly modulates these gate drive outputs.
            case (step)
                STEP_1: begin gate_H_A = pwm_A; gate_L_B = pwm_B; end
                STEP_2: begin gate_H_A = pwm_A; gate_L_C = pwm_C; end
                STEP_3: begin gate_H_B = pwm_B; gate_L_C = pwm_C; end
                STEP_4: begin gate_H_B = pwm_B; gate_L_A = pwm_A; end
                STEP_5: begin gate_H_C = pwm_C; gate_L_A = pwm_A; end
                STEP_6: begin gate_H_C = pwm_C; gate_L_B = pwm_B; end
            endcase
        end
    end

endmodule