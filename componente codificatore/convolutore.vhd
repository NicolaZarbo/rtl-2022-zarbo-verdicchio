
                                                     ----------------------------
-----------------------------------------------------CODIFICATORE CONVOLUZIOINALE----------------------------------------------------------------
                                                     -----------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity codificatore_convoluzionale is
    Port ( i_U : in STD_LOGIC:='0';
           i_start : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           i_rst : in std_logic;
           o_Y : out STD_LOGIC_vector (1 downto 0);
           stop_en : in std_logic);  --eneable usato per fermare macchina stati

end codificatore_convoluzionale;



architecture Behavioral of codificatore_convoluzionale is

type stati is (s00,s01,s10,s11);
signal st_att,s_prox : stati := s00;
--signals uscita
signal p1,p2: std_logic:='0' ;

begin 
---CLOCK CON GESTIONE PROCESSI
processo_syn_clk : process (i_clk,i_start, i_rst, s_prox, st_att, p1,p2, stop_en) is
begin

if(i_start='0' )then
       st_att <= s00; 
       o_y(1) <= '0';
       o_y(0) <= '0'; 
elsif((i_rst ='1') )then
       st_att <= s00;
       o_y(1) <= '0';
       o_y(0) <= '0';
       
elsif (rising_edge(i_clk)  ) then
       if (stop_en='1') then
          st_att <= st_att;
       else 
          st_att <= s_prox;
       end if; 
          o_y(1) <= p1;
          o_y(0) <= p2;
end if;
end process;


processo_out : process(i_U, st_att) is
begin 
    case(st_att) is

        when s00 =>
          if (i_U = '0') then
            p1 <= '0';
            p2 <= '0';
          else  
            p1 <= '1';
            p2 <= '1';
           end if;

        when s01 =>
            if (i_U = '0') then
                p1 <= '1';
                p2 <= '1';
            else 
                p1 <= '0';
                p2 <= '0';
            end if;

       when s10 =>
            if (i_U = '0') then
                p1 <= '0';
                p2 <= '1';
            else 
                p1 <= '1';
                p2 <= '0';
            end if;

      when s11 =>
            if (i_U = '0') then
                p1 <= '1';
                p2 <= '0';
            else 
                p1 <= '0';
                p2 <= '1';
            end if;

end case;
end process;

processo_stati : process(i_U, st_att ) is
begin 
    s_prox <= st_att;
    case(st_att) is

        when s00 =>
          if (i_U = '0') then
            s_prox <= s00;
            
          else  
            s_prox <= s10;
          
           end if;
           
        when s01 =>
            if (i_U = '0') then
                s_prox <= s00;
            else 
                s_prox <= s10;
            end if;

        when s10 =>
            if (i_U = '0') then
                s_prox <= s01;
            else 
                s_prox <= s11;
            end if;

        when s11 =>
            if (i_U = '0') then
                s_prox <= s01;
            else 
                s_prox <= s11;
            end if;

end case;
end process;

end Behavioral;