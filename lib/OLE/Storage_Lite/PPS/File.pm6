use v6;

use OLE::Storage_Lite::PPS;

unit class OLE::Storage_Lite::PPS::File is OLE::Storage_Lite::PPS;

#sub new ($$$) {
#  my($sClass, $sNm, $sData) = @_;
#    OLE::Storage_Lite::PPS::_new(
#        $sClass,
#        undef,
#        $sNm,
#        2,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        $sData,
#        undef);
#}

#sub newFile ($$;$) {
#    my($sClass, $sNm, $sFile) = @_;
#    my $oSelf =
#    OLE::Storage_Lite::PPS::_new(
#        $sClass,
#        undef,
#        $sNm,
#        2,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        undef,
#        '',
#        undef);
##
#    if((!defined($sFile)) or ($sFile eq '')) {
#        $oSelf->{_PPS_FILE} = IO::File->new_tmpfile();
#    }
#    elsif(UNIVERSAL::isa($sFile, 'IO::Handle')) {
#        $oSelf->{_PPS_FILE} = $sFile;
#    }
#    elsif(!ref($sFile)) {
#        #File Name
#        $oSelf->{_PPS_FILE} = new IO::File;
#        return undef unless($oSelf->{_PPS_FILE});
#        $oSelf->{_PPS_FILE}->open("$sFile", "r+") || return undef;
#    }
#    else {
#        return undef;
#    }
#    if($oSelf->{_PPS_FILE}) {
#        $oSelf->{_PPS_FILE}->seek(0, 2);
#        binmode($oSelf->{_PPS_FILE});
#        $oSelf->{_PPS_FILE}->autoflush(1);
#    }
#    return $oSelf;
#}

#sub append ($$) {
#    my($oSelf, $sData) = @_;
#    if($oSelf->{_PPS_FILE}) {
#        print {$oSelf->{_PPS_FILE}} $sData;
#    }
#    else {
#        $oSelf->{Data} .= $sData;
#    }
#}
