# Deployment Guide

This guide provides step-by-step instructions for deploying the monitoring app to production on monitoring.lucho-dev.xyz.

## Prerequisites

- A server with Docker and Docker Compose installed
- Domain name pointing to your server (monitoring.lucho-dev.xyz)
- SSH access to the server
- (Optional) Reverse proxy (nginx, Traefik, or Caddy)

## Deployment Steps

### 1. Prepare the Server

SSH into your server:
```bash
ssh user@your-server-ip
```

Install Docker and Docker Compose if not already installed:
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

### 2. Clone the Repository

```bash
cd /opt
sudo git clone https://github.com/louisbertrand22/Monitoring-app.git
cd Monitoring-app
```

### 3. Configure Environment Variables

Copy the example environment file and update it:
```bash
sudo cp .env.example .env
sudo nano .env
```

Update the following values:
```env
GF_SECURITY_ADMIN_PASSWORD=your-strong-password-here
GF_SERVER_ROOT_URL=https://monitoring.lucho-dev.xyz
```

### 4. Start the Monitoring Stack

```bash
sudo docker compose up -d
```

Verify all containers are running:
```bash
sudo docker compose ps
```

You should see three containers running:
- prometheus
- grafana
- blackbox-exporter

### 5. Configure Reverse Proxy (nginx example)

If using nginx, create a new configuration file:
```bash
sudo nano /etc/nginx/sites-available/monitoring.lucho-dev.xyz
```

Add the following configuration:
```nginx
server {
    listen 80;
    server_name monitoring.lucho-dev.xyz;

    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name monitoring.lucho-dev.xyz;

    # SSL configuration (adjust paths to your certificates)
    ssl_certificate /etc/letsencrypt/live/monitoring.lucho-dev.xyz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/monitoring.lucho-dev.xyz/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable the site and reload nginx:
```bash
sudo ln -s /etc/nginx/sites-available/monitoring.lucho-dev.xyz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6. Set Up SSL Certificate

If you don't have SSL certificates, use Let's Encrypt:
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d monitoring.lucho-dev.xyz
```

### 7. Access Grafana

Open your browser and navigate to:
```
https://monitoring.lucho-dev.xyz
```

Log in with:
- Username: `admin`
- Password: (the one you set in `.env`)

### 8. View the Dashboard

After logging in:
1. Go to "Dashboards" → "Browse"
2. Click on "Lucho Dev - Website Monitoring"
3. You should see the status of all monitored websites

## Alternative: Using Traefik

If you prefer using Traefik as a reverse proxy, add this to your `docker-compose.yml`:

```yaml
services:
  grafana:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.rule=Host(`monitoring.lucho-dev.xyz`)"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
```

## Maintenance

### View Logs
```bash
sudo docker compose logs -f
```

### Restart Services
```bash
sudo docker compose restart
```

### Update Images
```bash
sudo docker compose pull
sudo docker compose up -d
```

### Backup Data
```bash
sudo docker run --rm \
  -v monitoring-app_prometheus_data:/data \
  -v /opt/backups:/backup \
  alpine tar czf /backup/prometheus-$(date +%Y%m%d).tar.gz /data

sudo docker run --rm \
  -v monitoring-app_grafana_data:/data \
  -v /opt/backups:/backup \
  alpine tar czf /backup/grafana-$(date +%Y%m%d).tar.gz /data
```

## Troubleshooting

### Services Won't Start
Check logs:
```bash
sudo docker compose logs
```

### Can't Access Grafana
1. Check if the container is running: `sudo docker compose ps`
2. Check if port 3000 is accessible: `curl http://localhost:3000`
3. Check reverse proxy configuration
4. Check firewall rules

### No Data in Grafana
1. Check Prometheus targets: http://monitoring.lucho-dev.xyz:9090/targets
2. Verify Blackbox exporter is running
3. Check Prometheus logs: `sudo docker compose logs prometheus`

### Websites Showing as DOWN
1. Verify the websites are actually accessible
2. Check from the server: `curl -I https://portfolio.lucho-dev.xyz`
3. Review Blackbox exporter logs: `sudo docker compose logs blackbox-exporter`

## Security Recommendations

1. **Change default password**: Always change the default Grafana password
2. **Use strong passwords**: Generate strong passwords for admin accounts
3. **Enable HTTPS**: Always use SSL/TLS in production
4. **Firewall**: Only expose necessary ports (80, 443)
5. **Regular updates**: Keep Docker images updated
6. **Backup regularly**: Schedule regular backups of data volumes
7. **Monitor the monitor**: Set up alerts in Grafana for the monitoring stack itself

## Next Steps

After deployment:
1. Change the default admin password
2. Set up email notifications in Grafana
3. Create alert rules for website downtime
4. Add more monitoring metrics as needed
5. Set up retention policies for Prometheus data
