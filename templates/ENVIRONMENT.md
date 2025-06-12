# Environment Setup

This document outlines the dependencies, configurations, and setup required for the project environment.

## System Requirements

- **Node.js**: v20.x or later
- **Python**: 3.10 or later
- **Database**: PostgreSQL 14.x
- **Redis**: 6.x or later
- **OS**: macOS, Linux, or WSL2 on Windows

## Installation Guide

### 1. Clone the Repository

```bash
git clone [REPOSITORY_URL]
cd [PROJECT_DIRECTORY]
```

### 2. Install Dependencies

#### Backend

```bash
cd backend
pip install -r requirements.txt
```

#### Frontend

```bash
cd frontend
npm install
```

### 3. Environment Configuration

Create a `.env` file in the project root and backend directory:

```bash
# In project root
cp .env.example .env
# In backend directory
cp backend/.env.example backend/.env
```

Required environment variables:

```
# Database
DATABASE_URL=postgresql://[USER]:[PASSWORD]@[HOST]:[PORT]/[DATABASE]

# Authentication
JWT_SECRET=[RANDOM_SECRET]
JWT_EXPIRY=8h

# API Keys
S3_ACCESS_KEY_ID=[KEY]
S3_SECRET_ACCESS_KEY=[SECRET]
S3_REGION=[REGION]
S3_BUCKET=[BUCKET_NAME]

# Redis
REDIS_URL=redis://[HOST]:[PORT]
```

### 4. Database Setup

```bash
# Create database
createdb [DATABASE_NAME]

# Run migrations
cd backend
alembic upgrade head
```

### 5. Validation

Run the environment validation script:

```bash
./scripts/validate_environment.sh
```

## Cloud Services Setup

### AWS S3

- Region: [REGION]
- Bucket: [BUCKET_NAME]
- Access: [ACCESS_POLICY]

### Redis (Upstash)

- Instance Type: [INSTANCE_TYPE]
- Persistence: [PERSISTENCE_SETTINGS]

## Common Environment Issues

### Database Connection

If you see `Error: connect ECONNREFUSED [DATABASE_HOST]`:

1. Check if PostgreSQL is running: `pg_isready`
2. Verify connection string in `.env`
3. Check if database exists: `psql -l`

### Node Modules

If you see `Error: Cannot find module`:

1. Check if node_modules exists: `ls -la frontend/node_modules`
2. Try reinstalling: `cd frontend && rm -rf node_modules && npm install`

### Python Virtual Environment

It's recommended to use a virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## Development Servers

### Backend

```bash
cd backend
uvicorn main:app --reload
```

Server will run at: http://localhost:8000

### Frontend

```bash
cd frontend
npm run dev
```

Server will run at: http://localhost:3000

## Deployment Environment

- **Production**: [PRODUCTION_URL]
- **Staging**: [STAGING_URL]
- **CI/CD**: [CI_CD_SYSTEM]

## Environment Validation

The validation script checks:

1. Database connection
2. Redis connection
3. S3 access
4. Required environment variables
5. Node.js and Python versions

Run validation before starting development:

```bash
./scripts/validate_environment.sh
```

## Environment Refresh Protocol

When environment needs updating:

1. Pull latest changes: `git pull origin main`
2. Install dependencies: `pip install -r requirements.txt && cd frontend && npm install`
3. Run migrations: `cd backend && alembic upgrade head`
4. Validate environment: `./scripts/validate_environment.sh`