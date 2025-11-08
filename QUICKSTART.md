# Quick Start Guide

Get your monitoring stack up and running in 5 minutes!

## Prerequisites

✅ Docker installed  
✅ Docker Compose installed  
✅ 2GB free RAM  
✅ Internet connection

## Installation

### Step 1: Clone the Repository
```bash
git clone https://github.com/louisbertrand22/Monitoring-app.git
cd Monitoring-app
```

### Step 2: Validate Configuration (Optional)
```bash
./validate.sh
```

### Step 3: Start the Services
```bash
docker compose up -d
```

Wait 30-60 seconds for services to initialize.

### Step 4: Access Grafana
Open your browser to: **http://localhost:3000**

Login credentials:
- **Username**: `admin`
- **Password**: `admin`

⚠️ You'll be prompted to change the password on first login.

### Step 5: View the Dashboard
1. Click on "Dashboards" (☰ menu → Dashboards)
2. Click "Browse"
3. Select **"Lucho Dev - Website Monitoring"**

You should see:
- ✅ Status gauges for all 4 websites
- 📊 Response time graphs
- 📈 HTTP status code monitoring
- 🔒 SSL certificate expiry tracking

## What You're Monitoring

- **Portfolio**: https://portfolio.lucho-dev.xyz
- **Flashcards**: https://flashcards.lucho-dev.xyz
- **F1 Dashboard**: https://f1dashboard.lucho-dev.xyz
- **My App**: https://my-app.lucho-dev.xyz

## Common Commands

### Using Docker Compose

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Check status
docker compose ps
```

### Using Makefile (if available)

```bash
# Start
make up

# Stop
make down

# View logs
make logs

# Check status
make status

# Backup data
make backup
```

## Accessing Services Directly

- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Blackbox Exporter**: http://localhost:9115

## Verifying Everything Works

### 1. Check Container Status
```bash
docker compose ps
```

All services should show "Up" status.

### 2. Check Prometheus Targets
Visit: http://localhost:9090/targets

All targets should show **"UP"** in green.

### 3. Check Dashboard
Visit Grafana dashboard - all gauges should be green (UP).

## Customization

### Add More Websites to Monitor

1. Edit `prometheus/prometheus.yml`
2. Add your URL to the `targets` list:
   ```yaml
   - targets:
       - https://portfolio.lucho-dev.xyz
       - https://flashcards.lucho-dev.xyz
       - https://f1dashboard.lucho-dev.xyz
       - https://my-app.lucho-dev.xyz
       - https://your-new-site.com  # Add here
   ```
3. Restart Prometheus:
   ```bash
   docker compose restart prometheus
   ```

### Change Admin Password

1. Log into Grafana
2. Click on your profile (bottom left)
3. Select "Change Password"
4. Enter new password

Or set via environment variable in `.env` file:
```env
GF_SECURITY_ADMIN_PASSWORD=your-secure-password
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Check if ports are available
sudo netstat -tulpn | grep -E ':(3000|9090|9115)'
```

### Can't access Grafana
```bash
# Check if container is running
docker compose ps grafana

# Check logs
docker compose logs grafana

# Try accessing via curl
curl http://localhost:3000
```

### No data in dashboard
```bash
# Check Prometheus targets
curl http://localhost:9090/targets

# Check Prometheus is scraping
docker compose logs prometheus | grep "scrape"

# Check Blackbox exporter
docker compose logs blackbox-exporter
```

### Website shows as DOWN but it's UP
```bash
# Test from Blackbox exporter
curl "http://localhost:9115/probe?module=http_2xx&target=https://portfolio.lucho-dev.xyz"

# Check network connectivity from container
docker compose exec prometheus wget -O- https://portfolio.lucho-dev.xyz
```

## Production Deployment

For production deployment on monitoring.lucho-dev.xyz:

1. **Read the deployment guide**: See [DEPLOYMENT.md](DEPLOYMENT.md)
2. **Set secure passwords**: Update `.env` file
3. **Configure HTTPS**: Set up reverse proxy with SSL
4. **Restrict access**: Configure firewall rules
5. **Set up backups**: Schedule regular backups

## Next Steps

After getting started:

- ✅ Change default admin password
- 📧 Configure email notifications (optional)
- 🚨 Set up alert rules (optional)
- 🔧 Customize dashboard to your needs
- 📚 Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
- 🚀 Follow [DEPLOYMENT.md](DEPLOYMENT.md) for production setup

## Getting Help

- 📖 Read the [README.md](README.md)
- 🏗️ Check [ARCHITECTURE.md](ARCHITECTURE.md)
- 🚀 See [DEPLOYMENT.md](DEPLOYMENT.md)
- 🐛 Open an issue on GitHub

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Blackbox Exporter](https://github.com/prometheus/blackbox_exporter)

---

**Happy Monitoring! 📊**
