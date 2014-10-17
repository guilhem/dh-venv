package Debian::Debhelper::Buildsystem::python_venv;

use strict;
use Debian::Debhelper::Dh_Lib qw(sourcepackage doit basename);
use Cwd qw( abs_path );
use Env qw(DH_REQUIREMENT_FILE
					@DH_PIP_INSTALL
					@DH_PIP_INSTALL_REQUIREMENT
					@DH_VENV_CREATE
					DH_VENV_ROOT_PATH
					DH_VENV_PKG);
use base 'Debian::Debhelper::Buildsystem';

if (defined $ENV{DH_VERBOSE} && $ENV{DH_VERBOSE} ne "") {
	unshift @DH_PIP_INSTALL, '--verbose';
	unshift @DH_VENV_CREATE, '--verbose';
} else {
	unshift @DH_PIP_INSTALL, '--quiet';
	unshift @DH_VENV_CREATE, '--quiet';
}
unshift @DH_PIP_INSTALL, '--no-compile';
@DH_PIP_INSTALL_REQUIREMENT = @DH_PIP_INSTALL unless scalar(@DH_PIP_INSTALL_REQUIREMENT) == 0 ;
$DH_REQUIREMENT_FILE = 'requirements.txt' unless $DH_REQUIREMENT_FILE;
$DH_VENV_ROOT_PATH = '/usr/share/python' unless $DH_VENV_ROOT_PATH;
$DH_VENV_PKG = sourcepackage() unless $DH_VENV_PKG;

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
	if (-e $this->get_sourcepath($DH_REQUIREMENT_FILE)) {
		$this->doit_in_sourcedir('pip', 'install', @DH_PIP_INSTALL_REQUIREMENT, '--requirement', $DH_REQUIREMENT_FILE);
	}
	$this->doit_in_sourcedir('pip', 'install', @DH_PIP_INSTALL, '.');
}

sub install {
	my $this=shift;
	my $destdir=shift;

	my $builddir = abs_path($this->get_buildpath());

	my $dest_final = "$DH_VENV_ROOT_PATH/$DH_VENV_PKG";
	my $dest_src = $destdir . $dest_final;

	doit('mkdir', '-p', $dest_src);
	doit('cp', '--recursive', '--no-target-directory', $builddir, $dest_src);

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
	my $dest_local_dir = "$dest_src/local";
	$this->_cd($dest_local_dir);
	foreach my $file ( grep { -l $_ } glob("$dest_local_dir/*")) {
		my $bfile = basename($file);
		doit('ln', '--symbolic', '--force', "../$bfile");
	}
	$this->_cd($this->_rel2rel($this->{cwd}, $this->get_sourcedir()));
}

sub clean {
	my $this=shift;
	$this->rmdir_builddir();
}

1
