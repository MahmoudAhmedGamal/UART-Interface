module Receiver_ASH(
    input clk,
    input reset,
    input RXD,
    output wire [7:0]RX_Data,
    output wire Valid_rx,
    output wire Parity_error,
    output wire Stop_error
);
    reg [3:0] sample_counter ,sample_counter_next;  // For oversampling (16x)
    reg [2:0] bit_index      ,bit_index_next; // To track which bit is being received
    reg [1:0] state          ,state_next;
    reg [7:0] data_reg       ,data_reg_next; // To store received data
    reg [7:0] data_shifted   ,data_shifted_next; // Shifted data for processing
    reg       Stop_bit      ,Stop_bit_next; // Received stop bit
    reg       parity_bit     ,parity_bit_next; // Received and calculated parity bits
    reg       Valid_rx_reg  ,Valid_rx_reg_next; // To indicate valid data reception
    reg       Parity_error_reg,Parity_error_reg_next; // To indicate parity error
    reg       Stop_error_reg ,Stop_error_reg_next; // To indicate stop bit error

    localparam IDLE   = 2'b00,
               DATA   = 2'b01,
               PARITY = 2'b10,
               STOP   = 2'b11;

    function automatic [3:0] sample_counter_calc;
        input [3:0] current_value;
        if (current_value == 15)
            sample_counter_calc = 0;
        else
            sample_counter_calc = current_value + 1;
    endfunction

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_index <= 0;
            data_reg <= 0;
            data_shifted <= 0;
            sample_counter <= 0;
            parity_bit <= 0;
            Stop_bit <= 0;
            Valid_rx_reg <= 0;
            Parity_error_reg <= 0;
            Stop_error_reg <= 0;
        end
        else begin
            state <= state_next;
            bit_index <= bit_index_next;
            data_reg <= data_reg_next;
            data_shifted <= data_shifted_next;
            sample_counter <= sample_counter_next;
            parity_bit <= parity_bit_next;
            Stop_bit <= Stop_bit_next;
            Valid_rx_reg <= Valid_rx_reg_next;
            Parity_error_reg <= Parity_error_reg_next;
            Stop_error_reg <= Stop_error_reg_next;
        end
    end

    always @(*)begin
        state_next = state;
        bit_index_next = bit_index;
        data_reg_next = data_reg;
        data_shifted_next = data_shifted;
        sample_counter_next = sample_counter;
        parity_bit_next = parity_bit;
        Stop_bit_next = Stop_bit;
        Valid_rx_reg_next = Valid_rx_reg;
        Parity_error_reg_next = Parity_error_reg;
        Stop_error_reg_next = Stop_error_reg;
        case (state)
            IDLE: begin 

                    if (RXD == 0)begin  // Sample at middle of IDLE bit
                        sample_counter_next = sample_counter_calc(sample_counter);
                        if (sample_counter == 15)begin
                            state_next = DATA;  
                            Valid_rx_reg_next = 0;
                            Parity_error_reg_next = 0;
                            Stop_error_reg_next = 0;                        
                        end    
                    end   
                    else begin
                        sample_counter_next = 0;
                    end             
            end            
            DATA: begin
                    sample_counter_next = sample_counter_calc(sample_counter);
                    if(sample_counter == 7) begin
                        data_shifted_next = {RXD, data_shifted[7:1]}; // Shift in new bit
                    end

                    if (sample_counter == 15) begin  // Sample at middle of data bit
                        if(bit_index == 7)begin
                            data_reg_next = data_shifted; // Final bit received
                            data_shifted_next = 0; // Clear shifted data
                            bit_index_next = 0;
                            state_next = PARITY; // Move to parity bit after data bits
                        end
                        else begin
                            bit_index_next = bit_index + 1; // Move to next bit
                        end
                    end
            end
            PARITY: begin
                    sample_counter_next = sample_counter_calc(sample_counter);

                    if(sample_counter == 7)begin
                        parity_bit_next = RXD; // Read parity bit
                    end

                    if (sample_counter == 15)begin  // Sample at middle of data bit
                        if(parity_bit == (^data_reg))begin
                            state_next = STOP; // Move to stop bit if parity matches
                        end
                        else begin
                            state_next = IDLE; // Go back to IDLE on parity error
                            Parity_error_reg_next = 1; // Indicate parity error
                        end
                    end
            end
            STOP: begin
                    sample_counter_next = sample_counter_calc(sample_counter);

                    if(sample_counter == 7)begin
                        Stop_bit_next = RXD; // Read stop bit
                    end

                    if (sample_counter == 15)begin  // Sample stop bit
                        state_next = IDLE; // Go back to IDLE state
                        Valid_rx_reg_next = (Stop_bit) ? 1 : 0; // Indicate valid reception if stop bit is correct
                        Stop_error_reg_next = (Stop_bit) ? 0 : 1 ; // Indicate stop bit error if incorrect
                    end
            end
        endcase
    end
    assign Parity_error = Parity_error_reg;
    assign RX_Data = data_reg;
    assign Stop_error = Stop_error_reg;
    assign Valid_rx = Valid_rx_reg;
endmodule

