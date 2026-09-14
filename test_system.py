import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import random


class OrderBookGoldenModel:
    def __init__(self):
        self.software_memory = {}

    def process_network_packet(self, byte_array):
        """Pure Python software logic that mimics what the hardware should do"""
        if byte_array[0] != 0xAA:
            return 
            
        
        stock_id = int.from_bytes(byte_array[1:5], byteorder='big')
        price = int.from_bytes(byte_array[5:9], byteorder='big')
        shares = int.from_bytes(byte_array[9:13], byteorder='big')
        
        
        self.software_memory[stock_id] = {'price': price, 'shares': shares}
        
        return stock_id, price, shares


async def reset_hardware(dut):
    """Resets the hardware to a clean state."""
    dut.i_valid.value = 0
    dut.i_data_byte.value = 0x00
    dut.i_rst.value = 1
    for _ in range(2):
        await RisingEdge(dut.i_clk)
    dut.i_rst.value = 0
    await RisingEdge(dut.i_clk)

async def send_byte(dut, val):
    """Pushes exactly one byte into the hardware."""
    dut.i_valid.value = 1
    dut.i_data_byte.value = val
    await RisingEdge(dut.i_clk)




@cocotb.test()
async def test_1_happy_path(dut):
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    golden_model = OrderBookGoldenModel()
    await reset_hardware(dut)

    
    test_packet = [0xAA] + [random.randint(0, 255) for _ in range(12)]
    expected_id, expected_price, expected_shares = golden_model.process_network_packet(test_packet)

    
    for byte in test_packet:
        await send_byte(dut, byte)

    
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)

    
    assert dut.w_id.value == expected_id, f"ID Mismatch! HW: {dut.w_id.value}, SW: {expected_id}"
    assert dut.w_price.value == expected_price, f"Price Mismatch! HW: {dut.w_price.value}, SW: {expected_price}"
    assert dut.w_share.value == expected_shares, f"Shares Mismatch! HW: {dut.w_share.value}, SW: {expected_shares}"
    
    
@cocotb.test()
async def test_2_change2_0xFF(dut):
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    await reset_hardware(dut)
    
    test_packet = [0xFF] + [random.randint(0, 255) for _ in range(12)]

    for byte in test_packet:
        await send_byte(dut, byte)
        
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)
        
    assert dut.w_id.value == 0, f"Hardware leaked ID! HW output: {dut.w_id.value}"
    assert dut.w_price.value == 0, f"Hardware leaked Price! HW output: {dut.w_price.value}"
    assert dut.w_share.value == 0, f"Hardware leaked Shares! HW output: {dut.w_share.value}"
    
    
@cocotb.test()
async def test_3_reset_midway(dut):
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    await reset_hardware(dut)
    
    test_packet = [0xAA] + [random.randint(0, 255) for _ in range(12)]
    

    for i in range(6):
        await send_byte(dut, test_packet[i])
        
    await reset_hardware(dut)
        
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)
        
    assert dut.w_id.value == 0, f"Hardware leaked ID! HW output: {dut.w_id.value}"
    assert dut.w_price.value == 0, f"Hardware leaked Price! HW output: {dut.w_price.value}"
    assert dut.w_share.value == 0, f"Hardware leaked Shares! HW output: {dut.w_share.value}"
    
    
@cocotb.test()
async def test_4_network_pause(dut):
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    golden_model = OrderBookGoldenModel()
    await reset_hardware(dut)

    test_packet = [0xAA] + [random.randint(0, 255) for _ in range(12)]
    expected_id, expected_price, expected_shares = golden_model.process_network_packet(test_packet)

    for i in range(6):
        await send_byte(dut, test_packet[i])
        
    
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)
        
    dut.i_valid.value = 1
    for i in range (6,13):
        await send_byte(dut, test_packet[i])


    
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)
        


    assert dut.w_id.value == expected_id, f"ID Mismatch! HW: {dut.w_id.value}, SW: {expected_id}"
    assert dut.w_price.value == expected_price, f"Price Mismatch! HW: {dut.w_price.value}, SW: {expected_price}"
    assert dut.w_share.value == expected_shares, f"Shares Mismatch! HW: {dut.w_share.value}, SW: {expected_shares}"
    

@cocotb.test()
async def test_5_shimmy_test(dut):
    
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    golden_model = OrderBookGoldenModel()
    await reset_hardware(dut)

    
    test_packet = [0xFF] + [random.randint(0, 255) for _ in range(12)]
    

    
    for i in range(1):
        await send_byte(dut, test_packet[i])
     
    dut.i_valid.value = 0    
    for _ in range(3):
        await RisingEdge(dut.i_clk)
        
    test_packet = [0xAA] + [random.randint(0, 255) for _ in range(12)]
    expected_id, expected_price, expected_shares = golden_model.process_network_packet(test_packet)
        
    for byte in test_packet:
        await send_byte(dut, byte)

    
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)


    assert dut.w_id.value == expected_id, f"ID Mismatch! HW: {dut.w_id.value}, SW: {expected_id}"
    assert dut.w_price.value == expected_price, f"Price Mismatch! HW: {dut.w_price.value}, SW: {expected_price}"
    assert dut.w_share.value == expected_shares, f"Shares Mismatch! HW: {dut.w_share.value}, SW: {expected_shares}"
    

@cocotb.test()
async def test_6_trojan_horse(dut):
    
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    golden_model = OrderBookGoldenModel()
    await reset_hardware(dut)

    
    test_packet = [0xAA] + [random.randint(0, 255) for _ in range(12)]
    
    
    test_packet[3] = 0xAA  
    test_packet[7] = 0xAA  
    

    expected_id, expected_price, expected_shares = golden_model.process_network_packet(test_packet)

    
    for byte in test_packet:
        await send_byte(dut, byte)

    
    dut.i_valid.value = 0
    for _ in range(3):
        await RisingEdge(dut.i_clk)

    
    assert dut.w_id.value == expected_id, "Hardware got tricked by a fake 0xAA in the ID!"
    assert dut.w_price.value == expected_price, "Hardware got tricked by a fake 0xAA in the Price!"
    assert dut.w_share.value == expected_shares, "Hardware got tricked by a fake 0xAA in the Shares!"
    
    