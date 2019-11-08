use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::Root is OLE::Storage_Lite::PPS;

##------------------------------------------------------------------------------
## new (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub new ($;$$$) {
#    my($sClass, $raTime1st, $raTime2nd, $raChild) = @_;
#    OLE::Storage_Lite::PPS::_new(
#        $sClass,
#        undef,
#        OLE::Storage_Lite::Asc2Ucs('Root Entry'),
#        5,
#        undef,
#        undef,
#        undef,
#        $raTime1st,
#        $raTime2nd,
#        undef,
#        undef,
#        undef,
#        $raChild);
#}
##------------------------------------------------------------------------------
## save (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub save($$;$$) {
#  my($oThis, $sFile, $bNoAs, $rhInfo) = @_;
#  #0.Initial Setting for saving
#  $rhInfo = {} unless($rhInfo);
#  $rhInfo->{_BIG_BLOCK_SIZE}  = 2**
#                (($rhInfo->{_BIG_BLOCK_SIZE})?
#                    _adjust2($rhInfo->{_BIG_BLOCK_SIZE})  : 9);
#  $rhInfo->{_SMALL_BLOCK_SIZE}= 2 **
#                (($rhInfo->{_SMALL_BLOCK_SIZE})?
#                    _adjust2($rhInfo->{_SMALL_BLOCK_SIZE}): 6);
#  $rhInfo->{_SMALL_SIZE} = 0x1000;
#  $rhInfo->{_PPS_SIZE} = 0x80;
#
#  my $closeFile = 1;
#
#  #1.Open File
#  #1.1 $sFile is Ref of scalar
#  if(ref($sFile) eq 'SCALAR') {
#    require IO::Scalar;
#    my $oIo = new IO::Scalar $sFile, O_WRONLY;
#    $rhInfo->{_FILEH_} = $oIo;
#  }
#  #1.1.1 $sFile is a IO::Scalar object
#  # Now handled as a filehandle ref below.
#
#  #1.2 $sFile is a IO::Handle object
#  elsif(UNIVERSAL::isa($sFile, 'IO::Handle')) {
#    # Not all filehandles support binmode() so try it in an eval.
#    eval{ binmode $sFile };
#    $rhInfo->{_FILEH_} = $sFile;
#  }
#  #1.3 $sFile is a simple filename string
#  elsif(!ref($sFile)) {
#    if($sFile ne '-') {
#        my $oIo = new IO::File;
#        $oIo->open(">$sFile") || return undef;
#        binmode($oIo);
#        $rhInfo->{_FILEH_} = $oIo;
#    }
#    else {
#        my $oIo = new IO::Handle;
#        $oIo->fdopen(fileno(STDOUT),"w") || return undef;
#        binmode($oIo);
#        $rhInfo->{_FILEH_} = $oIo;
#    }
#  }
#  #1.4 Assume that if $sFile is a ref then it is a valid filehandle
#  else {
#    # Not all filehandles support binmode() so try it in an eval.
#    eval{ binmode $sFile };
#    $rhInfo->{_FILEH_} = $sFile;
#    # Caller controls filehandle closing
#    $closeFile = 0;
#  }
#
#  my $iBlk = 0;
#  #1. Make an array of PPS (for Save)
#  my @aList=();
#  if($bNoAs) {
#    _savePpsSetPnt2([$oThis], \@aList, $rhInfo);
#  }
#  else {
#    _savePpsSetPnt([$oThis], \@aList, $rhInfo);
#  }
#  my ($iSBDcnt, $iBBcnt, $iPPScnt) = $oThis->_calcSize(\@aList, $rhInfo);
#
#  #2.Save Header
#  $oThis->_saveHeader($rhInfo, $iSBDcnt, $iBBcnt, $iPPScnt);
#
#  #3.Make Small Data string (write SBD)
#  my $sSmWk = $oThis->_makeSmallData(\@aList, $rhInfo);
#  $oThis->{Data} = $sSmWk;  #Small Datas become RootEntry Data
#
#  #4. Write BB
#  my $iBBlk = $iSBDcnt;
#  $oThis->_saveBigData(\$iBBlk, \@aList, $rhInfo);
#
#  #5. Write PPS
#  $oThis->_savePps(\@aList, $rhInfo);
#
#  #6. Write BD and BDList and Adding Header informations
#  $oThis->_saveBbd($iSBDcnt, $iBBcnt, $iPPScnt,  $rhInfo);
#
#  #7.Close File
#  return $rhInfo->{_FILEH_}->close if $closeFile;
#}
##------------------------------------------------------------------------------
## _calcSize (OLE::Storage_Lite::PPS)
##------------------------------------------------------------------------------
#sub _calcSize($$)
#{
#  my($oThis, $raList, $rhInfo) = @_;
#
##0. Calculate Basic Setting
#  my ($iSBDcnt, $iBBcnt, $iPPScnt) = (0,0,0);
#  my $iSmallLen = 0;
#  my $iSBcnt = 0;
#  foreach my $oPps (@$raList) {
#      if($oPps->{Type}==OLE::Storage_Lite::PpsType_File()) {
#        $oPps->{Size} = $oPps->_DataLen();  #Mod
#        if($oPps->{Size} < $rhInfo->{_SMALL_SIZE}) {
#          $iSBcnt += int($oPps->{Size} / $rhInfo->{_SMALL_BLOCK_SIZE})
#                          + (($oPps->{Size} % $rhInfo->{_SMALL_BLOCK_SIZE})? 1: 0);
#        }
#        else {
#          $iBBcnt +=
#            (int($oPps->{Size}/ $rhInfo->{_BIG_BLOCK_SIZE}) +
#                (($oPps->{Size}% $rhInfo->{_BIG_BLOCK_SIZE})? 1: 0));
#        }
#      }
#  }
#  $iSmallLen = $iSBcnt * $rhInfo->{_SMALL_BLOCK_SIZE};
#  my $iSlCnt = int($rhInfo->{_BIG_BLOCK_SIZE}/ OLE::Storage_Lite::LongIntSize());
#  $iSBDcnt = int($iSBcnt / $iSlCnt)+ (($iSBcnt % $iSlCnt)? 1:0);
#  $iBBcnt +=  (int($iSmallLen/ $rhInfo->{_BIG_BLOCK_SIZE}) +
#                (( $iSmallLen% $rhInfo->{_BIG_BLOCK_SIZE})? 1: 0));
#  my $iCnt = scalar(@$raList);
#  my $iBdCnt = $rhInfo->{_BIG_BLOCK_SIZE}/OLE::Storage_Lite::PpsSize();
#  $iPPScnt = (int($iCnt/$iBdCnt) + (($iCnt % $iBdCnt)? 1: 0));
#  return ($iSBDcnt, $iBBcnt, $iPPScnt);
#}
##------------------------------------------------------------------------------
## _adjust2 (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub _adjust2($) {
#  my($i2) = @_;
#  my $iWk;
#  $iWk = log($i2)/log(2);
#  return ($iWk > int($iWk))? int($iWk)+1:$iWk;
#}
##------------------------------------------------------------------------------
## _saveHeader (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub _saveHeader($$$$$) {
#  my($oThis, $rhInfo, $iSBDcnt, $iBBcnt, $iPPScnt) = @_;
#  my $FILE = $rhInfo->{_FILEH_};
#
##0. Calculate Basic Setting
#  my $iBlCnt = $rhInfo->{_BIG_BLOCK_SIZE} / OLE::Storage_Lite::LongIntSize();
#  my $i1stBdL = int(($rhInfo->{_BIG_BLOCK_SIZE} - 0x4C) / OLE::Storage_Lite::LongIntSize());
#  my $i1stBdMax = $i1stBdL * $iBlCnt  - $i1stBdL;
#  my $iBdExL = 0;
#  my $iAll = $iBBcnt + $iPPScnt + $iSBDcnt;
#  my $iAllW = $iAll;
#  my $iBdCntW = int($iAllW / $iBlCnt) + (($iAllW % $iBlCnt)? 1: 0);
#  my $iBdCnt = int(($iAll + $iBdCntW) / $iBlCnt) + ((($iAllW+$iBdCntW) % $iBlCnt)? 1: 0);
#  my $i;
#
#  if ($iBdCnt > $i1stBdL) {
#    #0.1 Calculate BD count
#    $iBlCnt--; #the BlCnt is reduced in the count of the last sect is used for a pointer the next Bl
#    my $iBBleftover = $iAll - $i1stBdMax;
#
#    if ($iAll >$i1stBdMax) {
#      while(1) {
#        $iBdCnt = int(($iBBleftover) / $iBlCnt) + ((($iBBleftover) % $iBlCnt)? 1: 0);
#        $iBdExL = int(($iBdCnt) / $iBlCnt) + ((($iBdCnt) % $iBlCnt)? 1: 0);
#        $iBBleftover = $iBBleftover + $iBdExL;
#        last if($iBdCnt == (int(($iBBleftover) / $iBlCnt) + ((($iBBleftover) % $iBlCnt)? 1: 0)));
#      }
#    }
#    $iBdCnt += $i1stBdL;
#    #print "iBdCnt = $iBdCnt \n";
#  }
##1.Save Header
#  print {$FILE} (
#            "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1"
#            , "\x00\x00\x00\x00" x 4
#            , pack("v", 0x3b)
#            , pack("v", 0x03)
#            , pack("v", -2)
#            , pack("v", 9)
#            , pack("v", 6)
#            , pack("v", 0)
#            , "\x00\x00\x00\x00" x 2
#            , pack("V", $iBdCnt),
#            , pack("V", $iBBcnt+$iSBDcnt), #ROOT START
#            , pack("V", 0)
#            , pack("V", 0x1000)
#            , pack("V", $iSBDcnt ? 0 : -2)                  #Small Block Depot
#            , pack("V", $iSBDcnt)
#    );
##2. Extra BDList Start, Count
#  if($iAll <= $i1stBdMax) {
#    print {$FILE} (
#                pack("V", -2),      #Extra BDList Start
#                pack("V", 0),       #Extra BDList Count
#        );
#  }
#  else {
#    print {$FILE} (
#            pack("V", $iAll+$iBdCnt),
#            pack("V", $iBdExL),
#        );
#  }
#
##3. BDList
#    for($i=0; $i<$i1stBdL and $i < $iBdCnt; $i++) {
#        print {$FILE} (pack("V", $iAll+$i));
#    }
#    print {$FILE} ((pack("V", -1)) x($i1stBdL-$i)) if($i<$i1stBdL);
#}
##------------------------------------------------------------------------------
## _saveBigData (OLE::Storage_Lite::PPS)
##------------------------------------------------------------------------------
#sub _saveBigData($$$$) {
#  my($oThis, $iStBlk, $raList, $rhInfo) = @_;
#  my $iRes = 0;
#  my $FILE = $rhInfo->{_FILEH_};
#
##1.Write Big (ge 0x1000) Data into Block
#  foreach my $oPps (@$raList) {
#    if($oPps->{Type}!=OLE::Storage_Lite::PpsType_Dir()) {
##print "PPS: $oPps DEF:", defined($oPps->{Data}), "\n";
#        $oPps->{Size} = $oPps->_DataLen();  #Mod
#        if(($oPps->{Size} >= $rhInfo->{_SMALL_SIZE}) ||
#            (($oPps->{Type} == OLE::Storage_Lite::PpsType_Root()) && defined($oPps->{Data}))) {
#            #1.1 Write Data
#            #Check for update
#            if($oPps->{_PPS_FILE}) {
#                my $sBuff;
#                my $iLen = 0;
#                $oPps->{_PPS_FILE}->seek(0, 0); #To The Top
#                while($oPps->{_PPS_FILE}->read($sBuff, 4096)) {
#                    $iLen += length($sBuff);
#                    print {$FILE} ($sBuff);           #Check for update
#                }
#            }
#            else {
#                print {$FILE} ($oPps->{Data});
#            }
#            print {$FILE} (
#                        "\x00" x
#                        ($rhInfo->{_BIG_BLOCK_SIZE} -
#                            ($oPps->{Size} % $rhInfo->{_BIG_BLOCK_SIZE}))
#                    ) if ($oPps->{Size} % $rhInfo->{_BIG_BLOCK_SIZE});
#            #1.2 Set For PPS
#            $oPps->{StartBlock} = $$iStBlk;
#            $$iStBlk +=
#                    (int($oPps->{Size}/ $rhInfo->{_BIG_BLOCK_SIZE}) +
#                        (($oPps->{Size}% $rhInfo->{_BIG_BLOCK_SIZE})? 1: 0));
#        }
#    }
#  }
#}
##------------------------------------------------------------------------------
## _savePps (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub _savePps($$$)
#{
#  my($oThis, $raList, $rhInfo) = @_;
##0. Initial
#  my $FILE = $rhInfo->{_FILEH_};
##2. Save PPS
#  foreach my $oItem (@$raList) {
#      $oItem->_savePpsWk($rhInfo);
#  }
##3. Adjust for Block
#  my $iCnt = scalar(@$raList);
#  my $iBCnt = $rhInfo->{_BIG_BLOCK_SIZE} / $rhInfo->{_PPS_SIZE};
#  print {$FILE} ("\x00" x (($iBCnt - ($iCnt % $iBCnt)) * $rhInfo->{_PPS_SIZE}))
#        if($iCnt % $iBCnt);
#  return int($iCnt / $iBCnt) + (($iCnt % $iBCnt)? 1: 0);
#}
##------------------------------------------------------------------------------
## _savePpsSetPnt2 (OLE::Storage_Lite::PPS::Root)
##  For Test
##------------------------------------------------------------------------------
#sub _savePpsSetPnt2($$$)
#{
#  my($aThis, $raList, $rhInfo) = @_;
##1. make Array as Children-Relations
##1.1 if No Children
#  if($#$aThis < 0) {
#      return 0xFFFFFFFF;
#  }
#  elsif($#$aThis == 0) {
##1.2 Just Only one
#      push @$raList, $aThis->[0];
#      $aThis->[0]->{No} = $#$raList;
#      $aThis->[0]->{PrevPps} = 0xFFFFFFFF;
#      $aThis->[0]->{NextPps} = 0xFFFFFFFF;
#      $aThis->[0]->{DirPps} = _savePpsSetPnt2($aThis->[0]->{Child}, $raList, $rhInfo);
#      return $aThis->[0]->{No};
#  }
#  else {
##1.3 Array
#      my $iCnt = $#$aThis + 1;
##1.3.1 Define Center
#      my $iPos = 0; #int($iCnt/ 2);     #$iCnt
#
#      my @aWk = @$aThis;
#      my @aPrev = ($#$aThis > 1)? splice(@aWk, 1, 1) : (); #$iPos);
#      my @aNext = splice(@aWk, 1); #, $iCnt - $iPos -1);
#      $aThis->[$iPos]->{PrevPps} = _savePpsSetPnt2(
#            \@aPrev, $raList, $rhInfo);
#      push @$raList, $aThis->[$iPos];
#      $aThis->[$iPos]->{No} = $#$raList;
#
##1.3.2 Devide a array into Previous,Next
#      $aThis->[$iPos]->{NextPps} = _savePpsSetPnt2(
#            \@aNext, $raList, $rhInfo);
#      $aThis->[$iPos]->{DirPps} = _savePpsSetPnt2($aThis->[$iPos]->{Child}, $raList, $rhInfo);
#      return $aThis->[$iPos]->{No};
#  }
#}
##------------------------------------------------------------------------------
## _savePpsSetPnt2 (OLE::Storage_Lite::PPS::Root)
##  For Test
##------------------------------------------------------------------------------
#sub _savePpsSetPnt2s($$$)
#{
#  my($aThis, $raList, $rhInfo) = @_;
##1. make Array as Children-Relations
##1.1 if No Children
#  if($#$aThis < 0) {
#      return 0xFFFFFFFF;
#  }
#  elsif($#$aThis == 0) {
##1.2 Just Only one
#      push @$raList, $aThis->[0];
#      $aThis->[0]->{No} = $#$raList;
#      $aThis->[0]->{PrevPps} = 0xFFFFFFFF;
#      $aThis->[0]->{NextPps} = 0xFFFFFFFF;
#      $aThis->[0]->{DirPps} = _savePpsSetPnt2($aThis->[0]->{Child}, $raList, $rhInfo);
#      return $aThis->[0]->{No};
#  }
#  else {
##1.3 Array
#      my $iCnt = $#$aThis + 1;
##1.3.1 Define Center
#      my $iPos = 0; #int($iCnt/ 2);     #$iCnt
#      push @$raList, $aThis->[$iPos];
#      $aThis->[$iPos]->{No} = $#$raList;
#      my @aWk = @$aThis;
##1.3.2 Devide a array into Previous,Next
#      my @aPrev = splice(@aWk, 0, $iPos);
#      my @aNext = splice(@aWk, 1, $iCnt - $iPos -1);
#      $aThis->[$iPos]->{PrevPps} = _savePpsSetPnt2(
#            \@aPrev, $raList, $rhInfo);
#      $aThis->[$iPos]->{NextPps} = _savePpsSetPnt2(
#            \@aNext, $raList, $rhInfo);
#      $aThis->[$iPos]->{DirPps} = _savePpsSetPnt2($aThis->[$iPos]->{Child}, $raList, $rhInfo);
#      return $aThis->[$iPos]->{No};
#  }
#}
##------------------------------------------------------------------------------
## _savePpsSetPnt (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub _savePpsSetPnt($$$)
#{
#  my($aThis, $raList, $rhInfo) = @_;
##1. make Array as Children-Relations
##1.1 if No Children
#  if($#$aThis < 0) {
#      return 0xFFFFFFFF;
#  }
#  elsif($#$aThis == 0) {
##1.2 Just Only one
#      push @$raList, $aThis->[0];
#      $aThis->[0]->{No} = $#$raList;
#      $aThis->[0]->{PrevPps} = 0xFFFFFFFF;
#      $aThis->[0]->{NextPps} = 0xFFFFFFFF;
#      $aThis->[0]->{DirPps} = _savePpsSetPnt($aThis->[0]->{Child}, $raList, $rhInfo);
#      return $aThis->[0]->{No};
#  }
#  else {
##1.3 Array
#      my $iCnt = $#$aThis + 1;
##1.3.1 Define Center
#      my $iPos = int($iCnt/ 2);     #$iCnt
#      push @$raList, $aThis->[$iPos];
#      $aThis->[$iPos]->{No} = $#$raList;
#      my @aWk = @$aThis;
##1.3.2 Devide a array into Previous,Next
#      my @aPrev = splice(@aWk, 0, $iPos);
#      my @aNext = splice(@aWk, 1, $iCnt - $iPos -1);
#      $aThis->[$iPos]->{PrevPps} = _savePpsSetPnt(
#            \@aPrev, $raList, $rhInfo);
#      $aThis->[$iPos]->{NextPps} = _savePpsSetPnt(
#            \@aNext, $raList, $rhInfo);
#      $aThis->[$iPos]->{DirPps} = _savePpsSetPnt($aThis->[$iPos]->{Child}, $raList, $rhInfo);
#      return $aThis->[$iPos]->{No};
#  }
#}
##------------------------------------------------------------------------------
## _savePpsSetPnt (OLE::Storage_Lite::PPS::Root)
##------------------------------------------------------------------------------
#sub _savePpsSetPnt1($$$)
#{
#  my($aThis, $raList, $rhInfo) = @_;
##1. make Array as Children-Relations
##1.1 if No Children
#  if($#$aThis < 0) {
#      return 0xFFFFFFFF;
#  }
#  elsif($#$aThis == 0) {
##1.2 Just Only one
#      push @$raList, $aThis->[0];
#      $aThis->[0]->{No} = $#$raList;
#      $aThis->[0]->{PrevPps} = 0xFFFFFFFF;
#      $aThis->[0]->{NextPps} = 0xFFFFFFFF;
#      $aThis->[0]->{DirPps} = _savePpsSetPnt($aThis->[0]->{Child}, $raList, $rhInfo);
#      return $aThis->[0]->{No};
#  }
#  else {
##1.3 Array
#      my $iCnt = $#$aThis + 1;
##1.3.1 Define Center
#      my $iPos = int($iCnt/ 2);     #$iCnt
#      push @$raList, $aThis->[$iPos];
#      $aThis->[$iPos]->{No} = $#$raList;
#      my @aWk = @$aThis;
##1.3.2 Devide a array into Previous,Next
#      my @aPrev = splice(@aWk, 0, $iPos);
#      my @aNext = splice(@aWk, 1, $iCnt - $iPos -1);
#      $aThis->[$iPos]->{PrevPps} = _savePpsSetPnt(
#            \@aPrev, $raList, $rhInfo);
#      $aThis->[$iPos]->{NextPps} = _savePpsSetPnt(
#            \@aNext, $raList, $rhInfo);
#      $aThis->[$iPos]->{DirPps} = _savePpsSetPnt($aThis->[$iPos]->{Child}, $raList, $rhInfo);
#      return $aThis->[$iPos]->{No};
#  }
#}
##------------------------------------------------------------------------------
## _saveBbd (OLE::Storage_Lite)
##------------------------------------------------------------------------------
#sub _saveBbd($$$$)
#{
#  my($oThis, $iSbdSize, $iBsize, $iPpsCnt, $rhInfo) = @_;
#  my $FILE = $rhInfo->{_FILEH_};
##0. Calculate Basic Setting
#  my $iBbCnt = $rhInfo->{_BIG_BLOCK_SIZE} / OLE::Storage_Lite::LongIntSize();
#  my $iBlCnt = $iBbCnt - 1;
#  my $i1stBdL = int(($rhInfo->{_BIG_BLOCK_SIZE} - 0x4C) / OLE::Storage_Lite::LongIntSize());
#  my $i1stBdMax = $i1stBdL * $iBbCnt  - $i1stBdL;
#  my $iBdExL = 0;
#  my $iAll = $iBsize + $iPpsCnt + $iSbdSize;
#  my $iAllW = $iAll;
#  my $iBdCntW = int($iAllW / $iBbCnt) + (($iAllW % $iBbCnt)? 1: 0);
#  my $iBdCnt = 0;
#  my $i;
##0.1 Calculate BD count
#  my $iBBleftover = $iAll - $i1stBdMax;
#  if ($iAll >$i1stBdMax) {
#
#    while(1) {
#      $iBdCnt = int(($iBBleftover) / $iBlCnt) + ((($iBBleftover) % $iBlCnt)? 1: 0);
#      $iBdExL = int(($iBdCnt) / $iBlCnt) + ((($iBdCnt) % $iBlCnt)? 1: 0);
#      $iBBleftover = $iBBleftover + $iBdExL;
#      last if($iBdCnt == (int(($iBBleftover) / $iBlCnt) + ((($iBBleftover) % $iBlCnt)? 1: 0)));
#    }
#  }
#  $iAllW += $iBdExL;
#  $iBdCnt += $i1stBdL;
#  #print "iBdCnt = $iBdCnt \n";
#
##1. Making BD
##1.1 Set for SBD
#  if($iSbdSize > 0) {
#    for ($i = 0; $i<($iSbdSize-1); $i++) {
#      print {$FILE} (pack("V", $i+1));
#    }
#    print {$FILE} (pack("V", -2));
#  }
##1.2 Set for B
#  for ($i = 0; $i<($iBsize-1); $i++) {
#      print {$FILE} (pack("V", $i+$iSbdSize+1));
#  }
#  print {$FILE} (pack("V", -2));
#
##1.3 Set for PPS
#  for ($i = 0; $i<($iPpsCnt-1); $i++) {
#      print {$FILE} (pack("V", $i+$iSbdSize+$iBsize+1));
#  }
#  print {$FILE} (pack("V", -2));
##1.4 Set for BBD itself ( 0xFFFFFFFD : BBD)
#  for($i=0; $i<$iBdCnt;$i++) {
#    print {$FILE} (pack("V", 0xFFFFFFFD));
#  }
##1.5 Set for ExtraBDList
#  for($i=0; $i<$iBdExL;$i++) {
#    print {$FILE} (pack("V", 0xFFFFFFFC));
#  }
##1.6 Adjust for Block
#  print {$FILE} (pack("V", -1) x ($iBbCnt - (($iAllW + $iBdCnt) % $iBbCnt)))
#                if(($iAllW + $iBdCnt) % $iBbCnt);
##2.Extra BDList
#  if($iBdCnt > $i1stBdL)  {
#    my $iN=0;
#    my $iNb=0;
#    for($i=$i1stBdL;$i<$iBdCnt; $i++, $iN++) {
#      if($iN>=($iBbCnt-1)) {
#          $iN = 0;
#          $iNb++;
#          print {$FILE} (pack("V", $iAll+$iBdCnt+$iNb));
#      }
#      print {$FILE} (pack("V", $iBsize+$iSbdSize+$iPpsCnt+$i));
#    }
#    print {$FILE} (pack("V", -1) x (($iBbCnt-1) - (($iBdCnt-$i1stBdL) % ($iBbCnt-1))))
#        if(($iBdCnt-$i1stBdL) % ($iBbCnt-1));
#    print {$FILE} (pack("V", -2));
#  }
#}
