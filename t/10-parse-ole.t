use v6;

use Test;

use OLE::Storage_Lite;

constant SMALL_FILENAME = 'sample/tsv.dat';
constant LARGE_FILENAME = 'sample/test.xls';

plan 2;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

subtest 'large blocks', {
  plan 5;

  my $ole = OLE::Storage_Lite.new( LARGE_FILENAME );
  my @pps = $ole.getPpsTree;
  
  is @pps.elems, 1, "Single root object";
  
  subtest 'Root Entry', {
    plan 13;
  
    my $elem = @pps[0];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::Root;
  
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
    plan 13;
  
    my $elem = @pps[0].Child[0];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          1,          'No';
    is        $elem.Type,        2,          'Type';
    is        $elem.Size,        4096,       'Size';
    is        $elem.Name,        'Workbook', 'Name';
    is        $elem.Data,        Any,        'Data';
    is        $elem.StartBlock,  0,          'StartBlock';
    is        $elem.PrevPps,     2**32 - 1,  'PrevPps';
    is        $elem.NextPps,     2**32 - 1,  'NextPps';
    is        $elem.DirPps,      2**32 - 1,  'DirPps';
    is-deeply $elem.Time1st,     [ Int ],    'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],    'Time2nd';
    is-deeply $elem.Child,       [ ],        'Child';
  };
  
  subtest 'SummaryInformation', {
    plan 13;
  
    my $elem = @pps[0].Child[1];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,         2,          'No';
    is        $elem.Type,       2,          'Type';
    is        $elem.Size,       4096,       'Size';
    is        $elem.Name,
              qq{\x[05]SummaryInformation}, 'Name';
    is        $elem.Data,       Any,        'Data';
    is        $elem.StartBlock, 8,          'StartBlock';
    is        $elem.PrevPps,    1,          'PrevPps';
    is        $elem.NextPps,    3,          'NextPps';
    is        $elem.DirPps,     2**32 - 1,  'DirPps';
    is-deeply $elem.Time1st,    [ Int ],    'Time1st';
    is-deeply $elem.Time2nd,    [ Int ],    'Time2nd';
    is-deeply $elem.Child,      [ ],        'Time2nd';
  };
  
  subtest 'DocumentSummaryInformation', {
    plan 13;
  
    my $elem = @pps[0].Child[2];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          3,                 'No';
    is        $elem.Type,        2,                 'Type';
    is        $elem.Size,        4096,              'Size';
    is        $elem.Name,
              qq{\x[05]DocumentSummaryInformation}, 'Name';
    is        $elem.Data,        Any,               'Data';
    is        $elem.StartBlock,  16,                'StartBlock';
    is        $elem.PrevPps,     2**32 - 1,         'PrevPps';
    is        $elem.NextPps,     2**32 - 1,         'NextPps';
    is        $elem.DirPps,      2**32 - 1,         'DirPps';
    is-deeply $elem.Time1st,     [ Int ],           'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],           'Time2nd';
    is-deeply $elem.Child,       [ ],               'Child';
  
    done-testing;
  };

  done-testing;
};

