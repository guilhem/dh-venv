# Goal

Packaging a python app can be really painful.  
You have to package your app, test it with lib already packaged and package yourself any python lib you want (and pray for not breaking something).

On the other side, dev love to use vendoring like [`virtualenv`](http://virtualenv.readthedocs.org/) (python 2) or [`venv`](https://docs.python.org/3/library/venv.html) (python 3.3+).

Unite them all!

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
| DH_PKG | Virtualenv name | single_word | package source name |
| DH_REQUIREMENT_FILE | requirement file to install | single_word |  requirements.txt |
| DH_PIP_INSTALL | options to pass to `pip install` | value:semicolon:separated | --no-compile |
| DH_PIP_INSTALL_REQUIREMENT | options to pass to `pip install --requirements` | value:semicolon:separated | DH_PIP_INSTALL |
| DH_VENV_CREATE | options to pass at creation of `virtualenv` | value:semicolon:separated | --no-site-packages |
