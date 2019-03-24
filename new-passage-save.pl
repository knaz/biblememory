#!/usr/local/bin/perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;

my $u = $q->param('u') || '';
my $passage = $q->param('passage') || '';
my $version = $q->param('version') || '';
my $text = $q->param('text') || '';
my @linewords = grep $_ > 0, $q->param('linewords');

$version ||= 'RAW' if $text;

{
    my $file = $passage;
    $file =~ s/\W/_/g;
    mkdir "users/$u/passages" unless -d "users/$u/passages";
    open my $f, ">users/$u/passages/$file";

    use Data::Dumper;
    print $f Dumper({
        passage => $passage,
        version => $version,
        linewords => \@linewords,
        text => $text,
    });
}

print "Content-type: text/html\n\n";
print <<EOF;
<html>
<head>
<script>
window.location = "http://keithnaz.com/biblememory/memorize.pl?u=$u";
</script>
</head>
<body>
</body>
</html>
EOF
