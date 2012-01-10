#!/usr/bin/perl -w
#    Copyright 2011 Merijntje Tak
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, version 3 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
#
#    tracestore.pl - Store traceroutes based on NetFlow data
#
#   For all information, please view the README file.

use strict;
use DBD::mysql;
use Net::Traceroute;
use Socket;
use Data::Dumper;
use threads ('exit' => 'threads_only'); # exit() in thread becomes threads->exit()

my $mysqlHost = 'localhost';
my $mysqlUser = 'mysqlUser';
my $mysqlPass = 'mysqlPass';
my $mysqlName = 'databaseName';
my $flowdFile = '/var/log/flowd';             # Flowd  database file
my $flowdSudo = 1;                            # Use sudo for flowd-reader
my $flowdBin = '/opt/flowd/bin/flowd-reader'; # flowd-reader binary
my $sudoBin = '/usr/bin/sudo';                # sudo binary
my $processTime = 300;                        # Amount of seconds to process during each run, 300 is default

my $debugSwitch = 0;
my $debugSwitchThreads = 0;
#
# SQL functions INET_ATON and INET_NTOA are being used to
#  convert the IP to an INT value
#

#
# getStartTime
# Determine the start time in epoch seconds for analysis
# Input: none
# Output: reference to start time in epoch secs
sub getStartTime {
  my $startTime = time - $processTime;
  return(\$startTime);
}

#
# processInput
# Process the argument given to this script
# Input: reference to $ARGV[0]
# Output: reference to IP address
#
sub processInput {
  my $input_ref = shift;
  my $ip;

  if ( $$input_ref =~ m/[A-Za-z]+/o ) {

    my $packed_ip = gethostbyname($$input_ref);

    if (defined $packed_ip) {
      $ip = inet_ntoa($packed_ip);
    }

    if ( !defined($ip) || $ip =~  m/[A-Za-z]+/o ) {

      print "Address $$input_ref cannot be resolved. Aborting...\n" ;
      exit(1);

    }


  } else {

    $ip = $$input_ref;

  }

  return(\$ip);
   
}


#
# setupTrace
# Create the trace object
# Input: target IP address
# Output: Reference to traceroute object
#
sub setupTrace {
	my $target_ref = shift;

	my $trace = Net::Traceroute->new(host => $$target_ref);

	return(\$trace);

}

#
# listHops
# Put all the hops in a reference
# Input: reference to trace object
# Output: reference to hash
#  $data{$hopCount}{$queryCount}{'host'} = $hostname
#  $data{$hopCount}{$queryCount}{'time'} = $RTT
# 
sub listHops {
  my $trace_ref = shift;
  my %data;
	
  my $tr = $trace_ref;
	
  print "Trace endpoint found\n" if $debugSwitch == 1;

  my $hops = $$tr->hops;

  print "hops: $hops\n" if $debugSwitch == 1;

  my $hopCount = 0;
  while ( $hopCount++ < $hops ) {

    my $queryCount = 0;
    while ( $queryCount++ < 3 ) {

      if ( $$tr->hop_query_host($hopCount, $queryCount)  =~ m/^255.255.255.255$/o ) {
        next;
      }

      $data{$hopCount}{$queryCount}{'host'} = $$tr->hop_query_host($hopCount, $queryCount);
      $data{$hopCount}{$queryCount}{'time'} = $$tr->hop_query_time($hopCount, $queryCount);

    }
  }

  return(\%data);
}

#
# createMysqlConn
# Creates connection to mysql database
# Input: mysqlHost, mysqlUser, mysqlPass, mysqlDb
# Output: reference to database handler or 1 if unsuccessfull
#
sub createMysqlConn {
  my $dbhost_ref = shift;
  my $dbuser_ref = shift;
  my $dbpass_ref = shift;
  my $dbname_ref = shift;

  my $dbh = DBI->connect('DBI:mysql:'.$$dbname_ref.";host=".$$dbhost_ref, $$dbuser_ref, $$dbpass_ref, { PrintError => 1 } ); 

  if ( defined($DBI::errstr) ) {
    print "Error connecting to database:\n$DBI::errstr \n";
    exit(1);
  }

  return(\$dbh);
}

#
# closeMysqlConn
# Closes mysql connection cleanly
# Input: reference to database handler
#
sub closeMysqlConn {
  my $dbh_ref = shift;

  $$dbh_ref->disconnect();

  return(0);
}

