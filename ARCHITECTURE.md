# Monitoring Architecture

This document explains the architecture and metrics of the monitoring solution.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitored Websites                        │
├─────────────────────────────────────────────────────────────┤
│  • portfolio.lucho-dev.xyz                                   │
│  • flashcards.lucho-dev.xyz                                  │
│  • f1dashboard.lucho-dev.xyz                                 │
│  • my-app.lucho-dev.xyz                                      │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    │ HTTP Probes (every 30s)
                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Blackbox Exporter                               │
│  • HTTP/HTTPS probing                                        │
│  • SSL certificate validation                                │
│  • Response time measurement                                 │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    │ Metrics Endpoint
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                   Prometheus                                 │
│  • Metrics collection (scraping)                             │
│  • Time-series database                                      │
│  • Alerting rules engine                                     │
│  • Data retention management                                 │
└───────────────────┬─────────────────────────────────────────┘
                    │
                    │ PromQL Queries
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     Grafana                                  │
│  • Visualization dashboards                                  │
│  • Alerting and notifications                                │
│  • User interface                                            │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Blackbox Exporter

**Purpose**: Probes external endpoints and exposes metrics about their availability and performance.

**Configuration**:
- Module: `http_2xx`
- Accepted status codes: 200, 201, 202, 301, 302, 304
- Timeout: 5 seconds per probe
- SSL verification enabled

**Metrics Collected**:
- `probe_success`: Whether the probe succeeded (0=down, 1=up)
- `probe_http_duration_seconds`: Total HTTP request duration
- `probe_http_status_code`: HTTP status code returned
- `probe_ssl_earliest_cert_expiry`: SSL certificate expiration timestamp
- `probe_dns_lookup_time_seconds`: DNS resolution time
- `probe_http_ssl`: Whether HTTPS was used

### 2. Prometheus

**Purpose**: Collects, stores, and provides query interface for metrics.

**Configuration**:
- Scrape interval: 30 seconds
- Evaluation interval: 30 seconds
- Data retention: 15 days (default)
- Storage path: `/prometheus` (Docker volume)

**Jobs Configured**:
1. **prometheus**: Self-monitoring
2. **grafana**: Grafana monitoring
3. **blackbox-http**: Website HTTP probes
4. **blackbox-https-cert**: SSL certificate monitoring

**Key Features**:
- Time-series database
- PromQL query language
- Label-based data model
- Built-in alerting

### 3. Grafana

**Purpose**: Visualization and alerting platform.

**Configuration**:
- Port: 3000
- Default credentials: admin/admin (change in production!)
- Data source: Prometheus (auto-provisioned)
- Dashboards: Auto-provisioned from JSON

**Features**:
- Pre-configured dashboard
- Prometheus data source
- Alert support (can be configured)
- User management

## Metrics Collected

### Availability Metrics

| Metric | Description | Type | Labels |
|--------|-------------|------|--------|
| `probe_success` | Probe success status (0/1) | Gauge | instance, job |
| `probe_http_status_code` | HTTP response status code | Gauge | instance, job |

### Performance Metrics

| Metric | Description | Type | Labels |
|--------|-------------|------|--------|
| `probe_http_duration_seconds` | Total HTTP request duration | Gauge | instance, job, phase |
| `probe_dns_lookup_time_seconds` | DNS lookup time | Gauge | instance, job |
| `probe_http_ssl` | Whether connection used SSL | Gauge | instance, job |

### SSL Certificate Metrics

| Metric | Description | Type | Labels |
|--------|-------------|------|--------|
| `probe_ssl_earliest_cert_expiry` | Certificate expiry timestamp | Gauge | instance, job |

## Dashboard Panels

### 1. Status Gauges
- **Purpose**: Quick visual status of each website
- **Query**: `probe_success{instance="https://..."}`
- **Type**: Gauge
- **Mapping**: 0=DOWN (red), 1=UP (green)

### 2. HTTP Response Time
- **Purpose**: Track website performance over time
- **Query**: `probe_http_duration_seconds{job="blackbox-http"}`
- **Type**: Time series graph
- **Unit**: Seconds

### 3. HTTP Status Codes
- **Purpose**: Monitor HTTP responses
- **Query**: `probe_http_status_code{job="blackbox-http"}`
- **Type**: Time series graph
- **Alerts**: Can trigger on 4xx, 5xx codes

