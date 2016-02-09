#! /usr/bin/perl

use strict;

eval {
  if ( ! grep /AUTOLOAD/, keys %Monitoring::GLPlugin::) {
    require Monitoring::GLPlugin;
    require Monitoring::GLPlugin::DB;
  }
};
if ($@) {
  printf "UNKNOWN - module Monitoring::GLPlugin was not found. Either build a standalone version of this plugin or set PERL5LIB\n";
  printf "%s\n", $@;
  exit 3;
}

my $plugin = Classes::Device->new(
    shortname => '',
    usage => '%s [-v] [-t <timeout>] '.
        '--hostname=<db server hostname> [--port <port>] '.
        '--username=<username> --password=<password> '.
        '--mode=<mode> '.
        '...',
    version => '$Revision: #PACKAGE_VERSION# $',
    blurb => 'This plugin checks microsoft sql servers ',
    url => 'http://labs.consol.de/nagios/check_firebird_health',
    timeout => 60,
);
$plugin->add_mode(
    internal => 'server::connectiontime',
    spec => 'connection-time',
    alias => undef,
    help => 'Time to connect to the server',
);
$plugin->add_mode(
    internal => 'server::cpubusy',
    spec => 'cpu-busy',
    alias => undef,
    help => 'Cpu busy in percent',
);
$plugin->add_mode(
    internal => 'server::iobusy',
    spec => 'io-busy',
    alias => undef,
    help => 'IO busy in percent',
);
$plugin->add_mode(
    internal => 'server::fullscans',
    spec => 'full-scans',
    alias => undef,
    help => 'Full table scans per second',
);
$plugin->add_mode(
    internal => 'server::connectedusers',
    spec => 'connected-users',
    alias => undef,
    help => 'Number of currently connected users',
);
$plugin->add_mode(
    internal => 'server::database::transactions',
    spec => 'transactions',
    alias => undef,
    help => 'Transactions per second (per database)',
);
$plugin->add_mode(
    internal => 'server::batchrequests',
    spec => 'batch-requests',
    alias => undef,
    help => 'Batch requests per second',
);
$plugin->add_mode(
    internal => 'server::latch::waits',
    spec => 'latches-waits',
    alias => undef,
    help => 'Number of latch requests that could not be granted immediately',
);
$plugin->add_mode(
    internal => 'server::latch::waittime',
    spec => 'latches-wait-time',
    alias => undef,
    help => 'Average time for a latch to wait before the request is met',
);
$plugin->add_mode(
    internal => 'server::memorypool::lock::waits',
    spec => 'locks-waits',
    alias => undef,
    help => 'The number of locks per second that had to wait',
);
$plugin->add_mode(
    internal => 'server::memorypool::lock::timeouts',
    spec => 'locks-timeouts',
    alias => undef,
    help => 'The number of locks per second that timed out',
);
$plugin->add_mode(
    internal => 'server::memorypool::lock::deadlocks',
    spec => 'locks-deadlocks',
    alias => undef,
    help => 'The number of deadlocks per second',
);
$plugin->add_mode(
    internal => 'server::sql::recompilations',
    spec => 'sql-recompilations',
    alias => undef,
    help => 'Re-Compilations per second',
);
$plugin->add_mode(
    internal => 'server::sql::initcompilations',
    spec => 'sql-initcompilations',
    alias => undef,
    help => 'Initial compilations per second',
);
$plugin->add_mode(
    internal => 'server::totalmemory',
    spec => 'total-server-memory',
    alias => undef,
    help => 'The amount of memory that SQL Server has allocated to it',
);
$plugin->add_mode(
    internal => 'server::memorypool::buffercache::hitratio',
    spec => 'mem-pool-data-buffer-hit-ratio',
    alias => ['buffer-cache-hit-ratio'],
    help => 'Data Buffer Cache Hit Ratio',
);
$plugin->add_mode(
    internal => 'server::memorypool::buffercache::lazywrites',
    spec => 'lazy-writes',
    alias => undef,
    help => 'Lazy writes per second',
);
$plugin->add_mode(
    internal => 'server::memorypool::buffercache::pagelifeexpectancy',
    spec => 'page-life-expectancy',
    alias => undef,
    help => 'Seconds a page is kept in memory before being flushed',
);
$plugin->add_mode(
    internal => 'server::memorypool::buffercache::freeliststalls',
    spec => 'free-list-stalls',
    alias => undef,
    help => 'Requests per second that had to wait for a free page',
);
$plugin->add_mode(
    internal => 'server::memorypool::buffercache::checkpointpages',
    spec => 'checkpoint-pages',
    alias => undef,
    help => 'Dirty pages flushed to disk per second. (usually by a checkpoint)',
);
$plugin->add_mode(
    internal => 'server::database::online',
    spec => 'database-online',
    alias => undef,
    help => 'Check if a database is online and accepting connections',
);
$plugin->add_mode(
    internal => 'server::database::databasefree',
    spec => 'database-free',
    alias => undef,
    help => 'Free space in database',
);
$plugin->add_mode(
    internal => 'server::database::backupage',
    spec => 'database-backup-age',
    alias => ['backup-age'],
    help => 'Elapsed time (in hours) since a database was last backed up',
);
$plugin->add_mode(
    internal => 'server::database::logbackupage',
    spec => 'database-logbackup-age',
    alias => ['logbackup-age'],
    help => 'Elapsed time (in hours) since a database transaction log was last backed up',
);
$plugin->add_mode(
    internal => 'server::database::autogrowths::file',
    spec => 'database-file-auto-growths',
    alias => undef,
    help => 'The number of File Auto Grow events (either data or log) in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::autogrowths::logfile',
    spec => 'database-logfile-auto-growths',
    alias => undef,
    help => 'The number of Log File Auto Grow events in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::autogrowths::datafile',
    spec => 'database-datafile-auto-growths',
    alias => undef,
    help => 'The number of Data File Auto Grow events in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::autoshrinks::file',
    spec => 'database-file-auto-shrinks',
    alias => undef,
    help => 'The number of File Auto Shrink events (either data or log) in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::autoshrinks::logfile',
    spec => 'database-logfile-auto-shrinks',
    alias => undef,
    help => 'The number of Log File Auto Shrink events in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::autoshrinks::datafile',
    spec => 'database-datafile-auto-shrinks',
    alias => undef,
    help => 'The number of Data File Auto Shrink events in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::database::dbccshrinks::file',
    spec => 'database-file-dbcc-shrinks',
    alias => undef,
    help => 'The number of DBCC File Shrink events (either data or log) in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::jobs::failed',
    spec => 'failed-jobs',
    alias => undef,
    help => 'The jobs which did not exit successful in the last <n> minutes (use --lookback)',
);
$plugin->add_mode(
    internal => 'server::jobs::enabled',
    spec => 'jobs-enabled',
    alias => undef,
    help => 'The jobs which are not enabled (scheduled)',
);
$plugin->add_mode(
    internal => 'server::sql',
    spec => 'sql',
    alias => undef,
    help => 'any sql command returning a single number',
);
$plugin->add_mode(
    internal => 'server::sqlruntime',
    spec => 'sql-runtime',
    alias => undef,
    help => 'the time an sql command needs to run',
);
$plugin->add_mode(
    internal => 'server::database::createuser',
    spec => 'create-monitoring-user',
    alias => undef,
    help => 'convenience function which creates a monitoring user',
);
$plugin->add_mode(
    internal => 'server::database::listdatabases',
    spec => 'list-databases',
    alias => undef,
    help => 'convenience function which lists all databases',
);
$plugin->add_mode(
    internal => 'server::database::datafile::listdatafiles',
    spec => 'list-datafiles',
    alias => undef,
    help => 'convenience function which lists all datafiles',
);
$plugin->add_mode(
    internal => 'server::memorypool::lock::listlocks',
    spec => 'list-locks',
    alias => undef,
    help => 'convenience function which lists all locks',
);
$plugin->add_arg(
    spec => 'debug|d',
    help => "--debug
",
    required => 0,);
