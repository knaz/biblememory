#!/usr/bin/perl

use strict;
use warnings;

use CGI;

my $q = CGI->new;
my $u = $q->param('u') || '';
my $filename = $q->param('f') || '';

if ($u && $filename) {
    unlink "users/$u/passages/$filename";
    unlink "users/$u/passages/$filename.log";
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
