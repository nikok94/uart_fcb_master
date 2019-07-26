----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.07.2019 13:04:32
-- Design Name: 
-- Module Name: data32_receiver - Behavioral
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
use IEEE.STD_LOGIC_unsigned.ALL;
use IEEE.Numeric_Std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity data32_receiver is
    Port ( 
      clk       : in std_logic;
      rst       : in std_logic;
      d8        : in std_logic_vector(7 downto 0);
      d8_valid  : in std_logic;
      d32       : out std_logic_vector(31 downto 0);
      d32_valid : out std_logic
    );
end data32_receiver;

architecture Behavioral of data32_receiver is
    signal d8_counter       : std_logic_vector(2 downto 0):=(others => '0');
    signal d32_buff         : std_logic_vector(31 downto 0):=(others => '0');
    signal d32_buff_valid   : std_logic;
    signal d8_valid_d       : std_logic;

begin

d8_counter_proc :
    process(clk, rst)
    begin
      if (rst = '1') then
        d8_counter <= (others => '0');
      elsif rising_edge(clk) then
        if (d32_buff_valid = '1') then
          d8_counter <= (others => '0');
        elsif (d8_valid = '1') then
          d8_counter <= d8_counter + 1;
        end if;
      end if;
    end process;

d32_buff_proc :
    process(clk, rst)
    begin
      if (rst = '1') then
        d32_buff <= (others => '0');
        d8_valid_d <= '0';
      elsif rising_edge(clk) then
        if (d8_valid = '1') then
          d32_buff((8*(to_integer(unsigned(d8_counter))) + 7) downto (8*(to_integer(unsigned(d8_counter))))) <= d8;
        end if;
        d8_valid_d <= d8_valid;
      end if;
    end process;

d32_buff_valid <= d8_counter(2);
d32_valid <= d32_buff_valid;
d32 <= d32_buff;

end Behavioral;
