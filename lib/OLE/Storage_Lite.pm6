use v6;

unit class OLE::Storage_Lite;

use experimental :pack;

#------------------------------------------------------------------------------
# Consts for OLE::Storage_Lite
#------------------------------------------------------------------------------
#
constant HEADER-ID = "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1";

constant PPS-TYPE-DIR  = 1;
constant PPS-TYPE-FILE = 2;
constant PPS-TYPE-ROOT = 5;

constant DATA-SIZE    = 0x1000; # Upper limit of Data size, fallback to file
constant LONGINT-SIZE = 4;
constant PPS-SIZE     = 0x80;

has $._FILE; # String or IO::Handle or ...

multi method new( $_FILE ) {
  self.bless( :$_FILE );
}

method pps-tree( $bData? ) {
  my $rhInfo = _init-parse( $._FILE );
die $rhInfo;
  my $oPps = _pps-tree( 0, $rhInfo, $bData );
  $oPps;
}

sub _pps-tree( Int $iNo, $rhInfo, $bData, $raDone? ) {
}

method pps-search( $raName, $bData?, Int $iCase? ) {
  my $rhInfo = _init-parse( $._FILE );
  my @aList = _pps-search( 0, $rhInfo, $raName, $bData, $iCase );
  @aList;
}

sub _pps-search( Int $iNo, $rhINfo, $raName, $bData, Int $iCase, $raDone? ) {
}

method nth-pps( Int $iNo, $bData? ) {
  my $rhInfo = _init-parse( $._FILE );
  my $oPps = _nth-pps( $iNo, $rhInfo, $bData );
  $oPps;
}

sub _nth-pps( Int $iPos, %rhInfo, $bData ) {
  my Int $iPpsStart = %rhInfo<_ROOT_START>;
  my Int ( $iPpsBlock, $iPpsPos );
  my Buf $sWk;
  my Int $iBlock;

  my Int $iBaseCnt = Int( %rhInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  $iPpsBlock = Int( $iPos / $iBaseCnt );
  $iPpsPos   = $iPos % $iBaseCnt;

  $iBlock = _nth-block-no( $iPpsStart, $iPpsBlock, %rhInfo );
  die "No block found" unless defined $iBlock;
}

sub _nth-block-no( Int $iStBlock, Int $iNth, %rhInfo ) {
  my Int $iSv;
  my Int $iNext = $iStBlock;
  loop ( my $i = 0; $i < $iNth; $i++ ) {
    $iSv = $iNext;
    $iNext = _next-block-no( $iSv, %rhInfo );
    return Nil unless _is-normal-block( $iNext );
  }
  $iNext;
}

sub _next-block-no( Int $iBlockNo, %rhInfo ) {
  my Int $iRes = %rhInfo<_BBD_INFO>.{$iBlockNo};
  return defined( $iRes ) ?? $iRes !! $iBlockNo + 1;
}

# Break out different IO styles her.
#
sub _init-parse( $file ) {
  my $oIo = open $file;
  _header-info( $oIo );
}

sub _header-info( $FILE ) {
  my %rhInfo =
    _FILEH_ => $FILE
  ;

  %rhInfo<_FILEH_>.seek: 0, SeekFromBeginning;
  my Str $sWk = %rhInfo<_FILEH_>.read( 8 ).unpack('A8');
  die "Header ID missing" if $sWk ne HEADER-ID;

  my Int $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x1E, 2, "v" );
  die "Big block size missing" unless defined( $iWk );
  %rhInfo<_BIG_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x20, 2, "v" );
  die "Small block size missing" unless defined( $iWk );
  %rhInfo<_SMALL_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x2C, 4, "v" );
  die "BDB count missing" unless defined( $iWk );
  %rhInfo<_BDB_COUNT> = $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x30, 4, "V" );
  die "Root start missing" unless defined( $iWk );
  %rhInfo<_ROOT_START> = $iWk;

# $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x38, 4, "v" );
# die "Min size BB missing" unless defined( $iWk );
# %rhInfo<_MIN_SIZE_BB> = $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x3C, 4, "V" );
  die "Small BD start missing" unless defined( $iWk );
  %rhInfo<_SBD_START> = $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x40, 4, "V" );
  die "Small BD count missing" unless defined( $iWk );
  %rhInfo<_SBD_COUNT> = $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x44, 4, "V" );
  die "Extra BBD start missing" unless defined( $iWk );
  %rhInfo<_EXTRA_BBD_START> = $iWk;

  $iWk = _info-from-file( %rhInfo<_FILEH_>, 0x48, 4, "V" );
  die "Extra BBD count missing" unless defined( $iWk );
  %rhInfo<_EXTRA_BBD_COUNT> = $iWk;

  # Get BBD Info
  #
  %rhInfo<_BBD_INFO> = _bbd-info( %rhInfo );

  # Get Root PPS
  #
  my $oRoot = _nth-pps( 0, %rhInfo, Nil );

