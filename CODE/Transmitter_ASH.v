module Transmitter_ASH(
    input wire clk,
    input wire reset,
    input wire [7:0] TX_Data,
    input wire transmit,
    output wire  busy,
    output wire  TXD
);
    reg [2:0] bit_index  ,bit_index_next;
    reg [2:0] state      ,next_state;
    reg [7:0] data_reg   ,data_reg_next; 
    reg       parity_bit ,parity_bit_next;
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
            data_reg <= data_reg_next;
            bit_index <= bit_index_next;
            parity_bit <= parity_bit_next;
        end
    end
    always @(*) begin 
            next_state = state;
            data_reg_next = data_reg;
            bit_index_next = bit_index;
            parity_bit_next = parity_bit;

            case (state)
                IDLE: begin
                    if (transmit) begin
                        next_state = START; 
                        data_reg_next = TX_Data;
                        parity_bit_next = ^TX_Data; // Calculate even parity
                        bit_index_next = 0;          
                    end  
                end
                START: begin
                    next_state = DATA;
                end
                
                DATA: begin
                    if (bit_index == 7) begin
                        next_state = PARITY;
                    end else begin
                        bit_index_next = bit_index + 1;
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
