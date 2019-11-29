use v6;

unit class OLE::Storage_Lite;

use OLE::Storage_Lite::Utils;
use OLE::Storage_Lite::PPS::Dir;
use OLE::Storage_Lite::PPS::File;
use OLE::Storage_Lite::PPS::Root;

use experimental :pack;

# A couple of notes on how I translated (loosely) this from the Perl 5 module:
#
# I'm taking advantage of being able to pass along array and hash types, and
# leaving hash "attribute"s as just that, attributes.
#
#   This is probably most notable with the %rhInfo and @Time{1st,2nd} vars.
#
# Dropping parens where unneeded, using object notation only where needed, like
# pack/unpack because they're "experimental".
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
#
# I've added given-when when it makes sense, and stuck with the original loop
# types that the code used. Not terribly consistent, but if it makes finding
# coincidences between the Perl 5 and Raku code easier, I'm all for it.
#

#------------------------------------------------------------------------------
# Consts for OLE::Storage_Lite
#------------------------------------------------------------------------------
#
constant OLE-ENCODING = 'UTF-16LE';

constant HEADER-ID = "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1";

constant PPS-TYPE-DIR  = 1;
constant PPS-TYPE-FILE = 2;
constant PPS-TYPE-ROOT = 5;

constant DATA-SIZE    = 0x1000; # Upper limit of Data size, fallback to file
constant INT-SIZE     = 2;
constant LONGINT-SIZE = 4;
constant PPS-SIZE     = 0x80;

has Str $._FILE; # String or IO::Handle or ...

multi method new( Str $_FILE ) {
  self.bless( :$_FILE );
}

# I really don't think @aDone is useful in general
# But I'll keep it around until I have actual tests.
#
method getPpsTree( $bData? ) {
  my %hInfo = self._getHeaderInfo( $._FILE );
my @aDone;
  my OLE::Storage_Lite::PPS @oPps =
    self._getPpsTree( 0, %hInfo, $bData, @aDone ); # @aDone is my own
  @oPps;
}

method getPpsSearch( @aName, $bData?, Int $iCase? ) {
  my %hInfo = self._getHeaderInfo( $._FILE );
  my OLE::Storage_Lite::PPS @aList =
    self._getPpsSearch( 0, %hInfo, @aName, $bData, $iCase );
  @aList;
}

method getNthPps( Int $iNo, $bData? ) {
  my %hInfo = self._getHeaderInfo( $._FILE );
  my OLE::Storage_Lite::PPS $oPps =
    self._getNthPps( $iNo, %hInfo, $bData );
  $oPps;
}

# XXX _initParse was here, now _getHeaderInfo() does the work.

method _getPpsTree( Int $iNo, %hInfo, $bData, @aDone ) {
  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }
  else {
    @aDone = ();
  }
  append @aDone, $iNo;

  my Int $iRootBlock = %hInfo<_ROOT_START>;

  my OLE::Storage_Lite::PPS $oPps = self._getNthPps( $iNo, %hInfo, $bData );

  if $oPps.DirPps != 2**32 - 1 {
    my OLE::Storage_Lite::PPS @aChildL =
      self._getPpsTree( $oPps.DirPps, %hInfo, $bData, @aDone );
    $oPps.Child = @aChildL;
  }
  else {
    $oPps.Child = ();
  }

  my OLE::Storage_Lite::PPS @aList = ( );
  append @aList, self._getPpsTree( $oPps.PrevPps, %hInfo, $bData, @aDone ) if
    $oPps.PrevPps != 2**32 - 1;
  append @aList, $oPps;
  append @aList, self._getPpsTree( $oPps.NextPps, %hInfo, $bData, @aDone ) if
    $oPps.NextPps != 2**32 - 1;
  @aList;
}

