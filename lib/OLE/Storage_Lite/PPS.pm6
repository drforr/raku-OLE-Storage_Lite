use v6;

# I've changed the "OO" part of this module just to simplify things.
#
# The original module called new() here which called new() on one of a bunch
# of different modules based on $iType.
#
# That means a parent module needed to include its children. Which is bad.
# So instead I put the method higher up in the OLE::Storage_Lite hierarchy.
# It now just needs the PPS modules it's going to disgorge, so it's more like
# a Factory pattern, I suppose.
#

unit class OLE::Storage_Lite::PPS;

has Int $.No;
has Str $.Name; # Gotten usually from Buffers, decoded to UTF-8...
has Int $.Type;
has Int $.PrevPps;
has Int $.NextPps;
has Int $.DirPps;
has     @.Time1st;
has     @.Time2nd;
has Int $.StartBlock;
has Int $.Size;
has     $.Data;
has     @.Child;

# Specifically, this method right here gets moved up.
#
#sub new ($$$$$$$$$$;$$) {
##1. Constructor for General Usage
#  my($sClass, $iNo, $sNm, $iType, $iPrev, $iNext, $iDir,
#     $raTime1st, $raTime2nd, $iStart, $iSize, $sData, $raChild) = @_;
#
#  if($iType == OLE::Storage_Lite::PpsType_File()) { #FILE
#    return OLE::Storage_Lite::PPS::File->_new
#        ($iNo, $sNm, $iType, $iPrev, $iNext, $iDir, $raTime1st, $raTime2nd,
#         $iStart, $iSize, $sData, $raChild);
#  }
#  elsif($iType == OLE::Storage_Lite::PpsType_Dir()) { #DIRECTRY
#    return OLE::Storage_Lite::PPS::Dir->_new
#        ($iNo, $sNm, $iType, $iPrev, $iNext, $iDir, $raTime1st, $raTime2nd,
#         $iStart, $iSize, $sData, $raChild);
#  }
#  elsif($iType == OLE::Storage_Lite::PpsType_Root()) { #ROOT
#    return OLE::Storage_Lite::PPS::Root->_new
#        ($iNo, $sNm, $iType, $iPrev, $iNext, $iDir, $raTime1st, $raTime2nd,
#         $iStart, $iSize, $sData, $raChild);
#  }
#  else {
#    die "Error PPS:$iType $sNm\n";
#  }
#}

#sub _new ($$$$$$$$$$$;$$) {
#  my($sClass, $iNo, $sNm, $iType, $iPrev, $iNext, $iDir,
#        $raTime1st, $raTime2nd, $iStart, $iSize, $sData, $raChild) = @_;
##1. Constructor for OLE::Storage_Lite
#  my $oThis = {
#    No   => $iNo,
#    Name => $sNm,
#    Type => $iType,
#    PrevPps => $iPrev,
#    NextPps => $iNext,
#    DirPps => $iDir,
#    Time1st => $raTime1st,
#    Time2nd => $raTime2nd,
#    StartBlock => $iStart,
#    Size       => $iSize,
#    Data       => $sData,
#    Child      => $raChild,
#  };
#  bless $oThis, $sClass;
#  return $oThis;
#}

##------------------------------------------------------------------------------
## _DataLen (OLE::Storage_Lite::PPS)
## Check for update
##------------------------------------------------------------------------------
#sub _DataLen($) {
#    my($oSelf) =@_;
#    return 0 unless(defined($oSelf->{Data}));
#    return ($oSelf->{_PPS_FILE})?
#        ($oSelf->{_PPS_FILE}->stat())[7] : length($oSelf->{Data});
#}

#sub _makeSmallData($$$) {
#  my($oThis, $aList, $rhInfo) = @_;
#  my ($sRes);
#  my $FILE = $rhInfo->{_FILEH_};
#  my $iSmBlk = 0;
#
#  foreach my $oPps (@$aList) {
##1. Make SBD, small data string
#  if($oPps->{Type}==OLE::Storage_Lite::PpsType_File()) {
#    next if($oPps->{Size}<=0);
#    if($oPps->{Size} < $rhInfo->{_SMALL_SIZE}) {
#      my $iSmbCnt = int($oPps->{Size} / $rhInfo->{_SMALL_BLOCK_SIZE})
#                    + (($oPps->{Size} % $rhInfo->{_SMALL_BLOCK_SIZE})? 1: 0);
#      #1.1 Add to SBD
#      for (my $i = 0; $i<($iSmbCnt-1); $i++) {
#            print {$FILE} (pack("V", $i+$iSmBlk+1));
#      }
#      print {$FILE} (pack("V", -2));
#
#      #1.2 Add to Data String(this will be written for RootEntry)
#      #Check for update
#      if($oPps->{_PPS_FILE}) {
#        my $sBuff;
#        $oPps->{_PPS_FILE}->seek(0, 0); #To The Top
#        while($oPps->{_PPS_FILE}->read($sBuff, 4096)) {
#            $sRes .= $sBuff;
#        }
#      }
#      else {
#        $sRes .= $oPps->{Data};
#      }
#      $sRes .= ("\x00" x
#        ($rhInfo->{_SMALL_BLOCK_SIZE} - ($oPps->{Size}% $rhInfo->{_SMALL_BLOCK_SIZE})))
#        if($oPps->{Size}% $rhInfo->{_SMALL_BLOCK_SIZE});
#      #1.3 Set for PPS
#      $oPps->{StartBlock} = $iSmBlk;
#      $iSmBlk += $iSmbCnt;
#    }
#  }
#  }
#  my $iSbCnt = int($rhInfo->{_BIG_BLOCK_SIZE}/ OLE::Storage_Lite::LongIntSize());
#  print {$FILE} (pack("V", -1) x ($iSbCnt - ($iSmBlk % $iSbCnt)))
#    if($iSmBlk  % $iSbCnt);
##2. Write SBD with adjusting length for block
#  return $sRes;
#}

#sub _savePpsWk($$) {
#  my($oThis, $rhInfo) = @_;
##1. Write PPS
#  my $FILE = $rhInfo->{_FILEH_};
#  print {$FILE} (
#            $oThis->{Name}
#            . ("\x00" x (64 - length($oThis->{Name})))  #64
#            , pack("v", length($oThis->{Name}) + 2)     #66
#            , pack("c", $oThis->{Type})         #67
#            , pack("c", 0x00) #UK               #68
#            , pack("V", $oThis->{PrevPps}) #Prev        #72
#            , pack("V", $oThis->{NextPps}) #Next        #76
#            , pack("V", $oThis->{DirPps})  #Dir     #80
#            , "\x00\x09\x02\x00"                #84
#            , "\x00\x00\x00\x00"                #88
#            , "\xc0\x00\x00\x00"                #92
#            , "\x00\x00\x00\x46"                #96
#            , "\x00\x00\x00\x00"                #100
#            , OLE::Storage_Lite::LocalDate2OLE($oThis->{Time1st})       #108
#            , OLE::Storage_Lite::LocalDate2OLE($oThis->{Time2nd})       #116
#            , pack("V", defined($oThis->{StartBlock})?
#                      $oThis->{StartBlock}:0)       #116
#            , pack("V", defined($oThis->{Size})?
#                 $oThis->{Size} : 0)            #124
#            , pack("V", 0),                  #128
#        );
#}
