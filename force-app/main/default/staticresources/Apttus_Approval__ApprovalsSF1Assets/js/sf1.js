j$ = jQuery.noConflict();

var categoriesNum;
var categoryNames = new Array();
var categoryMap = {};
var catalogProducts = new Array();
var productNames = new Array();
var ignoreTap = false;
var selectedProductIds = new Array();
var cartProductIds = new Array();
var excludedProductIds = new Array();
var categoryProductResults = new Array();
var constraintRuleResults;
var listWindow;
var searchResultsWindow;
var window_height;
var sticky_offset;
var productPages = [];
var pageSize = 10;



var dealRatings = {};
dealRatings['green'] = {value:0,styleClass:'glyphicon-ok icon-success',label:'Good'};
dealRatings['yellow'] = {value:1,styleClass:'glyphicon-warning-sign icon-warning',label:'Average'};
dealRatings['orange'] = {value:2,styleClass:'glyphicon-exclamation-sign icon-danger',label:'Moderate'};
dealRatings['red'] = {value:3,styleClass:'glyphicon-exclamation-sign icon-danger',label:'Critical'};
 
// dealRatings['green'] = {value:0,styleClass:' icon-success',label:'Good'};
// dealRatings['yellow'] = {value:1,styleClass:' icon-warning',label:'Average'};
// dealRatings['orange'] = {value:2,styleClass:' icon-danger',label:'Moderate'};
// dealRatings['red'] = {value:3,styleClass:' icon-danger',label:'Critical'};

 
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
        paginateSearchResults(categoryProductResults);
    } else {
        categoryProductResults = categoryProductResults.concat(category.Products);
        paginateSearchResults(categoryProductResults);
    }
}


function loadTree() {

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
                j$('#typeahead').val(catName);
                j$('#menuWindow').removeClass('animate');
            }
        ).bind('loaded.jstree', function(e, data) {
            j$("[hasImage='true']").addClass('hasImage');
            j$("[hasImage='false']").addClass('noImage');
            j$('#browseCategories').jstree('open_all');
            // if(selectedNodeId != undefined){
            //     j$('#categoriesTree').jstree('open_node',j$('#'+selectedNodeId));
            // }
            
        });
    
}

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

  // j$(document).off('tap').on('tap', function() {console.log('tapped'); });
  // j$(document).off('taphold').on('taphold', function() {console.log('taphold'); });
  // j$(document).off('swipe').on('swipe', function() {console.log('swipe'); });
  // j$(document).off('swipeleft').on('swipeleft', function() {console.log('swipeleft'); });
  // j$(document).off('swiperight').on('swiperight', function() {console.log('swiperight'); });
  // j$(document).off('pagebeforeload').on('pagebeforeload', function() {console.log('pagebeforeload'); });
  // j$(document).off('ready').on('ready', function() {console.log('ready'); });



//console.log('categories length '+categories.length);

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

////////////////READY FUNCTION/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
j$( 'div[data-role="page"]').ready(function() {
    var inMobileCard;
    //console.log(hasLineItems);
    if(j$('div[data-role="page"]').css('min-height')) {
        inMobileCard = Number(j$('div[data-role="page"]').css('min-height').replace('px',''));
    }
    if(hasLineItems == 'true') {
        j$('#cartContainer').addClass('active');
        j$('#cartPageBtn').addClass('headerBtnActive');
        j$('#catalogContainer').removeClass('active');
    }
    else {
        j$('#catalogPageBtn').addClass('headerBtnActive');    
    }
    //j$('#cartContainer').addClass('active');
    //j$('#catalogContainer').removeClass('active');
    if(inMobileCard > 250) {
        //console.log('show header');
        //j$('#cartContainer').addClass('active');
        //j$('#catalogContainer').removeClass('active');
        j$('.mobileCardHide').show();
        j$('.mobileCardShow').hide();
    }
    else {
        //j$('.footer').css('bottom',0);
        j$('.footer').css('top', window_height-35);
        j$('#list').css('height','');
        j$('#cartContainer').addClass('active');
        j$('#cartPageBtn').addClass('headerBtnActive');
        j$('#catalogContainer').removeClass('active');
    }

});

function hideProductImages() {
    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }
}

