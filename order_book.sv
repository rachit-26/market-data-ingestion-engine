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

// Storage: three 256-deep memories so each maps cleanly to one M9K block RAM.
// Block RAM has NO reset port, so there is deliberately no if(i_rst) clear here
// — that single loop is what forced the whole array into flip-flops before.
logic [31:0] price_mem [255:0];
logic [31:0] share_mem [255:0];
logic [31:0] id_mem    [255:0];

// Power-up contents, baked into the bitstream. This replaces the reset-clear
// and keeps the same "reads 0 until written" behaviour.
integer i;
initial begin
    for (i = 0; i < 256; i = i + 1) begin
        price_mem[i] = '0;
        share_mem[i] = '0;
        id_mem[i]    = '0;
    end
end

// WRITE PORT — synchronous, your original style
always_ff @(posedge i_clk) begin
    if (i_write_en == 1) begin
        price_mem[i_stock_id[7:0]] <= i_price;
        share_mem[i_stock_id[7:0]] <= i_share;
        id_mem[i_stock_id[7:0]]    <= i_stock_id;
    end
    // no else-hold branch: a RAM already holds its value on its own
end

// READ PORT — this is where your if(i_rst) lives now. These are ordinary
// output registers (not RAM), so they CAN legally be reset.
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