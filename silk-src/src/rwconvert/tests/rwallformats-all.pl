#! /usr/bin/perl -w
# MD5: multiple
# TEST: ../rwfilter/rwfilter --stime=2009/02/13:20:00-2009/02/13:20 --sensor=S2 --proto=6 --aport=80,8080,443 --pass=stdout ../../tests/data.rwf | ./rwallformats --no-invocation --basename=/tmp/sk-teststmp && md5 /tmp/sk-teststmp*

use strict;
use SiLKTests;
use File::Find;

# name of this script
my $NAME = $0;
$NAME =~ s,.*/,,;

my $rwallformats = check_silk_app('rwallformats');
my $rwfilter = check_silk_app('rwfilter');
my $rwfileinfo = check_silk_app('rwfileinfo');
my %file;
$file{data} = get_data_or_exit77('data');

my $base_name = 'sk-teststmp';

# create our tempdir
my $tmpdir = make_tempdir();

my $cmd = "$rwfilter --stime=2009/02/13:20:00-2009/02/13:20 --sensor=S2 --proto=6 --aport=80,8080,443 --pass=stdout $file{data} | $rwallformats --no-invocation --basename='$tmpdir/$base_name'";
if (!check_exit_status($cmd)) {
    exit 1;
}

# get list of expected MD5s for each file from the end of this file;
# some files have multiple checksums due to differences in LZO
my %checksums;
while (<DATA>) {
    next unless /\w/;
    next if /^\#/;
    my ($expect, $tail_name) = split " ";
    if (exists $checksums{$tail_name}) {
        push @{$checksums{$tail_name}}, $expect;
    }
    elsif (!$SiLKTests::SK_ENABLE_ZLIB && $tail_name =~ /-c1-/) {
        # skip
    }
    elsif (!$SiLKTests::SK_ENABLE_LZO && $tail_name =~ /-c2-/) {
        # skip
    }
    else {
        $checksums{$tail_name} = [$expect];
    }
}

# array to store names of files that do not match
my @mismatch;
# array to store names of files that are unknown to this script
my @unknown;

# find the files in the data directory and compare their MD5 hashes
File::Find::find({wanted => \&check_file, no_chdir => 1}, $tmpdir);

# print names of first few files that don't match
if (@mismatch) {
    my $max = 4;
    if (@mismatch == 1) {
        die "$NAME: Found 1 checksum miss: @mismatch\n";
    }
    elsif (@mismatch <= $max) {
        die("$NAME: Found ", scalar(@mismatch), " checksum misses: ",
            join(", ", @mismatch), "\n");
    }
    else {
        die("$NAME: Found ", scalar(@mismatch), " checksum misses: ",
            join(", ", @mismatch[0..$max], "..."), "\n");
    }
}

# print names of unknown files
if (@unknown) {
    my $max = 2;
    if (@unknown == 1) {
        die "$NAME: Found 1 unknown file: @unknown\n";
    }
    elsif (@unknown <= $max) {
        die("$NAME: Found ", scalar(@unknown), " unknown files: ",
            join(", ", @unknown), "\n");
    }
    else {
        die("$NAME: Found ", scalar(@unknown), " unknown files: ",
            join(", ", @unknown[0..$max], "..."), "\n");
    }
}

# print names of files we did not find
if (keys %checksums) {
    my @missing = keys %checksums;
    my $max = 2;
    if (@missing == 1) {
        die "$NAME: There is 1 missing file: @missing\n";
    }
    elsif (@missing <= $max) {
        die("$NAME: There are ", scalar(@missing), " missing files: ",
            join(", ", @missing), "\n");
    }
    else {
        die("$NAME: There are ", scalar(@missing), " missing files: ",
            join(", ", @missing[0..$max], "..."), "\n");
    }
}

# successful!
exit 0;


# This function is called by File::Find::find.  The full path to the
# file is in the $_ variable.
#
# The function computes the MD5 of each file and compares it to the
# expected value; if the values do not match, it puts the file name
# into the @mismatch array
sub check_file
{
    # skip anything that is not a file
    return unless -f $_;
    return if m,/-silktests-$,;
    my $path = $_;
    my $tail_name = $_;
    # set $tail_name to be the varying part of the filename; that is,
    # remove the directory and base_name
    $tail_name =~ s,^$tmpdir/$base_name-,,;
    unless (exists $checksums{$tail_name}) {
        push @unknown, $path;
        return;
    }
    my @sums = @{$checksums{$tail_name}};
    delete $checksums{$tail_name};

    my $md5;
    compute_md5(\$md5, "cat $path", 0);
    return if grep {$_ eq $md5} @sums;
    push @mismatch, $tail_name;
}


