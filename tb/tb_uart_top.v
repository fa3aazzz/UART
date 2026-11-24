`timescale 1ns/1ps

module tb_uart_top;
    parameter CLK_FREQ = 125000000;
    parameter BAUD = 115200;
    parameter OVERSAMPLE = 16;
    real BIT_NS;
    reg clk = 0;
    reg rst = 1;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tx;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_frame_error;

    reg use_force = 0;
    reg rx_force = 1;
    wire rx_line;

    assign rx_line = use_force ? rx_force : tx;

    uart_top #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD), .OVERSAMPLE(OVERSAMPLE)) dut (
        .clk(clk), .rst(rst),
        .tx_start(tx_start), .tx_data(tx_data), .tx_busy(tx_busy), .tx(tx),
        .rx(rx_line), .rx_data(rx_data), .rx_valid(rx_valid), .rx_frame_error(rx_frame_error)
    );

    always #4 clk = ~clk;

    integer errors = 0;
    integer frame_errors = 0;
    integer seed = 1;

    reg got_byte = 0;
    reg [7:0] got_data = 0;

    always @(posedge clk) begin
        if (rx_valid) begin
            got_byte <= 1;
            got_data <= rx_data;
        end
        if (rx_frame_error)
            frame_errors <= frame_errors + 1;
    end

    initial begin
        #100000000;
        $display("FAILED: timeout");
        $finish;
    end

    task check_byte(input [7:0] expected);
        begin
            if (got_byte == 0) begin
                errors = errors + 1;
                $display("FAIL: no byte received, expected %h", expected);
            end
            else if (got_data !== expected) begin
                errors = errors + 1;
                $display("FAIL: expected %h, received %h", expected, got_data);
            end
        end
    endtask

    task send_byte(input [7:0] d);
        begin
            got_byte = 0;
            @(negedge clk);
            tx_data = d;
            tx_start = 1;
            @(negedge clk);
            tx_start = 0;
            while (got_byte == 0)
                @(posedge clk);
            @(posedge clk);
            check_byte(d);
            while (tx_busy)
                @(posedge clk);
        end
    endtask

    task force_frame(input [7:0] d, input real bit_time, input stop);
        integer i;
        begin
            rx_force = 0;
            #(bit_time);
            for (i = 0; i < 8; i = i + 1) begin
                rx_force = d[i];
                #(bit_time);
            end
            rx_force = stop;
            #(bit_time);
            rx_force = 1;
            #(bit_time);
        end
    endtask

    integer k;
    integer gap;
    integer old_ferr;
    reg [7:0] d;

    initial begin
        BIT_NS = 1.0e9 / BAUD;

        repeat (4) @(posedge clk);
        @(negedge clk) rst = 0;
        repeat (10) @(posedge clk);

        for (k = 0; k < 256; k = k + 1)
            send_byte(k);
        $display("test 1 done, errors so far = %0d", errors);

        for (k = 0; k < 24; k = k + 1) begin
            d = $random(seed);
            gap = {$random(seed)} % 3000;
            repeat (gap) @(posedge clk);
            send_byte(d);
        end
        $display("test 2 done, errors so far = %0d", errors);

        @(negedge clk);
        use_force = 1;
        rx_force = 1;
        #(2*BIT_NS);

        got_byte = 0;
        force_frame(8'hA6, BIT_NS*1.03, 1'b1);
        check_byte(8'hA6);

        got_byte = 0;
        force_frame(8'hA6, BIT_NS*1.00, 1'b1);
        check_byte(8'hA6);

        got_byte = 0;
        force_frame(8'hA6, BIT_NS*0.97, 1'b1);
        check_byte(8'hA6);

        got_byte = 0;
        old_ferr = frame_errors;
        rx_force = 0;
        #1632;
        rx_force = 1;
        #(3*BIT_NS);
        if (frame_errors != old_ferr) begin
            errors = errors + 1;
            $display("FAIL: glitch caused a frame error");
        end
        if (got_byte == 1) begin
            errors = errors + 1;
            $display("FAIL: glitch produced a byte");
        end

        got_byte = 0;
        old_ferr = frame_errors;
        force_frame(8'h5A, BIT_NS, 1'b0);
        #(2*BIT_NS);
        if (frame_errors != old_ferr + 1) begin
            errors = errors + 1;
            $display("FAIL: bad stop bit gave %0d frame errors, expected 1", frame_errors - old_ferr);
        end
        if (got_byte == 1) begin
            errors = errors + 1;
            $display("FAIL: bad stop bit still produced a byte");
        end

        got_byte = 0;
        force_frame(8'h3C, BIT_NS, 1'b1);
        check_byte(8'h3C);

        @(negedge clk);
        use_force = 0;
        send_byte(8'hC3);
        $display("test 3 done, errors so far = %0d", errors);

        if (errors == 0)
            $display("PASS: all tests passed");
        else
            $display("FAILED: %0d error(s)", errors);
        $finish;
    end

endmodule