package Utils;

use v5.14;

sub parse_config {
    my ($path, $config) = @_;
    my $file;

    if ($path) {
        open $file, '<', $path or die "Can't open $path: $!";
    } else {
        $file = 'STDIN';
    }

    $config = {} if not $config;

    while (my $line = <$file>) {
        chomp $line;

        next if not $line or $line =~ /^#/; # skip blank or comment lines

        $line =~ s/([^#]+)#.*/$1/; # remove everything after comments

        my ($key, $value) = split(/\s*=\s*/, $line);
        chomp($value);

        $config->{$key} = $value;
    }

    close $file;

    return $config;
}

1;
