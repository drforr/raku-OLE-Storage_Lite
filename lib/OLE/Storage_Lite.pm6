use v6;

unit class OLE::Storage_Lite:ver<0.0.2>;

use OLE::Storage_Lite::Utils;
use OLE::Storage_Lite::PPS::Dir;
use OLE::Storage_Lite::PPS::File;
use OLE::Storage_Lite::PPS::Root;

use experimental :pack;

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

has Str $.FILE; # String or IO::Handle or ...
has IO::Handle $.FILE_H is rw;

# These need to be set on each pps-* call.
#
has Int $.ROOT_START      is rw;
has Int $.BDB_COUNT       is rw;
has Int $.SBD_START       is rw;
has Int $.SBD_COUNT       is rw; # Definitely not used
has Int $.EXTRA_BBD_START is rw;
has Int $.EXTRA_BBD_COUNT is rw; # Definitely not used
has %.BBD_INFO            is rw;
has Int $.SB_START        is rw;
has Int $.SB_SIZE         is rw; # Definitely not used

multi method new( Str $FILE ) {
  self.new( :$FILE );
}

# I really don't think @aDone is useful in general
# But I'll keep it around until I have actual tests.
#
method pps-tree( $bData? ) {
  $.FILE_H  = open $.FILE, :r, :bin;
  my %hInfo = self._getHeaderInfo;
  my Int @aDone;

  my OLE::Storage_Lite::PPS @oPps =
    self._getPpsTree( 0, %hInfo, $bData, @aDone ); # @aDone is my own

  close $.FILE_H;
  @oPps;
}

method pps-search( @aName, $bData?, $iCase? ) {
  $.FILE_H  = open $.FILE, :r, :bin;
  my %hInfo = self._getHeaderInfo;
  my Int @aDone;

  my OLE::Storage_Lite::PPS @aList =
    self._getPpsSearch( 0, %hInfo, @aName, @aDone, $bData, $iCase );

  close $.FILE_H;
  @aList;
}

method Nth-pps( Int $iNo, $bData? ) {
  $.FILE_H  = open $.FILE, :r, :bin;
  my %hInfo = self._getHeaderInfo;

  my OLE::Storage_Lite::PPS $oPps =
    self._getNthPps( $iNo, %hInfo, $bData );

  close $.FILE_H;
  $oPps;
}

# XXX _initParse was here, now _getHeaderInfo() does the work.

method _getPpsTree( Int $iNo, %hInfo, $bData, @aDone ) {
  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }
  append @aDone, $iNo;

  my OLE::Storage_Lite::PPS $oPps = self._getNthPps( $iNo, %hInfo, $bData );

  if $oPps.DirPps != 0xffffffff {
    my OLE::Storage_Lite::PPS @aChildL =
      self._getPpsTree( $oPps.DirPps, %hInfo, $bData, @aDone );
    $oPps.Child = @aChildL;
  }

  my OLE::Storage_Lite::PPS @aList;
  append @aList, self._getPpsTree( $oPps.PrevPps, %hInfo, $bData, @aDone ) if
    $oPps.PrevPps != 0xffffffff;
  append @aList, $oPps;
  append @aList, self._getPpsTree( $oPps.NextPps, %hInfo, $bData, @aDone ) if
    $oPps.NextPps != 0xffffffff;
  @aList;
}

method _getPpsSearch( Int $iNo, %hInfo, @aName, Int @aDone, $bData, $iCase ) {
  my OLE::Storage_Lite::PPS @aRes;

  if @aDone.elems {
    return () if grep { $_ == $iNo }, @aDone;
  }

  append @aDone, $iNo;
  my OLE::Storage_Lite::PPS $oPps =
     self._getNthPps( $iNo, %hInfo, Nil );
  if ( $iCase && grep { fc( $oPps.Name ) eq fc( $_ ) }, @aName ) or
       grep { $oPps.Name eq $_ }, @aName {
    $oPps = self._getNthPps( $iNo, %hInfo, $bData ) if $bData;
    @aRes = $oPps;
  }

  append @aRes,
    self._getPpsSearch( $oPps.DirPps, %hInfo, @aName, @aDone, $bData, $iCase )
      if $oPps.DirPps != 0xffffffff;
  append @aRes,
    self._getPpsSearch( $oPps.PrevPps, %hInfo, @aName, @aDone, $bData, $iCase )
      if $oPps.PrevPps != 0xffffffff;
  append @aRes,
    self._getPpsSearch( $oPps.NextPps, %hInfo, @aName, @aDone, $bData, $iCase )
      if $oPps.NextPps != 0xffffffff;

  @aRes;
}

