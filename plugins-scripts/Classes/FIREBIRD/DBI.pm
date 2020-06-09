package Classes::FIREBIRD::DBI;
our @ISA = qw(Classes::FIREBIRD);
use strict;
use File::Basename;

sub check_connect_and_version {
  my $self = shift;
  my $stderrvar;
  my $dbi_options = { RaiseError => 1, AutoCommit => $self->opts->commit, PrintError => 1 };
  my $dsn = "DBI:Firebird:";
  $dsn .= sprintf ";dbname=%s", $self->opts->database;
  if ($self->opts->hostname) {
    $dsn .= sprintf ";host=%s", $self->opts->hostname;
  }
  if ($self->opts->port) {
    $dsn .= sprintf ";port=%s", $self->opts->port;
  }
  $self->set_variable("dsn", $dsn);
  eval {
    require DBI;
    use POSIX ':signal_h';
    if ($^O =~ /MSWin/) {
      local $SIG{'ALRM'} = sub {
        die "alrm";
      };
    } else {
      my $mask = POSIX::SigSet->new( SIGALRM );
      my $action = POSIX::SigAction->new(
          sub { die "alrm"; }, $mask
      );
      my $oldaction = POSIX::SigAction->new();
      sigaction(SIGALRM ,$action ,$oldaction );
    }
    alarm($self->opts->timeout - 1); # 1 second before the global unknown timeout
    *SAVEERR = *STDERR;
    open OUT ,'>',\$stderrvar;
    *STDERR = *OUT;
    $self->{tic} = Time::HiRes::time();
    if ($self->{handle} = DBI->connect(
        $dsn,
        $self->opts->username,
        $self->decode_password($self->opts->password),
        $dbi_options)) {
      $Monitoring::GLPlugin::DB::session = $self->{handle};
    }
    $self->{tac} = Time::HiRes::time();
    *STDERR = *SAVEERR;
  };
  if ($@) {
    if ($@ =~ /alrm/) {
      $self->add_critical(
          sprintf "connection could not be established within %s seconds",
          $self->opts->timeout);
    } else {
      $self->add_critical($@);
    }
  } elsif (! $self->{handle}) {
    $self->add_critical("no connection");
  }
  if (! $self->check_messages()) {
    my $version;
    eval {
      $version = $self->fetchrow_array(q{
          SELECT
              rdb$get_context('SYSTEM', 'ENGINE_VERSION')
          FROM
              rdb$database
      });
    };
    if (! $version) {
      $self->clear_critical();
      $self->set_variable("version", "1.5");
      $self->set_variable("os", "Linux") if $self->opts->database =~ /^\//;
      $self->set_variable("os", "Windows") if $self->opts->database =~ /^[a-z]:/i;
      $self->set_variable("product", "FIREBIRD");
      $self->set_variable("dbuser", $self->opts->username);
    } else {
    }
  }
}

sub fetchrow_array {
  my $self = shift;
  my $sql = shift;
  my @arguments = @_;
  my $sth = undef;
  my @row = ();
  my $errvar = "";
  my $stderrvar = "";
  $self->set_variable("verbosity", 2);
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "SQL:\n%s\nARGS:\n%s\n",
        $sql, Data::Dumper::Dumper(\@arguments));
    $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    if (scalar(@arguments)) {
      $sth->execute(@arguments) || die DBI::errstr();
    } else {
      $sth->execute() || die DBI::errstr();
    }
    if (lc $sql =~ /^\s*(exec |sp_)/ || $sql =~ /^\s*exec sp/im) {
      # flatten the result sets
      do {
        while (my $aref = $sth->fetchrow_arrayref()) {
          push(@row, @{$aref});
        }
      } while ($sth->{syb_more_results});
    } else {
      @row = $sth->fetchrow_array();
    }
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper(\@row));
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
  } elsif ($stderrvar || $errvar) {
    $errvar = join("\n", (split(/\n/, $errvar), $stderrvar));
    $self->debug(sprintf "stderr %s", $errvar) ;
    $self->add_warning($errvar);
  }
  return $row[0] unless wantarray;
  return @row;
}

sub fetchall_array {
  my $self = shift;
  my $sql = shift;
  my @arguments = @_;
  my $sth = undef;
  my $rows = undef;
  my $errvar = "";
  my $stderrvar = "";
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "SQL:\n%s\nARGS:\n%s\n",
        $sql, Data::Dumper::Dumper(\@arguments));
    if ($sql =~ /^\s*dbcc /im) {
      # dbcc schreibt auf stdout. Die Ausgabe muss daher
      # mit einem eigenen Handler aufgefangen werden.
      $Monitoring::GLPlugin::DB::session->{syb_err_handler} = sub {
        my($err, $sev, $state, $line, $server,
            $proc, $msg, $sql, $err_type) = @_;
        push(@{$rows}, $msg);
        return 0;
      };
    }
    $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    if (scalar(@arguments)) {
      $sth->execute(@arguments);
    } else {
      $sth->execute();
    }
    if ($sql !~ /^\s*dbcc /im) {
      $rows = $sth->fetchall_arrayref();
    }
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper($rows));
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
    $rows = [];
  } elsif ($stderrvar || $errvar) {
    $errvar = join("\n", (split(/\n/, $errvar), $stderrvar));
    $self->debug(sprintf "stderr %s", $errvar) ;
    $self->add_warning($errvar);
  }
  return @{$rows};
}

sub exec_sp_1hash {
  my $self = shift;
  my $sql = shift;
  my @arguments = @_;
  my $sth = undef;
  my $rows = undef;
  eval {
    $self->debug(sprintf "SQL:\n%s\nARGS:\n%s\n",
        $sql, Data::Dumper::Dumper(\@arguments));
    $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    if (scalar(@arguments)) {
      $sth->execute(@arguments);
    } else {
      $sth->execute();
    }
    do {
      while (my $href = $sth->fetchrow_hashref()) {
        foreach (keys %{$href}) {
          push(@{$rows}, [ $_, $href->{$_} ]);
        }
      }
    } while ($sth->{syb_more_results});
    $self->debug(sprintf "RESULT:\n%s\n",
        Data::Dumper::Dumper($rows));
  };
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
    $rows = [];
  }
  return @{$rows};
}


sub execute {
  my $self = shift;
  my $sql = shift;
  my $errvar = "";
  my $stderrvar = "";
  *SAVEERR = *STDERR;
  open ERR ,'>',\$stderrvar;
  *STDERR = *ERR;
  eval {
    $self->debug(sprintf "EXEC:\n%s\n", $sql);
    my $sth = $Monitoring::GLPlugin::DB::session->prepare($sql);
    $sth->execute();
  };
  *STDERR = *SAVEERR;
  if ($@) {
    $self->debug(sprintf "bumm %s", $@);
    $self->add_critical($@);
  } elsif ($stderrvar || $errvar) {
    $errvar = join("\n", (split(/\n/, $errvar), $stderrvar));
    $self->debug(sprintf "stderr %s", $errvar) ;
    $self->add_warning($errvar);
  }
}

sub DESTROY {
  my $self = shift;
  $self->debug(sprintf "disconnecting DBD %s",
      $Monitoring::GLPlugin::DB::session ? "with handle" : "without handle");
  $Monitoring::GLPlugin::DB::session->disconnect() if $Monitoring::GLPlugin::DB::session;
}

