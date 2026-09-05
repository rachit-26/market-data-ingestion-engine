module top_level (
    input logic         i_clk,
    input logic         i_rst,
    input logic         i_valid,
    input logic  [7:0]  i_data_byte,
    output logic [31:0] o_TL_price,
    output logic [31:0] o_TL_share,
    output logic [31:0] o_TL_id  
);

wire [31:0] w_share;
wire [31:0] w_id;
wire [31:0] w_price;
wire        w_en;
wire [31:0] w_read_price;
wire [31:0] w_read_id;
wire [31:0] w_read_share;
 

parser ronit (      .o_stock_id(w_id),
                    .o_share(w_share),
                    .o_price(w_price),
                    .o_write_en(w_en),
                    .i_clk(i_clk),
                    .i_rst(i_rst),
                    .i_valid(i_valid),
                    .i_data_byte(i_data_byte)
                  );

order_book shush (      .i_clk(i_clk),
                        .i_rst(i_rst),
                        .i_price(w_price),
                        .i_share(w_share),
                        .i_stock_id(w_id),
                        .i_write_en(w_en),
                        .o_read_price(w_read_price),
                        .o_read_share(w_read_share),
                        .o_read_stock_id(w_read_id)

                      );

assign o_TL_price = w_read_price;
assign o_TL_share = w_read_share;
assign o_TL_id = w_read_id;




initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0); 
end

endmodule