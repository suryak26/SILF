import json
import models


class PIMSimulator:
    def __init__(self, params):
        self.params = params
        self.tensors = {}
        self.ops = []
        self.total_energy = 0.0
        self.total_latency = 0.0
        self.breakdown = models.zero_breakdown()
        print('Simulator initialized')

    def load_json(self, filepath):
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                data = json.load(f)

            self.tensors = {t['name']: t for t in data['tensors']}
            self.ops = data['ops']
            print(f'Load {filepath}, including {len(self.tensors)} tensors and {len(self.ops)} ops')
        except FileNotFoundError:
            print(f"[error] can't find JSON: {filepath}")
            exit(1)
        except json.JSONDecodeError:
            print(f"[error] can't parse JSON: {filepath}")
            exit(1)

    def _accumulate_breakdown(self, op_breakdown):
        for key in models.BREAKDOWN_KEYS:
            self.breakdown[key]['energy'] += op_breakdown[key]['energy']
            self.breakdown[key]['latency'] += op_breakdown[key]['latency']

    def _print_breakdown(self):
        print('--- 📊 Energy / Latency breakdown ---')
        print(f"{'Component':<18} | {'Energy (pJ)':>15} | {'Latency (ns)':>15} | {'E %':>8} | {'L %':>8}")
        print('-' * 76)

        for key in models.BREAKDOWN_KEYS:
            label = models.BREAKDOWN_LABELS.get(key, key)
            energy = self.breakdown[key]['energy']
            latency = self.breakdown[key]['latency']
            e_pct = energy / self.total_energy * 100 if self.total_energy else 0.0
            l_pct = latency / self.total_latency * 100 if self.total_latency else 0.0
            print(f"{label:<18} | {energy:15.2f} | {latency:15.2f} | {e_pct:7.2f}% | {l_pct:7.2f}%")

        bd_energy = sum(self.breakdown[key]['energy'] for key in models.BREAKDOWN_KEYS)
        bd_latency = sum(self.breakdown[key]['latency'] for key in models.BREAKDOWN_KEYS)
        print('-' * 76)
        print(f"{'Breakdown sum':<18} | {bd_energy:15.2f} | {bd_latency:15.2f} | {100.00:7.2f}% | {100.00:7.2f}%")

    def get_breakdown(self):
        return self.breakdown

    def run(self):
        print('--- 🚀 Simulation begins ---')
        self.total_energy = 0.0      # pJ
        self.total_latency = 0.0     # ns
        self.breakdown = models.zero_breakdown()

        for i, op in enumerate(self.ops):
            op_type = op.get('type', 'Unknown')
            e, l, op_breakdown = 0, 0, models.zero_breakdown()

            if op_type == 'MatMul':
                e, l, op_breakdown = models.matmul_query_cost(
                    op, self.tensors, self.params, return_breakdown=True
                )
            elif op_type in ('Gelu', 'SiLU', 'Relu'): # element-wise
                e, l, op_breakdown = models.calculate_unary_cost(
                    op, self.tensors, self.params, return_breakdown=True
                )
            elif op_type == 'ParallelOps':
                e, l, op_breakdown = models.calculate_parallel_cost(
                    op, self.tensors, self.params, return_breakdown=True
                )
            else:
                print(f'  [Op {i:2}] Type: {op_type:<12} | unknown op, ignore')
                continue

            self.total_energy += e
            self.total_latency += l
            self._accumulate_breakdown(op_breakdown)

            print(f'  [No.{i:2}] Type: {op_type:<12} | Energy: {e:15.2f} pJ | Latency: {l:15.2f} ns')

        print('--- 🏁 Simulation completed ---')
        print(f'Energy: {self.total_energy*1e-9:,.2f} mJ')
        print(f'Latency: {self.total_latency*1e-6:,.4f} ms')
        print(f'Power: {self.total_energy*1e-9 / (self.total_latency*1e-6):,.2f} W')
        self._print_breakdown()

# import json
# import models

# class PIMSimulator:
#     def __init__(self, params):
#         self.params = params
#         self.tensors = {}
#         self.ops = []
#         self.total_energy = 0.0
#         self.total_latency = 0.0
#         print("Simulator initialized")

#     def load_json(self, filepath):
#         try:
#             with open(filepath, 'r', encoding='utf-8') as f:
#                 data = json.load(f)

#             self.tensors = {t['name']: t for t in data['tensors']}
#             self.ops = data['ops']
#             print(f"Load {filepath}, including {len(self.tensors)} tensors and {len(self.ops)} ops")
#         except FileNotFoundError:
#             print(f"[error] can't find JSON: {filepath}")
#             exit(1)
#         except json.JSONDecodeError:
#             print(f"[error] can't parse JSON: {filepath}")
#             exit(1)

#     def run(self):
#         print("--- 🚀 Simulation begins ---")
#         self.total_energy = 0.0      # in mJ
#         self.total_latency = 0.0     # in ms

#         for i, op in enumerate(self.ops):
#             op_type = op.get('type', 'Unknown')
#             e, l = 0, 0

#             if op_type == 'MatMul':
#                 e, l = models.matmul_query_cost(op, self.tensors, self.params)
#             elif op_type in ('Gelu', 'SiLU', 'Relu'):
#                 e, l = models.calculate_unary_cost(op, self.tensors, self.params)
#             elif op_type == 'ParallelOps': # 'opcode' == 'parallelops'
#                 e, l = models.calculate_parallel_cost(op, self.tensors, self.params)

#             else:
#                 print(f"  [Op {i:2}] Type: {op_type:<12} | unknown op, ignore")
#                 continue

#             # ====== UNIT CONVERSION ======
#             # e = e * 1e-12      # pJ → mJ
#             # l = l * 1e-6       # ns → ms

#             self.total_energy  += e
#             self.total_latency += l

#             print(f"  [No.{i:2}] Type: {op_type:<12} | Energy: {e:15.2f} pJ | Latency: {l:15.2f} ns")

#         print("--- 🏁 Simulation completed ---")
#         print(f"✅ Total Energy: {self.total_energy:,.2f} pJ")
#         print(f"✅ Total Latency: {self.total_latency:,.2f} ns")