$plugin->add_arg(
    spec => 'hostname=s',
    help => "--hostname
   the database server",
    required => 0,);
$plugin->add_arg(
    spec => 'username=s',
    help => "--username
   the firebird user",
    required => 0,);
$plugin->add_arg(
    spec => 'password=s',
    help => "--password
   the firebird user's password",
    required => 0,);
$plugin->add_arg(
    spec => 'port=i',
    default => 1433,
    help => "--port
   the database server's port",
    required => 0,);
$plugin->add_arg(
    spec => 'server=s',
    help => "--server
   use a section in freetds.conf instead of hostname/port",
    required => 0,);
$plugin->add_arg(
    spec => 'mode|m=s',
    help => "--mode
   the mode of the plugin. select one of the following keywords:",
    required => 1,);
$plugin->add_arg(
    spec => 'database=s',
    help => "--database
   alias for --name in a database-specific context",
    required => 0,);
$plugin->add_arg(
    spec => 'datafile=s',
    help => "--datafile
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'waitevent=s',
    help => "--waitevent
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'offlineok',
    help => "--offlineok
   if mode database-free finds a database which is currently offline,
   a WARNING is issued. If you don't want this and if offline databases
   are perfectly ok for you, then add --offlineok. You will get OK instead.",
    required => 0,);
