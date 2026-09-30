import sys
from config import get_model_params
from simulator import PIMSimulator

TASK_JSON_FILENAME = 'test/Op/examp2.json'

if __name__ == "__main__":
    if len(sys.argv) > 1:
        TASK_JSON_FILENAME = sys.argv[1]

    params = get_model_params()
    simulator = PIMSimulator(params)
    simulator.load_json(TASK_JSON_FILENAME)
    simulator.run()