warn %rhInfo.gist;
}

sub _info-from-file( $FILE, Int $iPos, Int $iLen, Str $sFmt ) {
  return Nil unless $FILE;
  return Nil if $FILE.seek( $iPos, SeekFromBeginning ) == 0;

  my Buf $sWk = $FILE.read: $iLen;
  if $sFmt ~~ 'v' {
    return Nil if $sWk.decode('ascii').chars != $iLen;
  }
  return $sWk.unpack( $sFmt );
}

# slight change here, flatten references a bit in general.
#
sub _bbd-info( %rhInfo ) {
  my @aBdList;
  my Int $iBdbCnt = %rhInfo<_BDB_COUNT>;
  my Int $iGetCnt;
  my Buf $sWk;
  my Int $i1stCnt = Int((%rhInfo<_BIG_BLOCK_SIZE> - 0x4c) / LONGINT-SIZE);
  my Int $iBdlCnt = Int(%rhInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE) - 1;

  # 1st BDList
  #
  %rhInfo<_FILEH_>.seek: 0x4c, SeekFromBeginning;
  $iGetCnt = ($iBdbCnt < $i1stCnt) ?? $iBdbCnt !! $i1stCnt;
  $sWk = %rhInfo<_FILEH_>.read: LONGINT-SIZE + $iGetCnt;
  @aBdList.append: $sWk.unpack: "V$iGetCnt";
  $iBdbCnt -= $iGetCnt;

  # Extra BDList
  #
  my Int $iBlock = %rhInfo<_EXTRA_BBD_START>;
  while $iBdbCnt > 0 and _is-normal-block( $iBlock ) {
    _set-file-pos( $iBlock, 0, %rhInfo );
    $iGetCnt = ( $iBdbCnt < $iBdlCnt ) ?? $iBdbCnt !! $iBdlCnt;
    $sWk = %rhInfo<_FILEH_>.read: LONGINT-SIZE + $iGetCnt;
    @aBdList.append: $sWk.unpack( "V$iGetCnt" );
    $iBdbCnt -= $iGetCnt;
    $sWk = %rhInfo<_FILEH_>.read: LONGINT-SIZE;
    $iBlock = $sWk.unpack( "V" );
  }

  # Get BDs
  #
  my @aWk;
  my %hBd;
  my Int $iBlkNo = 0;
  #my Int $iBdL;
  #my $i;
  my Int $iBdCnt = Int(%rhInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE);
  for @aBdList -> $iBdL {
    _set-file-pos( $iBdL, 0, %rhInfo );
    $sWk = %rhInfo<_FILEH_>.read: %rhInfo<_BIG_BLOCK_SIZE>;
    @aWk = $sWk.unpack( "V$iBdCnt" );
    loop ( my $i = 0; $i < $iBdCnt ; $i++, $iBlkNo++ ) {
      if @aWk[$i] != $iBlkNo + 1 {
	%hBd{$iBlkNo} = @aWk[$i];
      }
    }
  }
  return %hBd;
}

sub _set-file-pos( Int $iBlock, Int $iPos, %rhInfo ) {
  %rhInfo<_FILEH_>.seek: ( $iBlock + 1 ) * %rhInfo<_BIG_BLOCK_SIZE> + $iPos,
                         SeekFromBeginning;
}

sub _is-normal-block( Int $iBlock ) {
  $iBlock < 0xFFFFFFFC
}

