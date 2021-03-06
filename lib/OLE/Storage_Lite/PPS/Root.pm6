use v6;

use OLE::Storage_Lite::PPS;
use OLE::Storage_Lite::Utils;

unit class OLE::Storage_Lite::PPS::Root is OLE::Storage_Lite::PPS;

use experimental :pack;

# XXX You're going to see a bit of '.elems - 1' in this code.
# XXX This is just so I can keep the off-by-one problems down. The original
# XXX Perl code uses $#{array} and @array.elems - 1 is the closest analog.
# XXX It'll probably go away when I've got the code stable.

constant OLE-ENCODING = 'UTF-16LE';

constant PPS-TYPE-DIR  = 1;
constant PPS-TYPE-FILE = 2;
constant PPS-TYPE-ROOT = 5;

constant LONGINT-SIZE = 4;

constant PPS-SIZE     = 0x80;

constant SENTINEL-END = 0xffffffff;

multi method new ( $Time1st, $Time2nd, @Child ) {
  self.bless(
    :Name( 'Root Entry' ),
    :Type( 5 ),
    :$Time1st,
    :$Time2nd,
    :@Child
  )
}

method save( Str $sFile, $bNoAs?, %hInfo? ) {
  %hInfo<_BIG_BLOCK_SIZE> =
    2**( %hInfo<_BIG_BLOCK_SIZE> ??
         self._adjust2( %hInfo<_BIG_BLOCK_SIZE> ) !! 9 );
  %hInfo<_SMALL_BLOCK_SIZE> =
    2**( %hInfo<_SMALL_BLOCK_SIZE> ??
         self._adjust2( %hInfo<_SMALL_BLOCK_SIZE> ) !! 6 );
  %hInfo<_SMALL_SIZE> = 0x1000;

  # sFile is Ref of scalar
  #
  %hInfo<_FILEH_> = open $sFile, :w;
  %hInfo<_FILEH_>.encoding( Nil ); # Binary "encoding"

  my Int $iBlk = 0;

  # Make an array of PPS
  #
  my OLE::Storage_Lite::PPS @aList;
my OLE::Storage_Lite::PPS @thisList = ( self );
  if $bNoAs {
    self._savePpsSetPnt2( @thisList, @aList, %hInfo ); 
  }
  else {
    _savePpsSetPnt( @thisList, @aList, %hInfo );
  }
  my Int ( $iSBDcnt, $iBBcnt, $iPPScnt ) = self._calcSize( @aList, %hInfo );

  # Save header
  #
  self._saveHeader( %hInfo, $iSBDcnt, $iBBcnt, $iPPScnt );

  # Make small data string
  #
  my Buf $sSmWk = self._makeSmallData( @aList, %hInfo );
  self.Data     = $sSmWk; # Small data's become RootEntry Data

  # Write BB
  #
  # This is a weird bit. 
  my Int $iBBlk = $iSBDcnt;
  self._saveBigData( $iBBlk, @aList, %hInfo );

  # Write PPS
  #
  self._savePps( @aList, %hInfo );

  # Write BD and BDList and Adding Header Information
  #
  self._saveBbd( $iSBDcnt, $iBBcnt, $iPPScnt, %hInfo );
  close %hInfo<_FILEH_>;
}

