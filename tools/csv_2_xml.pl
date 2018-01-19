#!c:/strawberry/perl/bin/perl

#-------------------------------------------------------------------------------
# Script: csv_2_xml.pl
#
# Function:
#   This is just a helper-script which converts the comic data stored in the
#   CSV file ANSI (more specific cp1252) encoded into XML file UTF-8 encoded.
#   After conversion from CSV to XML this script isn't useful anymore.
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

use Data::Dumper;
use Path::Tiny;

use DatabaseFunctionsCSV;
use DatabaseFunctionsXML;

# define path to comic database here
my $path_to_comic_database = './data';

convert_series_2_XML( $path_to_comic_database );

exit;

#-------------------------------------------------------------------------------
#   Loop through all directories which hold comic series information and convert
#   the CSV series files into XML files.
#
sub convert_series_2_XML {
    my $path_to_database = shift;

    my $mapping = DatabaseFunctionsXML::read_mapping( './conf/field_mapping_table.xml', 'comic_keeper');

    # get all 1st level folders in the database
    my @folders = path($path_to_database)->children;

    foreach my $folder ( @folders ) {

        # get just the name of the folder not the full path of the series
        my $folder_name = path($folder)->basename;
        say "Folder: " . $folder;

        my $xml_file = path($folder)->child('series.xml');
        my $csv_file = path($folder)->child('hefte.txt');

        my $series_name = get_series_name_from_CSV( $csv_file);
        say "Series: " . $series_name;

        my $data = csv_2_AoH( $folder );
        my $mapped_data = convert_series_field_names( $data, $mapping );

        say "Found information about comic books (issues) of this series:";
        say Dumper $mapped_data;

        # write XML to disc
        my $xml = AoH_2_XML( $mapped_data, $series_name, $xml_file ) if $series_name;

        say "\n";
    }
}