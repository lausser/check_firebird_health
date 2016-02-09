package Classes::FIREBIRD;
our @ISA = qw(Classes::Device);

use strict;
use Time::HiRes;
use IO::File;
use File::Copy 'cp';
use Data::Dumper;
our $AUTOLOAD;


sub init {
  my $self = shift;
  if ($self->mode =~ /^server::connectiontime/) {
    my $connection_time = $self->{tac} - $self->{tic};
    $self->set_thresholds(warning => 1, critical => 5);
    $self->add_message($self->check_thresholds($connection_time),
         sprintf "%.2f seconds to connect as %s",
              $connection_time, $self->opts->username,);
    $self->add_perfdata(
        label => 'connection_time',
        value => $connection_time,
    );
  } elsif ($self->mode =~ /^server::connectedusers/) {
    my $connectedusers = $self->fetchrow_array(q{
        SELECT
          COUNT(*)
        FROM
          master..sysprocesses
        WHERE
          hostprocess IS NOT NULL AND program_name != 'JS Agent'
    });
    if (! defined $connectedusers) {
      $self->add_unknown("unable to count connected users");
    } else {
      $self->set_thresholds(warning => 50, critical => 80);
      $self->add_message($self->check_thresholds($connectedusers),
          sprintf "%d connected users", $connectedusers);
      $self->add_perfdata(
          label => "connected_users",
          value => $connectedusers
      );
    }
  } elsif ($self->mode =~ /^server::sqlruntime/) {
    my $tic = Time::HiRes::time();
    my @genericsql = $self->fetchrow_array($self->opts->name);
    my $runtime = Time::HiRes::time() - $tic;
    # normally, sql errors and stderr result in CRITICAL or WARNING
    # we can clear these errors if we are only interested in the runtime
    $self->clear_all() if $self->check_messages() && 
        defined $self->opts->mitigation && $self->opts->mitigation == 0;
    $self->set_thresholds(warning => 1, critical => 5);
    $self->add_nagios($self->check_thresholds($runtime),
        sprintf "%.2f seconds to execute %s",
            $runtime,
            $self->opts->name2 ? $self->opts->name2 : $self->opts->name);
    $self->add_perfdata(
        label => "sql_runtime",
        value => $runtime,
        uom => "s",
    );
  } elsif ($self->mode =~ /^server::sql/) {
    if ($self->opts->regexp) {
      # sql output is treated as text
      my $pattern = $self->opts->name2;
      #if ($self->opts->name2 eq $self->opts->name) {
      my $genericsql = $self->fetchrow_array($self->opts->name);
      if (! defined $genericsql) {
        $self->add_unknown(sprintf "got no valid response for %s",
            $self->opts->name);
      } else {
        if (substr($pattern, 0, 1) eq '!') {
          $pattern =~ s/^!//;
          if ($genericsql !~ /$pattern/) {
            $self->add_ok(
                sprintf "output %s does not match pattern %s",
                    $genericsql, $pattern);
          } else {
            $self->add_critical(
                sprintf "output %s matches pattern %s",
                    $genericsql, $pattern);
          }
        } else {
          if ($genericsql =~ /$pattern/) {
            $self->add_ok(
                sprintf "output %s matches pattern %s",
                    $genericsql, $pattern);
          } else {
            $self->add_critical(
                sprintf "output %s does not match pattern %s",
                    $genericsql, $pattern);
          }
        }
      }
    } else {
      # sql output must be a number (or array of numbers)
      my @genericsql = $self->fetchrow_array($self->opts->name);
      if (! @genericsql) {
          #(scalar(grep { /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/ } @{$self->{genericsql}})) ==
          #scalar(@{$self->{genericsql}}))) {
        $self->add_unknown(sprintf "got no valid response for %s",
            $self->opts->name);
      } else {
        # name2 in array
        # units in array

        $self->set_thresholds(warning => 1, critical => 5);
        $self->add_message(
          # the first item in the list will trigger the threshold values
            $self->check_thresholds($genericsql[0]),
                sprintf "%s: %s%s",
                $self->opts->name2 ? lc $self->opts->name2 : lc $self->opts->name,
              # float as float, integers as integers
                join(" ", map {
                    (sprintf("%d", $_) eq $_) ? $_ : sprintf("%f", $_)
                } @genericsql),
                $self->opts->units ? $self->opts->units : "");
        my $i = 0;
        # workaround... getting the column names from the database would be nicer
        my @names2_arr = split(/\s+/, $self->opts->name2);
        foreach my $t (@genericsql) {
          $self->add_perfdata(
              label => $names2_arr[$i] ? lc $names2_arr[$i] : lc $self->opts->name,
              value => (sprintf("%d", $t) eq $t) ? $t : sprintf("%f", $t),
              uom => $self->opts->units ? $self->opts->units : "",
          );
          $i++;
        }
      }
    }
  } else {
    $self->no_such_mode();
  }
}


