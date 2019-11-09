use v6;

unit class OLE::Storage_Lite;

use OLE::Storage_Lite::PPS::Dir;
use OLE::Storage_Lite::PPS::File;
use OLE::Storage_Lite::PPS::Root;

use experimental :pack;
use P5localtime;

# A couple of notes on how I translated (loosely) this from the Perl 5 module:
#
# To save time I've Raku-ified method names where appropriate, which is to say
# pretty much everywhere. Camel case goes to kebab case, and I've dropped 'get'
# because it seems redundant.
#
# I'm taking advantage of being able to pass along array and hash types, and
# leaving hash "attribute"s as just that, attributes.
#
#   This is probably most notable with the %rhInfo and @Time{1st,2nd} vars.
#
# Dropping parens where unneeded, and also dropping parens around the new
# unpack/pack methods so I can better delineate where they go.
#
# Dropping unneeded 'return's on the last line.
#
# I'm leaving the method/function distinctions alone for the time being, simply
# because it's easier that way. Also it'll be easier to find changes from the
# Perl 5 module in the new Raku code.

# Once I've gotten it tested and able to do its job in Raku I'll feel better
# about completely rearranging things to work better in Raku.

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

sub _nth-pps( Int $iPos, %hInfo, $bData ) {
  my Int $iPpsStart = %hInfo<_ROOT_START>;
  my Int ( $iPpsBlock, $iPpsPos );
  my Buf $sWk;
  my Int $iBlock;

  my Int $iBaseCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
warn "iBaseCnt: $iBaseCnt\n";
  $iPpsBlock = Int( $iPos / $iBaseCnt );
  $iPpsPos   = $iPos % $iBaseCnt;

  $iBlock = _nth-block-no( $iPpsStart, $iPpsBlock, %hInfo );
warn "iBlock: $iBlock\n";
  die "No block found" unless defined $iBlock;

  _set-file-pos( $iBlock, PPS-SIZE * $iPpsPos, %hInfo );
  $sWk = %hInfo<_FILEH_>.read: PPS-SIZE;
  return Nil unless defined $iBlock;
  my Int $iNmSize = $sWk.subbuf( 0x40, 2 ).unpack: "v";
warn "iNmSize: $iNmSize\n";
  $iNmSize = ( $iNmSize > 2 ) ?? $iNmSize - 2 !! $iNmSize;
  my Buf $sNm   = $sWk.subbuf( 0, $iNmSize );
  my Int $iType = $sWk.subbuf( 0x42, 2 ).unpack: "C";
  my $lPpsPrev  = $sWk.subbuf( 0x44, LONGINT-SIZE ).unpack: "V";
  my $lPpsNext  = $sWk.subbuf( 0x48, LONGINT-SIZE ).unpack: "V";
  my $lDirPps   = $sWk.subbuf( 0x4C, LONGINT-SIZE ).unpack: "V";
  my @raTime1st =
     (( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
        OLE-date-to-local( $sWk.subbuf( 0x64, 8 ) ) !! Nil;
  my @raTime2nd =
     (( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
        OLE-date-to-local( $sWk.subbuf( 0x6c, 8 ) ) !! Nil;
  my Int ( $iStart, $iSize ) = $sWk.subbuf( 0x74, 8 ).unpack: "VV";
  if $bData {
    my $sData = _data( $iType, $iStart, $iSize, %hInfo );
#    return OLE::Storage_Lite::PPS.new
    return create-PPS(
      $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @raTime1st, @raTime2nd, $iStart, $iSize, $sData, Nil
    );
  }
  else {
#    return OLE::Storage_Lite::PPS.new
    return create-PPS(
      $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @raTime1st, @raTime2nd, $iStart, $iSize
    );
  }
}

# Rename 'new' to 'create', for the moment.
# The bless() mechanism isn't working for me...

sub create-PPS( $iNo, $sNm, $iType, $iPrev, $iNext, $iDir,
                @raTime1st, @raTime2nd, $iStart, $iSize, $sData?, @raChild? ) {
  if $iType == 2 { #OLE::Storage_Lite::PPS-TYPE-FILE {
    OLE::Storage_Lite::PPS::File.new(
      :No( $iNo ),
      :Name( $sNm.decode('utf-8') ),
      :Type( $iType ),
      :PrevPps( $iPrev ),
      :NextPps( $iNext ),
      :DirPps( $iDir ),
      :Time1st( @raTime1st ),
      :Time2nd( @raTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @raChild )
    )
  }
  elsif $iType == 1 { #OLE::Storage_Lite::PPS-TYPE-DIR {
    OLE::Storage_Lite::PPS::Dir.new(
      :No( $iNo ),
      :Name( $sNm.decode('utf-8') ),
      :Type( $iType ),
      :PrevPps( $iPrev ),
      :NextPps( $iNext ),
      :DirPps( $iDir ),
      :Time1st( @raTime1st ),
      :Time2nd( @raTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @raChild )
    )
  }
  elsif $iType == 5 { #OLE::Storage_Lite::PPS-TYPE-ROOT {
    OLE::Storage_Lite::PPS::Root.new(
      :No( $iNo ),
      :Name( $sNm.decode('utf-8') ),
      :Type( $iType ),
      :PrevPps( $iPrev ),
      :NextPps( $iNext ),
      :DirPps( $iDir ),
      :Time1st( @raTime1st ),
      :Time2nd( @raTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @raChild )
    )
  }
  else {
    die "Can't find PPS type $iType";
  }
}

sub _data( Int $iType, Int $iBlock, Int $iSize, %hInfo ) {
  if $iType == PPS-TYPE-FILE {
    if $iSize < DATA-SIZE {
      return _small-data( $iBlock, $iSize, %hInfo );
    }
    else {
      return _big-data( $iBlock, $iSize, %hInfo );
    }
  }
  elsif $iType == PPS-TYPE-ROOT {
    return _big-data( $iBlock, $iSize, %hInfo );
  }
  elsif $iType == PPS-TYPE-DIR {
    return;
  }
}

sub _small-data( Int $iSmBlock, Int $iSize, %hInfo ) {
  my ( $sRes, $sWk );
  my Int $iRest = $iSize;
  $sRes = '';
  while $iRest > 0 {
    _set-file-pos-small( $iSmBlock, %hInfo );
    $sWk = %hInfo<_FILEH>>.read(
             ( $iRest >= %hInfo<_SMALL_BLOCK_SIZE>) ??
	       %hInfo<_SMALL_BLOCK_SIZE> !!
	       $iRest );
    $sRes ~= $sWk;
    $iRest -= %hInfo<_SMALL_BLOCK_SIZE>;
    $iSmBlock = _next-small-block-no( $iSmBlock, %hInfo );
  }
  return $sRes;
}

sub _next-small-block-no( Int $iSmBlock, %hInfo ) {
  my Buf $sWk;

  my $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE;
  my $iNth = Int( $iSmBlock / $iBaseCnt );
  my $iPos = $iSmBlock % $iBaseCnt;
  my $iBlk = _nth-block-no( %hInfo<_SBD_START>, $iNth, %hInfo );
  _set-file-pos( $iBlk, $iPos * LONGINT-SIZE, %hInfo );
  $sWk = %hInfo<_FILEH_>.read: LONGINT-SIZE;
  return $sWk.unpack( "V" );
}

sub _set-file-pos-small( Int $iSmBlock, %hInfo ) {
  my Int $iSmStart = %hInfo<_SB_START>;
  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iNth = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos = $iSmBlock % $iBaseCnt;

  my Int $iBlk = _nth-block-no( $iSmStart, $iNth, %hInfo );
  _set-file-pos( $iBlk, $iPos * %hInfo<_SMALL_BLOCK_SIZE>, %hInfo );
}

sub _big-data( Int $iBlock, Int $iSize, %hInfo ) {
  my ( $iRest, $sWk, $sRes );

  return '' unless _is-normal-block( $iBlock );
  $iRest = $iSize;
  my ( $i, $iGetSize, $iNext );
  $sRes = '';
  my @aKeys = sort { $^a <=> $^b }, keys %( %hInfo<_BBD_INFO> );

  while $iRest > 0 {
    my @aRes = grep { $_ >= $iBlock }, @aKeys;
    my Int $iNKey = @aRes[0];
    $i = $iNKey - $iBlock;
    $iNext = %hInfo<_BBD_INFO>{$iNKey};
    _set-file-pos( $iBlock, 0, %hInfo );
    my $iGetSize = %hInfo<_BIG_BLOCK_SIZE> * ($i + 1);
    $iGetSize = $iRest if $iRest < $iGetSize;
    $sWk = %hInfo<_FILEH_>.read: $iGetSize;
    $sRes ~= $sWk;
    $iRest -= $iGetSize;
    $iBlock = $iNext;
  }
  $sRes;
}

sub OLE-date-to-local( $oletime ) {

  # Unpack FILETIME into high and low longs
  #
  my ( $lo, $hi ) = $oletime.unpack: "V2";

  # Convert the longs to a double
  #
  my $nanoseconds = $hi * 2**32 + $lo;

  # Convert the 100ns units to seconds
  #
  my $time = $nanoseconds / 1e7;

  # Subtract the number of seconds between the 1601 and 1970 epocs
  #
  $time -= 11644473600;

}

sub _nth-block-no( Int $iStBlock, Int $iNth, %hInfo ) {
  my Int $iSv;
  my Int $iNext = $iStBlock;
  loop ( my $i = 0; $i < $iNth; $i++ ) {
    $iSv = $iNext;
    $iNext = _next-block-no( $iSv, %hInfo );
    return Nil unless _is-normal-block( $iNext );
  }
  $iNext;
}

sub _next-block-no( Int $iBlockNo, %hInfo ) {
  my Int $iRes = %hInfo<_BBD_INFO>.{$iBlockNo};
  return defined( $iRes ) ?? $iRes !! $iBlockNo + 1;
}

# Break out different IO styles her.
#
sub _init-parse( $file ) {
  my $oIo = open $file;
  _header-info( $oIo );
}

sub _header-info( $FILE ) {
  my %hInfo =
    _FILEH_ => $FILE
  ;

  %hInfo<_FILEH_>.seek: 0, SeekFromBeginning;
  my Str $sWk = %hInfo<_FILEH_>.read( 8 ).unpack('A8');
  die "Header ID missing" if $sWk ne HEADER-ID;

  my Int $iWk = _info-from-file( %hInfo<_FILEH_>, 0x1E, 2, "v" );
  die "Big block size missing" unless defined( $iWk );
  %hInfo<_BIG_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x20, 2, "v" );
  die "Small block size missing" unless defined( $iWk );
  %hInfo<_SMALL_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x2C, 4, "v" );
  die "BDB count missing" unless defined( $iWk );
  %hInfo<_BDB_COUNT> = $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x30, 4, "V" );
  die "Root start missing" unless defined( $iWk );
  %hInfo<_ROOT_START> = $iWk;

# $iWk = _info-from-file( %hInfo<_FILEH_>, 0x38, 4, "v" );
# die "Min size BB missing" unless defined( $iWk );
# %hInfo<_MIN_SIZE_BB> = $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x3C, 4, "V" );
  die "Small BD start missing" unless defined( $iWk );
  %hInfo<_SBD_START> = $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x40, 4, "V" );
  die "Small BD count missing" unless defined( $iWk );
  %hInfo<_SBD_COUNT> = $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x44, 4, "V" );
  die "Extra BBD start missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_START> = $iWk;

  $iWk = _info-from-file( %hInfo<_FILEH_>, 0x48, 4, "V" );
  die "Extra BBD count missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_COUNT> = $iWk;

  # Get BBD Info
  #
  %hInfo<_BBD_INFO> = _bbd-info( %hInfo );

  # Get Root PPS
  #
  my $oRoot = _nth-pps( 0, %hInfo, Nil );