method _getHeaderInfo {
  my %hInfo;

  $.FILE_H.seek( 0, SeekFromBeginning );
  my Str $sWk = $.FILE_H.read( 8 ).unpack('A8');
  die "Header ID incorrect" if $sWk ne HEADER-ID;

  my Int $iWk = self._getInfoFromFile( 0x1E, 2, "v" );
  die "Big block size missing" unless defined( $iWk );
  %hInfo<_BIG_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = self._getInfoFromFile( 0x20, 2, "v" );
  die "Small block size missing" unless defined( $iWk );
  %hInfo<_SMALL_BLOCK_SIZE> = 2 ** $iWk;

  $iWk = self._getInfoFromFile( 0x2C, 4, "v" );
  die "BDB count missing" unless defined( $iWk );
  $.BDB_COUNT = $iWk;

  $iWk = self._getInfoFromFile( 0x30, 4, "V" );
  die "Root start missing" unless defined( $iWk );
  $.ROOT_START = $iWk;

# $iWk = self._getInfoFromFile( 0x38, 4, "v" );
# die "Min size BB missing" unless defined( $iWk );
# %hInfo<_MIN_SIZE_BB> = $iWk;

  $iWk = self._getInfoFromFile( 0x3C, 4, "V" );
  die "Small BD start missing" unless defined( $iWk );
  $.SBD_START = $iWk;

  $iWk = self._getInfoFromFile( 0x40, 4, "V" );
  die "Small BD count missing" unless defined( $iWk );
  $.SBD_COUNT = $iWk;

  $iWk = self._getInfoFromFile( 0x44, 4, "V" );
  die "Extra BBD start missing" unless defined( $iWk );
  $.EXTRA_BBD_START = $iWk;

  $iWk = self._getInfoFromFile( 0x48, 4, "V" );
  die "Extra BBD count missing" unless defined( $iWk );
  $.EXTRA_BBD_COUNT = $iWk;

  # Get BBD Info
  #
  %.BBD_INFO = self._getBbdInfo( %hInfo );

  # Get Root PPS
  #
  my OLE::Storage_Lite::PPS $oRoot =
    self._getNthPps( 0, %hInfo, Nil );
  $.SB_START = $oRoot.StartBlock;
  $.SB_SIZE  = $oRoot.Size;

  %hInfo;
}

method _getInfoFromFile( Int $iPos, Int $iLen, Str $sFmt ) {
  return Nil unless $.FILE_H;
  return Nil if $.FILE_H.seek( $iPos, SeekFromBeginning ) == 0;

  my Buf $sWk = $.FILE_H.read( $iLen );
  if $sFmt ~~ 'v' {
    return Nil if $sWk.decode('ascii').chars != $iLen;
  }
  return $sWk.unpack( $sFmt );
}

# slight change here, flatten references a bit in general.
#
method _getBbdInfo( %hInfo ) {
  my Int $iBdbCnt = $.BDB_COUNT;
  my Int $i1stCnt = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4c ) / LONGINT-SIZE );
  my Int $iBdlCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE ) - 1;
  my Int @aBdList;

  # 1st BDList
  #
  $.FILE_H.seek( 0x4c, SeekFromBeginning );
  my Int $iGetCnt = ( $iBdbCnt < $i1stCnt ) ?? $iBdbCnt !! $i1stCnt;
  my Buf $sWk     = $.FILE_H.read( LONGINT-SIZE + $iGetCnt );
  append @aBdList, $sWk.unpack( "V$iGetCnt" );
  $iBdbCnt -= $iGetCnt;

  # Extra BDList
  #
  my Int $iBlock = $.EXTRA_BBD_START;
  while $iBdbCnt > 0 and _isNormalBlock( $iBlock ) {
    self._setFilePos( $iBlock, 0, %hInfo );
    $iGetCnt = ( $iBdbCnt < $iBdlCnt ) ?? $iBdbCnt !! $iBdlCnt;
    $sWk     = $.FILE_H.read( LONGINT-SIZE + $iGetCnt );
    append @aBdList, $sWk.unpack( "V$iGetCnt" );

    $iBdbCnt -= $iGetCnt;
    $sWk      = $.FILE_H.read( LONGINT-SIZE );
    $iBlock   = $sWk.unpack( "V" );
  }

  # Get BDs
  #
  my Int @aWk;
  my %hBd;
  my Int $iBlkNo = 0;
  my Int $iBdCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  for @aBdList -> $iBdL {
    self._setFilePos( $iBdL, 0, %hInfo );
    $sWk = $.FILE_H.read( %hInfo<_BIG_BLOCK_SIZE> );
    @aWk = $sWk.unpack( "V$iBdCnt" );
    loop ( my Int $i = 0; $i < $iBdCnt ; $i++, $iBlkNo++ ) {
      if @aWk[$i] != $iBlkNo + 1 {
	%hBd{$iBlkNo} = @aWk[$i];
      }
    }
  }
  return %hBd;
}

