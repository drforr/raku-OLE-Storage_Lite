use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::File is OLE::Storage_Lite::PPS;

# Encoding is native Raku here, encoded to UCS2/UTF-16LE when written out

multi method new( Str $Name, $Data ) {
  self.bless(
    :$Name,
    :Type( 2 ),
    :$Data
  );
}
multi method new( Str $Name, @Time1st?, @Time2nd?, @Child? ) {
  self.bless(
    :$Name,
    :Type( 2 ),
    :@Time1st,
    :@Time2nd,
    :@Child
  );
}

method newFile( Str $sNm, Str $sFile? ) {
  my $oSelf = OLE::Storage::Lite::PPS.new(
#    :Name( $sNm.encode('UTF-16LE') ),
    :Name( $sNm ), # Encode/decode at the last possible point
    :Type( 2 ),
    :Data( '' ),
  );
  $oSelf._PPS_FILE = $sFile if $sFile;
  $oSelf;
}

method append( Str $sData ) {
  if self._PPS_FILE {
    self._PPS_FILE.print( $sData );
  }
  else {
    self.Data ~= $sData;
  }
}
