package FormFunctions;

#-------------------------------------------------------------------------------
#   Package holds functions needed to handle HTML forms
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.24.0;

require Exporter;

our @ISA = qw ( Exporter );

our @EXPORT = qw (
    parse_form
    );

#-------------------------------------------------------------------------------
#   Function parses the information returned from HTML forms which are encoded
#   in the URL
#
sub parse_form {
    my ($buffer, @pairs, $pair, $name, $value);

    my %form;   # hash which will hold the name-value pairs from the HTML-form

    # read text
    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
        read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    }
    else
    {
        $buffer = $ENV{'QUERY_STRING'};
    }
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
        # split name-value pairs
        ($name, $value) = split(/=/, $pair);
        # insert spaces again
        $value =~ tr/+/ /;
        # replace URL-encoded characters (%xx)
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        # save to hash
        if (defined $form{$name})	# most probably checkbox
        {
            $form{$name} = $form{$name} . ", " . $value;
        }
        else
        {
            $form{$name} = $value;
        }
    }
    return \%form;
}

1;