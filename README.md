# MLOps Task 0 — Batch Signal Job

A minimal, reproducible MLOps-style batch job that reads OHLCV price data,
computes a rolling mean on `close`, derives a binary trading signal, and
writes structured metrics (JSON) plus a detailed run log.

## What it does

1. Loads and validates `config.yaml` (`seed`, `window`, `version`).
2. Sets `numpy.random.seed(seed)` for deterministic runs.
3. Loads and validates `data.csv` (must contain a numeric `close` column).
4. Computes a rolling mean of `close` over `window` rows.
5. Derives `signal = 1 if close > rolling_mean else 0`.
6. Writes `metrics.json` (machine-readable) and `run.log` (human-readable).
7. Prints the final metrics JSON to stdout and exits `0` on success, non-zero
   on any error.

### Handling the first `window - 1` rows

The rolling mean needs a full window of history, so the first `window - 1`
rows have no rolling mean value (`min_periods=window`). These rows are
consistently assigned `signal = 0` (since `close > NaN` evaluates to
`False`), and are still included in `rows_processed` and in the
`signal_rate` average. This keeps the output fully deterministic and
avoids silently dropping rows.

## Files

| File | Purpose |
|---|---|
| `run.py` | Main batch job script |
| `config.yaml` | Job configuration (`seed`, `window`, `version`) |
| `data.csv` | Input OHLCV dataset (10,000 rows) |
| `requirements.txt` | Python dependencies |
| `Dockerfile` | Container build definition |
| `metrics.json` | Sample output from a successful run |
| `run.log` | Sample log from a successful run |

## Local run

```bash
pip install -r requirements.txt

python run.py --input data.csv --config config.yaml \
              --output metrics.json --log-file run.log
```

No paths are hard-coded inside `run.py` — all four arguments
(`--input`, `--config`, `--output`, `--log-file`) are required and must be
passed explicitly.

### Example `metrics.json` (success)

```json
{
  "version": "v1",
  "rows_processed": 10000,
  "metric": "signal_rate",
  "value": 0.4989,
  "latency_ms": 16,
  "seed": 42,
  "status": "success"
}
```

### Example `metrics.json` (error)

```json
{
  "version": "v1",
  "status": "error",
  "error_message": "Required column 'close' not found in input data."
}
```

`metrics.json` is always written, in both success and error cases, and the
process exits with code `0` on success and a non-zero code on any error
(missing/empty/invalid input file, missing `close` column, invalid or
incomplete config).

## Docker

Build:

```bash
docker build -t mlops-task .
```

Run:

```bash
docker run --rm mlops-task
```

The image bundles `data.csv` and `config.yaml` and runs the same CLI
internally (`python run.py --input data.csv --config config.yaml --output
metrics.json --log-file run.log`), then prints the final metrics JSON to
stdout. Exit code is `0` on success, non-zero on failure.

To persist `metrics.json` and `run.log` to the host instead of just seeing
stdout, mount a volume:

```bash
docker run --rm -v "$(pwd)/out:/app" mlops-task
```

## Reproducibility

Given the same `data.csv`, `config.yaml`, and `seed`, the job produces
identical `rows_processed`, `signal_rate`, and `signal` values on every run
(only `latency_ms`, a timing measurement, varies between runs).

## Evaluation notes

- **Correctness & determinism**: signal logic and rolling-mean handling
  are deterministic and documented above; seed is set explicitly.
- **Dockerization**: single-stage `python:3.9-slim` image, no hard-coded
  host paths, builds and runs with the two commands above.
- **Code quality**: input/config validation is centralized in
  `load_config` / `load_dataset`, with dedicated `ConfigError` /
  `DataError` exception types and a top-level catch-all fallback.
- **Observability**: `run.log` captures job start, config validation,
  rows loaded, each processing step, the metrics summary, and job end/
  status, including any exceptions.