#sub _getPpsTree($$$;$) {
#  my($iNo, $rhInfo, $bData, $raDone) = @_;
#  if(defined($raDone)) {
#    return () if(grep {$_ ==$iNo} @$raDone);
#  }
#  else {
#    $raDone=[];
#  }
#  push @$raDone, $iNo;
#
#  my $iRootBlock = $rhInfo->{_ROOT_START} ;
##1. Get Information about itself
#  my $oPps = _getNthPps($iNo, $rhInfo, $bData);
##2. Child
#  if($oPps->{DirPps} !=  0xFFFFFFFF) {
#    my @aChildL = _getPpsTree($oPps->{DirPps}, $rhInfo, $bData, $raDone);
#    $oPps->{Child} =  \@aChildL;
#  }
#  else {
#    $oPps->{Child} =  undef;
#  }
##3. Previous,Next PPSs
#  my @aList = ();
#  push @aList, _getPpsTree($oPps->{PrevPps}, $rhInfo, $bData, $raDone)
#                        if($oPps->{PrevPps} != 0xFFFFFFFF);
#  push @aList, $oPps;
#  push @aList, _getPpsTree($oPps->{NextPps}, $rhInfo, $bData, $raDone)
#                if($oPps->{NextPps} != 0xFFFFFFFF);
#  return @aList;
#}

#sub _getPpsSearch($$$$$;$) {
#  my($iNo, $rhInfo, $raName, $bData, $iCase, $raDone) = @_;
#  my $iRootBlock = $rhInfo->{_ROOT_START} ;
#  my @aRes;
##1. Check it self
#  if(defined($raDone)) {
#    return () if(grep {$_==$iNo} @$raDone);
#  }
#  else {
#    $raDone=[];
#  }
#  push @$raDone, $iNo;
#  my $oPps = _getNthPps($iNo, $rhInfo, undef);
#  if(($iCase && (grep(/^\Q$oPps->{Name}\E$/i, @$raName))) ||
#     (grep($_ eq $oPps->{Name}, @$raName))) {
#    $oPps = _getNthPps($iNo, $rhInfo, $bData) if ($bData);
#    @aRes = ($oPps);
#  }
#  else {
#    @aRes = ();
#  }
##2. Check Child, Previous, Next PPSs
#  push @aRes, _getPpsSearch($oPps->{DirPps},  $rhInfo, $raName, $bData, $iCase, $raDone)
#        if($oPps->{DirPps} !=  0xFFFFFFFF) ;
#  push @aRes, _getPpsSearch($oPps->{PrevPps}, $rhInfo, $raName, $bData, $iCase, $raDone)
#        if($oPps->{PrevPps} != 0xFFFFFFFF );
#  push @aRes, _getPpsSearch($oPps->{NextPps}, $rhInfo, $raName, $bData, $iCase, $raDone)
#        if($oPps->{NextPps} != 0xFFFFFFFF);
#  return @aRes;
#}

##===================================================================
## Get Header Info (BASE Information about that file)
##===================================================================
#sub _getHeaderInfo($) {
#  my($FILE) = @_;
#  my($iWk);
#  my $rhInfo = {};
#  $rhInfo->{_FILEH_} = $FILE;
#  my $sWk;
##0. Check ID
#  $rhInfo->{_FILEH_}->seek(0, 0);
#  $rhInfo->{_FILEH_}->read($sWk, 8);
#  return undef unless($sWk eq "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1");
##BIG BLOCK SIZE
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x1E, 2, "v");
#  return undef unless(defined($iWk));
#  $rhInfo->{_BIG_BLOCK_SIZE} = 2 ** $iWk;
##SMALL BLOCK SIZE
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x20, 2, "v");
#  return undef unless(defined($iWk));
#  $rhInfo->{_SMALL_BLOCK_SIZE} = 2 ** $iWk;
##BDB Count
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x2C, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_BDB_COUNT} = $iWk;
##START BLOCK
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x30, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_ROOT_START} = $iWk;
##MIN SIZE OF BB
##  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x38, 4, "V");
##  return undef unless(defined($iWk));
##  $rhInfo->{_MIN_SIZE_BB} = $iWk;
##SMALL BD START
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x3C, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_SBD_START} = $iWk;
##SMALL BD COUNT
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x40, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_SBD_COUNT} = $iWk;
##EXTRA BBD START
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x44, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_EXTRA_BBD_START} = $iWk;
##EXTRA BD COUNT
#  $iWk = _getInfoFromFile($rhInfo->{_FILEH_}, 0x48, 4, "V");
#  return undef unless(defined($iWk));
#  $rhInfo->{_EXTRA_BBD_COUNT} = $iWk;

##GET BBD INFO
#  $rhInfo->{_BBD_INFO}= _getBbdInfo($rhInfo);
##GET ROOT PPS
#  my $oRoot = _getNthPps(0, $rhInfo, undef);
#  $rhInfo->{_SB_START} = $oRoot->{StartBlock};
#  $rhInfo->{_SB_SIZE}  = $oRoot->{Size};
#  return $rhInfo;
#}

