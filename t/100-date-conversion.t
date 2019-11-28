use v6.c;

use experimental :pack;

use Test;

use OLE::Storage_Lite::Utils;

plan 198;

my $testdata = q:to[_END_];
0           0-0-0-1-0-70        00803ED5DEB19D01  # Thu Jan  1 00:00:00 1970
1           1-0-0-1-0-70        8016D7D5DEB19D01  # Thu Jan  1 00:00:01 1970
3997695     15-28-6-16-1-70     80E925B13AD69D01  # Mon Feb 16 06:28:15 1970
29753343    3-49-8-11-11-70     80E9A5BB79C09E01  # Fri Dec 11 08:49:03 1970
36634623    3-17-0-1-2-71       80E925760FFF9E01  # Mon Mar  1 00:17:03 1971
50593791    51-49-14-9-7-71     80516A100D7E9F01  # Mon Aug  9 14:49:51 1971
79101951    51-45-13-4-6-72     8051EACB5481A001  # Tue Jul  4 13:45:51 1972
124256255   35-37-3-9-11-73     80E9A578F91BA201  # Sun Dec  9 03:37:35 1973
171048959   59-35-18-3-5-75     80516A9B95C5A301  # Tue Jun  3 18:35:59 1975
183959551   31-52-3-31-9-75     80E9250AF93AA401  # Fri Oct 31 03:52:31 1975
201457663   43-27-17-20-4-76    80516A6326DAA401  # Thu May 20 17:27:43 1976
202637311   31-8-9-3-5-76       80516AF8E0E4A401  # Thu Jun  3 09:08:31 1976
203030527   7-22-22-7-5-76      80516A7F74E8A401  # Mon Jun  7 22:22:07 1976
236388351   51-25-0-29-5-77     8051EABBD717A601  # Wed Jun 29 00:25:51 1977
293470207   7-30-16-20-3-79     80516AC9FF1EA801  # Fri Apr 20 16:30:07 1979
324009983   23-46-3-8-3-80      80516ABEC134A901  # Tue Apr  8 03:46:23 1980
354877439   59-3-10-31-2-81     8051EAA37E4DAA01  # Tue Mar 31 10:03:59 1981
446300159   59-15-12-22-1-84    80E9A55DF28CAD01  # Wed Feb 22 12:15:59 1984
453312511   31-8-17-13-4-84     8051EAA6C1CCAD01  # Sun May 13 17:08:31 1984
482017279   19-41-22-10-3-85    8051EA25D3D1AE01  # Wed Apr 10 22:41:19 1985
508428287   47-4-14-10-1-86     80E9A5AFFFC1AF01  # Mon Feb 10 14:04:47 1986
510722047   7-14-3-9-2-86       80E92543DCD6AF01  # Sun Mar  9 03:14:07 1986
528285695   35-1-11-28-8-86     8051EA32A276B001  # Sun Sep 28 11:01:35 1986
571670527   7-22-13-12-1-88     80E925002F01B201  # Fri Feb 12 13:22:07 1988
599130111   51-1-9-26-11-88     80E9A553EDFAB201  # Mon Dec 26 09:01:51 1988
632619007   7-30-23-17-0-90     80E925BD812BB401  # Wed Jan 17 23:30:07 1990
633733119   39-58-20-30-0-90    80E9A5BBA335B401  # Tue Jan 30 20:58:39 1990
638189567   47-52-10-23-2-90    80E9A5B52B5EB401  # Fri Mar 23 10:52:47 1990
692518911   51-21-6-12-11-91    80E925124B4CB601  # Thu Dec 12 06:21:51 1991
737869823   23-50-4-20-4-93     8051EA45CAE8B701  # Thu May 20 04:50:23 1993
755892223   43-3-18-14-11-93    80E9A58FAB8CB801  # Tue Dec 14 18:03:43 1993
835387391   11-3-21-21-5-96     8051EA0DB55FBB01  # Fri Jun 21 21:03:11 1996
838729727   47-28-13-30-6-96    80516A091B7EBB01  # Tue Jul 30 13:28:47 1996
846135295   55-34-6-24-9-96     8051EA7775C1BB01  # Thu Oct 24 06:34:55 1996
856096767   27-39-12-16-1-97    80E92572061CBC01  # Sun Feb 16 12:39:27 1997
892076031   51-53-23-8-3-98     80516A944963BD01  # Wed Apr  8 23:53:51 1998
908460031   31-0-15-15-9-98     80516A8D4CF8BD01  # Thu Oct 15 15:00:31 1998
936312831   51-53-23-2-8-99     8051EA679EF5BE01  # Thu Sep  2 23:53:51 1999
944504831   11-27-18-6-11-99    80E9A5821740BF01  # Mon Dec  6 18:27:11 1999
951696000   0-0-0-28-1-100      00C062C17E81BF01  # Mon Feb 28 00:00:00 2000
951782399   59-59-23-28-1-100   80E933EB4782BF01  # Mon Feb 28 23:59:59 2000
951782400   0-0-0-29-1-100      0080CCEB4782BF01  # Tue Feb 29 00:00:00 2000
954138623   23-30-7-27-2-100    8051EA4FBE97BF01  # Mon Mar 27 07:30:23 2000
972226559   59-55-15-22-9-100   8051EA91403CC001  # Sun Oct 22 15:55:59 2000
983318400   0-0-0-28-1-101      0040936419A1C001  # Wed Feb 28 00:00:00 2001
983404799   59-59-23-28-1-101   8069648EE2A1C001  # Wed Feb 28 23:59:59 2001
983404800   0-0-0-1-2-101       0000FD8EE2A1C001  # Thu Mar  1 00:00:00 2001
1003552767  27-39-5-20-9-101    8051EA942959C101  # Sat Oct 20 05:39:27 2001
1031012351  11-19-1-3-8-102     80516AE8E752C201  # Tue Sep  3 01:19:11 2002
1037172735  15-32-7-13-10-102   80E9A5C9E68AC201  # Wed Nov 13 07:32:15 2002
1066926079  19-21-17-23-9-103   80516A128A99C301  # Thu Oct 23 17:21:19 2003
1076559871  31-24-4-12-1-104    80E9251C20F1C301  # Thu Feb 12 04:24:31 2004
1077926400  0-0-0-28-1-104      0080E7CE8DFDC301  # Sat Feb 28 00:00:00 2004
1078012799  59-59-23-28-1-104   80A9B8F856FEC301  # Sat Feb 28 23:59:59 2004
1078012800  0-0-0-29-1-104      004051F956FEC301  # Sun Feb 29 00:00:00 2004
1080557567  47-52-11-29-2-104   80516A5A8415C401  # Mon Mar 29 11:52:47 2004
1142554623  3-17-0-17-2-106     80E9A51D5849C601  # Fri Mar 17 00:17:03 2006
1144389631  31-0-7-7-3-106      80516AF5105AC601  # Fri Apr  7 07:00:31 2006
1146945535  55-58-20-6-4-106    8051EAE24F71C601  # Sat May  6 20:58:55 2006
1149829119  39-58-5-9-5-106     8051EAC0898BC601  # Fri Jun  9 05:58:39 2006
1183252479  39-14-2-1-6-107     8051EA9385BBC701  # Sun Jul  1 02:14:39 2007
1187643391  31-56-21-20-7-107   80516AF774E3C701  # Mon Aug 20 21:56:31 2007
1210121221  1-47-1-7-4-108      80D8233EE4AFC801  # Wed May  7 01:47:01 2008
1226899455  15-24-5-17-10-108   80E925BB7448C901  # Mon Nov 17 05:24:15 2008
1227227135  35-25-0-21-10-108   80E9A5AB6F4BC901  # Fri Nov 21 00:25:35 2008
1228210175  35-29-9-2-11-108    80E9257D6054C901  # Tue Dec  2 09:29:35 2008
1230767999  59-59-23-31-11-108  80A90EE3A36BC901  # Wed Dec 31 23:59:59 2008
1249116159  39-42-9-1-7-109     80516A688C12CA01  # Sat Aug  1 09:42:39 2009
1257111551  11-39-21-1-10-109   80E9A5BF3B5BCA01  # Sun Nov  1 21:39:11 2009
1271201791  31-36-0-14-3-110    8051EA866ADBCA01  # Wed Apr 14 00:36:31 2010
1288765439  59-23-6-3-10-110    80E925B31F7BCB01  # Wed Nov  3 06:23:59 2010
1294991359  19-49-7-14-0-111    80E9A58CBFB3CB01  # Fri Jan 14 07:49:19 2011
1297219583  23-46-2-9-1-111     80E9A58903C8CB01  # Wed Feb  9 02:46:23 2011
1339162623  3-37-14-8-5-112     80516A2B8445CD01  # Fri Jun  8 14:37:03 2012
1346502655  55-30-13-1-8-112    80516A034688CD01  # Sat Sep  1 13:30:55 2012
1349713919  59-31-17-8-9-112    8051EAD17AA5CD01  # Mon Oct  8 17:31:59 2012
1357119487  7-38-9-2-0-113      80E9A5DECCE8CD01  # Wed Jan  2 09:38:07 2013
1363673087  47-4-6-19-2-113     80E9A5A86724CE01  # Tue Mar 19 06:04:47 2013
1423769599  19-33-19-12-1-115   80E925C1FA46D001  # Thu Feb 12 19:33:19 2015
1502478335  35-5-20-11-7-117    80516A31DD12D301  # Fri Aug 11 20:05:35 2017
1538457599  59-19-6-2-9-118     8051EAF1175AD401  # Tue Oct  2 06:19:59 2018
1557790719  39-38-0-14-4-119    80516A5FED09D501  # Tue May 14 00:38:39 2019
1570963455  15-44-11-13-9-119   8051EA89BB81D501  # Sun Oct 13 11:44:15 2019
1576468479  39-54-3-16-11-119   80E9258AC4B3D501  # Mon Dec 16 03:54:39 2019
1604845567  7-26-14-8-10-120    80E9A518DBB5D601  # Sun Nov  8 14:26:07 2020
1612775423  23-10-9-8-1-121     80E9253BFAFDD601  # Mon Feb  8 09:10:23 2021
1654063103  23-58-6-1-5-122     8051EAFB8475D801  # Wed Jun  1 06:58:23 2022
1681260543  3-49-1-12-3-123     80516AF5E06CD901  # Wed Apr 12 01:49:03 2023
1766588415  15-0-15-24-11-125   80E9A502E674DC01  # Wed Dec 24 15:00:15 2025
1814822911  31-28-22-5-6-127    80516A149F2BDE01  # Mon Jul  5 22:28:31 2027
1820786687  47-4-23-12-8-127    8051EA93DC61DE01  # Sun Sep 12 23:04:47 2027
1824129023  23-30-15-21-9-127   80516A8F4280DE01  # Thu Oct 21 15:30:23 2027
1848377343  3-9-7-28-6-128      80516A14CC5CDF01  # Fri Jul 28 07:09:03 2028
1848770559  39-22-20-1-7-128    80516A9B5F60DF01  # Tue Aug  1 20:22:39 2028
1880883199  19-33-12-8-7-129    80516AAC6F84E001  # Wed Aug  8 12:33:19 2029
1986199551  51-5-10-9-11-132    80E925084042E401  # Thu Dec  9 10:05:51 2032
2029912063  43-27-9-29-3-134    80516A89D8CFE501  # Sat Apr 29 09:27:43 2034
2124873727  7-42-11-2-4-137     8051EA63842FE901  # Sat May  2 11:42:07 2037
2144993279  59-27-7-21-11-137   80E9A57D78E6E901  # Mon Dec 21 07:27:59 2037
_END_

for $testdata.lines -> $line {
  next if $line ~~ m{ ^ \s* '#' };

  my ( $unix_seconds, $expected_localtime, $expected_oletime, $comment ) =
    split( /\s+/, $line, 4 );
  $comment ~~ s{ ^ '#' \s* }='';

  my @expected_localtime =
    map { +$_ }, split( /\-/, $expected_localtime );
  my $got_oletime        = LocalDate2OLE( @expected_localtime );
     $got_oletime        = uc( $got_oletime.unpack( "H*" ) );

  is $got_oletime, $expected_oletime, "LocalDate2OLE: $comment";

  # Test LocalDate2OLE
  $expected_oletime = pack 'H*', $expected_oletime;

  my @got_localtime = OLEDate2Local($expected_oletime);
     @got_localtime = @got_localtime[0..5];

  my $got_localtime   = join '-', @got_localtime[0..5];
  $expected_localtime = join '-', @$expected_localtime;

  is($got_localtime, $expected_localtime, "OLEDate2Local: $comment");
}
