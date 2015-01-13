package Debian::Debhelper::Buildsystem::python_venv;

use strict;
use Debian::Debhelper::Dh_Lib qw(sourcepackage doit basename);
use File::Which;
use Cwd qw( abs_path );
use Env qw(DH_REQUIREMENT_FILE
  DH_VENV_CREATE
  DH_VENV_ROOT_PATH
  DH_VENV_PKG
  DH_VENV_INTERPRETER);
use base 'Debian::Debhelper::Buildsystem';

my @DH_VENV_CREATE             = split( /,/, $DH_VENV_CREATE );

if ( defined $ENV{DH_VERBOSE} && $ENV{DH_VERBOSE} ne "" ) {
    $ENV{PIP_VERBOSE} = 'true';
    unshift @DH_VENV_CREATE, '--verbose';
}
else {
    $ENV{PIP_QUIET} = 'true';
    unshift @DH_VENV_CREATE, '--quiet';
}

$DH_REQUIREMENT_FILE = 'requirements.txt'  unless $DH_REQUIREMENT_FILE;
$DH_VENV_ROOT_PATH   = '/usr/share/python' unless $DH_VENV_ROOT_PATH;
$DH_VENV_PKG         = sourcepackage()     unless $DH_VENV_PKG;
$DH_VENV_INTERPRETER = 'python'            unless $DH_VENV_INTERPRETER;

sub DESCRIPTION {
    "Python venv (setup.py)";
}

sub check_auto_buildable {
    my $this = shift;
    return ( -e $this->get_sourcepath("setup.py") ) ? 1 : 0;
}

sub new {
    my $class = shift;
    my $this  = $class->SUPER::new(@_);
    $this->prefer_out_of_source_building(@_);
    return $this;
}

sub build {
    my $this     = shift;
    my $builddir = abs_path( $this->get_builddir() );

    my $python_path = which($DH_VENV_INTERPRETER);
    $this->doit_in_sourcedir( 'virtualenv', "--python=${DH_VENV_INTERPRETER}",
        @DH_VENV_CREATE, $builddir );
    $ENV{PATH} = $builddir . '/bin' . ":$ENV{PATH}";
    my $python_venv_path = which('python');

    # Replace python to a wrapper script
    unlink $python_venv_path;
    open( my $fh, '>', $python_venv_path )
      or die "Could not open file '$python_venv_path' $!";
    print $fh "#!/bin/sh\nPYTHONHOME=${builddir} ${python_path} \$*\n";
    chmod 0755, $fh;
    close $fh;

    if ( -e $this->get_sourcepath($DH_REQUIREMENT_FILE) ) {
        $this->doit_in_sourcedir( 'pip', 'install',
            '--requirement',
            $DH_REQUIREMENT_FILE );
    }
    $this->doit_in_sourcedir( 'pip', 'install', '.' );
}

sub install {
    my $this    = shift;
    my $destdir = shift;

    my $builddir = abs_path( $this->get_buildpath() );

    my $dest_final = "$DH_VENV_ROOT_PATH/$DH_VENV_PKG";
    my $dest_src   = $destdir . $dest_final;

    doit( 'mkdir', '-p', $dest_src );
    doit( 'cp', '--recursive', '--no-target-directory', $builddir, $dest_src );

    my $dest_bin_dir = "$dest_src/bin";
    {
        # Edit inplace
        local $^I = q{};

        # Find all files in final "bin" who are not binary
        local @ARGV = grep { -f $_ && -T $_ } glob("$dest_bin_dir/*");
        while (<>) {

            # Fix shebang and any local path
            s[$builddir][$dest_final]g;
            print;
        }
    }
    my $dest_local_dir = "$dest_src/local";
    $this->_cd($dest_local_dir);
    foreach my $file ( grep { -l $_ } glob("$dest_local_dir/*") ) {
        my $bfile = basename($file);
        doit( 'ln', '--symbolic', '--force', "../$bfile" );
    }
    $this->_cd( $this->_rel2rel( $this->{cwd}, $this->get_sourcedir() ) );
}

sub clean {
    my $this = shift;
    $this->rmdir_builddir();
}

1