method _getPpsSearch( Int $iNo, %hInfo, @aName, $bData, Int $iCase, @aDone ) {
  my Int $iRootBlock = %hInfo<_ROOT_START>;
  my OLE::Storage_Lite::PPS @aRes;

  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }
  else {
    @aDone = ( );
  }

  append @aDone, $iNo;
  my OLE::Storage_Lite::PPS $oPps =
     self._getNthPps( $iNo, %hInfo, Nil );
  if ( $iCase && grep { fc( $oPps.Name ) eq fc( $_ ) }, @aName ) or
       grep { $oPps.Name eq $_ }, @aName {
    $oPps = self._getNthPps( $iNo, %hInfo, $bData ) if $bData;
    @aRes = $oPps;
  }
  else {
    @aRes = ( );
  }

  append @aRes,
    self._getPpsSearch( $oPps.DirPps, %hInfo, @aName, $bData, $iCase, @aDone )
      if $oPps.DirPps != 2**32 - 1;
  append @aRes,
    self._getPpsSearch( $oPps.PrevPps, %hInfo, @aName, $bData, $iCase, @aDone )
      if $oPps.PrevPps != 2**32 - 1;
  append @aRes,
    self._getPpsSearch( $oPps.NextPps, %hInfo, @aName, $bData, $iCase, @aDone )
      if $oPps.NextPps != 2**32 - 1;

  @aRes;
}

method _getHeaderInfo( $filename ) {
  my $file = open $filename, :r;
  my %hInfo =
    _FILEH_ => $file
  ;

  $file.seek( 0, SeekFromBeginning );
  my Str $sWk = $file.read( 8 ).unpack('A8');
  die "Header ID incorrect" if $sWk ne HEADER-ID;

  my Int $iWk = self._getInfoFromFile( $file, 0x1E, 2, "v" );
  die "Big block size missing" unless defined( $iWk );
  %hInfo<_BIG_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = self._getInfoFromFile( $file, 0x20, 2, "v" );
  die "Small block size missing" unless defined( $iWk );
  %hInfo<_SMALL_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = self._getInfoFromFile( $file, 0x2C, 4, "v" );
  die "BDB count missing" unless defined( $iWk );
  %hInfo<_BDB_COUNT> = $iWk;

  $iWk = self._getInfoFromFile( $file, 0x30, 4, "V" );
  die "Root start missing" unless defined( $iWk );
  %hInfo<_ROOT_START> = $iWk;

# $iWk = self._getInfoFromFile( $file, 0x38, 4, "v" );
# die "Min size BB missing" unless defined( $iWk );
# %hInfo<_MIN_SIZE_BB> = $iWk;

  $iWk = self._getInfoFromFile( $file, 0x3C, 4, "V" );
  die "Small BD start missing" unless defined( $iWk );
  %hInfo<_SBD_START> = $iWk;

  $iWk = self._getInfoFromFile( $file, 0x40, 4, "V" );
  die "Small BD count missing" unless defined( $iWk );
  %hInfo<_SBD_COUNT> = $iWk;

  $iWk = self._getInfoFromFile( $file, 0x44, 4, "V" );
  die "Extra BBD start missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_START> = $iWk;

  $iWk = self._getInfoFromFile( $file, 0x48, 4, "V" );
  die "Extra BBD count missing" unless defined( $iWk );
  %hInfo<_EXTRA_BBD_COUNT> = $iWk;

  # Get BBD Info
  #
  %hInfo<_BBD_INFO> = self._getBbdInfo( %hInfo );

  # Get Root PPS
  #
  my OLE::Storage_Lite::PPS $oRoot =
     self._getNthPps( 0, %hInfo, Nil );
  %hInfo<_SB_START> = $oRoot.StartBlock;
  %hInfo<_SB_SIZE>  = $oRoot.Size;

  %hInfo;
}