////////////////////PAGE INIT/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
j$('div[data-role="page"]').on("pageinit",function() {

    console.log('pageinit');
    //console.log('window height '+j$('div[data-role="page"]').css('min-height'));
    // console.log('hideProductImages '+hideProductImages);
    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }

    
    // j$.event.special.tap.emitTapOnTaphold = false;
    // j$.event.special.tap.tapholdThreshold = 500;
    //console.log('emitTapOnTaphold '+j$.event.special.tap.emitTapOnTaphold);
    //console.log('namespace count: {!count}');
    
    //console.log('approval status '+approvalPending);
    if(approvalPending) {
        console.log('block everything');
    }
    else {
        console.log('no worries');  
    }
    
    categoriesNum = categories.length;
    j$.each(categories, function(index,category){
        //console.log('getting category '+index+' - '+category.Name);
        //getProducts(category.CategoryId);
        getProductsRemote(category.CategoryId);
        if(categoryMap[category.ParentCategoryId]) {
            categoryMap[category.ParentCategoryId].ChildCategories.push(category.CategoryId);
        }
        categoryNames.push(category.Name);
    });

    //checkConstraintRules();
    
    var original_position_offset = j$('.footer').offset();
    sticky_offset = original_position_offset.top;
    j$('.footer').css('position', 'fixed');

    //console.log('list offset '+j$('#list').offset().top);
    // var sticky_height = j$('.footer').outerHeight();
    // var where_scroll = j$(window).scrollTop();
    console.log('saving window height');
    window_height = j$(window).height();
    console.log('window height '+window_height);
    listWindow = j$(window).height() - j$('#list').offset().top - 185;
    j$('.footer').css('top', window_height-35);
    searchResultsWindow = j$(window).height() - j$('#searchResults').offset().top - 35;
    console.log('lsearchResultsWindow '+searchResultsWindow);
    console.log('list window '+listWindow);
    j$('#list').css('height',listWindow);
    j$('#searchResults').css('height',searchResultsWindow);

    // j$(document).on( "scrollstart", function( event ) {

    // });
    j$(document).on('tap','#cartPageBtn',function() {
        j$('#searchResults').css('height',searchResultsWindow);
        j$('#list').css('height',listWindow);
        j$("#oneCarousel").carousel(0);
        j$('.footer').css('top', window_height-35);
        j$('#cartPageBtn').addClass('headerBtnActive');
        j$('#catalogPageBtn').removeClass('headerBtnActive');
        console.log(listWindow);
        console.log(searchResultsWindow);
        console.log('window height '+window_height);
    });

    j$(document).on('tap','#catalogPageBtn',function() {
        j$('#list').css('height',listWindow); 
        j$('#searchResults').css('height',searchResultsWindow);
        j$("#oneCarousel").carousel(1);
        j$('.footer').css('top', window_height-35);
        j$('#catalogPageBtn').addClass('headerBtnActive');
        j$('#cartPageBtn').removeClass('headerBtnActive');
        console.log(listWindow);
        console.log(searchResultsWindow);
        console.log('window height '+window_height);
    });

    j$(document).on('tap','.prodLine',function(e) { //product info

       // console.log(j$(this).attr('objId'));
       // e.preventDefault();
       // var productIds = [j$(this).attr('objId')];
       // var productResults = findProductsByIds(productIds);
       // console.log(productResults);
       // loadProductInfoDialog(productResults[0]);
    });

    j$('#constraintModal').on('hidden.bs.modal', function (e) {
        j$('.menuActionItemActive').removeClass('menuActionItemActive');
    });

    j$('#commissionModal').on('hidden.bs.modal', function (e) {
        j$('.menuActionItemActive').removeClass('menuActionItemActive');
    });
   
   j$('#approvalModal').on('hidden.bs.modal', function (e) {
        j$('.menuActionItemActive').removeClass('menuActionItemActive');
    });


   j$(document).off("taphold",'ul[id="list"] > li',lineItemAction).on("taphold",'ul[id="list"] > li',lineItemAction);

   //j$(document).off("tap",'ul[id="list"] > li',goToDetailPage).on("tap",'ul[id="list"] > li',goToDetailPage);

    j$(document).on('tap',function(e){
        //console.log('tapping '+ignoreTap);
        if(ignoreTap > 0){
            ignoreTap --;
        }
        if(ignoreTap==0){
            j$('.lineItemMenu').remove();
            j$('.actionContainer').remove();
            //ignoreTap = true;
        }
        // }else {
        //     ignoreTap = true;
        // }
        e.stopPropagation();
        
    });
    
});

function loadProductInfoDialog(product) {

    j$('#prodInfoTitle').html(product.Name);
    j$('#productCodeResult').html(product.ProductCode);
    j$('#productDescriptionResult').html(product.Description);
    j$('#productPriceResult').html('j$ '+product.Price);
    // j$('#prodInfoResult').html('<b>Product Code: </b>'+product.ProductCode+'<br/> <b>Description'+product.Description+'<br/>'+product.Price);
    j$('#prodInfoModal').modal('show');
}

function ignoreRule(event){
    console.log('ignoreRule');
    event.stopPropagation();
    //console.log(j$(event.currentTarget));
    var ruleActionId = j$(event.currentTarget).parent().attr('objId');
    console.log(ruleActionId);
    j$('#'+ruleActionId).remove();

    toastr.info("Constraint Rule Ignored");

    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.ignoreConstraintRule, 
        ruleActionId,
        function(result, event)
        {
            if(event.status)
            {
                console.log(result);
                checkConstraintRules();
            }
    });

}

