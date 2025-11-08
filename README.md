# Monitoring App

A comprehensive monitoring solution using Grafana and Prometheus to monitor multiple web applications.

## Monitored Applications

This monitoring stack tracks the following applications:
- 🎨 **Portfolio**: https://portfolio.lucho-dev.xyz
- 📚 **Flashcards**: https://flashcards.lucho-dev.xyz
- 🏎️ **F1 Dashboard**: https://f1dashboard.lucho-dev.xyz
- 🚀 **My App**: https://my-app.lucho-dev.xyz
- **ChickenStude** https://chicken-stude.lucho-dev.xyz/

## Stack Components

- **Prometheus**: Metrics collection and time-series database
- **Grafana**: Visualization and dashboard platform
- **Blackbox Exporter**: HTTP/HTTPS probe monitoring

## Features

- ✅ Website availability monitoring (HTTP probes)
- 📊 Response time tracking
- 🔐 SSL certificate expiry monitoring
- 📈 HTTP status code tracking
- 🎯 Pre-configured Grafana dashboard
- 🔄 Automatic data source provisioning

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/louisbertrand22/Monitoring-app.git
   cd Monitoring-app
   ```

2. **Start the monitoring stack**
   ```bash
   docker-compose up -d
   ```

3. **Access the services**
   - **Grafana**: http://localhost:3000
     - Default credentials: `admin` / `admin`
   - **Prometheus**: http://localhost:9090
   - **Blackbox Exporter**: http://localhost:9115

4. **View the dashboard**
   - Log into Grafana
   - Navigate to "Dashboards" → "Lucho Dev - Website Monitoring"

## Configuration

### Prometheus Configuration

The Prometheus configuration (`prometheus/prometheus.yml`) includes:
- Self-monitoring of Prometheus and Grafana
- HTTP probes for all monitored websites
- SSL certificate monitoring
- 30-second scrape interval

### Grafana Configuration

Grafana is pre-configured with:
- Prometheus as the default data source
- Automatic dashboard provisioning
- Website monitoring dashboard with:
  - Status gauges for each application
  - Response time graphs
  - HTTP status code tracking
  - SSL certificate expiry warnings

### Blackbox Exporter Configuration

The Blackbox exporter (`blackbox/blackbox.yml`) is configured to:
- Probe HTTP/HTTPS endpoints
- Accept various HTTP status codes (200, 301, 302, etc.)
- Support both HTTP/1.1 and HTTP/2.0
- Validate SSL certificates

## Dashboard Features

The pre-configured dashboard includes:

1. **Status Gauges**: Real-time UP/DOWN status for each application
2. **Response Time Graph**: Track response times over time
3. **HTTP Status Codes**: Monitor status code changes
4. **SSL Certificate Expiry**: Days remaining before certificate expiration
   - 🟢 Green: > 30 days
   - 🟡 Yellow: 7-30 days
   - 🔴 Red: < 7 days

## Deployment to Production

### Deploy to monitoring.lucho-dev.xyz

1. **Update environment variables** (optional)
   Create a `.env` file:
   ```env
   GF_SECURITY_ADMIN_PASSWORD=your-secure-password
   GF_SERVER_ROOT_URL=https://monitoring.lucho-dev.xyz
   ```

2. **Update docker-compose.yml** for production
   ```yaml
   grafana:
     environment:
       - GF_SERVER_ROOT_URL=https://monitoring.lucho-dev.xyz
       - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
   ```

3. **Configure reverse proxy** (nginx example)
   ```nginx
   server {
       listen 80;
       server_name monitoring.lucho-dev.xyz;
       
       location / {
           proxy_pass http://localhost:3000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

4. **Start the stack**
   ```bash
   docker-compose up -d
   ```

## Management Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f grafana
docker-compose logs -f prometheus
```

### Restart services
```bash
docker-compose restart
```

### Stop services
```bash
docker-compose down
```

### Update services
```bash
docker-compose pull
docker-compose up -d
```

## Customization

### Add New Websites to Monitor

1. Edit `prometheus/prometheus.yml`
2. Add the new URL to the `targets` list under `blackbox-http` job
3. Restart Prometheus: `docker-compose restart prometheus`

### Modify Dashboard

- Log into Grafana
- Navigate to the dashboard
- Click the gear icon ⚙️ to edit
- Make your changes
- Save the dashboard

## Troubleshooting

### Grafana shows "No Data"
- Check if Prometheus is running: `docker-compose ps`
- Verify Prometheus targets: http://localhost:9090/targets
- Check container logs: `docker-compose logs prometheus`

### Website shows as DOWN but it's UP
- Verify the website is accessible from the container
- Check Blackbox exporter logs: `docker-compose logs blackbox-exporter`
- Test manually: http://localhost:9115/probe?module=http_2xx&target=https://portfolio.lucho-dev.xyz

### SSL Certificate monitoring not working
- Ensure the websites use HTTPS
- Check Blackbox exporter configuration
- Verify probe metrics: http://localhost:9090/graph?g0.expr=probe_ssl_earliest_cert_expiry

## Data Persistence

Data is persisted in Docker volumes:
- `prometheus_data`: Prometheus time-series data
- `grafana_data`: Grafana dashboards and settings

To backup data:
```bash
docker run --rm -v monitoring-app_prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-backup.tar.gz /data
docker run --rm -v monitoring-app_grafana_data:/data -v $(pwd):/backup alpine tar czf /backup/grafana-backup.tar.gz /data
```

## Security Considerations

- Change default Grafana admin password
- Use environment variables for sensitive data
- Enable HTTPS with SSL certificates in production
- Restrict network access to monitoring ports
- Regularly update Docker images

## License

MIT

## Support

For issues and questions, please open an issue on GitHub.
