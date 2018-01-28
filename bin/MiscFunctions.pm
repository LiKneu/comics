package MiscFunctions;

#-------------------------------------------------------------------------------
#   Package holds miscellaneous functions
#   This package is the successor of seriezeigen.pl
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

use Time::Piece;

our @ISA = qw ( Exporter );

our @EXPORT = qw (
    read_db_settings
    get_last_edit_timestamp
    );

#------------------------------------------------------------------------------
#   Reads the settings for the different database fields from a file.
#   Stores the information in a hash of arrays.
#   The key holds the field/setting name and the array the respective list
#   of settings.
#
sub read_db_settings {
    my $config_file = './conf/db_settings.txt';

    open SETTINGS, '<', $config_file or die "Couldn't open $config_file: $!";
        my @settings = <SETTINGS>;
    close SETTINGS;

    my %HoA;
    my $heading;

    foreach ( @settings ) {
        my $line = $_;
        chomp $line;
        say $line;

        next if ( $line =~ /^\s*$/ );  # skip empty lines
        next if ( $line =~ /^\s*#/ );  # skip comment lines

        # get headers which are embraced in [ and ]
        if ( $line =~ /^\s*\[(.*)\]\s*$/ ) {
            $heading = $1;
            next;
        }
        # if it's not a heading then push the line onto the array which is
        # marked with the heading as key of the hash
        push (@{$HoA{$heading}}, $line);
    }
    return \%HoA;
}

#------------------------------------------------------------------------------
#   Reads the table headers which shall be displayed and their order from
#   the settings file and returns both information
#
sub get_table_header_settings {
    my $settings = shift;

    my $column;
    my @columns;
    my $heading;
    my $headings = {};

    my $header_order = $$settings{'Anzeige-Reihe'}; # TODO: change key to 'header order'

    foreach ( @$header_order ) {
        ( $column, $heading ) = split /,/, $_;
        push @columns, $column;
        if ( $heading ) {
            $$headings{$column} = $heading;
        }
    }
    return ( \@columns, $headings );    # TODO: is this also valid for usage with HTML::Template::Compiled?
}

#------------------------------------------------------------------------------
#   Evaluates the time stamp of the last write access to file series.xml
#   Returns the timestamp in format: DD.MM.YYYY HH:MM:SS
#
sub get_last_edit_timestamp {
    my $xml_file = shift;   # path to XML file of series

    my @file_info = stat ( $xml_file );

    my $t = localtime ( $file_info[9] );
    my $timestamp = $t->dmy( '.' ) . ' ' . $t->hms;

    return $timestamp;
}

1;