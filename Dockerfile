FROM python:3.9-slim

WORKDIR /app

# Install dependencies first (better layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and required input files
COPY run.py .
COPY config.yaml .
COPY data.csv .

# Default command: no hard-coded paths in run.py itself,
# but the container's default invocation points at the bundled files.
CMD ["python", "run.py", "--input", "data.csv", "--config", "config.yaml", \
     "--output", "metrics.json", "--log-file", "run.log"]
