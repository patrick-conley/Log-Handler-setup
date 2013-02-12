# NAME

PConley::Log::Setup - Perl extension to save space when I'm writing modules.
It takes care of my usual logger setup.

# SYNOPSIS

    use PConley::Log::Setup qw/ log_setup /;

    my $log = log_setup( Log::Handler->new(), verbosity => 2, logfile => 'messages' );

    OR

    my $log = Log::Handler->new();
    log_setup( $log, ... );

# DESCRIPTION

A quick little method to set up an object of Log::Handler the way I like it.

The program accepts three arguments: a Log::Handler object, the verbosity
(optional), and the name of the output file for important messages (optional).

## VERBOSITY

The verbosity has four options. Each level includes the behaviour of
lower-numbered levels

    -1 = Quiet  : emerg is written to stderr
                  error -> emerg are written to the error logfile (if given)
     0 = Default: notice is written to stdout
     1 = Verbose: info and warn are written to stdout
                  all messages give detailed caller information
                  info -> emerg are written to the logfile (if given)
     2 = Verbose: debug is written to stdout

## LOGFILE

If provided, messages will be written to a logfile as well as the screen.
Warnings and errors write to logfile.err; the file is truncated before each
run of the program. Routine messages, if enabled, will be written to
logfile.debug; this file is appended to on each run.

# DEPENDENCIES

    Log::Handler
    Params::Validate
    Term::ANSIColor
    Term::ReadKey
    Text::Wrap

# AUTHOR

Patrick Conley, <pconley@uvic.ca>

# COPYRIGHT AND LICENSE

Copyright (C) 2011 by Patrick Conley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.