method _calcSize( OLE::Storage_Lite::PPS @aList, %hInfo ) {
  my Int ( $iSBDcnt, $iBBcnt, $iPPScnt ) = ( 0, 0, 0 );
  my Int $iSmallLen = 0;
  my Int $iSBcnt    = 0;

  for @aList -> $oPps {
    if $oPps.Type == PPS-TYPE-FILE {
      $oPps.Size = $oPps._DataLen(); # Mod
      if $oPps.Size < %hInfo<_SMALL_SIZE> {
	$iSBcnt += Int( $oPps.Size / %hInfo<_SMALL_BLOCK_SIZE> ) +
	              ( ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ?? 1 !! 0 );
      }
      else {
	$iBBcnt += Int( $oPps.Size / %hInfo<_BIG_BLOCK_SIZE> ) +
  	              ( ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );
      }
    }
  }

  $iSmallLen = $iSBcnt * %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iSlCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  $iSBDcnt = Int( $iSBcnt / $iSlCnt ) + ( ( $iSBcnt % $iSlCnt ) ?? 1 !! 0 );
  $iBBcnt += Int( $iSmallLen / %hInfo<_BIG_BLOCK_SIZE> ) +
                 ( ( $iSmallLen % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );

  my Int $iCnt   = @aList.elems;
  # JMG added Int() around this division
  my Int $iBdCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  $iPPScnt = Int( $iCnt / $iBdCnt ) + ( ( $iCnt % $iBdCnt ) ?? 1 !! 0 );
  return ( $iSBDcnt, $iBBcnt, $iPPScnt );
}

method _adjust2( Int $i2 ) {
  my Int $iWk = log( $i2 ) / log(2);

  ( $iWk > Int( $iWk ) ) ?? Int( $iWk ) + 1 !! $iWk;
}

method _saveHeader( %hInfo, Int $iSBDcnt, Int $iBBcnt, Int $iPPScnt ) {
  my Int $iBlCnt    = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  my Int $i1stBdL   = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4C ) / LONGINT-SIZE );
  my Int $i1stBdMax = $i1stBdL * $iBlCnt - $i1stBdL;
  my Int $iBdExL    = 0;
  my Int $iAll      = $iBBcnt + $iPPScnt + $iSBDcnt;
  my Int $iAllW     = $iAll;
  my Int $iBdCntW   = Int( $iAllW / $iBlCnt ) +
                         ( ( $iAllW % $iBlCnt ) ?? 1 !! 0 );
  my Int $iBdCnt =
    Int( ( $iAll + $iBdCntW ) / $iBlCnt ) +
       ( ( ( $iAllW + $iBdCntW ) % $iBlCnt ) ?? 1 !! 0 );
  my Int $i;

  my IO::Handle $FILE = %hInfo<_FILEH_>;

  # Calculate basic setting

  if $iBdCnt > $i1stBdL {
    # Calculate BD count
    #
    $iBlCnt--;
    my Int $iBBleftover = $iAll - $i1stBdMax;

    if $iAll > $i1stBdMax {
      loop {
        $iBdCnt = Int( $iBBleftover / $iBlCnt ) +
	             ( ( $iBBleftover % $iBlCnt ) ?? 1 !! 0 );
	$iBdExL = Int( $iBdCnt / $iBlCnt ) +
	             ( ( $iBdCnt % $iBlCnt ) ?? 1 !! 0 );
	$iBBleftover = $iBBleftover + $iBdExL;
	last if $iBdCnt == Int( $iBBleftover / $iBlCnt ) +
	                      ( $iBBleftover % $iBlCnt ?? 1 !! 0 );
      }
    }
    $iBdCnt += $i1stBdL;
  }

  # Save Header
  #
  $FILE.write( Blob.new( flat
    0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1,
    _int32( 0 ) xx 4,
    _int16( 0x3b ),                # pack("v", 0x3b)
    _int16( 0x03 ),                # pack("v", 0x03)
    _int16( -2 ),                  # pack("v", -2)
    _int16( 9 ),                   # pack("v", 9)
    _int16( 6 ),                   # pack("v", 6)
    _int16( 0 ),                   # pack("v", 0)
    _int32( 0 ) xx 2,              # "\x00\x00\x00\x00" x 2
    _int32( $iBdCnt ),             # pack("V", $iBdCnt),
    _int32( $iBBcnt + $iSBDcnt ),  # pack("V", $iBBcnt+$iSBDcnt), #ROOT START
    _int32( 0 ),                   # pack("V", 0)
    _int32( 0x1000 ),              # pack("V", 0x1000)
    _int32( $iSBDcnt ?? 0 !! -2 ), # pack("V", $iSBDcnt ? 0 : -2) Small Block Depot
    _int32( $iSBDcnt )             # pack("V", $iSBDcnt)
  ) );

  # Extra BDlist Start, Count
  #
  if $iAll <= $i1stBdMax {
    $FILE.write( Blob.new( flat
      _int32( -2 ), # Extra BDList Start
      _int32( 0 )   # Extra BDList Count
    ) );
  }
  else {
    $FILE.write( Blob.new( flat
      _int32( $iAll + $iBdCnt ), # Extra BDList Start
      _int32( $iBdExL )          # Extra BDlist Count
    ) );
  }

  # BDlist
  #
  loop ( $i = 0 ; $i < $i1stBdL and $i < $iBdCnt ; $i++ ) {
    $FILE.write( Blob.new( _int32( $iAll + $i ) ) );
  }
  if $i < $i1stBdL {
    $FILE.write( Blob.new( flat
      ( _int32( -1 ) ) xx ( $i1stBdL - $i )
    ) );
  }
}

