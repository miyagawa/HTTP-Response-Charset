package HTTP::Response::Charset;

use strict;
our $VERSION = '0.01';

use HTTP::Headers::Util ();

sub HTTP::Response::charset {
    my $res = shift;
    return if $res->is_error;

    return $res->{_http_response_charset}
        if exists $res->{_http_response_charset};

    my $charset = _http_response_charset($res);
    if (defined $charset) {
        return $res->{_http_response_charset} = $charset;
    }

    return;
}

sub _http_response_charset {
    my $res = shift;

    # 1) Look in Content-Type: charset=...
    my @ct = HTTP::Headers::Util::split_header_words($res->header('Content-Type'));
    for my $ct (reverse @ct) {
        my(undef, undef, %ct_param) = @$ct;
        if ($ct_param{charset}) {
            return $ct_param{charset};
        }
    }

    # 1.1) If there's no charset=... set and Content-Type doesn't look like text, return
    unless ( mime_is_text($ct[-1]->[0]) ) {
        return;
    }

    # decode the content with Content-Encoding etc. but not Unicode
    my $content = $res->decoded_content(charset => 'none');
    unless (defined $content) {
        return;
    }

    # 2) If it looks like HTML, look for META head tags
    # if there's already META tag scanned, @ct == 2
    if (@ct < 2 && $ct[0]->[0] eq 'text/html') {
        require HTML::HeadParser;
        my $parser = HTML::HeadParser->new;
        $parser->parse($content);
        $parser->eof;

        my @ct = HTTP::Headers::Util::split_header_words($parser->header('Content-Type'));
        my(undef, undef, %ct_param) = @{$ct[0] || []};
        if ($ct_param{charset}) {
            return $ct_param{charset};
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
    return $ct =~ m!^text/!i || $ct =~ m!^application/(.*?\+)?xml$!i;
}

1;
__END__

=head1 NAME

HTTP::Response::Charset - Adds and improves charset detectoin of HTTP::Response

=head1 SYNOPSIS

  use Encode;
  use HTTP::Response::Charset;

  my $response = $ua->get($url);
  if (my $enc = $response->charset) {
      warn "encoding is $enc";

      # This does what you want only in text/*
      my $content = $response->decoded_content(charset => $enc);

      # This would be more explicit
      my $content = decode $enc, $response->content;
  }

=head1 DESCRIPTION

HTTP::Response::Charset adds I<charset> method to HTTP::Response,
which tries to detect its charset using various ways.

=head1 HOW THIS MODULE DETECTS RESPONSE ENCODING

Here's a fallback order this module tries to look for.

=over 4

=item Content-Type header

If the response has

  Content-Type: text/html; charset=utf-8

charset is I<utf-8> obviously.

If there's no charset= set and its MIME type doesn't look like text
data (e.g. audio/mp3), $response->charset will just return undef.

=item META tag

If there's no charset= attribute in Content-Type, and if Conetnt-Type
looks like HTML (i.e. I<text/html>), this module will scan HTML head
tags for:

  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />

Actually, META tag values like this are already scanned by
L<HTML::HeadParser> inside LWP::UserAgent automatically unless you
call I<parse_head> to set it to 0.

=item UTF BOM detection

If there's an UTF BOM set in the response body, this module
auto-detects the encoding by recognizing the BOM.

=item XML declaration

If the response looks like XML, this module will scan response body
looking for XML declaration like:

  <?xml version="1.0" encoding="euc-jp"?>

to get the encoding.

=item Encode::Detect

If Encode::Detect module is installed, this module tries to
auto-detect the encoding using its response body as a test data.

=back

=head1 METHODS

=over 4

=item charset

  $charset = $response->charset;

returns charset of HTTP response body. If the response doesn't look
like reasonable text data, or when this module fails to detect the
charset, returns undef.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::Response>, L<HTML::HeadParser>, L<LWP::UserAgent>, L<Encode::Detect>, L<http://use.perl.org/~miyagawa/journal/31250>

=cut
