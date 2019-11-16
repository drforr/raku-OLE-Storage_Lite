use v6;

use OLE::Storage_Lite::PPS;
use OLE::Storage_Lite::PPS::File;

use experimental :pack;

unit class OLE::Storage_Lite::PPS::Root is OLE::Storage_Lite::PPS;

constant LONGINT-SIZE = 4;

#has $.FILE is rw; # XXX JMG Not sure why this wasn't factored out earlier.

multi method new ( @Time1st, @Time2nd, @Child ) {
  self.bless(
    :Name( 'Root Entry' ),
    :Type( 5 ),
    :@Time1st,
    :@Time2nd,
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
  %hInfo<_PPS_SIZE>   = 0x80;

  # sFile is Ref of scalar
  #
#  %hInfo<_FILEH_> = open $sFile;
  $.FILE = open $sFile, :w;
  $.FILE.encoding( Nil ); # Binary "encoding"

  my Int $iBlk = 0;

  # Make an array of PPS
  #
  my @aList = ( );
my @thisList = ( self );
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
  my Str $sSmWk = self._makeSmallData( @aList, %hInfo );
  self.Data     = $sSmWk; # Small data's become RootEntry Data

  # Write BB
  #
  my Int $iBBlk = $iSBDcnt;
  self._saveBigData( $iBBlk, @aList, %hInfo );

  # Write PPS
  #
  self._savePps( @aList, %hInfo );

  # Write BD and BDList and Adding Header Information
  #
  self._saveBbd( $iSBDcnt, $iBBcnt, $iPPScnt, %hInfo );
}

method _calcSize( @aList, %hInfo ) {
  my Int ( $iSBDcnt, $iBBcnt, $iPPScnt ) = ( 0, 0, 0 );
  my Int $iSmallLen = 0;
  my Int $iSBcnt    = 0;

  for @aList -> $oPps {
    if $oPps.Type == 2 { # OLE::Storage_Lite::PPS-TYPE-FILE
      $oPps.Size = $oPps._DataLen(); # Mod
      if $oPps.Size < %hInfo<_SMALL_SIZE> {
	$iSBcnt += Int( $oPps.Size / %hInfo<_SMALL_BLOCK_SIZE> ) +
	              ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ?? 1 !! 0;
      }
      else {
	$iBBcnt += Int( $oPps.Size / %hInfo<_BIG_BLOCK_SIZE> ) +
  	              ( ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );
      }
    }
  }

  $iSmallLen = $iSBcnt * %hInfo<_SMALL_BLOCK_SIZE>;
  my Int $iSlCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / 4 ); # LONG-INT-SIZE
  $iSBDcnt = Int( $iSBcnt / $iSlCnt ) + ( ( $iSBcnt % $iSlCnt ) ?? 1 !! 0 );
  $iSBcnt += Int( $iSmallLen / %hInfo<_BIG_BLOCK_SIZE> ) +
                 ( ( $iSmallLen % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );

  my Int $iCnt   = @aList.elems;
  # JMG added Int() around this division
  my Int $iBdCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / 0x80 ); # PPS-SIZE
  $iPPScnt = Int( $iCnt / $iBdCnt ) + ( ( $iCnt % $iBdCnt ) ?? 1 !! 0 );
  return ( $iSBDcnt, $iBBcnt, $iPPScnt );
}

method _adjust2( Int $i2 ) {
  my $iWk = log( $i2 ) / log(2);

  ( $iWk > Int( $iWk ) ) ?? Int( $iWk ) + 1 !! $iWk;
}

method _saveHeader( %hInfo, Int $iSBDCnt, Int $iBBcnt, Int $iPPScnt ) {
#  my $FILE = %hInfo<_FILEH_>; # pFile originally?

  # Calculate basic setting
  #
  # JMG added Int() around these divisions
  my Int $iBlCnt  = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  my Int $i1stBdl = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4C ) / LONGINT-SIZE );
  my Int $i1stBdMax = $i1stBdl * $iBlCnt - $i1stBdl;
  my Int $iBdExL    = 0;
  my Int $iAll      = $iBBcnt + $iPPScnt + $iSBDCnt;
  my Int $iAllW     = $iAll;
  my Int $iBdCntW   = Int( $iAllW / $iBlCnt ) + ( $iAllW % $iBlCnt ?? 1 !! 0 );
  my Int $iBdCnt =
    Int( ( $iAll + $iBdCntW ) / $iBlCnt ) +
       ( ( ( $iAllW + $iBdCntW ) % $iBlCnt ) ?? 1 !! 0 );
  my Int $i;

  if $iBdCnt > $i1stBdl {
    # Calculate BD count
    #
    $iBlCnt--;
    my $iBBleftover = $iAll - $i1stBdMax;

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
    $iBdCnt += $i1stBdl;
  }

  # Save Header
  #
  $.FILE.write(
     "\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1" ~
     "\x00\x00\x00\x00" x 4 ~
     pack( "v", 0x3b ) ~
     pack( "v", 0x03 ) ~
     pack( "v", -2 ) ~
     pack( "v", 9 ) ~
     pack( "v", 6 ) ~
     pack( "v", 0 ) ~
     "\x00\x00\x00\x00" x 2 ~
     pack( "V", $iBdCnt ) ~
     pack( "V", $iBBcnt + $iSBDCnt ) ~ # ROOT START
     pack( "V", 0 ) ~
     pack( "V", 0x1000 ) ~
     pack( "V", $iSBDCnt ?? 0 !! -2 ) ~
     pack( "V", $iSBDCnt )
  );

  # Extra BDlist Start, Count
  #
  if $iAll <= $i1stBdMax {
    $.FILE.write(
      pack( "V", -2 ) ~ # Extra BDlist Start
      pack( "V", 0 )    # Extra BDList Count
    );
  }
  else {
    $.FILE.write(
      pack( "V", $iAll + $iBdCnt ) ~ # Extra BDlist Start
      pack( "V", $iBdExL )           # Extra BDList Count
    );
  }

  # BDlist
  #
  loop ( $i = 0 ; $i < $i1stBdl and $i < $iBdCnt ; $i++ ) {
    $.FILE.write( pack( "V", $iAll + $i ) );
  }