method _getInfoFromFile( $FILE, Int $iPos, Int $iLen, Str $sFmt ) {
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
method _getBbdInfo( %hInfo ) {
  my $FILE = %hInfo<_FILEH_>;

  my Int $iBdbCnt = %hInfo<_BDB_COUNT>;
  my Int $i1stCnt = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4c ) / LONGINT-SIZE );
  my Int $iBdlCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE ) - 1;
  my @aBdList;

  # 1st BDList
  #
  $FILE.seek( 0x4c, SeekFromBeginning );
  my Int $iGetCnt = ( $iBdbCnt < $i1stCnt ) ?? $iBdbCnt !! $i1stCnt;
  my Buf $sWk = $FILE.read( LONGINT-SIZE + $iGetCnt );
  append @aBdList, $sWk.unpack( "V$iGetCnt" );
  $iBdbCnt -= $iGetCnt;

  # Extra BDList
  #
  my Int $iBlock = %hInfo<_EXTRA_BBD_START>;
  while $iBdbCnt > 0 and _isNormalBlock( $iBlock ) {
    self._setFilePos( $iBlock, 0, %hInfo );
    $iGetCnt = ( $iBdbCnt < $iBdlCnt ) ?? $iBdbCnt !! $iBdlCnt;
    $sWk     = $FILE.read( LONGINT-SIZE + $iGetCnt );
    append @aBdList, $sWk.unpack( "V$iGetCnt" );
    $iBdbCnt -= $iGetCnt;
    $sWk    = $FILE.read( LONGINT-SIZE );
    $iBlock = $sWk.unpack( "V" );
  }

  # Get BDs
  #
  my @aWk;
  my %hBd;
  my Int $iBlkNo = 0;
  my Int $iBdCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  for @aBdList -> $iBdL {
    self._setFilePos( $iBdL, 0, %hInfo );
    $sWk = $FILE.read( %hInfo<_BIG_BLOCK_SIZE> );
    @aWk = $sWk.unpack( "V$iBdCnt" );
    loop ( my Int $i = 0; $i < $iBdCnt ; $i++, $iBlkNo++ ) {
      if @aWk[$i] != $iBlkNo + 1 {
	%hBd{$iBlkNo} = @aWk[$i];
      }
    }
  }
  return %hBd;
}

method _getNthPps( Int $iPos, %hInfo, $bData ) {
  my $FILE = %hInfo<_FILEH_>;

  my Int $iPpsStart = %hInfo<_ROOT_START>;
  my Buf $sWk;

  my Int $iBaseCnt  = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  my Int $iPpsBlock = Int( $iPos / $iBaseCnt );
  my Int $iPpsPos   = $iPos % $iBaseCnt;

  my Int $iBlock = self._getNthBlockNo( $iPpsStart, $iPpsBlock, %hInfo );
  die "No block found" unless defined $iBlock;

  self._setFilePos( $iBlock, PPS-SIZE * $iPpsPos, %hInfo );
  $sWk = $FILE.read( PPS-SIZE );
  return Nil unless defined $iBlock;

  my Int $iNmSize = $sWk.subbuf( 0x40, 2 ).unpack( "v" );
  $iNmSize = ( $iNmSize > 2 ) ?? $iNmSize - 2 !! $iNmSize;

  my Buf $sNm   = $sWk.subbuf( 0,        $iNmSize );
  my Int $iType = $sWk.subbuf( 0x42,     INT-SIZE ).unpack( "C" );
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

  # If we were to make OLE::Storage_Lite::PPS do the work of constructing
  # an object, then that would make OLE::Storage_Lite::PPS aware of its
  # children.
  #
  # And that would be a dependency loop.
  #
  if $bData {
    my $sData = self._getData( $iType, $iStart, $iSize, %hInfo );
#    return OLE::Storage_Lite::PPS.new
    return self.createPps(
      $iPos, $sNm.decode( OLE-ENCODING ),
      $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @aTime1st, @aTime2nd, $iStart, $iSize, $sData, ( )
    );
  }
  else {
#    return OLE::Storage_Lite::PPS.new
    return self.createPps(
      $iPos, $sNm.decode( OLE-ENCODING ),
      $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      @aTime1st, @aTime2nd, $iStart, $iSize
    );
  }
}

