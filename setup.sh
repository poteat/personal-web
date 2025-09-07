#!/bin/bash

# Setup script for poteat.github.io blog

echo "🚀 Setting up Hugo blog..."

# Initialize and update submodules
echo "📦 Initializing submodules..."
git submodule init
git submodule update

# Setup deployment repository
if [ ! -d "poteat.github.io/.git" ]; then
    echo "📝 Setting up deployment repository..."
    if [ -d "poteat.github.io" ]; then
        rm -rf poteat.github.io
    fi
    git clone git@github.com:poteat/poteat.github.io.git
else
    echo "✅ Deployment repository already configured"
fi

# Install Hugo if needed (macOS with Homebrew)
if ! command -v hugo &> /dev/null; then
    echo "📥 Hugo not found. Please install Hugo:"
    echo "  macOS: brew install hugo"
    echo "  Linux: snap install hugo --channel=extended"
    echo "  Or visit: https://gohugo.io/installation/"
    exit 1
else
    echo "✅ Hugo is installed: $(hugo version)"
fi

# Build the site
echo "🔨 Building site..."
hugo

echo ""
echo "✨ Setup complete!"
echo ""
echo "To run the development server:"
echo "  hugo server -D"
echo ""
echo "To deploy changes to GitHub Pages:"
echo "  ./deploy.sh"