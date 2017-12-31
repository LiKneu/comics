#!C:\strawberry\perl\bin\perl

#-------------------------------------------------------------------------------
#   Script: new_series.pl
#
#   Needs:
#       Template  : new_series.tmpl
#       Javascript: comicScripts.js
#
#   Function:
#       Creates standard folder structure for a new comic series.
#       Requests the name of the new series from the user and suggests a
#       conforming folder name with the help of some Javascript.
#       Creates also a XML file in the root directory of the series root folder
#       which holds the name of the series.
#
#   TODO: The above mentioned XML file is intended to replace hefte.txt later on
#-------------------------------------------------------------------------------

use strict;
use warnings;

use HTML::Template::Compiled;
use Path::Tiny;
use XML::LibXML;
use XML::LibXML::PrettyPrint;

use FormFunctions;

$| = 1;

# parse form input
my $form = parse_form();

my $series_name = $form->{'series'};	# series name from the input field
my $folder_name = $form->{'folder'};    # folder name from the input field
my $action = $form->{'action'};			# type of action the script has to do

my $path_to_data = '../data';           # path to the comic database

print "Content-type: text/html\n\n";

my $template = HTML::Template::Compiled->new(
    filename				=> '../templates/new_series.tmpl',
    case_sensitive			=> 1,
    search_path_on_include	=> 1,
    loop_context_vars 		=> 1,
    use_query				=> 0,
    default_escape			=> 'HTML',
    default_escape			=> 0,
);

$template->param(
    SERIES  => $series_name,
    FOLDER  => $folder_name,
);

print $template->output();

# in case user has provided all necessary information new folders will be
# created
if ($series_name && $folder_name && $action =~ 'create') {

    my $path_to_folder = path($path_to_data)->child($folder_name);

    # check whether folder of series does already exist
    if (-e $path_to_folder) {
        print '<p style="color:red">Folder [' . $folder_name . '] already exists!</p>';
    }
    else {
        # create folder for new series
        if ( path($path_to_folder)->mkpath ) {
            print '<p style="color:green">Folder created [' . $path_to_folder . ']</p>';
        }

        # create default folders for covers, icons, leseproben and logos
        foreach my $folder ( qw ( cover icon leseprobe logo ) ) {
            my $new_path = path($path_to_folder)->child($folder);
            if ( path( $new_path )->mkpath ) {
                print '<p style="color:green">Folder created [' . $new_path . ']</p>';
            }
        }
        # create document header
        my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');

        # create root element of the series
        my $series = $dom->createElement('series');
        $dom->setDocumentElement($series);

        # add node with the name of the series
        my $node = $series->addNewChild( undef, 'name');
        $node->appendTextNode( $series_name );

        # define path of the series xml file
        my $xml_file = path($path_to_folder)->child('series.xml');

        # format xml file so that is easier to read by humans
        my $pp = XML::LibXML::PrettyPrint->new();
        $pp->pretty_print($dom); # modified in-place

        # save formatted xml file to disc
        open my $out, '>:utf8', $xml_file or die "Couldn't open $xml_file: $!";
        print $out $dom->toString;
        close $out
    }
}
else {
    print '<p style="color:red">Name of series is missing!</p>' if !$series_name;
    print '<p style="color:red">Name of folder is missing!</p>' if !$folder_name;
}
