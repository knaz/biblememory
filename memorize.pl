#!/usr/bin/perl

use strict;
use warnings;

use lib ".";
use CGI;
use Versions;
my $q = CGI->new;
my $u = $q->param('u') || '';

my $html = do { local $/; open my $f, "<page-template.html"; <$f> };

$html =~ s/{title}/Peronal Memory URL/;

my $body = '';
$body .= qq{<div style="color: red">This is your personalized URL.  Bookmark this page.</div>}
    unless -d "users/$u";

mkdir "users/$u" unless -d "users/$u";
mkdir "users/$u/passages" unless -d "users/$u/passages";
opendir my $d, "users/$u/passages";
our $VAR1;
my %seen_versions;
my @toreview = map {
    my $file = $_;
    open my $f, "users/$u/passages/$file";
    my $text = do { local $/; <$f> };
    eval $text;
    $seen_versions{$VAR1->{version}}++;
    my $href = "drill.pl?u=$u&amp;f=$file";
    my $text = "$VAR1->{passage} - $VAR1->{version}";
    qq~<a target="_blank" href="$href">$text</a> ~ .
    qq~<a href="delete.pl?f=$file">Delete</a>~;
} sort grep !/^[.]+$/, readdir $d;

my $toreview = @toreview
    ? '<ul>' . join('', map "<li>$_</li>", @toreview) . '</ul>'
    : 'Nothing to review.';

my $copyrights = join '',
    map qq{<p class="copyright-notice">$_</p>},
    map $Versions::copyrights{$_},
    sort keys %seen_versions;

my $book_options = join '', map qq{<option value="$_">$_</option>},
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua', 'Judges',
    'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings', '1 Chronicles',
    '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
    'Ecclesiastes', 'Song of solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
    'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi', 'Matthew',
    'Mark', 'Luke', 'John', 'Acts', 'Romans', '1 Corinthians', '2 Corinthians',
    'Galatians', 'Ephesians', 'Philippians', 'Colossians', '1 Thessalonians',
    '2 Thessalonians', '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews',
    'James', '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation';

$body .= <<EOF;
    <h2>Review</h2>
    <p>$toreview<p>
    $copyrights
    <h2>New Raw Passage</h2>
    <form method="post" action="new-passage-paste.pl">
    <input type="hidden" name="u" value="$u">
    <table>
        <tr>
            <th>Name:</th>
            <td><input type="text" name="passage"></td>
        </tr>
        <tr>
            <th>Paste:</th>
            <td><textarea name="paste"></textarea></td>
        </tr>
        <tr>
            <td colspan="2"><button type="submit">Begin</button></td>
        </tr>
    </table>
    </form>
    <h2>New Passage</h2>
    <form action="new-passage.pl">
    <input type="hidden" name="u" value="$u">
    <table>
        <tr>
            <th>Version:</th>
            <td>
                <select name="version">
                    <option value="NASB">NASB</option>
                    <option value="ESV">ESV</option>
                    <option value="LBLA">LBLA</option>
                    <option value="SBLGNT">SBLGNT</option>
                    <option value="KJV">KJV</option>
                </select>
            </td>
        </tr>
        <tr>
            <th>Book:</th>
            <td><select name="book">$book_options</select></td>
        </tr>
        <tr>
            <th>Chapter:</th>
            <td><input name="chapter" type="text" value="1" style="width: 2em"></td>
        </tr>
        <tr>
            <th>Verses:</th>
            <td>
                <input name="first_verse" type="text" value="1" style="width: 2em">
                to <input name="last_verse" type="text" style="width: 2em">
            </td>
        </tr>
        <tr>
            <td colspan="2"><button type="submit">Begin</button></td>
        </tr>
    </table>
    </form>
    <span style="height: 3em">&nbsp;</span>
EOF

$html =~ s/{contentarea}/$body/;

print "Content-type: text/html\n\n";
print $html;
