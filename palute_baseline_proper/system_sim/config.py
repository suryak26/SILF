def get_model_params():
    params = {
        # -----------------------------
        # Quantization / LUT config
        # -----------------------------
        "u": 2,
        "pa": 4,
        "pw": 4,
        "LUT_DEPTH": 112,
        "LUT_GEN_CYCLES": 3,
        "AMORT_T_ACT_NS": 14.16,
        "AMORT_GEN_NS": 15.0,
        "AMORT_QUERY_COUNT": 104,

        # -----------------------------
        # DRAM
        # -----------------------------
        "N_row": 512,
        "N_col": 512,
        "N_channel": 4,
        "N_bank": 4,
        "N_mat": 512,
        "BW_row_buf": 128, # bit per cycle

        # -----------------------------
        # LUT generation
        # -----------------------------
        "E_LUT_gen": 45.36, # pJ
        "Gen_shared": 8,     # number of shared LUTs for one LUT generator

        # -----------------------------
        # Match
        # -----------------------------
        "CMP_num": 16,         # number of comparators
        "P_Match": 6.098e-4,   # W

        # -----------------------------
        # Accumulator
        # -----------------------------
        "T_clk": 2.0,      # ns, 500 MHz
        "P_acc": 1.1225e-3,   # W
        "Adder_num": 16,     # number of adders in one accumulator
        "Acc_shared": 8,   # number of MATS sharing one accumulator

        # -----------------------------
        # Transfer
        # -----------------------------
        "BW_Hybrid_Bonding": 1.38  # TB/s
    }

    return params