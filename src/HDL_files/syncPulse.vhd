-- The MIT License (MIT)
--
-- Copyright (c) 2024 Lovre Bogdanic, lovre.bogdanic@gmail.com
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


-- =============================================================================
-- This design is modified version of a design provided in PoC library 
-- developed by Patrick Lehmann, Technische Universitaet Dresden.
-- https://github.com/VLSI-EDA/PoC
-- 
-- Above mentioned library is published under Apache License, Version 2.0.
-- =============================================================================
--
-- Author of modifications: Lovre Bogdanic
-- 
-- Design is simplified for our typical usage, meaning one bit input with 2 
-- synchronization flip flops. 
-- 
-- Explanation: Pulse is used as a clock on input register and on it's rising edge  
-- register's output is set to one. This signal is then processed with one async 
-- register followed by two synchronization registers.
-- Output of a input register is cleared when pulse value is zero and output value 
-- is one. That also gives a limitation of allowed pulse frequency which is        



library ieee;
use ieee.std_logic_1164.all;

entity syncPulse is
	port (
		Clock         : in  std_logic;        -- <Clock>  output clock domain
		Input         : in  std_logic;        -- @async:  input bit
		Output        : out std_logic         -- @Clock:  output bit
	);
end entity;


architecture rtl of syncPulse is
	--attribute PRESERVE          : boolean;
	--attribute ALTERA_ATTRIBUTE  : string;
	
	signal Data_async       : std_logic                    := '0';
	signal Data_meta        : std_logic                    := '0';
	signal Data_sync        : std_logic_vector(1 downto 0) := (others => '0');
	
	-- Apply a SDC constraint to meta stable flip flop
	--attribute ALTERA_ATTRIBUTE of rtl        : architecture is "-name SDC_STATEMENT ""set_false_path -to [get_registers {Data_meta}] """;

	-- preserve both registers (no optimization, shift register extraction, ...)
	--attribute PRESERVE of Data_meta            : signal is TRUE;
	--attribute PRESERVE of Data_sync            : signal is TRUE;
	-- Notify the synthesizer / timing analyzer to identity a synchronizer circuit
	--attribute ALTERA_ATTRIBUTE of Data_meta    : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";

begin
	
	inputReg: process(Input, Data_sync(1))
	begin
		if Data_sync(1) = '1' then
			Data_async <= '0';
		elsif rising_edge(Input) then
			Data_async <= '1';
		end if;
	end process;
	
	asyncReg: process(Clock)
	begin
		if rising_edge(Clock) then
			Data_meta <= Data_async;
		end if;
	end process;
	
	syncReg: process(Clock)
	begin
		if rising_edge(Clock) then
			if Data_sync(1) = '1' then
				Data_sync <= (others => '0');
			else
				Data_sync <= Data_sync(0) & Data_meta;
			end if;	
		end if;
	end process;

	Output    <= Data_sync(1);

end rtl;

