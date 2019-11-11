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
#
# Actually that's a lie, it's easier to test things if everything is a method.
# I'll probably refactor it back once I'm sure of how it's going to be used.
#

# Once I've gotten it tested and able to do its job in Raku I'll feel better
# about completely rearranging things to work better in Raku.
#
# And yes, I do know that classes can have subs as well, I'm using subs until
# I figure out a better method of testing.

#------------------------------------------------------------------------------
# Consts for OLE::Storage_Lite
#------------------------------------------------------------------------------
#
constant HEADER-ID = "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1";

constant PPS-TYPE-DIR  = 1;
constant PPS-TYPE-FILE = 2;
constant PPS-TYPE-ROOT = 5;

constant DATA-SIZE    = 0x1000; # Upper limit of Data size, fallback to file
constant INT-SIZE     = 2;
constant LONGINT-SIZE = 4;
constant PPS-SIZE     = 0x80;

has $._FILE; # String or IO::Handle or ...

multi method new( $_FILE ) {
  self.bless( :$_FILE );
}

# I really don't think @aDone is useful in general
# But I'll keep it around until I have actual tests.
#
method getPpsTree( $bData? ) {
  my %hInfo = self._initParse( $._FILE );
my @aDone;
  my @oPps = _getPpsTree( 0, %hInfo, $bData, @aDone ); # @aDone is my own
  @oPps;
}

method getPpsSearch( @aName, $bData?, Int $iCase? ) {
  my %hInfo = self._initParse( $._FILE );
  my @aList = _getPpsSearch( 0, %hInfo, @aName, $bData, $iCase );
  @aList;
}

method getNthPps( Int $iNo, $bData? ) {
  my %hInfo = self._initParse( $._FILE );
  my $oPps  = _getNthPps( $iNo, %hInfo, $bData );
  $oPps;
}

# Break out different IO styles here.
#
method _initParse( $filename ) {
  my $oIo = open $filename;
  _getHeaderInfo( $oIo );
}

sub _getPpsTree( Int $iNo, %hInfo, $bData, @aDone ) {
  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }
  else {
    @aDone = ();
  }
  append @aDone, $iNo;

  my Int $iRootBlock = %hInfo<_ROOT_START>;

  my $oPps = _getNthPps( $iNo, %hInfo, $bData );

  if $oPps.DirPps != 2**32 - 1 {
    my @aChildL = _getPpsTree( $oPps.DirPps, %hInfo, $bData, @aDone );
    $oPps.Child = @aChildL;
  }
  else {
    $oPps.Child = ();
  }

  my @aList = ( );
  append @aList, _getPpsTree( $oPps.PrevPps, %hInfo, $bData, @aDone ) if
    $oPps.PrevPps != 2**32 - 1;
  append @aList, $oPps;
  append @aList, _getPpsTree( $oPps.NextPps, %hInfo, $bData, @aDone ) if
    $oPps.NextPps != 2**32 - 1;
  @aList;
}

sub _getPpsSearch( Int $iNo, %hInfo, @aName, $bData, Int $iCase, @aDone ) {
  my Int $iRootBlock = %hInfo<_ROOT_START>;
  my @aRes;

  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }
  else {
    @aDone = ( );
  }

  append @aDone, $iNo;
  my $oPps = _getNthPps( $iNo, %hInfo, Nil );
  if ( $iCase && grep { fc( $oPps.Name ) eq fc( $_ ) }, @aName ) or
       grep { $oPps.Name eq $_ }, @aName {
    $oPps = _getNthPps( $iNo, %hInfo, $bData ) if $bData;
    @aRes = $oPps;
  }
  else {
    @aRes = ( );
  }

  append @aRes, _getPpsSearch( $oPps.DirPps, %hInfo, @aName, $bData, $iCase, @aDone ) if
    $oPps.DirPps != 2**32 - 1;
  append @aRes, _getPpsSearch( $oPps.PrevPps, %hInfo, @aName, $bData, $iCase, @aDone ) if
    $oPps.PrevPps != 2**32 - 1;
  append @aRes, _getPpsSearch( $oPps.NextPps, %hInfo, @aName, $bData, $iCase, @aDone ) if
    $oPps.NextPps != 2**32 - 1;

  @aRes;
}

sub _getHeaderInfo( $FILE ) {
  my %hInfo =
    _FILEH_ => $FILE
  ;

  %hInfo<_FILEH_>.seek( 0, SeekFromBeginning );
  my Str $sWk = %hInfo<_FILEH_>.read( 8 ).unpack('A8');
  die "Header ID missing" if $sWk ne HEADER-ID;

  my Int $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x1E, 2, "v" );
  die "Big block size missing" unless defined( $iWk );
  %hInfo<_BIG_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x20, 2, "v" );
  die "Small block size missing" unless defined( $iWk );
  %hInfo<_SMALL_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x2C, 4, "v" );
  die "BDB count missing" unless defined( $iWk );
  %hInfo<_BDB_COUNT> = $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x30, 4, "V" );
  die "Root start missing" unless defined( $iWk );
  %hInfo<_ROOT_START> = $iWk;

