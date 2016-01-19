#!/usr/bin/perl
# create Config_mini.pl for CPAN if not created already by cperl core
#usage: perl Config_mini.pl.PL [ignored]

use strict ;
my $VERSION = '6.00';
use ExtUtils::Command;

BEGIN {

}

my $mini = searchdirs('Config_mini.pl', \@INC);
if ($mini) {
    my $minidata;
    {
        open(my $fh, "<", $mini) or die $!;
        local $/; # enable localized slurp mode
        $minidata = <$fh>;
        close $fh;
    }
    warn "found Config_mini.pl at $mini\n";
    print "XXXXXXXXXXXXXXXXXXXXXXXXX\n".$minidata."XXXXXXXXXXXXXXXXXXXXXXXXX\n";

    require 'xsc_test.pl'; #Config_mini.pl.PL not in cperl, no eval needed
    # test if Config_mini.pl is usuable in a seperate process since
    # Config_mini.pl might be so broken that the ExtUtils::Command::cp later on
    # might need something from %Config and %Config is broken after the broken
    # Config_mini.pl was half loaded into the process
    my $ret = runperl(progfile=> $mini, stderr => 1);
    # installed Config_mini.pl unusable, a possible perl maint upgrade happened
    if ($ret ne '') {
        undef($mini);# pretend we never found Config_mini.pl
    } else {
        @ARGV = ($mini, 'Config_mini.pl');
    }
}
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
    warn "found Config.pm at $INC{'Config.pm'}\n";
    print "XXXXXXXXXXXXXXXXXXXXXXXXX\n".$cfgdata."XXXXXXXXXXXXXXXXXXXXXXXXX\n";
    @ARGV = ($INC{'Config.pm'}, 'Config_mini.pl');
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
