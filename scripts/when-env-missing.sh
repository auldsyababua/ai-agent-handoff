#!/bin/sh
# when-env-missing.sh - Fix missing environment variable issues
# Usage: ./scripts/when-env-missing.sh [var-name]
set -e

# Colors (if terminal supports it)
if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
else
    GREEN=""
    RED=""
    YELLOW=""
    BLUE=""
    RESET=""
fi

printf '%s\n' "${BLUE}=== ENVIRONMENT VARIABLE FIXER ===${RESET}"
echo ""

# Create .env from example if missing
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    printf '%s\n' "${YELLOW}📋 Creating .env from .env.example...${RESET}"
    cp .env.example .env
    printf '%s\n' "${GREEN}✅ Created .env file${RESET}"
    printf '%s\n' "${YELLOW}⚠️  Please update the values in .env${RESET}"
    echo ""
fi

# Check if .env exists at all
if [ ! -f ".env" ] && [ ! -f ".env.example" ]; then
    printf '%s\n' "${YELLOW}📝 No .env or .env.example found. Creating basic .env...${RESET}"
    
    # Create a basic .env based on common patterns
    cat > .env << 'EOF'
# Database
DATABASE_URL=postgresql://localhost:5432/myapp_dev
TEST_DATABASE_URL=postgresql://localhost:5432/myapp_test

# Redis
REDIS_URL=redis://localhost:6379

# Application
NODE_ENV=development
PORT=3000
HOST=localhost

# Authentication
JWT_SECRET=your-secret-key-here
SESSION_SECRET=your-session-secret-here

# API Keys (get from your services)
# OPENAI_API_KEY=
# STRIPE_API_KEY=
# SENDGRID_API_KEY=
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=

# Feature Flags
DEBUG=true
EOF
    
    printf '%s\n' "${GREEN}✅ Created basic .env file${RESET}"
    printf '%s\n' "${YELLOW}⚠️  Update with your actual values!${RESET}"
fi

# Function to check for missing variables
check_missing_vars() {
    printf '%s\n' "${BLUE}Checking for missing environment variables...${RESET}"
    echo ""
    
    local missing_count=0
    
    # Common required variables by framework
    local required_vars=""
    
    # Detect framework and set required vars
    if [ -f "package.json" ]; then
        if grep -q '"next"' package.json 2>/dev/null; then
            required_vars="NODE_ENV"
        elif grep -q '"express"' package.json 2>/dev/null; then
            required_vars="NODE_ENV PORT"
        elif grep -q '"react-scripts"' package.json 2>/dev/null; then
            required_vars="NODE_ENV"
        fi
        
        # Check for database usage
        if grep -q '"pg"' package.json 2>/dev/null || grep -q '"postgres"' package.json 2>/dev/null; then
            required_vars="$required_vars DATABASE_URL"
        fi
        
        if grep -q '"mongoose"' package.json 2>/dev/null || grep -q '"mongodb"' package.json 2>/dev/null; then
            required_vars="$required_vars MONGODB_URI"
        fi
        
        if grep -q '"redis"' package.json 2>/dev/null; then
            required_vars="$required_vars REDIS_URL"
        fi
    fi
    
    # Python projects
    if [ -f "requirements.txt" ] || [ -f "Pipfile" ] || [ -f "pyproject.toml" ]; then
        if grep -q "django" requirements.txt 2>/dev/null || grep -q "flask" requirements.txt 2>/dev/null; then
            required_vars="$required_vars SECRET_KEY DATABASE_URL"
        fi
    fi
    
    # Check each required var
    for var in $required_vars; do
        if ! grep -q "^$var=" .env 2>/dev/null; then
            printf '%s\n' "${RED}❌ Missing: $var${RESET}"
            missing_count=$((missing_count + 1))
        else
            # Check if it's empty or still has placeholder
            local value=$(grep "^$var=" .env | cut -d= -f2-)
            if [ -z "$value" ] || echo "$value" | grep -q "your-.*-here" || [ "$value" = "changeme" ]; then
                printf '%s\n' "${YELLOW}⚠️  Empty/placeholder: $var = $value${RESET}"
            else
                printf '%s\n' "${GREEN}✅ Found: $var${RESET}"
            fi
        fi
    done
    
    # Check for empty values in .env
    if [ -f ".env" ]; then
        echo ""
        printf '%s\n' "${BLUE}Checking for empty values...${RESET}"
        
        while IFS= read -r line; do
            # Skip comments and empty lines
            if echo "$line" | grep -q '^#' || [ -z "$line" ]; then
                continue
            fi
            
            if echo "$line" | grep -q '=$' || echo "$line" | grep -q '= *$'; then
                local var_name=$(echo "$line" | cut -d= -f1)
                printf '%s\n' "${YELLOW}⚠️  Empty value: $var_name${RESET}"
            fi
        done < .env
    fi
    
    return $missing_count
}

