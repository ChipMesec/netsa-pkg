#! /usr/bin/perl -w
# MD5: fbfaee939e8e5d8c7f681872bed96b9d
# TEST: ./rwfilter --bytes-per-packet=39-60 --pass=stdout ../../tests/data.rwf | ../rwcat/rwcat --compression-method=none --byte-order=little --ipv4-output

use strict;
use SiLKTests;

my $rwfilter = check_silk_app('rwfilter');
my $rwcat = check_silk_app('rwcat');
my %file;
$file{data} = get_data_or_exit77('data');
my $cmd = "$rwfilter --bytes-per-packet=39-60 --pass=stdout $file{data} | $rwcat --compression-method=none --byte-order=little --ipv4-output";
my $md5 = "fbfaee939e8e5d8c7f681872bed96b9d";

check_md5_output($md5, $cmd);
