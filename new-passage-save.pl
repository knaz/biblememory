#!/usr/bin/perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;

my $u = $q->param('u') || '';
my $passage = $q->param('passage') || '';
my $version = $q->param('version') || '';
my @linewords = grep $_ > 0, $q->param('linewords');

{
    (my $file = $passage) =~ s/ /_/g;
    mkdir "users/$u/passages" unless -d "users/$u/passages";
    open my $f, ">users/$u/passages/$file";

    use Data::Dumper;
    print $f Dumper({
        passage => $passage,
        version => $version,
        linewords => \@linewords,
    });
}

print "Content-type: text/html\n\n";
print <<EOF;
<html>
<head>
<script>
window.location = "http://dm2usa.org/biblememory/memorize.pl?u=$u";
</script>
</head>
<body>
</body>
</html>
EOF
