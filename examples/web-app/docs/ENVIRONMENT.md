# Environment Setup

This document outlines the dependencies, configurations, and setup required for the TaskMaster project environment.

## System Requirements

- **Node.js**: v18.x or later
- **PostgreSQL**: 14.x or later
- **Redis**: 6.x or later
- **OS**: macOS, Linux, or WSL2 on Windows

## Installation Guide

### 1. Clone the Repository

```bash
git clone https://github.com/organization/taskmaster.git
cd taskmaster
```

### 2. Install Dependencies

#### Backend

```bash
cd backend
npm install
```

#### Frontend

```bash
cd frontend
npm install
```

### 3. Environment Configuration

Create `.env` files in both backend and frontend directories:

```bash
# In backend directory
cp .env.example .env

# In frontend directory
cp .env.example .env
```

Required backend environment variables:

```
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/taskmaster_dev

# Authentication
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRY=8h

# OpenAI API for Task Prioritization
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-3.5-turbo

# Redis for Caching
REDIS_URL=redis://localhost:6379

# Email Notifications
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your_smtp_username
SMTP_PASS=your_smtp_password
```

Required frontend environment variables:

```
# API URL
REACT_APP_API_URL=http://localhost:4000/api

# Feature Flags
REACT_APP_ENABLE_AI_FEATURES=true
REACT_APP_ENABLE_TEAM_FEATURES=true
```

### 4. Database Setup

```bash
# Create database
createdb taskmaster_dev

# Run migrations
cd backend
npm run migrate

# Seed initial data (optional)
npm run seed
```

### 5. Start Development Servers

#### Backend

```bash
cd backend
npm run dev
```

The backend server will run at http://localhost:4000

#### Frontend

```bash
cd frontend
npm start
```

The frontend dev server will run at http://localhost:3000

## Development Database

### Connection Details

- **Host**: localhost
- **Port**: 5432
- **Database**: taskmaster_dev
- **Username**: postgres (or your local PostgreSQL username)
- **Password**: password (or your local PostgreSQL password)

### Required Extensions

The application requires the following PostgreSQL extensions:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
```

These are automatically enabled during migrations.

## External Services Configuration

### OpenAI API

The TaskMaster application uses OpenAI for the AI prioritization feature:

1. Get an API key from [OpenAI](https://platform.openai.com/account/api-keys)
2. Add it to your backend `.env` file as `OPENAI_API_KEY`

### Email Service

For notification emails:

1. Set up an SMTP provider (SendGrid, Mailgun, etc.)
2. Configure the SMTP settings in your backend `.env` file

## Testing

### Running Tests

#### Backend Tests

```bash
cd backend
npm test           # Run all tests
npm run test:unit  # Run unit tests only
npm run test:integration # Run integration tests only
```

#### Frontend Tests

```bash
cd frontend
npm test           # Run all tests
npm run test:coverage # Run tests with coverage report
```

### Testing Database

The tests use a separate database:

```bash
createdb taskmaster_test
```

Test environment variables are configured in `.env.test`.

## Docker Setup (Optional)

TaskMaster can also be run using Docker:

```bash
# Start all services
docker-compose up

# Or start individual services
docker-compose up postgres redis
```

## Common Environment Issues

### Database Connection

If you see `Error: connect ECONNREFUSED 127.0.0.1:5432`:

1. Check if PostgreSQL is running: `pg_isready`
2. Verify connection string in `.env`
3. Check if database exists: `psql -l | grep taskmaster`

### Node Modules

If you see `Error: Cannot find module`:

1. Make sure you've run `npm install` in both directories
2. Try deleting `node_modules` and reinstalling:
   ```bash
   rm -rf node_modules
   npm install
   ```

### Environment Variables

If you see `Error: Environment variable X not set`:

1. Check that you've copied `.env.example` to `.env`
2. Verify all required variables are set
3. Make sure you're starting the server from the correct directory

## Production Environment

For production deployment, additional settings are required:

- **NODE_ENV**: Set to `production`
- **CORS_ORIGIN**: Set to your frontend domain
- **DATABASE_URL**: Use connection pooling configuration
- **REDIS_URL**: Use TLS-enabled connection string
- **LOG_LEVEL**: Set to `info` or `warn`

## Continuous Integration

The project uses GitHub Actions for CI:

- `.github/workflows/backend.yml`: Backend tests and linting
- `.github/workflows/frontend.yml`: Frontend tests and builds

## Monitoring and Logging

In development:
- Logs are output to the console
- API requests are logged with morgan

In production:
- Logs are formatted as JSON
- Application monitoring is done with New Relic
- Error tracking is done with Sentry

## Updating Dependencies

Periodically update dependencies:

```bash
# Check for outdated dependencies
npm outdated

# Update dependencies
npm update

# For major version updates, use
npm install package-name@latest
```

Always run tests after updating dependencies.