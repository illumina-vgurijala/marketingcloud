/**
 * Apttus Config & Pricing
 * JavaScript resource for PublishFavoriteInline VF page.
 * 
 * Copyright (c) 2016, Apttus Inc. All rights reserved.
 */
j$(document).ready(function() {
    var $priceListHiddenCtrl = j$("[id$=idPriceListScopeHidden]"),
    priceListsRetrievalMethod = function(request, response) {
        Visualforce.remoting.Manager.invokeAction(
        	j$.APTTUS.RemoteController.searchPriceLists, 
            request.term,
            j$.APTTUS.FavoriteConfigurationId,
            function(result, event) {
                if(event.type == 'exception') {
                    console.log(event.message);
                } else {
                    response(normalizeData(result, "Name", "Id"));
                }
            },
            {escape:false});
    };
    var priceListMultiPicklist = j$("[id$=idPriceListSearch]").multipickSearch({
        lblResultsItemsTitle: j$.APTTUS.Labels.AvailableItems,
        lblSelectedItemsTitle: j$.APTTUS.Labels.SelectedItems,
        lblClose: j$.APTTUS.Labels.Close,
        lblNoResults: j$.APTTUS.Labels.NoResultsAvailable,
        dataSourceFunction: priceListsRetrievalMethod,
        defaultResults: function(request, response) { 
            request.term = "";
            priceListsRetrievalMethod(request, response);
        },
        onItemSelected: function(settings, item){
            onAddSelectedItem($priceListHiddenCtrl, item.value);
        },
        onDelete: function(settings, item){
            onDeleteEvent(item.value, "idPriceListScopeHidden");
        }
    });

    populatePublishedPriceLists();

});

// function to refresh the page, only if there is no error
function refresh() {
	// identify presence of DOM to see any error/exception
	if (j$("[class~='message'][role='alert']").length == 0) {
	    window.top.location = '/' + j$.APTTUS.FavoriteConfigurationId;
	}
}