#sub _getInfoFromFile($$$$) {
#  my($FILE, $iPos, $iLen, $sFmt) =@_;
#  my($sWk);
#  return undef unless($FILE);
#  return undef if($FILE->seek($iPos, 0)==0);
#  return undef if($FILE->read($sWk,  $iLen)!=$iLen);
#  return unpack($sFmt, $sWk);
#}

#sub _getBbdInfo($) {
#  my($rhInfo) =@_;
#  my @aBdList = ();
#  my $iBdbCnt = $rhInfo->{_BDB_COUNT};
#  my $iGetCnt;
#  my $sWk;
#  my $i1stCnt = int(($rhInfo->{_BIG_BLOCK_SIZE} - 0x4C) / LONGINT-SIZE);
#  my $iBdlCnt = int($rhInfo->{_BIG_BLOCK_SIZE} / LONGINT-SIZE) - 1;

##1. 1st BDlist
#  $rhInfo->{_FILEH_}->seek(0x4C, 0);
#  $iGetCnt = ($iBdbCnt < $i1stCnt)? $iBdbCnt: $i1stCnt;
#  $rhInfo->{_FILEH_}->read($sWk, LONGINT-SIZE*$iGetCnt);
#  push @aBdList, unpack("V$iGetCnt", $sWk);
#  $iBdbCnt -= $iGetCnt;

##2. Extra BDList
#  my $iBlock = $rhInfo->{_EXTRA_BBD_START};
#  while(($iBdbCnt> 0) && _isNormalBlock($iBlock)){
#    _setFilePos($iBlock, 0, $rhInfo);
#    $iGetCnt= ($iBdbCnt < $iBdlCnt)? $iBdbCnt: $iBdlCnt;
#    $rhInfo->{_FILEH_}->read($sWk, LONGINT-SIZE*$iGetCnt);
#    push @aBdList, unpack("V$iGetCnt", $sWk);
#    $iBdbCnt -= $iGetCnt;
#    $rhInfo->{_FILEH_}->read($sWk, LONGINT-SIZE);
#    $iBlock = unpack("V", $sWk);
#  }
##3.Get BDs
#  my @aWk;
#  my %hBd;
#  my $iBlkNo = 0;
#  my $iBdL;
#  my $i;
#  my $iBdCnt = int($rhInfo->{_BIG_BLOCK_SIZE} / LONGINT-SIZE);
#  foreach $iBdL (@aBdList) {
#    _setFilePos($iBdL, 0, $rhInfo);
#    $rhInfo->{_FILEH_}->read($sWk, $rhInfo->{_BIG_BLOCK_SIZE});
#    @aWk = unpack("V$iBdCnt", $sWk);
#    for($i=0;$i<$iBdCnt;$i++, $iBlkNo++) {
#       if($aWk[$i] != ($iBlkNo+1)){
#            $hBd{$iBlkNo} = $aWk[$i];
#        }
#    }
#  }
#  return \%hBd;
#}

#sub _getNthPps($$$) {
#  my($iPos, $rhInfo, $bData) = @_;
#  my($iPpsStart) = ($rhInfo->{_ROOT_START});
#  my($iPpsBlock, $iPpsPos);
#  my $sWk;
#  my $iBlock;
#
#  my $iBaseCnt = $rhInfo->{_BIG_BLOCK_SIZE} / PPS-SIZE;
#  $iPpsBlock = int($iPos / $iBaseCnt);
#  $iPpsPos   = $iPos % $iBaseCnt;
#
#  $iBlock = _getNthBlockNo($iPpsStart, $iPpsBlock, $rhInfo);
#  return undef unless(defined($iBlock));
#
#  _setFilePos($iBlock, PPS-SIZE * $iPpsPos, $rhInfo);
#  $rhInfo->{_FILEH_}->read($sWk, PPS-SIZE);
#  return undef unless($sWk);
#  my $iNmSize = unpack("v", substr($sWk, 0x40, 2));
#  $iNmSize = ($iNmSize > 2)? $iNmSize - 2 : $iNmSize;
#  my $sNm= substr($sWk, 0, $iNmSize);
#  my $iType = unpack("C", substr($sWk, 0x42, 2));
#  my $lPpsPrev = unpack("V", substr($sWk, 0x44, LONGINT-SIZE));
#  my $lPpsNext = unpack("V", substr($sWk, 0x48, LONGINT-SIZE));
#  my $lDirPps  = unpack("V", substr($sWk, 0x4C, LONGINT-SIZE));
#  my @raTime1st =
#        (($iType == PPS-TYPE-ROOT) or ($iType == PPS-TYPE-DIR))?
#            OLEDate2Local(substr($sWk, 0x64, 8)) : undef ,
#  my @raTime2nd =
#        (($iType == PPS-TYPE-ROOT) or ($iType == PPS-TYPE-DIR))?
#            OLEDate2Local(substr($sWk, 0x6C, 8)) : undef,
#  my($iStart, $iSize) = unpack("VV", substr($sWk, 0x74, 8));
#  if($bData) {
#      my $sData = _getData($iType, $iStart, $iSize, $rhInfo);
#      return OLE::Storage_Lite::PPS->new(
#        $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
#        \@raTime1st, \@raTime2nd, $iStart, $iSize, $sData, undef);
#  }
#  else {
#      return OLE::Storage_Lite::PPS->new(
#        $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
#        \@raTime1st, \@raTime2nd, $iStart, $iSize, undef, undef);
#  }
#}

