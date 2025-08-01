`timescale 1ns/1ps

module Top_Module_tb();

    // Parameters
    localparam CLK_FREQ = 50_000_000;
    localparam BAUD_RATE = 9600;
    // Testbench signals
    reg clk;
    reg reset;
    //reg RXD;
    wire [7:0] RX_Data;
    reg transmit;
    //wire TXD;
    wire busy;
    reg [7:0] TX_Data;
    wire Valid_rx;
    wire Parity_error;
    wire Stop_error;

    // Instantiate DUT
    Top_Module #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .reset(reset),
        //.RXD(RXD),
        //.TXD(TXD),
        .RX_Data(RX_Data),
        .transmit(transmit),
        .busy(busy),
        .TX_Data(TX_Data),
        .Valid_rx(Valid_rx),
        .Parity_error(Parity_error),
        .Stop_error(Stop_error)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Clock generation
    end
    
    task reset_sequence;
        begin
            clk = 0;
            reset = 1;
            TX_Data = 8'b0;
            transmit = 0;
            @(negedge clk);
        end
    endtask
    task Validate_Outputs;
        input [7:0] DATA_SEND;
        begin
            if (RX_Data !== DATA_SEND)
                $display("TEST FAILED: DATA_SEND = %b, DATA_RECEIVED = %b, busy = %b, Stop_error = %b, Parity_error = %b", DATA_SEND, RX_Data, busy, Stop_error, Parity_error);
            else if (Parity_error)
                $display("TEST FAILED: DATA_SEND = %b, DATA_RECEIVED = %b, busy = %b, Stop_error = %b, Parity_error = %b", DATA_SEND, RX_Data, busy, Stop_error, Parity_error);
            else if (Stop_error)
                $display("TEST FAILED: DATA_SEND = %b, DATA_RECEIVED = %b, busy = %b Stop_error = %b, Parity_error = %b", DATA_SEND, RX_Data, busy, Stop_error, Parity_error);
            else
                $display("TEST COMPLETED: DATA_SEND = %b, DATA_RECEIVED = %b, busy = %b, Stop_error = %b, Parity_error = %b", DATA_SEND, RX_Data, busy, Stop_error, Parity_error);
        end
    endtask
    initial begin
        reset_sequence();
        reset = 0;
        @(negedge clk);

        repeat(100)begin
            TX_Data = $random;
            transmit = 1;
            wait (busy == 1);
            transmit = 0;
            @(negedge clk);
            wait (busy == 0);
            @(negedge clk);
            @(negedge clk);

            Validate_Outputs(TX_Data);
            @(negedge clk);
        end
        $stop;
    end
    initial begin
        $monitor("TX_Data=%b, RX_Data=%b, busy=%b", TX_Data, RX_Data, busy);
    end
endmodule
