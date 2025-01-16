    
    $( document ).ready(function() {
             makeTag();
             //For when user goes into an agreement; this will disable links
             $('#versionAwareLinks>span>a').click(function(){
              return false;
             });
             $('#noneVersionAwareLinks>span>a').click(function(){
              return false;
             });
             $("#agreementOwner").change(function(){
                searchAgreementsNoError();
             });
             //enables agreement queue onchange
             refreshQueue(); 
             //enables document queue onchange
             documentOwnerOnchange();
    });


    function refreshQueue() {
        $("#agreementOwner").change(function(){
            var e = document.getElementById("j_id0:idBrowseSObjects:j_id14:j_id55_mlktp");
			if( e != null) {
				var e2 = document.getElementById("j_id0:idBrowseSObjects:j_id14:j_id55");
				var strUser = e.options[e.selectedIndex].value;
				if (strUser == "Q01I610000010C77" && e2 != null) {
				   e2.placeholder = 'Queue Name';
				 } else {
					e2.placeholder = 'Agreement Owner';
				 }
			}
            searchAgreementsNoError();
         });
        //$("[id$=mlktp]").hide(); 
    }

    function documentOwnerOnchange() {
        $("#documentOwner").change(function(){
            getSelectedAgreement();
        });
    }

    function addHtmlPlaceHolder(placeHolderTxt) {
		var e = document.getElementById("j_id0:idBrowseSObjects:j_id14:j_id55");
		if( e != null) {
			e.placeholder = placeHolderTxt;
		}
    }

    function searchDocument() {
        var inputVal = document.getElementById('documentSearch').value;
        getInputTag(inputVal);

    }

    function makeTagHelper(tagStr, placeHolder, errorMsg) {
      var tags = tagStr.split(',');
      if (tagStr != "") {
         $("#documentSearch").tagit({
          allowSpaces: true,
          showAutocompleteOnFocus: true,
          placeholderText: placeHolder,
          availableTags: tags,
          preprocessTag: function (val) {
            if (!val) {
                return '';
            }
            if (val.length < 2) {
              //alert(errorMsg);
              return '';
            }
            var values = val.split(",");
            if (values.length > 1) {
                for (var i = 0; i < values.length; i++) {
                    $("#documentSearch").tagit("createTag", values[i]);
                }
                return ''
            } else {
                return val
            }
          },
          afterTagAdded: function(event, ui) {
                      $('ul.ui-autocomplete').css("margin-top",'20px'); 
                      $('ul.tagit').css('margin-top','0px'); 
              searchDocument();
                    },
          afterTagRemoved: function(event, ui) {
                      if($('ul.tagit').height() == 25){
                          $('ul.ui-autocomplete').css("margin-top",'13px');
                          $('ul.tagit').css('margin-top','14px');
                      }else{
                          $('ul.ui-autocomplete').css("margin-top",'20px');
                      }
                      searchDocument();
          }
        });
      } else {
        $("#documentSearch").tagit({
          allowSpaces: true,
          showAutocompleteOnFocus: true,
          placeholderText: placeHolder,
          preprocessTag: function (val) {
            if (!val) {
                return '';
            }
            if (val.length < 2) {
              //alert(errorMsg);
              return '';
            }
            var values = val.split(",");
            if (values.length > 1) {
                for (var i = 0; i < values.length; i++) {
                    $("#documentSearch").tagit("createTag", values[i]);
                }
                return ''
            } else {
                return val
            }
          },
          afterTagAdded: function(event, ui) {
        $('ul.ui-autocomplete').css("margin-top",'20px');
                      $(".tagit-autocomplete").hide();  
                      $('ul.tagit').css('margin-top','0px');
              searchDocument();
            },
                  afterTagRemoved: function(event, ui) {
                      if($('ul.tagit').height() == 25){
                          $('ul.ui-autocomplete').css("margin-top",'13px');
                          $('ul.tagit').css('margin-top','14px');
                      }else{
                          $('ul.ui-autocomplete').css("margin-top",'20px');
                      }
                      searchDocument();
          }
        });
      }
    }

    function openDocument() {
      //alert('responseXml built');
    }

    /**
     * Callback after a partial page update
     */
    function afterPageUpdate() {
      
      // delay to allow the page to be rendered 
            setTimeout(function() {
              
              // callback the object
        try {
          window.external.PageRefreshed();
        } catch(ex) {
          // object not available
        }
            }, 0);
            onAjaxStop();
    }
    
    // register to invoke the function after the page load
      window.onload = function() { 
        // make the window visible
      try {
        window.external.MakeVisible();
      } catch(ex) {
        // object not available
      }
    
      }

      // function to handle the enter key
    function noenterAgreement(ev)  {
        if (window.event && (window.event.keyCode == 13 || ev.which == 13)) {
          searchAgreements();
            return false;
            
         } else {
              return true;
              
         }
         
    }



    // function to handle the enter key
    function noenterDocument(ev)  {
        if (window.event && (window.event.keyCode == 13 || ev.which == 13)) {
          getSelectedAgreement();
            return false;
            
         } else {
              return true;
              
         }
         
    }

     