#sub _setFilePos($$$) {
#  my($iBlock, $iPos, $rhInfo) = @_;
#  $rhInfo->{_FILEH_}->seek(($iBlock+1)*$rhInfo->{_BIG_BLOCK_SIZE}+$iPos, 0);
#}

#sub _getNthBlockNo($$$) {
#  my($iStBlock, $iNth, $rhInfo) = @_;
#  my $iSv;
#  my $iNext = $iStBlock;
#  for(my $i =0; $i<$iNth; $i++) {
#    $iSv = $iNext;
#    $iNext = _getNextBlockNo($iSv, $rhInfo);
#    return undef unless _isNormalBlock($iNext);
#  }
#  return $iNext;
#}

#sub _getData($$$$) {
#  my($iType, $iBlock, $iSize, $rhInfo) = @_;
#  if ($iType == PPS-TYPE-FILE) {
#    if($iSize < DATA-SIZE) {
#        return _getSmallData($iBlock, $iSize, $rhInfo);
#    }
#    else {
#        return _getBigData($iBlock, $iSize, $rhInfo);
#    }
#  }
#  elsif($iType == PPS-TYPE-ROOT) {  #Root
#    return _getBigData($iBlock, $iSize, $rhInfo);
#  }
#  elsif($iType == PPS-TYPE-DIR) {  # Directory
#    return undef;
#  }
#}

#sub _getBigData($$$) {
#  my($iBlock, $iSize, $rhInfo) = @_;
#  my($iRest, $sWk, $sRes);
#
#  return '' unless(_isNormalBlock($iBlock));
#  $iRest = $iSize;
#  my($i, $iGetSize, $iNext);
#  $sRes = '';
#  my @aKeys= sort({$a<=>$b} keys(%{$rhInfo->{_BBD_INFO}}));
#
#  while ($iRest > 0) {
#    my @aRes = grep($_ >= $iBlock, @aKeys);
#    my $iNKey = $aRes[0];
#    $i = $iNKey - $iBlock;
#    $iNext = $rhInfo->{_BBD_INFO}{$iNKey};
#    _setFilePos($iBlock, 0, $rhInfo);
#    my $iGetSize = ($rhInfo->{_BIG_BLOCK_SIZE} * ($i+1));
#    $iGetSize = $iRest if($iRest < $iGetSize);
#    $rhInfo->{_FILEH_}->read( $sWk, $iGetSize);
#    $sRes .= $sWk;
#    $iRest -= $iGetSize;
#    $iBlock= $iNext;
#  }
#  return $sRes;
#}

#sub _getNextBlockNo($$){
#  my($iBlockNo, $rhInfo) = @_;
#  my $iRes = $rhInfo->{_BBD_INFO}->{$iBlockNo};
#  return defined($iRes)? $iRes: $iBlockNo+1;
#}

##------------------------------------------------------------------------------
## _isNormalBlock (OLE::Storage_Lite)
## 0xFFFFFFFC : BDList, 0xFFFFFFFD : BBD,
## 0xFFFFFFFE: End of Chain 0xFFFFFFFF : unused
##------------------------------------------------------------------------------
#sub _isNormalBlock($){
#  my($iBlock) = @_;
#  return ($iBlock < 0xFFFFFFFC)? 1: undef;
#}