function goToDetailPage(e) {
    console.log('going to detail page');
    if(!approvalPending ) {
        j$('.lineItemMenu').remove();
        j$('.actionContainer').remove();
        var li = j$(this);
        var contents = j$(li.children()[0]);
        var item = contents.text(); // Get the item value
        // var itemId = contents.attr("objId");
        var lineId = li.attr('Id');
        var selectedLineNumber = li.attr('objId');

        var configUrl = '/apex/'+namespace+'MiniCartView?configId='+cartId+'&quoteId='+quoteId+'&ctxLineNumber='+selectedLineNumber+'&plId='+priceListId;;
        sforce.one.navigateToURL(configUrl);
    }
}

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
        });
}

function setupProducts(catId, products){
        categoriesNum--;
        //console.log(categoriesNum);
        j$.each(products, function(index, newProduct){
            newProd = new product(newProduct.Name,newProduct.Description,newProduct.ContentUrl,newProduct.ImageUrl,newProduct.ProductCode,newProduct.ProductId,catId);
            j$.each(newProduct.Prices, function(index, price){
                newProd.Price = price.Value;
            });
            var notFound = true;
            j$.each(categoryMap[newProd.CategoryId].Products, function(index, prod){
                //console.log('------------ product '+product.ProductId+' - '+product.Name+' ---- '+prod.ProductId+' - '+prod.Name);
                if(newProduct.ProductId == prod.ProductId){
                    // console.log('------------found product '+product.ProductId+' - '+product.Name);
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
        if(categoriesNum == 0) {
            initializeSearchbox();     
        }
        
}

function cancelSelection() {
    selectedProductIds = new Array();
    j$('.selectItemCheck').removeAttr('checked');
    j$('#pageActions').show();
    j$('#multiSelectActions').hide();

}


function deleteLineItem(lineId){
    console.log('deleting '+lineId);
    var selectedLineNumber = j$('#'+lineId).attr('objid');
    j$('#Searching_Modal').modal('show')
    removeProduct(lineId,'product',selectedLineNumber);
}


function lineItemAction(e) {
    ignoreTap = 2;
    // console.log(e.type);
    e.stopPropagation();
    // if(e.type == 'tap' && !ignoreTap) {
    //  ignoreTap = false;
    //  console.log('ignored tap');
    //  //j$('.lineItemMenu').remove();
   //   //j$('.actionContainer').remove();
    //  return false;
    // }
    j$(document).off("tap",'ul[id="list"] > li',goToDetailPage);
    if(!approvalPending ) {
        // console.log('tap works');
        // ignoreTap = true;
        // alert('swiped right');
        j$('.lineItemMenu').remove();
        j$('.actionContainer').remove();
        var li = j$(this);
        var contents = j$(li.children()[0]);
        var item = contents.text(); // Get the item value
        // var itemId = contents.attr("objId");
        var lineId = li.attr('Id');
        var selectedLineNumber = li.attr('objId');

        setupAdjust(lineId);

        var panel = j$('.cartPanel');

        var topOffset = li.offset().top - panel.offset().top;


       var menu = j$("<div />").css('top',topOffset)
                                .css('left',0)
                               .css('height',li.height()+28)
                               .css('width',li.width()+28)
                               .css('display','none')
                               .addClass('lineItemMenu');

        var actionContainer = j$("<div />").css('top',topOffset)
                                .css('left','-20px')
                               .css('height',li.height()+28)
                               .css('width',li.width()+28)
                               .css('position','absolute')
                               .css('margin-top','30px')
                               .css('margin-right','10px')
                               .css('text-align', 'right')
                               .addClass('actionContainer');

        var deleteButton = j$('<button type="button" actionType="delete" class="lineAction btn btn-danger btn-md"><span class="glyphicon glyphicon-trash"></span>'+j$.APTTUS.Label.Remove+'</button>');

        var configButton = j$('<button type="button" actionType="config" class="lineAction btn btn-default btn-md"><span class="glyphicon glyphicon-wrench"></span> Detail</button>');
        var modifyButton = j$('<button type="button" actionType="modify" class="lineAction btn btn-default btn-md"><span class="glyphicon glyphicon-cog"></span> Edit</button>');
        //menu.html('<button type="button" class="btn btn-default btn-lg"><span class="glyphicon glyphicon-trash"></span> Delete</button>');
        actionContainer.append(deleteButton);
        actionContainer.append(configButton);
        actionContainer.append(modifyButton);

        li.append(menu);
        li.append(actionContainer);
        menu.fadeIn('fast');
        actionContainer.fadeIn('fast');


        console.log('setting up listener for lineaction');
        j$(document).off('tap','button.lineAction').on('tap','button.lineAction',function(e){

            j$('.lineItemMenu').remove();
            j$('.actionContainer').remove();
            // console.log(lineId);
            // console.log(selectedLineNumber);
            // e.preventDefault();
            var action  = j$(this).attr('actionType');
            //console.log('selecting line '+action);
            if(action == 'config') {
                var configUrl = '/apex/'+namespace+'MiniCartView?configId='+cartId+'&quoteId='+quoteId+'&ctxLineNumber='+selectedLineNumber+'&plId='+priceListId;;
                sforce.one.navigateToURL(configUrl);
            }
            if(action == 'delete') {
                console.log('deleting '+lineId);
                j$('#Searching_Modal').modal('show')
                removeProduct(lineId,'product',selectedLineNumber);

                // var configUrl = '/apex/MiniCartView2?configId='+cartId+'&quoteId='+quoteId+'&ctxLineNumber='+selectedLineNumber+'&plId='+priceListId;
                // console.log(configUrl);
                //sforce.one.navigateToURL(configUrl);
                
            }
            if(action == 'modify') {
                var configUrl = '/apex/MobileLineAdjust?configId='+cartId+'&quoteId='+quoteId+'&ctxLineNumber='+selectedLineNumber;
                j$('#myModal').modal('show');
                
                j$('#myModal').on('shown.bs.modal', function () {
                    //console.log(j$('#myModal').offset().top);
                    //console.log(li.offset().top);
                    console.log('showing modal');
                    // if(li.offset().top > 300) {
                    //     var modalOffset = li.offset().top-150;
                    //     //j$('#myModal').css('top', modalOffset+'px');
                    // }
                    
                }); 
                j$('#myModal').on('hidden.bs.modal', function () {
                    console.log('hiding modal');
                    j$(document).on("tap",'ul[id="list"] > li',goToDetailPage);
                });
                //sforce.one.navigateToURL(configUrl);
            }
            //addProduct(selectedProductId,options,'true');
            
        });
    }
  }

function addProductRemote(productName, productId,options, quantity) {
    // console.log(productName);
    // console.log(productId);
    // console.log(options);
    quantity = Number(quantity);
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.addProductRemote,
        productId,options,1,cartId,priceListId,quantity,
        function(result, event)
        {
            if(event.status)
            {
                console.log(result);
                console.timeEnd('addProductRemote');
                processConstraintRules(result.ruleResult);
                j$('.spinner-'+productId).toggle();
                j$('.plus-'+productId).toggle();
                //setTimeout(your_func, 5000);
                //process constraint rules after quantity update (just in case)
                //doRemoteProcessConstraintRules();
                //j$('.spinnerImg-'+ctxOptionId).hide();
                
                toastr.success(productName, "Product Added");
                //toastr.info('Added Product '+productId);
                cartProductIds.push(productId);
                showSearchResults3(currentPage);
                refreshCart();    
                return result;
            }
        }); 
}

function checkConstraintRules() {
    console.log('checkConstraintRules');
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.checkConstraintRules,
        cartId,
        function(result, event)
        {
            if(event.status)
            {
                processConstraintRules(result);
                console.log(result);
                return result;
            }
    }); 
}

function getProductInfosRemote(ruleAction, productIds) {
    console.log('getProductInfosRemote ');
    console.log(ruleAction);
    Visualforce.remoting.Manager.invokeAction(j$.APTTUS.QuoteDetailView.getProductInfos,
        productIds,
        function(result, event)
        {
            if(event.status)
            {
                console.log(result);
                if(result.length >0) {
                    var messageType = ruleAction.MessageType.toLowerCase();
                    console.log(messageType);
                    messageType = messageType == 'error'?'danger':messageType;
                    // var message = '<div class="panel panel-'+messageType+'"><div class="panel-heading">'+ruleAction.Message+'</div><div class="panel-body"></div></div>';
                    
                    var rulePanel =  j$(document.createElement('div'));
                    rulePanel.addClass('panel panel-'+messageType);
                    rulePanel.addClass('rulePanel');
                    rulePanel.attr('id',ruleAction.AppliedActionId);
                    rulePanel.append('<div class="panel-heading" onclick="j$(\'#'+ruleAction.AppliedActionId+'Body\').slideToggle(\'fast\');">'+ruleAction.Message+'</div>');

                    var ruleContainer =  j$(document.createElement('div'));
                    ruleContainer.addClass('panel-body');
                    ruleContainer.attr('id',ruleAction.AppliedActionId+'Body');
                    console.log('result.length '+result.length);
                    if(result.length == 0){
                        ruleContainer.css('display','none');
                    }

                    var list = j$(document.createElement('ul'));
                    list.addClass('ruleItems')
                    
                    j$.each(result, function(index, product){
                        var item = j$(document.createElement('li'));
                        item.attr('objId',product.Id);
                        item.addClass('flag flag--top active--list-1 pam border-bottom border--3 prodLine');
                        // if(selectedProductIds.indexOf(product.ProductId) > -1) {
                        //     item.attr('selected','true');
                        //     item.addClass('selectedProduct');
                        // }
                        var html = '';
                        // if(hideProductImages == 'false'){

                        //     html += '<div class="flag--image prm productImage">'+
                        //                 '<img src="'+product.ImageUrl+'" class="ht-75" alt="prodImage">'+
                        //             '</div>';
                        // }
                        html += '<div class="flag--body">'+
                                        '<span class="db text-color-1 f4">'+product.Name+'</span>'+
                                        '<span class="db text-color-2 f6">Starts at: $ 0</span>'+
                                        '<span class="db text-color-2 f6">Quantity: 1</span>'+
                                    '</div>';
                        if(!approvalPending && ruleAction.ActionType == 'Inclusion') {
                            html+='<div class="addButtonContainer"><button id="'+product.Id+'" prodName="'+product.Name+'" type="button" style="height:80%" class="addToCart has-spinner btn btn-default btn-md"><span class="glyphicon glyphicon-plus plus-'+product.Id+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.Id+'" style="display:none;"></span></button></div>';
                        }
                        else if(!approvalPending && ruleAction.ActionType == 'Exclusion') {
                            var lineItemId = j$('li[prodId="'+product.Id+'"]').attr('id');
                            console.log(lineItemId);
                            html+='<div class="addButtonContainer" onclick="deleteLineItem(\''+lineItemId+'\');"><button id="'+product.Id+'" prodName="'+product.Name+'" type="button" style="height:80%" class="has-spinner btn btn-default btn-md"><span class="glyphicon glyphicon-trash plus-'+product.Id+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.Id+'" style="display:none;"></span></button></div>';
                        }
                        else if(!approvalPending && ruleAction.ActionType == 'Replacement') {
                            var lineItemId = j$('li[prodId="'+product.Id+'"]').attr('id');
                            console.log(lineItemId);
                            html+='<div class="addButtonContainer" onclick="deleteLineItem(\''+lineItemId+'\');"><button id="'+product.Id+'" prodName="'+product.Name+'" type="button" style="height:80%" class="has-spinner btn btn-default btn-md"><span class="rotate90 glyphicon glyphicon-sort plus-'+product.Id+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.Id+'" style="display:none;"></span></button></div>';
                        }
                                    
                        item.html(html);
                        //var item = '<li class="flag flag--top active--list-1 pam border-bottom border--3" >'+product.Name+'</li>';
                        list.append(item);
                    });

                    ruleContainer.append(list);

                    rulePanel.append(ruleContainer);
                    

                    // var message = '<div class="panel panel-'+messageType+'"><div class="panel-heading">'+ruleAction.Message+'</div><div class="panel-body"><ul class="ruleItems"><li>'+result[0].Name+'<button class="btn bg-primary-btn btn--primary pvs size-full brm border border--1 wht f3 fw-semibold" onclick="addProductRemote(\''+result[0].Name+'\',\''+result[0].Id+'\',\'\');">Add</button></li></ul></div></div><br/>';
                    // // j$('#constraintRuleResult').append('<li>'+ruleAction.Message+'</li>');
                    // // j$('#constraintRuleResult').append('<li onclick="addProductRemote(\''+result[0].Name+'\',\''+result[0].Id+'\',\'\');">'+result[0].Name+'</li>');
                    
                    // j$('#constraintRuleResult').append(message);
                    //j$('#constraintRuleResult').append(rulePanel);
                    j$('#rulesPanel').append(rulePanel);
                }
                
                return result;
            }
        }); 
}


function getProductInfos(ruleAction, productIds) {
    //console.log(ruleAction);
    //console.log('getting these products');
    //console.log(productIds);
    var messageType = ruleAction.MessageType.toLowerCase();
    //console.log(messageType);
    messageType = messageType == 'error'?'danger':messageType;
    // var message = '<div class="panel panel-'+messageType+'"><div class="panel-heading">'+ruleAction.Message+'</div><div class="panel-body"></div></div>';
    
    var rulePanel =  j$(document.createElement('div'));
    rulePanel.addClass('panel panel-'+messageType);
    rulePanel.addClass('rulePanel');
    rulePanel.attr('id',ruleAction.AppliedActionId);
    rulePanel.append('<div class="panel-heading" objId="'+ruleAction.AppliedActionId+'" onclick="j$(\'#'+ruleAction.AppliedActionId+'Body\').slideToggle(\'fast\');">'+ruleAction.Message+'<span class="closeRule glyphicon glyphicon-remove"></span></div>');

    var ruleContainer =  j$(document.createElement('div'));
    ruleContainer.addClass('panel-body');
    ruleContainer.attr('id',ruleAction.AppliedActionId+'Body');

    var list = j$(document.createElement('ul'));
    list.addClass('ruleItems')
    var productResults = findProductsByIds(productIds);

    console.log('result.length '+productIds.length);
    if(productIds.length == 0){
        ruleContainer.css('display','none');
    }

    j$.each(productResults, function(index, product){
        var item = j$(document.createElement('li'));
        item.attr('objId',product.Id);
        item.addClass('flag flag--top active--list-1 pam border-bottom border--3 prodLine');
        // if(selectedProductIds.indexOf(product.ProductId) > -1) {
        //     item.attr('selected','true');
        //     item.addClass('selectedProduct');
        // }
        var html = '';

        var price;
            
        if(product.Price === undefined || product.Price == ''){
            price = '0.00';
        }else{
            price = parseFloat(product.Price).toFixed(2);
            price = numberWithCommas(price);
        }

        if(hideProductImages == 'false'){

            html += '<div class="flag--image prm productImage">'+
                        '<img src="'+product.ImageUrl+'" class="ht-75" alt="prodImage">'+
                    '</div>';
        }
        html += '<div class="flag--body">'+
                        '<span class="db text-color-1 f4">'+product.Name+'</span>'+
                        '<span class="db text-color-2 f6">Starts at: $'+price+'</span>'+
                        '<span class="db text-color-2 f6">Quantity: 1</span>'+
                    '</div>';
        if(!approvalPending && ruleAction.ActionType == 'Inclusion') {
            html+='<div class="addButtonContainer"><button id="'+product.ProductId+'" prodName="'+product.Name+'" type="button" style="height:80%" class="addToCart has-spinner btn btn-default btn-md"><span class="glyphicon glyphicon-plus plus-'+product.Id+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.Id+'" style="display:none;"></span></button></div>';
        }
        else if(!approvalPending && ruleAction.ActionType == 'Exclusion') {
            var lineItemId = j$('li[prodId="'+product.ProductId+'"]').attr('id');
            console.log(lineItemId);
            html+='<div class="addButtonContainer" onclick="deleteLineItem(\''+lineItemId+'\');"><button id="'+product.ProductId+'" prodName="'+product.Name+'" type="button" style="height:80%" class="has-spinner btn btn-default btn-md"><span class="glyphicon glyphicon-trash plus-'+product.ProductId+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.ProductId+'" style="display:none;"></span></button></div>';
        }
        else if(!approvalPending && ruleAction.ActionType == 'Replacement') {
            var lineItemId = j$('li[objid="'+ruleAction.TriggeringPrimaryNumbers[0]+'"]').attr('id');
            console.log(lineItemId);
            html+='<div class="addButtonContainer" onclick="deleteLineItem(\''+lineItemId+'\');"><button id="'+product.ProductId+'" prodName="'+product.Name+'" type="button" style="height:80%" class="addToCart has-spinner btn btn-default btn-md"><span class="rotate90 glyphicon glyphicon-sort plus-'+product.ProductId+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.ProductId+'" style="display:none;"></span></button></div>';
        }

                    
        item.html(html);
        //var item = '<li class="flag flag--top active--list-1 pam border-bottom border--3" >'+product.Name+'</li>';
        list.append(item);
    });

    ruleContainer.append(list);

    rulePanel.append(ruleContainer);
    
    // j$('#constraintRuleResult').append(rulePanel);
    j$('#rulesPanel').append(rulePanel);
                
}

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
        console.log('--------------------------------------');
        console.log(action.ActionIntent+' - '+action.Message);
        console.log('found lineNumber '+action.AffectedPrimaryNumbers[0]+' - '+j$('li[objId="'+action.AffectedPrimaryNumbers[0]+'"]').length);
        console.log(j$('li[objId="'+action.AffectedPrimaryNumbers[0]+'"]'));
        console.log(action);
        if(!action.IsIgnoredByUser) {
        if(j$('li[objId="'+action.AffectedPrimaryNumbers[0]+'"]').length == 0 || action.ActionIntent == 'Disable Selection') {
            if(action.MessageType == 'Error'){
                j$('#rulesIndicator').css('color','red');
                j$('#rulesIcon').css('color','red');
            }else {
                j$('#rulesIndicator').css('color','yellow');
                j$('#rulesIcon').css('color','yellow');
            }
            if(action.ActionIntent == 'Auto Include') {
                toastr.warning(action.Message);
                getProductInfos(action, new Array());
            }
            else if(action.ActionIntent == 'Prompt') {
                console.log('Prompt-----------');
                
                getProductInfos(action, action.SuggestedProductIds);
                showPrompt = true;
            }
            else if(action.ActionIntent == 'Show Message') {
                console.log('Show Message-----------');
                // console.log(action.Message);
                getProductInfos(action, action.SuggestedProductIds);
                showPrompt = true;
            }
            else if(action.ActionIntent == 'Disable Selection') {
                console.log('Disable Selection-----------');
                excludedProductIds = excludedProductIds.concat(action.SuggestedProductIds);
                var productsToExclude = new Array();
                j$.each(excludedProductIds, function(index,productId){
                    if(cartProductIds.indexOf(productId) > -1){
                        productsToExclude.push(productId);
                    }
                });
                console.log(action.SuggestedProductIds);
                console.log('excludedProductIds');
                console.log(excludedProductIds);
                getProductInfos(action, productsToExclude);
                
            } 
        }
        totalRules++;
        }
        
    });
    console.log('rulesBadge '+totalRules);
    j$('.rulesBadge').html(totalRules);
    j$(document).off("click",'.closeRule',ignoreRule).on("click",'.closeRule',ignoreRule);
    if(showPrompt) {
        //j$('#constraintModal').modal('show');
    }
}



