----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2019 11:46:32
-- Design Name: 
-- Module Name: data32_transmitter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data32_transmitter is
    Port (
      clk       : in std_logic;
      rst       : in std_logic;
      d32       : in std_logic_vector(31 downto 0);
      d32valid  : in std_logic;
      d32ready  : out std_logic;
      d8        : out std_logic_vector(7 downto 0);
      d8tv      : out std_logic;
      d8done    : in std_logic
    );
end data32_transmitter;

architecture Behavioral of data32_transmitter is
  type st_mac   is (idle, wait_d32, push_d8_0, wait_d8_0_done, push_d8_1, wait_d8_1_done, push_d8_2, wait_d8_2_done, push_d8_3, wait_d8_3_done);
  signal state          : st_mac:= idle;
  signal next_state     : st_mac;

begin
sync_proc   :
    process(clk, rst)
    begin
      if rst = '1' then
        state <= idle;
      elsif rising_edge(clk) then
        state <= next_state;
      end if;
    end process;

data_out_proc :
  process(state)
  begin
   d32ready <= '0';
   d8tv <= '0';
   d8 <= (others => '0');
    case state is
      when idle =>
      when wait_d32 =>
        d32ready <= '1';
      when push_d8_0 =>
        d8tv <= '1';
        d8 <= d32(7 downto 0);
      when push_d8_1 =>
        d8tv <= '1';
        d8 <= d32(15 downto 8);
      when push_d8_2 =>
        d8tv <= '1';
        d8 <= d32(23 downto 16);
      when push_d8_3 =>
        d8tv <= '1';
        d8 <= d32(31 downto 24);
     when others =>
    end case;
  end process;

next_state_proc :
    process(state, d32valid, d8done)
    begin
      next_state <= state;
        case state is
          when idle =>
            next_state <= wait_d32;
          when wait_d32 => 
            if (d32valid = '1') then
              next_state <= push_d8_0;
            end if;
          when push_d8_0 =>
            next_state <= wait_d8_0_done;
          when wait_d8_0_done => 
            if d8done = '1' then
              next_state <= push_d8_1;
            end if;
          when push_d8_1 =>
            next_state <= wait_d8_1_done;
          when wait_d8_1_done => 
            if d8done = '1' then
              next_state <= push_d8_2;
            end if;
          when push_d8_2 =>
            next_state <= wait_d8_2_done;
          when wait_d8_2_done => 
            if d8done = '1' then
              next_state <= push_d8_3;
            end if;
          when push_d8_3 =>
            next_state <= wait_d8_3_done;
          when wait_d8_3_done => 
            if d8done = '1' then
              next_state <= wait_d32;
            end if;
        end case;
    end process;



end Behavioral;
