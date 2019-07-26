----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.07.2019 12:48:44
-- Design Name: 
-- Module Name: uart_tranceiver_v1_00 - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

library work;
use work.fifo_in8_out32;
use work.data32_transmitter;
use work.UART_RX;
use work.UART_TX;



entity uart_tranceiver_v1_00 is
    Generic (
      c_freq_hz     : integer := 125000000;
      c_boad_rate   : integer := 9600
    );
    Port (
      tx            : out std_logic;
      rx            : in std_logic;

      m_fcb_clk     : in std_logic;
      m_fcb_resetn  : in std_logic;
      m_fcb_addr    : out std_logic_vector(31 downto 0);
      m_fcb_wrdata  : out std_logic_vector(31 downto 0);
      m_fcb_wrreq   : out std_logic;
      m_fcb_wrack   : in std_logic;
      m_fcb_rddata  : in std_logic_vector(31 downto 0);
      m_fcb_rdreq   : out std_logic;
      m_fcb_rdack   : in std_logic
      );
end uart_tranceiver_v1_00;

architecture Behavioral of uart_tranceiver_v1_00 is

  type state_machine    is (idle, comm_byte_wait, wait_addr, addr, wait_len, len, wait_wr_data, wr_data, rd_data, sts_rd_cntr, response);
  signal state, next_state      : state_machine;
  
--  type tx_state_machine is (idle, start_tx, tx_ready)
--  signal tx_state, tx_next_state    : tx_state_machine;
  constant g_CLKS_PER_BIT       : integer := c_freq_hz/c_boad_rate;
  signal rx_byte_valid          : std_logic;
  signal rx_byte                : std_logic_vector(7 downto 0);
  signal push_response          : std_logic;
  signal tx_byte                : std_logic_vector(7 downto 0);
  signal tx_byte_busy           : std_logic;
  signal tx_byte_done           : std_logic;
  signal tx_byte_done_d         : std_logic;
  signal comm_byte              : std_logic_vector(7 downto 0);
  signal fifo_in8_out32_valid   : std_logic;
  signal fifo_rst     : std_logic;
  signal fifo_rst_vec : std_logic_vector(3 downto 0);
  signal fifo_in8_out32_dout    : std_logic_vector(31 downto 0);
  signal fifo_in8_out32_rd_en   : std_logic;
  signal fifo_in8_out32_wr_en   : std_logic;
  signal address                : std_logic_vector(31 downto 0);
  signal buf_length             : std_logic_vector(31 downto 0);
  signal data_counter           : std_logic_vector(31 downto 0);
  signal fcb_write              : std_logic;
  signal fcb_read               : std_logic;
  signal start_tx               : std_logic;
  signal start_tx_d             : std_logic;
  signal fcb_wrreq              : std_logic;
  signal fcb_rdreq              : std_logic;
  signal t_done                 : std_logic;
  signal d8tv                   : std_logic;
  signal d32ready               : std_logic;
  signal d8                     : std_logic_vector(7 downto 0);


begin
m_fcb_wrreq <= fcb_wrreq;
m_fcb_rdreq <= fcb_rdreq;

fcb_write <= fcb_wrreq and m_fcb_wrack;
fcb_read <= fcb_rdreq and m_fcb_rdack;
m_fcb_addr <= address;
m_fcb_wrdata <= fifo_in8_out32_dout(7 downto 0) & fifo_in8_out32_dout(15 downto 8) & fifo_in8_out32_dout(23 downto 16) & fifo_in8_out32_dout(31 downto 24);

delay_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      tx_byte_done_d <= tx_byte_done;
    end if;
  end process;

uart_rx_inst : entity UART_RX 
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
      )
    port map(
      i_Clk         => m_fcb_clk,
      i_RX_Serial   => rx,
      o_RX_DV       => rx_byte_valid,
      o_RX_Byte     => rx_byte
      );

uart_tx_inst : entity UART_TX
    generic map(
      g_CLKS_PER_BIT => g_CLKS_PER_BIT
      )
    port map(
      i_Clk        => m_fcb_clk,
      i_TX_DV      => start_tx,
      i_TX_Byte    => tx_byte,
      o_TX_Active  => open,
      o_TX_Serial  => tx,
      o_TX_Done    => tx_byte_done
      );

fifo_in8_out32_inst :   ENTITY fifo_in8_out32 
  PORT MAP(
    rst     => fifo_rst,
    wr_clk  => m_fcb_clk,
    rd_clk  => m_fcb_clk,
    din     => rx_byte,
    wr_en   => fifo_in8_out32_wr_en,
    rd_en   => fifo_in8_out32_rd_en,
    dout    => fifo_in8_out32_dout,
    full    => open,
    empty   => open,
    valid   => fifo_in8_out32_valid
  );

