#! /usr/bin/perl -w
# MD5: 712eb28894d950c9bacaa1855f2d67a1
# TEST: ./rwstats --fields=scc --values=sip-distinct --percentage=1 ../../tests/data-v6.rwf

use strict;
use SiLKTests;

my $rwstats = check_silk_app('rwstats');
my %file;
$file{v6data} = get_data_or_exit77('v6data');
$file{v6_fake_cc} = get_data_or_exit77('v6_fake_cc');
$ENV{SILK_COUNTRY_CODES} = "$SiLKTests::PWD/$file{v6_fake_cc}";
my $cmd = "$rwstats --fields=scc --values=sip-distinct --percentage=1 $file{v6data}";
my $md5 = "712eb28894d950c9bacaa1855f2d67a1";

check_md5_output($md5, $cmd);