function initializeSearchbox() {
    //console.log('in searchbox!!');
    //console.log(productNames.length);
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
        //j$('#promoBox').hide();
        //j$('.bundleProduct').hide();
        //j$('.productPanel').show();
    });

    j$("#typeahead").on('keypress',function(e) {  //free text search
        // console.log(j$("#typeahead").val());
        // console.log('you pressed '+e.keyCode);
        if(e.keyCode == 13)     {        
            //e.preventDefault();        
            var token = j$("#typeahead").val();
            console.log('searching '+token);
            j$('.search-result-txt').html(token);
            searchProducts(token);
            j$("#typeahead").blur(); //double blur to hide suggestions?
            j$("#typeahead").blur();
            //j$('#promoBox').hide();
            //j$('.bundleProduct').hide();
            //j$('.productPanel').show();
    }});

    searchProducts('');
}

function getCategoryProductsSearch(searchToken) {
    var resultCategory;
    j$.each(categories, function(index,category){
        //console.log('matching '+searchToken+' to '+category.Name+' - '+(category.Name == searchToken));
        if(category.Name == searchToken) {
            //console.log('match!');
            resultCategory = category;
        }
    });
    showSearchResults(resultCategory.Products);
}

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
    // console.log(productResults.length);
    // showSearchResults(productResults);
    //showSearchResults2(productResults);
    paginateSearchResults(productResults);
    return productResults;
}

    function menuAction(element) {
      // console.log(element);
      element = j$(element);
      console.log(j$('.menuList li'));
      j$('.menuActionItemActive').removeClass('menuActionItemActive');
      element.toggleClass('menuActionItemActive');
      var action = element.attr('action');
      if(action == 'menu') {
       // alert('menu');
       j$('#menuItems').toggle();
       if(j$('#menuItems').is(':hidden')){
        element.removeClass('menuActionItemActive');
       }
      }
      else if(action == 'commission') {
        j$('#menuItems').hide();
        j$('#commissionModal').modal('show');
      }
      else if(action == 'approval') {
        j$('#menuItems').hide();
        j$('#approvalModal').modal('show');
      }
      else if(action == 'rating') {
        j$('#menuItems').hide();
        // j$('#Searching_Modal').modal('show');
        // sforce.one.navigateToURL(analyzeDealPage);
      }
      else if(action == 'rule') {
        j$('#menuItems').hide();
        //j$('#constraintModal').modal('show');
      }
    }

