#! /usr/bin/perl -w
# MD5: 97f1cb331a5f21c440c68ef8f0b011e6
# TEST: ./rwsort --fields=class,type,sensor ../../tests/data.rwf | ../rwcat/rwcat --compression-method=none --byte-order=little --ipv4-output

use strict;
use SiLKTests;

my $rwsort = check_silk_app('rwsort');
my $rwcat = check_silk_app('rwcat');
my %file;
$file{data} = get_data_or_exit77('data');
my $cmd = "$rwsort --fields=class,type,sensor $file{data} | $rwcat --compression-method=none --byte-order=little --ipv4-output";
my $md5 = "97f1cb331a5f21c440c68ef8f0b011e6";

check_md5_output($md5, $cmd);
