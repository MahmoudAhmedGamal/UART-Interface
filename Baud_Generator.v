module Baud_Generator #(
    parameter CLK_FREQ = 50_000_000,  // Default 50MHz clock
    parameter BAUD_RATE = 9600
)(
    input wire clk,
    input wire reset,    // Active-low reset
    output wire TX_TICK, // Output tick at desired baud rate
    output wire RX_TICK    // 16x oversampling clock (for receiver)
);

// Calculate divisor values
localparam TX_DIVISOR = CLK_FREQ / BAUD_RATE;
localparam RX_DIVISOR = TX_DIVISOR / 16;

reg [15:0] TX_COUNTER;
reg [15:0] RX_COUNTER;
reg TX_TICK_reg;
reg RX_TICK_reg;

// Baud rate generation
always @(posedge clk or posedge reset) begin
    if (reset) begin
        TX_COUNTER <= 0;
        RX_COUNTER <= 0;
        TX_TICK_reg <= 0;
        RX_TICK_reg <= 0;
    end else begin
        // Main baud rate counter (9600 baud)
        if (TX_COUNTER == TX_DIVISOR - 1) begin
            TX_COUNTER <= 0;
            TX_TICK_reg <=  ~TX_TICK_reg ;
        end else begin
            TX_COUNTER <= TX_COUNTER + 1;
            //TX_TICK_reg <= 0;
        end

        // 16x oversampling counter (153600 Hz for 9600 baud)
        if (RX_COUNTER == RX_DIVISOR - 1) begin
            RX_COUNTER <= 0;
            RX_TICK_reg <= ~RX_TICK_reg;
        end else begin
            RX_COUNTER <= RX_COUNTER + 1;
            //RX_TICK_reg <= 0;
        end
    end
end

assign TX_TICK = TX_TICK_reg;
assign RX_TICK = RX_TICK_reg;

endmodule