function findProductsByIds(productIds) {
    console.log('findProductsByIds');
    var productResults = new Array();
    //console.log('searching through '+categories.length+' categories');
    j$.each(categories, function(index,category){
        // console.log('found '+category.Products.length);
        j$.each(category.Products, function(index,product){
            // console.log(product.Id);
            // console.log(productIds.indexOf(product.ProductId));
            if(productIds.indexOf(product.ProductId) > -1){
                // console.log('Found  with '+product.Name);
                productResults.push(product);
            }
        });
    });
    return productResults;
}

function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function showSearchResults(results) {

    var list = j$('#searchResults');
    list.html('');
    // j$('#totalResults').html('( '+results.length+' )');
    j$('.title').html('Catalog ( '+results.length+' )');
    // console.log('--------------search results---------------');
    // console.log(results.length);
    j$.each(results, function(index, product){
        var price;
        
        if(product.Price === undefined || product.Price == ''){
            price = '100.00';
        }else{
            price = parseFloat(product.Price).toFixed(2);
            price = numberWithCommas(price);
        }

        var item = j$(document.createElement('li'));
        item.attr('objId',product.ProductId);
        item.addClass('flag flag--top active--list-1 pam border-bottom border--3 prodLine');
        var excludedProduct = excludedProductIds.indexOf(product.ProductId) > -1;
        var addedProduct = cartProductIds.indexOf(product.ProductId) > -1?'inline':'none';
        // console.log('excludedProduct = '+excludedProduct);
        if(excludedProduct) {
            item.attr('excluded','true');
            item.addClass('excludedProduct');
        }
        if(selectedProductIds.indexOf(product.ProductId) > -1) {
            item.attr('selected','true');
            item.addClass('selectedProduct');
        }
        var html = '';
        html += '<div style="width:100%;">'+
                        '<span class="db text-color-1 f4"><input type="checkbox" class="selectItemCheck"/>'+product.Name+'</span>'+
                    '</div>';
        // if(hideProductImages == 'false'){
        html += '<div style="width:100%;">';
            html += '<div class="flag--image prm productImage ht-75">'+
                    '</div>';
        // }
        // if(addedProduct){

        //     html += '<div class="flag--image prm" style="width:25px; background-color:green;">'+
        //             '</div>';
        // }
        html += '<div class="flag--body">'+
                        '<span style="color:green; display:'+addedProduct+';">Added</span>'+
                        '<span class="db text-color-2 f6">Starts at: $'+price+'</span>'+
                        '<span class="db text-color-2 f6">Quantity: 1</span>'+
                    '</div>';
        if(!approvalPending && !excludedProduct) {
            html+='<div class="addButtonContainer"><button id="'+product.ProductId+'" prodName="'+product.Name+'" type="button" style="height:80%" class=" addToCart has-spinner btn btn-default btn-md"><span class="glyphicon glyphicon-plus plus-'+product.ProductId+'" ></span><span class="glyphicon glyphicon-refresh spin spinner-'+product.ProductId+'" style="display:none;"></span></button></div>';
        }
        html += '</div>'+
        // html+='<div class="addButtonContainer"><button id="'+product.ProductId+'" prodName="'+product.Name+'" type="button" style="height:80%" class=" addToCart has-spinner btn btn-primary btn-md"><span class="glyphicon glyphicon-info-sign plus-'+product.ProductId+'" ></span></button></div>';
                    
        item.html(html);
        //var item = '<li class="flag flag--top active--list-1 pam border-bottom border--3" >'+product.Name+'</li>';
        list.append(item);
    });

    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }

    j$(document).off('click','.addToCart').on('click','.addToCart',function(){
        console.log('selecting product');
        //j$(this).toggleClass('selected-option');
        selectedProductId = j$(this).attr('Id');
        var prodName = j$(this).attr('prodName');
        var quantity = j$('input[objId="'+selectedProductId+'"] input[type="number"]').val();
        console.log(quantity);
        j$('.spinner-'+selectedProductId).toggle();
        j$('.plus-'+selectedProductId).toggle();
        // j$(this).toggleClass('active');
        //j$(this).addClass('btn-success').addClass('glyphicon-ok');
        //j$('span.'+selectedProductId).addClass('btn-success');
        var options = '';
        // j$( ".option:checked" ).each(function( index ) {
        //     if(j$( this ).attr('id')){
        //         options = options + j$( this ).attr('id') + ',';
            
        //     }
        // });
        //console.log(options);
        options = options.substr(0,options.length - 1);
        
        // addProduct(selectedProductId,options,'true');

        addProductRemote(prodName,selectedProductId,options,1);
        
    });
}

