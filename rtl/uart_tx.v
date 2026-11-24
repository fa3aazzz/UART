module uart_tx (
    input clk, rst,
    input tx_enb,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    
    always @(posedge clk)
        begin
            if (rst)
                begin
                    state <= IDLE;
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    shift_reg <= 8'd0;
                    bit_cnt <= 3'd0;
                end
            else
                begin
                    case (state)
                    
                        IDLE: begin
                            if(tx_start)
                                begin
                                    shift_reg <= tx_data;
                                    tx_busy <= 1'b1;
                                    state <= START;
                                end
                            else
                                state <= IDLE;
                            end
                            
                        START: begin
                            if (tx_enb)
                                begin
                                    tx <= 1'b0;
                                    bit_cnt <= 3'd0;
                                    state <= DATA;
                                end
                            else
                                state <= START;
                            end
                        
                        DATA: begin
                            if (tx_enb)
                                begin
                                    tx <= shift_reg[0];
                                    shift_reg <= {1'b0, shift_reg[7:1]};
                                    bit_cnt <= bit_cnt + 1;
                                    if (bit_cnt == 3'd7)
                                        state <= STOP;
                                end
                            end
                            
                        STOP: begin
                            if (tx_enb)
                                begin
                                    tx <= 1'b1;
                                    tx_busy <= 1'b0;
                                    state <= IDLE;
                                end
                            end
                        
                        default: state <= IDLE;
                    
                    endcase
                end
        end

endmodule