# XXX Note that $iStBlk in the original source is a reference to a Scalar.
# XXX
# XXX Later on I bind to another variable to reflect better what might be going
# XXX on in the code.
# XXX
method _saveBigData( Int $iStBlk is rw, OLE::Storage_Lite::PPS @aList, %hInfo ) {
  my Int        $iRes = 0;
  my IO::Handle $FILE = %hInfo<_FILEH_>;

  # Write Big (>= 0x1000) into Block
  #
  for @aList -> $oPps {
    if $oPps.Type != PPS-TYPE-DIR {
      $oPps.Size = $oPps._DataLen(); # Mod
      if ( $oPps.Size >= %hInfo<_SMALL_SIZE> ) ||
         ( ( $oPps.Type == PPS-TYPE-ROOT ) && defined( $oPps.Data ) ) {

	# Check for update
	#
	if $oPps._PPS_FILE {
	  my Buf $sBuff;
	  my Int $iLen = 0;
	  $oPps._PPS_FILE.seek( 0, SeekFromBeginning ); # 0, 0
	  while $sBuff = $oPps._PPS_FILE.read: 4096 {
	    $iLen += $sBuff.chars;
	    $FILE.write( $sBuff );
	  }
	}
	else {
	  # XXX Not sure if this is where we want to encode...
	  $FILE.write( $oPps.Data );
	}
	if $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> {
	  $FILE.write(
	    Blob.new(
	      0x00 xx ( %hInfo<_BIG_BLOCK_SIZE> -
	                ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) ) )
	  )
        }

	# Set for PPS
	#
	$oPps.StartBlock = $iStBlk;
	$iStBlk += Int( $oPps.Size / %hInfo<_BIG_BLOCK_SIZE> ) +
	              ( ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );
      }
    }
  }
}

method _savePps( OLE::Storage_Lite::PPS @aList, %hInfo ) {
  my IO::Handle $FILE = %hInfo<_FILEH_>;

  for @aList -> $oItem {
    $oItem._savePpsWk( %hInfo );
  }

#3. Adjust for Block
  my Int $iCnt  = @aList.elems;
  # XXX Added Int() here
  my Int $iBCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / PPS-SIZE );
  if $iCnt % $iBCnt {
    for ^( ( $iBCnt - ( $iCnt % $iBCnt ) ) * PPS-SIZE ) {
      $FILE.write( Buf.new( _int8( 0 ) ) );
    }
  }
  Int( $iCnt / $iBCnt ) + ( ( $iCnt % $iBCnt ) ?? 1 !! 0 );
}

