module packet_feeder (
    input  logic       i_clk,
    input  logic       i_rst,
    output logic       o_valid,
    output logic [7:0] o_data_byte
);

localparam int N = 13;
logic [7:0] rom [0:N-1];
logic [3:0] idx;

initial begin
        rom[0]  = 8'hAA; //start marker
        rom[1]  = 8'h00; rom[2]  = 8'h00; rom[3]  = 8'h00; rom[4]  = 8'h42; // id
        rom[5]  = 8'h00; rom[6]  = 8'h00; rom[7]  = 8'h03; rom[8]  = 8'hE8; // price
        rom[9]  = 8'h00; rom[10] = 8'h00; rom[11] = 8'h00; rom[12] = 8'h64; // shares
end

always_ff @(posedge i_clk)
    if (i_rst)        idx <= '0;
    else if (idx < N) idx <= idx + 1'b1;

assign o_valid     = (idx < N);
assign o_data_byte = (idx < N) ? rom[idx] : 8'h00;

endmodule   