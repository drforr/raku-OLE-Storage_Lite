use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::File is OLE::Storage_Lite::PPS;

method newFile( $sNm, $sFile? ) {
  my $oSelf = OLE::Storage::Lite::PPS.new(
    :Name( $sNm ),
    :Type( 2 ),
    :Data( '' ),
  );
  $oSelf._PPS_FILE = $sFile if $sFile;
  $oSelf;
}

method append( Str $sData ) {
  if self._PPS_FILE {
    self._PPS_FILE.print: $sData;
  }
  else {
    self.Data ~= $sData;
  }
}
