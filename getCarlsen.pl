#!/usr/bin/perl

#-------------------------------------------------------------------------------
# Script: Carlsen
#
# Function:
#   Controls the download of information of the website of the publisher
#   Splitter
#-------------------------------------------------------------------------------

use strict;
use warnings;
use 5.18.0;

use Data::Dumper;

use lib::Basics;
use lib::FromWeb;
use lib::FromCarlsen;
use lib::FromSplitter;

my $VERSION = '26-04-2017';

my $url;

my $comic_info = lib::Basics::set_default_comic_data;

#$url = 'https://www.carlsen.de/softcover/xiii-mystery-1-mangouste/27721';
$url = 'https://www.carlsen.de/softcover/die-adler-roms-die-adler-roms-4/37575';

# download the webpage give by the URL and store it in $dom
my $dom = lib::FromWeb::get_dom( $url );

# parse the downloaded webpage and return a hash with detailed comic book information
$comic_info = lib::FromCarlsen::get_details_Carlsen( $dom, $comic_info );

say Dumper $comic_info;

# write the comic book information in a CSV file
lib::Basics::write_CSV( $comic_info, './tmp/heft.txt' );

# download the cover image
my $localfiles = lib::FromCarlsen::get_images_Carlsen( $dom, $comic_info->{'Link zum Cover'} );

exit;
