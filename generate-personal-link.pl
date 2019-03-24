#!/usr/local/bin/perl

use strict;
use warnings;

use Digest::SHA1 qw(sha1_hex);
use Time::HiRes qw(time);

my $digest = make_digest();
$digest = make_digest() while (-d "users/$digest");

sub make_digest {
    my $digest = sha1_hex(time);
    return substr($digest, 0, 10);
}

print "Content-type: text/html\n\n";
print <<EOF;
<html>
<head>
<script>
window.location = "http://keithnaz.com/biblememory/memorize.pl?u=$digest";
</script>
</head>
<body>
</body>
</html>
EOF
