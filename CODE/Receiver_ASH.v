module Receiver_ASH(
    input clk,
    input reset,
    input RXD,
    output wire [7:0]RX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);
    reg parity_bit,parity;
    reg [3:0] sample_counter,sample_counter_next;  // For oversampling (16x)

    reg [2:0] bit_index;
    reg [3:0] state, state_next;
    reg [7:0] data_reg; 
    reg P_REG, S_REG ,Valid_rx_reg; // Add registers
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
            P_REG <= 0; // Clear on reset
            S_REG <= 0;   // Clear on reset
            Valid_rx_reg <= 0;
            parity <= 0;
        end
    else begin
        state <= state_next;
        case (state)
            IDLE: begin
                Valid_rx_reg <= 0;
                P_REG <= 0;
                S_REG <= 0;
                if (!RXD)begin
                    sample_counter <= 0;
                    bit_index <= 0;

                end
                
            end
            START: begin 
                        if (sample_counter == 7)begin  // Sample at middle of start bit
                            sample_counter <= 0;
                            parity <= 0; // Reset parity for new frame
                        end                  
                        else begin 
                            sample_counter <= sample_counter + 1;
                        end                   
            end            
            DATA: begin
                    if (sample_counter == 15) begin  // Sample at middle of data bit
                            data_reg[bit_index] <= RXD;
                            parity <= parity ^ RXD;
                            sample_counter <= 0;
                            if(bit_index == 7)begin
                                bit_index <= bit_index;
                            end
                            else begin
                                bit_index <= bit_index + 1;
                            end
                    end else begin
                        sample_counter <= sample_counter + 1;
                    end
            end
            PARITY: begin
                    if (sample_counter == 7)
                        parity_bit <= 0;
                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        sample_counter <= 0;
                        P_REG <= (parity == parity_bit)? 0 : 1;
                        /*if(parity_bit == RXD)begin
                        P_REG <=0 ;
                        end
                        else begin
                        P_REG <=1 ;
                        end*/
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
                            S_REG <= 0;
                        end
                        else begin
                            S_REG <= 1;
                        end
                    end
                    else begin
                        sample_counter <= sample_counter + 1;
                    end

            end
        endcase
    end
    end

    always @(*)begin
        state_next = state;
        case (state)
            IDLE: begin
                if (!RXD)begin
                    state_next = START;
                end
                else begin
                    state_next = IDLE;
                end
                
            end
            START: begin 
                        if (sample_counter == 7)begin  // Sample at middle of start bit
                            state_next = DATA;  
                        end   
                        else begin 
                            state_next = START; 
                        end                   
            end            
            DATA: begin
                    if (sample_counter == 15) begin  // Sample at middle of data bit
                            if(bit_index == 7)begin
                                state_next = PARITY; // Move to parity bit after data bits
                            end
                            else begin
                            state_next = DATA;  
                            end
                    end else begin
                        state_next = DATA;  
                    end
            end
            PARITY: begin
                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        state_next = STOP;
                    end
                    else begin
                        state_next = PARITY;                   
                    end
            end
            STOP: begin
                    if (sample_counter == 15)begin  // Sample stop bit
                        state_next = IDLE; // Go back to idle state
                    end
                    else begin
                        state_next = STOP;
                    end

            end
            default: state_next = IDLE; // Fallback to idle on unknown state
        endcase
    end
    
    assign RX_Data = (state == STOP)? data_reg : RX_Data;
    assign Parity_error = (state == STOP)? P_REG : 0;
    assign Stop_error = S_REG;
    assign Valid_rx = Valid_rx_reg;

endmodule
