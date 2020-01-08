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
# Also, anything that *needs* to do something type-specific to an object
# of a particular subclass should just be a method on that subclass, so it
# should never need to be invoked directly.

unit class OLE::Storage_Lite::PPS;

use OLE::Storage_Lite::Utils;

constant OLE-ENCODING = 'UTF-16LE';

constant PPS-TYPE-DIR  = 1;
constant PPS-TYPE-FILE = 2;
constant PPS-TYPE-ROOT = 5;

constant LONGINT-SIZE = 4;

my subset UInt   of Int where -1 < *;
my subset UInt32 of Int where -1 < * < 2**32;

has Str      $.Name       is required;
has UInt     $.Type       is required;
has UInt     $.No         is rw;
has UInt32   $.PrevPps    is rw;
has UInt32   $.NextPps    is rw;
has UInt32   $.DirPps     is rw;
has UInt     $.StartBlock is rw;
has UInt     $.Size       is rw;
has          $.Data       is rw;
has          @.Child      is rw;
has DateTime $.Time1st    is rw;
has DateTime $.Time2nd    is rw;

has Str $._PPS_FILE;

# The old 'new' methods really don't do anything special.

method _DataLen {
  return 0 unless self.Data;
  self._PPS_FILE ??
    self._PPS_FILE.stat()[7] !!
    self.Data.elems;
}

method _makeSmallData( OLE::Storage_Lite::PPS @aList, %hInfo ) {
  my Buf        $sRes;
  my IO::Handle $FILE   = %hInfo<_FILEH_>;
  my Int        $iSmBlk = 0;

  for @aList -> $oPps {
    if $oPps.Type == PPS-TYPE-FILE {
      next if $oPps.Size <= 0;
      if $oPps.Size < %hInfo<_SMALL_SIZE> {
        my Int $iSmbCnt =
	  Int( $oPps.Size / %hInfo<_SMALL_BLOCK_SIZE> ) +
   	     ( ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ?? 1 !! 0 );

	loop ( my Int $i = 0 ; $i < ( $iSmbCnt - 1 ) ; $i++ ) {
          $FILE.write( Blob.new( _int32( $i + $iSmBlk + 1 ) ) );
	}
	$FILE.write( Blob.new( _int32( -2 ) ) );

	if $oPps._PPS_FILE {
	  my Buf $sBuff;
	  $oPps._PPS_FILE.seek( 0, SeekFromBeginning );
	  while $sBuff = $oPps._PPS_FILE.read( 4096 ) {
	    $sRes.append( $sBuff );
	  }
	}
	else {
          $sRes = Buf.new unless $sRes;
          #$sRes.append( $oPps.Data.decode( OLE-ENCODING ).list );
          $sRes.append( $oPps.Data.list );
	}

        if $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> {
	  $sRes.append( 0x00 xx 
	           ( %hInfo<_SMALL_BLOCK_SIZE> -
		     ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) )
          );
	}
	
	$oPps.StartBlock = $iSmBlk;
	$iSmBlk += $iSmbCnt;
      }
    }
  }

  # Adjust for SBD block size
  #
  my Int $iSbCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / LONGINT-SIZE );
  if $iSmBlk % $iSbCnt {
    $FILE.write( Blob.new( flat
      ( _int32( -1 ) ) xx ( $iSbCnt - ( $iSmBlk % $iSbCnt ) )
    ) );
  }

  $sRes;
}

method _savePpsWk( %hInfo ) {
  my IO::Handle $FILE = %hInfo<_FILEH_>;

  my Blob $name = self.Name.encode( OLE-ENCODING );
  $FILE.write( $name );
  $FILE.write(
    Blob.new( flat
      0x00 xx ( 64 - $name.bytes ),                                 # 0..64
      _int16( $name.bytes + 2 ),                                    # 65-66
      self.Type,                                                    # 67
      0x00,                                                         # 68-71
      _int32( self.PrevPps ),                                       # 72-75
      _int32( self.NextPps ),                                       # 76-79
      _int32( self.DirPps ),                                        # 80-83
      0x00, 0x09, 0x02, 0x00,                                       # 84-87
      0x00, 0x00, 0x00, 0x00,                                       # 88-91
      0xc0, 0x00, 0x00, 0x00,                                       # 92-95
      0x00, 0x00, 0x00, 0x46,                                       # 96-99
      0x00, 0x00, 0x00, 0x00,                                       # 100-107
      LocalDateObject2OLE( self.Time1st ).list,                     # 108-115
      LocalDateObject2OLE( self.Time2nd ).list,                     # 116-123
      _int32( defined( self.StartBlock ) ?? self.StartBlock !! 0 ), # 124-127
      _int32( defined( self.Size ) ?? self.Size !! 0 ),             # 128-131
      _int32( 0 )                                                   # 132
    )
  );
}
