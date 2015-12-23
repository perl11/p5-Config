#!/usr/bin/perl
# create Config_mini.pl for CPAN if not created already by cperl core
#usage: perl Config_mini.pl.PL [ignored]

use strict ;
my $VERSION = '6.00';
use ExtUtils::Command;

my $mini = searchdirs('Config_mini.pl', \@INC);
if (! $mini) { #create it
    require Config;
    my $cfgdata;
    {
        open(my $fh, "<", $INC{'Config.pm'}) or die $!;
        local $/; # enable localized slurp mode
        $cfgdata = <$fh>;
        close $fh;
    }
    die "Found Config.pm is XS Config.pm, but sister file Config_mini.pl was "
        . "not found, broken XS Config install?"
        if index($cfgdata, 'Config_mini.pl') != -1;
    @ARGV = ($INC{'Config.pm'}, 'Config_mini.pl');
} else {
    #completly redundant but copy it to make mkf happy
    @ARGV = ($mini, 'Config_mini.pl');
}

cp();
die 'failed chmod on Config_mini.pl'
    if CORE::chmod(0777, 'Config_mini.pl') != 1; #avoid EU::C's chmod for speed
@ARGV = ('Config_mini.pl');  #make tools complain file created but timestamp
touch(); # not updated, and rerun Config_mini.pl.PL on >= 2nd "make all"

sub searchdirs {
    my($fn, $fullfn) = shift;
    foreach my $d ( @{$_[0]} ) {
        my $tmppath = $d.'/'.$fn;
        if (-s $tmppath) {
            $fullfn = $tmppath;
            last;
        }
    }
    return $fullfn;
}
