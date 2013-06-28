// 
// This file shows the minimum you need to provide to BookReader to display a book
//
// Copyright(c)2008-2009 Internet Archive. Software license AGPL version 3.

// Create the BookReader object
br = new BookReader();

// Return the width of a given page.  Here we assume all images are 800 pixels wide
br.getPageWidth = function(index) {
    return 800;
}

// Return the height of a given page.  Here we assume all images are 1200 pixels high
br.getPageHeight = function(index) {
    return 1200;
}

br.getOID = function() {
    if (window.location.search.length==0) {
	return "";
    }
    var oid_param = window.location.search.substr(1);
    var oid_split = oid_param.split("=");
    return oid_split[1];
}  
// We load the images from archive.org -- you can modify this function to retrieve images
// using a different URL structure
    getZTotal = function(oid) {
      var solrq = "/pagination/numofpages?oid="+oid
      console.log("solrZTotalQ:"+solrq);
      var result;
      $.ajax(
      {
         async: false,
         type: 'GET',
	 dataType: 'json',
	 url: solrq,
	 success: function(data)
         {
            console.log("SUCCESS:"+data.docs[0].ztotal_isi);
            result = data.docs[0].ztotal_isi; 
         },
	 error: function(xhr,ajaxOptions,thrownError) 
         { 
            alert(xhr.status+"-"+thrownError)
         }
       }
      );
      console.log("AJAX:"+result);
      return result;
    }

    //data = the result returned from the server in type 'json'. It is of type array
    //Example:
    //{"numFound":8,"start":0,"docs":[{"id":"libserver7:3"},{"id":"libserver7:4"},{"id":"libserver7:5"},{"id":"libserver7:6"},{"id":"libserver7:7"},{"id":"libserver7:8"},{"id":"libserver7:9"},{"id":"libserver7:10"}]}
    getPID = function(parentoid,index) {
      var solrq = "/pagination?oid="+parentoid+"&zi="+index
      //var solrq = "/pagination?oid="+parentoid+"&zi="+(index + 1)
      console.log("SOLRQ:"+solrq);
      var result;
      $.ajax(
      {
         async: false,
         type: 'GET',
         dataType: 'json',
         url: solrq,
         success: function(data) 
         { 
            console.log("SUCCESS:"+data.docs[0].id + " numFound: " + data.numFound); 
            result = data.docs[0].id;
         },
         error: function(xhr,ajaxOptions,thrownError) 
         { 
            alert(xhr.status+"-"+thrownError)
         }
      }
      );
      console.log("AJAX:"+result);
      return result;
    }
br.getPageURI = function(index, reduce, rotate) {
    // reduce and rotate are ignored in this simple implementation, but we
    // could e.g. look at reduce and load images from a different directory
    // or pass the information to an image server
    var netid = "0";
    var session = "0";
    console.log("index:"+index);
    console.log("OID_PARAM:"+br.getOID());
    //Don't think the next three lines are needed
    var leafStr = '000';            
    var imgStr = (index+1).toString();
    var re = new RegExp("0{"+imgStr.length+"}$");
    //var url = 'http://www.archive.org/download/BookReader/img/page'+leafStr.replace(re, imgStr) + '.jpg';
    //parentoid = "10590519";
    parentoid = br.getOID();
    index = index+1;
    pid = getPID(parentoid,index);
    console.log("pid:"+pid);
    //remove later
    //var url = "http://libserver3.yale.edu:8983/fedora/objects/"+pid+"/datastreams/jpg/content";
    var url = "http://imageserver.library.yale.edu/libserver7.yale.edu:8983/"+pid+"/"+netid+"/"+session+"/227/111/132/130/500.jpg";
    return url;
}

br.gettran = function() {
//return true of false based on results from solr query
    console.log("In gettran");
    //return lr for LTR and rl for RTL
    //return 'rl';
    //parentoid = getOIDturn();
    var solrq = "/pagination/transcript?oid="+this.parentoid
    console.log("SOLRQ:"+solrq);
    var transcript = "false";
    $.ajax(
    {
        async: false,
        type: 'GET',
        dataType: 'json',
        url: solrq,
        success: function(data) 
        { 
           console.log("SUCCESS:"+ data); 
           transcript = data;
        },
        error: function(xhr,ajaxOptions,thrownError) 
        { 
           alert(xhr.status+"-"+thrownError)
        }
     }
     );
      console.log("AJAX: transcript is: "+transcript);
     return transcript;;
  //OR, maybe set a variable. Then check the value of that variable to determine if 
  //button should be displayed
}

// Return which side, left or right, that a given page should be displayed on
br.getPageSide = function(index) {
    if (0 == (index & 0x1)) {
        return 'R';
    } else {
        return 'L';
    }
}

// This function returns the left and right indices for the user-visible
// spread that contains the given index.  The return values may be
// null if there is no facing page or the index is invalid.
br.getSpreadIndices = function(pindex) {
    var spreadIndices = [null, null]; 
    if ('rl' == this.pageProgression) {
        // Right to Left
        if (this.getPageSide(pindex) == 'R') {
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex + 1;
        } else {
            // Given index was LHS
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex - 1;
        }
    } else {
        // Left to right
        if (this.getPageSide(pindex) == 'L') {
            spreadIndices[0] = pindex;
            spreadIndices[1] = pindex + 1;
        } else {
            // Given index was RHS
            spreadIndices[1] = pindex;
            spreadIndices[0] = pindex - 1;
        }
    }
    
    return spreadIndices;
}

// For a given "accessible page index" return the page number in the book.
//
// For example, index 5 might correspond to "Page 1" if there is front matter such
// as a title page and table of contents.
br.getPageNum = function(index) {
    return index+1;
}

br.setrtl = function() {
    turndir = 'rl'
    console.log("in set rtl with turndir=" + turndir);
    this.setPageProgression(turndir);
}

br.setltr = function()
{
    turndir = 'lr'
    console.log("in set ltr with turndir=" + turndir);
    this.setPageProgression(turndir);
}

// Total number of leafs
//br.numLeafs = 15;
//br.numLeafs = getZTotal(10590519);
br.numLeafs = getZTotal(br.getOID());

// Book title and the URL used for the book title link
br.bookTitle= 'Yale Universitys BookReader Application';
// Will need the link to the metadata title of the object
br.bookUrl  = 'http://openlibrary.org';

// Override the path used to find UI images
br.imagesBaseURL = '../BookReader/images/';

br.transTitle = 'Transcript';
//br.pageturnTitle = "Right to Left Turning";
br.turnRTL = "Right to Left Turning";
br.turnLTR = "Left to Right Turning"
br.transUrl = 'http://www.yale.edu';

br.getEmbedCode = function(frameWidth, frameHeight, viewParams) {
    return "Embed code not supported in bookreader demo.";
}


// Let's go!
br.init();

// read-aloud and search need backend compenents and are not supported in the demo
$('#BRtoolbar').find('.read').hide();
$('#textSrch').hide();
$('#btnSrch').hide();

//Make a condition here. If no transcript is available the hide
//$('#BRtrans').hide();
