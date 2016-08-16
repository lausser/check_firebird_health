package Classes::Device;
our @ISA = qw(Monitoring::GLPlugin::DB);
use strict;


sub classify {
  my $self = shift;
  if ($self->opts->method eq "dbi") {
    bless $self, "Classes::FIREBIRD::DBI";
    if ((! $self->opts->hostname && ! $self->opts->server) ||
        ! $self->opts->username || ! $self->opts->password || ! $self->opts->database) {
      $self->add_unknown('Please specify hostname or server, database, username and password');
    }
    if (! eval "require DBD::Firebird") {
      $self->add_critical('could not load perl module DBD::Firebird');
    }
  } elsif ($self->opts->method eq "psql") {
    bless $self, "Classes::FIREBIRD::Psql";
    if ((! $self->opts->hostname && ! $self->opts->server) ||
        ! $self->opts->username || ! $self->opts->password) {
      $self->add_unknown('Please specify hostname or server, username and password');
    }
  } elsif ($self->opts->method eq "sqlrelay") {
    bless $self, "Classes::FIREBIRD::Sqlrelay";
    if ((! $self->opts->hostname && ! $self->opts->server) ||
        ! $self->opts->username || ! $self->opts->password) {
      $self->add_unknown('Please specify hostname or server, username and password');
    }
    if (! eval "require DBD::SQLRelay") {
      $self->add_critical('could not load perl module SQLRelay');
    }
  }
  if (! $self->check_messages()) {
    $self->check_connect_and_version();
    if (! $self->check_messages()) {
      $self->add_dbi_funcs();
      if ($self->opts->mode =~ /^my-/) {
        $self->load_my_extension();
      }
    }
  }
}

sub add_dbi_funcs {
  my $self = shift;
  {
    no strict 'refs';
    *{'Monitoring::GLPlugin::DB::fetchall_array'} = \&{"Classes::FIREBIRD::DBI::fetchall_array"};
    *{'Monitoring::GLPlugin::DB::fetchrow_array'} = \&{"Classes::FIREBIRD::DBI::fetchrow_array"};
    *{'Monitoring::GLPlugin::DB::execute'} = \&{"Classes::FIREBIRD::DBI::execute"};
  }
}

