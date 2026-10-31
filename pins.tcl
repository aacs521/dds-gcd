foreach {sig pin std} {
    clk         PIN_R20     "3.3-V LVTTL"
    reset       PIN_P12     "1.2-V"
    req         PIN_P11     "1.2-V"
    AB[0]       PIN_AC9     "1.2-V"
    AB[1]       PIN_AE10    "1.2-V"
    AB[2]       PIN_AD13    "1.2-V"
    AB[3]       PIN_AC8     "1.2-V"
    AB[4]       PIN_W11     "1.2-V"
    AB[5]       PIN_AB10    "1.2-V"
    AB[6]       PIN_V10     "1.2-V"
    AB[7]       PIN_AC10    "1.2-V"
    AB[8]       PIN_Y11     "1.2-V"
    AB[9]       PIN_AE19    "1.2-V"
    ack         PIN_L7      "2.5-V"
    C[0]        PIN_F7      "2.5-V"
    C[1]        PIN_F6      "2.5-V"
    C[2]        PIN_G6      "2.5-V"
    C[3]        PIN_G7      "2.5-V"
    C[4]        PIN_J8      "2.5-V"
    C[5]        PIN_J7      "2.5-V"
    C[6]        PIN_K10     "2.5-V"
    C[7]        PIN_K8      "2.5-V"
    C[8]        PIN_H7      "2.5-V"
    C[9]        PIN_J10     "2.5-V"
} {
    set_location_assignment $pin -to $sig
    set_instance_assignment -name IO_STANDARD $std -to $sig
}
