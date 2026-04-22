# Prometheus SwitchBot Exporter

A Prometheus exporter for SwitchBot smart plugs that exposes device metrics (power, voltage, weight, electricity usage) in Prometheus format.

## Features

- Exposes SwitchBot device status as Prometheus metrics
- Returns: power state, voltage, weight, daily electricity usage, electric current
- Provides probe duration and API status metrics
- Docker-ready with Nix Flakes

## Requirements

- Python 3 with fastapi, jinja2, requests, uvicorn
- SwitchBot API token and secret (from SwitchBot app V6.14+)

## Configuration

Set the following environment variables:

| Variable | Description |
|---------|-------------|
| `SWITCHBOT_TOKEN` | Open token from SwitchBot app V6.14+ |
| `SWITCHBOT_SECRET` | Secret key from SwitchBot app V6.14+ |

## Usage

### Running Directly

```bash
export SWITCHBOT_TOKEN="your_open_token"
export SWITCHBOT_SECRET="your_secret_key"
uvicorn src.main:app --host 0.0.0.0 --port 8000
```

### Running with Docker

```bash
docker pull ghcr.io/pineapplehunter/prometheus-switchbot:latest
docker run -p 8000:8000 \
  -e SWITCHBOT_TOKEN="your_token" \
  -e SWITCHBOT_SECRET="your_secret" \
  ghcr.io/pineapplehunter/prometheus-switchbot:latest
```

### Running with Docker Compose

```yaml
services:
  switchbot-exporter:
    image: ghcr.io/pineapplehunter/prometheus-switchbot:latest
    ports:
      - "8000:8000"
    environment:
      - SWITCHBOT_TOKEN=your_token
      - SWITCHBOT_SECRET=your_secret
```

### Running with Nix Flakes

```bash
nix run .
```

## Endpoints

- `GET /` - Health check
- `GET /metrics?target=<device_id>` - Returns Prometheus metrics for specified device

## Metrics

| Metric | Description |
|--------|-------------|
| `probe_duration_seconds` | Time taken to complete the probe |
| `api_request_status_code` | HTTP status code from SwitchBot API |
| `api_status_code` | SwitchBot API status code |
| `api_body_power` | Power state (on/off) |
| `api_body_voltage` | Current voltage |
| `api_body_weight` | Device weight |
| `api_body_electricity_of_day` | Daily electricity usage |
| `api_body_electric_current` | Electric current |

## Prometheus Configuration

```yaml
- job_name: switchbot
  scrape_interval: 60s
  scrape_timeout: 15s
  static_configs:
    - targets:
        - DEVICE_ID_1
        - DEVICE_ID_2
  relabel_configs:
    - source_labels: [__address__]
      target_label: __param_target
    - source_labels: [__param_target]
      target_label: instance
    - target_label: __address__
      replacement: prometheus-switchbot:8000
```

Replace `DEVICE_ID_1`, `DEVICE_ID_2` etc. with your SwitchBot device IDs.