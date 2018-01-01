package DatabaseFunctionsXML;

#-------------------------------------------------------------------------------
#   Package holds functions needed to handle comic book information stored
#   in XML file series.xml
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

use Path::Tiny;
use XML::LibXML;
use XML::LibXML::PrettyPrint;

use Data::Dumper;

use DatabaseFunctionsCSV;

require Exporter;

our @ISA = qw ( Exporter );

our @EXPORT = qw (
    get_series_name
    get_series_names
    );

#-------------------------------------------------------------------------------
#   Gets the name of the series from file series.xml
#
sub get_series_name {
    my $path_to_series = shift;
    my $series_name;

    my $dom = XML::LibXML->load_xml(location => $path_to_series);

    # the following two steps are necessary to remove the whitspace added by
    # XML::LibXML::PrettyPrint during generation of the XML file
    my $pp = XML::LibXML::PrettyPrint->new();
    $pp->strip_whitespace($dom);

    $series_name = $dom->findvalue('/series/name');

    return $series_name;
}

#-------------------------------------------------------------------------------
#   Get all the names of the available series stored in the database folder
#   structure
#
sub get_series_names {
    my $path_to_database = shift;
    my @series_names;

    # get all 1st level folders in the database
    my @folders = path($path_to_database)->children;

    foreach my $folder ( @folders ) {

        # get just the name of the folder not the full path of the series
        my $folder_name = path($folder)->basename;

        my $xml_file = path($folder)->child('series.xml');
        my $csv_file = path($folder)->child('hefte.txt');

        my $series_name;

        # if a XML file exist get the series name from it...
        if ( path($xml_file)->exists ) {
            $series_name = get_series_name( $xml_file );
            push @series_names, {series => $series_name, folder => $folder_name};
        }
        # otherwise use the 'deprecated' file hefte.txt to get the series name
        elsif ( path($csv_file )->exists ) {
            $series_name = get_series_name_from_CSV ( $csv_file );
            push @series_names, {series => $series_name, folder => $folder_name};
        }
    }
    return \@series_names;
}

1;