#  $.FILE.write( ( pack( "V", -1 ) xx ( $i1stBdl - $i ) ) ) if $i < $i1stBdl;
}

# XXX Note that $iStBlk in the original source is a reference to a Scalar.
# XXX
method _saveBigData( Int $iStBlk is rw, @aList, %hInfo ) {
  my Int        $iRes = 0;
#  my IO::Handle $FILE = %hInfo<_FILEH_>;

  # Write Big (>= 0x1000) into Block
  #
  for @aList -> $oPps {
    if $oPps.Type != 1 { # PPS-TYPE-DIR
      $oPps.Size = $oPps._DataLen(); # Mod
      if ( $oPps.Size >= %hInfo<_SMALL_SIZE> ) ||
         ( ( $oPps.Type == 5 ) && defined( $oPps.Data ) ) { # PPS-TYPE-ROOT

	# Check for update
	#
	if $oPps._PPS_FILE {
	  my Buf $sBuff;
	  my Int $iLen = 0;
	  $oPps._PPS_FILE.seek( 0, SeekFromBeginning ); # 0, 0
	  while $sBuff = $oPps._PPS_FILE.read: 4096 {
	    $iLen += $sBuff.chars;
	    $.FILE.print( $sBuff );
	  }
	}
	else {
	  $.FILE.print( $oPps.Data );
	}
	$.FILE.print(
	  "\x00" xx ( %hInfo<_BIG_BLOCK_SIZE> -
	              ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) )
	) if $oPps.Size % %hInfo<_BIG_BLOCK_SIZE>;

	$oPps.StartBlock = $iStBlk;
	$iStBlk += Int( $oPps.Size / %hInfo<_BIG_BLOCK_SIZE> ) +
	              ( ( $oPps.Size % %hInfo<_BIG_BLOCK_SIZE> ) ?? 1 !! 0 );
      }
    }
  }
}

method _savePps( @aList, %hInfo ) {
#  my $FILE = %hInfo<_FILEH_>;

  for @aList -> $oItem {
    $oItem._savePpsWk( %hInfo );
  }

  my Int $iCnt  = @aList.elems;
  my Int $iBCnt = %hInfo<_BIG_BLOCK_SIZE> / %hInfo<_PPS_SIZE>;
  $.FILE.print( "\x00" xx
               ( ( $iBCnt - ( $iCnt % $iBCnt ) ) * %hInfo<_PPS_SIZE> ) )
    if $iCnt % $iBCnt;
  Int( $iCnt / $iBCnt ) + ( ( $iCnt % $iBCnt ) ?? 1 !! 0 );
}

method _savePpsSetPnt2( @aThis, @aList, %hInfo ) {
  # If no child relations
  #
  if @aThis.elems <= 0 {
    return 0xffffffff;
  }
  elsif @aThis.elems == 1 {
    append @aList, @aThis[0];
    @aThis[0]<No>      = @aList.elems;
    @aThis[0]<PrevPps> = 0xffffffff;
    @aThis[0]<NextPps> = 0xffffffff;
    @aThis[0]<DirPps> =
      self._savePpsSetPnt2( @aThis[0]<Child>, @aList, %hInfo );
    return @aThis[0]<No>;
  }
  else {
    my Int $iCnt = @aThis.elems;
    my Int $iPos = 0;
    my @aWk      = @aThis;
    my @aPrev    = @aThis.elems > 1 ?? splice( @aWk, 1, 1 ) !! ( );
    my @aNext    = splice( @aWk, 1 );

    @aThis[$iPos]<PrevPps> =
      self._savePpsSetPnt2( @aPrev, @aList, %hInfo );
    append @aList, @aThis[$iPos];
    @aThis[$iPos]<No> = @aList.elems;
    @aThis[$iPos]<NextPps> =
      self._savePpsSetPnt2( @aNext, @aList, %hInfo );
    @aThis[$iPos]<DirPps> =
      self._savePpsSetPnt2( @aThis[$iPos]<Child>, @aList, %hInfo );
    return @aThis[$iPos]<No>;
  }
}

