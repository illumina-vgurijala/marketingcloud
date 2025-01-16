// This to make sure jQuery doesn't conflict with any other JS libraries
j$ = jQuery.noConflict();

var categoriesNum;
var categoryNames = new Array();
var categoryMap = {};
var catalogProducts = new Array();
var productNames = new Array();
var ignoreTap = false;
var selectedProductIds = new Array();
var cartProductIds = {};
var excludedProductIds = new Array();
var categoryProductResults = new Array();
var constraintRuleResults;
var listWindow;
var searchResultsWindow;
var window_height;
var sticky_offset;
var productPages = [];
var pageSize = 10;

var categoriesTreeLoaded = false;

var dealRatings = {};
dealRatings['green'] = {value:0,styleClass:'glyphicon apttusIcon-circle green',label:'Good'};
dealRatings['yellow'] = {value:1,styleClass:'glyphicon apttusIcon-circle yellow',label:'Average'};
dealRatings['orange'] = {value:2,styleClass:'glyphicon apttusIcon-circle orange',label:'Moderate'};
dealRatings['red'] = {value:3,styleClass:'glyphicon apttusIcon-circle red',label:'Critical'};

 
// dealRatings['green'] = {value:0,styleClass:' icon-success',label:'Good'};
// dealRatings['yellow'] = {value:1,styleClass:' icon-warning',label:'Average'};
// dealRatings['orange'] = {value:2,styleClass:' icon-danger',label:'Moderate'};
// dealRatings['red'] = {value:3,styleClass:' icon-danger',label:'Critical'};


function hideProductImages() {
    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }
}

function initializePage() {
    console.log('pageinit from SF1JS');

    // if(hideProductImages == 'true'){
    //     j$('.productImage').hide();    
    // }
    j$.aptActionFunctionQueue.setSkipToEndOfQueue(checkConstraintRules);

    //checkConstraintRules();
}

 
function hideImages() {
    console.log('hide Images '+hideProductImages);
    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }
}

function category(CategoryId, HasChildCategories, Name, ParentCategoryId, ProductCount){
    this.CategoryId = CategoryId;
    this.HasChildCategories = HasChildCategories;
    this.Name = Name;
    this.ParentCategoryId = ParentCategoryId;
    this.ChildCategories = new Array();
    this.ProductCount = ProductCount;
    this.Products = new Array();
}

function product(Name,Description,ContentUrl, ImageUrl, ProductCode, ProductId, CategoryId){
    this.Name = Name;
    this.Description = Description;
    this.ContentUrl = ContentUrl;
    this.ImageUrl = ImageUrl;
    this.ProductCode = ProductCode;
    this.ProductId = ProductId;
    this.CategoryId = CategoryId;
    this.Selected = false;
    this.Added = false;
    this.Installed = false;
    this.Bundle = false;
}

/**
 * Pause queueing
 */
function pauseQueue() {
    // set queue paused param
    j$.aptActionFunctionQueue.updateSetting('isQueuePaused', true);
}

/**
 * Resume queueing
 */
function resumeQueue() {
    // un-pause queue and push along    
    if(j$.aptActionFunctionQueue.updateSetting('isQueuePaused', false)) { 
        j$.aptActionFunctionQueue.processNext(); // only process next if queue was paused
    }
}

/**
 * Load products from cache for a particular category
 * @param  {[type]} categoryId [description]
 * @return {[type]}            [description]
 */
function loadProductsFromCategory(categoryId) {

    var category = categoryMap[categoryId];
    //console.log(category.Name);
    //console.log('children =  '+category.HasChildCategories);
    
    if(category.HasChildCategories == 'true') {
        //console.log('number of children =  '+category.ChildCategories.length);
        j$.each(category.ChildCategories, function(index,catId){
            loadProductsFromCategory(catId);
        });
        //console.log('loading products '+categoryProductResults.length);
        j$('.title').html('Browsing: '+category.Name+' ( '+categoryProductResults.length+' )');
        paginateSearchResults(categoryProductResults);
    } else {
        categoryProductResults = categoryProductResults.concat(category.Products);
        j$('.title').html('Browsing: '+category.Name+' ( '+categoryProductResults.length+' )');
        paginateSearchResults(categoryProductResults);
    }
}

/**
 * Load jstree for categories helper
 * @param  {[type]} arry [description]
 * @return {[type]}      [description]
 */
function loadTree() {

    if(!categoriesTreeLoaded) {
        var theTree = { 
            "json_data" : {
            },"types" : {
                "valid_children" : [ "all" ],
                "types" : {
                    "default" : {
                        "valid_children" : [ "default" ]
                    }
                }
            },
            "plugins" : [ "themes", "json_data", "ui", "wholerow" ],
            "core" : {"html_titles" : true},
            "themes" : {
                "icons" : false,
                "dots" : false
            }
        };
        
        theTree.json_data.data = buildSelectedTreeHierarchy(categories);
        j$("#browseCategories").jstree(theTree).bind("select_node.jstree", 
                function (e, data) { 
                   //console.log('selected node '+data);
                   var catName = data.rslt.obj.attr('title');
                   //console.log(data.rslt.obj.attr('Id'));
                   //console.log(categoryMap[data.rslt.obj.attr('Id')]);
                    //getCategoryProductsSearch(catName);
                    categoryProductResults = new Array()
                    loadProductsFromCategory(data.rslt.obj.attr('Id'));
                    j$('#categoriesFilterModal').modal('hide');
                    j$('.aptResultsSet').val(catName);
                    menuIconListener();
                }
            ).bind('loaded.jstree', function(e, data) {
                j$("[hasImage='true']").addClass('hasImage');
                j$("[hasImage='false']").addClass('noImage');
                //j$('#browseCategories').jstree('open_all');
                // if(selectedNodeId != undefined){
                //     j$('#categoriesTree').jstree('open_node',j$('#'+selectedNodeId));
                // }
                
            });
        categoriesTreeLoaded = true;
    }
    
}

