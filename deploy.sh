#!/bin/bash

# Deployment script for poteat.github.io blog

echo "🚀 Deploying to GitHub Pages..."

# Check if deployment repo exists
if [ ! -d "poteat.github.io/.git" ]; then
    echo "❌ Deployment repository not found. Please run ./setup.sh first"
    exit 1
fi

# Get commit message from parameter or prompt first
if [ -n "$1" ]; then
    # Use all parameters as the commit message
    commit_msg="$*"
    echo "📝 Using commit message: $commit_msg"
else
    echo ""
    read -p "Enter commit message (or press enter for default): " commit_msg
    if [ -z "$commit_msg" ]; then
        commit_msg="Update site $(date +'%Y-%m-%d %H:%M')"
    fi
fi

# Build the site
echo "🔨 Building site with Hugo..."
hugo -d poteat.github.io

# Check for deployment changes
cd poteat.github.io
if [ -z "$(git status --porcelain)" ]; then 
    echo "✅ No changes to deploy to GitHub Pages"
    cd ..
else

    # Show changes
    echo ""
    echo "📝 Changes to be deployed:"
    git status --short
    echo ""

    # Commit and push deployment
    echo "📤 Committing deployment changes..."
    git add -A
    git commit -m "$commit_msg"

    echo "🚢 Pushing to GitHub Pages..."
    git push origin master

    # Go back to main repo
    cd ..
fi
echo ""
echo "📝 Committing changes to source repository..."
git add -A
if git commit -m "$commit_msg" 2>/dev/null; then
    echo "🚢 Pushing source repository..."
    git push origin master
else
    echo "No changes to commit in source repo"
fi

echo ""
echo "✨ Deployment complete!"
echo "🌐 Your site will be live at https://code.lol in a few minutes"