# personal-web

## Installation and Invocation :)

For first-time installation of the tooling required to build the website:

```sh
snap install hugo
```

To clone repo and necessary submodules:

```sh
git clone git@github.com:poteat/personal-web.git
cd personal-web
chmod +x deploy.sh
cd themes
rm -rf mainroad
git clone git@github.com:vimux/mainroad.git
cd ..
rm -rf public
git rm --cached public
git submodule add git@github.com:poteat/poteat.github.io.git
cd ..
```

To add posts:

```sh
hugo new post/life/example.md
```

To start up local server on localhost:1313

```sh
hugo server -D
```

To build:

```sh
hugo -t mainroad -d poteat.github.io
```

Building will apply updates to the poteat.github.io distribution folder, which
is linked as a submodule to the public distribution repository. So, to deploy,
all you need to do is commit and push after building.
