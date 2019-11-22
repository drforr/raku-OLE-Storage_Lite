use v6;

unit class OLE::Storage_Lite::Utils;

sub _int16( Int $v ) is export {
  $v +& 0xff, $v +> 8 +& 0xff
}

sub _int32( Int $v ) is export {
        $v +& 0xff,
  $v +> 8  +& 0xff,
  $v +> 16 +& 0xff,
  $v +> 24 +& 0xff
}
