var zipFile = new JSZip();
var j$ = jQuery.noConflict();
var downloadUrl;
var totalFileSizeCounter = 0;
var selElem;
var selectedFileIds = [];

/*
 * apply slds styling to recordtype list component.
 * append --None-- as one of the record type values.
 * set the default record type value if passed.
 */
function initializeRecordTypeElement(recordTypeName) {
	
	//get the record type drop down.
	selElem = j$('.selectRecordType').children().children('select');
	
	//add slds select style to recordtypeList component
	j$('.selectRecordType').children().children('select').addClass('slds-select');
	
	//append none as value.
	selElem.prepend("<option value='--None--'>--None--</option>");  
	
	//set the recordtype if passed from page.	
	selElem.find('option:contains("' + recordTypeName + '")').attr('selected', 'selected');
}
		 
/*
 * add eventlistener for enter key press on search input text.		
 */
j$(document).on("keypress", ".search-text", 
  function() { 
	if(event.keyCode == 13){ 
		j$(".search-button").trigger('click'); 
		return false; 
	}
});

/*
 * add eventlistener for expand/collapse  filters section.
 */
j$(document).on("click", ".toggleFilter", 
  function() { 
	j$(this).parent().toggleClass('slds-is-open');
	if(!j$(this).parent().hasClass('slds-is-open')){
		j$(this).parent().find('.searchFilterSection').show();
		j$(this).parent().find('.expandFilter').show();
		j$(this).parent().find('.collapseFilter').hide();
	}else{
		j$(this).parent().find('.searchFilterSection').hide();
		j$(this).parent().find('.expandFilter').hide();
		j$(this).parent().find('.collapseFilter').show();
	}	
});

/*
 * expand/collapse agreement detail section.
 */
function expandCollapse(hideClass) {
	j$('.'+hideClass).toggleClass('agreementExpandCollapse');        
	if(j$('.'+hideClass).hasClass('agreementExpandCollapse')){
		j$('.'+hideClass+'-content').show(400);        
		j$('.'+hideClass+'-expand').show();
		j$('.'+hideClass+'-collapse').hide();
	}else{
		j$('.'+hideClass+'-content').hide(400);        
		j$('.'+hideClass+'-expand').hide();
		j$('.'+hideClass+'-collapse').show();
	}        
}

/*
 * expand/collapse file highlight div section.
 */
function expandFileCollapse(hideClass) {		
	j$('.'+hideClass).toggleClass('fileExpandCollapse');        
	if(j$('.'+hideClass).hasClass('fileExpandCollapse')){
		j$('.'+hideClass+'-content').hide();        
		j$('.'+hideClass+'-expand').hide();
		j$('.'+hideClass+'-collapse').show();
	}else{
		j$('.'+hideClass+'-content').show();        
		j$('.'+hideClass+'-expand').show();
		j$('.'+hideClass+'-collapse').hide();
	}        
}

/*
 * reset the values after render.
 */
function onRenderComplete(bytes, maxSize) {             
	totalFileSizeCounter = 0 ;
	j$("#totalFileSizeCounter").html(0 + ' '+ bytes +'/'+ maxSize); 
	j$(".emailIcon").prop( "disabled", true ); 
	j$('.collapseIcon').hide();
	j$('.expandFileIcon').hide();
}

/*
 * function to clear the search filters.
 */
function clearFilters() {
	
	// set record type to --None--.
    selElem.val("--None--");
	
	//empty the account field.
    j$('.accountId').val("");
}

/*
 * load the blob to pdf.js for searching and highlighting matched text.
 */
