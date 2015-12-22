=head1 NAME

XSConfig - Fast XS drop-in replacement for Config.pm with perfect hashing.

=head1 VERSION

Version 6.00_04

=head1 SYNOPSIS

The Config.pm included by default with Perl is pure Perl.  Nearly all Perl apps
will load Config.pm.  For a number of reasons, of speed and memory space,
reimplement the P5P shipped Config.pm as an XS library, shareable between
processes as read-only memory, and with a hash that is better optimized than
Perl hashes, courtesy of gperf tool which generates collision-free perfect
hashes.
 
This module is a drop-in replacement for Config.pm. All code that does
 
    use Config;
 
will use the XS implementation after installing this module.  To revert to the
original pure perl Config.pm, go and delete the following 3 files that will be
next to each other in /site, Config.pm, Config_mini.pl, Config_xs_heavy.pl, and
the Config shared library in /auto, after deleting the /site files, the original
pure perl Config.pm in /lib will be loaded.
 
IT IS HIGHLY RECOMMENDED THAT YOU HAVE GPERF TOOL INSTALLED AND RUNNABLE FROM
YOUR PATH BEFORE INSTALLING XS CONFIG.

=head1 AUTHOR

Daniel Dragan C<< <BULKDD at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015, Daniel Dragan
Copyright (C) 2015, cPanel Inc
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# XSLoader for perl, not miniperl

# for a description of the variables, please have a look at the
# Porting/Glossary file, or use the url:
# http://perl5.git.perl.org/perl.git/blob/HEAD:/Porting/Glossary

package XSConfig;
package
    Config;
use strict;
use warnings;
use vars '%Config', '$VERSION';

$VERSION = '6.00_04';

# Skip @Config::EXPORT because it only contains %Config, which we special
# case below as it's not a function. @Config::EXPORT won't change in the
# lifetime of Perl 5.
my %Export_Cache = (myconfig => 1, config_sh => 1, config_vars => 1,
		    config_re => 1, compile_date => 1, local_patches => 1,
		    bincompat_options => 1, non_bincompat_options => 1,
		    header_files => 1);

@Config::EXPORT = qw(%Config);
@Config::EXPORT_OK = keys %Export_Cache;

# Need to stub all the functions to make code such as print Config::config_sh
# keep working

sub bincompat_options;
sub compile_date;
sub config_re;
sub config_sh;
sub config_vars;
sub header_files;
sub local_patches;
sub myconfig;
sub non_bincompat_options;

# Define our own import method to avoid pulling in the full Exporter:
sub import {
    shift;
    @_ = @Config::EXPORT unless @_;

    my @funcs = grep $_ ne '%Config', @_;
    my $export_Config = @funcs < @_ ? 1 : 0;

    no strict 'refs';
    my $callpkg = caller(0);
    foreach my $func (@funcs) {
	die qq{"$func" is not exported by the Config module\n}
	    unless $Export_Cache{$func};
	*{$callpkg.'::'.$func} = \&{$func};
    }

    *{"$callpkg\::Config"} = \%Config if $export_Config;
    return;
}

sub TIEHASH {
    bless \do{my $uv = 0;}, $_[0]; #XS Config Obj constructor
}
sub DESTROY { }
sub STORE  { die "\%Config::Config is read-only\n" }
*DELETE = *CLEAR = \*STORE; # Typeglob aliasing uses less space

if (defined &DynaLoader::boot_DynaLoader) {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    %Config = ();
    tie %Config, 'Config';
} else {
    no warnings 'redefine';
    %Config:: = ();
    undef &{$_} for qw(import TIEHASH DESTROY AUTOLOAD STORE);
    require 'Config_mini.pl';
}

sub AUTOLOAD {
    if (defined &DynaLoader::boot_DynaLoader) {
        require 'Config_xs_heavy.pl';
    }
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}
