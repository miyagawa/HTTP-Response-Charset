package HTTP::Response::Charset;

use strict;
our $VERSION = '0.01';

sub HTTP::Response::charset {
    my $res = shift;

    return if $res->is_error;

    # 1) Look in Content-Type: charset=...
    my @ct  = $res->header('Content-Type');
    for my $ct (@ct) {
        if ($ct =~ /;\s*charset=([\w\-]+)/) {
            return $1;
        }
    }

    # 1.1) If there's no charset=... set and Content-Type doesn't look like text, return
    unless ( mime_is_text($ct[0]) ) {
        return;
    }

    my $content = $res->content;
    unless (defined $content) {
        return;
    }

    # 2) If it looks like HTML, look for META head tags
    # if there's already META tag scanned, @ct == 2
    if (@ct < 2 && mime_is_html($ct[0])) {
        require HTML::HeadParser;
        my $parser = HTML::HeadParser->new;
        $parser->parse($content);
        $parser->eof;

        my $ct = $parser->header('Content-Type');
        if ($ct && $ct =~ /;\s*charset=([\w\-]+)/) {
            return $1;
        }
    }

    # 3) If there's an UTF BOM set, look for it
    my $boms = [
        'UTF-8'    => "\x{ef}\x{bb}\x{bf}",
        'UTF-32BE' => "\x{0}\x{0}\x{fe}\x{ff}",
        'UTF-32LE' => "\x{ff}\x{fe}\x{0}\x{0}",
        'UTF-16BE' => "\x{fe}\x{ff}",
        'UTF-16LE' => "\x{ff}\x{fe}",
    ];

    my $count = 0;
    while ($count < @$boms) {
        my $enc = $boms->[$count++];
        my $bom = $boms->[$count++];

        if ($bom eq substr($content, 0, length($bom))) {
            return $enc;
        }
    }

    # 4) If it looks like an XML document, look for XML declaration
    if ($content =~ m!^<\?xml\s+version="1.0"\s+encoding="([\w\-]+)"\?>!) {
        return $1;
    }

    # 5) If there's Encode::Detect module installed, try it
    if ( eval { require Encode::Detect::Detector } ) {
        my $charset = Encode::Detect::Detector::detect($content);
        return $charset if $charset;
    }

    return;
}

sub mime_is_text {
    my $ct = shift;
    $ct =~ s/;.*$//;
    return $ct =~ m!^text/!i || $ct =~ m!^application/(.*?)xml$!i;
}

sub mime_is_html {
    my $ct = shift;
    $ct =~ s/;.*$//;
    return $ct =~ m!^text/html$!i || $ct =~ m!^application/xhtml\+xml$!i;
}

1;
__END__

=head1 NAME

HTTP::Response::Charset - Adds charset method to HTTP::Response

=head1 SYNOPSIS

  use Encode;
  use HTTP::Response::Charset;

  my $response = $ua->get($url);
  if (my $encoding = $response->charset) {
      my $content  = decode $encoding, $response->content;
  }

=head1 DESCRIPTION

HTTP::Response::Charset adds I<charset> method to HTTP::Response,
which tries to detect its charset using various ways. Here's a
fallback order this module tries to look for its charset.

=over 4

=item Content-Type header

If the response has

  Content-Type: text/html; charset=utf-8

charset is I<utf-8> obviously.

If there's no charset= set and its MIME type doesn't look like text
data (e.g. audio/mp3), $response->charset will just return undef.

=item META tag

If there's no charset= attribute in Content-Type, and if Conetnt-Type
looks like HTML (i.e. I<text/html> or I<application/xhtml+xml>), this
module will scan HTML head tags for:

  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />

META tag values like this are usually scanned by L<HTML::HeadParser>
inside LWP::UserAgent automatically.

=item BOM detection

If there's a UTF BOM set in the response body, this module
auto-detects the encoding by recognizing the BOM.

=item XML declaration

If the response MIME type is either I<application/*+xml>, I<text/xml>
or I<text/html>, this module will scan response body looking for XML
declaration like:

  <?xml version="1.0" encoding="euc-jp"?>

=item Encode::Detect

If Encode::Detect module is installed, this module tries to
auto-detect the encoding using its response body as a test data.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Response>, L<HTML::HeadParser>, L<LWP::UserAgent>, L<Encode::Detect>

=cut