/**
 * Build jstree for categories helper
 * @param  {[type]} arry [description]
 * @return {[type]}      [description]
 */
function buildSelectedTreeHierarchy(arry) {
    var roots = [], children = {};
    
    // find the top level nodes and hash the children based on parent
    for (var i = 0, len = arry.length; i < len; ++i) {
        var item = arry[i];
        var p = item.ParentCategoryId;
        var target = !p ? roots : (children[p] || (children[p] = []));
    
        target.push({ value: item });
    }
    
    // function to recursively build the tree
    var findChildren = function(parent) {
        //if (children[parent.value.Id]) {
            
            parent.children = children[parent.value.CategoryId];
            parent.data = {};
            parent.data.title = parent.value.Name;
            //parent.data.title = parent.value.Name+' ('+parent.value.ProductCount+')';
            // parent.data.icon = parent.value.imageUrl;
            hasImage = false;
            if(parent.value.imageUrl != ""){
                hasImage = true;
            }
            parent.attr = {
                        "Id" : parent.value.CategoryId, 
                        "hasImage" : hasImage, 
                        "Type" : parent.value.type, 
                        "title" : parent.value.Name,
                        "parentId" : parent.value.ParentCategoryId,
                        "isSelected" : parent.value.isSelected,
                        "errorMessages" : parent.value.errorMessages
                    };
            if (children[parent.value.CategoryId]) {
                for (var i = 0, len = parent.children.length; i < len; ++i) {
                    parent.children[i].data = {};
                    if(i < parent.children.length - 1){
                        //parent.children[i].data += "<img class='move-down' src='/img/arrow_dwn.gif' alt='"+parent.children[i].value.Id+"' />";
                    }
                    if(i > 0){
                        //parent.children[i].data += "<img class='move-up' src='/img/arrow_up.gif' alt='"+parent.children[i].value.Id+"' />";
                    }
                    parent.children[i].data.title = parent.children[i].value.Name;
                    hasImage = false
                    if(parent.children[i].value.imageUrl != ""){
                        hasImage = true;
                    }
                    parent.children[i].data.icon = parent.children[i].value.imageUrl;
                    parent.children[i].attr = {"Id" : parent.children[i].value.CategoryId, 
                                                "hasImage" : hasImage, 
                                                "hasError" : parent.children[i].value.hasError,
                                                "isSelected" : parent.children[i].value.isSelected,
                                                "title" : parent.children[i].value.Name,
                                                "parentId" : parent.children[i].value.ParentCategoryId,
                                                "errorMessages" : parent.children[i].value.errorMessages,
                                                "Type" : parent.children[i].value.type};
                    findChildren(parent.children[i]);
                }
            }
        //}
    };
    
    // enumerate through to handle the case where there are multiple roots
    for (var i = 0, len = roots.length; i < len; ++i) {
        findChildren(roots[i]);
    }
    
    return roots;
}


 var waitDialog = 

    (function () {
        // var lmtv = j$.mobile.loadingMessageTextVisible;
        return {
            
            show: function() {
              // j$.mobile.loadingMessageTextVisible = true;
              // j$.mobile.showPageLoadingMsg("a", "Loading...", false);
            },
            hide: function () {
                // j$.mobile.hidePageLoadingMsg();
                // j$.mobile.loadingMessageTextVisible = lmtv;
            }
        };
    })();




/**
 * Get products for a particular category remotely
 * @param  {[type]} categoryId [description]
 * @return {[type]}            [description]
 */
function getProductsRemote(categoryId){
    console.time('getProductsRemote');
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.getProductsForCategory,
        priceListId,categoryId,
        function(result, event)
        {
            if(event.status)
            {
                // console.log(result);
                console.timeEnd('getProductsRemote');
                setupProducts(categoryId,result);
                return result;
            }
            else {
                toastr.error(event.message, "Error ocurred");
                return event;
            }
        });
}

/**
 * Setup products and store in their respective categories
 * @param  {[type]} catId    [description]
 * @param  {[type]} products [description]
 * @return {[type]}          [description]
 */
