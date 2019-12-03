use v6;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/test.xls';

plan 5;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

my $ole = OLE::Storage_Lite.new( FILENAME );
my @pps = $ole.getPpsTree();

is @pps.elems, 1, "Single root object";

# Note that Time1st and Time2nd use Raku's gmtime, which might be slightly
# different than Perl 5's.
#
# Also, 'Type' is redundant, we have that information in the object name.

subtest 'Root Entry', {
  my $elem = @pps[0];

  plan 13;

  isa-ok $elem, 'OLE::Storage_Lite::PPS::Root';

  is        $elem.No,          0,                          'No';
  is        $elem.Type,        5,                          'Type';
  is        $elem.Size,        0,                          'Size';
  is        $elem.Name,        'Root Entry',               'Name';
  is-deeply $elem.Time1st,     [ 2, 28, 18, 5, 9, -240 ],  'Time1st';
  is-deeply $elem.Time2nd,     [ 31, 58, 21, 28, 1, 101 ], 'Time2nd';
  is        $elem.Data,        Any,                        'Data';
  is        $elem.StartBlock,  2**32 - 2,                  'StartBlock';
  is        $elem.PrevPps,     2**32 - 1,                  'PrevPps';
  is        $elem.NextPps,     2**32 - 1,                  'NextPps';
  is        $elem.DirPps,      2,                          'DirPps';
  is        $elem.Child.elems, 3,                          'Child';
};

subtest 'Workbook', {
  my $elem = @pps[0].Child[0];

  plan 13;

  isa-ok $elem, 'OLE::Storage_Lite::PPS::File';

  is        $elem.No,          1,          'No';
  is        $elem.Type,        2,          'Type';
  is        $elem.Size,        4096,       'Size';
  is        $elem.Name,        'Workbook', 'Name';
  is-deeply $elem.Time1st,     [ Any ],    'Time1st';
  is-deeply $elem.Time2nd,     [ Any ],    'Time2nd';
  is        $elem.Data,        Any,        'Data';
  is        $elem.StartBlock,  0,          'StartBlock';
  is        $elem.PrevPps,     2**32 - 1,  'PrevPps';
  is        $elem.NextPps,     2**32 - 1,  'NextPps';
  is        $elem.DirPps,      2**32 - 1,  'DirPps';
  is        $elem.Child.elems, 0,          'Child';
};

subtest 'SummaryInformation', {
  my $elem = @pps[0].Child[1];

  plan 13;

  isa-ok $elem, 'OLE::Storage_Lite::PPS::File';

  is        $elem.No,         2,          'No';
  is        $elem.Type,       2,          'Type';
  is        $elem.Size,       4096,       'Size';
  is        $elem.Name,
            qq{\x[05]SummaryInformation}, 'Name';
  is-deeply $elem.Time1st,    [ Any ],    'Time1st';
  is-deeply $elem.Time2nd,    [ Any ],    'Time2nd';
  is        $elem.Data,       Any,        'Data';
  is        $elem.StartBlock, 8,          'StartBlock';
  is        $elem.PrevPps,    1,          'PrevPps';
  is        $elem.NextPps,    3,          'NextPps';
  is        $elem.DirPps,     2**32 - 1,  'DirPps';

  is        $elem.Child.elems, 0, 'Child';
};

subtest 'DocumentSummaryInformation', {
  my $elem = @pps[0].Child[2];

  plan 13;

  isa-ok $elem, 'OLE::Storage_Lite::PPS::File';

  is        $elem.No,          3,                 'No';
  is        $elem.Type,        2,                 'Type';
  is        $elem.Size,	       4096,              'Size';
  is        $elem.Name,
            qq{\x[05]DocumentSummaryInformation}, 'Name';
  is-deeply $elem.Time1st,     [ Any ],           'Time1st';
  is-deeply $elem.Time2nd,     [ Any ],           'Time2nd';
  is        $elem.Data,        Any,               'Data';
  is        $elem.StartBlock,  16,                'StartBlock';
  is        $elem.PrevPps,     2**32 - 1,         'PrevPps';
  is        $elem.NextPps,     2**32 - 1,         'NextPps';
  is        $elem.DirPps,      2**32 - 1,         'DirPps';
  is        $elem.Child.elems, 0,                 'Child';

  done-testing;
};

done-testing;
