use v6;

use Test;

use OLE::Storage_Lite;

constant SMALL_FILENAME = 'sample/tsv.dat';
constant LARGE_FILENAME = 'sample/test.xls';

plan 2;

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)

# I was going to remove all one-word names, but that would make the tests look
# too much alike. Even if I did that it'd still be easy to go by line number
# to see what's actually being tested. I've done this elsewhere while I'm 
# still testing because it's also easy to copy/paste, like Time1st one name
# over an old name and make them stale.

subtest 'large blocks', {
  plan 5;

  my $ole = OLE::Storage_Lite.new( LARGE_FILENAME );
  my @pps = $ole.getPpsTree;
  
  is @pps.elems, 1, "Single root object";
  
  subtest 'Root Entry', {
    plan 13;
  
    my $node = @pps[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::Root;
  
    is $node.Child.elems, 3,                      'Child count';
    is $node.No,          0,                      'No';
    is $node.Type,        5,                      'Type';
    is $node.Size,        0,                      'Size';
    is $node.Name,        'Root Entry',           'Name';
    is $node.Data,        Any,                    'Data';
    is $node.StartBlock,  2**32 - 2,              'StartBlock';
    is $node.PrevPps,     2**32 - 1,              'PrevPps';
    is $node.NextPps,     2**32 - 1,              'NextPps';
    is $node.DirPps,      2,                      'DirPps';
    is $node.Time1st,     '1660-10-05T18:28:02Z', 'Time1st';
    is $node.Time2nd,     '2001-02-28T21:58:31Z', 'Time2nd';
  };
  
  subtest 'Workbook', {
    plan 13;
  
    my $node = @pps[0].Child[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,          'Child count';
    is $node.No,          1,          'No';
    is $node.Type,        2,          'Type';
    is $node.Size,        4096,       'Size';
    is $node.Name,        'Workbook', 'Name';
    is $node.Data,        Any,        'Data';
    is $node.StartBlock,  0,          'StartBlock';
    is $node.PrevPps,     2**32 - 1,  'PrevPps';
    is $node.NextPps,     2**32 - 1,  'NextPps';
    is $node.DirPps,      2**32 - 1,  'DirPps';
    is $node.Time1st,     DateTime,   'Time1st';
    is $node.Time2nd,     DateTime,   'Time2nd';
  };
  
  subtest 'SummaryInformation', {
    plan 13;
  
    my $node = @pps[0].Child[1];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,                            'Child count';
    is $node.No,          2,                            'No';
    is $node.Type,        2,                            'Type';
    is $node.Size,        4096,                         'Size';
    is $node.Name,        qq{\x[05]SummaryInformation}, 'Name';
    is $node.Data,        Any,                          'Data';
    is $node.StartBlock,  8,                            'StartBlock';
    is $node.PrevPps,     1,                            'PrevPps';
    is $node.NextPps,     3,                            'NextPps';
    is $node.DirPps,      2**32 - 1,                    'DirPps';
    is $node.Time1st,     DateTime,                     'Time1st';
    is $node.Time2nd,     DateTime,                     'Time2nd';
  };
  
  subtest 'DocumentSummaryInformation', {
    plan 13;
  
    my $node = @pps[0].Child[2];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,                                    'Child count';
    is $node.No,          3,                                    'No';
    is $node.Type,        2,                                    'Type';
    is $node.Size,        2**12,                                'Size';
    is $node.Name,        qq{\x[05]DocumentSummaryInformation}, 'Name';
    is $node.Data,        Any,                                  'Data';
    is $node.StartBlock,  16,                                   'StartBlock';
    is $node.PrevPps,     2**32 - 1,                            'PrevPps';
    is $node.NextPps,     2**32 - 1,                            'NextPps';
    is $node.DirPps,      2**32 - 1,                            'DirPps';
    is $node.Time1st,     DateTime,                             'Time1st';
    is $node.Time2nd,     DateTime,                             'Time2nd';
  
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
  
    my $node = @pps[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::Root;
  
    is $node.Child.elems, 2,                      'Child count';
    is $node.No,          0,                      'No';
    is $node.Type,        5,                      'Type';
    is $node.Size,        576,                    'Size';
    is $node.Name,        'Root Entry',           'Name';
    is $node.Data,        Any,                    'Data';
    is $node.StartBlock,  1,                      'StartBlock';
    is $node.PrevPps,     2**32 - 1,              'PrevPps';
    is $node.NextPps,     2**32 - 1,              'NextPps';
    is $node.DirPps,      1,                      'DirPps';
    is $node.Time1st,     '2070-01-01T00:00:00Z', 'Time1st';
    is $node.Time2nd,     '2070-01-01T00:00:00Z', 'Time2nd';

    done-testing;
  };

  subtest 'Workbook', {
    plan 13;
  
    my $node = @pps[0].Child[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,          'Child count';
    is $node.No,          2,          'No';
    is $node.Type,        2,          'Type';
    is $node.Size,        6,          'Size';
    is $node.Name,        'Workbook', 'Name';
    is $node.Data,        Any,        'Data';
    is $node.StartBlock,  0,          'StartBlock';
    is $node.PrevPps,     2**32 - 1,  'PrevPps';
    is $node.NextPps,     2**32 - 1,  'NextPps';
    is $node.DirPps,      2**32 - 1,  'DirPps';
    is $node.Time1st,     DateTime,   'Time1st';
    is $node.Time2nd,     DateTime,   'Time2nd';

    done-testing;
  };

  subtest 'Dir', {
    plan 13;
  
    my $node = @pps[0].Child[1];
  
    isa-ok $node, OLE::Storage_Lite::PPS::Dir;
  
    is $node.Child.elems, 3,                      'Child count';
    is $node.No,          1,                      'No';
    is $node.Type,        1,                      'Type';
    is $node.Size,        0,                      'Size';
    is $node.Name,        'Dir',                  'Name';
    is $node.Data,        Any,                    'Data';
    is $node.StartBlock,  0,                      'StartBlock';
    is $node.PrevPps,     2,                      'PrevPps';
    is $node.NextPps,     2**32 - 1,              'NextPps';
    is $node.DirPps,      3,                      'DirPps';
    is $node.Time1st,     '2070-01-01T00:00:00Z', 'Time1st';
    is $node.Time2nd,     '2070-01-01T00:00:00Z', 'Time2nd';

    done-testing;
  };

  subtest 'File_2', {
    plan 13;
  
    my $node = @pps[0].Child[1].Child[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,         'Child count';
    is $node.No,          4,         'No';
    is $node.Type,        2,         'Type';
    is $node.Size,        2**12,     'Size';
    is $node.Name,        'File_2',  'Name';
    is $node.Data,        Any,       'Data';
    is $node.StartBlock,  3,         'StartBlock';
    is $node.PrevPps,     2**32 - 1, 'PrevPps';
    is $node.NextPps,     2**32 - 1, 'NextPps';
    is $node.DirPps,      2**32 - 1, 'DirPps';
    is $node.Time1st,     DateTime,  'Time1st';
    is $node.Time2nd,     DateTime,  'Time2nd';

    done-testing;
  };

  subtest 'File_3', {
    plan 13;
  
    my $node = @pps[0].Child[1].Child[1];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,         'Child count';
    is $node.No,          3,         'No';
    is $node.Type,        2,         'Type';
    is $node.Size,        2**8,      'Size';
    is $node.Name,        'File_3',  'Name';
    is $node.Data,        Any,       'Data';
    is $node.StartBlock,  1,         'StartBlock';
    is $node.PrevPps,     4,         'PrevPps';
    is $node.NextPps,     5,         'NextPps';
    is $node.DirPps,      2**32 - 1, 'DirPps';
    is $node.Time1st,     DateTime,  'Time1st';
    is $node.Time2nd,     DateTime,  'Time2nd';

    done-testing;
  };

  subtest 'File_4', {
    plan 13;
  
    my $node = @pps[0].Child[1].Child[2];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is $node.Child.elems, 0,         'Child count';
    is $node.No,          5,         'No';
    is $node.Type,        2,         'Type';
    is $node.Size,        2**8,      'Size';
    is $node.Name,        'File_4',  'Name';
    is $node.Data,        Any,       'Data';
    is $node.StartBlock,  5,         'StartBlock';
    is $node.PrevPps,     2**32 - 1, 'PrevPps';
    is $node.NextPps,     2**32 - 1, 'NextPps';
    is $node.DirPps,      2**32 - 1, 'DirPps';
    is $node.Time1st,     DateTime,  'Time1st';
    is $node.Time2nd,     DateTime,  'Time2nd';

    done-testing;
  };

  done-testing;
};

done-testing;
