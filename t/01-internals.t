use v6;

use Test;
use OLE::Storage_Lite;

constant FILENAME = 'sample/test.xls';

plan 9;

# from getHeaderInfo on the original file:
# _BDB_COUNT: 1
# _BIG_BLOCK_SIZE: 512
# _EXTRA_BBD_COUNT: 0
# _EXTRA_BBD_START: 4294967294
# _FILEH_: !!perl/glob:IO::File
#   PACKAGE: Symbol
#   NAME: GEN0
#   IO:
#     fileno: 3
#     stat:
#       device: 2048
#       inode: 1357786
#       mode: 33188
#       links: 1
#       uid: 1000
#       gid: 1000
#       rdev: 0
#       size: 13824
#       atime: 1573350271
#       mtime: 1259024592
#       ctime: 1572807366
#       blksize: 4096
#       blocks: 32
#     tell: 13440
# _ROOT_START: 25
# _SBD_COUNT: 0
# _SBD_START: 4294967294
# _SB_SIZE: 0
# _SB_START: 4294967294
# _SMALL_BLOCK_SIZE: 64

my $header-info = OLE::Storage_Lite._getHeaderInfo( FILENAME );

is $header-info.<_SMALL_BLOCK_SIZE>, 64;
is $header-info.<_BIG_BLOCK_SIZE>, 512;

is $header-info.<_SBD_START>, 2**32-2;
is $header-info.<_ROOT_START>, 25;
is $header-info.<_EXTRA_BBD_START>, 2**32-2;

is $header-info.<_BDB_COUNT>, 1;
is $header-info.<_SBD_COUNT>, 0;
is $header-info.<_EXTRA_BBD_COUNT>, 0;

is-deeply $header-info.<_BBD_INFO>, {
  "100" => 4294967295, "101" => 4294967295, "102" => 4294967295,
  "103" => 4294967295, "104" => 4294967295, "105" => 4294967295,
  "106" => 4294967295, "107" => 4294967295, "108" => 4294967295,
  "109" => 4294967295, "110" => 4294967295, "111" => 4294967295,
  "112" => 4294967295, "113" => 4294967295, "114" => 4294967295,
  "115" => 4294967295, "116" => 4294967295, "117" => 4294967295,
  "118" => 4294967295, "119" => 4294967295, "120" => 4294967295,
  "121" => 4294967295, "122" => 4294967295, "123" => 4294967295,
  "124" => 4294967295, "125" => 4294967295, "126" => 4294967295,
  "127" => 4294967295, "15" => 4294967294, "23" => 4294967294,
  "24" => 4294967293, "25" => 4294967294, "26" => 4294967295,
  "27" => 4294967295, "28" => 4294967295, "29" => 4294967295,
  "30" => 4294967295, "31" => 4294967295, "32" => 4294967295,
  "33" => 4294967295, "34" => 4294967295, "35" => 4294967295,
  "36" => 4294967295, "37" => 4294967295, "38" => 4294967295,
  "39" => 4294967295, "40" => 4294967295, "41" => 4294967295,
  "42" => 4294967295, "43" => 4294967295, "44" => 4294967295,
  "45" => 4294967295, "46" => 4294967295, "47" => 4294967295,
  "48" => 4294967295, "49" => 4294967295, "50" => 4294967295,
  "51" => 4294967295, "52" => 4294967295, "53" => 4294967295,
  "54" => 4294967295, "55" => 4294967295, "56" => 4294967295,
  "57" => 4294967295, "58" => 4294967295, "59" => 4294967295,
  "60" => 4294967295, "61" => 4294967295, "62" => 4294967295,
  "63" => 4294967295, "64" => 4294967295, "65" => 4294967295,
  "66" => 4294967295, "67" => 4294967295, "68" => 4294967295,
  "69" => 4294967295, "7" => 4294967294, "70" => 4294967295,
  "71" => 4294967295, "72" => 4294967295, "73" => 4294967295,
  "74" => 4294967295, "75" => 4294967295, "76" => 4294967295,
  "77" => 4294967295, "78" => 4294967295, "79" => 4294967295,
  "80" => 4294967295, "81" => 4294967295, "82" => 4294967295,
  "83" => 4294967295, "84" => 4294967295, "85" => 4294967295,
  "86" => 4294967295, "87" => 4294967295, "88" => 4294967295,
  "89" => 4294967295, "90" => 4294967295, "91" => 4294967295,
  "92" => 4294967295, "93" => 4294967295, "94" => 4294967295,
  "95" => 4294967295, "96" => 4294967295, "97" => 4294967295,
  "98" => 4294967295, "99" => 4294967295
};

done-testing;
