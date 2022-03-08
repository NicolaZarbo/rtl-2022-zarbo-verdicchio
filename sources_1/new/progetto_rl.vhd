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


architecture arch_stati of project_reti_logiche is
type stati is (sReStart,sCuscino, sRead, sConv1 ,sConv2,sConv3,sConv4,sWrite1 ,sConv5 , sConv6, sConv7, sConv8 , sWrite2, sTerm );
signal st_att, st_prox : stati := sRestart;
signal fU, b_en : std_logic:= '0';
signal fY: std_logic_vector(1 downto 0);
signal in_addr, out_addr, in_a_prox, out_a_prox, nTerminazione : std_logic_vector(15 downto 0) := (others => '0');
signal in_value, out_value_buffer: std_logic_vector(7 downto 0);-- il msb in realtà viene letto dal segnale i_data dal convolutore

component codificatore_convoluzionale is
    Port ( i_U : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           o_en : in std_logic;
           o_Y : out STD_LOGIC_vector);
 end component;


begin 
 cod : codificatore_convoluzionale
port map (i_start => i_start, i_U => fU, i_clk => i_clk, o_Y => fY, o_en =>b_en);

clockSinc : process(i_clk,i_start,i_rst, st_prox, in_a_prox, out_a_prox) is
    begin
    
   -- elsif rising_edge(i_start) then
     --   st_att <= sReStart;
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


--------- output fuori da fsm per pulizia e controllo latch
o_en <= '1' when (st_att = sRestart or st_att = sRead or st_att = sWrite1 or st_att = sWrite2) else '0';
o_we <= '1' when (st_att = sWrite1 or st_att = sWrite2 ) else '0';
b_en <= '1' when (st_att = sRestart or st_att = sRead or st_att = sWrite1 or st_att = sWrite2 or st_att = sTerm or st_att = sCuscino) else '0';
o_done <= '1' when (st_att = sTerm and in_addr = nTerminazione and i_start = '1') else '0';
o_address<= in_addr when( st_att = sRead ) else--or st_prox = sRead
            out_addr when (st_att = sWrite1 or st_att = sWrite2 or st_prox = sWrite1 or st_prox = sWrite2) else (others => '0');
--out_value_buffer(7 downto 6) <= fY when (st_att = sConv2 or st_att = sConv6);
--out_value_buffer (5 downto 4) <= fY when (st_att = sConv3 or st_att = sConv7);
--out_value_buffer (3 downto 2) <= fY when (st_att = sConv4 or st_att = sConv8);
--out_value_buffer (1 downto 0) <= fY when (st_att = sWrite1 or st_att = sWrite2 );

o_data <= out_value_buffer;

fsm : process(i_clk,i_data, i_start, st_att, in_addr, in_value,fY,out_addr,nTerminazione) is
begin 
--bisogna fare una grande pulizia, togliere tutte le modifiche in modo che non generino decine di latch
    case(st_att) is
        
        when sReStart => --gestire il registro con dentro nTerminazione
                --o_done <='0';

            
           -- o_address <= (others => '0');
       --     in_a_prox <=(0 => '1', others => '0');
          --  out_a_prox<=std_logic_vector(to_unsigned(1000, 16));-- ma se ricevo un "restart" da dove inizia la crittura successiva??
     --       nTerminazione <= (others => '0');--inserisce numero 
     --       nTerminazione(7 downto 0) <= i_data+1 ;-- tutto ok se il numero è in binario unsigned normale, e se la memoria è indirizzata in unsigned normale
            
            st_prox <= sCuscino;
            
        when sCuscino =>
            st_prox <= sRead;
        when sRead =>
            
          --  o_address <= in_addr;
        --    in_a_prox <= std_logic_vector(to_unsigned(((to_integer(unsigned(in_addr))) + 1),16));
            st_prox <= sConv1;
            
        when sConv1 =>
            
        --    fU <= i_data(7);
           -- in_value <= i_data;
            st_prox <= sConv2;
            
        when sConv2 =>
         --   fU<= in_value(6);
        --    o_data (7 downto 6) <= fY;--fy ha gia l'uscita pronta? yes; sarebbe carino usare un registro a shift, potrei comprimere molti stati
            st_prox <= sConv3; 
                 
        when sConv3 =>
         --   fU<= in_value(5);
         --   o_data (5 downto 4) <=fY;
            st_prox <= sConv4;
            
        when sConv4 =>
       --     fU<= in_value(4);
       --     o_data (3 downto 2) <=fY;  

            st_prox <= sWrite1;
             --ferma macchina a stii convolutore
            
        when sWrite1 =>
      --      o_data (1 downto 0)<= fY;
        --    o_address <= out_addr;
        --    out_a_prox<= std_logic_vector(to_unsigned(((to_integer(unsigned(out_addr))) + 1),16));
           

            st_prox <= sConv5;
            
        when sConv5 => 
        
        --    fU<= in_value(3);
            st_prox <= sConv6;  
            
        when sConv6 =>
        --    fU<= in_value(2);
       --     o_data (7 downto 6) <= fY;
            st_prox <= sConv7; 
                             
        when sConv7 =>
          --  fU<= in_value(1);
      --      o_data (5 downto 4) <=fY;
            st_prox <= sConv8;
                        
        when sConv8 =>
           -- fU<= in_value(0);
      --      o_data (3 downto 2) <=fY;
            st_prox <= sWrite2;   
  
            
        when sWrite2 =>
      --      o_data (1 downto 0)<= fY;
         --   o_address <= out_addr;
      --      out_a_prox<= std_logic_vector(to_unsigned(((to_integer(unsigned(out_addr))) + 1),16));
           
            st_prox <= sTerm;    
            
        when sTerm=>   -- se finisce parole da leggere setta o_done a 0, cicla finche non riceve start = 0 e poi setta done a 0
            if (in_addr /= nTerminazione) then
              st_prox <= sRead;
            else
            
              if(rising_edge(i_start)) then
                st_prox <= sRestart;
              end if;
            end if;
     end case;   
