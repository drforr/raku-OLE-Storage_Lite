# OLE::Storage_Lite Sample
# Name : smpsv.pl
#  by Kawai, Takanori (Hippo2000) 2000.11.8
# Just save sample OLE_File(tsv.dat)
=execute sample
# perl smplls.pl tsave.dat
00    1 'RootEntry' (pps 0)                           ROOT 04.11.2000 16:00:00
01      1 'Workbook' (pps 2)                          FILE          6 bytes
02      2 'Dir' (pps 1)                               DIR  04.11.2000 03:50:01
03        1 'File_2' (pps 4)                          FILE       1000 bytes
04        2 'File_3' (pps 3)                          FILE        100 bytes
05        3 'File_4' (pps 5)                          FILE        100 bytes 
=cut
#=================================================================
use strict;
use OLE::Storage_Lite;
my $oF = OLE::Storage_Lite::PPS::File->new(
		    OLE::Storage_Lite::Asc2Ucs('Workbook'), 
		'ABCDEF');
my $oF2 = OLE::Storage_Lite::PPS::File->new(
		OLE::Storage_Lite::Asc2Ucs('File_2'), 
		'A'x 0x1000);
my $oF3 = OLE::Storage_Lite::PPS::File->new(
		OLE::Storage_Lite::Asc2Ucs('File_3'), 
		'B'x 0x100);
my $oF4 = OLE::Storage_Lite::PPS::File->new(
		OLE::Storage_Lite::Asc2Ucs('File_4'), 
		'C'x 0x100);
my $oD = OLE::Storage_Lite::PPS::Dir->new(
		OLE::Storage_Lite::Asc2Ucs('Dir'), 
	        #[1, 1, 17, 5, 11, 121],  #2021/12/5 17:01:01:0001
		[0, 0, 0, 1, 0, 70],
		[0, 0, 0, 1, 0, 70],
		[$oF2, $oF3, $oF4]);
my $oDt = OLE::Storage_Lite::PPS::Root->new(
#		undef,
		[0, 0, 0, 1, 0, 70],
		[0, 0, 0, 1, 0, 70],
		[$oF, $oD]);
$oDt->save("sample/tsv.dat");