__DATA__
b44a4d16273f868f907b081519eacb0c  FT_FLOWCAP-v2-c0-B.dat
aad19fce22233c7766afcb5bacc72148  FT_FLOWCAP-v2-c0-L.dat
62d46f91eec4f70bac9cc5dfe0882714  FT_FLOWCAP-v2-c1-B.dat
735b483a42705c8ed0338290af7058fd  FT_FLOWCAP-v2-c1-L.dat
17328ebc0908190bd40d55f25bc23dc6  FT_FLOWCAP-v2-c2-B.dat
17452fc1de6627ec5bee7c9943bd08b3  FT_FLOWCAP-v2-c2-L.dat
cee1b1f74822b31a7441a8211fa5bfed  FT_FLOWCAP-v3-c0-B.dat
a93c68d3143fe1f5c341f56ab860492b  FT_FLOWCAP-v3-c0-L.dat
86dca7d5924c99c676f2613b9a655fdc  FT_FLOWCAP-v3-c1-B.dat
ffe123fdb7dd8e01099575c3f9219ba3  FT_FLOWCAP-v3-c1-L.dat
2aab9a2a193d09ac293e5a60c0853a73  FT_FLOWCAP-v3-c2-B.dat
085b796186e4392ff8df1436bf5b57f0  FT_FLOWCAP-v3-c2-L.dat
ca48fd33ad7dd52b39b2fd7845c5068c  FT_FLOWCAP-v4-c0-B.dat
be8884450fa255feafb1c29237543abe  FT_FLOWCAP-v4-c0-L.dat
c18e37c1d921c4085a9a468c034d4cec  FT_FLOWCAP-v4-c1-B.dat
a816fd63f0e0679318620f6df349ff1a  FT_FLOWCAP-v4-c1-L.dat
cc5788bf9bd9170c8e1866133b9db791  FT_FLOWCAP-v4-c2-B.dat
7268776400d7f2e33b9be03dd119a989  FT_FLOWCAP-v4-c2-L.dat
7528be67c52e6f0dd5752ef39d9a8c8e  FT_FLOWCAP-v5-c0-B.dat
a85ad2f2bdb42130027602e743bdc04c  FT_FLOWCAP-v5-c0-L.dat
adb12ec96e46e3d7afd7cbb8dc2b0260  FT_FLOWCAP-v5-c1-B.dat
345a487a83ff21b06dd5c4b50446998a  FT_FLOWCAP-v5-c1-L.dat
375dbf3a0b1d7eb32d2873405ed78f20  FT_FLOWCAP-v5-c2-B.dat
f52996762d83f050fe0e95bbb47c0a16  FT_FLOWCAP-v5-c2-L.dat
c1cc1ca72b1732d6ffb2f2c2085d4c89  FT_FLOWCAP-v6-c0-B.dat
02580d776eb78efbc269641247589afd  FT_FLOWCAP-v6-c0-L.dat
259634b5542115cd8fb92ff156eaca2c  FT_FLOWCAP-v6-c1-B.dat
16c8f6e3d0792de285a86af6b00ed723  FT_FLOWCAP-v6-c1-L.dat
8cf761c5a5f90a5ee76e2302d61946c4  FT_FLOWCAP-v6-c2-B.dat
64329ca995c82e4f2df92af5338c4693  FT_FLOWCAP-v6-c2-L.dat
4a50279ac5644e9303abed48e86932e9  FT_RWAUGMENTED-v1-c0-B.dat
3bf9a754b721f9baed5430524a81367c  FT_RWAUGMENTED-v1-c0-L.dat
a5e5d3717c3ff3392677b15620167b9f  FT_RWAUGMENTED-v1-c1-B.dat
45cac95bc7c791923aab9feaabfa2c5b  FT_RWAUGMENTED-v1-c1-L.dat
b1f2ef65432af17c8c23eae012e5e677  FT_RWAUGMENTED-v1-c2-B.dat
8055ba43f57bccb4237d21abd815949b  FT_RWAUGMENTED-v1-c2-L.dat
373b4efb3dcd689d43bd1a872d8a0b82  FT_RWAUGMENTED-v2-c0-B.dat
e49b4d08689b220153101d6a306fa144  FT_RWAUGMENTED-v2-c0-L.dat
cd2058d07fdf08190ddd1ba70dc9ed19  FT_RWAUGMENTED-v2-c1-B.dat
49476b3038a4dec8aad8de2bb731d2e9  FT_RWAUGMENTED-v2-c1-L.dat
42377ff91107814405349029e54c96a5  FT_RWAUGMENTED-v2-c2-B.dat
f21bcd9349a304f81195f947b151880b  FT_RWAUGMENTED-v2-c2-L.dat
b2bd70fb60cfcb7f61e928508b2fcbb0  FT_RWAUGMENTED-v3-c0-B.dat
dd3828107a232b67e074d3b2883d2ca1  FT_RWAUGMENTED-v3-c0-L.dat
564cadb0881704e57e641acdca8d2505  FT_RWAUGMENTED-v3-c1-B.dat
55febe0cad038fc447683285a22dffda  FT_RWAUGMENTED-v3-c1-L.dat
028414eca3693c58658c21a5d74a0756  FT_RWAUGMENTED-v3-c2-B.dat
5b3da2eb1dbb9720ae439bbaaaa8d2d7  FT_RWAUGMENTED-v3-c2-L.dat
262f51d3ae0f756e0127aa08538519b1  FT_RWAUGMENTED-v4-c0-B.dat
144aba6d77cd68ea8370460f74a4461c  FT_RWAUGMENTED-v4-c0-L.dat
92093094295a885840f97b1c836ea23d  FT_RWAUGMENTED-v4-c1-B.dat
0c76232bc7fdb51a19d95ccec8677d18  FT_RWAUGMENTED-v4-c1-L.dat
15e7a96c911a2c0a7c369a62612d4ce0  FT_RWAUGMENTED-v4-c2-B.dat
345545ae3004e0db2b2a8f352e079876  FT_RWAUGMENTED-v4-c2-L.dat
a837739733c2ff3df2148bb5cd4947af  FT_RWAUGMENTED-v5-c0-B.dat
d2480d6252e5efe1ec04b1a1bde56241  FT_RWAUGMENTED-v5-c0-L.dat
df4441021aaf12ce64736a4bce232359  FT_RWAUGMENTED-v5-c1-B.dat
0faa9c6d01d0a335f94dcc6aabfac87d  FT_RWAUGMENTED-v5-c1-L.dat
4fe6788bdd83da5e25723649ace4aca4  FT_RWAUGMENTED-v5-c2-B.dat
8da2469163cd8f18965ad1cccfedb138  FT_RWAUGMENTED-v5-c2-L.dat
98f941dd108eb9adb6cd2345e84f3446  FT_RWAUGROUTING-v1-c0-B.dat
142535ea5803b315fe462c577f489981  FT_RWAUGROUTING-v1-c0-L.dat
385a009413348bd9907bc4ee9b42971d  FT_RWAUGROUTING-v1-c1-B.dat
9e1a77905d37ab7b0b09e0451c8957ba  FT_RWAUGROUTING-v1-c1-L.dat
f0345fe39fa5ba8c2850e1d0fc7e3512  FT_RWAUGROUTING-v1-c2-B.dat
b2ce0a2060dd7394e18e44ab8479739d  FT_RWAUGROUTING-v1-c2-L.dat
6c15e70f39c472ce767cb980b60f0906  FT_RWAUGROUTING-v2-c0-B.dat
75399a83966d3aaee25fab55e6880670  FT_RWAUGROUTING-v2-c0-L.dat
83c2f84eff7b0d9bf60d2ce8c754cf0b  FT_RWAUGROUTING-v2-c1-B.dat
6378188823a34aaf9e410ec3ebca6662  FT_RWAUGROUTING-v2-c1-L.dat
fee5b7e3606874f0547bf24980cec47e  FT_RWAUGROUTING-v2-c2-B.dat
b0e1615a33b13a784c88fe4bc5d4760d  FT_RWAUGROUTING-v2-c2-L.dat
38de6be29e51e2ae9612ad38ad13c38d  FT_RWAUGROUTING-v3-c0-B.dat
f6de88739278985c7b8f3b4e3b359d0f  FT_RWAUGROUTING-v3-c0-L.dat
c4ff7dc4cb28933647ca1ad9a2383850  FT_RWAUGROUTING-v3-c1-B.dat
bcfd975c66e9166a95b28b76cd1c49a9  FT_RWAUGROUTING-v3-c1-L.dat
2b2187ed21d638f88432e31441a9b8be  FT_RWAUGROUTING-v3-c2-B.dat
af234bd2185ae67b6ee988bf7b3ffb25  FT_RWAUGROUTING-v3-c2-L.dat
c971232239be750b0ce8ef6078955f9a  FT_RWAUGROUTING-v4-c0-B.dat
bac0c79592ffa00c6cfe37af3aee49a6  FT_RWAUGROUTING-v4-c0-L.dat
053445f125f46dc694c60bb8981f7b92  FT_RWAUGROUTING-v4-c1-B.dat
ed5bdbdddf969a7717cc6c4e29d6b1a7  FT_RWAUGROUTING-v4-c1-L.dat
1958a0255faea25ff0309ac0c33f2e6f  FT_RWAUGROUTING-v4-c2-B.dat
378a8c3a4ce5507ff77ed4205eb2e1b9  FT_RWAUGROUTING-v4-c2-L.dat
f5eb6d15777dd5ce35a31b5869f0b3bc  FT_RWAUGROUTING-v5-c0-B.dat
0ccdac22beb624a192afca1b1dbb6e48  FT_RWAUGROUTING-v5-c0-L.dat
1f927fbb39227e6787d8d5c9d980fb89  FT_RWAUGROUTING-v5-c1-B.dat
9327907535e2f22f3be63ac80bb50c6e  FT_RWAUGROUTING-v5-c1-L.dat
c280bc817bd45b18a4d215c6a42ca6d8  FT_RWAUGROUTING-v5-c2-B.dat
040ee413492170a753c1bc77d98c34c6  FT_RWAUGROUTING-v5-c2-L.dat
149c0f889c54d264053645ed0f02931a  FT_RWAUGSNMPOUT-v1-c0-B.dat
0cd1a08bdc4ddc2aac2192a84d7141d9  FT_RWAUGSNMPOUT-v1-c0-L.dat
7b252a5581fd720576dd48b707720c4a  FT_RWAUGSNMPOUT-v1-c1-B.dat
0753e9733faa189a22f75f7190a5e29e  FT_RWAUGSNMPOUT-v1-c1-L.dat
d2956ea1e10a511257265490d46cdec0  FT_RWAUGSNMPOUT-v1-c2-B.dat
5d3b367607de68d1a2de072bdecfb870  FT_RWAUGSNMPOUT-v1-c2-L.dat
ae2efb2041e4b72ef737de7c22a0018d  FT_RWAUGSNMPOUT-v2-c0-B.dat
d736603959b74a839365489823f37354  FT_RWAUGSNMPOUT-v2-c0-L.dat
3a7a9ee77c5572e850274c82d2caa238  FT_RWAUGSNMPOUT-v2-c1-B.dat
adc9b15e3e734d3786172a192b36ad22  FT_RWAUGSNMPOUT-v2-c1-L.dat
85ab41120bc52410764b37d5331e0df7  FT_RWAUGSNMPOUT-v2-c2-B.dat
d7d2d6dfd254167b8c866bea1d713340  FT_RWAUGSNMPOUT-v2-c2-L.dat
a3bd51c268884138d6264aaa648fb345  FT_RWAUGSNMPOUT-v3-c0-B.dat
3143664e6fa8a9f234d1aad9af982ece  FT_RWAUGSNMPOUT-v3-c0-L.dat
c5896cb89ebb0f8f2d0283beb8f870f6  FT_RWAUGSNMPOUT-v3-c1-B.dat
96ddce6ce8f6c771813c37e25ecd7823  FT_RWAUGSNMPOUT-v3-c1-L.dat
e9b386334dcdbf368301499546d1ac21  FT_RWAUGSNMPOUT-v3-c2-B.dat
2e42052b89abfb6807e28bca0c5773f6  FT_RWAUGSNMPOUT-v3-c2-L.dat
2c877ee05351789df6aa8059311278c1  FT_RWAUGSNMPOUT-v4-c0-B.dat
8bd3676ddb668cb8024ef9a8dc2bb2f3  FT_RWAUGSNMPOUT-v4-c0-L.dat
5d42754bbf97415a1c20954b4416e615  FT_RWAUGSNMPOUT-v4-c1-B.dat
e3e4ca6136c8541600b1178c508dde73  FT_RWAUGSNMPOUT-v4-c1-L.dat
28ff462463d46cdf67eae9d1c4cab296  FT_RWAUGSNMPOUT-v4-c2-B.dat
eb30d1b37ef7b04f0a019339e890d1a4  FT_RWAUGSNMPOUT-v4-c2-L.dat
518c0691f788ef76fb71fe58d3d921b3  FT_RWAUGSNMPOUT-v5-c0-B.dat
0fe6d5e27c443f63a5a31e7045189e19  FT_RWAUGSNMPOUT-v5-c0-L.dat
d4b8d59f94c25fb0ed1c75c5ffd333a1  FT_RWAUGSNMPOUT-v5-c1-B.dat
34ebc0473675b006a1c324276b5bf40c  FT_RWAUGSNMPOUT-v5-c1-L.dat
9ff94772e1145cd86e74d6097284c86a  FT_RWAUGSNMPOUT-v5-c2-B.dat
56620fa7b835ef1a9259876be4a9d5c5  FT_RWAUGSNMPOUT-v5-c2-L.dat
3e8a44d3508c1759901f66681433b28a  FT_RWAUGWEB-v1-c0-B.dat
242d72f8797f1bfd645f95d0863dda01  FT_RWAUGWEB-v1-c0-L.dat
258e9e083d17f50ff5254e768f8ae1b3  FT_RWAUGWEB-v1-c1-B.dat
4d51c8409541472060562b96e0b88b3d  FT_RWAUGWEB-v1-c1-L.dat
2af82b075b071d77133155e417a7838f  FT_RWAUGWEB-v1-c2-B.dat
fc29b6b2b7d8073abeb4f2e44b16e16a  FT_RWAUGWEB-v1-c2-L.dat
fb8842cf8fc017d74ddf481bcfeccc3c  FT_RWAUGWEB-v2-c0-B.dat
10a7545e53e6359186ec43e9625911df  FT_RWAUGWEB-v2-c0-L.dat
9e5906f38d5ac464bce779618b26adac  FT_RWAUGWEB-v2-c1-B.dat
1af8a48b20bb309da7f099535a02faad  FT_RWAUGWEB-v2-c1-L.dat
0db77a6c2e5d9503c5150656b19b2dc4  FT_RWAUGWEB-v2-c2-B.dat
147f54af0fe2c71c574a541e41caba89  FT_RWAUGWEB-v2-c2-L.dat
0dbcf4148f9ef1d5134b60032d8f955c  FT_RWAUGWEB-v3-c0-B.dat
1b60b8c8a9d5d7208956e4b0a0e65c50  FT_RWAUGWEB-v3-c0-L.dat
8917f6d3683d6a8eea94bf2c24d16387  FT_RWAUGWEB-v3-c1-B.dat
56e77c0ddee1e255c861b7c404447878  FT_RWAUGWEB-v3-c1-L.dat
3369dd55203b75c770a2b6a6b7c3ec54  FT_RWAUGWEB-v3-c2-B.dat
1701fbb1ac43031ceb4ffe3828b48c05  FT_RWAUGWEB-v3-c2-L.dat
d6b90b5d7a3c9a97a03d0e2c9f583f42  FT_RWAUGWEB-v4-c0-B.dat
539b181b898acd59e463ff779a7c059e  FT_RWAUGWEB-v4-c0-L.dat
8d7523adafeb5364c66eba36dca77c80  FT_RWAUGWEB-v4-c1-B.dat
f60be431bbee22799abe42c0990ff8b4  FT_RWAUGWEB-v4-c1-L.dat
6bd8f17373a7eb9b203123618435058b  FT_RWAUGWEB-v4-c2-B.dat
d899792cdebb3ec7017326ea9c07ce81  FT_RWAUGWEB-v4-c2-L.dat
1ff83fc66e0f959967fbe7fc94068071  FT_RWAUGWEB-v5-c0-B.dat
f958d7a2d8f5522802a714934a0fc38e  FT_RWAUGWEB-v5-c0-L.dat
be5e60a075f8371045a66157b34271f0  FT_RWAUGWEB-v5-c1-B.dat
a4609989704d4904e94ad83ed79b55d0  FT_RWAUGWEB-v5-c1-L.dat
84a277ff0adebe0d72221f3c03770605  FT_RWAUGWEB-v5-c2-B.dat
de709ae76c4326f845b4f9c908a93f93  FT_RWAUGWEB-v5-c2-L.dat
6986dfb3ca505b391d5f9fa9be1cda30  FT_RWFILTER-v1-c0-B.dat
cea530e72ae2b25052dbc5e96d9d0aa5  FT_RWFILTER-v1-c0-L.dat
091cf3a98cf8c1ec3d30e1d3f4936b7a  FT_RWFILTER-v1-c1-B.dat
78ca148b710d9cb00105aa4f8c0a1cc1  FT_RWFILTER-v1-c1-L.dat
f714e7a5380e16cb1fd7cb81d7c1a20b  FT_RWFILTER-v1-c2-B.dat
103f8d51add43fe1cf1f1e6e5ec0b765  FT_RWFILTER-v1-c2-L.dat
c1fc3a70265e72fbebe417ef8d675093  FT_RWFILTER-v2-c0-B.dat
d64003c3c6d3abed3c0df4db0529fd7b  FT_RWFILTER-v2-c0-L.dat
26c4e838cdeb201d791727e112fb96d8  FT_RWFILTER-v2-c1-B.dat
3987ba7f0b485dce4b65ff0d6fbe2d2a  FT_RWFILTER-v2-c1-L.dat
264217bbf4768eb9b5a7b2304ed71c21  FT_RWFILTER-v2-c2-B.dat
9838648a479719d6c891832cb8b8d42d  FT_RWFILTER-v2-c2-L.dat
82e819749752c149e6517bcf4c8c2e61  FT_RWFILTER-v3-c0-B.dat
0fd4b025dcb2d0adcdcc86b79eba6bb0  FT_RWFILTER-v3-c0-L.dat
29c6934e0d4cd6df4a34cb1225080257  FT_RWFILTER-v3-c1-B.dat
0ecc5cd71f91388ca3e8565046ad7e73  FT_RWFILTER-v3-c1-L.dat
cc3bc63da36bab23aeaaa58ee69d54d0  FT_RWFILTER-v3-c2-B.dat
fab739247996547627ce22e31d4bac89  FT_RWFILTER-v3-c2-L.dat
4d67c6ff508ee230c297195531fdf9a6  FT_RWFILTER-v4-c0-B.dat
8e0dccab479e7f961961e5f41155c255  FT_RWFILTER-v4-c0-L.dat
2aa64ffe5dc55c6808f1028961bf1fff  FT_RWFILTER-v4-c1-B.dat
ebb415f850e0831a0b0fb986382e10d9  FT_RWFILTER-v4-c1-L.dat
e96b80f6ca5903cedea61d001bec5008  FT_RWFILTER-v4-c2-B.dat
dc5d2ffe74ff1b7ec6843a63abc23536  FT_RWFILTER-v4-c2-L.dat
e5b1e8db7a40a8f0ddb1982168a8181f  FT_RWFILTER-v5-c0-B.dat
8b6c7f61e15b9226e1ceaf899aed253e  FT_RWFILTER-v5-c0-L.dat
1e17cf9578609c27e1b9ca574caa4d9a  FT_RWFILTER-v5-c1-B.dat
7cde0994c0758c2240b2b63b7d312a1f  FT_RWFILTER-v5-c1-L.dat
3ca1de6d51d1b892d2e061ae08792cae  FT_RWFILTER-v5-c2-B.dat
5e00a4bde82f084cf12bd7f179a33d36  FT_RWFILTER-v5-c2-L.dat
7dcaa52987c38d63b84a5b7c5ce33941  FT_RWGENERIC-v0-c0-B.dat
fd656c86111fe47d0cbf13ed392bed67  FT_RWGENERIC-v0-c0-L.dat
27893661440063991af0c88614fed945  FT_RWGENERIC-v0-c1-B.dat
f3122e81b9b23638187aa3376cc65ac5  FT_RWGENERIC-v0-c1-L.dat
5f7e5c8de1a6266b77f42d0ac4d10d73  FT_RWGENERIC-v0-c2-B.dat
bc415d8b1b19e9390c165e8d35a1a6bf  FT_RWGENERIC-v0-c2-L.dat
513984dc560dde040158a1971320680c  FT_RWGENERIC-v1-c0-B.dat
1640b04c5156437dcb9c3f7395fe98c1  FT_RWGENERIC-v1-c0-L.dat
099d36f38bfebec3ec35952b327ce13c  FT_RWGENERIC-v1-c1-B.dat
e3d4609ba3e3729f4f0d7b7335f3ed44  FT_RWGENERIC-v1-c1-L.dat
4ba13eb429dfcc94d73386c3215249cd  FT_RWGENERIC-v1-c2-B.dat
d51f3cb16cb0830019bfca4b1cd70247  FT_RWGENERIC-v1-c2-L.dat
947f1421d65b62e736c08d7a79f0ff42  FT_RWGENERIC-v2-c0-B.dat
d05b78204f16fb235fc150b1be56d0b7  FT_RWGENERIC-v2-c0-L.dat
a490c651a771b764ab218a6bb5e3a6e8  FT_RWGENERIC-v2-c1-B.dat
35742b3af08059c433ad65ae8e295105  FT_RWGENERIC-v2-c1-L.dat
4c1ed99c498491657b6105525b21ab67  FT_RWGENERIC-v2-c2-B.dat
bf959c2fb40352f6234df8b9f3717e1f  FT_RWGENERIC-v2-c2-L.dat
d6a93bcf2a9a6020bed0835ceb646ea2  FT_RWGENERIC-v3-c0-B.dat
0f0add9723e5b1fc24330730297c1b34  FT_RWGENERIC-v3-c0-L.dat
f57e0dd0e62b5c927f117101c88caeaa  FT_RWGENERIC-v3-c1-B.dat
0e849cf5ab4fb0df06f07e614d305991  FT_RWGENERIC-v3-c1-L.dat
152de2e564e5c7177ae6defeff387bf7  FT_RWGENERIC-v3-c2-B.dat
aee6d908907c55f7c430bfb7aa5c1bcb  FT_RWGENERIC-v3-c2-L.dat
71d4e55cd818777ee5438be65f7ccac5  FT_RWGENERIC-v4-c0-B.dat
14f984703521151b77b2a63669abefe4  FT_RWGENERIC-v4-c0-L.dat
d8b9226e8477614aebbb376a78dc5576  FT_RWGENERIC-v4-c1-B.dat
8291163b094e4a2ce441446ee6d6b4d0  FT_RWGENERIC-v4-c1-L.dat
069bacaccc25fadc2e2bbd1432857d16  FT_RWGENERIC-v4-c2-B.dat
dd18b1eabe121da6f8ac7c323e504e04  FT_RWGENERIC-v4-c2-L.dat
dd89f00bd51f03caf9de1e7812108005  FT_RWGENERIC-v5-c0-B.dat
223ab374329314618fe9d8a1d2f300e8  FT_RWGENERIC-v5-c0-L.dat
0884d019bfed192007a770275cfc52a7  FT_RWGENERIC-v5-c1-B.dat
518368e2e59f58adf0d21c796c73aa7e  FT_RWGENERIC-v5-c1-L.dat
3fa208bcfe8d3aaf76111ed9d7b154a1  FT_RWGENERIC-v5-c2-B.dat
aeb77d2fcb5bbd7d8d13c48de54d36ff  FT_RWGENERIC-v5-c2-L.dat
2f9f457aa09dadb79ce6e6b9cac7aa05  FT_RWIPV6-v1-c0-B.dat
9c18ef017e67ee89fa0daabc31daa233  FT_RWIPV6-v1-c0-L.dat
699212297d2621249b08d909de8b80a3  FT_RWIPV6-v1-c1-B.dat
0dfa265492d6a1c62d78882ef32a9964  FT_RWIPV6-v1-c1-L.dat
893d07912f8754ab1f611826f93a8cfa  FT_RWIPV6-v1-c2-B.dat
9584e20a7b9641afd78422afbd81a09b  FT_RWIPV6-v1-c2-L.dat
acc4780b215db74a91c541c98811e77f  FT_RWIPV6-v2-c0-B.dat
1c69b295749a55894504e9d5d00042e5  FT_RWIPV6-v2-c0-L.dat
6ff220d018769f8caa8aa3d96b9c92e5  FT_RWIPV6-v2-c1-B.dat
2b4d41ee54c55a1dec7d0f01e4eef410  FT_RWIPV6-v2-c1-L.dat
d3f5dcce303ef4395641299a4ea316cb  FT_RWIPV6-v2-c2-B.dat
f147e9fa29126c13c715aba56df5d842  FT_RWIPV6-v2-c2-L.dat
c603a50b2fe0f71073449bb00ffdcd7b  FT_RWIPV6ROUTING-v1-c0-B.dat
5ce7f5f312d053e719a09de2bdf4dd48  FT_RWIPV6ROUTING-v1-c0-L.dat
01db8a0206495ffa9cb3853b6a263565  FT_RWIPV6ROUTING-v1-c1-B.dat
78ad670f0cf3c3d67cea0e9ceda29be4  FT_RWIPV6ROUTING-v1-c1-L.dat
f2c65c5fabba2f150acb324ebdb26b51  FT_RWIPV6ROUTING-v1-c2-B.dat
58f02ba420d0860f0f5dd860827e7d61  FT_RWIPV6ROUTING-v1-c2-L.dat
0655e3c8de4049f43adf2f9eceff540b  FT_RWIPV6ROUTING-v2-c0-B.dat
5ed32a580fcf09eefd1016f68b3eab3b  FT_RWIPV6ROUTING-v2-c0-L.dat
59aefe73f0b406ac0c5b2dae4db48aec  FT_RWIPV6ROUTING-v2-c1-B.dat
95207e7656f6e575ba0363f9db673592  FT_RWIPV6ROUTING-v2-c1-L.dat
ba749a6064c4b274960437ca1b1d11c8  FT_RWIPV6ROUTING-v2-c2-B.dat
7d0990a104def93b4350ed12bab74e69  FT_RWIPV6ROUTING-v2-c2-L.dat
df514250db00d79242f13463b7245c70  FT_RWIPV6ROUTING-v3-c0-B.dat
041296f90b30ede7da5f81d7c3864074  FT_RWIPV6ROUTING-v3-c0-L.dat
d68e6034f3621bfad96967aec9e753c9  FT_RWIPV6ROUTING-v3-c1-B.dat
f695cab19a9a761ffcf918db10d936d8  FT_RWIPV6ROUTING-v3-c1-L.dat
4d7af74d80435e84e6775f09ea41ddb6  FT_RWIPV6ROUTING-v3-c2-B.dat
aa9f2303e3c62bb5ac60e4bd404b41bf  FT_RWIPV6ROUTING-v3-c2-L.dat
63ab6740566b8c6af7d43c2948ee8e82  FT_RWNOTROUTED-v1-c0-B.dat
c0fe797de574e9d2fd85447032910ff6  FT_RWNOTROUTED-v1-c0-L.dat
d305bcb80c26979cfa5aaaa19c74530c  FT_RWNOTROUTED-v1-c1-B.dat
4d54be7afa877687d4ec504f6a3ad060  FT_RWNOTROUTED-v1-c1-L.dat
ba6c890bd067b4459ddb411bc04f547e  FT_RWNOTROUTED-v1-c2-B.dat
bf52e8553b91ac3f5eae64583c6dabb9  FT_RWNOTROUTED-v1-c2-L.dat
c68a35d9f1f8536fda5b27b7a2e7fc9b  FT_RWNOTROUTED-v2-c0-B.dat
2389313df8dab0ae4c0c732cedbb5ea1  FT_RWNOTROUTED-v2-c0-L.dat
500b1718ee443086107097de48f9ca77  FT_RWNOTROUTED-v2-c1-B.dat
8a81a6828631802676faa183ad16a117  FT_RWNOTROUTED-v2-c1-L.dat
48d90f0351183137fb0db6bb24b79a8a  FT_RWNOTROUTED-v2-c2-B.dat
e321d9f627262e931838c6df4ed0209e  FT_RWNOTROUTED-v2-c2-L.dat
8a5362f0ab8f6bcbd48463878c23c94d  FT_RWNOTROUTED-v3-c0-B.dat
b572af9ccec4743025b7c28d66cf2d2d  FT_RWNOTROUTED-v3-c0-L.dat
540025825039fae3208d91d3567881c2  FT_RWNOTROUTED-v3-c1-B.dat
68ceda0aff331556818f48f0c35e20a8  FT_RWNOTROUTED-v3-c1-L.dat
60f5962b9d2d1de58aa530934473d004  FT_RWNOTROUTED-v3-c2-B.dat
044eec2be252b10c34adc4fe32d6cfa0  FT_RWNOTROUTED-v3-c2-L.dat
72e1c54caaa54243661c0a0c1a9de78b  FT_RWNOTROUTED-v4-c0-B.dat
96f05809a0f851cd5baf40ef450e514e  FT_RWNOTROUTED-v4-c0-L.dat
da068228b2ba1390c5fa065529ed65d1  FT_RWNOTROUTED-v4-c1-B.dat
5aa97d6d58b9dbc40b0e1c4880a42cd1  FT_RWNOTROUTED-v4-c1-L.dat
342ad55b44619fa4258e9857936b3c29  FT_RWNOTROUTED-v4-c2-B.dat
ad7338ea337bcfb54177950e83f34ece  FT_RWNOTROUTED-v4-c2-L.dat
db20862725dc8c2b7ae234eb74f2e6dd  FT_RWNOTROUTED-v5-c0-B.dat
5a5fdb68fa587d361ad47ab3071a0150  FT_RWNOTROUTED-v5-c0-L.dat
152f9f6672ef4556c5b611459b6cdbee  FT_RWNOTROUTED-v5-c1-B.dat
29642a8c73b50035ca5e2b0f6fae2dd4  FT_RWNOTROUTED-v5-c1-L.dat
c1a0505018059c833fb3d1b41e0b7ce7  FT_RWNOTROUTED-v5-c2-B.dat
f8bf559b9a06dc7dd3cbeeef8c45716d  FT_RWNOTROUTED-v5-c2-L.dat
45e616c2ea42dfc32ea7f238e2e2cfe5  FT_RWROUTED-v1-c0-B.dat
82c16c2a864c206de65bc5119767dff1  FT_RWROUTED-v1-c0-L.dat
fa9d7a6c0e8267b967c128349d010392  FT_RWROUTED-v1-c1-B.dat
1a1b604369c33b30b1322353328c13e6  FT_RWROUTED-v1-c1-L.dat
2f9184009ad2b56a4df53f3d40796352  FT_RWROUTED-v1-c2-B.dat
3ce7398124bccbb727ee3ad436b4e25e  FT_RWROUTED-v1-c2-L.dat
cb581ce9f132280ca46394fdaae64e63  FT_RWROUTED-v2-c0-B.dat
5e56afa64d9351d69c2ae973d5f663ed  FT_RWROUTED-v2-c0-L.dat
576e4ce47503cf80d7992db86b99d2dc  FT_RWROUTED-v2-c1-B.dat
36493734239e466cb9c892b1864a197f  FT_RWROUTED-v2-c1-L.dat
deeddd3127643705a1fd0b50c1b8ca7b  FT_RWROUTED-v2-c2-B.dat
cbbe239c3af9e33ed6212a55b527a45e  FT_RWROUTED-v2-c2-L.dat
077f02f2ee0d4a6ec5ac3b50e231a4d2  FT_RWROUTED-v3-c0-B.dat
f3a099444867927403f4fdd06a10a8ea  FT_RWROUTED-v3-c0-L.dat
b99deaad26c4199c189ab21111d3c698  FT_RWROUTED-v3-c1-B.dat
f67ea6d04eff01384f2809999e9dda53  FT_RWROUTED-v3-c1-L.dat
5b4c3aec0f06c80a67a2d2975720d6cc  FT_RWROUTED-v3-c2-B.dat
a5b89aa73ac64b9d988e8b7d0f96a301  FT_RWROUTED-v3-c2-L.dat
f17d7d2aa5427eaff43c4fac1574857f  FT_RWROUTED-v4-c0-B.dat
5034cea9260da8a6dad733b5f7c78d5a  FT_RWROUTED-v4-c0-L.dat
9e755deb6b1aad2aebed1cec1ab39ea1  FT_RWROUTED-v4-c1-B.dat
0dd46efea48cd2d08c14ea3f6987ea1e  FT_RWROUTED-v4-c1-L.dat
a89778891e1ba5f86b2cc095465284ed  FT_RWROUTED-v4-c2-B.dat
8ed64ad91f5c7c98f8fa4e03ff8873e4  FT_RWROUTED-v4-c2-L.dat
e9e16d7a47a3ba266bc5df8584d1b88f  FT_RWROUTED-v5-c0-B.dat
e5d2153a62b3691069e49dfb15ac71b7  FT_RWROUTED-v5-c0-L.dat
53ca49143ecb4ebd9ec5513c6fe1e62e  FT_RWROUTED-v5-c1-B.dat
27bb27f62bd0bd74e4dc5c6e664fb95a  FT_RWROUTED-v5-c1-L.dat
0668ecd5cd56a9c8bd94dc92dc021123  FT_RWROUTED-v5-c2-B.dat
f946ee0f1b13a987c555f0aab85bf411  FT_RWROUTED-v5-c2-L.dat
6be74a9eff6b196a51e97dfcc8e31d0a  FT_RWSPLIT-v1-c0-B.dat
ead8c12cd4ceed70f9d1cdbde78b37de  FT_RWSPLIT-v1-c0-L.dat
11a9157a43acfc36a5d6837cdf46899c  FT_RWSPLIT-v1-c1-B.dat
db25ad2e4c631bd22a4e55b829102ba0  FT_RWSPLIT-v1-c1-L.dat
2981a349f762c728dc94d06d6db0f0a3  FT_RWSPLIT-v1-c2-B.dat
9f668bae733c50a8991ee3cec869cbed  FT_RWSPLIT-v1-c2-L.dat
d2210f9a7d15e606b4a9bdadcb05e017  FT_RWSPLIT-v2-c0-B.dat
3a796fa45a437dcb01eeb16cf0bcc6d4  FT_RWSPLIT-v2-c0-L.dat
79bd8edb052c5644d92f402a13805f68  FT_RWSPLIT-v2-c1-B.dat
1e6bcff7d83ce045b27fcaafc305a34d  FT_RWSPLIT-v2-c1-L.dat
b933981892054094ab04faa9dceb1f34  FT_RWSPLIT-v2-c2-B.dat
104c0dee9f0dfae12ed6ec08d4fd9519  FT_RWSPLIT-v2-c2-L.dat
d43215bde7090e7badc8c9fb4f133095  FT_RWSPLIT-v3-c0-B.dat
366b18ddbd8d7d5ea7a3bcdea35cebdf  FT_RWSPLIT-v3-c0-L.dat
4a09747c160f6e23c085e2c2bcf60151  FT_RWSPLIT-v3-c1-B.dat
a76c1ef9e575c1b84030a7158d57acb2  FT_RWSPLIT-v3-c1-L.dat
22e485baeb50cee6ef7315399bd0dbf9  FT_RWSPLIT-v3-c2-B.dat
99f031786758815819964b0d42388fc2  FT_RWSPLIT-v3-c2-L.dat
6ea55e3e335e04f9b1a4a845ad7b3223  FT_RWSPLIT-v4-c0-B.dat
0fa608aacfea2014dc4556072853fdf0  FT_RWSPLIT-v4-c0-L.dat
9c9528e2f6bff9acaf3b8347d9dd2c0c  FT_RWSPLIT-v4-c1-B.dat
244f5c16ea72549132f67ae5506f02d4  FT_RWSPLIT-v4-c1-L.dat
be1126439a83f8b295fab6b355d92430  FT_RWSPLIT-v4-c2-B.dat
b1d788cec04da73ac18c0df4fc858db5  FT_RWSPLIT-v4-c2-L.dat
a4405165075cb9286a941c90bb68019d  FT_RWSPLIT-v5-c0-B.dat
cd3c855001d584165bc8ea62afa352c9  FT_RWSPLIT-v5-c0-L.dat
298e49f809f86d6d265a725383a2aa9c  FT_RWSPLIT-v5-c1-B.dat
554014f72af33a165fc5ede025f3d160  FT_RWSPLIT-v5-c1-L.dat
3690b7caf4c2e17960f8b8e3eb632c29  FT_RWSPLIT-v5-c2-B.dat
5a47281757ea51957f0b9c8d9514b9ca  FT_RWSPLIT-v5-c2-L.dat
0e1b1e8228b57886008a97cb765c331b  FT_RWWWW-v1-c0-B.dat
6c123a6c98d83c8cf317d0254c002cb6  FT_RWWWW-v1-c0-L.dat
089f3ea77e04dab201087a299f5d3ae0  FT_RWWWW-v1-c1-B.dat
4a857fcec93a5f9b283cb80b12d69f17  FT_RWWWW-v1-c1-L.dat
fa07a51f375a495e8ae5efa2ec5115fb  FT_RWWWW-v1-c2-B.dat
be8c53ead9dbe25bbe4158c87844db72  FT_RWWWW-v1-c2-L.dat
9f1f0176f53e5cc804b1bddfc2421b98  FT_RWWWW-v2-c0-B.dat
4a9b9dbc6f98dc0d5df5b9f83b1b140f  FT_RWWWW-v2-c0-L.dat
27a3e17dcc5525c9d200b4d61ae5f487  FT_RWWWW-v2-c1-B.dat
8b3b01eb20974cf574b60aec367e29e8  FT_RWWWW-v2-c1-L.dat
3237bae27c7c20ff91760dfea299b690  FT_RWWWW-v2-c2-B.dat
3e060aeb0fd815f70ccdb9a36191c73b  FT_RWWWW-v2-c2-L.dat
a726e5fc2c493da0856695a85fd11298  FT_RWWWW-v3-c0-B.dat
cfdd861442b0a4a49723d57595681bf7  FT_RWWWW-v3-c0-L.dat
7a027dd8366cf4b8d681d5a06ca37d8c  FT_RWWWW-v3-c1-B.dat
e15f6c43b9b10b6d9da58329efe12bd8  FT_RWWWW-v3-c1-L.dat
b55cb6891fcea6f5249ba629f8631e9b  FT_RWWWW-v3-c2-B.dat
abc4c8b10b22ba1277c1a04343e2a874  FT_RWWWW-v3-c2-L.dat
b67d537959ff93208eafb81469c5a09c  FT_RWWWW-v4-c0-B.dat
4c348bb299e4dd82ed24223aa0ed9a14  FT_RWWWW-v4-c0-L.dat
cd0c4dca54ac9922397da0bd398dfacd  FT_RWWWW-v4-c1-B.dat
3f406a8506b555adab4d8cd379a9d508  FT_RWWWW-v4-c1-L.dat
b0ff24fded4b760dc6fcb008761749b0  FT_RWWWW-v4-c2-B.dat
da6711570db3fcdfe2f9a9b82c6e51ff  FT_RWWWW-v4-c2-L.dat
123deb72a005b827d60a8e211a13f077  FT_RWWWW-v5-c0-B.dat
eed0098880ea791ccf34c4e1311887b4  FT_RWWWW-v5-c0-L.dat
32810191c8b2c8265b4bafc5a3d3181a  FT_RWWWW-v5-c1-B.dat
63355fc37c6141d131e5ad29a788d2f4  FT_RWWWW-v5-c1-L.dat
224fe676195b48daa49fded2045bd983  FT_RWWWW-v5-c2-B.dat
fed04907fc9b1b72e4c7c7955f491abe  FT_RWWWW-v5-c2-L.dat

