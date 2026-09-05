module parser (
    input  logic        i_clk,
    input  logic        i_rst,
    input  logic        i_valid,
    input  logic [7:0]  i_data_byte,
    output logic [31:0] o_stock_id,
    output logic [31:0] o_price,
    output logic [31:0] o_share,
    output logic        o_write_en

);

parameter IDLE = 0, READ_ID = 1, READ_PRICE = 2, READ_SHARES = 3, PUSH2MEM = 4;
logic [2:0] state, next_state;
logic [2:0] byte_counter;
logic [31:0] temp_stock_id, temp_price, temp_share;

always @(*) begin
    case (state) 

        IDLE: begin
            if((i_valid == 1) && (i_data_byte == 8'hAA)) begin
                next_state = READ_ID;
            end

            else begin
                next_state = state;
            end
        end

        READ_ID: begin
            if(byte_counter == 3) begin
                next_state = READ_PRICE;
            end

            else begin
                next_state = state;
            end
        end

        READ_PRICE: begin 
            if(byte_counter == 3) begin
                next_state = READ_SHARES;
            end

            else begin
                next_state = state;
            end
        end

        READ_SHARES: begin
            if(byte_counter == 3) begin
                next_state = PUSH2MEM;
            end

            else begin
                next_state = state;
            end
        end

        PUSH2MEM: begin
            next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end

    endcase
end

always @(posedge i_clk) begin
    if (i_rst) begin
            state <= IDLE;
            {byte_counter, o_stock_id, o_price, o_share, o_write_en, temp_stock_id, temp_price, temp_share} <= '0;
    end

    else begin
    state <= next_state;
    
    case(state)

        IDLE: begin
            o_write_en <= 0;
        end
            
        READ_ID: begin
            if (i_valid == 1) begin
                temp_stock_id <= {temp_stock_id[23:0],i_data_byte};
                if(byte_counter == 3) begin
                    byte_counter <= 0;
                end
                else 
                    byte_counter <= byte_counter + 1;
                end
        end
            

        READ_PRICE: begin
            if (i_valid == 1) begin
                temp_price <= {temp_price[23:0],i_data_byte};
                if(byte_counter == 3) begin
                    byte_counter <= 0;
                end
                else 
                    byte_counter <= byte_counter + 1;
                end
        end

        READ_SHARES: begin 
            if (i_valid == 1) begin
                temp_share <= {temp_share[23:0],i_data_byte};
                if(byte_counter == 3) begin
                    byte_counter <= 0;
                end
                else 
                    byte_counter <= byte_counter + 1;
                end
        end

        PUSH2MEM: begin
            o_stock_id <= temp_stock_id;
            o_price <= temp_price;
            o_share <= temp_share;
            o_write_en <= 1;
        end 

    endcase
    end
            
end

// synthesis translate_off
property p_reset_goes_idle;
    @(posedge i_clk) i_rst |=> (state == IDLE);
endproperty
A_RESET_IDLE: assert property (p_reset_goes_idle);

A_COUNTER_RANGE: assert property (@(posedge i_clk) byte_counter <= 3);

A_WRITE_EN_SRC: assert property (@(posedge i_clk) disable iff (i_rst)
    o_write_en |-> $past(state == PUSH2MEM));

A_WRITE_PULSE:  assert property (@(posedge i_clk) disable iff (i_rst)
    o_write_en |=> !o_write_en);
// synthesis translate_on

endmodule
        







            
            
        