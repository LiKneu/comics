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
    read_series_XML_2_DOM
    calculate_sum_prices
    is_series_complete
    get_number_of_issues
    get_series_name
    get_series_names
    convert_series_field_names
    AoH_2_XML
    );

#-------------------------------------------------------------------------------
#   Reads the xml file of the series into a DOM structure
#
sub read_series_XML_2_DOM {
    my $path_to_series = shift;

    my $dom = XML::LibXML->load_xml(location => $path_to_series);

    # the following two steps are necessary to remove the whitspace added by
    # XML::LibXML::PrettyPrint during generation of the XML file
    my $pp = XML::LibXML::PrettyPrint->new();
    $pp->strip_whitespace($dom);

    return $dom;
}

#-------------------------------------------------------------------------------
#   Calculates the sum of the money depending on the field name which is given
#   as parameter e.g. 'price', 'price_bought', 'present_price_trade'
#
sub calculate_sum_prices {
    # TODO: Make handling of different currencies configurable (exchange rate)
    my $dom = shift;    # DOM structure of the series
    my $field = shift;  # field which has to be summed up

    my @warnings_issue;     # array which will hold information about incomplete data
                            # set information like exchange rates or missing prices
    my @warnings_currency;  # same like above but for unknown currencies

    my $sum = 0;
    foreach my $issue ( $dom->findnodes ( '//issue' ) ) {
        my $hit = $issue->findvalue ( './' . $field );
        my $issue_no = $issue->findvalue ( './number');

        # the prices are stored as strings including the currency
        # so before calculation the sum we have to split the numbers
        # from the currency information
        my ( $price, $currency ) = split / /, $hit;

        # if there seems to be price information starting with a number
        if ( $price && $price =~ /^[1-9]/ ) {
            # to allow perl the summation w/o throwing a warning we have to
            # replace , by .
            $price =~ s/,/\./;  # replace , by . to show perl that price is number

            # handle different currencies besides EUR
            if ( $currency ) {
                if ($currency =~ 'DEM') {
                    $price *= 0.51129;
                    $sum += $price
                }
                elsif ($currency =~ 'EUR') {
                    $sum += $price;
                }
                else {
                    push @warnings_currency, $currency;
                }
            }
        }
        # otherwise the price seems not to be a valid price or doesn't exist
        else {
            # no price available - so add issue number to warning array
            push (@warnings_issue, $issue_no);
        }
    }

    $sum = sprintf "%.2f Euro", $sum;
    # replace . by , to show the sum of prices as it is expected by Europeans
    $sum =~ s/\./,/;

    my $missing_issue_price;
    if ( @warnings_issue ) {
        $missing_issue_price = join ', ', @warnings_issue;
        $missing_issue_price = 'Prices for following issues are missing: '
            . $missing_issue_price;
    }

    my $missing_currency;
    if ( @warnings_currency ) {
        $missing_currency = join ', ', @warnings_currency;
        $missing_currency = 'Exchange rates for following currencies missing: '
            . $missing_currency;
    }

    return $sum, $missing_issue_price, $missing_currency;
}

#-------------------------------------------------------------------------------
#   Evaluates whether a series is complete i.e. for each of all possible
#   issues at least one comic book is available on stock.
#
sub is_series_complete {
    my $series_dom = shift;

    my @missing;    # array which will hold the numbers of the missing issues
                    # if max number of issues can't be determined the array will
                    # hold an error message in $missing[0]

    # determine how many of the issue titles are available
    my $available_issues;
    foreach my $status ( $series_dom->findnodes ( '//status') ) {
        $available_issues ++ if $status->to_literal =~ /vorhanden/i;
    }

    # get the biggest number of issues which belong to this series
    my $max_number_of = 0;
    foreach my $issue ( $series_dom->findnodes ( '//issue' ) ) {
        my $number_of = $issue->findvalue ( './number_of' );
        if ( $number_of ) {
            $max_number_of = $number_of if $number_of > $max_number_of
        }
    }

    # if we have a bigger number of issue titles in the collection than
    # the max number of issues, we know that something is wrong
    # so we can't determin whether the series is complete or not
    if ( $available_issues > $max_number_of ) {
        push @missing, "can't determine completeness";
        return \@missing;
    }

    # for each issue which should be available in the series generate
    # a key in the hash
    my %should_have_issues;
    foreach ( 1..$max_number_of ) {
        $should_have_issues{$_} = '';
    }

    # for existing issues remove the key from the hash
    foreach my $issue ( $series_dom->findnodes ( '//issue' ) ) {
        my $issue_status = $issue->findvalue ( './status' );

        # TODO: make the word, which indicates availability of an issue configurable
        if (  $issue_status =~ /vorhanden/i ) {

            # get the number of the existing issue
            my $issue_number = $issue->findvalue ( './number' );

            # remove the issue from the hash
            delete $should_have_issues{ $issue_number };
        }
    }

    # let's see which issues are missing in the series by finding out
    # which keys are still available in the hash
    @missing = sort ( { $a <=> $b } keys %should_have_issues );

    # return missing issues
    return \@missing;
}

#-------------------------------------------------------------------------------
#   Gets the total number of issues on stock which belong to a series.
#   CAUTION: The number includes doublettes (not only unique titles)
#
sub get_number_of_issues {
    my $series_dom = shift;

    my $number_of_issues = 0;
    foreach my $issue ( $series_dom->findnodes ( '//issue' ) ) {
        # TODO: make the word, which indicates availability of an issue configurable
        if ( $issue->findvalue ( './status' ) =~ /vorhanden/i ) {
            my $copies = $issue->findvalue ( './copies' );
            $number_of_issues += $copies if $copies;
        }
    }

    return $number_of_issues;
}

#-------------------------------------------------------------------------------
#   Gets the name of the series from file series.xml
#
sub get_series_name {
    my $series_dom = shift;
    return $series_dom->findvalue('/series/name');
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
            my $series_dom = read_series_XML_2_DOM( $xml_file );
            $series_name = $series_dom->findvalue('/series/name');
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
    my $data = shift;           # the AoH of series information
    my $mapping_table = shift;  # the hash holding the mapping rules

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