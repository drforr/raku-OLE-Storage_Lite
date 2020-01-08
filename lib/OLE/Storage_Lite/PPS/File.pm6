use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::File is OLE::Storage_Lite::PPS;

# Encoding is native Raku here, encoded to UCS2/UTF-16LE when written out

multi method new( Str $Name, Buf $Data ) {
  self.bless(
    :$Name,
    :Type( 2 ),
    :$Data
  );
}
multi method new( Str $Name, DateTime $time1st?, DateTime $time2nd?, OLE::Storage_Lite::PPS @Child? ) {
  self.bless(
    :$Name,
    :Type( 2 ),
    :$time1st,
    :$time2nd,
    :@Child
  );
}

# Encode $Name to UCS2 at the last possible point.
#
method newFile( Str $Name, Str $sFile? ) {
  my OLE::Storage_Lite::PPS::File $oSelf = OLE::Storage::Lite::PPS::File.new(
    :$Name,
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
