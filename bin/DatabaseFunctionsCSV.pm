package DatabaseFunctionsCSV;
#-------------------------------------------------------------------------------
#   Package holds functions needed to handle comic book information stored
#   in CSV file hefte.txt
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

use Text::CSV;

require Exporter;

our @ISA = qw ( Exporter );

our @EXPORT = qw (
    get_series_name_from_CSV
    );

sub get_series_name_from_CSV {
    my $path_to_CSV = shift;

    # read the whole series line by line into an array holding the issues
    open (SERIES, "<", $path_to_CSV) or die "Couldn't open $path_to_CSV: $?";
    my @issues = <SERIES>;
    close(SERIES);

    # create new CSV object
    my $csv = Text::CSV->new(
        { binary 			=> 1,       # alle codes allowed
            eol    			=> $\,      # set newline according to OS
            allow_whitespace 	=> 1,	# allow whitespace between fields
            quote_char		=> '"',     # set type of quotation marks
            sep_char			=> ',',	# set character for field separation
        });

    # split the fields of the first line holding issue information into its
    # data fields
    if ($csv->parse($issues[1]))
    {
        my @fields = $csv->fields();
        return $fields[36]; # field 36 should hold the name of the series
    }
    else
    {
        # If we have to return undef it is most likely that no data sets of
        # comic book issues exist jet.
        # Maybe only excerpts (Leseproben) existieren.
        return undef;
    }
}

1;