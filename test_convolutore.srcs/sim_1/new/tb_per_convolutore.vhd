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
    Port ( i_U : in STD_LOGIC;
       i_start : in STD_LOGIC;
       i_clk : in STD_LOGIC;
       --i_rst :in STD_LOGIC; --rst potrebbe essere superfluo, basta il rising edge di start per resettare
   --    o_done : out STD_LOGIC;
       o_Y : out STD_LOGIC_vector (1 downto 0);
       o_en : in std_logic
          );
end component;

signal tb_start : std_logic := '0';
signal tb_en : std_logic := '0';
signal tb_U : std_logic := '0';
signal tb_clk : std_logic := '0';
signal tb_Y : std_logic_vector(1 downto 0) ;

begin
UUT : codificatore_convoluzionale
Port map (
    i_start => tb_start,
    i_clk => tb_clk,
    i_U => tb_U,
    o_Y => tb_Y,
    o_en => tb_en
    );
    
  clock : process  is
  begin
   tb_clk <= not tb_clk ;
   wait for 50ns;
   end process;
   
   
   test : process is
   begin
      wait for 100ns;
         tb_start <= '1' ;
         wait for 100ns;--read
         tb_en <= '1';
       --  wait for 20ns;-- arrivo valore i data
        wait for 100 ns;  --cv1
        tb_en<='0';
                 tb_U <= '1';

          wait for 100 ns;
          tb_U <= '0';

    end process;


end testb;