#!/usr/bin/perl -w

=head1 USAGE

./count-glyphs.pl font.sfd

=cut

use strict;
use List::Util qw( uniq );
use YAML::Tiny;

my $config = YAML::Tiny->read( 'config.yml' )->[0];
my ( %ranges, %range_by_code, %count_glyph, %count_ref, @codes, %has_code );
my $other = 0;

foreach my $type ( qw( gost unicode ) ) {
    foreach my $key ( keys %{ $config->{$type} } ) {
        my @chars = map {
            /^([\da-f]+)-([\da-f]+)$/
            ? ( hex($1) .. hex($2) )
            : hex($_)
        } split /\s+/, $config->{$type}->{$key};
        $ranges{$type}{$key} = \@chars;
        map { $range_by_code{$type}[$_] = $key } @chars;
    }
}

local $/;
my $font = <>;

while ( $font =~ /StartChar: (.+?)\nEncoding: (\d+) \d+ (\d+)\n.+?\n(.+?)\nEndChar\n/gs ) {
    my ( $name,  $code, $number, $content ) = ( $1, $2, $3, $4 );
    #push @codes, $code;
    $has_code{$code} = 1;

    my $ref = $content =~ /Refer:/ ? 'reference' : '';
    my $set = '';

    if ( defined $range_by_code{'gost'}[$code] ) {
        $set = $range_by_code{'gost'}[$code];
        if ( $ref ) {
            $count_ref{  'gost'}{ $set }++;
        }
        else {
            $count_glyph{'gost'}{ $set }++;
        }
        $set .= ' GOST';
    }
    elsif ( defined $range_by_code{'unicode'}[$code] ) {
        $set = $range_by_code{'unicode'}[$code];
        if ( $ref ) {
            $count_ref{  'unicode'}{ $set }++;
        }
        else {
            $count_glyph{'unicode'}{ $set }++;
        }
    }
    else {
        $other++;
    }

    printf "%d\t%s (%x)\t%s\t%s\n", $number, $name, $code, $ref, $set;
}

# Statistics for writing systems

print "--------------------\nGOST compliant:\n", stats('gost'),
    "\n--------------------\nMore:\n",           stats('unicode'),
    "other\t$other\n\n--------------------\nLanguages:\n";

# Supported languages
foreach my $alphabet ( sort keys %{ $config->{'alphabet'} } ) {
    my @alphabet = map { ord } split '', $config->{'alphabet'}->{$alphabet};
    my $presented = 1;
    foreach my $code ( @alphabet ) {
        $presented = 0
        and last
            unless exists $has_code{$code}
    }
    print "$alphabet " if $presented;
}
print "\n";

sub stats {
    my $type = shift;
    my $out  = '';
    foreach my $range ( sort( uniq( keys %{ $count_ref{$type} }, keys %{ $count_glyph{$type} } ) ) ) {
        my $glyphs  = $count_glyph{$type}{$range} // 0;
        my $refs    = $count_ref{  $type}{$range} // 0;
        my $sum     = $glyphs + $refs;
        my $total   = scalar @{ $ranges{$type}{$range} };
        my $percent = $total && $type eq 'gost'
            ? sprintf ' (%d %%)', 100 * $sum / $total
            : '';

        $out .= sprintf "%s\t%d (+%d) = %d of %d%s\n",
            $range,
            $glyphs, $refs,
            $sum, $total, $percent;
    }
    return $out;
}