subtest 'small blocks', {
  plan 7;

  my $ole = OLE::Storage_Lite.new( SMALL_FILENAME );
  my @pps = $ole.getPpsTree;

  is @pps.elems, 1, "Single root object";
  
  subtest 'Root Entry', {
    plan 13;
  
    my $elem = @pps[0];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::Root;
  
    is        $elem.No,          0,                        'No';
    is        $elem.Type,        5,                        'Type';
    is        $elem.Size,        576,                      'Size';
    is        $elem.Name,        'Root Entry',             'Name';
    is-deeply $elem.Time1st,     [ 0, 0, 0, 1, 0, -299 ],  'Time1st';
    is-deeply $elem.Time2nd,     [ 0, 0, 16, 4, 10, 100 ], 'Time2nd';
    is        $elem.Data,        Any,                      'Data';
    is        $elem.StartBlock,  1,                        'StartBlock';
    is        $elem.PrevPps,     2**32 - 1,                'PrevPps';
    is        $elem.NextPps,     2**32 - 1,                'NextPps';
    is        $elem.DirPps,      1,                        'DirPps';
    is        $elem.Child.elems, 2,                        'Child';

    done-testing;
  };

  subtest 'Workbook', {
    plan 13;
  
    my $elem = @pps[0].Child[0];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          2,          'No';
    is        $elem.Type,        2,          'Type';
    is        $elem.Size,        6,          'Size';
    is        $elem.Name,        'Workbook', 'Name';
    is-deeply $elem.Time1st,     [ Int ],    'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],    'Time2nd';
    is        $elem.Data,        Any,        'Data';
    is        $elem.StartBlock,  0,          'StartBlock';
    is        $elem.PrevPps,     2**32 - 1,  'PrevPps';
    is        $elem.NextPps,     2**32 - 1,  'NextPps';
    is        $elem.DirPps,      2**32 - 1,  'DirPps';
    is        $elem.Child.elems, 0,          'Child';

    done-testing;
  };

  subtest 'Dir', {
    plan 13;
  
    my $elem = @pps[0].Child[1];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::Dir;
  
    is        $elem.No,          1,                          'No';
    is        $elem.Type,        1,                          'Type';
    is        $elem.Size,        0,                          'Size';
    is        $elem.Name,        'Dir',                      'Name';
    is-deeply $elem.Time1st,     [ 19, 57, 4, 23, 10, 119 ], 'Time1st';
    is-deeply $elem.Time2nd,     [ 19, 57, 4, 23, 10, 119 ], 'Time2nd';
    is        $elem.Data,        Any,                        'Data';
    is        $elem.StartBlock,  0,                          'StartBlock';
    is        $elem.PrevPps,     2,                          'PrevPps';
    is        $elem.NextPps,     2**32 - 1,                  'NextPps';
    is        $elem.DirPps,      3,                          'DirPps';
    is        $elem.Child.elems, 3,                          'Child';

    done-testing;
  };

  subtest 'File_2', {
    plan 13;
  
    my $elem = @pps[0].Child[1].Child[0];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          4,         'No';
    is        $elem.Type,        2,         'Type';
    is        $elem.Size,        4096,      'Size';
    is        $elem.Name,        'File_2',  'Name';
    is-deeply $elem.Time1st,     [ Int ],   'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],   'Time2nd';
    is        $elem.Data,        Any,       'Data';
    is        $elem.StartBlock,  3,         'StartBlock';
    is        $elem.PrevPps,     2**32 - 1, 'PrevPps';
    is        $elem.NextPps,     2**32 - 1, 'NextPps';
    is        $elem.DirPps,      2**32 - 1, 'DirPps';
    is        $elem.Child.elems, 0,         'Child';

    done-testing;
  };

  subtest 'File_3', {
    plan 13;
  
    my $elem = @pps[0].Child[1].Child[1];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          3,         'No';
    is        $elem.Type,        2,         'Type';
    is        $elem.Size,        256,       'Size';
    is        $elem.Name,        'File_3',  'Name';
    is-deeply $elem.Time1st,     [ Int ],   'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],   'Time2nd';
    is        $elem.Data,        Any,       'Data';
    is        $elem.StartBlock,  1,         'StartBlock';
    is        $elem.PrevPps,     4,         'PrevPps';
    is        $elem.NextPps,     5,         'NextPps';
    is        $elem.DirPps,      2**32 - 1, 'DirPps';
    is        $elem.Child.elems, 0,         'Child';

    done-testing;
  };

  subtest 'File_4', {
    plan 13;
  
    my $elem = @pps[0].Child[1].Child[2];
  
    isa-ok $elem, OLE::Storage_Lite::PPS::File;
  
    is        $elem.No,          5,         'No';
    is        $elem.Type,        2,         'Type';
    is        $elem.Size,        256,       'Size';
    is        $elem.Name,        'File_4',  'Name';
    is-deeply $elem.Time1st,     [ Int ],   'Time1st';
    is-deeply $elem.Time2nd,     [ Int ],   'Time2nd';
    is        $elem.Data,        Any,       'Data';
    is        $elem.StartBlock,  5,         'StartBlock';
    is        $elem.PrevPps,     2**32 - 1, 'PrevPps';
    is        $elem.NextPps,     2**32 - 1, 'NextPps';
    is        $elem.DirPps,      2**32 - 1, 'DirPps';
    is        $elem.Child.elems, 0,         'Child';

    done-testing;
  };

  done-testing;
};

done-testing;
