#! /usr/bin/perl -w
# MD5: 8fce79d3c2a01a6828927297bf14c5a4
# TEST: ./rwsettool --mask=66 ../../tests/set2-v6.set | ./rwsetcat

use strict;
use SiLKTests;

my $rwsettool = check_silk_app('rwsettool');
my $rwsetcat = check_silk_app('rwsetcat');
my %file;
$file{v6set2} = get_data_or_exit77('v6set2');
check_features(qw(ipset_v6));
my $cmd = "$rwsettool --mask=66 $file{v6set2} | $rwsetcat";
my $md5 = "8fce79d3c2a01a6828927297bf14c5a4";

check_md5_output($md5, $cmd);
