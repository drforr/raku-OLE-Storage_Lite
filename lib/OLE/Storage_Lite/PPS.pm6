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

# $.Type is gone, because it's intimately tied to the subclass name(s). Instead,
# when an instance of PPS:: is created, it's given a default Type at creation.
#
# This way we don't ever have to manually set it.

has Str $.Name       is required; # Gotten from Buffers, decoded to UTF-8...
has Int $.Type       is required;
has Int $.No         is rw;
has Int $.PrevPps    is rw;
has Int $.NextPps    is rw;
has Int $.DirPps     is rw;
has     @.Time1st    is rw;
has     @.Time2nd    is rw;
has Int $.StartBlock is rw;
has Int $.Size       is rw;
has     $.Data       is rw;
has     @.Child      is rw;

has Str $._PPS_FILE;

# The old 'new' methods really don't do anything special.

method _DataLen {
  return 0 unless self.Data;
  self._PPS_FILE ??
    self._PPS_FILE.stat()[7] !!
    self.Data.chars;
}

method _makeSmallData( @aList, %hInfo ) {
  my Str        $sRes;
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
	    $sRes ~= $sBuff;
	  }
	}
	else {
	  $sRes ~= $oPps.Data;
	}

	$sRes ~= ( "\x00" x
	           ( %hInfo<_SMALL_BLOCK_SIZE> -
		     ( $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE> ) ) ) if
	  $oPps.Size % %hInfo<_SMALL_BLOCK_SIZE>;
	
	$oPps.StartBlock = $iSmBlk;
	$iSmBlk += $iSmbCnt;
      }
    }
  }

  # Adjust for SBD block size
  #
  my Int $iSbCnt = Int( %hInfo<_BIG_BLOCK_SIZE> / 4 ); # LONG-INT-SIZE
  $FILE.write( Blob.new( flat
    ( _int32( -1 ) ) xx ( $iSbCnt - ( $iSmBlk % $iSbCnt ) )
  ) ) if $iSmBlk % $iSbCnt;

  $sRes;
}

method _savePpsWk( %hInfo ) {

  my $name = self.Name.encode( OLE-ENCODING );
  %hInfo<_FILEH_>.write( $name );
  %hInfo<_FILEH_>.write(
    Blob.new( flat
      0x00 xx ( 64 - $name.bytes ),  # 0..64
      _int16( $name.bytes + 2 ),     # 65
      _int8( self.Type ),            # 67
      _int8( 0 ),                    # 68
      _int32( self.PrevPps ),        # 72
#      _int32( self.NextPps ),        # 76
#      _int32( self.DirPps ),         # 80
#      0x00, 0x09, 0x02, 0x00,        # 84
#      0x00, 0x00, 0x00, 0x00,        # 88
#      0xc0, 0x00, 0x00, 0x00,        # 92
#      0x00, 0x00, 0x00, 0x46,        # 96
#      0x00, 0x00, 0x00, 0x00,        # 100
#      LocalDate2OLE( self.Time1st ), # 108
#      LocalDate2OLE( self.Time2nd ), # 116
    )
  );

#  print {$FILE} (
#            , pack("V", defined($oThis->{StartBlock})?
#                      $oThis->{StartBlock}:0)       #116
#            , pack("V", defined($oThis->{Size})?
#                 $oThis->{Size} : 0)            #124
#            , pack("V", 0),                  #128
#        );

exit 0;
}
