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
type stati is (sReStart, sCuscino, sRead, sConv1 ,sConv2,sConv3,sConv4,sWrite1 ,sConv5 , sConv6, sConv7, sConv8 , sWrite2, sTerm );
signal st_att, st_prox : stati := sRestart;
signal fU, b_en : std_logic:= '0';
signal fY: std_logic_vector(1 downto 0);
signal in_addr, out_addr, in_a_prox, out_a_prox, nTerminazione : std_logic_vector(15 downto 0) := (others => '0');
signal in_value, out_value_buffer: std_logic_vector(7 downto 0);-- il msb in realtà viene letto dal segnale i_data dal convolutore

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
port map (i_start => i_start, i_U => fU, i_clk => i_clk, o_Y => fY, stop_en =>b_en, i_rst => i_rst);

 --processo per sincronizzare
clockSinc : process(i_clk,i_start,i_rst, st_prox, in_a_prox, out_a_prox) is
    begin   
if ( rising_edge(i_clk) ) then
     if (i_rst ='1') then
      st_att <= sRestart;
     else
       in_addr <= in_a_prox;       
       out_addr <= out_a_prox;
       if (i_start='1') then
         st_att <= st_prox;
       else
         st_att <= sRestart;
       end if;
     end if;
end if;
    
end process;


--------- output, tenuti fuori da fsm per pulizia e per evitare latch----------
o_en <= '1' when (st_att = sRestart or st_att = sRead or st_att = sWrite1 or st_att = sWrite2) else '0';
o_we <= '1' when (st_att = sWrite1 or st_att = sWrite2 ) else '0';
b_en <= '1' when (st_att = sRestart or st_att = sCuscino or st_att = sRead or st_att = sWrite1 or st_att = sWrite2 or st_att = sTerm or st_att = sCuscino) else '0';
o_done <= '1' when ((st_att = sTerm  and i_start = '1' and in_addr = nTerminazione) ) else '0';
o_address<= in_addr when( st_att = sRead ) else--or st_prox = sRead
            out_addr when (st_att = sWrite1 or st_att = sWrite2 or st_prox = sWrite1 or st_prox = sWrite2) else (others => '0');
o_data <= out_value_buffer;
-----------------------------------------------------------------



--gestione stati e terminazione
fsm : process(i_clk,i_data, i_start, st_att, in_addr, in_value,fY,out_addr,nTerminazione) is
begin 
    case(st_att) is
        
        when sReStart => --stato di partenza e reset
            st_prox <= sCuscino;
            
       when sCuscino => --serve unicamente per il caso in cui in mem 0000 leggo il valore '00000000';
            st_prox <= sTerm;
            
        when sRead =>
            st_prox <= sConv1;
            
        when sConv1 =>
            st_prox <= sConv2;
            
        when sConv2 =>
            st_prox <= sConv3; 
                 
        when sConv3 =>
            st_prox <= sConv4;
            
        when sConv4 =>
            st_prox <= sWrite1;
            
        when sWrite1 =>   --scrittura prima parola generata da una parola in ingresso
            st_prox <= sConv5;
            
        when sConv5 => 
            st_prox <= sConv6;  
            
        when sConv6 =>
            st_prox <= sConv7; 
                             
        when sConv7 =>
            st_prox <= sConv8;
                        
        when sConv8 => 
            st_prox <= sWrite2;   
  
            
        when sWrite2 =>   --scrittura seconda parola
            st_prox <= sTerm;    
            
        when sTerm=>   -- se finisce parole da leggere (nTerm = inAddr) e start ='1' -> done =1
            if (in_addr /= nTerminazione) then
              st_prox <= sRead;
            else
            
              if(rising_edge(i_start)) then  --se viene inserito un nuovo start per iniziare una codifica, resetta fsm
                st_prox <= sRestart;
              end if;
            end if;
     end case;   
end process;


--registri aggiornati su clock in discesa
process_registri : process(i_clk) is
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
    if (st_att = sConv2 or st_att = sConv6) then
      out_value_buffer(7 downto 6) <= fY ;
    elsif (st_att = sConv3 or st_att = sConv7) then
      out_value_buffer (5 downto 4) <= fY ;
    elsif(st_att = sConv4 or st_att = sConv8)then
        out_value_buffer (3 downto 2) <= fY  ;
    elsif (st_att = sWrite1 or st_att = sWrite2 )then
         out_value_buffer (1 downto 0) <= fY  ;
    end if;
    
    --registro per controllo terminazione flusso in entrata
    if (st_att = sRestart) then
        nTerminazione(15 downto 8) <= (others =>'0') ;
        nTerminazione(7 downto 0) <= i_data+1  ;
    end if;
    
    --registro per salvare valore letto in memoria
    if (st_att = sConv1) then
        in_value <= i_data;
    end if;
end if;
end process;


--entrata componente codificatore convoluzionale 
fU <= in_value(7) when (st_att = sConv1) else
      in_value(6) when (st_att = sConv2) else
      in_value(5) when (st_att = sConv3) else
      in_value(4) when (st_att = sConv4) else
      in_value(3) when (st_att = sConv5) else
      in_value(2) when (st_att = sConv6) else
      in_value(1) when (st_att = sConv7) else
      in_value(0) when (st_att = sConv8) else '-';

end arch_stati;