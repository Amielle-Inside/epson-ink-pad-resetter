# Dockerfile - Epson Ink Pad Resetter
# Dockerização feita com Hermes Agent e nvidia/nemotron-3.5-super-vl-120b-a12b
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    FLASK_HOST=0.0.0.0 \
    FLASK_PORT=5000 \
    FLASK_DEBUG=1

# Dependências de sistema exigidas pelo easysnmp (bind C da net-snmp)
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libsnmp-dev \
        libssl-dev \
        python3-dev \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py ./
COPY epson ./epson
COPY templates ./templates

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fsS http://127.0.0.1:5000/ || exit 1

CMD ["python", "app.py"]