warn %hInfo.gist;
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
sub _bbd-info( %hInfo ) {
  my @aBdList;
  my Int $iBdbCnt = %hInfo<_BDB_COUNT>;
  my Int $iGetCnt;
  my Buf $sWk;
  my Int $i1stCnt = Int((%hInfo<_BIG_BLOCK_SIZE> - 0x4c) / LONGINT-SIZE);
  my Int $iBdlCnt = Int(%hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE) - 1;

  # 1st BDList
  #
  %hInfo<_FILEH_>.seek: 0x4c, SeekFromBeginning;
  $iGetCnt = ($iBdbCnt < $i1stCnt) ?? $iBdbCnt !! $i1stCnt;
  $sWk = %hInfo<_FILEH_>.read: LONGINT-SIZE + $iGetCnt;
  @aBdList.append: $sWk.unpack: "V$iGetCnt";
  $iBdbCnt -= $iGetCnt;

  # Extra BDList
  #
  my Int $iBlock = %hInfo<_EXTRA_BBD_START>;
  while $iBdbCnt > 0 and _is-normal-block( $iBlock ) {
    _set-file-pos( $iBlock, 0, %hInfo );
    $iGetCnt = ( $iBdbCnt < $iBdlCnt ) ?? $iBdbCnt !! $iBdlCnt;
    $sWk = %hInfo<_FILEH_>.read: LONGINT-SIZE + $iGetCnt;
    @aBdList.append: $sWk.unpack( "V$iGetCnt" );
    $iBdbCnt -= $iGetCnt;
    $sWk = %hInfo<_FILEH_>.read: LONGINT-SIZE;
    $iBlock = $sWk.unpack( "V" );
  }

  # Get BDs
  #
  my @aWk;
  my %hBd;
  my Int $iBlkNo = 0;
  #my Int $iBdL;
  #my $i;
  my Int $iBdCnt = Int(%hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE);
  for @aBdList -> $iBdL {
    _set-file-pos( $iBdL, 0, %hInfo );
    $sWk = %hInfo<_FILEH_>.read: %hInfo<_BIG_BLOCK_SIZE>;
    @aWk = $sWk.unpack( "V$iBdCnt" );
    loop ( my $i = 0; $i < $iBdCnt ; $i++, $iBlkNo++ ) {
      if @aWk[$i] != $iBlkNo + 1 {
	%hBd{$iBlkNo} = @aWk[$i];
      }
    }
  }
  return %hBd;
}

sub _set-file-pos( Int $iBlock, Int $iPos, %hInfo ) {
  %hInfo<_FILEH_>.seek: ( $iBlock + 1 ) * %hInfo<_BIG_BLOCK_SIZE> + $iPos,
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
