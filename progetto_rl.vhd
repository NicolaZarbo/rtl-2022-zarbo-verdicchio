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


architecture arch_stati of project_reti_logiche is  --
type stati is (sReStart, sCuscino, sRead, sCod1 ,sCod2,sCod3,sCod4,sWrite1 ,sCod5 , sCod6, sCod7, sCod8 , sWrite2, sTerm );
signal st_att, st_prox : stati := sRestart;
signal fU, stop_cod : std_logic:= '0';
signal fY: std_logic_vector(1 downto 0) := (others => '0');
signal in_addr, out_addr, in_a_prox, out_a_prox, nTerminazione : std_logic_vector(15 downto 0) := (others => '0');
signal in_value, out_value_buffer: std_logic_vector(7 downto 0);

component codificatore_convoluzionale is
    Port ( i_U : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           i_rst :in std_logic;
           stop_en : in std_logic;
           o_Y : out STD_LOGIC_vector);
 end component;


begin 
 cod : codificatore_convoluzionale
port map (i_start => i_start, i_U => fU, i_clk => i_clk, o_Y => fY, stop_en =>stop_cod, i_rst => i_rst);

 --processo per sincronizzare, reset asincrono
clockSinc : process(i_clk, i_start, i_rst, st_prox, in_a_prox, out_a_prox) is
    begin   
if (i_rst ='1') then
          st_att <= sRestart;
elsif ( rising_edge(i_clk) ) then
       in_addr <= in_a_prox;       
       out_addr <= out_a_prox;
       if (i_start='1') then
         st_att <= st_prox;
       else
         st_att <= sRestart;
       end if;
     
end if;
    
end process;


--------- output, tenuti fuori da fsm per pulizia e per evitare latch----------
o_en <= '1' when (st_att = sRestart or st_att = sRead or st_att = sWrite1 or st_att = sWrite2) else '0';
o_we <= '1' when (st_att = sWrite1 or st_att = sWrite2 ) else '0';
o_done <= '1' when ((st_att = sTerm  and i_start = '1' and in_addr = nTerminazione) ) else '0';
o_address<= in_addr when( st_att = sRead ) else
            out_addr when (st_att = sWrite1 or st_att = sWrite2 or st_prox = sWrite1 or st_prox = sWrite2) else (others => '0');
o_data <= out_value_buffer;
-----------------------------------------------------------------



--gestione stati e terminazione
fsm : process(st_att, in_addr, i_start ,nTerminazione) is
begin 
    case(st_att) is
        
        when sReStart => --stato di partenza e reset
            st_prox <= sCuscino;
            
       when sCuscino => --serve unicamente per gestire il caso di sequenza minima = |0|
            st_prox <= sTerm;
            
        when sRead =>
            st_prox <= sCod1;
            
        when sCod1 =>
            st_prox <= sCod2;
            
        when sCod2 =>
            st_prox <= sCod3; 
                 
        when sCod3 =>
            st_prox <= sCod4;
            
        when sCod4 =>
            st_prox <= sWrite1;
            
        when sWrite1 =>   --scrittura prima parola generata da una parola in ingresso
            st_prox <= sCod5;
            
        when sCod5 => 
            st_prox <= sCod6;  
            
        when sCod6 =>
            st_prox <= sCod7; 
                             
        when sCod7 =>
            st_prox <= sCod8;
                        
        when sCod8 => 
            st_prox <= sWrite2;   
  
            
        when sWrite2 =>   --scrittura seconda parola
            st_prox <= sTerm;    
            
        when sTerm=>   -- se finisce parole da leggere (nTerm = inAddr) e start ='1' -> done =1
            if (in_addr /= nTerminazione) then
              st_prox <= sRead;
            elsif(i_start='0') then  --se viene inserito un nuovo start per iniziare una codifica, resetta fsm
                st_prox <= sRestart;
            else 
                st_prox <= sTerm; 
            end if;
     end case;   
end process;


--registri aggiornati su clock in discesa
process_registri : process(i_clk, st_att, i_data, out_addr, fY, in_addr) is
begin
if(i_clk'event and i_clk ='0')then
    --registro prossimo address per write
    if(st_att = sWrite1 or st_att = sWrite2) then
        out_a_prox<= std_logic_vector(to_unsigned(((to_integer(unsigned(out_addr))) + 1),16));
    elsif (st_att = sRestart) then
        out_a_prox<= std_logic_vector(to_unsigned(1000, 16)) ;
    end if;
    --registro per prossimo address per read
    if (st_att = sRead ) then
        in_a_prox <= std_logic_vector(to_unsigned(((to_integer(unsigned(in_addr))) + 1),16));
    elsif (st_att = sRestart) then
        in_a_prox <=(0 => '1', others => '0');
    end if;
    
    --registro per valore da scrivere in write
    if (st_att = sCod2 or st_att = sCod6) then
       out_value_buffer(7 downto 6) <= fY ;
    elsif (st_att = sCod3 or st_att = sCod7) then
       out_value_buffer (5 downto 4) <= fY ;
    elsif(st_att = sCod4 or st_att = sCod8)then
        out_value_buffer (3 downto 2) <= fY  ;
    elsif (st_att = sWrite1 or st_att = sWrite2 )then
         out_value_buffer (1 downto 0) <= fY  ;
    end if;
    
    --registro per controllo terminazione flusso in entrata
    if (st_att = sRestart) then
        nTerminazione(15 downto 0) <= std_logic_vector(to_unsigned(((to_integer(unsigned(i_data))) + 1),16)) ;
    end if;
    
    --registro per salvare valore letto in memoria
    if (st_att = sCod1) then
        in_value <= i_data;
    end if;
end if;
end process;

-------------segnali per fsm codificatore convoluzionale------------
-- segnale per fermare fsm codificatore
stop_cod <= '1' when (st_att = sRestart or st_att = sCuscino or st_att = sRead or st_att = sWrite1 or st_att = sWrite2 or st_att = sTerm or st_att = sCuscino) else '0';

--entrata componente codificatore convoluzionale 
fU <= in_value(7) when (st_att = sCod1) else
      in_value(6) when (st_att = sCod2) else
      in_value(5) when (st_att = sCod3) else
      in_value(4) when (st_att = sCod4) else
      in_value(3) when (st_att = sCod5) else
      in_value(2) when (st_att = sCod6) else
      in_value(1) when (st_att = sCod7) else
      in_value(0) when (st_att = sCod8) else '-';
--------------------------------------------------------------------
end arch_stati;


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