package PConley::Log::Setup;

our $VERSION = '11.11.22';

use 5.012004;
use strict;
use warnings;
use utf8;

use Log::Handler;
use Params::Validate;
use Term::ANSIColor;

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT_OK = qw/ log_setup /;

# User messages: 
# These do not print the line number or level in normal operation; they're
# intended simply to replace general output
#  notice : normal messages (ie., progress). print on 0+
#  error  : errors that should kill the program. print on 0+
#
# Diagnostic messages
# Include the line number and level. Intended mainly for debugging
#  debug          : routine logging messages. print on 2
#  info           : slightly more important logging messages. print on 1+
#  warning        : routine logging messages denoting anything bad. print on 1+
#  critical-alert : (equivalent to error)
#  emergency      : unused

my $verbosity = 0;

my %colortable = (
   DEBUG    => "reset",
   INFO     => "green",
   NOTICE   => "bold",
   WARNING  => "green",
   ERROR    => "red",
   CRITICAL => "bold red",
   ALERT    => "bold red",
   EMERGENCY=> "bold red",
);

# Function: format( $message ) {{{1
# Purpose:  format messages to be printed when verbosity>1
# Argument: hashref of the message layout strings
sub format
{
   my $msg = shift;
   $msg->{subroutine} =~ s/.*:://g;

   print color $colortable{$msg->{level}};

   if ( $verbosity == 2 )
   {
      printf "%9s %15.15s:%-4d %s", 
         $msg->{level}, $msg->{subroutine}, $msg->{line}, $msg->{message};
   }
   else
   {
      printf "%9s :%-4d %s", $msg->{level}, $msg->{line}, $msg->{message};
   }

   print color "reset";
}

# Function: log_setup( Log::Handler->new(), verbosity => $verb, logfile => $out ) {{{1
# Purpose : Call Log::Handler methods to set up its output
#           -1 = Quiet:   only errors are printed to stdout/stderr; errors are
#                         written to the log file (if given)
#            0 = Default: notice -> error are written to screen
#            1 = Verbose: info -> error are written to screen; messages are
#                         duplicated to the log file (if given)
#            2 = Verbose: debug -> error are written to screen
# Input   : Log::Handler object
#           [ int verbosity ]
#           [ string logfile ]
# Return  : N/A
sub log_setup
{

   my $logger = shift;

   my %options = Params::Validate::validate( @_, {
         verbosity => { 
            type => Params::Validate::SCALAR,
            default => 0,
            callbacks => {
               'greater than quiet' => sub { shift @_ >= -1 },
               'less than verbose' => sub { shift @_ <= 2 },
            },
         },
         logfile => {
            type => Params::Validate::SCALAR,
            optional => 1,
         },
      } );

   $verbosity = $options{verbosity};
   my $log_file_format = "%T [%L] %s:%l\n		%m";

   # Logfiles {{{2
   # TODO: use &format?

   # Debug log
   $logger->add(
      file => {
         maxlevel => $options{verbosity}+5, minlevel => "emergency",
         filename => $options{logfile} . ".debug", 
         message_layout => $log_file_format,
      } ) if ( $options{verbosity} >= 0 && defined $options{logfile} );

   # Error log
   $logger->add(
      file => {
         maxlevel => "warning", minlevel => "emergency",
         filename => $options{logfile} . ".err", 
         message_layout => $log_file_format,
         mode => "trunc", fileopen => 0,
      } ) if ( defined $options{logfile} );

   # Stdout {{{2

   # Debug mode
   $logger->add( forward => {
         forward_to  => \&format,
         message_pattern => [ qw/%L %s %l %m/ ],
         message_layout => "%m",
         # info is level 6, debug is level 7. Print info for $verb = 1,
         # debug for $verb = 2
         maxlevel => $options{verbosity}+5, minlevel => "emerg",
      } ) if ( $options{verbosity} > 0 );

   # Default mode
   $logger->add(
      screen => {
         maxlevel => "notice", minlevel => "notice",
         log_to => "STDOUT", message_layout => "%m",
      } ) if ( $options{verbosity} == 0 );

   # Errors
   $logger->add( 
      forward => {
         maxlevel => "error", minlevel => "alert",
         message_pattern => [ qw/%m %L/ ],
         message_layout => "%m",
         forward_to => 
            sub { print( (ucfirst lc "$_[0]->{level}: ") . $_[0]->{message} ); exit },
      } );

   # }}}2

   $logger->debug( "Set up output log to level: $options{verbosity}" );
   $logger->debug( "Writing to logfile: $options{logfile}" ) 
      if ( defined $options{logfile} );

   return $logger;

} # }}}1

1;
__END__

# {{{1 

=head1 NAME

PConley::Log::Setup - Perl extension to save space when I'm writing modules.
It takes care of my usual logger setup

=head1 SYNOPSIS

  use PConley::Log::Setup qw/ log_setup /;

  my $log = log_setup( Log::Handler->new(), verbosity => 2, logfile => 'messages' );

  OR

  my $log = Log::Handler->new();
  log_setup( $log, ... );

=head1 DESCRIPTION

A quick little method to set up an object of Log::Handler the way I like it.

The program accepts three arguments: a Log::Handler object, the verbosity
(optional), and the name of the output file for important messages (optional).

=head2 VERBOSITY

The verbosity has four options. Each level includes the behaviour of
lower-numbered levels

   -1 = Quiet   : critical -> emerg written to screen and kill the program; 
                  warning -> emerg written to the error logfile if given
   0  = Default : notice -> error written to screen
   1  = Verbose : info written to screen; 
                  info -> emerg written to the logfile if given
   2  = Verbose : debug written to screen

=head2 LOGFILE

If provided, messages will be written to a logfile as well as the screen.
Warnings and errors write to logfile.err; the file is truncated before each
run of the program. Routine messages, if enabled, will be written to
logfile.log; this file is appended to on each run.

=head1 DEPENDENCIES

 Log::Handler
 Params::Validate

=head1 AUTHOR

Patrick Conley, E<lt>pconley@uvic.caE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Patrick Conley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
