module ClockGating(
    input clk,               // Main clock
    input enable,            // Enable signal
    output gated_clk         // Gated clock output
);
    reg clk_en;              // Internal signal to hold enable state
    
    // Gating logic: Only pass the clock when enable is high
    always @(posedge clk or negedge enable) begin
        if (!enable)
            clk_en <= 1'b0;   // Disable clock when enable is low
        else
            clk_en <= 1'b1;   // Enable clock when enable is high
    end
    
    assign gated_clk = clk & clk_en;  // Gated clock output
endmodule