end process;
process_registri : process(i_clk) is

begin
if(i_clk'event and i_clk ='0')then

    if(st_att = sWrite1 or st_att = sWrite2) then
        out_a_prox<= std_logic_vector(to_unsigned(((to_integer(unsigned(out_addr))) + 1),16));
    elsif (st_att = sRestart) then
        out_a_prox<= std_logic_vector(to_unsigned(1000, 16)) ;
    end if;
    
    if (st_att = sRead ) then
        in_a_prox <= std_logic_vector(to_unsigned(((to_integer(unsigned(in_addr))) + 1),16));
    elsif (st_att = sRestart) then
        in_a_prox <=(0 => '1', others => '0');
    end if;
    
    if (st_att = sConv2 or st_att = sConv6) then
      out_value_buffer(7 downto 6) <= fY ;
    elsif (st_att = sConv3 or st_att = sConv7) then
      out_value_buffer (5 downto 4) <= fY ;
    elsif(st_att = sConv4 or st_att = sConv8)then
        out_value_buffer (3 downto 2) <= fY  ;
    elsif (st_att = sWrite1 or st_att = sWrite2 )then
         out_value_buffer (1 downto 0) <= fY  ;
    end if;
    
    if (st_att = sRestart) then
        nTerminazione(15 downto 8) <= (others =>'0') ;
        nTerminazione(7 downto 0) <= i_data+1  ;
    end if;
    if (st_att = sConv1) then
        in_value <= i_data;
    end if;
end if;
end process;

----questo è un registro; uso latch o ci sono altri modi?
--out_a_prox<= std_logic_vector(to_unsigned(((to_integer(unsigned(out_addr))) + 1),16)) when (st_att = sWrite1 or st_att = sWrite2) else
--             std_logic_vector(to_unsigned(1000, 16)) when (st_att = sRestart);
---- stesso discorso di out prox address, registro
--in_a_prox <= std_logic_vector(to_unsigned(((to_integer(unsigned(in_addr))) + 1),16)) when (st_att = sRead )else 
--             (0 => '1', others => '0') when (st_att = sRestart);

fU <= in_value(7) when (st_att = sConv1) else
      in_value(6) when (st_att = sConv2) else
      in_value(5) when (st_att = sConv3) else
      in_value(4) when (st_att = sConv4) else
      in_value(3) when (st_att = sConv5) else
      in_value(2) when (st_att = sConv6) else
      in_value(1) when (st_att = sConv7) else
      in_value(0) when (st_att = sConv8) else '-';

--registro nterm
--nTerminazione(15 downto 8) <= (others =>'0') ;
--nTerminazione(7 downto 0) <= i_data+1 when (st_att = sRestart) ;

end arch_stati;