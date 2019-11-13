use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::Dir is OLE::Storage_Lite::PPS;

multi method new( Str $Name, @Time1st, @Time2nd, @Child ) {
  self.bless(
    :$Name,
    :@Time1st,
    :@Time2nd,
    :@Child
  )
}