# $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x38, 4, "v" );
# die "Min size BB missing" unless defined( $iWk );
# %hInfo<_MIN_SIZE_BB> = $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x3C, 4, "V" );
  die "Small BD start missing" unless defined( $iWk );
  %hInfo<_SBD_START> = $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x40, 4, "V" );
  die "Small BD count missing" unless defined( $iWk );
  %hInfo<_SBD_COUNT> = $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x44, 4, "V" );
  die "Extra BBD start missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_START> = $iWk;

  $iWk = _getInfoFromFile( %hInfo<_FILEH_>, 0x48, 4, "V" );
  die "Extra BBD count missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_COUNT> = $iWk;

  # Get BBD Info
  #
  %hInfo<_BBD_INFO> = _getBbdInfo( %hInfo );

  # Get Root PPS
  #
  my $oRoot = _getNthPps( 0, %hInfo, Nil );

  %hInfo;
}

sub _getInfoFromFile( $FILE, Int $iPos, Int $iLen, Str $sFmt ) {
  return Nil unless $FILE;
  return Nil if $FILE.seek( $iPos, SeekFromBeginning ) == 0;

  my Buf $sWk = $FILE.read( $iLen );
  if $sFmt ~~ 'v' {
    return Nil if $sWk.decode('ascii').chars != $iLen;
  }
  return $sWk.unpack( $sFmt );
}

# slight change here, flatten references a bit in general.
#
sub _getBbdInfo( %hInfo ) {
  my @aBdList;
  my Int $iBdbCnt = %hInfo<_BDB_COUNT>;
  my Int $iGetCnt;
  my Buf $sWk;
  my Int $i1stCnt = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4c ) / LONGINT-SIZE );
  my Int $iBdlCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE ) - 1;

  # 1st BDList
  #
  %hInfo<_FILEH_>.seek( 0x4c, SeekFromBeginning );
  $iGetCnt = ( $iBdbCnt < $i1stCnt ) ?? $iBdbCnt !! $i1stCnt;
  $sWk = %hInfo<_FILEH_>.read( LONGINT-SIZE + $iGetCnt );
  append @aBdList, $sWk.unpack( "V$iGetCnt" );
  $iBdbCnt -= $iGetCnt;

  # Extra BDList
  #
  my Int $iBlock = %hInfo<_EXTRA_BBD_START>;
  while $iBdbCnt > 0 and _isNormalBlock( $iBlock ) {
    _setFilePos( $iBlock, 0, %hInfo );
    $iGetCnt = ( $iBdbCnt < $iBdlCnt ) ?? $iBdbCnt !! $iBdlCnt;
    $sWk = %hInfo<_FILEH_>.read( LONGINT-SIZE + $iGetCnt );
    append @aBdList, $sWk.unpack( "V$iGetCnt" );
    $iBdbCnt -= $iGetCnt;
    $sWk = %hInfo<_FILEH_>.read( LONGINT-SIZE );
    $iBlock = $sWk.unpack( "V" );
  }

  # Get BDs
  #
  my @aWk;
  my %hBd;
  my Int $iBlkNo = 0;
  my Int $iBdCnt = Int(%hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE);
  for @aBdList -> $iBdL {
    _setFilePos( $iBdL, 0, %hInfo );
    $sWk = %hInfo<_FILEH_>.read( %hInfo<_BIG_BLOCK_SIZE> );
    @aWk = $sWk.unpack( "V$iBdCnt" );
    loop ( my Int $i = 0; $i < $iBdCnt ; $i++, $iBlkNo++ ) {
      if @aWk[$i] != $iBlkNo + 1 {
	%hBd{$iBlkNo} = @aWk[$i];
      }
    }
  }
  return %hBd;
}

