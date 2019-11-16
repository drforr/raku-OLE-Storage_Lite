use v6;

# I've changed the "OO" part of this module just to simplify things.
#
# The original module called new() here which called new() on one of a bunch
# of different modules based on $iType.
#
# That means a parent module needed to include its children. Which is bad.
# So instead I put the method higher up in the OLE::Storage_Lite hierarchy.
# It now just needs the PPS modules it's going to disgorge, so it's more like
# a Factory pattern, I suppose.
#

unit class OLE::Storage_Lite::PPS;

use experimental :pack;

has Int $.No is rw;
has Str $.Name is rw; # Gotten usually from Buffers, decoded to UTF-8...
has Int $.Type is rw is required;
has Int $.PrevPps is rw;
has Int $.NextPps is rw;
has Int $.DirPps is rw;
has     @.Time1st is rw;
has     @.Time2nd is rw;
has Int $.StartBlock is rw;
has Int $.Size is rw;
has     $.Data is rw;
has     @.Child is rw;

has Str $._PPS_FILE;

has $.FILE is rw; # XXX JMG Not sure why this wasn't factored out earlier.

# The old 'new' methods really don't do anything special.

method _DataLen {
  return 0 unless self.Data;
  self._PPS_FILE ??
    self._PPS_FILE.stat()[7] !!
    self.Data.chars;
}

method _makeSmallData( @aList, %hInfo ) {
  my Str        $sRes;
#  my IO::Handle $FILE   = %hInfo<_FILEH_>;
  my Int        $iSmBlk = 0;

  for @aList -> $oPps {
    if $oPps.Type == 2 { # OLE::Storage_Lite::PPS-TYPE-FILE
      next if $oPps.Size <= 0;
      if $oPps.Size < %hInfo<_SMALL_SIZE> {
        my Int $iSmbCnt =
	  ( Int( $oPps.Size / %hInfo<_SMALL_BLOCK_SIZE> ) +
   	       ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ) ?? 1 !! 0;

	loop ( my Int $i = 0 ; $i < $iSmbCnt - 1 ; $i++ ) {
	  $.FILE.write( pack( "V", $i + $iSmBlk + 1 ) );
	}
	$.FILE.write( pack( "V", -2 ) );

	if $oPps._PPS_FILE {
	  my Buf $sBuff;
	  $oPps._PPS_FILE.seek( 0, SeekFromBeginning );
	  while $sBuff = $oPps._PPS_FILE.read( 4096 ) {
	    $sRes ~= $sBuff;
	  }
	}
	else {
	  $sRes ~= $oPps.Data;
	}

	$sRes ~= ( "\x00" xx 
	           ( %hInfo<_SMALL_BLOCK_SIZE> -
		     ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ) ) if
	  $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE>;
	
	$oPps.StartBlock = $iSmBlk;
	$iSmBlk += $iSmbCnt;
      }
    }
  }

  my Int $iSbCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / 4 ); # LONG-INT-SIZE
  $.FILE.write( pack( "V", -1 ) xx ( $iSbCnt - ( $iSmBlk % $iSbCnt ) ) ) if
    $iSmBlk % $iSbCnt;

  $sRes;
}

method _savePpsWk( %rhInfo ) {
#  my $FILE = %rhInfo.<_FILEH_>;

  $.FILE.write(
    self.Name
    ~ "\x80" xx ( 64 - self.Name.chars )                                 # 64
    ~ ( self.Name.chars + 2 ).pack( "v" )                                # 66
    ~ self.Type.pack( "c" )                                              # 67
    ~ 0x00.pack( "c" )                                                   # 68
    ~ self.PrevPps.pack( "V" )                                           # 72
    ~ self.NextPps.pack( "V" )                                           # 76
    ~ self.DirPps.pack( "V" )                                            # 80
    ~ "\x00\x09\x02\x00"                                                 # 84
    ~ "\x00\x00\x00\x00"                                                 # 88
    ~ "\xc0\x00\x00\x00"                                                 # 92
    ~ "\x00\x00\x00\x46"                                                 # 96
    ~ "\x00\x00\x00\x00"                                                 # 100
    ~ OLE::Storage_Lite::LocalDate2OLE( self.Time1st )                   # 108
    ~ OLE::Storage_Lite::LocalDate2OLE( self.Time2nd )                   # 116
    ~ ( defined( self.StartBlock ?? self.StartBlock !! 0 ) ).pack( "V" ) # 120
    ~ ( defined( self.size ?? self.Size !! 0 ) ).pack( "V" )             # 124
    ~ 0.pack( "V" )                                                      # 128
  );
}
