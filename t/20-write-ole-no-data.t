use v6.c;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/raku-test-no-data.xls';

subtest 'before writing', {
  my $workbook =
    OLE::Storage_Lite::PPS::File.new( "Workbook" );

  my $summary-information =
    OLE::Storage_Lite::PPS::File.new( "\x05SummaryInformation" );

  my $document-summary-information =
    OLE::Storage_Lite::PPS::File.new( "\x[05]DocumentSummaryInformation" );

  my $root = OLE::Storage_Lite::PPS::Root.new(
    ( 1, 28, 18, 5, 9, -240, 2, 278, 0 ),
    ( 31, 58, 21, 28, 1, 101, 3, 58, 0 ),
    ( $workbook, $summary-information, $document-summary-information )
  );
  $root.save( FILENAME );

  subtest 'workbook', {
    my $node = $workbook;
    plan 6;
 
    isa-ok $node, 'OLE::Storage_Lite::PPS::File';
 
    is        $node.Child.elems, 0,          'Child count';
    is        $node.Name,        'Workbook', 'Name';
    is-deeply $node.Time1st,     [],         'Time1st';
    is-deeply $node.Time2nd,     [],         'Time2nd';
    is        $node.Type,        2,          'Type';
 
    done-testing;
  };

  subtest 'summary information', {
    my $node = $summary-information;
    plan 6;
 
    isa-ok $node, 'OLE::Storage_Lite::PPS::File';
 
    is        $node.Child.elems, 0,     'Child count';
    is        $node.Name,
              "\x05SummaryInformation", 'Name';
    is-deeply $node.Time1st,     [],    'Time1st';
    is-deeply $node.Time2nd,     [],    'Time2nd';
    is        $node.Type,        2,     'Type';
 
    done-testing;
  };

  subtest 'document summary information', {
    my $node = $document-summary-information;
    plan 6;
 
    isa-ok $node, 'OLE::Storage_Lite::PPS::File';
 
    is        $node.Child.elems, 0,               'Child count';
    is        $node.Name,
              "\x[05]DocumentSummaryInformation", 'Name';
    is-deeply $node.Time1st,     [],              'Time1st';
    is-deeply $node.Time2nd,     [],              'Time2nd';
    is        $node.Type,        2,               'Type';
 
    done-testing;
  };

  subtest 'root', {
    my $node = $root;
    plan 6;
 
    isa-ok $node, 'OLE::Storage_Lite::PPS::Root';
 
    is        $node.Child.elems, 3,                 'Child count';
    is        $node.Name,        'Root Entry',      'Name';
    is-deeply $node.Time1st,
              [ 1, 28, 18, 5, 9, -240, 2, 278, 0 ], 'Time1st';
    is-deeply $node.Time2nd,
              [ 31, 58, 21, 28, 1, 101, 3, 58, 0 ], 'Time2nd';
    is        $node.Type,        5,                 'Type';
 
    done-testing;
  };
};

subtest 'after writing', {
  my $ole      = OLE::Storage_Lite.new( FILENAME );
  my $new-root = $ole.getPpsTree;

	#`{
  subtest 'summary information', {
    my $node = $new-root.[0].Child.[0];

    plan 14;

    isa-ok $node, 'OLE::Storage_Lite::PPS::File';

    is        $node.Child.elems, 0,          'Child count';
    is        $node.Data[0],     0xfe,       'Data 0';
    is        $node.Data[1],     0xff,       'Data 1';
    is        $node.DirPps,      0xffffffff, 'DirPps';
    is        $node.Name,                    
              "\x05SummaryInformation",      'Name';
    is        $node.NextPps,     0xffffffff, 'NextPps';
    is        $node.No,          1,          'No';
    is        $node.PrevPps,     0xffffffff, 'PrevPps';
    is        $node.Size,        4096,       'Size';
    is        $node.StartBlock,  0,          'StartBlock';
    is-deeply $node.Time1st,     [ Any ],    'Time1st';
    is-deeply $node.Time2nd,     [ Any ],    'Time2nd';
    is        $node.Type,        2,          'Type';

    done-testing;
  };

  subtest 'workbook', {
    my $node = $new-root.[0].Child.[1];

    plan 14;

    isa-ok $node, 'OLE::Storage_Lite::PPS::File';

    is        $node.Child.elems, 0,          'Child count';
    is        $node.Data[0],     0x9,        'Data 0';
    is        $node.Data[1],     0x8,        'Data 1';
    is        $node.DirPps,      0xffffffff, 'DirPps';
    is        $node.Name,        "Workbook", 'Name';
    is        $node.NextPps,     3,          'NextPps';
    is        $node.No,          2,          'No';
    is        $node.PrevPps,     1,          'PrevPps';
    is        $node.Size,        4096,       'Size';
    is        $node.StartBlock,  8,          'StartBlock';
    is-deeply $node.Time1st,     [ Any ],    'Time1st';
    is-deeply $node.Time2nd,     [ Any ],    'Time2nd';
    is        $node.Type,        2,          'Type';

    done-testing;
  };

  subtest 'summary information', {
    my $node = $new-root.[0].Child.[2];

    plan 14;

    isa-ok $node, 'OLE::Storage_Lite::PPS::File';

    is        $node.Child.elems, 0,               'Child count';
    is        $node.Data[0],     0xfe,            'Data 0';
    is        $node.Data[1],     0xff,            'Data 1';
    is        $node.DirPps,      0xffffffff,      'DirPps';
    is        $node.Name,                    
              "\x[05]DocumentSummaryInformation", 'Name';
    is        $node.NextPps,     0xffffffff,      'NextPps';
    is        $node.No,          3,               'No';
    is        $node.PrevPps,     0xffffffff,      'PrevPps';
    is        $node.Size,        4096,            'Size';
    is        $node.StartBlock,  16,              'StartBlock';
    is-deeply $node.Time1st,     [ Any ],         'Time1st';
    is-deeply $node.Time2nd,     [ Any ],         'Time2nd';
    is        $node.Type,        2,               'Type';

    done-testing;
  };
}

  subtest 'root', {
    plan 11;

    my $node = $new-root.[0];
 
    isa-ok $node, 'OLE::Storage_Lite::PPS::Root';
 
#    is        $node.Child.elems, 3,                          'Child count';
    is        $node.DirPps,      2,                          'DirPps';
    is        $node.Name,        'Root Entry',               'Name';
    is        $node.NextPps,     0xffffffff,                 'NextPps';
    is        $node.No,          0,                          'No';
    is        $node.PrevPps,     0xffffffff,                 'PrevPps';
    is        $node.Size,        0,                          'Size';
    is        $node.StartBlock,  0,                          'StartBlock';
    is-deeply $node.Time1st,     [ 1, 28, 18, 5, 9, -240 ],  'Time1st';
    is-deeply $node.Time2nd,     [ 31, 58, 21, 28, 1, 101 ], 'Time2nd';
    is        $node.Type,        5,                          'Type';
 
    done-testing;
  };

  done-testing;
};

done-testing;
