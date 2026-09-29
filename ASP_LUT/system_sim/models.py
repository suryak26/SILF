import math

BREAKDOWN_KEYS = (
    'lut_generation',
    'match_query',
    'dram_rw',
    'accumulate',
)

BREAKDOWN_LABELS = {
    'lut_generation': 'LUT generation',
    'match_query': 'Match & query',
    'dram_rw': 'Memory read/write',
    'accumulate': 'Accumulate',
}


def zero_breakdown():
    return {
        key: {'energy': 0.0, 'latency': 0.0}
        for key in BREAKDOWN_KEYS
    }


def add_breakdown_cost(breakdown, key, energy=0.0, latency=0.0):
    if key not in breakdown:
        raise KeyError(f'Unknown breakdown key: {key}')
    breakdown[key]['energy'] += energy
    breakdown[key]['latency'] += latency


def breakdown_totals(breakdown):
    energy = sum(breakdown[key]['energy'] for key in BREAKDOWN_KEYS)
    latency = sum(breakdown[key]['latency'] for key in BREAKDOWN_KEYS)
    return energy, latency


def lut_len(params, u, pw):
    L = params['LUT_DEPTH']
    N_row = params['N_row']
    serial_times = max(1, math.ceil(L / N_row))

    if L > N_row:
        print(f"[info] LUT length exceeds N_row: L={L}, N_row={N_row}, serial_times={serial_times}")

    return L, serial_times

