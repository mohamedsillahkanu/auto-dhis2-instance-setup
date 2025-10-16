# DHIS2 Local Installation Guide

## Quick Start with Docker (Recommended)

### Prerequisites
- Docker Desktop installed ([Download here](https://www.docker.com/products/docker-desktop))
- 4GB RAM minimum (8GB recommended)
- 10GB free disk space

### Option 1: Using Docker Compose (Easiest)

1. **Create a project folder:**
```bash
mkdir dhis2-local
cd dhis2-local
```

2. **Create `docker-compose.yml` file:**
```yaml
version: '3'

services:
  database:
    image: postgis/postgis:15-3.3-alpine
    environment:
      POSTGRES_USER: dhis
      POSTGRES_PASSWORD: dhis
      POSTGRES_DB: dhis2
    volumes:
      - dhis2-db-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dhis"]
      interval: 10s
      timeout: 5s
      retries: 5

  dhis2:
    image: dhis2/core:2.40.5
    depends_on:
      database:
        condition: service_healthy
    environment:
      DHIS2_DATABASE_HOST: database
      DHIS2_DATABASE_NAME: dhis2
      DHIS2_DATABASE_USERNAME: dhis
      DHIS2_DATABASE_PASSWORD: dhis
    ports:
      - "8080:8080"
    volumes:
      - dhis2-data:/DHIS2_home

volumes:
  dhis2-db-data:
  dhis2-data:
```

3. **Start DHIS2:**
```bash
docker-compose up -d
```

4. **Wait for startup (3-5 minutes):**
```bash
docker-compose logs -f dhis2
```
Look for: `Server startup in [XXXX] milliseconds`

5. **Access DHIS2:**
- URL: http://localhost:8080
- Username: `admin`
- Password: `district`

### Option 2: Single Docker Command

```bash
# Start PostgreSQL with PostGIS
docker run -d \
  --name dhis2-db \
  -e POSTGRES_USER=dhis \
  -e POSTGRES_PASSWORD=dhis \
  -e POSTGRES_DB=dhis2 \
  -v dhis2-db-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgis/postgis:15-3.3-alpine

# Wait 30 seconds for database to initialize

# Start DHIS2
docker run -d \
  --name dhis2-app \
  --link dhis2-db:database \
  -e DHIS2_DATABASE_HOST=database \
  -e DHIS2_DATABASE_NAME=dhis2 \
  -e DHIS2_DATABASE_USERNAME=dhis \
  -e DHIS2_DATABASE_PASSWORD=dhis \
  -p 8080:8080 \
  -v dhis2-data:/DHIS2_home \
  dhis2/core:2.40.5
```

## Useful Docker Commands

```bash
# Check status
docker-compose ps

# View logs
docker-compose logs -f dhis2

# Stop services
docker-compose stop

# Start services
docker-compose start

# Remove everything (clean slate)
docker-compose down -v

# Restart DHIS2 only
docker-compose restart dhis2
```

## Manual Installation (Without Docker)

### Prerequisites
- Java JDK 17 ([Download](https://adoptium.net/))
- PostgreSQL 15 with PostGIS ([Download](https://www.postgresql.org/download/))
- Tomcat 9 ([Download](https://tomcat.apache.org/download-90.cgi))

### Step 1: Install and Configure PostgreSQL

1. **Install PostgreSQL 15 and PostGIS**

2. **Create database:**
```bash
# Login to PostgreSQL
psql -U postgres

# Create user and database
CREATE USER dhis WITH PASSWORD 'dhis';
CREATE DATABASE dhis2 WITH OWNER dhis;

# Connect to dhis2 database
\c dhis2

# Enable PostGIS extension
CREATE EXTENSION postgis;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE dhis2 TO dhis;
GRANT ALL ON SCHEMA public TO dhis;

# Exit
\q
```

### Step 2: Configure DHIS2

1. **Create DHIS2 home directory:**
```bash
# Linux/Mac
mkdir -p ~/DHIS2_home

# Windows
mkdir C:\DHIS2_home
```

2. **Create configuration file:**

Linux/Mac: `~/DHIS2_home/dhis.conf`
Windows: `C:\DHIS2_home\dhis.conf`

```properties
# Database connection
connection.dialect = org.hibernate.dialect.PostgreSQLDialect
connection.driver_class = org.postgresql.Driver
connection.url = jdbc:postgresql://localhost:5432/dhis2
connection.username = dhis
connection.password = dhis

# Server configuration
server.base.url = http://localhost:8080

# Encryption (generate random 24-character string)
encryption.password = xxxxxxxxxxxxxxxxxxxx
```

### Step 3: Deploy DHIS2

1. **Download DHIS2 WAR file:**
   - Visit: https://github.com/dhis2/dhis2-releases/releases
   - Download: `dhis.war` for version 2.40.5

2. **Deploy to Tomcat:**
```bash
# Copy to Tomcat webapps
cp dhis.war /path/to/tomcat/webapps/

# Set DHIS2_HOME environment variable
# Linux/Mac
export DHIS2_HOME=~/DHIS2_home

# Windows
setx DHIS2_HOME "C:\DHIS2_home"
```

3. **Start Tomcat:**
```bash
# Linux/Mac
/path/to/tomcat/bin/startup.sh

# Windows
C:\path\to\tomcat\bin\startup.bat
```

4. **Access DHIS2:**
   - URL: http://localhost:8080/dhis
   - Username: `admin`
   - Password: `district`

## Troubleshooting

### Docker Issues

**Container won't start:**
```bash
# Check logs
docker-compose logs dhis2

# Common fix: Remove and recreate
docker-compose down -v
docker-compose up -d
```

**Port already in use:**
```bash
# Change ports in docker-compose.yml
ports:
  - "8081:8080"  # Use port 8081 instead
```

**Database connection failed:**
```bash
# Ensure database is healthy
docker-compose ps
docker-compose logs database
```

### Manual Installation Issues

**Database connection error:**
- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `dhis.conf`
- Check firewall allows port 5432

**Out of memory:**
- Increase Tomcat memory in `setenv.sh`:
```bash
export CATALINA_OPTS="-Xms1024m -Xmx2048m"
```

**Slow startup:**
- First startup takes 5-10 minutes
- Check logs: `tail -f tomcat/logs/catalina.out`

## Next Steps After Installation

1. **Change default password:**
   - Login with admin/district
   - Go to Profile → Edit user settings → Change password

2. **Import demo data (optional):**
   - Go to Import-Export app
   - Import sample datasets for testing

3. **Configure organization units:**
   - Set up your hierarchy (country → regions → facilities)

4. **Create users and roles:**
   - Define different access levels
   - Create user accounts

5. **Set up data elements:**
   - Define what data you'll collect
   - Create datasets and forms

## System Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4GB
- Storage: 10GB
- OS: Windows 10+, macOS 10.15+, Linux

**Recommended:**
- CPU: 4 cores
- RAM: 8GB
- Storage: 20GB SSD
- OS: Ubuntu 20.04+ or similar

## Resources

- [DHIS2 Documentation](https://docs.dhis2.org)
- [DHIS2 Community](https://community.dhis2.org)
- [GitHub Releases](https://github.com/dhis2/dhis2-releases)
- [Docker Hub](https://hub.docker.com/r/dhis2/core)

## Quick Reference

| Component | Default Value |
|-----------|--------------|
| URL | http://localhost:8080 |
| Username | admin |
| Password | district |
| Database | dhis2 |
| DB User | dhis |
| DB Password | dhis |
| PostgreSQL Port | 5432 |
| Tomcat Port | 8080 |
