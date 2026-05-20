.PHONY: help setup seed run test build docs clean validate

help:
	@echo "Targets:"
	@echo "  setup     Install dbt deps and verify profile"
	@echo "  seed      Load dbt seeds into Snowflake"
	@echo "  run       Run dbt models"
	@echo "  test      Run dbt tests"
	@echo "  build     Run seeds, models, and tests (full pipeline)"
	@echo "  validate  Run reconciliation script against raw data"
	@echo "  docs      Generate and serve dbt docs"
	@echo "  clean     Remove dbt target/ and logs/"

setup:
	cd dbt && dbt deps && dbt debug

seed:
	cd dbt && dbt seed

run:
	cd dbt && dbt run

test:
	cd dbt && dbt test

build:
	cd dbt && dbt build

validate:
	python scripts/validate.py

docs:
	cd dbt && dbt docs generate && dbt docs serve

clean:
	rm -rf dbt/target dbt/logs
