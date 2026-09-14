module order_book (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_write_en,
    input  logic [31:0] i_stock_id,
    input  logic [31:0] i_price,
    input  logic [31:0] i_share,
    output logic [31:0] o_read_price,
    output logic [31:0] o_read_share,
    output logic [31:0] o_read_stock_id
);


logic [31:0] price_mem [255:0];
logic [31:0] share_mem [255:0];
logic [31:0] id_mem    [255:0];


integer i;
initial begin
    for (i = 0; i < 256; i = i + 1) begin
        price_mem[i] = '0;
        share_mem[i] = '0;
        id_mem[i]    = '0;
    end
end


always_ff @(posedge i_clk) begin
    if (i_write_en == 1) begin
        price_mem[i_stock_id[7:0]] <= i_price;
        share_mem[i_stock_id[7:0]] <= i_share;
        id_mem[i_stock_id[7:0]]    <= i_stock_id;
    end
    
end


always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_read_price    <= '0;
        o_read_share    <= '0;
        o_read_stock_id <= '0;
    end
    else begin
        o_read_price    <= price_mem[i_stock_id[7:0]];
        o_read_share    <= share_mem[i_stock_id[7:0]];
        o_read_stock_id <= id_mem[i_stock_id[7:0]];
    end
end

endmodule