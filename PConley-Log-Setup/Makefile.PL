use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'PConley::Log::Setup',
    VERSION_FROM      => 'lib/PConley/Log/Setup.pm', # finds $VERSION
    PREREQ_PM         => { 'Params::Validate' => 0, 'Log::Handler' => 0 }, # e.g., Module::Name => 1.1
    PREFIX            => '/home/pconley/perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PConley/Log/Setup.pm', # retrieve abstract from module
       AUTHOR         => 'Patrick Conley <pconley@uvic.ca>') : ()),
);
