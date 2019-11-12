use v6;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/test.xls';

plan 4;

#use Utils;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

my $ole  = OLE::Storage_Lite.new( FILENAME );
my @pps  = $ole.getPpsTree();
#warn @pps.perl;
#my $tree = Utils::serialize_pps($pps);

subtest 'Root Entry', {
  my $elem = @pps[0];

  is        $elem.No,         0,                                    'No';
  is        $elem.Type,       5,                                    'Type';
  is        $elem.Size,       0,                                    'Size';
  is        $elem.Name,       'Root Entry',                         'Name';
  is-deeply $elem.Time1st,    [ 1, 28, 18, 5, 9, -240, 2, 278, 0 ], 'Time1st';
  is-deeply $elem.Time2nd,    [ 31, 58, 21, 28, 1, 101, 3, 58, 0 ], 'Time2nd';
  is        $elem.PrevPps,    2**32 - 1,                            'PrevPps';
  is        $elem.NextPps,    2**32 - 1,                            'NextPps';
  is        $elem.DirPps,     2,                                    'DirPps';

  is        $elem.StartBlock, 2**32 - 2,  'StartBlock';
}

subtest 'Workbook', {
  my $elem = @pps[0].Child[0];

  is        $elem.No,         1,          'No';
  is        $elem.Data,       Any,        'Data';
  is        $elem.Type,       2,          'Type';
  is        $elem.StartBlock, 0,          'StartBlock';
  is        $elem.Size,       4096,       'Size';
  is        $elem.Name,       'Workbook', 'Name';
  is-deeply $elem.Time1st,    [ Any ],    'Time1st';
  is-deeply $elem.Time2nd,    [ Any ],    'Time2nd';
  is        $elem.PrevPps,    2**32 - 1,  'PrevPps';
  is        $elem.NextPps,    2**32 - 1,  'NextPps';
  is        $elem.DirPps,     2**32 - 1,  'DirPps';
}

subtest 'SummaryInformation', {
  my $elem = @pps[0].Child[1];

  is        $elem.No,         2,                    'No';
  is        $elem.Data,       Any,                  'Data';
  is        $elem.Type,       2,                    'Type';
  is        $elem.StartBlock, 8,                    'StartBlock';
  is        $elem.Size,       4096,                 'Size';
  is        $elem.Name,       'SummaryInformation', 'Name';
  is-deeply $elem.Time1st,    [ Any ],              'Time1st';
  is-deeply $elem.Time2nd,    [ Any ],              'Time2nd';
  is        $elem.PrevPps,    1,                    'PrevPps';
  is        $elem.NextPps,    3,                    'NextPps';
  is        $elem.DirPps,     2**32 - 1,            'DirPps';
}

subtest 'DocumentSummaryInformation', {
  my $elem = @pps[0].Child[2];

  is        $elem.No,         3,                            'No';
  is        $elem.Data,       Any,                          'Data';
  is        $elem.Type,       2,                            'Type';
  is        $elem.StartBlock, 16,                           'StartBlock';
  is        $elem.Size,       4096,                         'Size';
  is        $elem.Name,       'DocumentSummaryInformation', 'Name';
  is-deeply $elem.Time1st,    [ Any ],                      'Time1st';
  is-deeply $elem.Time2nd,    [ Any ],                      'Time2nd';
  is        $elem.PrevPps,    2**32 - 1,                    'PrevPps';
  is        $elem.NextPps,    2**32 - 1,                    'NextPps';
  is        $elem.DirPps,     2**32 - 1,                    'DirPps';
}

#is_deeply $tree, {
#  DirPps     => 2,
#  Child   => [
#      DirPps     => 2**32 - 1,
#    },
#      NextPps    => 3,
#      DirPps     => 2**32 - 1,
#    },
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