function setupProducts(catId, products){
    //console.log(catId);
    //console.log('in setup prodcuts');
    categoriesNum--;
    //console.log(categoriesNum);
    //console.log(products);
    j$.each(products, function(index, newProduct){
        newProd = new product(newProduct.Name,newProduct.Description,newProduct.ContentUrl,newProduct.ImageUrl,newProduct.ProductCode,newProduct.ProductId,catId);
        j$.each(newProduct.Prices, function(index, price){
            newProd.Price = price.Value;
        });
        var notFound = true;
        j$.each(categoryMap[newProd.CategoryId].Products, function(index, prod){
            //console.log('------------ product '+product.ProductId+' - '+product.Name+' ---- '+prod.ProductId+' - '+prod.Name);
            if(newProduct.ProductId == prod.ProductId){
                //console.log('------------found product '+product.ProductId+' - '+product.Name);
                notFound = false;
            }
        });
        //console.log('notFound '+notFound);
        if(notFound) {
            categoryMap[newProd.CategoryId].Products.push(newProd);
            productNames.push(newProduct.Name);
        }
    });

    categories = [];
    for (var catId in categoryMap) {
        if(categoryMap.hasOwnProperty(catId)){
            categories.push(categoryMap[catId]);
        }
    }
    j$.aptActionFunctionQueue.processNext();
        
}

/**
 * Initialize search box and blank search
 * @return {[type]} [description]
 */
function initializeSearchbox() {
    //console.log('in searchbox!!');
    //console.log(productNames);
    j$('.total-products').html(productNames.length);

    j$('#typeahead').typeahead('destroy');

    j$('#typeahead').typeahead([
        {
            name: 'products',
            local: productNames,
            header: '<h3 class="league-name">Products</h3>'
        },
        {
            name: 'categories',
            local: categoryNames,
            header: '<h3 class="league-name">Categories</h3>'
        }
    ]);

    j$('#typeahead').off('typeahead:selected');
    j$('#typeahead').off('keypress');

    //autocomplete search
    j$('#typeahead').on('typeahead:selected', function(obj, datum, dataset_name) {
        //console.log('typeahead selected');
        //console.log(datum);
        //console.log(dataset_name);
        j$('.search-result-txt').html(datum.value);
        if(dataset_name == 'products') {
            searchProducts(datum.value);    
        }
        else {
            getCategoryProductsSearch(datum.value);
        }
    });

    j$("#typeahead").on('keypress',function(e) {  //free text search
        if(e.keyCode == 13)     {        
            var token = j$("#typeahead").val();
            console.log('searching '+token);
            j$('.search-result-txt').html(token);
            searchProducts(token);
            j$("#typeahead").blur(); //double blur to hide suggestions?
            j$("#typeahead").blur();
    }});
    j$.aptActionFunctionQueue.processNext();
    //searchProducts('');
    //paginateSearchResults(categoryMap[j$.APTTUS.defaultCategoryId].Products);
}

/**
 * Cancel selection of items
 * @return {[type]} [description]
 */
function cancelSelection() {
    selectedProductIds = new Array();
    j$('.selectItemCheck').removeAttr('checked');
    j$('#pageActions').show();
    j$('#multiSelectActions').hide();

}

/**
 * Delete line item * NOT IN USE *
 * @param  {[type]} lineId [description]
 * @return {[type]}        [description]
 */
function deleteLineItem(lineId){
    console.log('deleting '+lineId);
    var selectedLineNumber = j$('#'+lineId).attr('objid');
    j$('#Searching_Modal').modal('show')
    removeProduct(lineId,'product',selectedLineNumber);
}

/**
 * Delete line item * NOT IN USE *
 * @param  {[type]} lineId [description]
 * @return {[type]}        [description]
 */
function deleteLineItemByLineNumber(lineNumbers){
    console.log('deleting '+lineNumbers);
    var lines = lineNumbers.split(',');
    j$.each(lines, function(index, lineNumber){
        var selectedLineId = j$('li[objId='+lineNumber+']').attr('id');
        console.log(selectedLineId);
        j$('#Searching_Modal').modal('show');
        removeProduct(selectedLineId,'product',lineNumber);
    });

}


function addProductToCart(productName, productId,options, quantity) {

    j$.aptActionFunctionQueue.execute(addProductRemote, [productName, productId,options, quantity], true, null)
                             .then(
                                function() {                                    
                                     console.log('finished addProductToCart');
                                     console.log(j$.aptActionFunctionQueue.getQueuedFunctions());
                                     checkConstraintRules();
                                }, null);
    // resume queue
    resumeQueue();
}


/**
 * Add product remotely
 * @param {[type]} productName [description]
 * @param {[type]} productId   [description]
 * @param {[type]} options     [description]
 * @param {[type]} quantity    [description]
 */
function addProductRemote(productName, productId,options, quantity) {
    // console.log(productName);
    // console.log(productId);
    // console.log(options);
    quantity = Number(quantity);
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.addProductRemote,
        productId,options,1,cartId,priceListId,quantity,
        function(result, event)
        {
            // console.log(event);
            // console.log(result);
            if(event.status)
            {
                //console.log(result);
                console.timeEnd('addProductRemote');
                //processConstraintRules(result.ruleResult);
                j$('.spinner-'+productId).toggle();
                j$('.plus-'+productId).toggle();
                //setTimeout(your_func, 5000);
                //process constraint rules after quantity update (just in case)
                //doRemoteProcessConstraintRules();
                //j$('.spinnerImg-'+ctxOptionId).hide();
                
                toastr.success(productName, "Product Added");
                updateHeaderStatus();
                //toastr.info('Added Product '+productId);
                cartProductIds[productId] = [];
                showSearchResults(currentPage);
                refreshCart();
                j$.aptActionFunctionQueue.processNext();    
                return result;
            }
            else {
                j$('.spinner-'+productId).toggle();
                j$('.plus-'+productId).toggle();
                toastr.error(event.message, "Error ocurred");
                j$.aptActionFunctionQueue.processNext();
                return event;
            }
        }); 
}

