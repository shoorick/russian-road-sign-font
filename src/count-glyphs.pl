#!/usr/bin/perl -n -0777

=head1 USAGE

./count-glyphs.pl font.sfd

=cut

while ( /StartChar: (.+?)\nEncoding: (\d+) \d+ (\d+)\n.+?\n(.+?)\nEndChar\n/gs ) {
    my ( $name, $code, $number, $content ) = ( $1, $2, $3, $4 );
    my $ref = $content =~ /Refer:/ ? 'reference' : '';

    printf "%d\t%s (%x)\t%s\n", $number, $name, $code, $ref;
}

