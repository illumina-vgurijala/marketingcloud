var searchObjects;
var queryTerm;

/**
  * fieldAutocomplete searches for all input elements with the class searchBoxClass and adds an autocomplete. 
  * the script is called when idPredicatesSection is rendered/rerendered. 
  *  
  *
  * minLength: minimum length required for autocomplete
  * source: retrieves list of products and field names similar to search term greater than or equal to minLength
  * focus: updates value in search field when a autocomplete item is focused on
  * select: updates value in search field when a autocomplete item is selected and updates id field to store api name in
  *         json 
  */
function fieldAutocomplete(actionType) {
    
    if(document.getElementsByClassName('searchBoxClass').length > 0) {


        var attributesSearch = function(request,response) {
            queryTerm = request.term;
                
                if(actionType == null) {
                    Visualforce.remoting.Manager
                        .invokeAction(j$.APTTUS.RemoteController.getSimilarFields, queryTerm, function(result, event){
                            if (event.status) {
                                searchObjects = result;
                                response(searchObjects);
                            } else {
                                alert(event.message);
                            }
                        });
                } else {
                    Visualforce.remoting.Manager
                        .invokeAction(j$.APTTUS.RemoteController.getSimilarFields, queryTerm, actionType, function(result, event){
                            if (event.status) {
                                searchObjects = result;
                                response(searchObjects);
                            } else {
                                alert(event.message);
                            }
                        });
                }
        }

        var onAddSingleSelectedItem = function ($hiddenInput, item) {
            $hiddenInput.val(item.value );
            $hiddenInput.next().val(item.label);
        }
        
        j$(".searchBoxClass").each(function(){
            var $hiddenInput = j$(this).next()
            var attributeSelectPicklist = j$(this).multipickSearch({
                lblResultsItemsTitle: j$.APTTUS.AVAILABLE_ITEMS,
                lblSelectedItemsTitle: j$.APTTUS.SELECTED_ITEMS,
                lblClose: j$.APTTUS.CLOSE,
                lblNoResults: j$.APTTUS.NO_RESULTS,
                multipick : false , 
                showMenu: true,
                showRecentItems: false,
                dataSourceFunction: function(request, response) {
                    attributesSearch(request, response);
                },
                defaultAvailableView : true,
                  defaultResults: function (request, response) {
                    request.term = "";
                    attributesSearch(request, response);
                },
                onItemSelected: function (settings, item) {
                    onAddSingleSelectedItem($hiddenInput, item);
                },
                onDelete: function (settings, item) { // remove item from selected list
                    $hiddenInput.val("");
                    $hiddenInput.next().val("");

                }
            });

 // set the selectedItem
            if($hiddenInput.val() != '') {
                attributeSelectPicklist.multipickSearch("setSelectedItems", [{label: $hiddenInput.next().val(), value: $hiddenInput.val()}]);

                attributeSelectPicklist.val($hiddenInput.next().val());
                    if($hiddenInput.next().val() != ''){
                        // show the cross icon
                        j$(this).parent().find(".cancel-btn").show().attr("style", "display:inline-block").parent().attr("style", "display:inline-block");
                }
            }
               
                

         }); 
    }


    };