$plugin->add_arg(
    spec => 'mitigation=s',
    help => "--mitigation
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'notemp',
    help => "--notemp
skip the tempdb",
    required => 0,);
$plugin->add_arg(
    spec => 'name=s',
    help => "--name
   the name of the database etc depending on the mode",
    required => 0,);
$plugin->add_arg(
    spec => 'drecksptkdb=s',
    help => "--drecksptkdb
   This parameter must be used instead of --name, because Devel::ptkdb is stealing the latter from the command line",
    aliasfor => "name",
    required => 0,
);
$plugin->add_arg(
    spec => 'name2=s',
    help => "--name2
   if name is a sql statement, this statement would appear in
   the output and the performance data. This can be ugly, so 
   name2 can be used to appear instead",
    required => 0,);
$plugin->add_arg(
    spec => 'name3=s',
    help => "--name3
   The tertiary name of whatever",
    required => 0,
);
$plugin->add_arg(
    spec => 'regexp',
    help => "--regexp
   if this parameter is used, name will be interpreted as a 
   regular expression",
    required => 0,);
#$plugin->add_arg(
#    spec => 'perfdata',
#    help => "--perfdata
#bla",
#    required => 0,);
$plugin->add_arg(
    spec => 'warning=s',
    help => "--warning
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'critical=s',
    help => "--critical
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'warningx=s%',
    help => '--warningx
   The extended warning thresholds
   e.g. --warningx db_msdb_free_pct=6: to override the threshold for a
   specific item ',
    required => 0,
);
$plugin->add_arg(
    spec => 'criticalx=s%',
    help => '--criticalx
   The extended critical thresholds',
    required => 0,
);
$plugin->add_arg(
    spec => 'dbthresholds:s',
    help => "--dbthresholds
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'absolute|a',
    help => "--absolute
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'basis',
    help => "--basis
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'lookback|l=i',
    help => "--lookback
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'environment|e=s%',
    help => "--environment
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'negate=s%',
    help => "--negate
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'method=s',
    default => 'dbi',
    help => "--method
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'runas|r=s',
    help => "--runas
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'scream',
    help => "--scream
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'shell',
    help => "--shell
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'eyecandy',
    help => "--eyecandy
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'encode',
    help => "--encode
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'units=s',
    help => "--units
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => '3',
    help => "--3
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'statefilesdir=s',
    help => "--statefilesdir
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'with-mymodules-dyn-dir=s',
    help => "--with-mymodules-dyn-dir
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'multiline',
    help => '--multiline
   Multiline output',
    required => 0,
);
$plugin->add_arg(
    spec => 'report=s',
    help => "--report
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'commit',
    default => 0,
    help => "--commit
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'labelformat=s',
    help => "--labelformat
_tobedone_",
    required => 0,);
$plugin->add_arg(
    spec => 'extra-opts:s',
    help => "--extra-opts
_tobedone_",
    required => 0,);

$plugin->getopts();
$plugin->classify();
$plugin->validate_args();


if (! $plugin->check_messages()) {
  $plugin->init();
  if (! $plugin->check_messages()) {
    $plugin->add_ok($plugin->get_summary())
        if $plugin->get_summary();
    $plugin->add_ok($plugin->get_extendedinfo(" "))
        if $plugin->get_extendedinfo();
  }
} else {
#  $plugin->add_critical('wrong device');
}
my ($code, $message) = $plugin->opts->multiline ?
    $plugin->check_messages(join => "\n", join_all => ', ') :
    $plugin->check_messages(join => ', ', join_all => ', ');
$message .= sprintf "\n%s\n", $plugin->get_info("\n")
    if $plugin->opts->verbose >= 1;
#printf "%s\n", Data::Dumper::Dumper($plugin);
$plugin->nagios_exit($code, $message);