#
# insertMetaData
# Create the SQL query for the traceroute table (metadata), do it, and return the inserted id
# Input: reference to database handler, reference to target
# Output: reference to inserted id
#
sub insertMetaData {
  my $dbh_ref = shift;
  my $target_ref = shift;

  my $src = "10.100.0.70";
  my $dst = $$target_ref;

  my $insq = "INSERT INTO traceroutes (src, dest, time) 
                VALUES (INET_ATON(\"$src\"), INET_ATON(\"$dst\"), now());";
  $$dbh_ref->do($insq);

  my $sth = $$dbh_ref->prepare("SELECT LAST_INSERT_ID() AS id;");
  $sth->execute;
  my $res_ref = $sth->fetchrow_arrayref();
  my $id = $$res_ref[0];

  return(\$id);
}

#
# insertData
# Insert the trace data into the database
# Input: reference to database handler, traceroutes_id, hop number, ip, rtt
# Output: exit status
#
sub insertData {
  my $dbh_ref = shift;
  my $metaid_ref = shift;
  my $hop_ref = shift;
  my $ip_ref = shift;
  my $rtt_ref = shift;

  my $insq = "INSERT INTO traceresults (traceroutes_id, hop, ip, rtt)
               VALUES ($$metaid_ref, $$hop_ref, INET_ATON(\"$$ip_ref\"), $$rtt_ref)";

  $$dbh_ref->do($insq);

}

#
# prepareData
# Use the data from the trace in the insertData function
# Input: reference to data returned from listHops(), database handler
# Output: exit status
#
sub prepareData {
  my $data_ref = shift;
  my $dbh_ref = shift;
  my $id_ref = shift;

  foreach my $hop ( keys(%$data_ref) ) {

    my $data_query_ref = \%{$$data_ref{$hop}};

    foreach my $query ( keys(%$data_query_ref) ) {

      my $ip = \$$data_query_ref{$query}{'host'};
      my $rtt = \$$data_query_ref{$query}{'time'};

      insertData($dbh_ref, $id_ref, \$hop, $ip, $rtt);

    }

  }  

}

#
# getFlowdHosts
# Get list of hosts to process from flowd from the last x minutes 
# Input: reference to start time in epoch seconds
# Output: reference to an array with hosts to check
#
sub getFlowdHosts {
  my $starttime_ref = shift;

  my %rawHosts;
  my @hosts;

  my $cmd = "$flowdBin -cv $flowdFile |";
  if ( $flowdSudo == 1 ) {
    open(FLOWD, $sudoBin." ".$cmd);
  } else {
    open(FLOWD, $cmd);
  }

  while (<FLOWD>) {
    my $line = $_;

    if ( $line =~ m/^#|^LOGFILE/o ) {
      next;
    }

    my @lineSplit = split(/,/, $line);

    if ( $lineSplit[0] < $$starttime_ref ) {
      next;
    }

    $rawHosts{$lineSplit[10]} = 0;
  }
  close(FLOWD);

  foreach my $host ( keys(%rawHosts) ) {
    push(@hosts, $host);
  }

  return(\@hosts);

}

#
# main
# Main routine of the program
# Input: config values at the top of the file
# Output: none
#
sub main {
  my $target_ref = processInput(\$ARGV[0]);

  print "Target: ".$$target_ref."\n" if $debugSwitch == 1;

  my $trace_ref = setupTrace($target_ref);
  my $data_ref = listHops($trace_ref);

  my $dbh_ref = createMysqlConn(\$mysqlHost,\$mysqlUser,\$mysqlPass,\$mysqlName);

  my $id_ref = insertMetaData($dbh_ref, $target_ref);

  print "Trace ID: $$id_ref\n" if $debugSwitch == 1;

  prepareData($data_ref, $dbh_ref, $id_ref);

  closeMysqlConn($dbh_ref);
}

#main();

# newMain is the old main with the flowd list included
sub newMain {

  # Get the start time of the analysis run
  my $starttime_ref = getStartTime;

  # Get a list of hosts we need to traceroute
  my $hosts_ref = getFlowdHosts($starttime_ref);

  # Create a MySQL connection
  my $dbh_ref = createMysqlConn(\$mysqlHost,\$mysqlUser,\$mysqlPass,\$mysqlName);

  # Start tracing these hosts (threading needed!)
  foreach my $host (@$hosts_ref) {

    # Create a trace object
    my $trace_ref = setupTrace(\$host);

    # Get a list of hops
    my $data_ref = listHops($trace_ref);

    # Insert metadata about the trace into the database
    my $id_ref = insertMetaData($dbh_ref, \$host);
    print "Trace ID: $$id_ref\n" if $debugSwitch == 1;

    # Prepare and insert actual data into the database
    prepareData($data_ref, $dbh_ref, $id_ref);

  }

  # Close connection to MySQL
  closeMysqlConn($dbh_ref);

}

#newMain();

# threading stuff
# newMain + threading support
# We need a thread routine before we run the main program
sub thread {
  my $host_ref = shift;

  print "Thread ".threads->tid()." started\n" if $debugSwitchThreads == 1;

  # Create a trace object
  my $trace_ref = setupTrace($host_ref);

  # Get a list of hops
  my $data_ref = listHops($trace_ref);

  # Create a MySQL connection (db connection cannot be used by multiple threads)
  my $dbh_ref = createMysqlConn(\$mysqlHost,\$mysqlUser,\$mysqlPass,\$mysqlName);

  # Insert metadata about the trace into the database
  my $id_ref = insertMetaData($dbh_ref, $host_ref);
  print "Trace ID: $$id_ref\n" if $debugSwitch == 1;

  # Prepare and insert actual data into the database
  prepareData($data_ref, $dbh_ref, $id_ref);

  # Close connection to MySQL
  closeMysqlConn($dbh_ref);

  threads->exit(0);
}
sub threadMain {

  # Get the start time of the analysis run
  my $starttime_ref = getStartTime;

  # Get a list of hosts we need to traceroute
  my $hosts_ref = getFlowdHosts($starttime_ref);

  print "Total number of hosts: ".scalar(@$hosts_ref)."\n" if $debugSwitchThreads == 1;

  # Start tracing these hosts
  foreach my $host (@$hosts_ref) {
    my $thr = threads->create('thread', \$host);

    print "Thread ".$thr->tid()." stack size: ".$thr->get_stack_size()."\n" if $debugSwitchThreads == 1;
  }

  # Wait for all threads to finish
  while ( threads->list(threads::running) > 0 ) {
    print "Number of running threads: ".scalar(threads->list(threads::running))."\n" if $debugSwitchThreads == 1;

    my @joinable = threads->list(threads::joinable);
    foreach my $thr (@joinable) {
      $thr->join();
      print "Thread ".$thr->tid()." joined\n" if $debugSwitchThreads == 1;
    }

    sleep(1);
  }
    
}

threadMain();
