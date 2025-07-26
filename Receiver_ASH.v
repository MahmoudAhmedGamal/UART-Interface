module Receiver_ASH(
    input clk,
    input reset,
    input RXD,
    output wire [7:0]RX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);
    reg parity_bit;
    reg [3:0] sample_counter,sample_counter_next;  // For oversampling (16x)

    reg stop;
    reg [2:0] bit_index;
    reg [3:0] state;//, state <
    reg [7:0] data_reg; 
    reg parity_error_reg, stop_error_reg; // Add registers
    localparam IDLE = 3'b000,
               START = 3'b001,
               DATA = 3'b010,
               PARITY = 3'b011,
               STOP = 3'b100;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_index <= 0;
            data_reg <= 0;
            sample_counter <= 0;
            parity_error_reg <= 0; // Clear on reset
            stop_error_reg <= 0;   // Clear on reset
            Valid_rx_reg <= 0;
        end
    else begin
        //state <= state;
        case (state)
            IDLE: begin
                Valid_rx_reg <= 0;
                if (!RXD)begin
                    state <= START;
                    sample_counter <= 0;
                    bit_index <= 0;

                end
                
            end
            START: begin 
                        if (sample_counter == 7)begin  // Sample at middle of start bit
                            sample_counter <= 0;
                            state <= DATA;  
                        end                  
                        else begin 
                            sample_counter <= sample_counter + 1;
                        end                   
            end            
            DATA: begin
                    if (sample_counter == 15) begin  // Sample at middle of data bit
                            data_reg[bit_index] <= RXD;
                            sample_counter <= 0;
                            if(bit_index == 7)begin
                                state <= PARITY; // Move to parity bit after data bits
                                parity_bit <= ^data_reg;
                            end
                            else begin
                                bit_index <= bit_index + 1;
                            end
                    end else begin
                        sample_counter <= sample_counter + 1;
                    end
            end
            PARITY: begin
                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        sample_counter <= 0;
                        state <= STOP;
                        if(parity_bit = RXD)begin
                        parity_error_reg <=0 ;
                        end
                        else begin
                        parity_error_reg <=1 ;
                        end
                    end
                    else begin
                        sample_counter <= sample_counter + 1;
                    end
            end
            STOP: begin
                    if (sample_counter == 15)begin  // Sample stop bit
                        if(RXD)begin
                            //RX_Data <= data_reg;
                            Valid_rx_reg <= 1;
                            stop_error_reg <= 0;
                        end
                        else begin
                            stop_error_reg <= 1;
                        end
                        state <= IDLE; // Go back to idle state
                    end
                    else begin
                        sample_counter <= sample_counter + 1;
                    end

            end
            default: state <= IDLE; // Fallback to idle on unknown state
        endcase
    end
    end
    
    assign RX_Data = (state == STOP)? data_reg : 0;
    assign Parity_error = parity_error_reg;
    assign Stop_error = stop_error_reg;
    assign Valid_rx = Valid_rx_reg;

endmodule
