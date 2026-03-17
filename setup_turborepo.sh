#!/bin/sh

set -e


# Remove default apps and packages
rm -rf ./apps/* && rm -rf ./packages/* 

# Install additional dependencies
bun add --dev --exact @biomejs/biome
# Make biome configuration file
bunx --bun biome init
jq '.files += {
	"ignoreUnknown": false,
	"includes": [
	  "**",
	  "!**/node_modules",
	  "!**/dist",
	  "!**/build",
	  "!**/.env",
	  "!**/.turbo"
	]
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json

jq '.formatter += {
	"enabled": true,
	"indentStyle": "space"
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json

jq '.linter += {
    "enabled": true,
    "rules": {
      "recommended": true,
      "nursery": {
        "useSortedClasses": "error"
      }
    }
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json

jq '.javascript += {
	    "formatter": {
      "quoteStyle": "double"
    }
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json

jq '.assist += {
    "enabled": true,
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
}' biome.json > biome.json.tmp

mv biome.json.tmp biome.json
jq '.css += {
    "parser": {
      "tailwindDirectives": true
    }
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json

jq '.vcs += {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
}' biome.json > biome.json.tmp
mv biome.json.tmp biome.json


# Add biome scripts to package.json
jq '.scripts += {
	  "build": "turbo run build",
    "dev": "turbo run dev",
    "check": "biome check . --max-diagnostics=none --error-on-warnings",
    "check:fix": "biome check . --fix --max-diagnostics=none --error-on-warnings",
    "typecheck": "turbo run typecheck",
    "prepare": "husky",
    "css": "npx @biomejs/biome check --write --unsafe ."
}'  package.json > package.json.tmp
mv package.json.tmp package.json

# Install Husky and set up Git hooks
bun add --dev husky
bunx husky init

echo "bun check" > .husky/pre-commit
echo "bun typecheck" >> .husky/pre-commit

# Set up GitHub workflow for CI/CD

mkdir -p .github/workflows

cat <<EOL > .github/workflows/ci.yml
name: CI

on: 
    pull_request:
    workflow_dispatch:
    push:
        branches:
        - main


jobs:
  build-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - run: corepack enable
      - uses: actions/setup-node@v3
        with:
          node-version: "22"
          cache: "bun"
      
      - name: Install dependencies
        run: bun add --frozen-lockfile

      - name: Run typecheck
        run: bun typecheck
      
      - name: Run biome lint and format check
        run: bun check

      - name: build project
        run: bun build
EOL

# Final installation of dependencies
bun install

echo "Setup complete! Your Turbo monorepo with Biome is ready in the '$PROJECT_NAME' directory."
