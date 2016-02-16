package Passage;

use strict;
use warnings;

use LWP::UserAgent;

sub get_passage {
    my (%params) = @_;

    my $version = $params{version};
    my $book    = $params{book};
    my $chapter = $params{chapter};
    my $a       = $params{first_verse};
    my $b       = $params{last_verse};
    my $n       = $params{words_per_phrase};
    my $format  = $params{format};

    my @verses;
    if ($version =~ /\A(NASB|LBLA|SBLGNT)\z/) {
        $book =~ s/ /_/g;
        open my $f, '<', "source/$version/".lc("$book-$chapter");
        @verses = <$f>;
        $b = @verses if $b > @verses;
        @verses = @verses[$a-1..$b-1];
        chomp for @verses;
    }
    elsif ($version eq 'ESV') {
        die "todo";

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->env_proxy;

        my $response = $ua->get(
            "http://www.esvapi.org/v2/rest/passageQuery?key=IP&passage=$book+$chapter:$a-$b"
        );
        # see sampleesv.html
        # headings are h3
        # paragraphs are p
        # chapter labels are: <span class="chapter-num" id="v43001001-1">1:1&nbsp;</span>
        # verse labels are: <span class="verse-num" id="v43001002-1">2&nbsp;</span>

        if ($response->is_success) {
            print $response->decoded_content;
        }
        else {
            die $response->status_line;
        }
    }

    if ($format eq 'html') {
        s/(\d+)\t\s*/$1:/ for @verses;
        # make sure it's inside any tags
        s/(\d+):(<.*?>)(\s*)/$2$3$1:/ for @verses;
    }
    else {
        s/\d+\t// for @verses;
    }
    my $verses = join(' ', @verses);
    $verses =~ s{</?span.*?>}{}g if $format eq 'stripped';
    $verses =~ s/(\S)&mdash;(\S)/$1&mdash; $2/; # make sure an mdash separates words, add an artificial space

    my $tree = parse_text(\$verses, []);

    my @phrases;
    while (@$tree) {
        my $num_to_shift = ref $n ? shift(@$n) : $n;
        push @phrases, shift_words($tree, $num_to_shift);
    }

    if ($format eq 'html') {
        s/(\d+):(\S)/<span style="font-size: 0.8em">$1<\/span> $2/ for @phrases;
    }

    return @phrases;
}

sub shift_words {
    my ($tree, $n, $return_n) = @_;

    my @words;
    my $spaces_seen = 0;

    while (@$tree) {
        if (!ref $tree->[0] && $tree->[0] =~ /\A\s+\z/) {
            push @words, ' ';
            shift @$tree;
            $spaces_seen++;
            last if $spaces_seen == $n;
        }
        elsif (ref $tree->[0]) {
            push @words, $tree->[0]{element};

            $tree->[0]{element} =~ /<(\w+)/;
            my $tag = $1;

            my ($_spaces_seen, $_word) = shift_words($tree->[0]{children},
                $n - $spaces_seen, 1);

            $spaces_seen += $_spaces_seen;
            push @words, $_word, "</$tag>";

            shift @$tree if 0 == @{$tree->[0]{children}};

            die "recursion into shift_words saw too many spaces"
                if $spaces_seen > $n;
            last if $spaces_seen == $n;
        }
        else {
            push @words, shift @$tree;
        }
    }

    return ($spaces_seen, join '', @words) if $return_n;

    pop @words if $words[-1] eq ' ';
    return join '', @words;
}

sub parse_text {
    my ($ref, $tree) = @_;

    while ($$ref) {
        if ($$ref =~ s/^(\s+)//) {
            push @$tree, $1; # a space
        }
        elsif ($$ref =~ s/^([^\s<>]+)//) {
            push @$tree, $1; # a word
        }
        elsif ($$ref =~ s/^(<[^\/].*?>)//) {
            my $el = $1;
            push @$tree, {
                element => $el,
                children => parse_text($ref, []),
            };
        }
        else {
            $$ref =~ s/^<\/.*?>//;
            # close tag
            return $tree;
        }
    }

    return $tree;
}

1;
