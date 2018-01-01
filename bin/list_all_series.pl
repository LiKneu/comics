#!C:\strawberry\perl\bin\perl

#-------------------------------------------------------------------------------
#   Script: list_all_series.pl
#
#   Needs:
#       Template: list_all_series.tmpl
#
#   Function:
#       Goes through all folders of the comic data base and retrieves the
#       names of the available series from either
#           - hefte.txt
#               or
#           - series.xml
#
#   TODO: This script is intended to replace sammlungsliste.pl
#   TODO: series.xml is intended to replace hefte.txt
#-------------------------------------------------------------------------------

use strict;
use warnings;

use HTML::Template::Compiled;
use Data::Dumper;

use DatabaseFunctionsXML;

$| = 1;

my $path_to_data = '../data';   # path to the comic database

my $all_series = get_series_names( $path_to_data );

print "Content-type: text/html\n\n";

my $template = HTML::Template::Compiled->new(
    filename				=> '../templates/list_all_series.tmpl',
    case_sensitive			=> 1,
    search_path_on_include	=> 1,
    loop_context_vars 		=> 1,
    use_query				=> 0,
    default_escape			=> 'HTML',
#    default_escape			=> 0,
);

$template->param(
    SERIES_DATA  => $all_series,
);

print $template->output();

exit;