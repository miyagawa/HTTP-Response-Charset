use Test::Base;
use HTTP::Response::Charset;
use LWP::UserAgent;

plan skip_all => "TEST_ONLINE isn't set" unless $ENV{TEST_ONLINE};

filters { url => 'chomp', charset => 'chomp' };
plan tests => 1 * blocks;

my $ua = LWP::UserAgent->new;

run {
    my $block = shift;
    my $res   = $ua->get($block->url);
    is $res->charset, $block->charset, $block->name;
}

__END__

=== Content-Type:
--- url
http://www.msn.com/
--- charset
utf-8

=== Content-Type:
--- url
http://www.yahoo.co.jp/
--- charset
euc-jp

=== gif should be undef
--- url
http://www.google.co.jp/intl/ja_jp/images/logo.gif
--- charset eval
undef

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
euc-jp

=== Detectable utf-8 data
--- url
http://plagger.org/HTTP-Response-Charset/utf8.txt
--- charset
UTF-8