/**
 * Run constraint rule check remotely
 * @return {[type]} [description]
 */
function checkConstraintRules() {
    j$.aptActionFunctionQueue.execute(checkConstraintRulesRemote, [], true, null)
                             .then(
                                function() {                                    
                                    console.log('finished checkConstraintRules');
                                }, null);
    // resume queue
    resumeQueue();
}


/**
 * Run constraint rule check remotely
 * @return {[type]} [description]
 */
function checkConstraintRulesRemote() {
    console.log('checkConstraintRules');
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.SF1Header.checkConstraintRules,
        cartId,
        function(result, event)
        {
            if(event.status)
            {
                processConstraintRules(result);
                console.log(result);
                j$.aptActionFunctionQueue.processNext(); 
                return result;
            }
            else {
                toastr.error(event.message, "Error ocurred");
                j$.aptActionFunctionQueue.processNext(); 
                return event;
            }
    }); 
}

/**
 * Get product information remote * NOT IN USE *
 * @param  {[type]} productIds [description]
 * @return {[type]}            [description]
 */
function getProductInfosRemote(productIds, ruleAction) {
    console.log('--------------------------getProductInfosRemote ');
    console.log(productIds);
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.SF1Header.getProductInfos,
        productIds,priceListId,
        function(result, event)
        {
            if(event.status)
            {
                console.log(result);
                var prodList = [];
                j$.each(result, function(index, prod){
                    var newProd = new product(prod.prodSO.Name,prod.prodSO.Description,null,null,null,prod.prodSO.Id,null);
                    newProd.Price = prod.plItemSO.Apttus_Config2__ListPrice__c;
                    prodList.push(newProd);
                });
                ruleAction.productResults = prodList;
                showRuleResults(ruleAction, ruleAction.SuggestedProductIds);

                return prodList;
            }
            else {
                toastr.error(event.message, "Error ocurred");
                return event;
            }
        }); 
}

/**
 * Show rule results and insert them into Rule Panel in header
 * @param  {[type]} ruleAction [description]
 * @param  {[type]} productIds [description]
 * @return {[type]}            [description]
 */
function showRuleResults(ruleAction, productIds) {
    console.log('showRuleResults-----------------------------------------------');
    console.log(ruleAction);
    ruleAction.MessageType = ruleAction.MessageType.toLowerCase();
    //ruleAction.productResults = new Array(); 
    //ruleAction.productResults = findProductsByIds(ruleAction.SuggestedProductIds);
    j$('#rulesPanel').append(tmpl("constraintRule", ruleAction));

    console.log(j$('#rulesPanel'));
                
}


/**
 * Process constraint rules
 * @param  {[type]} ruleResults [description]
 * @return {[type]}             [description]
 */
function processConstraintRules(ruleResults) {
    //check flags
    // j$('#constraintRuleResult').html('');
    j$('#rulesPanel').html('');
    constraintRuleResults = ruleResults;
    if(ruleResults.ConstraintRuleActions.length == 0) {
        j$('#rulesIndicator').removeAttr('style');
        j$('#rulesIcon').removeAttr('style');
    }
    else {
        j$('#rulesIndicator').removeAttr('style');
        j$('#rulesIcon').removeAttr('style');
    }
    var showPrompt = false;
    var totalRules = 0;
    j$.each(ruleResults.ConstraintRuleActions, function(index, action){
        // console.log(action);
        if(!action.IsIgnoredByUser && action.IsPending) {
            // if(j$('li[objId="'+action.AffectedPrimaryNumbers[0]+'"]').length == 0 || action.ActionIntent == 'Disable Selection') {
                if(action.MessageType == 'Error'){
                    j$('#rulesIndicator').css('color','red');
                    j$('#rulesIcon').css('color','red');
                }else {
                    j$('#rulesIndicator').css('color','yellow');
                    j$('#rulesIcon').css('color','yellow');
                }
                //getProductInfosRemote(action.SuggestedProductIds);
                if(action.ActionIntent == 'Auto Include') {
                    toastr.warning(action.Message);
                    showRuleResults(action, new Array());
                }
                else if(action.ActionIntent == 'Prompt') {
                    //action.productResults = getProductInfosRemote(action.SuggestedProductIds);
                    //showRuleResults(action, action.SuggestedProductIds);
                    // showPrompt = true;
                    getProductInfosRemote(action.SuggestedProductIds, action);
                }
                else if(action.ActionIntent == 'Show Message') {
                    //action.productResults = getProductInfosRemote(action.SuggestedProductIds, action);
                    //showRuleResults(action, action.SuggestedProductIds);
                    // showPrompt = true;
                    getProductInfosRemote(action.SuggestedProductIds, action);
                }
                else if(action.ActionIntent == 'Disable Selection') {
                    excludedProductIds = excludedProductIds.concat(action.SuggestedProductIds);
                    var productsToExclude = new Array();
                    j$.each(excludedProductIds, function(index,productId){
                        if(cartProductIds[productId]){
                            productsToExclude.push(productId);
                        }
                    });
                    showRuleResults(action, productsToExclude);
                    
                }
                else {
                    //showRuleResults(action, action.SuggestedProductIds);
                    getProductInfosRemote(action.SuggestedProductIds, action);
                } 
            // }
            totalRules++;
        }
        
    });
    console.log('rulesBadge '+totalRules);
    j$('.rulesBadge').html(totalRules);
    if(!j$('#rulesPanel').hasClass('closed') && totalRules == 0) {
        closedAllOverlays();
    }
    j$(document).off("click",'.dismissRule',ignoreRule).on("click",'.dismissRule',ignoreRule);

    j$(document).off("click",'.ruleAction',processRuleAction).on("click",'.ruleAction',processRuleAction);

    j$.aptActionFunctionQueue.processNext(); 
}