# these are for LZ0 2.05
a4e0ac1c437310d6c17be507c559afeb  FT_FLOWCAP-v2-c2-B.dat
c017f5d40f061cef2f618dfd506d95bb  FT_FLOWCAP-v2-c2-L.dat
782d711b70e70ef4e31103b86201d7d1  FT_FLOWCAP-v3-c2-B.dat
0f11857a2049cded66be1ec05391861e  FT_FLOWCAP-v3-c2-L.dat
89b31c6dcd6ccc3afca8560c464b51b8  FT_FLOWCAP-v4-c2-B.dat
ef4e3a4b98833f7d58e1e2b350d4509c  FT_FLOWCAP-v4-c2-L.dat
a36dcc30de049968c726c5a072297a3e  FT_FLOWCAP-v5-c2-B.dat
c375b8a2324d17f9ab3b3e25787d89c6  FT_FLOWCAP-v5-c2-L.dat
7d6233dc312713f204419a79688b34af  FT_FLOWCAP-v6-c2-B.dat
48f8b9beda2dcfc4e126ccbe0055f4b8  FT_FLOWCAP-v6-c2-L.dat
bb68cf8288b2a886fa8834f11fb8487a  FT_RWAUGMENTED-v1-c2-B.dat
5a4b1818ff457804de2cc42a82b13648  FT_RWAUGMENTED-v1-c2-L.dat
795bb874ddd7aa5204e4cea56dbdf0f7  FT_RWAUGMENTED-v2-c2-B.dat
5471237c27e2298e8224965d4ae965ed  FT_RWAUGMENTED-v2-c2-L.dat
b6ea73eb6e88c390a8e88c24e02fd773  FT_RWAUGMENTED-v3-c2-B.dat
b492b042e977ca3e95befb60576cfc24  FT_RWAUGMENTED-v3-c2-L.dat
63db7feef7a0dc5fac87e79b9c4e8426  FT_RWAUGMENTED-v4-c2-B.dat
def543fdc6eb4a010dc615244ee798f9  FT_RWAUGMENTED-v4-c2-L.dat
ea070efc91e0c4bc635d27f7aa7db261  FT_RWAUGMENTED-v5-c2-B.dat
f0b16ae7aaf31fcae3f88e5c414298cb  FT_RWAUGMENTED-v5-c2-L.dat
b248346dd161f1086b12124c21d96fc2  FT_RWAUGROUTING-v1-c2-B.dat
d48b29f70badf448460665506cdb8105  FT_RWAUGROUTING-v1-c2-L.dat
e92eccf9e0b6e692bc800a24e7592af9  FT_RWAUGROUTING-v2-c2-B.dat
611b5eb73ff88c2d5196913c10094470  FT_RWAUGROUTING-v2-c2-L.dat
aef9494014304e7039339fc2b1ec1e7b  FT_RWAUGROUTING-v3-c2-B.dat
1536239303fb0ab51764b7b86890f122  FT_RWAUGROUTING-v3-c2-L.dat
ac1266bda8f769d8af130f999cd38b64  FT_RWAUGROUTING-v4-c2-B.dat
02cd539d7781b69ed8c8b9fa5e316665  FT_RWAUGROUTING-v4-c2-L.dat
982171f7fa917eef2ac67153037dfb23  FT_RWAUGROUTING-v4-c2-L.dat
21d7f13b1205f5f99c54bfe6456f4ff9  FT_RWAUGROUTING-v5-c2-B.dat
841880810bcb005f54720eda57ff68b5  FT_RWAUGROUTING-v5-c2-L.dat
4a64b53e543ca0404a3d86cf63f5704e  FT_RWAUGSNMPOUT-v1-c2-B.dat
e27d2d5d3f7290c0438af58887770c4f  FT_RWAUGSNMPOUT-v1-c2-L.dat
c8def06c781fd0dc54e9d2ad17761a4d  FT_RWAUGSNMPOUT-v2-c2-B.dat
c4fdd886c699a7bbfa0da43db1bbed1d  FT_RWAUGSNMPOUT-v2-c2-L.dat
81821692f45c2ebd1492be720326d12e  FT_RWAUGSNMPOUT-v3-c2-B.dat
ca5c63f9b25399502783b5a6cb638517  FT_RWAUGSNMPOUT-v3-c2-L.dat
7776dbfc6cc30f8e4d45a1a0cec825b9  FT_RWAUGSNMPOUT-v4-c2-B.dat
77517cec816e2f0595b79330e09bb3cb  FT_RWAUGSNMPOUT-v4-c2-L.dat
a418fa84e005719d291ea094d09a2ee8  FT_RWAUGSNMPOUT-v4-c2-L.dat
abb72022b214182e74a4a83f33d9e0a0  FT_RWAUGSNMPOUT-v5-c2-B.dat
735a1aaaaa731e4ca09459f27a267a06  FT_RWAUGSNMPOUT-v5-c2-L.dat
e13c9ddbf88db7c164fa35a16fd42ed4  FT_RWAUGWEB-v1-c2-B.dat
75dd3b0e091b8b47bdf8aeef273cb885  FT_RWAUGWEB-v1-c2-L.dat
8c9ceee6ea01dccef2aadb04724d93d8  FT_RWAUGWEB-v2-c2-B.dat
3395f89ec192cef4cc2c480ff2cf5655  FT_RWAUGWEB-v2-c2-L.dat
ac7dd539cfef7dd1ec1cf7a3ed09ed71  FT_RWAUGWEB-v3-c2-B.dat
22098b52166e172e4ff3dd3b041b5d2d  FT_RWAUGWEB-v3-c2-L.dat
4f726e586357bd9ad368b271088cd19b  FT_RWAUGWEB-v4-c2-B.dat
55e088874c8a13d3bd4b0fa6eff7631e  FT_RWAUGWEB-v4-c2-L.dat
617e97e4083e5cdee40ea8681ee41ba6  FT_RWAUGWEB-v5-c2-B.dat
24735d528f6caaf2472817e4fbf1dbf0  FT_RWAUGWEB-v5-c2-L.dat
175297a49afe93c8e776d326e70c1a94  FT_RWFILTER-v1-c2-B.dat
45b67cf1370043ceac3a1990b3b11523  FT_RWFILTER-v1-c2-L.dat
50f7a64b64ab8a66f990f940e79acf32  FT_RWFILTER-v1-c2-L.dat
840d91d68c7fcaffdad266ea572e070c  FT_RWFILTER-v2-c2-B.dat
4d1f6e9a0d6cf1b5257cc9da08bfac46  FT_RWFILTER-v2-c2-L.dat
4d823f4f740170e0735f873a376a6a33  FT_RWFILTER-v2-c2-L.dat
9ff9fff30a8966510a1ace5225dcb13b  FT_RWFILTER-v3-c2-B.dat
54c445ea4d0720491f9a27751c4fdf0e  FT_RWFILTER-v3-c2-L.dat
9177d1a168fb7d7f5e2bce317fb70681  FT_RWFILTER-v4-c2-B.dat
74fd5636f9e60feea81afff77de8e5c0  FT_RWFILTER-v4-c2-L.dat
b1e599acbd38297668a26111e9a1a5ae  FT_RWFILTER-v5-c2-B.dat
03f10f91b38d587d3f637957f6da6ecb  FT_RWFILTER-v5-c2-L.dat
1113491db59268294475c1f17f2a3b43  FT_RWGENERIC-v0-c2-B.dat
ed644a6334b6539162bb2666e185b6b6  FT_RWGENERIC-v0-c2-B.dat
ebb5e5cd03075df9d16c4cdedfdff201  FT_RWGENERIC-v0-c2-L.dat
03b3626ea799141bcb04f7c8bb81729e  FT_RWGENERIC-v1-c2-B.dat
3cac6c8c86141be002e09f2a64f162b3  FT_RWGENERIC-v1-c2-B.dat
565bcd86bee05b2568a8e6b032d2cfde  FT_RWGENERIC-v1-c2-L.dat
cdbb0f75a7cc26655984cde91a93fba5  FT_RWGENERIC-v1-c2-L.dat
e4a92ceb39512bf4083ad5feb50c3c51  FT_RWGENERIC-v2-c2-B.dat
2341f474272c4757a43c8af83d10d22e  FT_RWGENERIC-v2-c2-L.dat
b9eebbab145c24a5b3a9319f2c08f1b4  FT_RWGENERIC-v3-c2-B.dat
cfcbb41b0943775e67f1ae0a79899386  FT_RWGENERIC-v3-c2-L.dat
e8ddb9c4f05b74741207c9857e24ecc1  FT_RWGENERIC-v3-c2-L.dat
4002bdb8d625cec9c2a2f4ff5df53d78  FT_RWGENERIC-v4-c2-B.dat
21461364e5d98839f80ef8748187a3f3  FT_RWGENERIC-v4-c2-L.dat
3d105fb623442acef5713822e40ee1e0  FT_RWGENERIC-v4-c2-L.dat
1f5c8950a3d830662dec12e39df8178d  FT_RWGENERIC-v5-c2-B.dat
4fd0fce59fc8842d8323ed0ecd912143  FT_RWGENERIC-v5-c2-L.dat
04290bbd4e3792378f4dff4a1f5a7ffe  FT_RWIPV6-v1-c2-B.dat
120d260058331f00a70c22d9c7336436  FT_RWIPV6-v1-c2-L.dat
9fac70d8c01c31593f9aebacbe162ec2  FT_RWIPV6-v2-c2-B.dat
44173848504cbd453a2879f1fe9dc928  FT_RWIPV6-v2-c2-L.dat
5159a43177c18c05b73173404a3fa582  FT_RWIPV6ROUTING-v1-c2-B.dat
36feaefacfeae8f026d3d99c6e987331  FT_RWIPV6ROUTING-v1-c2-L.dat
ab52c004814044775ace0d261355a2c7  FT_RWIPV6ROUTING-v2-c2-B.dat
c9fb85772fa528ac9ed27e20b6790c28  FT_RWIPV6ROUTING-v2-c2-L.dat
900f4e183068efc6e799d3462995ea6a  FT_RWIPV6ROUTING-v3-c2-B.dat
12c3ca82a05a3929d25fb0375a374f38  FT_RWIPV6ROUTING-v3-c2-L.dat
83e009f3e2ccade295f10b0d059936b6  FT_RWNOTROUTED-v1-c2-B.dat
0e255acc3bed430a78f894f092db26de  FT_RWNOTROUTED-v1-c2-L.dat
1dab0016c7378a3ae899c437c098b402  FT_RWNOTROUTED-v2-c2-B.dat
e93c395441b58b1ecfc265f4fc89fca1  FT_RWNOTROUTED-v2-c2-L.dat
802cd817a803c4444a5f19c83c641efd  FT_RWNOTROUTED-v3-c2-B.dat
1f985b55009ef1537d4043f1c2c069f0  FT_RWNOTROUTED-v3-c2-L.dat
7c5ae989965d10f340d66ebcc5b34142  FT_RWNOTROUTED-v4-c2-B.dat
0883071253b0d411a4999958a2de9b98  FT_RWNOTROUTED-v4-c2-L.dat
a3e1ec14056374ed4655e243caa8813a  FT_RWNOTROUTED-v5-c2-B.dat
0dbde685f35e61ac591acfe38eee5a3a  FT_RWNOTROUTED-v5-c2-L.dat
0b9db379ac08cbb91aa0cc9012d8e7d7  FT_RWROUTED-v1-c2-B.dat
8ff6912cb01fa853c3c2cae5618aa4cb  FT_RWROUTED-v1-c2-L.dat
4ae4cbc09fbb9f7f8d50918d9601fe6b  FT_RWROUTED-v2-c2-B.dat
5e00ae2d4a38399df53514f54f36caef  FT_RWROUTED-v2-c2-L.dat
594da013877ccded5e06ede473343806  FT_RWROUTED-v3-c2-B.dat
090182ea16bc33f0637c23b15f49b804  FT_RWROUTED-v3-c2-L.dat
342dcdfae3e7a564fd75e896efa86c9f  FT_RWROUTED-v4-c2-B.dat
af7b0cc4065f25f9f6636d37f9abc812  FT_RWROUTED-v4-c2-L.dat
57bff52f73267c20b7ea572be077cd5d  FT_RWROUTED-v5-c2-B.dat
ed24b39a73700af62b613aab278290eb  FT_RWROUTED-v5-c2-L.dat
4badb225c7c836289fed62a6f0f0caa7  FT_RWSPLIT-v1-c2-B.dat
119920643f6e44636f0522146e5456a3  FT_RWSPLIT-v1-c2-L.dat
9c4da6cca34b50ffccbbf02e121cbe32  FT_RWSPLIT-v2-c2-B.dat
3b0a1b69dfaa03686e504546d4dd523d  FT_RWSPLIT-v2-c2-L.dat
e24303f6099c208d48d3bb12847c0908  FT_RWSPLIT-v3-c2-B.dat
2c5f4c3ae6ce2be3ebf3497052a10df4  FT_RWSPLIT-v3-c2-L.dat
5dbcce6cb27c8b0bfacaae80be30cc15  FT_RWSPLIT-v4-c2-B.dat
2a8d703b45520b8e6b689002e67c3c65  FT_RWSPLIT-v4-c2-L.dat
66261ff71674601dbb26669f8bb78a6d  FT_RWSPLIT-v5-c2-B.dat
38e1540440f9b59e02859d971b23c148  FT_RWSPLIT-v5-c2-L.dat
b04aedb14475fb0ac4895791f4634483  FT_RWWWW-v1-c2-B.dat
05d8689cc5b0394f71bd5f3ee3913dde  FT_RWWWW-v1-c2-L.dat
5b85282b92664f3cbcef5452c9858d42  FT_RWWWW-v2-c2-B.dat
7aff9fcfda792e584d619442f974abe7  FT_RWWWW-v2-c2-L.dat
60f07f703982330978b3843b18304bb5  FT_RWWWW-v3-c2-B.dat
6d8e8d225daf544ddcb8b3b2f69590e6  FT_RWWWW-v3-c2-L.dat
de98d83fa8969ae3e26af2ebfe85abf2  FT_RWWWW-v4-c2-B.dat
8fffb563e2eb43257450e25f098afe7b  FT_RWWWW-v4-c2-L.dat
b0d369d8c9ba2d73dda356fb9abdd35e  FT_RWWWW-v5-c2-B.dat
a5bb40388a14669608958dcec52e9b11  FT_RWWWW-v5-c2-L.dat

# LZO-2.06 on 32-bit Ubuntu gives different results for two files
eec70dcca953c0dcefeeafbffae6bd97 FT_RWIPV6ROUTING-v3-c2-B.dat
a3345cae9921e02bb0e858552edd961b FT_RWIPV6ROUTING-v3-c2-L.dat
