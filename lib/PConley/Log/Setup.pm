package PConley::Log::Setup;
our $VERSION = '12.07.30';

use 5.012004;
use strict;
use warnings;
use utf8;

use Log::Handler;
use Params::Validate;
use Term::ANSIColor;
use Term::ReadKey;
use Text::Wrap;

require Exporter;
our @ISA = qw/ Exporter /;
our @EXPORT_OK = qw/ log_setup /;

# User messages: 
# These do not print the line number or level in normal operation; they're
# intended simply to replace general output
#  notice: normal messages (ie., progress). print on 0+
#  emerg : errors that should kill the program (via Log->die). print on 0+
#  error-alert : errors that should *eventually* kill the program. print on
#          0+. For example, use this to print a specific error message within
#          a function, then check the function's return value and print a
#          general error with die()
#
# Diagnostic messages
# Include the line number and level. Intended for debugging
#  debug  : routine logging messages. print on 2
#  info   : slightly more important logging messages. print on 1+
#  warning: routine logging messages denoting anything bad. print on 1+

my $Verbosity = 0;
# Amount to skip at the start of the line: vverbose, verbose, long messages
my @Indent = ( 31, 16, 8 );

my %Colourtable = (
   DEBUG    => "reset",
   INFO     => "green",
   WARNING  => "yellow",
   NOTICE   => "bold",
   ERROR    => "red",
   CRITICAL => "red",
   ALERT    => "red",
   EMERGENCY=> "bold red",
);

my $Term_Width;
( $Term_Width, undef, undef, undef ) = Term::ReadKey::GetTerminalSize();

$Data::Dumper::Indent = 1;

# Function: _format( $message ) {{{1
# Purpose:  format messages to be printed when verbosity>1
# Argument: hashref of the message layout strings
sub _format
{
   my $msg = shift;
   $msg->{subroutine} =~ s/.*:://g;

   # Format the message
   my $indent = $Verbosity == 2 ? $Indent[0] : $Indent[1]; # Width of the level, sub, etc.

   # Remove any trailing newline (put it back later)
   $msg->{message} =~ s/\n\s*$//;

   # Give long lines plenty of space
   my @lines = $msg->{message} =~ /\n/g;
   if ( @lines > 5 )
   {
      $msg->{message} =~ s/^/\n/;
      $indent = $Indent[2];
   }

   my $spaces = " "x$indent;

   local($Text::Wrap::columns) = $Term_Width-$indent; #columns to use
   local($Text::Wrap::huge) = "overflow";     # don't mind long words

   # Wrap each line of each to the maximum width, appropriately indented
   $msg->{message} = Text::Wrap::wrap("", "", $msg->{message});
   $msg->{message} =~ s/\n/\n$spaces/g;

   print color $Colourtable{$msg->{level}};

   if ( $Verbosity == 2 )
   {
      printf "%9s %15.15s:%-4d %s", 
         $msg->{level}, $msg->{subroutine}, $msg->{line}, $msg->{message};
   }
   else
   {
      printf "%9s :%-4d %s", $msg->{level}, $msg->{line}, $msg->{message};
   }

   print color "reset";
   print "\n";
}

# Function: _print_errors {{{1
# Purpose:  Errors are formatted substantially differently from other messages
#           when not running in verboes mode
# Input:    hashref of message layout
# Return:   N/A
sub _print_errors
{
   print STDERR (ucfirst lc "$_[0]->{level}: "), $_[0]->{message};
}

# Function: log_setup( Log::Handler->new(), verbosity => $verb, logfile => $out, silent => ? ) {{{1
# Purpose : Call Log::Handler methods to set up its output. See POD for an
#           up-to-date explanation of what is printed when.
# Input   : Log::Handler object
#           [ int verbosity ]
#           [ string logfile ]
#           [ bool runs-silently ]
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
         silent => {
            type => Params::Validate::BOOLEAN,
            default => 0,
         },
      } );

   $Verbosity = $options{verbosity};
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
         maxlevel => "error", minlevel => "emergency",
         filename => $options{logfile} . ".err", 
         message_layout => $log_file_format,
         mode => "trunc", fileopen => 0,
      } ) if ( defined $options{logfile} );

   # Stdout {{{2

   # Debug mode
   $logger->add( forward => {
         forward_to  => \&_format,
         message_pattern => [ qw/%L %s %l %m/ ],
         message_layout => "%m",
         # info is level 6, debug is level 7. Print info for $verb = 1,
         # debug for $verb = 2
         maxlevel => $options{verbosity}+5, minlevel => "emerg",
      } ) if ( $options{verbosity} > 0 );

   # Bypass Carp::croak for $logger->die()
   $logger->add( forward => {
         forward_to => sub { exit 1 },
         maxlevel => "alert", minlevel => "emerg",
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
         maxlevel => "error", minlevel => "critical",
         message_pattern => [ qw/%m %L/ ],
         message_layout => "%m",
         forward_to => \&_print_errors,
      } ) if ( $options{verbosity} == 0 );

   $logger->add(
      forward => {
         maxlevel => "alert", minlevel => "alert",
         message_pattern => [ qw/%m %L/ ],
         message_layout => "%m",
         forward_to => sub { _print_errors( @_ ); exit 1 },
      } ) if ( $options{verbosity} == 0 );

   # }}}2

   if ( !$options{silent} )
   {
      $logger->debug( "Set up output log to level: $options{verbosity}" );
      $logger->debug( "Writing to logfile: $options{logfile}" ) 
         if ( defined $options{logfile} );
   }

   return $logger;

} # }}}1

1;
__END__

{{{

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

  -1 = Quiet  : emerg is written to stderr
                error -> emerg are written to the error logfile (if given)
   0 = Default: notice is written to stdout
   1 = Verbose: info and warn are written to stdout
                all messages give detailed caller information
                info -> emerg are written to the logfile (if given)
   2 = Verbose: debug is written to stdout

=head2 LOGFILE

If provided, messages will be written to a logfile as well as the screen.
Warnings and errors write to logfile.err; the file is truncated before each
run of the program. Routine messages, if enabled, will be written to
logfile.debug; this file is appended to on each run.

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
