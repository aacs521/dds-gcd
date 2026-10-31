-- finite state machine
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entity
entity gcd_fsm is
    port (
        clk     :   in  std_logic;
        reset   :   in  std_logic;
        req     :   in  std_logic;
        N       :   in  std_logic;
        Z       :   in  std_logic;

        ABorALU :   out std_logic;
        LDA     :   out std_logic;
        LDB     :   out std_logic;
        FN      :   out unsigned(1 downto 0);
        ack     :   out std_logic
    );
end entity gcd_fsm;

-- rtl
architecture rtl_gcd_fsm of gcd_fsm is
    type state_t is (
        s_idle,
        s_loada, s_waitb,
        s_loadb, s_chkb,
        s_comp, s_compsub,
        s_done, s_doneb
    );
    signal state, next_state : state_t;
begin
    process (clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then state <= s_idle;
            else                state <= next_state;
            end if;
        end if;
    end process;

    process (state, req, N, Z)
    begin
        next_state <= state;
        ABorALU <= '0';
        LDA <= '0';
        LDB <= '0';
        FN <= "00";
        ack <= '0';

        case state is
            when s_idle =>
                if req = '1' then
                    next_state <= s_loada;
                end if;

            when s_loada =>
                ABorALU <= '0';
                LDA <= '1';
                ack <= '1';
                if req = '0' then
                    next_state <= s_waitb;
                end if;

            when s_waitb =>
                if req = '1' then
                    next_state <= s_loadb;
                end if;

            when s_loadb =>
                ABorALU <= '0';
                LDB <= '1';
                FN <= "10";
                if Z = '1' then
                    next_state <= s_doneb;
                else
                    next_state <= s_chkb;
                end if;

            when s_chkb =>
                FN <= "11";
                if Z = '1' then
                    next_state <= s_done;
                else
                    next_state <= s_comp;
                end if;

            when s_comp =>
                FN <= "00";
                if Z = '1' then
                    next_state <= s_done;
                elsif N <= '0' then
                    ABorALU <= '1';
                    LDA <= '1';
                    next_state <= s_comp;
                else
                    next_state <= s_compsub;
                end if;

            when s_compsub =>
                FN <= "01";
                ABorALU <= '1';
                LDB <= '1';
                next_state <= s_comp;

            when s_done =>
                ABorALU <= '1';
                FN <= "10";
                ack <= '1';
                if req = '0' then
                    next_state <= s_idle;
                end if;

            when s_doneb =>
                ABorALU <= '1';
                FN <= "11";
                ack <= '1';
                if req = '0' then
                    next_state <= s_idle;
                end if;

            when others =>
                next_state <= s_idle;
        end case;
    end process;
end architecture rtl_gcd_fsm;