function processRuleAction(event) {
    //console.log('processRuleAction');
    event.stopPropagation();
    //console.log(j$(event.currentTarget));
    var ruleActionBtn = j$(event.currentTarget);
    console.log(ruleActionBtn);
    var actionType = ruleActionBtn.attr('action');
    var prodId = ruleActionBtn.attr('id');
    var prodName = ruleActionBtn.attr('prodname');
    switch(actionType){
        case 'Inclusion':
            console.log('inclusion rule');
            addProductToCart(prodName,prodId,null,1);
            break;
        case 'Exclusion':
            console.log('exclusion rule');
            console.log(cartProductIds[prodId]);
            deleteLineItem(cartProductIds[prodId][0]);
            break;
        case 'Replacement':
            console.log('replacement rule');
            console.log(ruleActionBtn.parent().attr('triggerLineNum'));
            deleteLineItemByLineNumber(ruleActionBtn.parent().attr('triggerLineNum'));
            addProductToCart(prodName,prodId,null,1);
            break;
        default:
            console.log('no case for '+actionType);
    }

}

/**
 * Ignore particular constraint rule
 * @param  {[type]} event [description]
 * @return {[type]}       [description]
 */
function ignoreRule(event){
    console.log('ignoreRule');
    event.stopPropagation();
    //console.log(j$(event.currentTarget));
    var ruleActionId = j$(event.currentTarget).attr('objId');
    console.log(ruleActionId);
    j$('#'+ruleActionId).remove();

    toastr.info("Constraint Rule Ignored");

    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.SF1Header.ignoreConstraintRule, 
        ruleActionId,
        function(result, event)
        {
            if(event.status)
            {
                console.log(result);
                checkConstraintRules();
            }
            else {
                toastr.error(event.message, "Error ocurred");
                return event;
            }
    });

}


/**
 * Return the products in a particular category
 * @param  {[type]} searchToken [description]
 * @return {[type]}             [description]
 */
function getCategoryProductsSearch(searchToken) {
    var resultCategory;
    j$.each(categories, function(index,category){
        //console.log('matching '+searchToken+' to '+category.Name+' - '+(category.Name == searchToken));
        if(category.Name == searchToken) {
            //console.log('match!');
            resultCategory = category;
        }
    });
    j$('.title').html('Browsing: '+resultCategory.Name+' ( '+resultCategory.Products.length+' )');
    paginateSearchResults(resultCategory.Products);
}

/**
 * Search for a product through the catalog
 * @param  {[type]} searchToken [description]
 * @return {[type]}             [description]
 */
function searchProducts(searchToken) {
    searchToken = searchToken.toLowerCase();
    //var vals = Object.keys(categoryMap).map(key => categoryMap[key]);
    //console.log(vals);
    var productResults = new Array();
    //console.log('searching through '+categories.length+' categories');
    j$.each(categories, function(index,category){
        //console.log('found '+category.Products.length);
        j$.each(category.Products, function(index,product){
            //console.log(product.Name);
            if(product.Name.toLowerCase().indexOf(searchToken) != -1 || product.ProductCode.toLowerCase().indexOf(searchToken) != -1 ){
                //console.log('matched '+searchToken+' with '+product.Name+' '+product.ProductCode+' /// '+product.Description);
                productResults.push(product);
            }
        });
    });
    j$('.title').html('Showing ( '+productResults.length+' )');
    paginateSearchResults(productResults);
}

/**
 * Find products by their Ids in the cache
 * @param  {[type]} productIds [description]
 * @return {[type]}            [description]
 */
function findProductsByIds(productIds) {
    //console.log('findProductsByIds');
    var productResults = new Array();
    //console.log('searching through '+categories.length+' categories');
    j$.each(categories, function(index,category){
        // console.log('found '+category.Products.length);
        j$.each(category.Products, function(index,product){
            // console.log(product.ProductId);
            // console.log(productIds.indexOf(product.ProductId));
            if(productIds.indexOf(product.ProductId) > -1){
                // console.log('Found  with '+product.Name);
                productResults.push(product);
            }
        });
    });
    return productResults;
}



/**
 * [numberWithCommas description]
 * @param  {[type]} x [description]
 * @return {[type]}   [description]
 */
function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Separates search results into pages of 10 elements
 * @param  {[type]} results [description]
 * @return {[type]}         [description]
 */
function paginateSearchResults(results) {
    console.log('paginateSearchResults');
    console.log(results);
    var pageNum = 0;
    productPages = [];
    productPages[pageNum] = []; //initialize first page
    j$.each(results, function cycleProducts(index, product){
        productPages[pageNum].push(product);
        if(index % pageSize == 9){ //prepare next page
            pageNum++;
            productPages[pageNum] = [];
        }
        
    });
    showSearchResults(0); //show first page
}