method _setFilePos( Int $iBlock, Int $iPos, %hInfo ) {
  %hInfo<_FILEH_>.seek(
    ( $iBlock + 1 ) * %hInfo<_BIG_BLOCK_SIZE> + $iPos,
    SeekFromBeginning
  );
}

method _getNthBlockNo( Int $iStBlock, Int $iNth, %hInfo ) {
  my Int $iSv;
  my Int $iNext = $iStBlock;

  loop ( my Int $i = 0; $i < $iNth; $i++ ) {
    $iSv   = $iNext;
    $iNext = self._getNextBlockNo( $iSv, %hInfo );
    return Nil unless _isNormalBlock( $iNext );
  }
  $iNext;
}

method _getData( Int $iType, Int $iBlock, Int $iSize, %hInfo ) {
  my $buf;
  given $iType {
    when PPS-TYPE-FILE {
      if $iSize < DATA-SIZE {
        $buf = self._getSmallData( $iBlock, $iSize, %hInfo );
      }
      else {
        $buf = self._getBigData( $iBlock, $iSize, %hInfo );
      }
    }
    when PPS-TYPE-ROOT {
      $buf = self._getBigData( $iBlock, $iSize, %hInfo );
    }
    when PPS-TYPE-DIR {
      return;
    }
  }
  return $buf;
}

method _getBigData( Int $iBlock, Int $iSize, %hInfo ) {
  my $_iBlock = $iBlock;
  return '' unless _isNormalBlock( $_iBlock );

  my Int $iRest = $iSize;
  my Buf $sRes  = Buf.new();
  my @aKeys     = sort { $^a <=> $^b },
                       map { +$_ }, keys %( %hInfo<_BBD_INFO> );

  while $iRest > 0 {
    my @aRes      = grep { $_ >= $_iBlock }, @aKeys;
    my Int $iNKey = @aRes[0];
    my Int $i     = $iNKey - $_iBlock;
    my Int $iNext = %hInfo<_BBD_INFO>{$iNKey};

    self._setFilePos( $_iBlock, 0, %hInfo );

    my Int $iGetSize = %hInfo<_BIG_BLOCK_SIZE> * ( $i + 1 );

    $iGetSize = $iRest if $iRest < $iGetSize;
    my Buf $sWk = %hInfo<_FILEH_>.read( $iGetSize );
    $sRes      ~= $sWk;
    $iRest     -= $iGetSize;
    $_iBlock    = $iNext;
  }
  $sRes;
}

method _getNextBlockNo( Int $iBlockNo, %hInfo ) {
  my Int $iRes = %hInfo<_BBD_INFO>{$iBlockNo};

  return defined( $iRes ) ?? $iRes !! $iBlockNo + 1;
}

sub _isNormalBlock( Int $iBlock ) {
  $iBlock < 0xFFFFFFFC;
}

method _getSmallData( Int $iSmBlock, Int $iSize, %hInfo ) {
  my Str $sWk;
  my Int $iRest = $iSize;
  my Str $sRes  = '';

  while $iRest > 0 {
    self._setFilePosSmall( $iSmBlock, %hInfo );
    $sWk = %hInfo<_FILEH_>.read(
      $iRest >= %hInfo<_SMALL_BLOCK_SIZE> ??
        %hInfo<_SMALL_BLOCK_SIZE> !!
        $iRest
    );
    $sRes    ~= $sWk;
    $iRest   -= %hInfo<_SMALL_BLOCK_SIZE>;
    $iSmBlock = self._getNextSmallBlockNo( $iSmBlock, %hInfo );
  }
  return $sRes;
}

method _setFilePosSmall( Int $iSmBlock, %hInfo ) {
  my Int $iSmStart = %hInfo<_SB_START>;
  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iNth     = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos     = $iSmBlock % $iBaseCnt;
  my Int $iBlk     = self._getNthBlockNo( $iSmStart, $iNth, %hInfo );

  self._setFilePos( $iBlk, $iPos * %hInfo<_SMALL_BLOCK_SIZE>, %hInfo );
}

