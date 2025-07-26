module Transmitter_ASH(
    input wire clk,
    input wire reset,
    //input baud_tick,         // Baud rate tick from generator
    input wire [7:0] TX_Data,
    input wire transmit,
    //input baud_tick,         // Baud rate tick from generator
    output wire  busy,
    output wire  TXD
);
    reg [3:0] sample_counter,sample_counter_next;  // For oversampling (16x)

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
            sample_counter <= 0;

        end
        else begin
            state <= next_state;
            // Bit index updates only during DATA_BIT
            if(state == START) bit_index <= 0;

            if (state == DATA)
                bit_index <= bit_index + 1;
            else
                bit_index <= 0;
            // Load data when starting transmission
            if (state == IDLE && transmit) begin
                data_reg  <= TX_Data;
                parity_bit <= ^TX_Data; // Even parity
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
                    else 
                        next_state = IDLE;
                end
                
                START: begin
                    //if (baud_tick) begin
                        //if (sample_counter == 15) begin  // Sample at middle of start bit
                        //    sample_counter_next <= 0;
                            next_state = DATA;
                       // end else begin
                        //    sample_counter_next <= sample_counter + 1;
                        //end
                    //end
                end
                
                DATA: begin
                    //if (baud_tick) begin
                        //if (sample_counter == 15) begin  // Sample at middle of start bit
                            //sample_counter_next <= 0;
                            if (bit_index == 7) begin
                                next_state = PARITY;
                            end else begin
                                next_state = DATA;
                            end
                        //end else begin
                            //sample_counter_next <= sample_counter + 1;
                        //end
                    //end
                end
                
                PARITY: begin
                   // if (baud_tick) begin
                        //if (sample_counter == 15) begin  // Sample at middle of start bit
                        //    sample_counter_next <= 0;
                            next_state = STOP;
                        //end else begin
                         //   sample_counter_next <= sample_counter + 1;
                        //end
                    //end
                end
                
                STOP: begin
                    //if (baud_tick) begin
                    //    if (sample_counter == 15) begin  // Sample at middle of start bit
                    //        sample_counter_next <= 0;
                            next_state = IDLE; // Go back to idle state
                    //    end else begin
                    //       sample_counter_next <= sample_counter + 1;
                     //   end
                    //end
                end
                default: next_state = IDLE;
            endcase
    end
    assign TXD = (state == IDLE )? 1: (state == START)? 0: (state == DATA)? data_reg[bit_index] : (state == PARITY) ? parity_bit : 1;
    assign busy = (state != IDLE);

endmodule


    