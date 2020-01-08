use v6.c;

use Test;

use OLE::Storage_Lite;

constant FILENAME = 'sample/raku-small-test.dat';

# When you create the objects, fields like *Pps, No, Size, and StartBlock
# aren't initialized. They're filled when reading.
#
subtest 'before writing', {
  plan 7;

  my $workbook = OLE::Storage_Lite::PPS::File.new(
    "Workbook",
    Buf.new( 0x41, 0x42, 0x43, 0x44, 0x45, 0x46 )
  );

  my $File_2 = OLE::Storage_Lite::PPS::File.new(
    "File_2",
    Buf.new( ord("A") xx 0x1000 )
  );

  my $File_3 = OLE::Storage_Lite::PPS::File.new(
    "File_3",
    Buf.new( ord("B") xx 0x100 )
  );

  my $File_4 = OLE::Storage_Lite::PPS::File.new(
    "File_4",
    Buf.new( ord("C") xx 0x100 )
  );

  my $dir = OLE::Storage_Lite::PPS::Dir.new(
    "Dir",
    DateTime.new(
      second => 0,
      minute => 0,
      hour => 0,
      day => 1,
      month => 1,
      year => 1970
    ),
    DateTime.new(
      second => 0,
      minute => 0,
      hour => 0,
      day => 1,
      month => 1,
      year => 1970
    ),
    ( $File_2, $File_3, $File_4 )
  );

  my $root = OLE::Storage_Lite::PPS::Root.new(
#Any,
    DateTime.new(
      second => 0,
      minute => 0,
      hour => 0,
      day => 1,
      month => 1,
      year => 1970
    ),
    DateTime.new(
      second => 0,
      minute => 0,
      hour => 0,
      day => 1,
      month => 1,
      year => 1970
    ),
    ( $workbook, $dir )
  );

  subtest 'workbook', {
    plan 6;

    my $node = $workbook;
 
    isa-ok    $node,             OLE::Storage_Lite::PPS::File;

    is        $node.Child.elems, 0,          'Child count';
    is        $node.Data[0],     0x41,       'Data 0';
    is        $node.Data[1],     0x42,       'Data 1';
    is        $node.Name,        "Workbook", 'Name';
    is        $node.Type,        2,          'Type';
#    is-deeply $node.Time1st,     [],         'Time1st';
#    is-deeply $node.Time2nd,     [],         'Time2nd';

    done-testing;
  };

  subtest 'File_2', {
    plan 5;

    my $node = $File_2;
 
    isa-ok    $node,          OLE::Storage_Lite::PPS::File;

    is        $node.Child.elems, 0,        'Child count';
    is        $node.Data.[0],    0x41,     'Data';
    is        $node.Name,        "File_2", 'Name';
    is        $node.Type,        2,        'Type';
#    is-deeply $node.Time1st,  [],       'Time1st';
#    is-deeply $node.Time2nd,  [],       'Time2nd';
 
    done-testing;
  };

  subtest 'File_3', {
    plan 5;

    my $node = $File_3;
 
    isa-ok    $node,          OLE::Storage_Lite::PPS::File;

    is        $node.Child.elems, 0,        'Child count';
    is        $node.Data.[0],    0x42,     'Data';
    is        $node.Name,        "File_3", 'Name';
    is        $node.Type,        2,        'Type';
#    is-deeply $node.Time1st,     [],       'Time1st';
#    is-deeply $node.Time2nd,     [],       'Time2nd';
 
    done-testing;
  };

  subtest 'File_4', {
    plan 5;

    my $node = $File_4;
 
    isa-ok    $node,          OLE::Storage_Lite::PPS::File;

    is        $node.Child.elems, 0,        'Child count';
    is        $node.Data.[0],    0x43,     'Data';
    is        $node.Name,        "File_4", 'Name';
    is        $node.Type,        2,        'Type';
#    is-deeply $node.Time1st,     [],       'Time1st';
#    is-deeply $node.Time2nd,     [],       'Time2nd';
 
    done-testing;
  };

  subtest 'Dir', {
    plan 5;

    my $node = $dir;
 
    isa-ok    $node,             OLE::Storage_Lite::PPS::Dir;

    is        $node.Child.elems, 3,                    'Child count';
    is        $node.Data,        Any,                  'Data';
    is        $node.Name,        "Dir",                'Name';
    is        $node.Type,        1,                    'Type';
#    is-deeply $node.Time1st,     [ 0, 0, 0, 1, 0, 0 ], 'Time1st';
#    is-deeply $node.Time2nd,     [ 0, 0, 0, 1, 0, 0 ], 'Time2nd';
 
    done-testing;
  };

  subtest 'Root', {
    plan 5;

    my $node = $root;

    isa-ok    $node,             OLE::Storage_Lite::PPS::Root;

    is        $node.Child.elems, 2,                    'Child count';
    is        $node.Data,        Any,                  'Data';
    is        $node.Name,        'Root Entry',         'Name';
    is        $node.Type,        5,                    'Type';
#    is-deeply $node.Time1st,     [ 0, 0, 0, 1, 0, 0 ], 'Time1st';
#    is-deeply $node.Time2nd,     [ 0, 0, 0, 1, 0, 0 ], 'Time2nd';
    
    done-testing;
  };

  ok $root.save( FILENAME ); # XXX Don't forget there's a flag here as well

  done-testing;
};