method _getNthPps( Int $iPos, %hInfo, $bData? ) {
  my Int $iPpsStart = $.ROOT_START;
  my Int $iBaseCnt  = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  my Int $iPpsBlock = Int( $iPos / $iBaseCnt );
  my Int $iPpsPos   = $iPos % $iBaseCnt;
  my Buf $sWk;

  my Int $iBlock = self._getNthBlockNo( $iPpsStart, $iPpsBlock );
  die "No block found" unless defined $iBlock;

  self._setFilePos( $iBlock, PPS-SIZE * $iPpsPos, %hInfo );
  $sWk = $.FILE_H.read( PPS-SIZE );
  return Nil unless defined $iBlock;

  my Int $iNmSize = $sWk.subbuf( 0x40, 2 ).unpack( "v" );
  $iNmSize        = ( $iNmSize > 2 ) ?? $iNmSize - 2 !! $iNmSize;

  my Buf $sNm      = $sWk.subbuf( 0,        $iNmSize );
  my Int $iType    = $sWk.subbuf( 0x42,     INT-SIZE ).unpack( "C" );
  my Int $lPpsPrev = $sWk.subbuf( 0x44, LONGINT-SIZE ).unpack( "V" );
  my Int $lPpsNext = $sWk.subbuf( 0x48, LONGINT-SIZE ).unpack( "V" );
  my Int $lDirPps  = $sWk.subbuf( 0x4C, LONGINT-SIZE ).unpack( "V" );

  my DateTime $dtTime1st =
     ( ( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
         OLEDate2LocalObject( $sWk.subbuf( 0x64, 8 ) ) !! Nil;
  my DateTime $dtTime2nd =
     ( ( $iType == PPS-TYPE-ROOT ) or ( $iType == PPS-TYPE-DIR ) ) ??
         OLEDate2LocalObject( $sWk.subbuf( 0x6c, 8 ) ) !! Nil;
  my Int ( $iStart, $iSize ) = $sWk.subbuf( 0x74, 8 ).unpack( "VV" );

  # If we were to make OLE::Storage_Lite::PPS do the work of constructing
  # an object, then that would make OLE::Storage_Lite::PPS aware of its
  # children.
  #
  # And that would be a dependency loop.
  #
  if $bData {
    my $sData = self._getData( $iType, $iStart, $iSize, %hInfo );
    return self.createPps(
      $iPos, $sNm.decode( OLE-ENCODING ),
      $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      $dtTime1st, $dtTime2nd, $iStart, $iSize, $sData, ( )
    );
  }
  else {
    return self.createPps(
      $iPos, $sNm.decode( OLE-ENCODING ),
      $iType, $lPpsPrev, $lPpsNext, $lDirPps,
      $dtTime1st, $dtTime2nd, $iStart, $iSize
    );
  }
}

method _setFilePos( Int $iBlock, Int $iPos, %hInfo ) {
  $.FILE_H.seek(
    ( $iBlock + 1 ) * %hInfo<_BIG_BLOCK_SIZE> + $iPos,
    SeekFromBeginning
  );
}

method _getNthBlockNo( Int $iStBlock, Int $iNth ) {
  my Int $iSv;
  my Int $iNext = $iStBlock;

  loop ( my Int $i = 0; $i < $iNth; $i++ ) {
    $iSv   = $iNext;
    $iNext = self._getNextBlockNo( $iSv );
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
  my Int $_iBlock = $iBlock;
  return '' unless _isNormalBlock( $_iBlock );

  my Int $iRest = $iSize;
  my Buf $sRes  = Buf.new();
  my Int @aKeys = sort { $^a <=> $^b },
                   map { +$_ }, keys %.BBD_INFO;

  while $iRest > 0 {
    my Int @aRes  = grep { $_ >= $_iBlock }, @aKeys;
    my Int $iNKey = @aRes[0];
    my Int $i     = $iNKey - $_iBlock;
    my Int $iNext = %.BBD_INFO{$iNKey};

    self._setFilePos( $_iBlock, 0, %hInfo );

    my Int $iGetSize = %hInfo<_BIG_BLOCK_SIZE> * ( $i + 1 );

    $iGetSize = $iRest if $iRest < $iGetSize;
    my Buf $sWk = $.FILE_H.read( $iGetSize );
    $sRes      ~= $sWk;
    $iRest     -= $iGetSize;
    $_iBlock    = $iNext;
  }
  $sRes;
}

method _getNextBlockNo( Int $iBlockNo ) {
  my $iRes = %.BBD_INFO{~$iBlockNo};

  return defined( $iRes ) ?? $iRes !! $iBlockNo + 1;
}

sub _isNormalBlock( Int $iBlock ) {
  $iBlock < 0xFFFFFFFC;
}

method _getSmallData( Int $iSmBlock, Int $iSize, %hInfo ) {
  my Int $iRest = $iSize;
  my Str $sRes  = '';
  my Str $sWk;

  while $iRest > 0 {
    self._setFilePosSmall( $iSmBlock, %hInfo );
    $sWk = $.FILE_H.read(
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
  my Int $iSmStart = $.SB_START;
  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iNth     = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos     = $iSmBlock % $iBaseCnt;
  my Int $iBlk     = self._getNthBlockNo( $iSmStart, $iNth );

  self._setFilePos( $iBlk, $iPos * %hInfo<_SMALL_BLOCK_SIZE>, %hInfo );
}

method _getNextSmallBlockNo( Int $iSmBlock, %hInfo ) {
  my Int $iBaseCnt = %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE;
  my Int $iNth     = Int( $iSmBlock / $iBaseCnt );
  my Int $iPos     = $iSmBlock % $iBaseCnt;
  my Int $iBlk     = self._getNthBlockNo( $.SBD_START, $iNth );
  my Buf $sWk;

  self._setFilePos( $iBlk, $iPos * LONGINT-SIZE, %hInfo );
  $sWk = $.FILE_H.read( LONGINT-SIZE );

  return $sWk.unpack( "V" );
}

# Asc2Ucs2 has been removed - just use 'encode'
# Ucs2Asc has been removed - just use 'encode'
#
# OLE2LocalDate has moved to OLE::Storage_Lite::Utils
# LocalDate2OLE has moved to OLE::Storage_Lite::Utils

# Rename 'new' to 'create', for the moment.
# The bless() mechanism isn't working for me...
# 
# # Also *gotta* clean up the hierarchy, PPS.pm is referencing child classes.
#
method createPps( Int $No, Str $Name, Int $Type, Int $PrevPps, Int $NextPps,
                  Int $DirPps, DateTime $Time1st, DateTime $Time2nd,
                  Int $StartBlock, Int $Size, $Data?, @Child? ) {
  given $Type {
    when PPS-TYPE-FILE {
      OLE::Storage_Lite::PPS::File.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :$Time1st, :$Time2nd,
        :$Data, :@Child
      )
    }
    when PPS-TYPE-DIR {
      OLE::Storage_Lite::PPS::Dir.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :$Time1st, :$Time2nd,
        :$Data, :@Child
      )
    }
    when PPS-TYPE-ROOT {
      OLE::Storage_Lite::PPS::Root.new(
        :$No, :$Name, :$Type, :$Size, :$StartBlock,
        :$PrevPps, :$NextPps, :$DirPps,
        :$Time1st, :$Time2nd,
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
    my $oPps = $oOl.pps-tree(1);

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

=head2 pps-tree()

    $oPpsRoot = $oOle.pps-tree([$bData]);

Returns PPS as an L<OLE::Storage_Lite::PPS::Root> object. Other PPS objects will be included as its children.

If C<$bData> is true, the objects will have data in the file.

=head2 pps-search()

    $oPpsRoot = $oOle.pps-tree(@aName [, $bData][, $iCase] );

Returns PPSs as L<OLE::Storage_Lite::PPS> objects that has the name specified in C<$raName> array.

If C<$bData> is true, the objects will have data in the file.
If C<$iCase> is true, search is case insensitive.

=head2 Nth-pps()

    $oPpsRoot = $oOle.Nth-pps($iNth [, $bData]);

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

    $oRoot = OLE::Storage_Lite::PPS::Root.new( $dtTime1st, $dtTime2nd, @aChild);

Constructor.

C<$dtTime1st>, C<$dtTime2nd> are array refs with ($iSec, $iMin, $iHour, $iDay, $iMon, $iYear).
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
                  [, $dtTime1st]
                  [, $dtTime2nd]
                  [, @aChild]);


Constructor.

C<$sName> is a name of the PPS.

C<$dtTime1st>, C<$dtTime2nd> is a array ref as
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

This function makes to use file handle for getting and storing data.

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