/**
 * Show products for a particular page
 * @param  {[type]} pageNum [description]
 * @return {[type]}         [description]
 */
function showSearchResults(pageNum) {

    var multiSelect = false;
    var fragment = document.createDocumentFragment();
    var list = document.getElementById("searchResults");
    list.innerHTML = '';
    // $('#searchResults').remove('prodLine');
    j$.each(productPages[pageNum], function(index, product){
        
        var item =  document.createElement('div');
        item.className = 'listItem prodLine';
        item.setAttribute('objId',product.ProductId);

        var excludedProduct = excludedProductIds.indexOf(product.ProductId) > -1;
        product.Added = cartProductIds[product.ProductId];
        // console.log('excludedProduct = '+excludedProduct);
        if(excludedProduct) {
            item.setAttribute('excluded','true');
            //item.addClass('excludedProduct');
        }
        if(selectedProductIds.indexOf(product.ProductId) > -1) {
            item.setAttribute('selected','true');
            product.Selected = true;
            //item.addClass('selectedProduct');
        } else {
            product.Selected = false;
        }

        if(product.Price === undefined || product.Price == ''){
            product.Price = '0.00';
        } else {
            product.Price = parseFloat(product.Price).toFixed(2);
            product.Price = numberWithCommas(product.Price);
        }

        product.MultiSelect = multiSelect;

        item.innerHTML = tmpl("productItem", product);
        fragment.appendChild(item);
        temp = product;
    });
    var paginationControl =  document.createElement('div');
    var paginationObject = {
        pagesEnabled: productPages.length > 1,
        prevPage: pageNum-1,
        nextPage: pageNum+1,
        hasPrevPage: pageNum != 0,
        hasNextPage: pageNum != productPages.length-1
    };
    paginationControl.innerHTML = tmpl("pagination", paginationObject);
    fragment.appendChild(paginationControl);

    list.appendChild(fragment);

    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }

    j$('.selectItemCheck').on('click',function selectItem(){
        var objId = j$(this).attr('objId');
        var index = selectedProductIds.indexOf(objId);
        if(index > -1) {
          selectedProductIds.splice(index,1);
        } else {
          selectedProductIds.push(objId);
        }
        console.log(selectedProductIds);
        if(selectedProductIds.length > 0){
          j$('#pageActions').hide();
          j$('#multiSelectActions').show();
          if(selectedProductIds.length > 1){
            j$('.multiple').removeClass('disabled');
          } else {
            j$('.multiple').addClass('disabled');
          }
        } else {
          j$('#pageActions').show();
          j$('#multiSelectActions').hide();
        }
        
    });

    j$(document).off('click','.addToCart').on('click','.addToCart',function(){
        console.log('selecting product');
        //j$(this).toggleClass('selected-option');
        selectedProductId = j$(this).attr('Id');
        var prodName = j$(this).attr('prodName');
        var quantity = j$('input[objId="'+selectedProductId+'"]').val();
        console.log(quantity);
        j$('.spinner-'+selectedProductId).toggle();
        j$('.plus-'+selectedProductId).toggle();
        var options = '';
        options = options.substr(0,options.length - 1);
        
        // addProduct(selectedProductId,options,'true');

        addProductToCart(prodName,selectedProductId,options,quantity);
        
    });
}

/**
 * Add multiple products * NOT IN USE *
 * @param {[type]} element [description]
 */
function addMultipleProducts(element){
    console.log(this);
    j$.each(selectedProductIds, function multipleAddProductRemote(index, productId){
        addProductToCart('',productId,'');
    });
    cancelSelection();

}

j$.APTTUS = {};
j$.APTTUS.cp_cERROR_UNKNOWN = "ERROR: Unknown error:\n";
if(typeof j$.APTTUS.currencyTemplate === 'undefined'){
    j$.APTTUS.currencyTemplate ='';
}
/**
 * Adjusts the currency/decimal fields, taking into account the Locale of the ORG
 * @return void
 */