# Function to suggest values
suggest_values() {
    local var_name="$1"
    
    case "$var_name" in
        DATABASE_URL)
            printf '%s\n' "  Example: postgresql://username:password@localhost:5432/dbname"
            printf '%s\n' "  Example: mysql://username:password@localhost:3306/dbname"
            ;;
        MONGODB_URI)
            printf '%s\n' "  Example: mongodb://localhost:27017/myapp"
            ;;
        REDIS_URL)
            printf '%s\n' "  Example: redis://localhost:6379"
            ;;
        PORT)
            printf '%s\n' "  Example: 3000"
            ;;
        NODE_ENV)
            printf '%s\n' "  Options: development, production, test"
            ;;
        JWT_SECRET|SESSION_SECRET|SECRET_KEY)
            printf '%s\n' "  Generate with: openssl rand -base64 32"
            ;;
        *)
            printf '%s\n' "  Check your service documentation for this value"
            ;;
    esac
}

# Main execution
if [ -n "$1" ]; then
    # Check specific variable
    var_name="$1"
    printf '%s\n' "${BLUE}Checking for variable: $var_name${RESET}"
    
    if [ -f ".env" ]; then
        if grep -q "^$var_name=" .env; then
            local value=$(grep "^$var_name=" .env | cut -d= -f2-)
            printf '%s\n' "${GREEN}✅ Found: $var_name = $value${RESET}"
        else
            printf '%s\n' "${RED}❌ Not found: $var_name${RESET}"
            printf '%s\n' ""
            printf '%s\n' "Adding to .env..."
            echo "$var_name=" >> .env
            printf '%s\n' "${GREEN}✅ Added $var_name to .env${RESET}"
            suggest_values "$var_name"
        fi
    else
        printf '%s\n' "${RED}No .env file found!${RESET}"
        printf '%s\n' "Run this script without arguments to create one"
    fi
else
    # General check
    check_missing_vars || true
fi

# Show .env.example if it exists
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo ""
    printf '%s\n' "${YELLOW}=== .env.example contents ===${RESET}"
    cat .env.example
fi

# Final tips
echo ""
printf '%s\n' "${YELLOW}=== TIPS ===${RESET}"
printf '%s\n' "1. Copy .env.example to .env if it exists"
printf '%s\n' "2. Never commit .env files to git"
printf '%s\n' "3. Use strong, unique values for secrets"
printf '%s\n' "4. Different values for dev/test/prod environments"
printf '%s\n' "5. Some services provide .env templates in their docs"

# Check if .env is in .gitignore
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.env$" .gitignore; then
        echo ""
        printf '%s\n' "${RED}⚠️  WARNING: .env is not in .gitignore!${RESET}"
        printf '%s\n' "Adding .env to .gitignore..."
        echo ".env" >> .gitignore
        printf '%s\n' "${GREEN}✅ Added .env to .gitignore${RESET}"
    fi
fi