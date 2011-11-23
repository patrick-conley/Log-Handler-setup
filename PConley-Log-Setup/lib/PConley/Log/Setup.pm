package PConley::Log::Setup;

our $VERSION = '11.11.22';

use 5.012004;
use strict;
use warnings;
use utf8;

use Log::Handler;
use Params::Validate;

# Function: setup( Log::Handler->new(), verbosity => $verb, logfile => $out ) {{{1
# Purpose : Call Log::Handler methods to set up its output
#           -1 = Quiet:   nothing is printed to stdout/stderr; errors are
#                         written to the log file (if given)
#            0 = Default: notice -> error are written to screen
#            1 = Verbose: info -> error are written to screen; messages are
#                         duplicated to the log file (if given)
#            2 = Verbose: debug -> error are written to screen
# Input   : Log::Handler object
#           [ int verbosity ]
#           [ string logfile ]
# Return  : N/A
sub setup
{

   my $logger = shift;

   my %options = Params::Validate::validate( @_, {
         verbosity => { 
            type => Params::Validate::SCALAR,
            default => 0,
            callbacks => {
               'greater than quiet' => sub { shift >= -1 },
               'less than verbose' => sub { shift <= 2 },
            },
         },
         logfile => {
            type => Params::Validate::SCALAR,
         },
      } );

   my $logFormat = "[%L] l.%l: %m";

   # Debug mode {{{2
   if ( $options{verbosity} > 0 )
   {

      # info is level 6, debug is level 7. Print info for $verb = 1, debug for
      # $verb = 2
      my $debug_verbosity = $options{verbosity} + 5;

      $log->add(
         screen => {
            maxlevel => $debug_verbosity, minlevel => "info",
            log_to => "STDOUT", message_layout => $logFormat,
         }
      );

      if ( defined $options{logfile} )
      {
         $log->add(
            file => {
               maxlevel => "info", minlevel => "emergency",
               filename => $options{logfile} . ".log", message_layout => "%T [%L] %m",
            }
         );
      }

   }

   # Debug and default modes {{{2
   if ( $options{verbosity} >= 0 )
   {
      $log->add(
         screen => {
            maxlevel => "notice", minlevel => "notice",
            log_to => "STDOUT", message_layout => $logFormat,
         }
      );

      $log->add(
         screen => {
            maxlevel => "warning", minlevel => "error",
            log_to => "STDERR", message_layout => $logFormat,
         }
      );

   }

   $log->add(
      forward => {
         maxlevel => "critical", minlevel => "emerg",
         message_layout => $logFormat,
         forward_to => sub { die "$_[0]->{message}" }
      }
   );

   # error-file {{{2
   if ( defined $options{logfile} )
   {
      $log->add(
         file => {
            maxlevel => "warning", minlevel => "emergency",
            filename => $options{logfile} . ".err", message_layout => "%t $logFormat",
            mode => "trunc", fileopen => 0,
         }
      );
   }

   # }}}2
   
   $log->info( "Set up output log to level [ $options{verbosity} ]" );

} # }}}1

1;
__END__
=head1 NAME

PConley::Log::Setup - Perl extension to save space when I'm writing modules.
It takes care of my usual logger setup

=head1 SYNOPSIS

  use PConley::Log::Setup;

  my $log = setup( Log::Handler->new(), verbosity => 2, logfile => 'messages' );

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
