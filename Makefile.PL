use inc::Module::Install;
name 'HTTP-Response-Charset';
all_from 'lib/HTTP/Response/Charset.pm';

requires 'LWP';

feature 'Auto-Detect encoding', [
    -default => 0,
    recommends('Encode::Detect', 0),
];

build_requires 'Test::More';
use_test_base;

auto_include;
WriteAll;