method _savePpsSetPnt2( @aThis, OLE::Storage_Lite::PPS @aList, %hInfo ) {
  # If no child relations
  #
#1. make Array as Children-Relations
#1.1 if No Children
  if @aThis.elems - 1 < 0 {
    return SENTINEL-END;
  }
#1.2 Just Only one
  elsif @aThis.elems - 1 == 0 {
    append @aList, @aThis[0];
    @aThis[0].No      = @aList.elems - 1;
    @aThis[0].PrevPps = SENTINEL-END;
    @aThis[0].NextPps = SENTINEL-END;
    @aThis[0].DirPps =
      self._savePpsSetPnt2( @aThis[0].Child, @aList, %hInfo );
    return @aThis[0].No;
  }
  else {
#1.3 Array
    my Int $iCnt = @aThis.elems;
#1.3.1 Define Center
    my Int $iPos = 0;
    my OLE::Storage_Lite::PPS @aWk   = @aThis;
    my OLE::Storage_Lite::PPS @aPrev =
       @aThis.elems - 1 > 1 ?? splice( @aWk, 1, 1 ) !! ( );
    my OLE::Storage_Lite::PPS @aNext = splice( @aWk, 1 );

    @aThis[$iPos].PrevPps =
      self._savePpsSetPnt2( @aPrev, @aList, %hInfo );
    append @aList, @aThis[$iPos];
    @aThis[$iPos].No = @aList.elems - 1;

#1.3.2 Divide an array into Previous, Next
    @aThis[$iPos].NextPps =
      self._savePpsSetPnt2( @aNext, @aList, %hInfo );
    @aThis[$iPos].DirPps =
      self._savePpsSetPnt2( @aThis[$iPos].Child, @aList, %hInfo );
    return @aThis[$iPos].No;
  }
}

# XXX Removed _savePpsSetPnt2s() - it's not used at all.

sub _savePpsSetPnt( @aThis, @aList, %hInfo ) {
  # If no child relations
  #
#1. make Array as Children-Relations
#1.1 if No Children
  if @aThis.elems - 1 < 0 {
    return SENTINEL-END;
  }
#1.2 Just Only one
  elsif @aThis.elems - 1 == 0 {
    # Just one element
    #
    append @aList, @aThis[0];
    @aThis[0].No      = @aList.elems - 1;
    @aThis[0].PrevPps = SENTINEL-END;
    @aThis[0].NextPps = SENTINEL-END;
    @aThis[0].DirPps  = _savePpsSetPnt( @aThis[0].Child, @aList, %hInfo );

    return @aThis[0].No;
  }
#1.3 Array
  else {
#1.3.1 Define Center
    my Int $iCnt = @aThis.elems;

    # Define center
    #
    my Int $iPos = Int( $iCnt / 2 );
    append @aList, @aThis[$iPos];
    @aThis[$iPos].No = @aList.elems - 1;
    my OLE::Storage_Lite::PPS @aWk = @aThis;

#1.3.2 Divide a array into Previous,Next
    # Divide array into Previous, Next
    #
    my OLE::Storage_Lite::PPS @aPrev = splice( @aWk, 0, $iPos );
    my OLE::Storage_Lite::PPS @aNext = splice( @aWk, 1, $iCnt - $iPos - 1 );
    @aThis[$iPos].PrevPps = _savePpsSetPnt( @aPrev, @aList, %hInfo );
    @aThis[$iPos].NextPps = _savePpsSetPnt( @aNext, @aList, %hInfo );
    @aThis[$iPos].DirPps =
      _savePpsSetPnt( @aThis[$iPos].Child, @aList, %hInfo );
    return @aThis[$iPos].No;
  }
}

# XXX _savePpsSetPnt1 isn't used anywhere in the source

method _saveBbd( Int $iSbdSize, Int $iBsize, Int $iPpsCnt, %hInfo ) {
  my IO::Handle $FILE = %hInfo<_FILEH_>;

#0. Calculate Basic Setting

  # XXX JMG Added Int() here
  my Int $iBbCnt    = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  my Int $iBlCnt    = $iBbCnt - 1;
  my Int $i1stBdL   = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4c ) / LONGINT-SIZE );
  my Int $i1stBdMax = $i1stBdL * $iBbCnt - $i1stBdL;
  my Int $iBdExL    = 0;
  my Int $iAll      = $iBsize + $iPpsCnt + $iSbdSize;
  my Int $iAllW     = $iAll;
  my Int $iBdCntW   = Int( $iAllW / $iBbCnt ) + ( $iAllW % $iBbCnt ?? 1 !! 0 );
  my Int $iBdCnt;
  my Int $i;

