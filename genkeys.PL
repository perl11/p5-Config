#A script the generate the big common keys
#qw() block for XSConfig.t and Config_xs.PL
use POSIX qw(ceil);
my %keys;

#put keys here
my @keys = qw(





);

#de-dup
$keys{$_} = 1 foreach (@keys);
@keys = sort keys %keys;
my @lines;
my $line;
foreach my $key (@keys) {
    my $align;
    $align = (ceil((length $line)/4)*4)-length $line;
    if(length($line) + $align + length($key) > 79) {
        chop($line); #remove space at end of line
        push @lines, $line;
        $line = $key . ' ';
    } else {
        $line .= ' ' x $align;
        $line .= $key . ' ';
    }
}
$, = "\n";
chop($line);
print @lines, $line;
