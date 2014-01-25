#
#===============================================================================
#
#         FILE: Server.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 01/25/2014 10:02:18 PM
#     REVISION: ---
#===============================================================================

package Module::Temperature::Server;
use Modern::Perl 2013;
use Moose;
extends 'Module::Temperature';

#TODO: implement
# use existing temp_io_async
# include CPU and GPU temperature
# include temperature from /proc on laptop

no Moose;
__PACKAGE__->meta->make_immutable;

1;

