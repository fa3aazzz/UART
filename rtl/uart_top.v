module uart_top #(
    parameter CLK_FREQ = 125_000_000,
    parameter BAUD = 115_200,
    parameter OVERSAMPLE = 16
    )(
    input clk, rst,
    input tx_start,
    input [7:0] tx_data,
    output tx_busy,
    output tx,
    input rx,
    output [7:0] rx_data,
    output rx_valid, rx_frame_error
    );
    
    wire tx_enb, rx_enb;
    
    baud_generator #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OVERSAMPLE(OVERSAMPLE))
        baud_gen (.clk(clk), .rst(rst), .tx_enb(tx_enb), .rx_enb(rx_enb));
        
    uart_tx u_tx (.clk(clk), .rst(rst), .tx_enb(tx_enb), .tx_start(tx_start), .tx_data(tx_data),
                  .tx(tx), .tx_busy(tx_busy));
                  
    uart_rx u_rx (.clk(clk), .rst(rst), .rx_enb(rx_enb), .rx(rx),
                  .rx_data(rx_data), .rx_valid(rx_valid), .rx_frame_error(rx_frame_error));
    
endmodule
