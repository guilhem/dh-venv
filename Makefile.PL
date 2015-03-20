use inc::Module::Install;

name 'dh-venv';
version '0.3.1';

postamble <<'END_OF_MAKEFILE';
install:: extra_install
pure_install:: extra_install
install_vendor:: extra_install

extra_install:
	install -d $(DESTDIR)/usr/share/debhelper/autoscripts
	install -m 640 autoscripts/* $(DESTDIR)/usr/share/debhelper/autoscripts
	install -d $(DESTDIR)/usr/share/dh-venv/
	install -m 644 templates/python.tmpl $(DESTDIR)/usr/share/dh-venv/python.tmpl
END_OF_MAKEFILE

WriteAll;