subtest 'read small-block file', {
  plan 7;

  my $ole = OLE::Storage_Lite.new( FILENAME );
  my @pps = $ole.getPpsTree;

  is @pps.elems, 1, "Single root object";
  
  subtest 'Root Entry', {
    plan 11;
  
    my $node = @pps[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::Root;
  
    is        $node.Child.elems, 2,                    'Child count';
    is        $node.No,          0,                    'No';
    is        $node.Type,        5,                    'Type';
    is        $node.Size,        576,                  'Size';
    is        $node.Name,        'Root Entry',         'Name';
#    is-deeply $node.Time1st,     [ 0, 0, 0, 1, 0, 0 ], 'Time1st';
#    is-deeply $node.Time2nd,     [ 0, 0, 0, 1, 0, 0 ], 'Time2nd';
    is        $node.Data,        Any,                  'Data';
    is        $node.StartBlock,  1,                    'StartBlock';
    is        $node.PrevPps,     2**32 - 1,            'PrevPps';
    is        $node.NextPps,     2**32 - 1,            'NextPps';
    is        $node.DirPps,      1,                    'DirPps';

    done-testing;
  };

  subtest 'Workbook', {
    plan 10;
  
    my $node = @pps[0].Child[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is        $node.Child.elems, 0,          'Child';
    is        $node.No,          2,          'No';
    is        $node.Type,        2,          'Type';
    is        $node.Size,        6,          'Size';
    is        $node.Name,        'Workbook', 'Name';
#    is-deeply $node.Time1st,     [ Any ],    'Time1st';
#    is-deeply $node.Time2nd,     [ Any ],    'Time2nd';
#    is        $node.Data,        "ABCDEF,    'Data';
    is        $node.StartBlock,  0,          'StartBlock';
    is        $node.PrevPps,     2**32 - 1,  'PrevPps';
    is        $node.NextPps,     2**32 - 1,  'NextPps';
    is        $node.DirPps,      2**32 - 1,  'DirPps';

    done-testing;
  };

  subtest 'Dir', {
    plan 11;
  
    my $node = @pps[0].Child[1];
  
    isa-ok $node, OLE::Storage_Lite::PPS::Dir;
  
    is        $node.Child.elems, 3,                    'Child';
    is        $node.No,          1,                    'No';
    is        $node.Type,        1,                    'Type';
    is        $node.Size,        0,                    'Size';
    is        $node.Name,        'Dir',                'Name';
#    is-deeply $node.Time1st,     [ 0, 0, 0, 1, 0, 0 ], 'Time1st';
#    is-deeply $node.Time2nd,     [ 0, 0, 0, 1, 0, 0 ], 'Time2nd';
    is        $node.Data,        Any,                  'Data';
    is        $node.StartBlock,  0,                    'StartBlock';
    is        $node.PrevPps,     2,                    'PrevPps';
    is        $node.NextPps,     2**32 - 1,            'NextPps';
    is        $node.DirPps,      3,                    'DirPps';

    done-testing;
  };

  subtest 'File_2', {
    plan 11;
  
    my $node = @pps[0].Child[1].Child[0];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is        $node.Child.elems, 0,         'Child';
    is        $node.No,          4,         'No';
    is        $node.Type,        2,         'Type';
    is        $node.Size,        2**12,     'Size';
    is        $node.Name,        'File_2',  'Name';
#    is-deeply $node.Time1st,     [ Any ],   'Time1st';
#    is-deeply $node.Time2nd,     [ Any ],   'Time2nd';
    is        $node.Data,        Any,       'Data';
    is        $node.StartBlock,  3,         'StartBlock';
    is        $node.PrevPps,     2**32 - 1, 'PrevPps';
    is        $node.NextPps,     2**32 - 1, 'NextPps';
    is        $node.DirPps,      2**32 - 1, 'DirPps';

    done-testing;
  };

  subtest 'File_3', {
    plan 11;
  
    my $node = @pps[0].Child[1].Child[1];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is        $node.Child.elems, 0,         'Child';
    is        $node.No,          3,         'No';
    is        $node.Type,        2,         'Type';
    is        $node.Size,        2**8,      'Size';
    is        $node.Name,        'File_3',  'Name';
#    is-deeply $node.Time1st,     [ Any ],   'Time1st';
#    is-deeply $node.Time2nd,     [ Any ],   'Time2nd';
    is        $node.Data,        Any,       'Data';
    is        $node.StartBlock,  1,         'StartBlock';
    is        $node.PrevPps,     4,         'PrevPps';
    is        $node.NextPps,     5,         'NextPps';
    is        $node.DirPps,      2**32 - 1, 'DirPps';

    done-testing;
  };

  subtest 'File_4', {
    plan 11;
  
    my $node = @pps[0].Child[1].Child[2];
  
    isa-ok $node, OLE::Storage_Lite::PPS::File;
  
    is        $node.Child.elems, 0,         'Child';
    is        $node.No,          5,         'No';
    is        $node.Type,        2,         'Type';
    is        $node.Size,        2**8,      'Size';
    is        $node.Name,        'File_4',  'Name';
#    is-deeply $node.Time1st,     [ Any ],   'Time1st';
#    is-deeply $node.Time2nd,     [ Any ],   'Time2nd';
    is        $node.Data,        Any,       'Data';
    is        $node.StartBlock,  5,         'StartBlock';
    is        $node.PrevPps,     2**32 - 1, 'PrevPps';
    is        $node.NextPps,     2**32 - 1, 'NextPps';
    is        $node.DirPps,      2**32 - 1, 'DirPps';

    done-testing;
  };

  done-testing;
};

FILENAME.IO.unlink if FILENAME.IO.e;

done-testing;
