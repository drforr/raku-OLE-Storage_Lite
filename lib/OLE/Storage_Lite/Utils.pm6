use v6;

unit class OLE::Storage_Lite::Utils;

use experimental :pack;
use P5localtime;

sub _int8( Int $v ) is export {
       $v +& 0xff
}

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
        append( @bytes,
	          @args[ $arg-index ] +& 0xff
	  ) for ^$count;
	$arg-index++;
      }
      when 'v' {
        append( @bytes,
   	          @args[ $arg-index ]      +& 0xff,
	          @args[ $arg-index ] +> 8 +& 0xff
	  ) for ^$count;
	$arg-index++;
      }
      when 'V' {
        append( @bytes,
                  @args[ $arg-index ]       +& 0xff,
	          @args[ $arg-index ] +> 8  +& 0xff,
	          @args[ $arg-index ] +> 16 +& 0xff,
	          @args[ $arg-index ] +> 24 +& 0xff
	  ) for ^$count;
	$arg-index++;
      }
    }
  }
  @bytes;
}

#------------------------------------------------------------------------------
# OLEDate2Local()
#
# Convert from a Windows FILETIME structure to a localtime array. FILETIME is
# a 64-bit value representing the number of 100-nanosecond intervals since
# January 1 1601.
#
# We first convert the FILETIME to seconds and then subtract the difference
# between the 1601 epoch and the 1970 Unix epoch.
#
sub OLEDate2Local( Buf $oletime ) is export {

  # Unpack FILETIME into high and low longs
  #
  my ( $lo, $hi ) = $oletime.unpack( "V2" );

  # Convert the longs to a double
  #
  my $nanoseconds = $hi * 2**32 + $lo;

  # Convert the 100ns units to seconds
  #
  my $time = $nanoseconds / 1e7;

  # Subtract the number of seconds between the 1601 and 1970 epocs
  #
  $time -= 11644473600;

  my @localtime = gmtime( $time );

  @localtime;
}

#------------------------------------------------------------------------------
# LocalDate2OLE()
#
# Convert from a a localtime array to a Window FILETIME structure. FILETIME is
# a 64-bit value representing the number of 100-nanosecond intervals since
# January 1 1601.
#
# We first convert the localtime (actually gmtime) to seconds and then add the
# difference between the 1601 epoch and the 1970 Unix epoch. We convert that to
# 100 nanosecond units, divide it into high and low longs and return it as a
# packed 64bit structure.
#
sub LocalDate2OLE( @localtime? ) is export {

  return 0x00 x 8 unless @localtime;

# Perl 5 spec worked like this:
#
# Jan is 0
# my $time = timegm( $sec, $min, $hour, $mday, $mon, $year );
#                    0     1     2      3      4     5

  my $dt = DateTime.new(
    year    => @localtime[5] + 1900,
    month   => @localtime[4] + 1,
    day     => @localtime[3],
    hour    => @localtime[2],
    minute  => @localtime[1],
    second  => @localtime[0]
  );
  
  # Convert from localtime (actually gmtime) to seconds.
  my $time = $dt.posix( :ignore-timezone( True ) );

  # Add the number of seconds between the 1601 and 1970 epochs.
  $time += 11644473600;
  
  # The FILETIME seconds are in units of 100 nanoseconds.
  my $nanoseconds = $time * 1E7;

  # Pack the total nanoseconds into 64 bits...
  #
  my Int $hi = $nanoseconds +> 32 +& ( 2**32 - 1 );
  my Int $lo = $nanoseconds +& ( 2**32 - 1 );

  return Buf.new( _int32( $lo ), _int32( $hi ) );
}