method _getNextSmallBlockNo( Int $iSmBlock, %hInfo ) {
  my Buf $sWk;

  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE;
  my Int $iNth     = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos     = $iSmBlock % $iBaseCnt;
  my Int $iBlk     = self._getNthBlockNo( %hInfo<_SBD_START>, $iNth, %hInfo );

  self._setFilePos( $iBlk, $iPos * LONGINT-SIZE, %hInfo );
  $sWk = %hInfo<_FILEH_>.read( LONGINT-SIZE );

  return $sWk.unpack( "V" );
}

# Asc2Ucs2 was used, now just use proper encoding methods please.
#
# Same for Ucs2Asc

##------------------------------------------------------------------------------
## OLEDate2Local()
##
## Convert from a Windows FILETIME structure to a localtime array. FILETIME is
## a 64-bit value representing the number of 100-nanosecond intervals since
## January 1 1601.
##
## We first convert the FILETIME to seconds and then subtract the difference
## between the 1601 epoch and the 1970 Unix epoch.
##
#sub OLEDate2Local( Buf $oletime ) is export {
#
#  # Unpack FILETIME into high and low longs
#  #
#  my ( $lo, $hi ) = $oletime.unpack( "V2" );
#
#  # Convert the longs to a double
#  #
#  my $nanoseconds = $hi * 2**32 + $lo;
#
#  # Convert the 100ns units to seconds
#  #
#  my $time = $nanoseconds / 1e7;
#
#  # Subtract the number of seconds between the 1601 and 1970 epocs
#  #
#  $time -= 11644473600;
#
#  my @localtime = gmtime( $time );
#
#  @localtime;
#}
#
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
#sub LocalDate2OLE( @localtime? ) is export {
#
#  return "\x00" x 8 unless @localtime;
#
## Perl 5 spec worked like this:
##
## Jan is 0
## my $time = timegm( $sec, $min, $hour, $mday, $mon, $year );
##                    0     1     2      3      4     5
#
#  my $dt = DateTime.new(
#    year    => @localtime[5] + 1900,
#    month   => @localtime[4] + 1,
#    day     => @localtime[3],
#    hour    => @localtime[2],
#    minute  => @localtime[1],
#    second  => @localtime[0]
#  );
#  
#  # Convert from localtime (actually gmtime) to seconds.
#  my $time = $dt.posix( :ignore-timezone( True ) );
#
#  # Add the number of seconds between the 1601 and 1970 epochs.
#  $time += 11644473600;
#  
#  # The FILETIME seconds are in units of 100 nanoseconds.
#  my $nanoseconds = $time * 1E7;
#
#  # Pack the total nanoseconds into 64 bits...
##  my Int $hi = Int( $nanoseconds / 2**32 );
##  my Int $lo = $nanoseconds % 2**32;
#  my Int $hi = $nanoseconds +> 32 +& ( 2**32 - 1 );
#  my Int $lo = $nanoseconds +& ( 2**32 - 1 );
#
#  my $oletime = pack( "VV", $lo, $hi );
#
#  return $oletime;
#}

# Rename 'new' to 'create', for the moment.
# The bless() mechanism isn't working for me...
# 
# # Also *gotta* clean up the hierarchy, PPS.pm is referencing child classes.
#
method createPps( Int $No, Str $Name, Int $Type, Int $PrevPps, Int $NextPps,
                  Int $DirPps, @Time1st, @Time2nd, Int $StartBlock, Int $Size,
   	          $Data?, @Child? ) {
  given $Type {
    when PPS-TYPE-FILE {
      OLE::Storage_Lite::PPS::File.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :@Time1st, :@Time2nd,
        :$Data, :@Child
      )
    }
    when PPS-TYPE-DIR { #OLE::Storage_Lite::PPS-TYPE-DIR
      OLE::Storage_Lite::PPS::Dir.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :@Time1st, :@Time2nd,
        :$Data, :@Child
      )
    }
    when PPS-TYPE-ROOT { #OLE::Storage_Lite::PPS-TYPE-ROOT
      OLE::Storage_Lite::PPS::Root.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :@Time1st, :@Time2nd,
        :$Data, :@Child
      )
    }
    default {
      die "Can't find PPS type $Type";
    }
  }
}

