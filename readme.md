# personal-web

My personal blog built with Hugo and deployed to GitHub Pages at
[code.lol](https://code.lol).

## 🚀 Quick Start

### Prerequisites

- Git
- Hugo
- GitHub account with access to deployment repository

### Initial Setup

Clone the repository and run the setup script:

```sh
git clone git@github.com:poteat/personal-web.git
cd personal-web
./setup.sh
```

The setup script will:

- Initialize git submodules (theme and deployment repo)
- Clone the deployment repository
- Verify Hugo is installed
- Build the site

### Development

Start the local development server:

```sh
hugo server -D
```

The site will be available at http://localhost:1313 with live reload.

## 📝 Content Management

### Creating New Posts

```sh
hugo new post/category/my-new-post.md
```

Categories include: `programming`, `life`, `algorithms`, `bioinformatics`,
`simulation`

### Adding "Read More" Breaks

Add `<!--more-->` in your markdown where you want the preview to end on the
homepage:

```markdown
---
title: "My Post Title"
date: 2024-01-01
---

This is the preview text that appears on the homepage.

<!--more-->

The rest of the content only shows on the full post page.
```

### Creating Hidden Posts

To create a post that's accessible via direct URL but not listed on the homepage
or category pages (useful for drafts you want to share, or unlisted content):

```markdown
---
title: "My Hidden Post"
date: 2024-01-01
build:
  list: never
  render: always
  publishResources: true
---
```

- `list: never` — excludes the post from all list pages (homepage, categories)
- `render: always` — the post is still rendered and accessible via its URL
- `publishResources: true` — ensures images and other resources are published

## 🚢 Deployment

Deploy changes to GitHub Pages:

```sh
./deploy.sh
```

The deployment script will:

1. Build the site with Hugo
2. Show you what changes will be deployed
3. Ask for confirmation
4. Prompt for a commit message
5. Push to the `poteat.github.io` repository

Your changes will be live at https://code.lol within a few minutes.

## 📁 Project Structure

```
personal-web/
├── content/          # Blog posts and pages
│   ├── post/        # Blog posts organized by category
│   ├── about.md     # About page
│   └── contact.md   # Contact page
├── themes/
│   └── mainroad/    # Hugo theme (git submodule)
├── poteat.github.io/ # Deployment repository (git submodule)
├── static/          # Static assets (images, etc.)
├── config.toml      # Hugo configuration
├── setup.sh         # Initial setup script
└── deploy.sh        # Deployment script
```

## 🔧 Manual Commands

If you prefer manual commands over the scripts:

### Build the site:

```sh
hugo -d poteat.github.io
```

### Deploy manually:

```sh
cd poteat.github.io
git add -A
git commit -m "Update site"
git push origin master
cd ..
```
