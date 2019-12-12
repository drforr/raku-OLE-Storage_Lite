use v6.c;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/raku-test-no-data.xls';

sub test-workbook( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,          'Child count';
  is        $node.DirPps,      Int,        'DirPps';
  is        $node.Data,        Any,        'Data';
  is        $node.Name,        'Workbook', 'Name';
  is        $node.NextPps,     Int,        'NextPps';
  is        $node.No,          Int,        'No';
  is        $node.PrevPps,     Int,        'PrevPps';
  is        $node.Size,        Int,        'Size';
  is        $node.StartBlock,  Int,        'StartBlock';
  is-deeply $node.Time1st,     [],         'Time1st';
  is-deeply $node.Time2nd,     [],         'Time2nd';
  is        $node.Type,        2,          'Type';

  done-testing;
}

sub test-summary-information( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,     'Child count';
  is        $node.DirPps,      Int,   'DirPps';
  is        $node.Data,        Any,   'Data';
  is        $node.Name,
            "\x05SummaryInformation", 'Name';
  is        $node.NextPps,     Int,   'NextPps';
  is        $node.No,          Int,   'No';
  is        $node.PrevPps,     Int,   'PrevPps';
  is        $node.Size,        Int,   'Size';
  is        $node.StartBlock,  Int,   'StartBlock';
  is-deeply $node.Time1st,     [],    'Time1st';
  is-deeply $node.Time2nd,     [],    'Time2nd';
  is        $node.Type,        2,     'Type';

  done-testing;
}

sub test-document-summary-information( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,               'Child count';
  is        $node.DirPps,      Int,             'DirPps';
  is        $node.Data,        Any,             'Data';
  is        $node.Name,
            "\x[05]DocumentSummaryInformation", 'Name';
  is        $node.NextPps,     Int,             'NextPps';
  is        $node.No,          Int,             'No';
  is        $node.PrevPps,     Int,             'PrevPps';
  is        $node.Size,        Int,             'Size';
  is        $node.StartBlock,  Int,             'StartBlock';
  is-deeply $node.Time1st,     [],              'Time1st';
  is-deeply $node.Time2nd,     [],              'Time2nd';
  is        $node.Type,        2,               'Type';

  done-testing;
}

sub test-root( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::Root';

  is        $node.Child.elems, 3,                 'Child count';
  is        $node.DirPps,      Int,               'DirPps';
  is        $node.Data,        Any,               'Data';
  is        $node.Name,        'Root Entry',      'Name';
  is        $node.NextPps,     Int,               'NextPps';
  is        $node.No,          Int,               'No';
  is        $node.PrevPps,     Int,               'PrevPps';
  is        $node.Size,        Int,               'Size';
  is        $node.StartBlock,  Int,               'StartBlock';
  is-deeply $node.Time1st,
            [ 1, 28, 18, 5, 9, -240, 2, 278, 0 ], 'Time1st';
  is-deeply $node.Time2nd,
            [ 31, 58, 21, 28, 1, 101, 3, 58, 0 ], 'Time2nd';
  is        $node.Type,        5,                 'Type';

  done-testing;
}

my $workbook = OLE::Storage_Lite::PPS::File.new(
  "Workbook"
);

my $summary-information = OLE::Storage_Lite::PPS::File.new(
  "\x05SummaryInformation"
);

my $document-summary-information = OLE::Storage_Lite::PPS::File.new(
  "\x[05]DocumentSummaryInformation"
);

my $root = OLE::Storage_Lite::PPS::Root.new(
  ( 1, 28, 18, 5, 9, -240, 2, 278, 0 ),
  ( 31, 58, 21, 28, 1, 101, 3, 58, 0 ),
  ( $workbook, $summary-information, $document-summary-information )
);

subtest 'before writing', {

  subtest 'workbook', {
    test-workbook( $workbook );
  };

  subtest 'summary information', {
    test-summary-information( $summary-information );
  };

  subtest 'document summary information', {
    test-document-summary-information( $document-summary-information );
  };

  subtest 'root', {
    test-root( $root );
  };

};

$root.save( FILENAME );

#my $ole = OLE::Storage_Lite.new( FILENAME );
#my $new-root = $ole.getPpsTree;
#die $new-root;

done-testing;
