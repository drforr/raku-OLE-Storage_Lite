#package Utils;
#
#sub int32_minus_1 {
#  2**32 - 1
#}
#
#sub serialize_pps {
#  my ($pps) = @_;
#
#  my $output = { };
#
#  for my $name ( qw( Type Data No Size StartBlock Time1st
#		     Time2nd Name DirPps NextPps PrevPps ) ) {
#    $output->{$name} = $pps->{$name};
#  }
#
#  if ( $pps->{Child} and @{ $pps->{Child} } ) {
#    $output->{Child} = [ ];
#
#    foreach my $item (@{$pps->{Child}}) {
#      my $res = serialize_pps($item);
#      push @{ $output->{Child} }, $res;
#    }
#  }
#
#  return $output;
#}
#
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
#
#1;
