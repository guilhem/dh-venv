package Debian::Debhelper::Buildsystem::python_venv;

use strict;
use Debian::Debhelper::Dh_Lib qw(sourcepackage);
use Cwd qw( abs_path );
use Env qw(@DH_PIP_INSTALL @DH_PIP_INSTALL_REQUIREMENT @DH_VENV_CREATE);
use base 'Debian::Debhelper::Buildsystem';

push @DH_PIP_INSTALL, '--no-compile';
push @DH_VENV_CREATE, '--no-site-packages';
@DH_PIP_INSTALL_REQUIREMENT = @DH_PIP_INSTALL unless defined(@DH_PIP_INSTALL_REQUIREMENT);

sub DESCRIPTION {
	"Python venv (setup.py)"
}

sub check_auto_buildable {
	my $this=shift;
	return (-e $this->get_sourcepath("setup.py")) ? 1 : 0;
}

sub new {
	my $class=shift;
	my $this= $class->SUPER::new(@_);
	$this->prefer_out_of_source_building(@_);
	return $this;
}

sub build {
	my $this=shift;
	$this->doit_in_sourcedir('virtualenv', @DH_VENV_CREATE, $this->get_builddir());
        $ENV{PATH} = $this->get_builddir() . '/bin' . ":$ENV{PATH}";
	if (-e $this->get_sourcepath("requirements.txt")) {
		$this->doit_in_sourcedir('pip', 'install', @DH_PIP_INSTALL_REQUIREMENT, '--requirement', 'requirements.txt');
	}
	$this->doit_in_sourcedir('pip', 'install', @DH_PIP_INSTALL, '.');
}

sub install {
	my $this=shift;
	my $destdir=shift;

	my $builddir = abs_path($this->get_buildpath());

	my $pkg = defined $ENV{DH_PKG} ? $ENV{DH_PKG} : sourcepackage();

	my $dest_final = "/usr/share/python/$pkg";
	my $dest_src = $destdir . $dest_final;

	$this->doit_in_builddir('mkdir', '-p', $dest_src);
	$this->doit_in_sourcedir('cp', '--recursive', '--no-target-directory', $builddir, $dest_src);

	my $dest_bin_dir = "$dest_src/bin";
	{
		# Edit inplace
		local $^I = q{};
		# Find all files in final "bin" who are not binary
		local @ARGV = grep { -T $_ } glob("$dest_bin_dir/*");
		while ( <> ) {
			# Fix shebang and any local path
			s[$builddir][$dest_final]g;
			print;
		}
	}
}


sub clean {
	my $this=shift;
	$this->rmdir_builddir();
}

1
