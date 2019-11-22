use v6;

unit class OLE::Storage_Lite::Utils;

sub _int16( Int $v ) is export {
       $v +& 0xff,
  $v +> 8 +& 0xff
}

sub _int32( Int $v ) is export {
        $v +& 0xff,
  $v +> 8  +& 0xff,
  $v +> 16 +& 0xff,
  $v +> 24 +& 0xff
}

my grammar Unpack {
  rule TOP { <term>* }

  token term { <format> <count>? }

  token format { <[ C v V ]> }
  token count { \d+ }
}

sub _unpack( Str $format, *@args ) is export {
  my $f = Unpack.parse( $format );
  my uint8 @bytes;

  my $arg-index = 0;
  for $f.<term> -> $term {
    my $count = $term.<count> // 1;
    given $term.<format> {
      when 'C' {
        append( @bytes, @args[ $arg-index++ ] +& 0xff ) for ^$count;
      }
      when 'v' {
        append( @bytes,
   	          @args[ $arg-index++ ]      +& 0xff,
	          @args[ $arg-index++ ] +> 8 +& 0xff
	  ) for ^$count;
      }
      when 'V' {
        append( @bytes,
                  @args[ $arg-index++ ]       +& 0xff,
	          @args[ $arg-index++ ] +> 8  +& 0xff,
	          @args[ $arg-index++ ] +> 16 +& 0xff,
	          @args[ $arg-index++ ] +> 24 +& 0xff
	  ) for ^$count;
      }
    }
  }
  @bytes;
}
