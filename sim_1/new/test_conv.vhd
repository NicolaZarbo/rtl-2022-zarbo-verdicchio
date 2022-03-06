----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.03.2022 16:24:39
-- Design Name: 
-- Module Name: test_conv - Behavioral
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_conv is
end test_conv;

architecture testb of test_conv is
component  codificatore_convoluzionale is
Port (
     i_U : in STD_LOGIC;
          i_start : in STD_LOGIC;
          i_clk : in STD_LOGIC;
        --  o_done : out STD_LOGIC;
          o_Y : out STD_LOGIC_vector(1 downto 0)
          );
end component;

signal i_start : std_logic := '0';
signal i_U : std_logic := '0';
signal i_clk : std_logic := '0';
--signal o_done : std_logic;
signal o_Y : std_logic ;

begin
UUT : codificatore_convoluzionale
Port map (
    i_start => i_start,
    i_clk => i_clk,
    i_U => i_U,
 --   o_done => o_done,
    o_Y => o_Y
    );
   
   i_clk <= not i_clk after 100 ns;
   i_U <= not i_clk;
   i_start <= '1' after 101ns;

end testb;
