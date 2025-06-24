// Digital Input Filter Module
module digital_input_filter #(
    parameter DEFAULT_FILTER_LEN = 32'd50000  // Default filter length after reset
)(
    input wire clk,                           // Clock signal
    input wire reset_n,                       // Active-low reset

    input wire noisy_in,                      // Noisy input signal
    input wire [31:0] filter_len_in,          // Filter length value (from AXI or other module)
    input wire load_filter_len,               // Pulse to load new filter length

    output reg filtered_out,                  // Filtered (debounced) output
    output wire filtered_out_n                // Inverted filtered output
);

    reg [31:0] filter_counter;                // Counter to measure signal stability
    reg [31:0] filter_len;                    // Internal register for the active filter length
    reg prev_input;                           // Stores the previous state of the input

    // Main sequential logic
    always @(posedge clk or negedge reset_n) begin
        // Asynchronous reset condition
        if (!reset_n) begin
            filter_counter <= 32'd0;
            filter_len     <= DEFAULT_FILTER_LEN;
            prev_input     <= 1'b0;
            filtered_out   <= 1'b0;
        // Synchronous operation
        end else begin
            // Load new filter length if requested
            if (load_filter_len)
                filter_len <= filter_len_in;

            // If the input is stable
            if (noisy_in == prev_input) begin
                // Increment counter if not yet reached the filter length
                if (filter_counter < filter_len)
                    filter_counter <= filter_counter + 1'b1;
                // If counter reaches the length, validate the input
                else
                    filtered_out <= noisy_in;
            // If the input changes (is unstable)
            end else begin
                prev_input     <= noisy_in;      // Store the new input value
                filter_counter <= 32'd0;        // Reset the stability counter
            end
        end
    end

    // Assign the inverted output
    assign filtered_out_n = ~filtered_out;

endmodule