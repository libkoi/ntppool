package NTPPool::Control::Zone;
use strict;
use base qw(NTPPool::Control);
use NTPPool::Server;
use Apache::Constants qw(OK);

sub cache_info {
  my $self = shift;
  return +{ id => join ";",
            "zonepage",
            $self->zone_name,
            $self->sort_order,
            $self->show_servers,
            ($self->show_servers_access ? 1 : 0),
          }
}

sub zone_name {
  my $self = shift;
  my ($zone_name) = ($self->request->uri =~ m!^/zone/([^/]+)!);
  $zone_name ||= '@';
  $zone_name;
}

# TODO: make the web interface actually do this
sub sort_order {
    my $self = shift;
    my $sort = $self->req_param('sort') || ''; 
    $sort = 'description' unless $sort eq 'server_count';
}

sub show_servers_access {
    my $self = shift;
    my $p = $self->user && $self->user->privileges;
    warn Data::Dumper->Dump([\$p], [qw(p)]);
    return 1 if $self->user 
      and $self->user->privileges
      and $self->user->privileges->see_all_servers;
    return 0;
}

sub show_servers {
    my $self = shift;
    return 1 if $self->req_param('show_servers') and $self->show_servers_access;
    return 0;
} 

sub render {
  my $self = shift;
  my $zone_name = $self->zone_name;
  my ($zone) = NTPPool::Zone->search(name => $zone_name) or return 404;
  $self->tpl_param('zone' => $zone);

  $self->tpl_param('is_logged_in' => $self->show_servers_access );
  $self->tpl_param('show_servers' => $self->show_servers);
  if ($self->show_servers) {
      my @servers = sort { $a->ip cmp $b->ip } $zone->servers;
      $self->tpl_param('servers', \@servers);
  }

  return OK, $self->evaluate_template('tpl/zone.html');
}

1;
