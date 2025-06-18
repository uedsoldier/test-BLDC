module pwm_generator_3phase (
    input  wire clk,
    input  wire reset_n,
    input  wire enable,
    input  wire [15:0] pwm_period,  
    input  wire [15:0] duty_a,
    input  wire [15:0] duty_b,
    input  wire [15:0] duty_c,
    output reg  pwm_a,
    output reg  pwm_b,
    output reg  pwm_c
);

    reg [15:0] counter;

    always @(posedge clk or negedge reset_n) begin
        if (reset_n == 1'b0)
            counter <= 16'd0;
        else if (enable) begin
            if (counter >= pwm_period - 1)
                counter <= 16'd0;
            else
                counter <= counter + 16'd1;
        end else
            counter <= 16'd0;
    end

    always @(*) begin
        if (reset_n == 1'b0) begin  // Force outputs to 0 during reset_n
            pwm_a = 1'b0;
            pwm_b = 1'b0;
            pwm_c = 1'b0;
        end else if (!enable) begin
            pwm_a = 1'b0;
            pwm_b = 1'b0;
            pwm_c = 1'b0;
        end else begin
            pwm_a = (counter < duty_a);
            pwm_b = (counter < duty_b);
            pwm_c = (counter < duty_c);
        end
    end

endmodule

