#! /usr/bin/perl -w
# MD5: 796448848fa25365cd3500772b9a9649
# TEST: ./rwsort --field=9,1 --output-path=stdout ../../tests/data.rwf | ../rwcat/rwcat --compression-method=none --byte-order=little --ipv4-output

use strict;
use SiLKTests;

my $rwsort = check_silk_app('rwsort');
my $rwcat = check_silk_app('rwcat');
my %file;
$file{data} = get_data_or_exit77('data');
my $cmd = "$rwsort --field=9,1 --output-path=stdout $file{data} | $rwcat --compression-method=none --byte-order=little --ipv4-output";
my $md5 = "796448848fa25365cd3500772b9a9649";

check_md5_output($md5, $cmd);
