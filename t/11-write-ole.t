use v6.c;

use Test;

use P5localtime;
use OLE::Storage_Lite;

plan 6;

# Use subroutines instead of subtests so we can make sure there's 1:1 fidelity
# between what's written out and what we read back in.

sub test-workbook( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,          'Child count';
  is        $node.Data,        'ABCDEF',   'Data';
  is        $node.DirPps,      Int,        'DirPps';
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

sub test-second-file( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,            'Child count';
  is        $node.Data,        'A' x 0x1000, 'Data';
  is        $node.DirPps,      Int,          'DirPps';
  is        $node.Name,        'File_2',     'Name';
  is        $node.NextPps,     Int,          'NextPps';
  is        $node.No,          Int,          'No';
  is        $node.PrevPps,     Int,          'PrevPps';
  is        $node.Size,        Int,          'Size';
  is        $node.StartBlock,  Int,          'StartBlock';
  is-deeply $node.Time1st,     [],           'Time1st';
  is-deeply $node.Time2nd,     [],           'Time2nd';
  is        $node.Type,        2,            'Type';

  done-testing;
}

sub test-third-file( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,           'Child count';
  is        $node.Data,        'B' x 0x100, 'Data';
  is        $node.DirPps,      Int,         'DirPps';
  is        $node.Name,        'File_3',    'Name';
  is        $node.NextPps,     Int,         'NextPps';
  is        $node.No,          Int,         'No';
  is        $node.PrevPps,     Int,         'PrevPps';
  is        $node.Size,        Int,         'Size';
  is        $node.StartBlock,  Int,         'StartBlock';
  is-deeply $node.Time1st,     [],          'Time1st';
  is-deeply $node.Time2nd,     [],          'Time2nd';
  is        $node.Type,        2,           'Type';

  done-testing;
}

sub test-fourth-file( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::File';

  is        $node.Child.elems, 0,           'Child count';
  is        $node.Data,        'C' x 0x100, 'Data';
  is        $node.DirPps,      Int,         'DirPps';
  is        $node.Name,        'File_4',    'Name';
  is        $node.NextPps,     Int,         'NextPps';
  is        $node.No,          Int,         'No';
  is        $node.PrevPps,     Int,         'PrevPps';
  is        $node.Size,        Int,         'Size';
  is        $node.StartBlock,  Int,         'StartBlock';
  is-deeply $node.Time1st,     [],          'Time1st';
  is-deeply $node.Time2nd,     [],          'Time2nd';
  is        $node.Type,        2,           'Type';

  done-testing;
}

sub test-dir( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::Dir';

  is        $node.Child.elems, 3,
            'Child count';
  is        $node.Data,        Any,                                  'Data';
  is        $node.DirPps,      Int,                                  'DirPps';
  is        $node.Name,        'Dir',                                'Name';
  is        $node.NextPps,     Int,                                  'NextPps';
  is        $node.No,          Int,                                  'No';
  is        $node.PrevPps,     Int,                                  'PrevPps';
  is        $node.Size,        Int,                                  'Size';
  is        $node.StartBlock,  Int,
            'StartBlock';
  is-deeply $node.Time1st,     [ 0, 0, 0,  1, 0,  -299, 1, 0,   0 ], 'Time1st';
  is-deeply $node.Time2nd,     [ 0, 0, 16, 4, 10, 100,  6, 308, 0 ], 'Time2nd';
  is        $node.Type,        Int,                                  'Type';

  done-testing;
}

sub test-root( $node ) {
  plan 13;

  isa-ok $node, 'OLE::Storage_Lite::PPS::Root';

  is        $node.Child.elems, 2,                        'Child count';
  is        $node.Data,        Any,                      'Data';
  is        $node.DirPps,      Int,                      'DirPps';
  is        $node.Name,        'Root Entry',             'Name';
  is        $node.NextPps,     Int,                      'NextPps';
  is        $node.No,          Int,                      'No';
  is        $node.PrevPps,     Int,                      'PrevPps';
  is        $node.Size,        Int,                      'Size';
  is        $node.StartBlock,  Int,                      'StartBlock';
  is-deeply $node.Time1st,     [ ],                      'Time1st';
  is-deeply $node.Time2nd,     [ 0, 0, 16, 4, 10, 100 ], 'Time2nd';
  is        $node.Type,        5,                        'Type';

  done-testing;
}

# Original sample script by Kawai, Takanori (Hippo2000)
#
# Rewritten to be a test by Jeff G. (drforr)
#
# Writes to a tmp file, probably should use File::Temp. XXX

constant FILENAME = 'sample/tsv.dat'; # XXX should use File::Temp?

my @aL = localtime();
splice( @aL, 6 );

my @Time1st = ( 0, 0, 0,  1, 0,  -299, 1, 0,   0 );
my @Time2nd = ( 0, 0, 16, 4, 10, 100,  6, 308, 0 );

# The method encodes to UCS2/UTF-16LE
my $workbook = OLE::Storage_Lite::PPS::File.new(
  'Workbook', 'ABCDEF'
);

subtest 'Workbook', {
  test-workbook( $workbook );
};

my $file_2 = OLE::Storage_Lite::PPS::File.new(
  'File_2', 'A' x 0x1000
);

subtest 'File_2', {
  test-second-file( $file_2 );
};

my $file_3 = OLE::Storage_Lite::PPS::File.new(
  'File_3', 'B'x 0x100
);

subtest 'File_3', {
  test-third-file( $file_3 );
};

my $file_4 = OLE::Storage_Lite::PPS::File.new(
  'File_4', 'C'x 0x100
);

subtest 'File_4', {
  test-fourth-file( $file_4 );
};

my $dir = OLE::Storage_Lite::PPS::Dir.new(
#  'Dir', @aL, @aL, ($oF2, $oF3, $oF4)
  'Dir', @Time1st, @Time2nd, ( $file_2, $file_3, $file_4 )
);

subtest 'Dir', {
  test-dir( $dir );
};

my $root = OLE::Storage_Lite::PPS::Root.new(
  (),
  (0, 0, 16, 4, 10, 100),  #2000/11/4 16:00:00:0000
  ($workbook, $dir)
);

subtest 'Root', {
  test-root( $root );
};

$root.save( 'new-' ~ FILENAME );

#my $ole = OLE::Storage_Lite.new( FILENAME );
#my $pps = $ole.getPpsTree;

done-testing;