# XXX Removed _savePpsSetPnt2s() - it's not used at all.

sub _savePpsSetPnt( @aThis, @aList, %hInfo ) {
  # If no child relations
  #
  if @aThis.elems <= 0 {
    return 0xffffffff;
  }
  elsif @aThis.elems == 1 {
    # Just one element
    #
    append @aList, @aThis[0];
    @aThis[0].No      = @aList.elems;
    @aThis[0].PrevPps = 0xffffffff;
    @aThis[0].NextPps = 0xffffffff;
    @aThis[0].DirPps  = _savePpsSetPnt( @aThis[0].Child, @aList, %hInfo );

    return @aThis[0].No;
  }
  else {
    # Array
    #
    my Int $iCnt = @aThis.elems;

    # Define center
    #
    my Int $iPos = Int( $iCnt / 2 );
    append @aList, @aThis[$iPos];
    @aThis[$iPos].No = @aList.elems;
    my @aWk = @aThis;

    # Divide array into Previous, Next
    #
    my @aPrev = splice( @aWk, 0, $iPos );
    my @aNext = splice( @aWk, 1, $iCnt - $iPos - 1 );
    @aThis[$iPos].PrevPps = _savePpsSetPnt( @aPrev, @aList, %hInfo );
    @aThis[$iPos].NextPps = _savePpsSetPnt( @aNext, @aList, %hInfo );
    @aThis[$iPos].DirPps =
      _savePpsSetPnt( @aThis[$iPos].Child, @aList, %hInfo );
    return @aThis[$iPos].No;
  }
}

# XXX _savePpsSetPnt1 isn't used anywhere in the source

method _saveBbd( Int $iSbdSize, Int $iBsize, Int $iPpsCnt, %hInfo ) {
#  my $FILE = %hInfo<_FILEH_>;

  # Calculate basic setting
  #
  my Int $iBbCnt  = %hInfo<_BIG_BLOCK_SIZE> / 4; # LONG-INT-SIZE
  my Int $iBlCnt  = $iBbCnt - 1;
  my Int $i1stBdL = Int( ( %hInfo<_BIG_BLOCK_SIZE> - 0x4c ) / 4 ); # LONG-INT-SIZE
  my Int $i1stBdMax = $i1stBdL * $iBbCnt - $i1stBdL;
  my Int $iBdExL    = 0;
  my Int $iAll      = $iBsize + $iPpsCnt + $iSbdSize;
  my Int $iAllW     = $iAll;
  my Int $iBdCntW   = Int( $iAllW / $iBbCnt ) + ( $iAllW % $iBbCnt ?? 1 !! 0 );
  my Int $iBdCnt;
  my Int $i;

  # Calculate BD count
  #
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

  # Making BD
  #
  if $iSbdSize > 0 {
    loop ( $i = 0 ; $i < $iSbdSize - 1 ; $i++ ) {
      $.FILE.print( pack( "V", $i + 1 ) );
    }
    $.FILE.print( pack( "V", -2 ) );
  }

  # Set for B
  #
  loop ( $i = 0 ; $i < $iBsize - 1 ; $i++ ) {
    $.FILE.print( pack( "V", $i + $iSbdSize + 1 ) );
  }
  $.FILE.print( pack( "V", -2 ) );

  # Set for PPS
  #
  loop ( $i = 0 ; $i < $iPpsCnt - 1 ; $i++ ) {
    $.FILE.print( pack( "V", $i + $iSbdSize + $iBsize + 1 ) );
  }
  $.FILE.print( pack( "V", -2 ) );

  # Set for BBD itself ( 0xFFFFFFFD : BBD )
  #
  loop ( $i = 0 ; $i < $iBdCnt ; $i++ ) {
    $.FILE.print( pack( "V", 0xFFFFFFFD ) );
  }

  # Set for ExtraBDList
  #
  loop ( $i = 0 ; $i < $iBdExL ; $i++ ) {
    $.FILE.print( pack( "V", 0xFFFFFFFC ) );
  }

  # Adjust for Block
  #
  $.FILE.print( ( pack( "V", -1 ) ) xx
                 ( $iBbCnt - ( $iAllW + $iBdCnt % $iBbCnt ) ) )
    if $iAllW + $iBdCnt % $iBbCnt;

  # Extra BDList
  #
  if $iBdCnt > $i1stBdL {
    my Int $iN = 0;
    my Int $iNb = 0;
    loop ( $i = $i1stBdL ; $i < $iBdCnt ; $i++, $iN++ ) {
      if $iN >= $iBbCnt - 1 {
	$iN = 0;
	$iNb++;
	$.FILE.print( pack( "V", $iAll + $iBdCnt + $iNb ) );
      }
      $.FILE.print( ( pack( "V", -1 ) ) xx
                   ( ( $iBbCnt - 1 ) - ( $iBdCnt - $i1stBdL % $iBbCnt - 1 ) ) )
        if $iBdCnt - $i1stBdL % $iBbCnt - 1;
      $.FILE.print( pack( "V", -2 ) );
    }
  }
}