data32_transmitter_inst : entity data32_transmitter
    Port map(
      clk       => m_fcb_clk,
      rst       => fifo_rst,
      d32       => m_fcb_rddata,
      d32valid  => fcb_read,
      d32ready  => d32ready,
      d8        => d8,
      d8tv      => d8tv,
      d8done    => t_done
    );

t_done <= (tx_byte_done_d and (not tx_byte_done));

fifo_in8_out32_wr_en <= rx_byte_valid when (state = wait_addr) or (state = wait_len) or (state = wait_wr_data) else '0';

start_tx <= push_response or d8tv;

fifo_in8_out32_rst_proc : 
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (state = idle) then
        fifo_rst_vec <= (others => '1');
      else
        fifo_rst_vec(3 downto 1) <= fifo_rst_vec(2 downto 0);
        fifo_rst_vec(0) <= '0';
      end if;
    end if;
  end process;

fifo_rst <= fifo_rst_vec(3);

tx_byte <= x"aa" when (state = response) else d8;

comm_byte_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (state = comm_byte_wait) then
        if (rx_byte_valid = '1') then
          comm_byte <= rx_byte;
        end if;
      end if;
    end if;
  end process;

addr_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (state = addr) then
          address <= fifo_in8_out32_dout(7 downto 0) & fifo_in8_out32_dout(15 downto 8) & fifo_in8_out32_dout(23 downto 16) & fifo_in8_out32_dout(31 downto 24);
      else
        if (comm_byte(0) = '1') then
          if ((fcb_write = '1') or (fcb_read = '1')) then
            address <= address + 4;
          end if;
        end if;
      end if;
    end if;
  end process;

buf_length_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (state = len) then
          buf_length <= fifo_in8_out32_dout(7 downto 0) & fifo_in8_out32_dout(15 downto 8) & fifo_in8_out32_dout(23 downto 16) & fifo_in8_out32_dout(31 downto 24);
      end if;
    end if;
  end process;

data_counter_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (state = idle) then
        data_counter <= (others => '0');
      else
        if ((fcb_write = '1') or (fcb_read = '1')) then
          data_counter <= data_counter + 1;
        end if;
      end if;
    end if;
  end process;

sync_proc :
  process(m_fcb_clk) 
  begin
    if rising_edge(m_fcb_clk) then
      if (m_fcb_resetn = '0') then
        state <= idle;
      else
        state <= next_state;
      end if;
    end if;
  end process;

out_proc :
  process(state, rx_byte_valid, fifo_in8_out32_valid)
  begin
    fifo_in8_out32_rd_en <= '0';
    fcb_wrreq <= '0';
    push_response <= '0';
    fcb_rdreq <= '0';
    fcb_rdreq <= '0';
      case state is 
        when idle =>
        when comm_byte_wait =>
        when addr => 
          fifo_in8_out32_rd_en <= '1';
        when len =>
          fifo_in8_out32_rd_en <= '1';
        when wr_data =>
          fifo_in8_out32_rd_en <= '1';
          fcb_wrreq <= '1';
        when rd_data =>
          fcb_rdreq <= '1';
        when response =>
          push_response <= '1';
        when others =>
      end case;
  end process;

next_state_proc:
  process(state, rx_byte_valid, fifo_in8_out32_valid, comm_byte(1), data_counter, d32ready, fcb_write, buf_length, fcb_read)
  begin
    next_state <= state;
      case state is 
        when idle =>
          next_state <= comm_byte_wait;
        when comm_byte_wait =>
          if (rx_byte_valid = '1') then
            next_state <= wait_addr;
          end if;
        when wait_addr => 
          if (fifo_in8_out32_valid = '1') then
            next_state <= addr;
          end if;
        when addr =>
            next_state <= wait_len;
        when wait_len =>
          if (fifo_in8_out32_valid = '1') then
            next_state <= len;
          end if;
        when len =>
          if (comm_byte(1) = '1') then 
            next_state <= wait_wr_data;
          else 
            next_state <= rd_data;
          end if;
        when wait_wr_data =>
          if (data_counter >= buf_length) then
            next_state <= response;
          else
            if (fifo_in8_out32_valid = '1') then
              next_state <= wr_data;
            end if;
          end if;
        when wr_data =>
          if fcb_write = '1' then
            next_state <= wait_wr_data;
          end if;
        when rd_data =>
          if (fcb_read = '1') then
            next_state <= sts_rd_cntr;
          end if;
        when sts_rd_cntr =>
          if (d32ready = '1') then
            if (data_counter = buf_length) then
                next_state <= idle;
            else
                next_state <= rd_data;
            end if;
          end if;
        when response =>
          next_state <= idle;
        when others =>
      end case;
  end process;


end Behavioral;
