.PHONY: help sim check all mutated repaired sim-day2 tools wave-a wave-b

help:
	@echo "8051 Bootcamp (WBS Day 1 & Day 2) - IIC-OSIC / WSL Targets:"
	@echo "  make sim       - Run Day-1 baseline simulations (hello, test_a, test_b)"
	@echo "  make check     - Run golden ISA trace checker on Day-1 test_a & test_b"
	@echo "  make all       - Run Day-1 sim + check"
	@echo "  make mutated   - Run MUT-01 defect injection test_a"
	@echo "  make repaired  - Run repaired regression (test_a + test_b)"
	@echo "  make sim-day2  - Run Day-2 peripheral & IRQ simulations (e05_gpio, e06_timer, e07_irq)"
	@echo "  make tools     - Refresh tools.lock with active container versions"
	@echo "  make wave-a    - Open traces/test_a.vcd in Surfer"
	@echo "  make wave-b    - Open traces/test_b.vcd in Surfer"

sim:
	bash scripts/run_baseline_all.sh

check:
	python3 scripts/trace_checker.py --rom firmware/asm/test_a_arith.in --trace reports/test_a_trace.csv
	python3 scripts/trace_checker.py --rom firmware/asm/test_b_ctrl_stack.in --trace reports/test_b_trace.csv

all: sim check

mutated:
	bash scripts/run_mutated_test_a.sh

repaired:
	bash scripts/run_repaired_regression.sh

sim-day2:
	bash scripts/run_day2_all.sh

tools:
	bash scripts/check_tools.sh

wave-a:
	surfer traces/test_a.vcd &

wave-b:
	surfer traces/test_b.vcd &