function paginateSearchResults(results) {
    var pageNum = 0;
    productPages = [];
    j$('.title').html('Catalog ( '+results.length+' )');
    productPages[pageNum] = []; //initialize first page
    j$.each(results, function cycleProducts(index, product){
        productPages[pageNum].push(product);
        if(index % pageSize == 9){ //prepare next page
            pageNum++;
            productPages[pageNum] = [];
        }
        
    });
    showSearchResults3(0); //show first page
}

function showSearchResults3(pageNum) {

    //var list = j$('#searchResults');
    //list.html('');
    // j$('#totalResults').html('( '+results.length+' )');
    
    // console.log('--------------search results---------------');
    // console.log(results.length);
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
        product.Added = cartProductIds.indexOf(product.ProductId) > -1;
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

    $('.selectItemCheck').on('click',function selectItem(){
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
        // j$(this).toggleClass('active');
        //j$(this).addClass('btn-success').addClass('glyphicon-ok');
        //j$('span.'+selectedProductId).addClass('btn-success');
        var options = '';
        // j$( ".option:checked" ).each(function( index ) {
        //     if(j$( this ).attr('id')){
        //         options = options + j$( this ).attr('id') + ',';
            
        //     }
        // });
        //console.log(options);
        options = options.substr(0,options.length - 1);
        
        // addProduct(selectedProductId,options,'true');

        addProductRemote(prodName,selectedProductId,options,quantity);
        
    });
}

