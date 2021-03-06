#! /usr/bin/perl -w
# MD5: 6acc4b5d8569198f2f414125d6239dfd
# TEST: ./rwstats --fields=dport --values=bytes --count=20 --top ../../tests/data-v6.rwf ../../tests/data-v6.rwf ../../tests/empty.rwf

use strict;
use SiLKTests;

my $rwstats = check_silk_app('rwstats');
my %file;
$file{v6data} = get_data_or_exit77('v6data');
$file{empty} = get_data_or_exit77('empty');
check_features(qw(ipv6));
my $cmd = "$rwstats --fields=dport --values=bytes --count=20 --top $file{v6data} $file{v6data} $file{empty}";
my $md5 = "6acc4b5d8569198f2f414125d6239dfd";

check_md5_output($md5, $cmd);
