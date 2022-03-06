

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity codificatore_convoluzionale is
    Port ( i_U : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           i_rst :in STD_LOGIC; --rst potrebbe essere superfluo, basta il rising edge di start per resettare
       --    o_done : out STD_LOGIC;
           o_Y : out STD_LOGIC_vector;
           o_en : in std_logic);  --eneable usato per fermaremacchina stati

end codificatore_convoluzionale;



architecture Behavioral of codificatore_convoluzionale is

type stati is (s00,s01,s10,s11);
--signals stati
signal st_att,st_prox : stati:= s00;
--signals uscita
signal p1,p2, done: std_logic ;

begin 

processo_syn_clk : process (i_clk,i_start, i_rst)
begin
    if(rising_edge(i_start)or i_rst='1')then
      st_att <= s00;
      st_prox <= s00;
     end if; 
      if (rising_edge(i_clk) and i_start ='1' ) then
        st_att <= st_prox; 
        o_y(1) <= p1;--togliere per desincronizzare output testare temporizzazione output, ogni quanti clock a partire dal set di u l'uscita è corretta
        o_y(0) <= p2;
        end if;
end process;

processo_out: process(i_U, st_att, o_en )
begin 
-- decode output attuale
    case(st_att) is
--stato 00
        when s00 =>
          if (i_U = '0') then
            p1 <= '0';
            p2 <= '0';
          else  
            p1 <= '1';
            p2 <= '1';
           end if;
--stato 01

        when s01 =>
            if (i_U = '0') then
                p1 <= '1';
                p2 <= '1';
            else 
                p1 <= '0';
                p2 <= '0';
            end if;


 -- stato 10
       when s10 =>
            if (i_U = '0') then
                p1 <= '0';
                p2 <= '1';
            else 
                p1 <= '1';
                p2 <= '0';
            end if;


   -- stato 11 
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

processo_stati: process(i_U, st_att )
begin 
    st_prox <= st_att;
if (o_en ='0') then
-- se enable = 1 allora non cambio stato, mantengo output invariato, latch volontario per stprox
-- decode prossimo stato 
    case(st_att) is
--stato 00
        when s00 =>
          if (i_U = '0') then
            st_prox <= s00;
            
          else  
            st_prox <= s10;
          
           end if;
          --sistemare formattazione + aggiungere process output separato da prox stato????
--stato 01
        when s01 =>
            if (i_U = '0') then
                st_prox <= s00;
            else 
                st_prox <= s10;
            end if;


 -- stato 10
        when s10 =>
            if (i_U = '0') then
                st_prox <= s01;
            else 
                st_prox <= s11;
            end if;


   -- stato 11 
        when s11 =>
            if (i_U = '0') then
                st_prox <= s01;
            else 
                st_prox <= s11;
            end if;

end case;
end if;
end process;

end Behavioral;