j$.APTTUS.formatFields = function (currencyFieldPrecision, percentageFieldPrecision, quantityFieldPrecision){
    
    var currencyPrecision = parseInt(currencyFieldPrecision);
    var percentagePrecision = parseInt(percentageFieldPrecision);
    var quantityPrecision = parseInt(quantityFieldPrecision);

    if (currencyPrecision > 0) {
        currencyPrecision ++;

    } else if (currencyPrecision < 0) {
        currencyPrecision = 0;

    } 

    if (percentagePrecision > 0) {
        percentagePrecision ++;

    } else if (percentagePrecision < 0) {
        percentagePrecision = 0;

    }

    if (quantityPrecision > 0) {
        quantityPrecision ++;

    } else if (quantityPrecision < 0) {
        quantityPrecision = 0;

    }
    
    //remove extra decimal from percentage field
    j$("[class^=aptPercentage], [class*=aptPercentage]").each(function(){
    
        var re = new RegExp("\\.\\d{3,}%"); 
        var re2 = new RegExp("\\.\\d{3,}$"); 
        var re3 = new RegExp(",\\d{3,}%");
        var re4 = new RegExp(",\\d{3,}$"); 
        if (j$(this).is("input")) {
            var matches2 =re2.test(j$(this).val());
            var matches4 = re4.test(j$(this).val());
            if(!(j$(this).hasClass('formatted'))){
                if (matches2) {
                    j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(".") + percentagePrecision));
                    j$(this).addClass('formatted');

                } else if (matches4) {
                    j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(",") + percentagePrecision));
                    j$(this).addClass('formatted');

                }

                
            }
            
        } else {

            j$(this).children().each(function(){
                var matches =re.test(j$(this).html());
                var matches3 = re3.test(j$(this).html());
                var matches2 =re2.test(j$(this).html());
                var matches4 = re4.test(j$(this).html());
                if(!(j$(this).hasClass('formatted'))){
                    if (matches) {
                        j$(this).html(j$(this).html().replace("%",""));
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + percentagePrecision) + "%");
                        j$(this).addClass('formatted');

                    } else if (matches3) {
                        j$(this).html(j$(this).html().replace("%",""));
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + percentagePrecision) + "%");
                        j$(this).addClass('formatted');

                    } else if (matches2) {
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + percentagePrecision));
                        j$(this).addClass('formatted');

                    } else if (matches4) {
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + percentagePrecision));
                        j$(this).addClass('formatted');

                    }

                    
                }

            })

        }

    });
    // check if the decimal places are rendered on the dummy line item.
    // Introduced to fix a bug with Japanese currency where the decimal places
    // are not rendered in multicurrency orgs causing the formatting script 
    // to trim the values incorrectly.
    if(j$.APTTUS.currencyTemplate === "" || j$.APTTUS.currencyTemplate.indexOf("56") !== -1){
        //remove extra decimal values from currency field
        j$("[class^=aptCurrency], [class*=aptCurrency]").each(function(){
            
            var re = new RegExp("\\.\\d{3,}$"); // currency at start of string and "."" is decimal separator
            var re2 = new RegExp("\\.\\d{3,} \\D+$"); // currency at end of string and "."" is decimal separator
            var re3 = new RegExp(",\\d{3,}$"); // currency at start of string and "," is decimal separator
            var re4 = new RegExp(",\\d{3,} \\D+$"); // currency at end of string and "," is decimal separator
            var negativeCurrency = false;
            var tempValue = j$(this).val();
            
            if (j$(this).is("input")) {
                if(!(j$(this).hasClass("formatted"))){
                    if (tempValue.indexOf("(") == 0) {
                        negativeCurrency = true ;
                        tempValue = tempValue.replace("(","");
                        tempValue = tempValue.replace(")","");
    
                    } else if (tempValue.indexOf("(") != -1) {
                        var multiCurrencySection = tempValue.substring(tempValue.indexOf("(")-1,tempValue.length);
                        tempValue = tempValue.replace(multiCurrencySection,"");
    
                    }
                    
                    var matches = re.test(tempValue);
                    var matches2 = re2.test(tempValue);
                    var matches3 = re3.test(tempValue);
                    var matches4 = re4.test(tempValue);
    
                    if (matches || matches2 || matches3 || matches4) {
                        j$(this).val(tempValue);
                        j$(this).addClass("formatted");
    
                    }
    
                    //check if string matches a decimal format with currency symbol in the beginning 
                    //and the decimal separator is .
                    if (matches) {
                        var matchedGroups = re.exec(j$(this).val());
                        var filtered =  j$(this).val().replace(matchedGroups[0],"");
                        var decimalPortion = matchedGroups[0].substring(0,currencyPrecision); 
                        j$(this).val(filtered + decimalPortion);
                        //check if value is a negative value the add closing parenthesis
                        if(negativeCurrency){
                            j$(this).val("(" + j$(this).val() + ")");
    
                        }
    
                    }
                    //check if string matches a decimal format with currency symbol in the end
                    //and the decimal separator is .
                    else if (matches2){
                        var currencySymbolRE = new RegExp("\\D+$");
                        var matchedGroups = re2.exec(j$(this).val());
                        var filtered =  j$(this).val().replace(matchedGroups[0],"");
                        var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
                        var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                        decimalPortion = decimalPortion.replace(currencySymbol[0], "");
                        j$(this).val(filtered + decimalPortion + currencySymbol[0]);
                        //check if value is a negative value the add closing parenthesis
                        if(negativeCurrency){
                            j$(this).val("(" + j$(this).val() + ")");
    
                        }
    
                    }
                    //check if string matches a decimal format with currency symbol in the beginning 
                    //and the decimal separator is ,
                    else if (matches3){
                        var matchedGroups = re3.exec(j$(this).val());
                        var filtered =  j$(this).val().replace(matchedGroups[0],"");
                        var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                        j$(this).val(filtered + decimalPortion);
                        //check if value is a negative value the add closing parenthesis
                        if(negativeCurrency) {
                            j$(this).val("(" + j$(this).val() + ")");
    
                        }
    
                    }
                    //check if string matches a decimal format with currency symbol in the end
                    //and the decimal separator is ,
                    else if (matches4) {
                        var currencySymbolRE = new RegExp("\\D+$");
                        var matchedGroups = re4.exec(j$(this).val());
                        var filtered =  j$(this).val().replace(matchedGroups[0],"");
                        var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
                        var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                        decimalPortion = decimalPortion.replace(currencySymbol[0], "");
                        j$(this).val(filtered + decimalPortion + currencySymbol[0]);
                        //check if value is a negative value the add closing parenthesis
                        if(negativeCurrency){
                            j$(this).val("(" + j$(this).val() + ")");
    
                        }
    
                    }
    
                }
    
            } else {
                j$(this).children('span').each(function(){
                    if(!(j$(this).hasClass("formatted"))){
                        var negativeCurrency = false;
                        var tempValue = j$(this).html();
    
                        if(tempValue.indexOf("(") == 0) {
                            negativeCurrency = true ;
                            tempValue = tempValue.replace("(","");
                            tempValue = tempValue.replace(")","");
    
                        } else if (tempValue.indexOf("(") != -1) {
                            var multiCurrencySection = tempValue.substring(tempValue.indexOf("(")-1, tempValue.length);
                            tempValue = tempValue.replace(multiCurrencySection,"");
    
                        }
                        
                        var matches = re.test(tempValue);
                        var matches2 = re2.test(tempValue);
                        var matches3 = re3.test(tempValue);
                        var matches4 = re4.test(tempValue);
    
                        if (matches || matches2 || matches3 || matches4) {
                            j$(this).html(tempValue);
                            j$(this).addClass("formatted");
    
                        }
    
                        //check if string matches a decimal format
                        if (matches) {
                            var matchedGroups = re.exec(j$(this).html());
                            var filtered =  j$(this).html().replace(matchedGroups[0],"");
                            var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                            j$(this).html(filtered + decimalPortion);
                            //check if value is a negative value the add closing parenthesis
                            if(negativeCurrency){
                                j$(this).html("(" + j$(this).html() + ")");
    
                            } 
                            
                        } else if (matches2) {
                            var currencySymbolRE = new RegExp("\\D+$");
                            var matchedGroups = re2.exec(j$(this).html());
                            var filtered =  j$(this).html().replace(matchedGroups[0],"");
                            var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
                            var decimalPortion = matchedGroups[0].substring(0, currencyPrecision);
                            decimalPortion = decimalPortion.replace(currencySymbol[0], ""); 
                            j$(this).html(filtered + decimalPortion + currencySymbol[0]);
                            //check if value is a negative value the add closing parenthesis
                            if (negativeCurrency){
                                j$(this).html("(" + j$(this).html() + ")");
    
                            }
    
                        } else if (matches3) {
                            var matchedGroups = re3.exec(j$(this).html());
                            var filtered =  j$(this).html().replace(matchedGroups[0],"");
                            var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                            j$(this).html(filtered + decimalPortion);
                            //check if value is a negative value the add closing parenthesis
                            if (negativeCurrency) {
                                j$(this).html("(" + j$(this).html() + ")");
                            
                            }
    
                        } else if (matches4) {
                            var currencySymbolRE = new RegExp("\\D+$");
                            var matchedGroups = re4.exec(j$(this).html());
                            var filtered =  j$(this).html().replace(matchedGroups[0],"");
                            var currencySymbol = currencySymbolRE.exec(matchedGroups[0]);
                            var decimalPortion = matchedGroups[0].substring(0, currencyPrecision); 
                            decimalPortion = decimalPortion.replace(currencySymbol[0], "");
                            j$(this).html(filtered + decimalPortion + currencySymbol[0]);
                            //check if value is a negative value the add closing parenthesis
                            if(negativeCurrency){
                                j$(this).html("(" + j$(this).html() + ")");
    
                            }
    
                        }
    
                    }
    
                })
                    
            }
        });
    }
    //remove decimal values from quantity field
    j$("[class^=aptQuantity], [class*=aptQuantity]").each(function(){
        var re = new RegExp("\\.\\d{3,}$");
        var re3 = new RegExp(",\\d{3,}$");
        
        if(j$(this).is("input")){
            var matches =re.test(j$(this).val());
            var matches3 = re3.test(j$(this).val());
            if(!(j$(this).hasClass('formatted'))){
                if (matches) {
                    j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(".") + quantityPrecision));
                    j$(this).addClass('formatted');

                } else if (matches3) {
                    j$(this).val(j$(this).val().substring(0,j$(this).val().lastIndexOf(",") + quantityPrecision));
                    j$(this).addClass('formatted');

                }

                
            
            }
        } else {
            var matches =re.test(j$(this).html());
            var matches3 = re3.test(j$(this).html());
            if(!(j$(this).hasClass('formatted'))){
                if (matches) {
                    j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + quantityPrecision));
                    j$(this).addClass('formatted');

                } else if (matches3) {
                    j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + quantityPrecision));
                    j$(this).addClass('formatted');
                    
                }
            
            }
            
            j$(this).children().each(function(){
                var matches =re.test(j$(this).html());
                var matches3 = re3.test(j$(this).html());
                if(!(j$(this).hasClass('formatted'))){
                    if (matches) {
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(".") + quantityPrecision));
                        j$(this).addClass('formatted');

                    } else if (matches3) {
                        j$(this).html(j$(this).html().substring(0,j$(this).html().lastIndexOf(",") + quantityPrecision));
                        j$(this).addClass('formatted');
                        
                    }

                 }

            })


            

        }

    }); 

}