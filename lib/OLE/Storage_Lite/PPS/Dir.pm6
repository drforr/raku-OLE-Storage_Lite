use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::Dir is OLE::Storage_Lite::PPS;

multi method new( Str $Name, $time1st, $time2nd, @Child ) {
  self.bless(
    :$Name,
    :Type( 1 ),
    :$time1st,
    :$time2nd,
    :@Child
  )
}
