library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity main is
    Port ( a : in STD_LOGIC_VECTOR(31 downto 0) ;
			  b : in STD_LOGIC_VECTOR(31 downto 0) ;
			  op : in std_logic;
			  start,reset,clock : in std_logic;
			  result : out STD_LOGIC_VECTOR(31 downto 0);
			  sum_frac : out std_logic_vector(24 downto 0 );
			  s_expo : out std_logic_vector(8 downto 0);
			  done : out std_logic);
end main;

architecture Behavioral of main is
type state_type is (S0,S1,S2,S3,S4);
signal state : state_type := S0;
signal expo_a : std_logic_vector(8 downto 0);
signal expo_b : std_logic_vector(8 downto 0);
signal sum_expo : std_logic_vector(8 downto 0);
signal diff_expo : std_logic_vector(8 downto 0);
signal diff : integer := 0;
signal sign_a : std_logic;
signal sign_b : std_logic;
signal sum_sign : std_logic;
signal faction_a : std_logic_vector(24 downto 0);
signal faction_b : std_logic_vector(24 downto 0);
signal sum_faction : std_logic_vector(24 downto 0);

begin
	process(clock)
		begin
		
		if (reset = '1') then
			state <= S0;
			result <= (others => '0');
			done <= '0';
			
		elsif rising_edge(clock) then
			case state is
				when S0 =>
					if start = '1' then
						expo_a <= '0' & a(30 downto 23);
						expo_b <= '0' & b(30 downto 23);
						sign_a <= a(31);
						sign_b <= b(31);
						faction_a <= "01" & a(22 downto 0);
						faction_b <= "01" & b(22 downto 0);
						state <= S1;
						
					else
						state <= S0;
						done <= '0';
					end if;
						
				when S1 =>
					if unsigned(expo_a) > unsigned(expo_b) then
						sum_expo <= expo_a;
						diff_expo <= std_logic_vector(unsigned(expo_a) - unsigned(expo_b));
						diff <= to_integer(unsigned(diff_expo));
						if diff > 23 then
							sum_faction <= faction_a;
							sum_sign <= sign_a;
							state <= S3;
						else
							faction_b <= std_logic_vector(shift_right(unsigned(faction_b), diff));
							state <= S2;			
						end if;
						
					else
						if unsigned(expo_a) = unsigned(expo_b) then
							sum_expo <= expo_a;
							state <= S2;
						else
							sum_expo <= expo_b;
							diff_expo <= std_logic_vector(unsigned(expo_a) - unsigned(expo_b));
							diff <= to_integer(unsigned(diff_expo));
							if diff > 23 then
								sum_faction <= faction_b;
								sum_sign <= sign_b;
								state <= S3;
							else
								faction_a <= std_logic_vector(shift_right(unsigned(faction_a), diff));
								state <= S2;			
							end if;
						end if;
					end if;
						
				when S2 =>
					if (op = '1') then 
						if (sign_a xor sign_b) = '0' then
							sum_faction <= std_logic_vector(unsigned(faction_a) + unsigned(faction_b));
							sum_sign <= sign_a;
							state <= S3;
						else
							if unsigned(faction_a) > unsigned(faction_b) then
								sum_faction <= std_logic_vector(unsigned(faction_a) - unsigned(faction_b));
								sum_sign <= sign_a;
								state <= S3;
							else
								sum_faction <= std_logic_vector(unsigned(faction_b) - unsigned(faction_a));
								sum_sign <= sign_b;
								state <= S3;
							end if;
						end if;
					elsif (op = '0') then    
						if (sign_a xor sign_b) = '0' then
							sum_faction <= std_logic_vector(unsigned(faction_a) - unsigned(faction_b));
							sum_sign <= sign_a;
							state <= S3;
						else
							if unsigned(faction_a) > unsigned(faction_b) then
								sum_faction <= std_logic_vector(unsigned(faction_a) + unsigned(faction_b));
								sum_sign <= sign_a;
								state <= S3;
							else
								sum_faction <= std_logic_vector(unsigned(faction_b) + unsigned(faction_a));
								sum_sign <= sign_b;
								state <= S3;
							end if;
						end if;
					end if ;
					
				when S3 =>
					if sum_faction(24) = '1' then
						sum_faction <= std_logic_vector(shift_right(unsigned(sum_faction), 1));
						sum_expo <= std_logic_vector(unsigned(sum_expo) + 1);
						state <= S4;
					else
						if sum_faction(23) = '1' then
							state <= S4;
						else 
							sum_faction <= std_logic_vector(shift_left(unsigned(sum_faction), 1));
							sum_expo <= std_logic_vector(unsigned(sum_expo) - 1);
							state <= S4;
						end if;
					end if;
					
				when S4 =>
					s_expo <= sum_expo ;
					sum_frac <= sum_faction ;
					result <= sum_sign & sum_expo(7 downto 0) & sum_faction(22 downto 0);
					state <= S0;
					done <= '1';
					
				when others =>
               state <= S0;

			end case;				
				
		end if;
	end process;
    
end Behavioral;
