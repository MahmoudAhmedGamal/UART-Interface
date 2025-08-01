module Receiver_ASH(
    input clk,
    input reset,
    input RXD,
    output wire [7:0]RX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);

    wire parity_check; // For parity error checking
    reg parity_bit,parity,Stop_bit;
    reg [3:0] sample_counter;  // For oversampling (16x)
    reg [2:0] bit_index;
    reg [2:0] state, state_next;
    reg [7:0] data_reg; 
    localparam START = 3'b000,
               DATA = 3'b001,
               PARITY = 3'b010,
               STOP = 3'b011;
               //STOP = 3'b100;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= START;
            bit_index <= 0;
            data_reg <= 0;
            sample_counter <= 0;
            parity <= 0;
            parity_bit <= 0; // Clear parity_bit on reset
            Stop_bit <= 0; // Clear Stop_bit on reset
        end
    else begin
        state <= state_next;
        
        case (state)
            /*START: begin

            end*/
            START: begin 
                        if (!RXD)begin
                            sample_counter <= 0;
                            bit_index <= 0;
                            if (sample_counter == 15)begin  // Sample at middle of start bit
                                sample_counter <= 0;
                                //parity <= 0; // Reset parity for new frame
                                //parity_bit <= 0; // Clear parity_bit
                            end                  
                            else begin 
                                sample_counter <= sample_counter + 1;
                            end   
                        end 
                        else begin
                            sample_counter <= 0;
                        end
            end            
            DATA: begin
                if (sample_counter == 15) begin
                    data_reg[bit_index] <= RXD;
                    if (bit_index == 7) begin
                        bit_index <= 0;
                    end else begin
                        bit_index <= bit_index + 1;
                    end
                    sample_counter <= 0;
                end else begin
                    sample_counter <= sample_counter + 1;
                end
            end
            PARITY: begin
                    if (sample_counter == 7)
                        parity_bit <= RXD; // Read parity bit
                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        parity <= ^data_reg; // Calculate parity after all bits are received
                        sample_counter <= 0;
                    end
                    else begin
                        sample_counter <= sample_counter + 1;
                    end
            end
            STOP: begin
                    if (sample_counter == 7)
                        Stop_bit <= RXD; // Read parity bit
                    if (sample_counter == 15)begin  // Sample stop bit
                        sample_counter <= 0;
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
            /*START: begin
                    if (!RXD)begin
                        state_next = START;
                    end
            end*/
            START: begin 
            
                    if ((!RXD) && sample_counter == 15)begin  // Sample at middle of start bit
                        state_next = DATA;  
                    end                    
            end            
            DATA: begin
                    if (sample_counter == 15) begin  // Sample at middle of data bit
                        if(bit_index == 7)begin
                            state_next = PARITY; // Move to parity bit after data bits
                        end
                    end
            end
            PARITY: begin
                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        if(parity_bit == parity)begin
                            state_next = STOP; // Move to stop bit if parity matches
                        end
                        else begin
                            state_next = START; // Go back to START on parity error
                        end
                    end
            end
            STOP: begin
                    if (sample_counter == 15)begin  // Sample stop bit
                        state_next = START; // Go back to START state
                    end
            end
            default: state_next = START; // Fallback to START on unknown state
        endcase
    end
    assign parity_check = (state == STOP) ? (parity == parity_bit) : 1'b0;
    assign Parity_error = (state == STOP) ? ~parity_check : 0;
    assign RX_Data = data_reg;
    assign Stop_error = (state == STOP && sample_counter == 15) ? ~Stop_bit : 0;
    assign Valid_rx = (state == STOP && sample_counter == 15) ? Stop_bit : 0 ;

endmodule
