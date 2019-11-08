use v6;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/test.xls';

plan 0;

#use Utils;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

my $ole  = OLE::Storage_Lite.new( FILENAME );
my $pps  = $ole.getPpsTree();
#my $tree = Utils::serialize_pps($pps);
#
#is_deeply $tree, {
#  Type       => 5,
#  No         => 0,
#  Size       => 0,
#  StartBlock => 2**32 - 2,
#  Time1st    => [ 1, 28, 18, 5, 9, -240, 2, 278, 0 ],
#  Time2nd    => [ 31, 58, 21, 28, 1, 101, 3, 58, 0 ],
#  Name       => encode('UTF-16LE', q{Root Entry}),
#  Data       => undef,
#  PrevPps    => 2**32 - 1,
#  NextPps    => 2**32 - 1,
#  DirPps     => 2,
#  Child   => [
#    { Type       => 2,
#      No         => 1,
#      Size       => 4096,
#      StartBlock => 0,
#      Time1st    => [ undef ],
#      Time2nd    => [ undef ],
#      Name       => encode('UTF-16LE', q{Workbook}),
#      Data       => undef,
#      PrevPps    => 2**32 - 1,
#      NextPps    => 2**32 - 1,
#      DirPps     => 2**32 - 1,
#    },
#    { Type       => 2,
#      No         => 2,
#      Size       => 4096,
#      StartBlock => 8,
#      Time1st    => [ undef ],
#      Time2nd    => [ undef ],
#      Name       => encode('UTF-16LE', qq{\x05SummaryInformation} ),
#      Data       => undef,
#      PrevPps    => 1,
#      NextPps    => 3,
#      DirPps     => 2**32 - 1,
#    },
#    { Type       => 2,
#      No         => 3,
#      Size       => 4096,
#      StartBlock => 16,
#      Time1st    => [ undef ],
#      Time2nd    => [ undef ],
#      Name       => encode('UTF-16LE', qq{\x05DocumentSummaryInformation} ),
#      Data       => undef,
#      PrevPps    => 2**32 - 1,
#      NextPps    => 2**32 - 1,
#      DirPps     => 2**32 - 1,
#    }
#  ]
#};
#
#=pod
#
#sub serialize_pps {
#  my ($pps) = @_;
#
#  my $output = { };
#
#  for my $name ( qw( Type Data No Size StartBlock Time1st
#		     Time2nd Name DirPps NextPps PrevPps ) ) {
#    $output->{$name} = $pps->{$name};
#  }
#
#  if ( $pps->{Child} and @{ $pps->{Child} } ) {
#    $output->{Child} = [ ];
#
#    foreach my $item (@{$pps->{Child}}) {
#      my $res = serialize_pps($item);
#      push @{ $output->{Child} }, $res;
#    }
#  }
#
#  return $output;
#}
#
#=cut

done-testing;
