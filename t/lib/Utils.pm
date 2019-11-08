class Utils;

sub int32_minus_1 {
  2**32 - 1
}

sub serialize_pps($pps) is export {

  my $output = {
    Type       => $pps.Type,
    Data       => $pps.Data,
    No         => $pps.No,
    Size       => $pps.Size,
    StartBlock => $pps.StartBlock,
    Time1st    => $pps.Time1st,
    Time2nd    => $pps.Time2nd,
    Name       => $pps.Name,
    DirPps     => $pps.DirPps,
    NextPps    => $pps.NextPps,
    PrevPps    => $pps.PrevPps,
  };

  if ( $pps->{Child} and @{ $pps->{Child} } ) {
    $output->{Child} = [ ];

    foreach $pps.Child -> $item {
      my $res = serialize_pps($item);
      $output.{Child}.append: $res;
    }
  }

  return $output;
}

#sub prune {
#  my ($ref, @prune_me) = @_;
#  my %prune_me = map { $_ => 1 } @prune_me;
#  my %pruned;
#
#  $pruned{$_} = $ref->{$_} for grep {
#    !($_ eq 'Child' or exists $prune_me{$_})
#  } keys %$ref;
#
#  if ( $ref->{Child} ) {
#    for my $child ( @{ $ref->{Child} } ) {
#      push @{ $pruned{Child} }, prune( $child, @prune_me );
#    }
#  }
#
#  return \%pruned;
#}

1;
