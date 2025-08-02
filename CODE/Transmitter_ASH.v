module Transmitter_ASH(
    input wire clk,
    input wire reset,
    input wire [7:0] TX_Data,
    input wire transmit,
    output wire  busy,
    output wire  TXD
);
    reg [2:0] bit_index;
    reg parity_bit;
    reg [3:0] state,next_state;
    reg [7:0] data_reg; 

    localparam IDLE = 3'b000,
               START = 3'b001,
               DATA = 3'b010,
               PARITY = 3'b011,
               STOP = 3'b100;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            parity_bit <= 0;
            data_reg <= 0;
            bit_index <= 0;
        end
        else begin
            state <= next_state;
            if (state == IDLE && transmit) begin
                data_reg  <= TX_Data;
                parity_bit <= ^TX_Data; // Even parity
                bit_index <= 0;
            end

            if (state == DATA && bit_index < 7) begin
                bit_index <= bit_index + 1;
            end
        end
    end
    always @(*) begin 
            next_state = state;
            case (state)
                IDLE: begin
                    if (transmit) begin
                        next_state = START;            
                    end  
                end
                START: begin
                    next_state = DATA;
                end
                
                DATA: begin
                    if (bit_index == 7) begin
                        next_state = PARITY;
                    end else begin
                        next_state = DATA;
                    end
                end
                
                PARITY: begin
                    next_state = STOP;
                end
                
                STOP: begin
                    next_state = IDLE; 
                end

                default: next_state = IDLE;
            endcase
    end
    assign TXD = (state == IDLE )? 1: (state == START)? 0: (state == DATA)? data_reg[bit_index] : (state == PARITY) ? parity_bit : 1;
    assign busy = (state == IDLE)? 0 : 1;

endmodule



    
