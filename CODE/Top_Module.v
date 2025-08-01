module Top_Module #(
    parameter CLK_FREQ = 50_000_000,
    parameter BAUD_RATE = 9600
)(
    input clk,
    input reset,
    // UART interface signals
    //input wire RXD,
    //output wire TXD,
    // User interface
    output wire [7:0] RX_Data,
    input wire transmit,
    output wire busy,
    input wire [7:0] TX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);
    wire TX_TICK ;
    wire RX_TICK ;
    wire TXD;
    Baud_Generator #(.CLK_FREQ(CLK_FREQ),.BAUD_RATE(BAUD_RATE)) bd (
        .clk(clk),
        .reset(reset),
        .TX_TICK(TX_TICK),
        .RX_TICK(RX_TICK)
    );
    Transmitter_ASH tx(
        .clk(TX_TICK),
        .reset(reset),
        //.baud_tick(TX_TICK),        
        .TX_Data(TX_Data),
        .transmit(transmit),
        .busy(busy),
        .TXD(TXD)
    );
    Receiver_ASH rx(
        .clk(RX_TICK),
        .reset(reset),
        .RXD(TXD),
        //.baud_tick(RX_TICK),         // Baud rate tick from generator
        .RX_Data(RX_Data),
        .Valid_rx(Valid_rx),
        .Parity_error(Parity_error),
        .Stop_error(Stop_error)
);
endmodule
