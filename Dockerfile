from ubuntu

RUN apt-get update && apt-get install -y --force-yes software-properties-common && apt-get clean
RUN add-apt-repository -y ppa:dh-venv/stable
RUN apt-get update && apt-get install -y --force-yes devscripts equivs debhelper dh-venv && apt-get clean

VOLUME /code
WORKDIR /code

CMD mk-build-deps --install --tool "apt-get -y --force-yes" && debuild --no-tgz-check --no-lintian -us -uc && mkdir -p build && cp -f ../*.deb build/
