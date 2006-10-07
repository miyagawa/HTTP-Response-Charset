use Test::Base;
use HTTP::Response::Charset;
use LWP::UserAgent;

plan skip_all => "TEST_ONLINE isn't set" unless $ENV{TEST_ONLINE};

my @seeds = (
    "http://del.icio.us/rss/popular",
    "http://b.hatena.ne.jp/entrylist?mode=rss&sort=hot&threshold=3",
);

my @urls;
my $ua = LWP::UserAgent->new;
for my $seed (@seeds) {
    my $content = $ua->get($seed)->content;
    while ($content =~ /<item rdf:about="(.*?)"/g) {
        push @urls, $1;
    }
}

plan tests => 1 * @urls;

for my $url (@urls) {
    my $res = $ua->get($url);
    my $charset = $res->charset;
    ok $charset, "$url ($charset)";
}
