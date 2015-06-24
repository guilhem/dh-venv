from ubuntu:12.04

RUN apt-get update && apt-get install -y --force-yes python-software-properties && apt-get clean
RUN add-apt-repository -y ppa:dh-venv/stable
RUN apt-get update && apt-get install -y --force-yes devscripts equivs debhelper dh-venv && apt-get clean

VOLUME /code
WORKDIR /code

CMD apt-get update && mk-build-deps --install --tool "apt-get -y --force-yes" && debuild --no-tgz-check --no-lintian -us -uc && mkdir -p build && cp -f ../*.deb build/
