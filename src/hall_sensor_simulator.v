module hall_sensor_simulator (
    input  wire        clk,                // Global clock signal
    input  wire        reset_n,            // Global reset signal, active LOW
    input  wire        enable_sim,         // Enable the Hall simulation
    input  wire        sim_direction,      // 0: Forward sequence, 1: Reverse sequence
    input  wire [31:0] sim_speed_duration, // Controls how fast the Hall sequence changes (32-bit for extended range)
    input  wire [15:0] strobe_pulse_duration, // Strobe high duration in clock cycles

    output reg  [2:0]  simulated_hall,     // Simulated Hall sensor outputs
    output reg         hall_sample_strobe  // Strobe signal for logic analyzer
);

    reg [2:0] current_hall_state;
    reg [31:0] speed_counter; // Adjusted to 32 bits to match sim_speed_duration

    // Counter for strobe pulse duration (Adjusted to 16 bits)
    reg [15:0] strobe_pulse_counter_reg; // Max 65535 cycles

    // Define the Hall sequences
    localparam [2:0] FWD_HALL_SEQ_0 = 3'b011;
    localparam [2:0] FWD_HALL_SEQ_1 = 3'b010;
    localparam [2:0] FWD_HALL_SEQ_2 = 3'b110;
    localparam [2:0] FWD_HALL_SEQ_3 = 3'b100;
    localparam [2:0] FWD_HALL_SEQ_4 = 3'b101;
    localparam [2:0] FWD_HALL_SEQ_5 = 3'b001;

    localparam [2:0] REV_HALL_SEQ_0 = 3'b001;
    localparam [2:0] REV_HALL_SEQ_1 = 3'b101;
    localparam [2:0] REV_HALL_SEQ_2 = 3'b100;
    localparam [2:0] REV_HALL_SEQ_3 = 3'b110;
    localparam [2:0] REV_HALL_SEQ_4 = 3'b010;
    localparam [2:0] REV_HALL_SEQ_5 = 3'b011;


    // --- State Machine for Hall Sequence Generation ---
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin // Active low reset condition
            current_hall_state   <= FWD_HALL_SEQ_0;
            simulated_hall       <= FWD_HALL_SEQ_0;
            speed_counter        <= 32'd0;
            hall_sample_strobe   <= 1'b0;
            strobe_pulse_counter_reg <= 16'd0; // Reset value adjusted to 16 bits
        end else if (enable_sim) begin
            // Logic to advance Hall state
            speed_counter <= speed_counter + 32'd1;
            if (speed_counter >= sim_speed_duration) begin // Time to advance Hall state
                speed_counter <= 32'd0;

                // Determine the next Hall state based on current state and direction
                if (sim_direction == 0) begin // Forward sequence
                    case (current_hall_state)
                        FWD_HALL_SEQ_0: current_hall_state <= FWD_HALL_SEQ_1;
                        FWD_HALL_SEQ_1: current_hall_state <= FWD_HALL_SEQ_2;
                        FWD_HALL_SEQ_2: current_hall_state <= FWD_HALL_SEQ_3;
                        FWD_HALL_SEQ_3: current_hall_state <= FWD_HALL_SEQ_4;
                        FWD_HALL_SEQ_4: current_hall_state <= FWD_HALL_SEQ_5;
                        FWD_HALL_SEQ_5: current_hall_state <= FWD_HALL_SEQ_0; // Wrap-around
                        default: current_hall_state <= FWD_HALL_SEQ_0;
                    endcase
                end else begin // Reverse sequence
                    case (current_hall_state)
                        REV_HALL_SEQ_0: current_hall_state <= REV_HALL_SEQ_1;
                        REV_HALL_SEQ_1: current_hall_state <= REV_HALL_SEQ_2;
                        REV_HALL_SEQ_2: current_hall_state <= REV_HALL_SEQ_3;
                        REV_HALL_SEQ_3: current_hall_state <= REV_HALL_SEQ_4;
                        REV_HALL_SEQ_4: current_hall_state <= REV_HALL_SEQ_5;
                        REV_HALL_SEQ_5: current_hall_state <= REV_HALL_SEQ_0; // Wrap-around
                        default: current_hall_state <= REV_HALL_SEQ_0;
                    endcase
                end
                // Start strobe pulse when Hall state changes
                hall_sample_strobe <= 1'b1;
                strobe_pulse_counter_reg <= 16'd0; // Reset strobe counter to start new pulse
            end else begin
                // Continue or end strobe pulse
                if (strobe_pulse_counter_reg < strobe_pulse_duration) begin
                    strobe_pulse_counter_reg <= strobe_pulse_counter_reg + 16'd1;
                    hall_sample_strobe <= 1'b1; // Keep strobe high
                end else begin
                    hall_sample_strobe <= 1'b0; // End strobe pulse
                end
            end
            simulated_hall <= current_hall_state; // Output the current Hall state
        end else begin
            // When simulation is disabled, hold last Hall state, reset counters, strobe low
            speed_counter        <= 32'd0;
            hall_sample_strobe   <= 1'b0;
            strobe_pulse_counter_reg <= 16'd0;
        end
    end

endmodule