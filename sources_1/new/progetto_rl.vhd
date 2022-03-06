library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;



entity project_reti_logiche is
port (
i_clk : in std_logic;
i_rst : in std_logic;
i_start : in std_logic;
i_data : in std_logic_vector(7 downto 0);
o_address : out std_logic_vector(15 downto 0);
o_done : out std_logic;
o_en : out std_logic;
o_we : out std_logic;
o_data : out std_logic_vector (7 downto 0)
);

end project_reti_logiche;

--aggiungere stati per macchina
architecture arch_stati of project_reti_logiche is
type stati is (sReStart, sRead, sConv1 ,sConv2 , sWrite, sTerm );
signal st_att, st_prox : stati;
signal fU : std_logic;
signal fY: std_logic_vector(1 downto 0);
signal in_addr, out_addr, in_a_prox, out_a_prox : std_logic_vector(15 downto 0);
signal in_value: std_logic_vector(7 downto 0);-- il msb in realtà viene letto dal segnale i_data dal convolutore
component codificatore_convoluzionale is
    Port ( i_U : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           o_en : out std_logic;
           o_Y : out STD_LOGIC_vector);
 end component;


begin 
 cod : codificatore_convoluzionale
port map (i_start => i_start, i_U => fU, i_clk => i_clk, o_Y => fY, o_en =>o_en, i_rst=>i_rst);

clockSinc : process(i_rst,i_clk) is
    begin
    if i_rst='1' or rising_edge(i_start) then
        st_att <= sReStart;
    end if;
    if ( rising_edge(i_clk)) then
        st_att<=st_prox;
        in_addr <= in_a_prox;
    end if;

end process;
fsm: process(i_data, i_start) is
begin 

    case(st_att) is
        
        when sReStart =>
            in_addr <= x"0000";
            in_a_prox <=x"0000";
            st_prox <= sRead;
            
        when sRead =>
            o_en <= '1';
            o_we <= '0';
            o_address <= in_addr;
            in_a_prox <= in_addr+1;  --tramite std_logic_unsigned.all;
            
        when sConv1 =>
            o_en <= '0';
            fU <= i_data(0);
            in_value <= i_data;
            st_prox <= sConv2;
        
        when sConv2 =>
            fU<= in_value(1);
            o_data (7 downto 6) <= fY;--fy ha gia l'uscita pronta?
            
            
     end case;   
end process;
--begin

--if (rising_edge(i_start)) then
--in_addr <= x"0000";
--in_a_prox <= x"0000";

--end if;

--if (start ='1' and rising_edge(i_clk)) then
--    in_addr <= in_a_prox;  
--    o_address <= in_addr;
--    o_en <= '1';
--    o_we <= '0';
--    in_a_prox <= std_logic_vector(to_unsigned(to_integer(unsigned(in_addr)) + 1, 16));
    
    


end arch_stati;