### 4. SSL Certificate Expiry
- **Purpose**: Prevent certificate expiration issues
- **Query**: `(probe_ssl_earliest_cert_expiry - time()) / 86400`
- **Type**: Bar gauge
- **Unit**: Days
- **Thresholds**: 
  - Green: > 30 days
  - Yellow: 7-30 days
  - Red: < 7 days

## Query Examples

### Check if a website is up
```promql
probe_success{instance="https://portfolio.lucho-dev.xyz"}
```

### Average response time over 5 minutes
```promql
avg_over_time(probe_http_duration_seconds{instance="https://portfolio.lucho-dev.xyz"}[5m])
```

### Days until SSL certificate expires
```promql
(probe_ssl_earliest_cert_expiry{instance="https://portfolio.lucho-dev.xyz"} - time()) / 86400
```

### Websites currently down
```promql
probe_success == 0
```

### Maximum response time in last hour
```promql
max_over_time(probe_http_duration_seconds{job="blackbox-http"}[1h])
```

## Alert Rules (Future Enhancement)

You can configure alerts in Prometheus for:

1. **Website Down**
   ```yaml
   - alert: WebsiteDown
     expr: probe_success == 0
     for: 2m
     annotations:
       summary: "Website {{ $labels.instance }} is down"
   ```

2. **High Response Time**
   ```yaml
   - alert: HighResponseTime
     expr: probe_http_duration_seconds > 3
     for: 5m
     annotations:
       summary: "Website {{ $labels.instance }} is slow"
   ```

3. **SSL Certificate Expiring**
   ```yaml
   - alert: SSLCertificateExpiring
     expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
     annotations:
       summary: "SSL certificate for {{ $labels.instance }} expires in less than 30 days"
   ```

## Data Retention

### Prometheus
- **Default**: 15 days
- **Configuration**: Add `--storage.tsdb.retention.time=30d` to command args
- **Size-based**: Add `--storage.tsdb.retention.size=10GB`

### Grafana
- Uses Prometheus as data source (no local storage)
- Dashboard configurations stored in volume

## Scaling Considerations

### Current Setup (Small Scale)
- 4 websites
- 30-second scrape interval
- Suitable for: Single server, low traffic

### To Monitor More Websites
1. Add targets to `prometheus/prometheus.yml`
2. Restart Prometheus: `docker compose restart prometheus`
3. Dashboard auto-updates with new targets

### For Large Scale (100+ websites)
Consider:
- Increase scrape interval to reduce load
- Use Prometheus federation
- Implement Thanos for long-term storage
- Use Grafana Cloud for centralized dashboards

## Security

### Current Security Features
- Configurable admin password
- Network isolation (Docker network)
- No exposed Prometheus port (can be accessed via localhost only)

### Recommended Enhancements
1. Enable HTTPS for Grafana
2. Configure authentication (LDAP, OAuth)
3. Set up firewall rules
4. Regular security updates
5. Use secrets management for passwords

## Backup and Recovery

### What to Backup
- Prometheus data: `/prometheus` volume
- Grafana dashboards: `/var/lib/grafana` volume

### Backup Commands
```bash
# Automated via Makefile
make backup

# Manual
docker run --rm -v monitoring-app_prometheus_data:/data \
  -v $(pwd)/backups:/backup alpine \
  tar czf /backup/prometheus-backup.tar.gz /data
```

### Recovery
```bash
# Stop services
docker compose down

# Restore data
docker run --rm -v monitoring-app_prometheus_data:/data \
  -v $(pwd)/backups:/backup alpine \
  tar xzf /backup/prometheus-backup.tar.gz -C /

# Start services
docker compose up -d
```

## Troubleshooting

### High Memory Usage
- Prometheus stores data in memory
- Reduce retention time
- Increase scrape interval
- Add memory limits in docker-compose.yml

### Missing Data
- Check Prometheus targets: http://localhost:9090/targets
- Verify network connectivity
- Check container logs

### Slow Dashboards
- Reduce query time range
- Use recording rules for complex queries
- Optimize panel queries

## Next Steps

Potential enhancements:
1. Add alerting rules
2. Configure email notifications
3. Add more metrics (application-specific)
4. Set up alert manager
5. Implement log aggregation (ELK/Loki)
6. Add uptime percentage calculations
7. Create SLA dashboards
