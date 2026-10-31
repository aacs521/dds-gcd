-- datapath with components
library ieee;
use ieee.std_logic_1164.all;

-- buffer entity
entity c_buffer is
    generic (
        N       :   positive
    );
    port (
        A       :   in  std_logic_vector(N-1 downto 0);

        Q       :   out std_logic_vector(N-1 downto 0)
    );
end entity c_buffer;


library ieee;
use ieee.std_logic_1164.all;

-- 2-to-1 mux entity
entity c_mux is
    generic (
        N       :   positive
    );
    port (
        A       :   in  std_logic_vector(N-1 downto 0);
        B       :   in  std_logic_vector(N-1 downto 0);
        s       :   in  std_logic;

        Q       :   out std_logic_vector(N-1 downto 0)
    );
end entity c_mux;


library ieee;
use ieee.std_logic_1164.all;

-- positive edge-triggered register entity
entity c_reg is
    generic (
        N       :   positive
    );
    port (
        clk     :   in  std_logic;
        en      :   in  std_logic;
        A       :   in  std_logic_vector(N-1 downto 0);

        Q       :   out std_logic_vector(N-1 downto 0)
    );
end entity c_reg;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ALU entity
entity c_alu is
    generic (
        W       :   positive
    );
    port (
        A       :   in  unsigned(W-1 downto 0);
        B       :   in  unsigned(W-1 downto 0);
        fn      :   in  unsigned(1 downto 0);

        Q       :   out unsigned(W-1 downto 0);
        Z       :   out std_logic;
        N       :   out std_logic
    );
end entity c_alu;

-- buffer architecture
architecture rtl_c_buffer of c_buffer is
begin
    Q <= A;
end architecture rtl_c_buffer;

-- 2-to-1 mux architecture
architecture rtl_c_mux of c_mux is
begin
    Q <= A when s = '1' else B;
end architecture rtl_c_mux;

-- positive-edge triggered register architecture
architecture rtl_c_reg of c_reg is
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                Q <= A;
            end if;
        end if;
    end process;
end architecture rtl_c_reg;

-- ALU architecture
architecture rtl_c_alu of c_alu is
    signal d : unsigned (W downto 0);
    signal r : unsigned (W-1 downto 0);
begin
    d <= resize(A, W+1) - resize(B, W+1);
    r <= d(W-1 downto 0)    when fn = "00" else
         (B - A)            when fn = "01" else
         A                  when fn = "10" else B;
    Q <= r;
    N <= d(W);
    Z <= '1' when r = 0 else '0';
end architecture rtl_c_alu;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- main entity
entity gcd_datapath is
    generic (
        Ndp     :   positive
    );
    port (
        clk     :   in  std_logic;
        ABorALU :   in  std_logic;
        LDA     :   in  std_logic;
        LDB     :   in  std_logic;
        FN      :   in  unsigned(1 downto 0);
        AB      :   in  std_logic_vector(Ndp-1 downto 0);

        N       :   out std_logic;
        Z       :   out std_logic;
        C       :   out std_logic_vector(Ndp-1 downto 0)
    );
end entity gcd_datapath;

-- main rtl
architecture rtl_gcd_datapath of gcd_datapath is
    component c_buffer is
        generic (
            N       :   positive
        );
        port (
            A       :   in  std_logic_vector(N-1 downto 0);

            Q       :   out std_logic_vector(N-1 downto 0)
        );
    end component c_buffer;

    component c_mux is
        generic (
            N       :   positive
        );
        port (
            A       :   in  std_logic_vector(N-1 downto 0);
            B       :   in  std_logic_vector(N-1 downto 0);
            s       :   in  std_logic;

            Q       :   out std_logic_vector(N-1 downto 0)
        );
    end component c_mux;

    component c_reg is
        generic (
            N       :   positive
        );
        port (
            clk     :   in  std_logic;
            en      :   in  std_logic;
            A       :   in  std_logic_vector(N-1 downto 0);

            Q       :   out std_logic_vector(N-1 downto 0)
        );
    end component c_reg;

    component c_alu is
        generic (
            W       :   positive
        );
        port (
            A       :   in  unsigned(W-1 downto 0);
            B       :   in  unsigned(W-1 downto 0);
            fn      :   in  unsigned(1 downto 0);

            Q       :   out unsigned(W-1 downto 0);
            Z       :   out std_logic;
            N       :   out std_logic
        );
    end component c_alu;

    signal cint, y, aout, bout : unsigned(Ndp-1 downto 0);
begin
    mux : c_mux
        generic map (N => Ndp)
        port map (
            A           => std_logic_vector(y),
            B           => AB,
            s           => ABorALU,
            unsigned(Q) => cint
        );

    rega : c_reg
        generic map (N => Ndp)
        port map (
            clk         => clk,
            en          => LDA,
            A           => std_logic_vector(cint),
            unsigned(Q) => aout
        );

    regb : c_reg
        generic map (n => Ndp)
        port map (
            clk         => clk,
            en          => LDB,
            A           => std_logic_vector(cint),
            unsigned(Q) => bout
        );

    alu : c_alu
        generic map (W => Ndp)
        port map (
            A       => aout,
            B       => bout,
            fn      => FN,
            Q       => y,
            Z       => Z,
            N       => N
        );

    buf : c_buffer
        generic map (N => Ndp)
        port map (
            A       => std_logic_vector(cint),
            Q       => C
        );
end architecture rtl_gcd_datapath;
