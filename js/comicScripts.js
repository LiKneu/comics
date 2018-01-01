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

//  This function filters the table of all comic series according to the search
//  string given in an input field.
//  Function taken from: https://www.w3schools.com/howto/howto_js_filter_table.asp
function filterSeriesTable() {
  // Declare variables
  var input, filter, table, tr, td, i;
  input = document.getElementById("searchInput");
  filter = input.value.toUpperCase();
  table = document.getElementById("tableOfSeries");
  tr = table.getElementsByTagName("tr");

  // Loop through all table rows, and hide those who don't match the search query
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[0];
    if (td) {
      if (td.innerHTML.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }
  }
}