function showSearchResults2(results) {

    //var list = j$('#searchResults');
    //list.html('');
    // j$('#totalResults').html('( '+results.length+' )');
    j$('.title').html('Catalog ( '+results.length+' )');
    // console.log('--------------search results---------------');
    // console.log(results.length);
    var fragment = document.createDocumentFragment();
    var list = document.getElementById("searchResults");
    list.innerHTML = '';
    
    j$.each(results, function(index, product){
        
        var item =  document.createElement('li');
        item.className = 'listItem prodLine';
        item.setAttribute('objId',product.ProductId);

        var excludedProduct = excludedProductIds.indexOf(product.ProductId) > -1;
        product.Added = cartProductIds.indexOf(product.ProductId) > -1;
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

        item.innerHTML = tmpl("productItem", product);
        fragment.appendChild(item);
    });

    list.appendChild(fragment);

    if(hideProductImages == 'true'){
        j$('.productImage').hide();    
    }

    $('.selectItemCheck').on('click',function selectItem(){
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
        console.log(j$('.spinner-'+selectedProductId));
        j$('.spinner-'+selectedProductId).toggle();
        j$('.plus-'+selectedProductId).toggle();
        // j$(this).toggleClass('active');
        //j$(this).addClass('btn-success').addClass('glyphicon-ok');
        //j$('span.'+selectedProductId).addClass('btn-success');
        var options = '';
        // j$( ".option:checked" ).each(function( index ) {
        //     if(j$( this ).attr('id')){
        //         options = options + j$( this ).attr('id') + ',';
            
        //     }
        // });
        //console.log(options);
        options = options.substr(0,options.length - 1);
        
        // addProduct(selectedProductId,options,'true');

        addProductRemote(prodName,selectedProductId,options);
        
    });
}

function addMultipleProducts(element){
    console.log(this);
    j$.each(selectedProductIds, function multipleAddProductRemote(index, productId){
        addProductRemote('',productId,'');
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