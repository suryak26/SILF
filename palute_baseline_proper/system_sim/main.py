from config import get_model_params
from simulator import PIMSimulator

TASK_JSON_FILENAME = 'test/Op/examp2.json'

if __name__ == "__main__":
    params = get_model_params()
    simulator = PIMSimulator(params)
    simulator.load_json(TASK_JSON_FILENAME)
    simulator.run()