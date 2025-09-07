#!/bin/bash

# Deployment script for poteat.github.io blog

echo "🚀 Deploying to GitHub Pages..."

# Check if deployment repo exists
if [ ! -d "poteat.github.io/.git" ]; then
    echo "❌ Deployment repository not found. Please run ./setup.sh first"
    exit 1
fi

# Build the site
echo "🔨 Building site with Hugo..."
hugo -d poteat.github.io

# Check for changes
cd poteat.github.io
if [ -z "$(git status --porcelain)" ]; then 
    echo "✅ No changes to deploy"
    exit 0
fi

# Show changes
echo ""
echo "📝 Changes to be deployed:"
git status --short
echo ""

# Prompt for confirmation
read -p "Do you want to deploy these changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Commit and push
echo "📤 Committing changes..."
git add -A

# Get commit message
echo ""
read -p "Enter commit message (or press enter for default): " commit_msg
if [ -z "$commit_msg" ]; then
    commit_msg="Update site $(date +'%Y-%m-%d %H:%M')"
fi

git commit -m "$commit_msg"

echo "🚢 Pushing to GitHub..."
git push origin master

# Go back to main repo and commit changes
cd ..
echo ""
echo "📝 Committing changes to source repository..."
git add -A
git commit -m "$commit_msg" 2>/dev/null || echo "No changes to commit in source repo"

echo ""
echo "✨ Deployment complete!"
echo "🌐 Your site will be live at https://code.lol in a few minutes"