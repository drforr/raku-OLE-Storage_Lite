#use strict;
#use warnings;
#
#use Encode;
#
#use Test::More;
#
#use lib 't/lib';
#use Utils;
#use OLE::Storage_Lite;
#
#plan tests => 1;
#
## Original sample script by Kawai, Takanori (Hippo2000)
##
## Rewritten to be a test by Jeff G. (drforr)
##
## Writes to a tmp file, probably should use File::Temp. XXX
#
#use constant FILENAME => 'sample/tsv.dat'; # XXX should use File::Temp?
#
#my @aL = localtime();
#splice(@aL, 6);
#
#my $oF = OLE::Storage_Lite::PPS::File->new(
#  OLE::Storage_Lite::Asc2Ucs('Workbook'), 'ABCDEF'
#);
#
#my $oF2 = OLE::Storage_Lite::PPS::File->new(
#  OLE::Storage_Lite::Asc2Ucs('File_2'), 'A'x 0x1000
#);
#
#my $oF3 = OLE::Storage_Lite::PPS::File->new(
#  OLE::Storage_Lite::Asc2Ucs('File_3'), 'B'x 0x100
#);
#
#my $oF4 = OLE::Storage_Lite::PPS::File->new(
#  OLE::Storage_Lite::Asc2Ucs('File_4'), 'C'x 0x100
#);
#
#my $oD = OLE::Storage_Lite::PPS::Dir->new(
#  OLE::Storage_Lite::Asc2Ucs('Dir'), \@aL, \@aL, [$oF2, $oF3, $oF4]
#);
#
#my $oDt = OLE::Storage_Lite::PPS::Root->new(
#  undef,
#  [0, 0, 16, 4, 10, 100],  #2000/11/4 16:00:00:0000
#  [$oF, $oD]
#);
#
#my $raW = $oDt->{Child};
#$oDt->save(FILENAME);
#
#my $ole  = OLE::Storage_Lite->new( FILENAME );
#my $pps  = $ole->getPpsTree();
#my $tree = Utils::serialize_pps($pps);
#
## Skip Time1st and Time2nd fields because this file is written out as part
## of the test suite now, so updated and created times (which is what I think
## these entries are) change continually.
##
## Luckily Utils::prune( $tree, @keys_to_prune ) # removes those keys that
##                                               # might vary.
##
#is_deeply Utils::prune($tree, qw( Time1st Time2nd )), {
#  Type       => 5,
#  No         => 0,
#  Size       => 576,
#  StartBlock => 1,
#  Data       => undef,
#  NextPps    => Utils::int32_minus_1,
#  PrevPps    => Utils::int32_minus_1,
#  DirPps     => 1,
##  Time1st    => [ 0, 0, 0, 1, 0, '-299', 1, 0, 0 ],
##  Time2nd    => [ 0, 0, 16, 4, 10, '100', 6, 308, 0 ],
#  Name       => encode('UTF-16LE', qq{Root Entry} ),
#  Child => [
#    { Type       => 2,
#      DirPps     => Utils::int32_minus_1,
#      NextPps    => Utils::int32_minus_1,
#      PrevPps    => Utils::int32_minus_1,
#      Size       => 6,
#      StartBlock => 0,
#      Data       => undef,
#      No         => 2,
##      Time1st    => [ undef ],
##      Time2nd    => [ undef ],
#      Name       => encode('UTF-16LE', qq{Workbook} ),
#    },
#    { Type       => 1,
#      DirPps     => 3,
#      NextPps    => Utils::int32_minus_1,
#      PrevPps    => 2,
#      Size       => 0,
#      StartBlock => 0,
#      Data       => undef,
#      No         => 1,
##      Time2nd    => [ 36, 22, 6, 4, 10, '119', 1, 307, 0 ],
##      Time1st    => [ 36, 22, 6, 4, 10, '119', 1, 307, 0 ],
#      Name       => encode('UTF-16LE', qq{Dir} ),
#      Child   => [
#        { Type       => 2,
#          DirPps     => Utils::int32_minus_1,
#          NextPps    => Utils::int32_minus_1,
#          PrevPps    => Utils::int32_minus_1,
#          Size       => 4096,
#          StartBlock => 3,
#          Data       => undef,
#          No         => 4,
##          Time1st    => [ undef ],
##          Time2nd    => [ undef ],
#          Name       => encode('UTF-16LE', qq{File_2} ),
#        },
#        { Type       => 2,
#          DirPps     => Utils::int32_minus_1,
#          NextPps    => 5,
#          PrevPps    => 4,
#          No         => 3,
#          Data       => undef,
#          StartBlock => 1,
#          Size       => 256,
##          Time1st    => [ undef ],
##          Time2nd    => [ undef ],
#          Name       => encode('UTF-16LE', qq{File_3} ),
#        },
#        { Type       => 2,
#          StartBlock => 5,
#          PrevPps    => 2**32 - 1,
#          Data       => undef,
#          No         => 5,
#          DirPps     => 2**32 - 1,
#          NextPps    => 2**32 - 1,
#          Size       => 256,
##          Time1st    => [ undef ],
##          Time2nd    => [ undef ],
#          Name       => encode('UTF-16LE', qq{File_4} ),
#        }
#      ]
#    }
#  ]
#};
#
#=cut
