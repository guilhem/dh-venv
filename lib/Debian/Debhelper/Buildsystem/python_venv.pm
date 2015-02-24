package Debian::Debhelper::Buildsystem::python_venv;

use strict;
use Debian::Debhelper::Dh_Lib;
use File::Which qw(which);
use Cwd qw( abs_path );
use Env qw(DH_VENV_REQUIREMENT_FILE
  DH_VENV_CREATE
  DH_VENV_ROOT_PATH
  DH_VENV_NAME
  DH_VENV_PKG
  DH_VENV_INTERPRETER);
use base 'Debian::Debhelper::Buildsystem';

my @DH_VENV_CREATE = split( /,/, $DH_VENV_CREATE );

if ( defined $ENV{DH_VERBOSE} && $ENV{DH_VERBOSE} ne "" ) {
    $ENV{PIP_VERBOSE} = 'true';
    unshift @DH_VENV_CREATE, '--verbose';
}
else {
    $ENV{PIP_QUIET} = 'true';
    unshift @DH_VENV_CREATE, '--quiet';
}

$DH_VENV_REQUIREMENT_FILE = 'requirements.txt' unless $DH_VENV_REQUIREMENT_FILE;
$DH_VENV_ROOT_PATH   = '/usr/share/python' unless $DH_VENV_ROOT_PATH;
$DH_VENV_NAME        = sourcepackage()     unless $DH_VENV_NAME;
$DH_VENV_PKG         = sourcepackage()     unless $DH_VENV_PKG;
$DH_VENV_INTERPRETER = 'python'            unless $DH_VENV_INTERPRETER;

my $python_path = which($DH_VENV_INTERPRETER);

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

    doit( 'virtualenv', "--python=${DH_VENV_INTERPRETER}",
        @DH_VENV_CREATE, $builddir );

    if ( -e $this->get_sourcepath($DH_VENV_REQUIREMENT_FILE) ) {
        $this->doit_in_sourcedir( "${builddir}/bin/pip", 'install',
            '--requirement', $DH_VENV_REQUIREMENT_FILE );
    }
    $this->doit_in_sourcedir( "${builddir}/bin/pip", 'install', '.' );
}

sub install {
    my $this    = shift;
    my $destdir = shift;

    my $builddir = abs_path( $this->get_buildpath() );

    my $dest_final = "$DH_VENV_ROOT_PATH/$DH_VENV_NAME";
    my $dest_src   = $destdir . $dest_final;

    copy_recursively( $builddir, $dest_src, '.pyc$' );

    # Fix shebangs
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

    # Fix "local" links. make it relative
    my $dest_local_dir = "$dest_src/local";
    $this->_cd($dest_local_dir);
    foreach my $file ( grep { -l $_ } glob("$dest_local_dir/*") ) {
        my $bfile = basename($file);
        doit( 'ln', '--symbolic', '--force', "../$bfile" );
    }
    $this->_cd( $this->_rel2rel( $this->{cwd}, $this->get_sourcedir() ) );

    my $python_venv_path = "${dest_bin_dir}/python";

    # Replace python to a wrapper script
    unlink $python_venv_path;
    open( my $fh, '>', $python_venv_path )
      or die "Could not open file '$python_venv_path' $!";
    print $fh "#!/bin/sh\nPYTHONHOME=${dest_final} ${python_path} \"\$@\"\n";
    chmod 0755, $fh;
    close $fh;

    # Provide ${python:Depends} varaible substitution
    my $python_major =
      `$python_path -c "import sys; print(sys.version_info[0])"`;
    my $python_minor =
      `$python_path -c "import sys; print(sys.version_info[1])"`;
    my $python_minor_plus = $python_minor + 1;
    addsubstvar( $DH_VENV_PKG, "python:Depends",
        'python', ">= $python_major.$python_minor" );
    addsubstvar( $DH_VENV_PKG, "python:Depends",
        'python', "<< $python_major.${python_minor_plus}" );

    # Add compile scripts
    if ( !$dh{NOSCRIPTS} ) {
        autoscript( ${DH_VENV_PKG}, "postinst", "postinst-venv-compile",
            "s/#PACKAGE#/${DH_VENV_PKG}/" );
        autoscript( ${DH_VENV_PKG}, "prerm", "prerm-venv-clean",
            "s/#PACKAGE#/${DH_VENV_PKG}/" );
    }
}

sub clean {
    my $this = shift;
    $this->rmdir_builddir();
}

sub copy_recursively {
    my ( $from_dir, $to_dir, $regex ) = @_;
    opendir my ($dh), $from_dir or die "Could not open dir '$from_dir': $!";
    for my $entry ( readdir $dh ) {
        next if ( $entry =~ /$regex/ || $entry eq '.' || $entry eq '..' );
        my $source      = "$from_dir/$entry";
        my $destination = "$to_dir/$entry";
        if ( -l $source ) {
            symlink readlink($source), $destination; #my to = readlink($source);
        }
        elsif ( -d $source ) {
            doit( 'mkdir', '-p', $destination )
              or die "mkdir '$destination' failed: $!"
              if not -e $destination;
            copy_recursively( $source, $destination, $regex );
        }
        else {
            doit( 'cp', $source, $destination ) or die "copy failed: $!";
        }
    }
    closedir $dh;
    return;
}

1