=begin pod

=head1 NAME

OLE::Storage_Lite - Simple Class for OLE document interface.

=head1 SYNOPSIS

    use OLE::Storage_Lite;

    # Initialize.

    my $oOl = OLE::Storage_Lite.new("some.xls");

    # Read data
    my $oPps = $oOl.getPpsTree(1);

    # Save Data
    # To a File
    $oPps.save("kaba.xls"); #kaba.xls
    $oPps.save('-');        #STDOUT

=head1 DESCRIPTION

L<OLE::Storage_Lite> allows you to read and write an OLE structured file.

L<OLE::Storage_Lite::PPS> is a class representing PPS. L<OLE::Storage_Lite::PPS::Root>, L<OLE::Storage_Lite::PPS::File> and L<OLE::Storage_Lite::PPS::Dir>
are subclasses of L<OLE::Storage_Lite::PPS>.

=head3 CAVEAT

A PPS' name is maintained internally as UTF-8 with no restrictions, yet it seems that the code requires it to be ASCII, because of the Asc2Ucs and Ucs2Asc conversion functions.

If it turns out that Excel can *only* handle ASCII names for these we'll place a 'where' constraint on the name blocking it to ASCII-only.

=head2 new()

Constructor.

    $oOle = OLE::Storage_Lite.new($sFile);

Creates a L<OLE::Storage_Lite> object for C<$sFile>. C<$sFile> must be a valid file name. 

=head2 getPpsTree()

    $oPpsRoot = $oOle.getPpsTree([$bData]);

Returns PPS as an L<OLE::Storage_Lite::PPS::Root> object. Other PPS objects will be included as its children.

If C<$bData> is true, the objects will have data in the file.

=head2 getPpsSearch()

    $oPpsRoot = $oOle.getPpsTree(@aName [, $bData][, $iCase] );

Returns PPSs as L<OLE::Storage_Lite::PPS> objects that has the name specified in C<$raName> array.

If C<$bData> is true, the objects will have data in the file.
If C<$iCase> is true, search is case insensitive.

=head2 getNthPps()

    $oPpsRoot = $oOle.getNthPps($iNth [, $bData]);

Returns PPS as C<OLE::Storage_Lite::PPS> object specified number C<$iNth>.

If C<$bData> is true, the objects will have data in the file.

=head2 Asc2Ucs(), Ucs2Asc()

    # XXX $sUcs2 = OLE::Storage_Lite::Asc2Ucs($sAsc);

This utility function used to exist in the Perl 5 version. Now it's managed
by the module itself. When the file is read it's transcoded to UTF-8, and when
the UTF-8 string is written out it's transcoded to UTF-16LE.

=head1 L<OLE::Storage_Lite::PPS>

OLE::Storage_Lite::PPS has these properties:

=over 4

=item No

Order number in saving.

=item Name

Its name (in UTF-8, the name is translated in/out of UCS-2)

=item Type

Its type (1:Dir, 2:File (Data), 5: Root)

=item PrevPps

Previous pps (as No)

=item NextPps

Next pps (as No)

=item DirPps

Dir pps (as No).

=item Time1st

Timestamp 1st in array ref as similar fomat of localtime.

=item Time2nd

Timestamp 2nd in array ref as similar fomat of localtime.

=item StartBlock

Start block number

=item Size

Size of the pps

=item Data

Its data

=item Child

Its child PPSs in array ref

=back

=head1 OLE::Storage_Lite::PPS::Root

L<OLE::Storage_Lite::PPS::Root> has 2 methods.

=head2 new()

    $oRoot = OLE::Storage_Lite::PPS::Root.new( @aTime1st, @aTime2nd, @aChild);

