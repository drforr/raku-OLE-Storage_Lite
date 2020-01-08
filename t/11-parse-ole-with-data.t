use v6;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/test.xls';

plan 5;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

# This time, actually load the data. That's what the 1 is in pps-tree...
# Should make that an optional flag in the full Raku version.
#
my $ole = OLE::Storage_Lite.new( FILENAME );
my @pps = $ole.pps-tree( 1 ); 

is @pps.elems, 1, "Single root object";

# Note that Time1st and Time2nd use Raku's gmtime, which might be slightly
# different than Perl 5's.
#
# Also, 'Type' is redundant, we have that information in the object name.
#
# I want to fix that later on for the final Raku API.

subtest 'Root Entry', {
  plan 13;

  my $node = @pps[0];

  isa-ok    $node,             OLE::Storage_Lite::PPS::Root;

  is $node.Child.elems, 3,                      'Child';
  is $node.No,          0,                      'No';
  is $node.Type,        5,                      'Type';
  is $node.Size,        0,                      'Size';
  is $node.Name,        'Root Entry',           'Name';
  is $node.Data,        '',                     'Data';
  is $node.StartBlock,  2**32 - 2,              'StartBlock';
  is $node.PrevPps,     2**32 - 1,              'PrevPps';
  is $node.NextPps,     2**32 - 1,              'NextPps';
  is $node.DirPps,      2,                      'DirPps';
  is $node.Time1st,     '1660-10-05T18:28:02Z', 'Time1st';
  is $node.Time2nd,     '2001-02-28T21:58:31Z', 'Time2nd';

  done-testing;
};

subtest 'Workbook', {
  plan 13;

  my $node = @pps[0].Child[0];

  isa-ok    $node,             OLE::Storage_Lite::PPS::File;

  is $node.Child.elems, 0,          'Child count';
  is $node.No,          1,          'No';
  is $node.Type,        2,          'Type';
  is $node.Size,        2**12,      'Size';
  is $node.Name,        'Workbook', 'Name';
  is $node.StartBlock,  0,          'StartBlock';
  is $node.PrevPps,     2**32 - 1,  'PrevPps';
  is $node.NextPps,     2**32 - 1,  'NextPps';
  is $node.DirPps,      2**32 - 1,  'DirPps';
  is $node.Data.[0],    9,          'Data';
  is $node.Time1st,     DateTime,   'Time1st';
  is $node.Time2nd,     DateTime,   'Time2nd';

  done-testing;
};

subtest 'SummaryInformation', {
  plan 13;

  my $node = @pps[0].Child[1];

  isa-ok    $node,             OLE::Storage_Lite::PPS::File;

  is $node.Child.elems, 0,                            'Child count';
  is $node.No,          2,                            'No';
  is $node.Type,        2,                            'Type';
  is $node.Size,        2**12,                        'Size';
  is $node.Name,        qq{\x[05]SummaryInformation}, 'Name';
  is $node.StartBlock,  8,                            'StartBlock';
  is $node.PrevPps,     1,                            'PrevPps';
  is $node.NextPps,     3,                            'NextPps';
  is $node.DirPps,      2**32 - 1,                    'DirPps';
  is $node.Data.[31],   242,                          'Data';
  is $node.Time1st,     DateTime,                     'Time1st';
  is $node.Time2nd,     DateTime,                     'Time2nd';

  done-testing;
};

subtest 'DocumentSummaryInformation', {
  plan 13;

  my $node = @pps[0].Child[2];

  isa-ok    $node,             OLE::Storage_Lite::PPS::File;

  is $node.Child.elems, 0,                                    'Child count';
  is $node.No,          3,                                    'No';
  is $node.Type,        2,                                    'Type';
  is $node.Size,	2**12,                                'Size';
  is $node.Name,        qq{\x[05]DocumentSummaryInformation}, 'Name';
  is $node.StartBlock,  16,                                   'StartBlock';
  is $node.PrevPps,     2**32 - 1,                            'PrevPps';
  is $node.NextPps,     2**32 - 1,                            'NextPps';
  is $node.DirPps,      2**32 - 1,                            'DirPps';
  is $node.Data.[31],   213,                                  'Data';
  is $node.Time1st,     DateTime,                             'Time1st';
  is $node.Time2nd,     DateTime,                             'Time2nd';

  done-testing;
};

done-testing;
