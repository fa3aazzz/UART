module baud_generator #(
    parameter CLK_FREQ = 125_000_000,
    parameter BAUD = 115_200,
    parameter OVERSAMPLE = 16
    )(
    input clk, rst,
    output reg tx_enb, rx_enb
    );
    
    localparam TX_DIV = (CLK_FREQ + (BAUD/2))/BAUD; // 1085 clock cycles
    localparam RX_DIV = (CLK_FREQ + ((BAUD*OVERSAMPLE)/2))/(BAUD*OVERSAMPLE); // 68 clock cycles for rx to sample allat more than tx
    
    reg [$clog2(TX_DIV)-1:0] tx_counter;
    reg [$clog2(RX_DIV)-1:0] rx_counter;
    
    always @(posedge clk)
        if (rst)
            begin
                tx_counter <= 0;
                tx_enb <= 0;
            end
        else if (tx_counter == TX_DIV-1)
            begin
                tx_counter <= 0;
                tx_enb <= 1;
            end
        else
            begin
                tx_counter <= tx_counter + 1;
                tx_enb <= 0;
            end
            
    always @(posedge clk)
        if (rst)
            begin
                rx_counter <= 0;
                rx_enb <= 0;
            end
        else if (rx_counter == RX_DIV-1)
            begin
                rx_counter <= 0;
                rx_enb <= 1;
            end
        else
            begin
                rx_counter <= rx_counter + 1;
                rx_enb <= 0;
            end
    
endmodule