Constructor.

C<@aTime1st>, C<@aTime2nd> are array refs with ($iSec, $iMin, $iHour, $iDay, $iMon, $iYear).
$iSec means seconds, $iMin means minutes. $iHour means hours.
$iDay means day. $iMon is month -1. $iYear is year - 1900.

C<@aChild> is a array of child PPSs.

=head2 save()

    $oRoot = $oRoot.save( $sFile, $bNoAs );

Saves information into C<$sFile>. If C<$sFile> is '-', this will use STDOUT.

The C<new()> constructor also accepts a valid filehandle. Remember to C<binmode()> the filehandle first.

If C<$bNoAs> is defined, this function will use the No of PPSs for saving order.
If C<$bNoAs> is undefined, this will calculate PPS saving order.

=head1 OLE::Storage_Lite::PPS::Dir

L<OLE::Storage_Lite::PPS::Dir> has 1 method.

=head2 new()

    $oRoot = OLE::Storage_Lite::PPS::Dir.new(
                    $sName,
                  [, @aTime1st]
                  [, @aTime2nd]
                  [, @aChild]);


Constructor.

C<$sName> is a name of the PPS.

C<@aTime1st>, C<@aTime2nd> is a array ref as
($iSec, $iMin, $iHour, $iDay, $iMon, $iYear).
$iSec means seconds, $iMin means minutes. $iHour means hours.
$iDay means day. $iMon is month -1. $iYear is year - 1900.

C<@aChild> is a array ref of children PPSs.


=head1 OLE::Storage_Lite::PPS::File

L<OLE::Storage_Lite::PPS::File> has 3 methods.

=head2 new

    $oRoot = OLE::Storage_Lite::PPS::File.new($sName, $sData);

C<$sName> is the name of the PPS.

C<$sData> is the data in the PPS.


=head2 newFile()

    $oRoot = OLE::Storage_Lite::PPS::File.newFile($sName, $sFile);

This function makes to use file handle for geting and storing data.

C<$sName> is name of the PPS.

If C<$sFile> is scalar, it assumes that is a filename.
If C<$sFile> is an IO::Handle object, it uses that specified handle.
If C<$sFile> is undef or '', it uses temporary file.

CAUTION: Take care C<$sFile> will be updated by C<append> method.
So if you want to use IO::Handle and append a data to it,
you should open the handle with "r+".

=head2 append()

    $oRoot = $oPps.append($sData);

appends specified data to that PPS.

C<$sData> is appending data for that PPS.

=head1 CAUTION

A saved file with VBA (a.k.a Macros) by this module will not work correctly.
However modules can get the same information from the file,
the file occurs a error in application(Word, Excel ...).

=head1 DEPRECATED FEATURES

Older version of C<OLE::Storage_Lite> autovivified a scalar ref in the C<new()> constructors into a scalar filehandle. This functionality is still there for backwards compatibility but it is highly recommended that you do not use it. Instead create a filehandle (scalar or otherwise) and pass that in.

=head1 COPYRIGHT

The OLE::Storage_Lite module is Copyright (c) 2000,2001 Kawai Takanori. Japan.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 ACKNOWLEDGEMENTS

First of all, I would like to acknowledge to Martin Schwartz and his module OLE::Storage.

=head1 AUTHOR

Jeffrey Goff <jgoff@cpan.org>

=head1 AUTHOR EMERITUS

Kawai Takanori <kwitknr@cpan.org>

This module is currently maintained by John McNamara jmcnamara@cpan.org

=head1 SEE ALSO

OLE::Storage

Documentation for the OLE Compound document has been released by Microsoft under the I<Open Specification Promise>. See http://www.microsoft.com/interop/docs/supportingtechnologies.mspx

The Digital Imaging Group have also detailed the OLE format in the JPEG2000 specification: see Appendix A of http://www.i3a.org/pdf/wg1n1017.pdf

=cut

=end pod
