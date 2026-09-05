module top_hw (
    input  logic       i_clk,     
    input  logic       i_rst_n,   
    input  logic [1:0] i_sel,      //2 slide switches
    output logic [7:0] o_led
);

logic        rst;
logic        w_valid;
logic [7:0]  w_byte;
logic [31:0] w_price, w_share, w_id;

assign rst = ~i_rst_n; 

packet_feeder feeder (
        .i_clk(i_clk), .i_rst(rst),
        .o_valid(w_valid), .o_data_byte(w_byte)
    );

top_level dut (
        .i_clk(i_clk), .i_rst(rst), .i_valid(w_valid), .i_data_byte(w_byte),
        .o_TL_price(w_price), .o_TL_share(w_share), .o_TL_id(w_id)
    );

always_comb case (i_sel)
        2'd0: o_led = w_id[7:0];        
        2'd1: o_led = w_price[7:0];     
        2'd2: o_led = w_share[7:0];     
        default: o_led = w_price[15:8]; 
    endcase

endmodule