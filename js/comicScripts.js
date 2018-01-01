/*------------------------------------------------------------------------------
    Script: comicScrpts.js

    Used by:
        Template: new_series.tmpl
------------------------------------------------------------------------------*/

//  This function derives the folder name of the new series from its title
function getFolderName( series_name ) {
    // change all characters to lowercase
    var folderName = series_name.toLowerCase();
    // remove all not allowed characters from the folder name
    folderName = folderName.replace(/[,;.:#'+*~!?"§$%&/()={}\\`´]/g,"");
    // replace all whitespace with '_'
    folderName = folderName.replace(/\s+/g, "_");
    // replace German Umlaute
    folderName = folderName.replace(/ä/g, "ae");
    folderName = folderName.replace(/ö/g, "oe");
    folderName = folderName.replace(/ü/g, "ue");
    folderName = folderName.replace(/ß/g, "ss");

    document.getElementById('input_folder').value = folderName;
}

//  This function calls the perl function which creates a new folder for
//    a new series
function callPerlNewSeries () {
    var seriesName = document.getElementById('input_series').value;
    var folderName = document.getElementById('input_folder').value;
    var seriesURL = "./new_series.pl?series=" + seriesName +  "&folder=" + folderName + "&action=create";
    // adds the information about folder name and name of the series to the
    // link of the perl script
    document.getElementById('lnk_create_series').href = seriesURL;
}