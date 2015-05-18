# `dh-venv` Docker build image

This image is used to build your own python package who use dh-venv

## Usage

```sh
sudo docker run --rm -v $PWD:/code guilhem/dh-venv
```
This create a directory `build` with all your deb packages.