#sub _getSmallData($$$) {
#  my($iSmBlock, $iSize, $rhInfo) = @_;
#  my($sRes, $sWk);
#  my $iRest = $iSize;
#  $sRes = '';
#  while ($iRest > 0) {
#    _setFilePosSmall($iSmBlock, $rhInfo);
#    $rhInfo->{_FILEH_}->read($sWk,
#        ($iRest >= $rhInfo->{_SMALL_BLOCK_SIZE})?
#            $rhInfo->{_SMALL_BLOCK_SIZE}: $iRest);
#    $sRes .= $sWk;
#    $iRest -= $rhInfo->{_SMALL_BLOCK_SIZE};
#    $iSmBlock= _getNextSmallBlockNo($iSmBlock, $rhInfo);
#  }
#  return $sRes;
#}

#sub _setFilePosSmall($$) {
#  my($iSmBlock, $rhInfo) = @_;
#  my $iSmStart = $rhInfo->{_SB_START};
#  my $iBaseCnt = $rhInfo->{_BIG_BLOCK_SIZE} / $rhInfo->{_SMALL_BLOCK_SIZE};
#  my $iNth = int($iSmBlock/$iBaseCnt);
#  my $iPos = $iSmBlock % $iBaseCnt;
#
#  my $iBlk = _getNthBlockNo($iSmStart, $iNth, $rhInfo);
#  _setFilePos($iBlk, $iPos * $rhInfo->{_SMALL_BLOCK_SIZE}, $rhInfo);
#}

#sub _getNextSmallBlockNo($$) {
#  my($iSmBlock, $rhInfo) = @_;
#  my($sWk);
#
#  my $iBaseCnt = $rhInfo->{_BIG_BLOCK_SIZE} / LONGINT-SIZE;
#  my $iNth = int($iSmBlock/$iBaseCnt);
#  my $iPos = $iSmBlock % $iBaseCnt;
#  my $iBlk = _getNthBlockNo($rhInfo->{_SBD_START}, $iNth, $rhInfo);
#  _setFilePos($iBlk, $iPos * LONGINT-SIZE, $rhInfo);
#  $rhInfo->{_FILEH_}->read($sWk, LONGINT-SIZE);
#  return unpack("V", $sWk);
#
#}

#sub Asc2Ucs($) {
#  my($sAsc) = @_;
#  return join("\x00", split //, $sAsc) . "\x00";
#}

#sub Ucs2Asc($) {
#  my($sUcs) = @_;
#  return join('', map(pack('c', $_), unpack('v*', $sUcs)));
#}

##------------------------------------------------------------------------------
## OLEDate2Local()
##
## Convert from a Window FILETIME structure to a localtime array. FILETIME is
## a 64-bit value representing the number of 100-nanosecond intervals since
## January 1 1601.
##
## We first convert the FILETIME to seconds and then subtract the difference
## between the 1601 epoch and the 1970 Unix epoch.
##
#sub OLEDate2Local {
#
#    my $oletime = shift;
#
#    # Unpack the FILETIME into high and low longs.
#    my ( $lo, $hi ) = unpack 'V2', $oletime;
#
#    # Convert the longs to a double.
#    my $nanoseconds = $hi * 2**32 + $lo;
#
#    # Convert the 100 nanosecond units into seconds.
#    my $time = $nanoseconds / 1e7;
#
#    # Subtract the number of seconds between the 1601 and 1970 epochs.
#    $time -= 11644473600;
#
#    # Convert to a localtime (actually gmtime) structure.
#    my @localtime = gmtime($time);
#
#    return @localtime;
#}

##------------------------------------------------------------------------------
## LocalDate2OLE()
##
## Convert from a a localtime array to a Window FILETIME structure. FILETIME is
## a 64-bit value representing the number of 100-nanosecond intervals since
## January 1 1601.
##
## We first convert the localtime (actually gmtime) to seconds and then add the
## difference between the 1601 epoch and the 1970 Unix epoch. We convert that to
## 100 nanosecond units, divide it into high and low longs and return it as a
## packed 64bit structure.
##
#sub LocalDate2OLE {
#
#    my $localtime = shift;
#
#    return "\x00" x 8 unless $localtime;
#
#    # Convert from localtime (actually gmtime) to seconds.
#    my $time = timegm( @{$localtime} );
#
#    # Add the number of seconds between the 1601 and 1970 epochs.
#    $time += 11644473600;
#
#    # The FILETIME seconds are in units of 100 nanoseconds.
#    my $nanoseconds = $time * 1E7;
#
#use POSIX 'fmod';
#
#    # Pack the total nanoseconds into 64 bits...
#    my $hi = int( $nanoseconds / 2**32 );
#    my $lo = fmod($nanoseconds, 2**32);
#
#    my $oletime = pack "VV", $lo, $hi;
#
#    return $oletime;
#}