#0.1 Calculate BD count
  my Int $iBBleftover = $iAll - $i1stBdMax;
  if $iAll > $i1stBdMax {
    loop {
      $iBdCnt = Int( ( $iBBleftover / $iBlCnt ) + ( ( $iBBleftover % $iBlCnt ) ?? 1 !! 0 ) );
      $iBdExL = Int( $iBdCnt / $iBlCnt ) + ( ( $iBdCnt % $iBlCnt ) ?? 1 !! 0 );
      $iBBleftover = $iBBleftover + $iBdExL;
      last if $iBdCnt == Int( $iBBleftover / $iBlCnt ) +
                            ( ( $iBBleftover % $iBlCnt ) ?? 1 !! 0 );
    }
  }
  $iAllW  += $iBdExL;
  $iBdCnt += $i1stBdL;

#1. Making BD
#1.1 Set for SBD
  if $iSbdSize > 0 {
    loop ( $i = 0 ; $i < ( $iSbdSize - 1 ) ; $i++ ) {
      $FILE.write( Blob.new( _int32( $i + 1 ) ) );
    }
#1..0x17 count
    $FILE.write( Blob.new( _int32( -2 ) ) );
  }

#1.2 Set for B
  loop ( $i = 0 ; $i < ( $iBsize - 1 ) ; $i++ ) {
    $FILE.write( Blob.new( _int32( $i + $iSbdSize + 1 ) ) )
  }
  $FILE.write( Blob.new( _int32( -2 ) ) );

#1.3 Set for PPS
  loop ( $i = 0 ; $i < $iPpsCnt - 1 ; $i++ ) {
    $FILE.write( Blob.new( _int32( $i + $iSbdSize + $iBsize + 1 ) ) );
  }
  $FILE.write( Blob.new( _int32( -2 ) ) );

#1.4 Set for BBD itself ( 0xFFFFFFFD : BBD)
  loop ( $i = 0 ; $i < $iBdCnt ; $i++ ) {
    $FILE.write( Blob.new( _int32( 0xfffffffd ) ) );
  }

#1.5 Set for ExtraBDList
  loop ( $i = 0 ; $i < $iBdExL ; $i++ ) {
    $FILE.write( Blob.new( _int32( 0xfffffffc ) ) );
  }

#1.6 Adjust for Block
  if ( $iAllW + $iBdCnt ) % $iBbCnt {
    loop ( $i = 0 ; $i < $iBbCnt - ( ( $iAllW + $iBdCnt ) % $iBbCnt ) ; $i++ ) {
      $FILE.write( Blob.new( _int32( -1 ) ) );
    }
  }

#2.Extra BDList
  if $iBdCnt > $i1stBdL {
    my Int $iN  = 0;
    my Int $iNb = 0;

    loop ( my Int $i = $i1stBdL ; $i < $iBdCnt ; $i++, $iN++ ) {
      if $iN >= ( $iBbCnt - 1 ) {
          $iN = 0;
          $iNb++;

          $FILE.write( Blob.new( _int32( $iAll + $iBdCnt + $iNb ) ) );
      }
      $FILE.write( Blob.new( _int32( $iBsize + $iSbdSize + $iPpsCnt + $i ) ) );
    }
    if ( $iBdCnt - $i1stBdL ) % ( $iBbCnt - 1 ) {
      $FILE.write( Blob.new( _int32( -1 ) ) ) for
        ( ( $iBbCnt - 1 ) - ( ( $iBdCnt - $i1stBdL ) % ( $iBbCnt - 1 ) ) );
    }
    $FILE.write( Blob.new( _int32( -2 ) ) );
  }
}
