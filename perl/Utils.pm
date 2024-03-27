package Utils;

use v5.14;
use Data::Dumper;

=head1 Parse simple config file into a hash
Supports files without blanklines
=cut
sub parse_config {
    my ($path, $config) = @_;
    my $file;

    if ($path) {
        open $file, '<', $path or die "Can't open $path $!";
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

    return %$config;
}

# Formats:
# - o:OPT:v:DEFAULT ==> "-o", %options{OPT} = VALUE or DEFAULT, consumes following arg
# - o:OPT:S:VALUE ==> "-o", %options{OPT} = VALUE, also sets VALUE as default
# - o:OPT:s:VALUE ==> "-o", %options{OPT} = VALUE
# - o:OPT:s ==> o:OPT:s:1
sub parse_args {
    my (%specs, %options, @args);

    while (@_) {
        my ($opt, $key, $mode, $value) = split /:/, shift @_;

        $specs{$opt} = {
            KEY => $key,
            MODE => $mode,
            VALUE => (defined $value ? $value : 1 - ($options{$key} or 0) )
        };

        if (not ($mode eq 's')) {
            $options{$key} = $value;
        }
    }

    while (@ARGV) {
        my $opt = shift @ARGV;
        my $optname;

        if ($opt =~ /^-\w/) {
            $optname = substr $opt, 1;
        } elsif ($opt =~ /^--\w\w+/) {
            $optname = substr $opt, 2;
        }

        if ($optname) {
            exists $specs{$optname} or die "Invalid option: $opt";

            my $spec = $specs{$optname};
            my ($key, $mode, $value) = ($spec->{KEY}, $spec->{MODE}, $spec->{VALUE});

            if ($mode eq 'v') {
                if (not @ARGV) { die "Missing for option: $opt"; }

                $options{$key} = shift @ARGV;
            } elsif (lc $mode eq 's') {
                $options{$key} = $value;
            }
        } else {
            push @args, $opt;
        }
    }

    return \%options, \@args;
}

1;