sub _getNthPps( Int $iPos, %hInfo, $bData ) {
  my Int $iPpsStart = %hInfo<_ROOT_START>;
  my Int ( $iPpsBlock, $iPpsPos );
  my Buf $sWk;
  my Int $iBlock;

  my Int $iBaseCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  $iPpsBlock = Int( $iPos / $iBaseCnt );
  $iPpsPos   = $iPos % $iBaseCnt;

  $iBlock = _getNthBlockNo( $iPpsStart, $iPpsBlock, %hInfo );
  die "No block found" unless defined $iBlock;

  _setFilePos( $iBlock, PPS-SIZE * $iPpsPos, %hInfo );
  $sWk = %hInfo<_FILEH_>.read( PPS-SIZE );
  return Nil unless defined $iBlock;
  my Int $iNmSize = $sWk.subbuf( 0x40, 2 ).unpack( "v" );
  $iNmSize = ( $iNmSize > 2 ) ?? $iNmSize - 2 !! $iNmSize;
  my Buf $sNm   = $sWk.subbuf( 0, $iNmSize );
  my Int $iType = $sWk.subbuf( 0x42, INT-SIZE ).unpack( "C" );
  my $lPpsPrev  = $sWk.subbuf( 0x44, LONGINT-SIZE ).unpack( "V" );
  my $lPpsNext  = $sWk.subbuf( 0x48, LONGINT-SIZE ).unpack( "V" );
  my $lDirPps   = $sWk.subbuf( 0x4C, LONGINT-SIZE ).unpack( "V" );
  my @aTime1st =
     ( ( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
         OLEDate2Local( $sWk.subbuf( 0x64, 8 ) ) !! Nil;
  my @aTime2nd =
     ( ( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
         OLEDate2Local( $sWk.subbuf( 0x6c, 8 ) ) !! Nil;
  my Int ( $iStart, $iSize ) = $sWk.subbuf( 0x74, 8 ).unpack( "VV" );
  if $bData {
    my Str $sData = _getData( $iType, $iStart, $iSize, %hInfo );
#    return OLE::Storage_Lite::PPS.new
    return createPps(
      $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @aTime1st, @aTime2nd, $iStart, $iSize, $sData, Nil
    );
  }
  else {
#    return OLE::Storage_Lite::PPS.new
    return createPps(
      $iPos, $sNm, $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @aTime1st, @aTime2nd, $iStart, $iSize
    );
  }
}

sub _setFilePos( Int $iBlock, Int $iPos, %hInfo ) {
  %hInfo<_FILEH_>.seek(
    ( $iBlock + 1 ) * %hInfo<_BIG_BLOCK_SIZE> + $iPos,
    SeekFromBeginning
  );
}

sub _getNthBlockNo( Int $iStBlock, Int $iNth, %hInfo ) {
  my Int $iSv;
  my Int $iNext = $iStBlock;
  loop ( my Int $i = 0; $i < $iNth; $i++ ) {
    $iSv = $iNext;
    $iNext = _getNextBlockNo( $iSv, %hInfo );
    return Nil unless _isNormalBlock( $iNext );
  }
  $iNext;
}

sub _getData( Int $iType, Int $iBlock, Int $iSize, %hInfo ) {
  given $iType {
    when PPS-TYPE-FILE {
      if $iSize < DATA-SIZE {
        return _getSmallData( $iBlock, $iSize, %hInfo );
      }
      else {
        return _getBigData( $iBlock, $iSize, %hInfo );
      }
    }
    when PPS-TYPE-ROOT {
      return _getBigData( $iBlock, $iSize, %hInfo );
    }
    when PPS-TYPE-DIR {
      return;
    }
    default {
      die "Can't get data from unknown type $iType\n";
    }
  }
}

sub _getBigData( Int $iBlock, Int $iSize, %hInfo ) {
  my Int $iRest;
  my Str ( $sWk, $sRes );

  return '' unless _isNormalBlock( $iBlock );
  $iRest = $iSize;
  my ( $i, $iGetSize, $iNext );
  $sRes = '';
  my @aKeys = sort { $^a <=> $^b }, keys %( %hInfo<_BBD_INFO> );

  while $iRest > 0 {
    my @aRes = grep { $_ >= $iBlock }, @aKeys;
    my Int $iNKey = @aRes[0];
    $i = $iNKey - $iBlock;
    $iNext = %hInfo<_BBD_INFO>{$iNKey};
    _setFilePos( $iBlock, 0, %hInfo );
    my Int $iGetSize = %hInfo<_BIG_BLOCK_SIZE> * ($i + 1);
    $iGetSize = $iRest if $iRest < $iGetSize;
    $sWk = %hInfo<_FILEH_>.read( $iGetSize );
    $sRes ~= $sWk;
    $iRest -= $iGetSize;
    $iBlock = $iNext;
  }
  $sRes;
}

sub _getNextBlockNo( Int $iBlockNo, %hInfo ) {
  my Int $iRes = %hInfo<_BBD_INFO>.{$iBlockNo};
  return defined( $iRes ) ?? $iRes !! $iBlockNo + 1;
}

sub _isNormalBlock( Int $iBlock ) {
  $iBlock < 0xFFFFFFFC;
}

sub _getSmallData( Int $iSmBlock, Int $iSize, %hInfo ) {
  my ( $sRes, $sWk );
  my Int $iRest = $iSize;
  $sRes = '';
  while $iRest > 0 {
    _setFilePosSmall( $iSmBlock, %hInfo );
    $sWk = %hInfo<_FILEH>>.read(
             ( $iRest >= %hInfo<_SMALL_BLOCK_SIZE>) ??
	       %hInfo<_SMALL_BLOCK_SIZE> !!
	       $iRest );
    $sRes ~= $sWk;
    $iRest -= %hInfo<_SMALL_BLOCK_SIZE>;
    $iSmBlock = _getNextSmallBlockNo( $iSmBlock, %hInfo );
  }
  return $sRes;
}

sub _setFilePosSmall( Int $iSmBlock, %hInfo ) {
  my Int $iSmStart = %hInfo<_SB_START>;
  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iNth = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos = $iSmBlock % $iBaseCnt;

  my Int $iBlk = _getNthBlockNo( $iSmStart, $iNth, %hInfo );
  _setFilePos( $iBlk, $iPos * %hInfo<_SMALL_BLOCK_SIZE>, %hInfo );
}

sub _getNextSmallBlockNo( Int $iSmBlock, %hInfo ) {
  my Buf $sWk;

  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE;
  my Int $iNth = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos = $iSmBlock % $iBaseCnt;
  my Int $iBlk = _getNthBlockNo( %hInfo<_SBD_START>, $iNth, %hInfo );
  _setFilePos( $iBlk, $iPos * LONGINT-SIZE, %hInfo );
  $sWk = %hInfo<_FILEH_>.read( LONGINT-SIZE );
  return $sWk.unpack( "V" );
}

sub Asc2Ucs( $sAsc ) {
  return join( "\x00", split '', $sAsc ) ~ "\x00";
}

sub Ucs2Asc( $sUcs ) {
  return join( '', map( $_.pack( 'c' ), $sUcs.unpack( 'v*' ) ) );
}

#------------------------------------------------------------------------------
# OLEDate2Local()
#
# Convert from a Windows FILETIME structure to a localtime array. FILETIME is
# a 64-bit value representing the number of 100-nanosecond intervals since
# January 1 1601.
#
# We first convert the FILETIME to seconds and then subtract the difference
# between the 1601 epoch and the 1970 Unix epoch.
#
sub OLEDate2Local( $oletime ) {

  # Unpack FILETIME into high and low longs
  #
  my ( $lo, $hi ) = $oletime.unpack( "V2" );

  # Convert the longs to a double
  #
  my $nanoseconds = $hi * 2**32 + $lo;

  # Convert the 100ns units to seconds
  #
  my $time = $nanoseconds / 1e7;

  # Subtract the number of seconds between the 1601 and 1970 epocs
  #
  $time -= 11644473600;

  $time;
}

#------------------------------------------------------------------------------
# LocalDate2OLE()
#
# Convert from a a localtime array to a Window FILETIME structure. FILETIME is
# a 64-bit value representing the number of 100-nanosecond intervals since
# January 1 1601.
#
# We first convert the localtime (actually gmtime) to seconds and then add the
# difference between the 1601 epoch and the 1970 Unix epoch. We convert that to
# 100 nanosecond units, divide it into high and low longs and return it as a
# packed 64bit structure.
#
sub LocalDate2OLE( @localtime? ) {
	die "XXX Need timegm()....";

    return "\x00" x 8 unless @localtime;

    # Convert from localtime (actually gmtime) to seconds.
#    my $time = timegm( @localtime );
my $time;

    # Add the number of seconds between the 1601 and 1970 epochs.
    $time += 11644473600;

    # The FILETIME seconds are in units of 100 nanoseconds.
    my $nanoseconds = $time * 1E7;

#use POSIX 'fmod';

    # Pack the total nanoseconds into 64 bits...
    my $hi = Int( $nanoseconds / 2**32 );
    my $lo = $nanoseconds % 2**32;

    my $oletime = pack( "VV", $lo, $hi );

    return $oletime;
}

# Rename 'new' to 'create', for the moment.
# The bless() mechanism isn't working for me...
# 
sub createPps( $iNo, $sNm, $iType, $iPrev, $iNext, $iDir,
               @aTime1st, @aTime2nd, $iStart, $iSize, $sData?, @aChild? ) {
  if $iType == 2 { #OLE::Storage_Lite::PPS-TYPE-FILE {
    OLE::Storage_Lite::PPS::File.new(
      :No( $iNo ),
      :Name( $sNm.decode('utf-8') ),
      :Type( $iType ),
      :PrevPps( $iPrev ),
      :NextPps( $iNext ),
      :DirPps( $iDir ),
      :Time1st( @aTime1st ),
      :Time2nd( @aTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @aChild )
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
      :Time1st( @aTime1st ),
      :Time2nd( @aTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @aChild )
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
      :Time1st( @aTime1st ),
      :Time2nd( @aTime2nd ),
      :StartBlock( $iStart ),
      :Size( $iSize ),
      :Data( $sData ),
      :Child( @aChild )
    )
  }
  else {
    die "Can't find PPS type $iType";
  }
}
