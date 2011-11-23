package PConley::Log::Setup;

use 5.012004;
use strict;
use warnings;

our $VERSION = '0.01';

use Log::Handler;

# Function: setup( $verbosity ) {{{1
# Purpose:  Call Log::Handler methods to set up its output
#           -1 = Quiet:   nothing is printed to stdout/stderr; errors are
#                         written to TagList.err
#            0 = Default: notice -> error are written to screen
#            1 = Verbose: info -> error are written to screen; messages are
#                         duplicated to TagList.log
#            2 = Verbose: debug -> error are written to screen
# Input:    int verbosity
# Return:   N/A
sub setup
{

   my $log = shift;

   my $logFormat = "[%L] l.%l: %m";
   my $verbosity = @_ ? shift : 0;

   # Debug mode {{{2
   if ( $verbosity > 0 )
   {

      # info is level 6, debug is level 7. Print info for $verb = 1, debug for
      # $verb = 2
      my $debug_verbosity = $verbosity + 5;

      $log->add(
         screen => {
            maxlevel => $debug_verbosity, minlevel => "info",
            log_to => "STDOUT", message_layout => $logFormat,
         }
      );

      $log->add(
         file => {
            maxlevel => "info", minlevel => "emergency",
            filename => "TagList.log", message_layout => "%T [%L] %m",
         }
      );

   }

   # Debug and default modes {{{2
   if ( $verbosity >= 0 )
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

      $log->add(
         forward => {
            maxlevel => "critical", minlevel => "emerg",
            message_layout => $logFormat,
            forward_to => sub { die "$_[0]->{message}" }
         }
      );

   }

   # error-file {{{2
   $log->add(
      file => {
         maxlevel => "warning", minlevel => "emergency",
         filename => "TagList.err", message_layout => "%t $logFormat",
         mode => "trunc", fileopen => 0,
      }
   );

   # }}}2
   
   $log->info( "Set up output log to level [ $verbosity ]" );

} # }}}1

my $log = Log::Handler->new();

setup( $log );

$log->warning( "test" );

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Log::Setup - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Log::Setup;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Log::Setup, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Patrick Conley, E<lt>pconley@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Patrick Conley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
