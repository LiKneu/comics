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
    convert_series_field_names
    AoH_2_XML
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

#-------------------------------------------------------------------------------
#   Stores array of hashes as XML file on disc.
#   Detects German keys and converts them to English XML tags before storing
#   the file.
#   If English keys are used no conversion is done.
#
sub AoH_2_XML {
    my $data = shift;       # data structure to be converted to xml
    my $series_name = shift;
    my $filename = shift;   # path where to store the xml output

#    my $series_name = shift @$data; # get and remove the name of the series
    # from the array

    # create document header
    my $dom = XML::LibXML::Document->new('1.0', 'UTF-8');

    # create root element of the series
    my $series = $dom->createElement('series');
    $dom->setDocumentElement($series);

    # add node with the name of the series
    my $node = $series->addNewChild( undef, 'name');
    $node->appendTextNode( $series_name );

    # add an element for each issue in the array to the series node
    foreach my $issue ( @$data ) {
        my $issue_node = $series->addNewChild( undef, 'issue' );

        # add all fields to the issue element
        foreach my $key ( keys %$issue ) {
            my $field_node = $issue_node->addNewChild(undef, $key );
            $field_node->appendTextNode( $issue->{ $key } );
        }
    }

    # if a filename is given store XML structure to disc
    if ( $filename ) {

        # format xml file so that is easier to read by humans
        my $pp = XML::LibXML::PrettyPrint->new();
        $pp->pretty_print($dom); # modified in-place

#        open my $out, '>:utf8', $filename or die "Couldn't open $filename: $!";
        open my $out, '>', $filename or die "Couldn't open $filename: $!";
        print $out $dom->toString;
        close $out;
    }
    # otherwise return the structure
    else {
        return $dom;
    }
}

#-------------------------------------------------------------------------------
#   Reads the mapping table and returns a hash
#       key: can be chosen according to the required mapping e.g.:
#            comic_keeper = German field names based on the ComicKeeper database
#            splitter = field names as they are found on the Splitter web page
#       value:  name of the English xml element which is the leading field name
#
sub read_mapping {
    my $path_to_mapping_file = shift;   # path to the mapping file
    my $mapping = shift;  # name of the mapping e.g. comic_keeper, splitter

    my $maps = {};  # hash for element names and mapping information

    my $xml = XML::LibXML->load_xml(location => $path_to_mapping_file)
        or die "cannot read file: $!";

    # for all nodes below the root node/element 'field_mapping_table'
    foreach my $node ($xml->findnodes('/field_mapping_table/*')) {
        # findvalue: content of the element
        # localName: name of the element
        $maps->{$node->findvalue($mapping)} = $node->localName()
    }

    return $maps;
}

#-------------------------------------------------------------------------------
#   Takes AoH with information of a comic book series and converts the keys
#   into the standardized English ones if necessary.
#   It is assumed that the user hands over a mapping fitting to the data
sub convert_series_field_names {
    my $data = shift;       # the AoH of series information
    my $mapping_table = shift;    # the hash holding the mapping rules

    my $mapped_data = [];   # array which will hold the data with standard
                            # English field names

    foreach my $issue ( @$data ) {
        my %tmp_hash;
        foreach my $key ( sort keys %$mapping_table ) {
            $tmp_hash{$mapping_table->{$key}} = $issue->{$key};
        }
        push @$mapped_data, \%tmp_hash;
    }

    return $mapped_data;
}

1;