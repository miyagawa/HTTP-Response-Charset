use Test::Base;
use HTTP::Response::Charset;
use LWP::UserAgent;

plan skip_all => "TEST_ONLINE isn't set" unless $ENV{TEST_ONLINE};
filters { url => 'chomp', charset => 'chomp' };
plan tests => 3 * blocks;

my $ua = LWP::UserAgent->new;

run {
    my $block = shift;
    my $res   = $ua->get($block->url);
    is $res->charset, $block->charset, $block->name;

 SKIP: {
        skip "don't test decoded_content", 2 if $block->skip_decode;
        my $body = $res->decoded_content(charset => $res->charset);
        ok utf8::is_utf8($body);
        unlike $body, qr/[\x{80}-\x{ff}]/, "no mis-decoded latin-1 range characters";
    }
}

__END__

=== Content-Type:
--- url
http://www.msn.com/
--- charset
utf-8
--- skip_decode
MSN site might contain Spanish latin characters, eh.

=== Content-Type:
--- url
http://www.yahoo.co.jp/
--- charset
euc-jp

=== Content-Type:
--- url
http://www.google.co.jp/
--- charset
Shift_JIS

=== gif should be undef
--- url
http://www.google.co.jp/intl/ja_jp/images/logo.gif
--- charset eval
undef
--- skip_decode
It's a GIF image.

=== No charset in Content-Type, but in META
--- url
http://www.asahi.com/
--- charset
EUC-JP

=== No charset in Content-Type, but in META
--- url
http://www.yahoo.com/
--- charset
UTF-8

=== UTF BOM
--- url
http://plagger.org/HTTP-Response-Charset/utf16-bom.txt
--- charset
UTF-16BE

=== XML declaration
--- url
http://plagger.org/HTTP-Response-Charset/foo.xml
--- charset
utf-8
--- skip_decode
XXX decode_content() doesn't decode "application/xml".

=== Detectable utf-8 data
--- url
http://plagger.org/HTTP-Response-Charset/utf8.txt
--- charset
UTF-8
