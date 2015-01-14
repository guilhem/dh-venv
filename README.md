# Goal

Packaging a python app can be really painful.  
You have to package your app, test it with lib already packaged and package yourself any python lib you want (and pray for not breaking something).

On the other side, dev love to use vendoring like [`virtualenv`](http://virtualenv.readthedocs.org/) (python 2) or [`venv`](https://docs.python.org/3/library/venv.html) (python 3.3+).

Unite them all!

# Install

## Ubuntu

### Repository
* [stable repository](https://launchpad.net/~dh-venv/+archive/ubuntu/stable):  
`sudo add-apt-repository ppa:dh-venv/stable`
* [daily build repository](https://launchpad.net/~dh-venv/+archive/ubuntu/daily):  
`sudo add-apt-repository ppa:dh-venv/daily`

### Package
```
sudo apt-get update; sudo apt-get install dh-venv
```

# Usage

## `rules`

In your `rules` file, just add this for a simple package (who works):

```makefile
#!/usr/bin/make -f
# -*- makefile -*-

# Uncomment this to turn on verbose mode.
#export DH_VERBOSE=1

%:
	dh $@ --buildsystem python_venv
```

## Package

By default, it will create a virtualenv in `/usr/share/python` with package source name (find in `control` file).

## Options

Some global variables can be used to customize / extend `dh-venv`:

| Varible | Action  | Format | Default Value  |
| --------|:-------:|:------:| --------------:|
| `DH_VENV_PKG` | Virtualenv name | single_word | package source name |
| `DH_REQUIREMENT_FILE` | requirement file to install | single_word | `requirements.txt` |
| `DH_VENV_CREATE` | options to pass at creation of `virtualenv` | value,comma,separated | `--no-site-packages` |
| `DH_VENV_ROOT_PATH` | Root path for destination application | single_word | ``/usr/share/python` |
