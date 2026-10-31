-- top level arch
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity
entity gcd is
    generic (
        N       :   positive := 10
    );
    port (
        clk     :   in  std_logic;
        reset   :   in  std_logic;
        req     :   in  std_logic;

        AB      :   in  std_logic_vector(N-1 downto 0);

        ack     :   out std_logic;
        C       :   out std_logic_vector(N-1 downto 0)
    );
end entity gcd;

-- rtl
architecture rtl_gcd of gcd is
    signal abalu, lda, ldb, nf, zf : std_logic;
    signal fn : unsigned(1 downto 0);
    signal ireq, ireset : std_logic_vector(1 downto 0) := "00";
begin
    process (clk)
    begin
        if rising_edge(clk) then
            ireq <= ireq(0) & not req;
            ireset <= ireset(0) & not reset;
        end if;
    end process;

    u_fsm : entity work.gcd_fsm
        port map (
            clk     => clk,
            reset   => ireset(1),
            req     => ireq(1),
            N       => nf,
            Z       => zf,
            ABorALU => abalu,
            LDA     => lda,
            LDB     => ldb,
            FN      => fn,
            ack     => ack
        );

    u_datapath : entity work.gcd_datapath
        generic map (Ndp => N)
        port map (
            clk     => clk,
            ABorALU => abalu,
            LDA     => lda,
            LDB     => ldb,
            FN      => fn,
            AB      => AB,
            N       => nf,
            Z       => zf,
            C       => C
        );
end architecture rtl_gcd;
