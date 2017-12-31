#!C:\strawberry\perl\bin\perl

#-------------------------------------------------------------------------------
#   Script: comics_navi.pl
#
#   Needs:
#       Template  : comics_navi.tmpl
#
#   Function:
#       Shows start screen of the comic database.
#-------------------------------------------------------------------------------

use strict;
use warnings;

use HTML::Template::Compiled;

$| = 1;

my $version = "2017-12-31";

my $graph_path = "../graphics";

print "Content-type: text/html\n\n";

my $template = HTML::Template::Compiled->new(
	filename				=> '../templates/comics_navi.tmpl',
	case_sensitive			=> 1,
	search_path_on_include	=> 1,
	loop_context_vars 		=> 1,
	use_query				=> 0,
	default_escape			=> 'HTML',
	default_escape			=> 0,
);

$template->param(
	GRAPH_PATH  => $graph_path,
);

print $template->output();

exit;