def LUT_gen_cost(op, tensors, params, return_breakdown=False):
    breakdown = zero_breakdown()
    T_clk = params['T_clk']
    E_gen = params['E_LUT_gen']     # pJ per one LUT generation
    N_channel = params['N_channel']
    N_bank = params['N_bank']
    N_MAT = params['N_mat']

    N_MAT_per_Chip = N_channel * N_bank * N_MAT

    Gen_shared = params['Gen_shared']
    BW_row_buf = params['BW_row_buf']

    A_info = tensors[op['A']]
    N, K1 = A_info['shape']
    pa = A_info['bits']
    _, M = A_info['shape']

    B_info = tensors[op['B']]
    pw = B_info['bits']

    n = N
    d = K1
    u = params['u']
    N_LUT = math.ceil(d / u) * n
    N_LUT_max = N_MAT_per_Chip * (params['N_col'] // (pa * max(1, math.ceil(params['LUT_DEPTH'] / params['N_row']))))
    Length, _ = lut_len(params, u=u, pw=pw)

    # 1. Read raw data from DRAM
    t_read, e_read = dram_read_write_model(pa, 'logic_data') # only read pa-bit data in one row
    N_data = n * d # number of data elements to read from DRAM
    e_read_total = e_read * N_data
    t_read_total =  t_read * max(1, math.ceil((N_data * pa) / (N_MAT_per_Chip * BW_row_buf)))

    # 2. Generate LUTs
    e_gen_total = E_gen * N_LUT
    t_gen_total = params['LUT_GEN_CYCLES'] * T_clk * Gen_shared * max(1, math.ceil(N_LUT / N_MAT_per_Chip))  # 3 cycles per LUT generation, if num of LUT exceed N_MAT_per_Chip, need to generate in serial

    # 3. Write LUTs back to DRAM
    t_write, e_write = dram_read_write_model(pa, 'logic_lut') # only write pa-bit data in one row
    Length, _ = lut_len(params, u=u, pw=pw)

    e_write_total = e_write * Length * N_LUT
    t_write_total = t_write * Length * max(1, math.ceil((N_LUT * pa) / (N_MAT_per_Chip * BW_row_buf)))

    # Total energy and latency
    E_gen_total = e_gen_total + e_read_total + e_write_total
    T_gen_total = t_gen_total + t_read_total + t_write_total

    if return_breakdown:
        add_breakdown_cost(breakdown, 'lut_generation', energy=e_gen_total, latency=t_gen_total)
        add_breakdown_cost(breakdown, 'dram_rw', energy=e_read_total + e_write_total, latency=t_read_total + t_write_total)
        return e_gen_total, e_read_total + e_write_total, t_gen_total, t_read_total + t_write_total

    return E_gen_total, T_gen_total

def Compare_cost(op, tensors, params):
    T_clk = params['T_clk']
    u = params['u']

    if 'B' in op:
        A_info = tensors[op['A']]
        B_info = tensors[op['B']]
        N, K1 = A_info['shape']
        K2, M = B_info['shape']
        pw = B_info['bits']
        N_LUT = math.ceil(K1 / u) * N * M
        pa = B_info['bits']

    else:
        A_info = tensors[op['A']]
        N, K1 = A_info['shape']
        pw = A_info['bits']
        N_LUT = N * K1
        pa = A_info['bits']

    Length, serial_times = lut_len(params, u=u, pw=pw)

    N_col = params['N_col']

    N_channel = params['N_channel']
    N_bank = params['N_bank']
    N_MAT = params['N_mat']
    N_cmp = params['CMP_num']

    LUT_per_MAT = N_col // (pa * serial_times)
    N_total_MAT = N_channel * N_bank * N_MAT    # total number of MATs in the chip
    N_LUT_max = N_total_MAT * LUT_per_MAT         # maximum number of LUTs that can be loaded to MATs
    N_load_LUT = max(1, math.ceil(N_LUT / N_LUT_max))   # number of times to load LUTs to MATS

    T_match = min(Length, params['N_row']) * T_clk * N_load_LUT # ns
    E_match = params['P_Match'] * Length * T_clk * 1000 * N_load_LUT # pJ

    return E_match, T_match

def MATCH_LUT(op, tensors, params, return_breakdown=False):
    A_info = tensors[op['A']]
    pa = A_info['bits']
    N, K1 = A_info['shape']

    n = N
    d = K1
    u = params['u']

    if op.get('B') is None:
        N_LUT = d * n
    else:
        N_LUT = math.ceil(d / u) * n

    t_data, e_rw = dram_read_write_model(pa, 'logic_lut')     # only read pa-bit data in one row
    t_trans = DRAM_transfer_cost(op, tensors, params)

    if return_breakdown:
        return e_rw * N_LUT, t_data, t_trans
    return e_rw * N_LUT, t_data + t_trans


def DRAM_transfer_cost(op, tensors, params):
    A_info = tensors[op['A']]
    shape = A_info['shape']

    if len(shape) == 1:
        N, K = 1, shape[0]
    else:
        N, K = shape[0], shape[1]

    pw = A_info['bits']
    bits = N * K * pw

    T_transfer = (bits / (params['BW_Hybrid_Bonding'] * 1e12 * 8)) * 1e9  # ns

    return T_transfer

M3D_TIER_T_RCD = [3.92, 8.50]   # ns
M3D_T_RP = 4.77                 # ns
M3D_T_RAS_EXTRA = 27.50         # ns
M3D_E_PER_BIT = 0.429           # pJ/bit

def dram_read_write_model(bits, type):

    if type == 'logic_data':
        tRCD = M3D_TIER_T_RCD[0]
    elif type == 'logic_lut':
        tRCD = M3D_TIER_T_RCD[1]
    else:
        raise ValueError("type must be 'logic_data' or 'logic_lut'")


    tRP = M3D_T_RP
    tRAS = tRCD + M3D_T_RAS_EXTRA
    tRC = tRP + tRAS

    energy = bits * M3D_E_PER_BIT
    # simplified closed-row access
    latency = tRC

    return latency, energy


def Accumulation_cost(op, tensors, params):

    A_info = tensors[op['A']]
    N, K1 = A_info['shape']
    B_info = tensors[op['B']]
    K2, M = B_info['shape']
    u = params['u']

    if K1 != K2:
        raise RuntimeError(
            f"Matrix dimension not match: "
            f"A is ({N}, {K1}), B is ({K2}, {M})"
        )

    N_acc_task = N * M

    N_serial_times = params['Acc_shared']   # number of MATS sharing one accumulator

    num_operand = math.ceil(K1 / u)

    if num_operand <= 1:
        return 0, 0

    Adder_num = max(1, params['Adder_num'])

    total_cycles = 0
    active_operand = num_operand

    while active_operand > 1:
        num_add = active_operand // 2
        total_cycles += math.ceil(num_add / Adder_num)
        active_operand = math.ceil(active_operand / 2)

    e_acc = params['P_acc'] * total_cycles * params['T_clk'] * 1000
    t_acc = params['T_clk'] * total_cycles

    return e_acc * N_acc_task, t_acc * N_serial_times


def matmul_query_cost(op, tensors, params, return_breakdown=False):
    breakdown = zero_breakdown()

    try:
        A_info = tensors[op['A']]
        B_info = tensors[op['B']]

        N, K1 = A_info['shape']
        K2, M = B_info['shape']

        if op.get('transpose_B', False):
            K2, M = M, K2

        if K1 != K2:
            raise RuntimeError(
                f"Matrix dimension not match: "
                f"A is ({N}, {K1}), B is ({K2}, {M}) after transpose_B={op.get('transpose_B', False)}"
            )

        # 1. LUT generation and DRAM read/write
        e_lut_gen, e_dram, t_lut_gen, t_dram = LUT_gen_cost(op, tensors, params, return_breakdown=True)
        add_breakdown_cost(breakdown, 'lut_generation', e_lut_gen, t_lut_gen)
        add_breakdown_cost(breakdown, 'dram_rw', e_dram, t_dram)

        # 2. Compare & match
        e_sweep, t_sweep = Compare_cost(op, tensors, params)
        e_rw, t_data, t_trans = MATCH_LUT(op, tensors, params, return_breakdown=True)
        add_breakdown_cost(breakdown, 'match_query', e_sweep, t_sweep)
        add_breakdown_cost(breakdown, 'dram_rw', e_rw, t_trans+t_data)

        # 3. Accumulation
        e_acc, t_acc = Accumulation_cost(op, tensors, params)
        add_breakdown_cost(breakdown, 'accumulate', e_acc, t_acc)

        e, t = breakdown_totals(breakdown)
        if return_breakdown:
            return e, t, breakdown
        return e, t

    except KeyError as e:
        print(f"[error] MatMul: can't find tensor or parameter {e}")
        if return_breakdown:
            return 0, 0, breakdown
        return 0, 0


def calculate_unary_cost(op, tensors, params, return_breakdown=False):
    breakdown = zero_breakdown()

    try:
        N_channel = params['N_channel']
        N_bank = params['N_bank']
        N_MAT = params['N_mat']
        A_info = tensors[op['A']]

        shape = A_info['shape']
        if len(shape) == 1:
            N, K1 = 1, shape[0]
        else:
            N, K1 = shape[0], shape[1]

        N_LUT = N * K1

        N_col = params['N_col']
        pa = params['pa']
        LUT_per_MAT = N_col // pa
        N_total_MAT = N_channel * N_bank * N_MAT
        N_used_MAT = min(N_total_MAT, math.ceil(N_LUT / LUT_per_MAT))

        N_LUT_max = N_total_MAT * LUT_per_MAT
        N_load_LUT = math.ceil(N_LUT / N_LUT_max)
        N_task_para = min(N_LUT_max, N_LUT)
        N_sweep = math.ceil(N_LUT / N_task_para) * N_load_LUT

        e_sweep, t_sweep = Compare_cost(op, tensors, params)
        e_query = N_used_MAT * e_sweep * N_sweep
        t_query = t_sweep * N_sweep

        e_rw, t_data, t_trans = MATCH_LUT(op, tensors, params, return_breakdown=True)
        add_breakdown_cost(breakdown, 'match_query', e_query, t_query)
        # Current transfer model only provides latency. No data-transfer energy is modeled here.
        add_breakdown_cost(breakdown, 'dram_rw', e_rw, (t_trans + t_data)*N_sweep)

        e, t = breakdown_totals(breakdown)
        if return_breakdown:
            return e, t, breakdown
        return e, t

    except KeyError as e:
        print(f"[error] Unary: can't find tensor or parameter {e}")
        if return_breakdown:
            return 0, 0, breakdown
        return 0, 0


def calculate_parallel_cost(op, tensors, params, return_breakdown=False):
    branch_energies = []
    branch_latencies = []
    branch_breakdowns = []

    for branch_op in op['branches']:
        branch_type = branch_op.get('type', 'Unknown')
        e, l, bd = 0, 0, zero_breakdown()

        if branch_type == 'MatMul':
            e, l, bd = matmul_query_cost(branch_op, tensors, params, return_breakdown=True)
        elif branch_type in ('Unary', 'GeluOp'):
            e, l, bd = calculate_unary_cost(branch_op, tensors, params, return_breakdown=True)
        else:
            print(f"  [Parallel branch] Type: {branch_type:<12} | unknown op, ignore")

        branch_energies.append(e)
        branch_latencies.append(l)
        branch_breakdowns.append(bd)

    op_energy = sum(branch_energies)
    op_latency = max(branch_latencies) if branch_latencies else 0

    breakdown = zero_breakdown()

    # Energy of parallel branches is additive.
    for bd in branch_breakdowns:
        for key in BREAKDOWN_KEYS:
            breakdown[key]['energy'] += bd[key]['energy']

    # Latency of ParallelOps follows the critical branch, matching op_latency = max(branch latency).
    if branch_breakdowns:
        critical_idx = max(range(len(branch_latencies)), key=lambda idx: branch_latencies[idx])
        critical_bd = branch_breakdowns[critical_idx]
        for key in BREAKDOWN_KEYS:
            breakdown[key]['latency'] = critical_bd[key]['latency']

    if return_breakdown:
        return op_energy, op_latency, breakdown
    return op_energy, op_latency