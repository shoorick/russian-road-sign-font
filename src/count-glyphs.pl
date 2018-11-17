#!/usr/bin/perl -w

=head1 USAGE

./count-glyphs.pl font.sfd

=cut

use strict;
use List::Util qw( uniq );
use YAML::Tiny;

my $config = YAML::Tiny->read( 'config.yml' )->[0];
my ( %ranges, @range_by_code, %count_glyph, %count_ref );

foreach my $key ( keys %{ $config->{'gost'} } ) {
    my @chars = map {
        /^([\da-f]+)-([\da-f]+)$/
        ? ( hex($1) .. hex($2) )
        : hex($_)
    } split /\s+/, $config->{'gost'}->{$key};
    $ranges{$key} = \@chars;
    map { $range_by_code[$_] = $key } @chars;
}

local $/;
my $font = <>;

while ( $font =~ /StartChar: (.+?)\nEncoding: (\d+) \d+ (\d+)\n.+?\n(.+?)\nEndChar\n/gs ) {
    my ( $name, $code, $number, $content ) = ( $1, $2, $3, $4 );
    my $ref = $content =~ /Refer:/ ? 'reference' : '';

    printf "%d\t%s (%x)\t%s\n", $number, $name, $code, $ref;

    if ( defined $range_by_code[$code] ) {
        if ( $ref ) {
            $count_ref{   $range_by_code[$code] }++;
        }
        else {
            $count_glyph{ $range_by_code[$code] }++;
        }
    }
}

foreach my $range ( sort( uniq( keys %count_ref, keys %count_glyph ) ) ) {
    my $glyphs  = $count_glyph{$range} // 0;
    my $refs    = $count_ref{$range}   // 0;
    my $sum     = $glyphs + $refs;
    my $total   = scalar @{ $ranges{$range} };
    my $percent = $total
        ? sprintf ' (%d %%)', 100 * $sum / $total
        : '';

    printf "%s\t%d + %d = %d of %d%s\n",
        $range,
        $glyphs, $refs,
        $sum, $total, $percent;
}