function loadPDFJS(blobDocumentContent, docId, searchString, highlightErrorMessage) {
	var loading = PDFJS.getDocument({
		data: atob(blobDocumentContent)
	});

	loading.promise.then(function(doc) {
		var results = [];
		
		//handle the highlighting for keyword search characters (* and ?)
		if (searchString.indexOf("*") >= 0) {
			searchString = searchString.split("*").join("");
		}
		if (searchString.indexOf("?") >= 0) {
			searchString = searchString.split("?").join("");
		}
		
		for (var i = 1; i <= doc.numPages; i++) {
			results.push(searchPage(doc, i, searchString));
		}
		
		return Promise.all(results);
	}).then(function(searchResults) {
		document.getElementById('searchText' + docId).innerHTML = '';
		
		var divMsg = document.createElement('div');
		divMsg.innerHTML = highlightErrorMessage;
		divMsg.className = "errorCls";
		
		// Display results using divs
		searchResults.forEach(function(result) {
			var div = document.createElement('div');
			
			result.items.forEach(function(s) {
				if (s != null && s != '') {
					div.className = "pr";
					var span1 = document.createElement('span');
					span1.className = "prl";

					var span2 = document.createElement('span');
					span2.className = "prl2";

					span2.textContent = 'Page-' + result.page;

					var replaceD = "<span class='highlight'>" + searchString + "</span>";
					
					s = s.replace(new RegExp(searchString.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), "ig"), replaceD);

					span1.innerHTML = s;
					
					divMsg.className = 'slds-hide';
					div.appendChild(span1);
					div.appendChild(span2);
					var hr = document.createElement('hr');
					div.appendChild(hr);
				}


			});

			document.getElementById('searchText' + docId).appendChild(div);
			document.getElementById('searchText' + docId).appendChild(divMsg);
		});
	}).catch(console.error);
	j$('.loading_spinner').hide();
}

/*
 * look for the searchtext and split the sentence based on regex below.
 */
function searchPage(doc, pageNumber, searchText) {
    return doc.getPage(pageNumber).then(function(page) {
        return page.getTextContent();
    }).then(function(content) {
		
        // Search combined text content using regular expression
        var text = content.items.map(function(i) {
            return i.str;
        }).join('');

        var re = new RegExp("(.{0,70})" + searchText.replace(/[.*+?^${}()|[\]\\]/g, '\\\$&') + "(.{0,70})", "gi"),
            m;
        var lines = [];
        while (m = re.exec(text)) {
            var line = (m[1] ? "..." : "") + m[0] + (m[2] ? "..." : "");
            lines.push(line);
        }
        return {
            page: pageNumber,
            items: lines
        };
    });
}

/*
 * validate the search text entered.
 * display error meesage if characters entered less than 2.
 */
function validateSearchContent(searchString) {
    j$('#searchDivId').addClass('slds-is-open');
    j$('.searchFilterSection').hide();
    j$('.expandFilter').hide();
    j$('.collapseFilter').show();
	
    document.getElementById('minimumCharactersErrorMessage').style.display = 'none';
    document.getElementById('minCharswithSpecialCharactersErrorMessage').style.display = 'none';
    document.getElementById('resultsDiv').style.display = 'block';
	
    var searchString = document.getElementById(searchString).value;
    var searchStringoriginal = searchString;

    if(searchString.indexOf('*') >= 0 || searchString.indexOf('?') >= 0 || searchString.indexOf('(') >= 0 || searchString.indexOf(')') >= 0 ||
        searchString.indexOf('"') >= 0) {
        searchString = searchString.replace(/[*?()"]/g, '');
        if (searchString.length < 2) {
            document.getElementById('resultsDiv').style.display = 'none';
            document.getElementById('minCharswithSpecialCharactersErrorMessage').style.display = 'block';
            j$('.loading_spinner').hide();
        } 
		else {
			//on successful validation, call the search function
            searchContent(searchStringoriginal, selElem.find("option:selected").text(), j$('.accountId').val());
        }
    } 
	else if(searchString.length < 2) {
        document.getElementById('resultsDiv').style.display = 'none';
        document.getElementById('minimumCharactersErrorMessage').style.display = 'block';
        j$('.loading_spinner').hide();
    } 
	else {
		//on successful validation, call the search function
        searchContent(searchStringoriginal, selElem.find("option:selected").text(), j$('.accountId').val());

    }
}