#1;

#=head1 NAME
#
#OLE::Storage_Lite - Simple Class for OLE document interface.
#
#=head1 SYNOPSIS
#
#    use OLE::Storage_Lite;
#
#    # Initialize.
#
#    # From a file
#    my $oOl = OLE::Storage_Lite->new("some.xls");
#
#    # From a filehandle object
#    use IO::File;
#    my $oIo = new IO::File;
#    $oIo->open("<iofile.xls");
#    binmode($oIo);
#    my $oOl = OLE::Storage_Lite->new($oFile);
#
#    # Read data
#    my $oPps = $oOl->getPpsTree(1);
#
#    # Save Data
#    # To a File
#    $oPps->save("kaba.xls"); #kaba.xls
#    $oPps->save('-');        #STDOUT
#
#    # To a filehandle object
#    my $oIo = new IO::File;
#    $oIo->open(">iofile.xls");
#    bimode($oIo);
#    $oPps->save($oIo);
#
#
#=head1 DESCRIPTION
#
#OLE::Storage_Lite allows you to read and write an OLE structured file.
#
#OLE::Storage_Lite::PPS is a class representing PPS. OLE::Storage_Lite::PPS::Root, OLE::Storage_Lite::PPS::File and OLE::Storage_Lite::PPS::Dir
#are subclasses of OLE::Storage_Lite::PPS.
#
#
#=head2 new()
#
#Constructor.
#
#    $oOle = OLE::Storage_Lite->new($sFile);
#
#Creates a OLE::Storage_Lite object for C<$sFile>. C<$sFile> must be a correct file name.
#
#The C<new()> constructor also accepts a valid filehandle. Remember to C<binmode()> the filehandle first.
#
#
#=head2 getPpsTree()
#
#    $oPpsRoot = $oOle->getPpsTree([$bData]);
#
#Returns PPS as an OLE::Storage_Lite::PPS::Root object.
#Other PPS objects will be included as its children.
#
#If C<$bData> is true, the objects will have data in the file.
#
#
#=head2 getPpsSearch()
#
#    $oPpsRoot = $oOle->getPpsTree($raName [, $bData][, $iCase] );
#
#Returns PPSs as OLE::Storage_Lite::PPS objects that has the name specified in C<$raName> array.
#
#If C<$bData> is true, the objects will have data in the file.
#If C<$iCase> is true, search is case insensitive.
#
#
#=head2 getNthPps()
#
#    $oPpsRoot = $oOle->getNthPps($iNth [, $bData]);
#
#Returns PPS as C<OLE::Storage_Lite::PPS> object specified number C<$iNth>.
#
#If C<$bData> is true, the objects will have data in the file.
#
#
#=head2 Asc2Ucs()
#
#    $sUcs2 = OLE::Storage_Lite::Asc2Ucs($sAsc>);
#
#Utility function. Just adds 0x00 after every characters in C<$sAsc>.
#
#
#=head2 Ucs2Asc()
#
#    $sAsc = OLE::Storage_Lite::Ucs2Asc($sUcs2);
#
#Utility function. Just deletes 0x00 after words in C<$sUcs>.
#
#
#=head1 OLE::Storage_Lite::PPS
#
#OLE::Storage_Lite::PPS has these properties:
#
#=over 4
#
#=item No
#
#Order number in saving.
#
#=item Name
#
#Its name in UCS2 (a.k.a Unicode).
#
#=item Type
#
#Its type (1:Dir, 2:File (Data), 5: Root)
#
#=item PrevPps
#
#Previous pps (as No)
#
#=item NextPps
#
#Next pps (as No)
#
#=item DirPps
#
#Dir pps (as No).
#
#=item Time1st
#
#Timestamp 1st in array ref as similar fomat of localtime.
#
#=item Time2nd
#
#Timestamp 2nd in array ref as similar fomat of localtime.
#
#=item StartBlock
#
#Start block number
#
#=item Size
#
#Size of the pps
#
#=item Data
#
#Its data
#
#=item Child
#
#Its child PPSs in array ref
#
#=back
#
#
#=head1 OLE::Storage_Lite::PPS::Root
#
#OLE::Storage_Lite::PPS::Root has 2 methods.
#
#=head2 new()
#
#    $oRoot = OLE::Storage_Lite::PPS::Root->new(
#                    $raTime1st,
#                    $raTime2nd,
#                    $raChild);
#
#
#Constructor.
#
#C<$raTime1st>, C<$raTime2nd> are array refs with ($iSec, $iMin, $iHour, $iDay, $iMon, $iYear).
#$iSec means seconds, $iMin means minutes. $iHour means hours.
#$iDay means day. $iMon is month -1. $iYear is year - 1900.
#
#C<$raChild> is a array ref of children PPSs.
#
#
#=head2 save()
#
#    $oRoot = $oRoot>->save(
#                    $sFile,
#                    $bNoAs);
#
#
#Saves information into C<$sFile>. If C<$sFile> is '-', this will use STDOUT.
#
#The C<new()> constructor also accepts a valid filehandle. Remember to C<binmode()> the filehandle first.
#
#If C<$bNoAs> is defined, this function will use the No of PPSs for saving order.
#If C<$bNoAs> is undefined, this will calculate PPS saving order.
#
#
#=head1 OLE::Storage_Lite::PPS::Dir
#
#OLE::Storage_Lite::PPS::Dir has 1 method.
#
#=head2 new()
#
#    $oRoot = OLE::Storage_Lite::PPS::Dir->new(
#                    $sName,
#                  [, $raTime1st]
#                  [, $raTime2nd]
#                  [, $raChild>]);
#
#
#Constructor.
#
#C<$sName> is a name of the PPS.
#
#C<$raTime1st>, C<$raTime2nd> is a array ref as
#($iSec, $iMin, $iHour, $iDay, $iMon, $iYear).
#$iSec means seconds, $iMin means minutes. $iHour means hours.
#$iDay means day. $iMon is month -1. $iYear is year - 1900.
#
#C<$raChild> is a array ref of children PPSs.
#
#
#=head1 OLE::Storage_Lite::PPS::File
#
#OLE::Storage_Lite::PPS::File has 3 method.
#
#=head2 new
#
#    $oRoot = OLE::Storage_Lite::PPS::File->new($sName, $sData);
#
#C<$sName> is name of the PPS.
#
#C<$sData> is data of the PPS.
#
#
#=head2 newFile()
#
#    $oRoot = OLE::Storage_Lite::PPS::File->newFile($sName, $sFile);
#
#This function makes to use file handle for geting and storing data.
#
#C<$sName> is name of the PPS.
#
#If C<$sFile> is scalar, it assumes that is a filename.
#If C<$sFile> is an IO::Handle object, it uses that specified handle.
#If C<$sFile> is undef or '', it uses temporary file.
#
#CAUTION: Take care C<$sFile> will be updated by C<append> method.
#So if you want to use IO::Handle and append a data to it,
#you should open the handle with "r+".
#
#
#=head2 append()
#
#    $oRoot = $oPps->append($sData);
#
#appends specified data to that PPS.
#
#C<$sData> is appending data for that PPS.
#
#
#=head1 CAUTION
#
#A saved file with VBA (a.k.a Macros) by this module will not work correctly.
#However modules can get the same information from the file,
#the file occurs a error in application(Word, Excel ...).
#
#
#=head1 DEPRECATED FEATURES
#
#Older version of C<OLE::Storage_Lite> autovivified a scalar ref in the C<new()> constructors into a scalar filehandle. This functionality is still there for backwards compatibility but it is highly recommended that you do not use it. Instead create a filehandle (scalar or otherwise) and pass that in.
#
#
#=head1 COPYRIGHT
#
#The OLE::Storage_Lite module is Copyright (c) 2000,2001 Kawai Takanori. Japan.
#All rights reserved.
#
#You may distribute under the terms of either the GNU General Public
#License or the Artistic License, as specified in the Perl README file.
#
#
#=head1 ACKNOWLEDGEMENTS
#
#First of all, I would like to acknowledge to Martin Schwartz and his module OLE::Storage.
#
#
#=head1 AUTHOR
#
#Kawai Takanori kwitknr@cpan.org
#
#This module is currently maintained by John McNamara jmcnamara@cpan.org
#
#
#=head1 SEE ALSO
#
#OLE::Storage
#
#Documentation for the OLE Compound document has been released by Microsoft under the I<Open Specification Promise>. See http://www.microsoft.com/interop/docs/supportingtechnologies.mspx
#
#The Digital Imaging Group have also detailed the OLE format in the JPEG2000 specification: see Appendix A of http://www.i3a.org/pdf/wg1n1017.pdf
#
#
#=cut
