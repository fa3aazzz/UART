module uart_rx(
    input clk, rst,
    input rx_enb,
    input rx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_frame_error
    );
    
    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg rx_meta, rx_sync;
    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    
    always @(posedge clk)
        begin
            if (rst)
                begin
                    rx_data <= 0;
                    rx_valid <= 0;
                    rx_frame_error <= 0;
                    rx_meta <= 1;
                    rx_sync <= 1;
                    state <= IDLE;
                    tick_cnt <= 0;
                    bit_cnt <= 0;
                    shift_reg <= 0;
                end
            else
                begin
                    rx_meta <= rx;
                    rx_sync <= rx_meta;
                    rx_valid <= 0;
                    rx_frame_error <= 0;
                    
                    if (rx_enb)
                        begin
                            case (state)
                                
                                IDLE: begin
                                    if (rx_sync == 1'b0)
                                        begin
                                            tick_cnt <= 4'd0;
                                            state <= START;
                                        end
                                      end
                                
                                START: begin
                                    if (tick_cnt == 4'd7)
                                        begin
                                            if (rx_sync == 1'b0)
                                                begin
                                                    tick_cnt <= 4'd0;
                                                    bit_cnt <= 3'd0;
                                                    state <= DATA;
                                                end
                                            else
                                                state <= IDLE;
                                        end
                                    else
                                        tick_cnt <= tick_cnt + 1;
                                       end
                                
                                DATA: begin
                                    if (tick_cnt == 4'd15)
                                        begin
                                            shift_reg <= {rx_sync, shift_reg[7:1]};
                                            tick_cnt <= 4'd0;
                                            bit_cnt <= bit_cnt + 1;
                                            if (bit_cnt == 3'd7)
                                                state <= STOP;
                                        end
                                    else
                                        tick_cnt <= tick_cnt + 1;
                                      end
                                      
                                STOP: begin
                                    if (tick_cnt == 4'd15)
                                        begin
                                            if (rx_sync == 1'b1)
                                                begin
                                                    rx_data <= shift_reg;
                                                    rx_valid <= 1'b1;
                                                end
                                            else
                                                rx_frame_error <= 1'b1;
                                            state <= IDLE;
                                        end
                                    else
                                        tick_cnt <= tick_cnt + 1;
                                      end
                                  
                                default: state <= IDLE;
                                
                            endcase
                        end
                end
        end
endmodule
