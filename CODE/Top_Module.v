module Top_Module #(
    parameter CLK_FREQ = 50_000_000,// Default 50MHz clock
    parameter BAUD_RATE = 9600
)(
    input clk,
    input reset,
    //Transmitter Signals
    input wire transmit,
    input wire [7:0] TX_Data,
    output wire busy,

    //Receiver Signals
    output wire [7:0] RX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);
    // Internal signals
    // Baud rate tick signals
    wire TX_TICK ;
    wire RX_TICK ;
    wire TXD;// Transmit Data line

    // Instantiate Baud Generator
    Baud_Generator #(.CLK_FREQ(CLK_FREQ),.BAUD_RATE(BAUD_RATE)) bd (
        .clk(clk),
        .reset(reset),
        .TX_TICK(TX_TICK),
        .RX_TICK(RX_TICK)
    );

    // Instantiate Transmitter and Receiver modules
    Transmitter_ASH tx(
        .clk(TX_TICK),
        .reset(reset),
        .TX_Data(TX_Data),
        .transmit(transmit),
        .busy(busy),
        .TXD(TXD)
    );
    Receiver_ASH rx(
        .clk(RX_TICK),
        .reset(reset),
        .RXD(TXD),
        .RX_Data(RX_Data),
        .Valid_rx(Valid_rx),
        .Parity_error(Parity_error),
        .Stop_error(Stop_error)
);
endmodule