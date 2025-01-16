var $ = jQuery.noConflict();
    
//Bar heights (need to be set here to set positioning on runtime)    
var quoteBarHeight = 46;
var menuBarHeight = 46;
var actionBarHeight = 46;
    
    
var windowSize = $(window).height();
var windowWidth = $(window).width();
var enableMiniCart = 'true';
var fixedBarMode = true;

console.log('window height: '+$(window).height());
console.log('window width: '+$(window).width());
    
j$.APTTUS = {};
j$.APTTUS.formatFields = function(one,two,three){};

var cartId = 'cartId';
var quoteId = 'quoteId';
var priceListId = 'priceListId';
var hasLineItems = 'true';
var approvalStatus = 'Approval Pending';
var approvalPending = 'false' == 'true'? true: false;
var namespace = '{!count}' == '1'?'Apttus_S1Demo__':'';
var hideProductImages = true;
var analyzeDealPage = '{!analyzeDeal}';

var openedOverlay = '';

j$.APTTUS.Label = {};
j$.APTTUS.Label.Remove = '{!$Label.Apttus_Config2__Remove}';

toastr.options = {
    "closeButton": true,
    "debug": false,
    "positionClass": "toast-show",
    "onclick": null,
    "showDuration": "4000",
    "hideDuration": "300",
    "timeOut": "2500",
    "extendedTimeOut": "1000",
    "showEasing": "swing",
    "hideEasing": "linear",
    "showMethod": "slideDown",
    "hideMethod": "slideUp"
}

var contentSize = windowSize - quoteBarHeight - menuBarHeight; //1px for weird semi-transparent border bug


$( "<style type=\"text/css\">#menuWindow { height:"+windowSize+"px; }</style>").appendTo( "head" );
//$( "<style type=\"text/css\">#cartInformation { right:-"+windowWidth+"px; }</style>").appendTo( "head" );

if(hideProductImages){
	$( "<style type=\"text/css\">.productImage { display: none !important; }</style>").appendTo( "head" );
}

$( "<style type=\"text/css\">#upper { height:"+quoteBarHeight+"px; line-height:"+quoteBarHeight+"px; }</style>").appendTo( "head" );
$( "<style type=\"text/css\">#bar { height:"+(menuBarHeight+1)+"px; line-height:"+menuBarHeight+"px; }</style>").appendTo( "head" );
$( "<style type=\"text/css\">.content { height: "+contentSize+"px; }</style>").appendTo( "head" );
$( "<style type=\"text/css\">#overflow { height: "+$(window).height()+"px; }</style>").appendTo( "head" );
$( "<style type=\"text/css\">.component { height: "+contentSize-70+"px }</style>").appendTo( "head" );
$( "<style type=\"text/css\">.overlayBody { height: "+contentSize-100+"px }</style>").appendTo( "head" );
$( "<style type=\"text/css\">.overlay { top:"+(quoteBarHeight+menuBarHeight+2)+"px !important; }</style>").appendTo( "head" );


var pricingUrl = '/apex/SF1Cart?cartId={!cartId}&quoteId={!propId}';

//$('#cartInformation').css('right','-'+windowWidth+'px');
//$('#menuWindow').css('left','-'+windowWidth+'px');
// $('div[data-role="page"]').on("pageinit",function() {
// 	checkConstraintRules();
// });
 $(document).ready(function(){
//$('div[data-role="page"]').on("pageinit",function() {
	console.log('sf1 header ready');  
	// console.log(windowWidth);
	$( "<style type=\"text/css\">.content { height: "+contentSize-actionBarHeight+"px !important; }</style>").appendTo( "head" );
	console.log('content size = '+contentSize);

	$('#lower').css('height',contentSize+'px');
	$('.content').css('height',contentSize-actionBarHeight+'px');
	$('.component').css('height',contentSize-actionBarHeight+'px');
//	$('#quoteInfoFields').css('height',contentSize-100+'px');
	$('.overlayBody').css('height',contentSize-actionBarHeight+'px');
	//$('#list').css('height',contentSize-20);

    $(document).on('scroll', function scrollingDocument(){
        if ($('#bar')[0].offsetTop < $(document).scrollTop()){
            $("#bar").css({position: "fixed", top:0});
            //console.log('fixed');
        }
        if ($(document).scrollTop() < $(".position-saver")[0].offsetTop){
            $("#bar").css({position: "static", top: 0});           
            //console.log('static');
            //$("#upper").delay(1000).slideUp(300);
        }            
    });

  
    $('#quoteTitle').off('click').on('click',function upperBarListener(){
        $('.quoteCaret').toggleClass('glyphicon-chevron-down');
        $('.quoteCaret').toggleClass('glyphicon-chevron-up');
        toggleIconBar();
        console.log('clicked upper');
    });

//   $('.title').off('click').on('click',function quoteBarListener(){
//   	toggleQuoteBar();
//    console.log('clicked bar');
//  });
  

  $('#bar > span').off('click').on('click',function barIconListener(){
      var target = String(this.getAttribute('data-target'));
      var element = this;
      closedAllOverlays(function(){ openOverlay(element,target);});

  });
  

   $('#searchIcon').off('click').on('click',function searchIconListener(){
   	$('#searchBox').toggleClass('hide');
   });
  
  	$('#menuIcon').off('click').on('click',function() {
  		menuIconListener();
  	});


  
    $('#lower').scroll(function() {
    	
      var pos = $('#lower').scrollTop();
      if (pos === 0) {
          $("#upper").slideDown();
          contentSize = windowSize - 80;
          $('#lower').css('height',contentSize+'px');
      }
      else {
        if($("#upper").is(":visible")){
          $("#upper").slideUp();
          contentSize = windowSize - 50;
          $('#lower').css('height',contentSize+'px');
        }

      }
    });

    if(!fixedBarMode){
	    $('.content').scroll(function contentScrollListener() {
	      var pos = $('.content').scrollTop();
	      if (pos === 0) {
	          	$("#bar").slideDown();
	          	$('.quoteCaret').removeClass('glyphicon-chevron-down');
    			$('.quoteCaret').addClass('glyphicon-chevron-up');
	          	contentSize = windowSize - 80;
	          	$('.content').css('height',contentSize+'px');
	      }
	      else {
	        if($("#bar").is(":visible")){
	          	$("#bar").slideUp();
	          	$('.quoteCaret').addClass('glyphicon-chevron-down');
    			$('.quoteCaret').removeClass('glyphicon-chevron-up');
	          	contentSize = windowSize - 50;
	          	$('.content').css('height',contentSize+'px');
	        }

	      }
	    });	
    }

    $(document).on("click", "#backIcon", function(){
		drillNavigation('home');
	});

    //listener activates spinners on buttons
    $('.has-spinner').off('click').on('click',function spinnerListener(){
    	var btnId = $(this).attr('Id');
    	toggleSpinner(btnId)
    });
	

    //Check constraint rules, gotta make this into a component
	//checkConstraintRules();
     
     
    console.log('catalog stuff');

    if(hideProductImages == 'true'){
        $('.productImage').hide();    
    }

    if(approvalPending) {
        console.log('block everything');
    }
    else {
        console.log('no worries');  
    }

    // checkConstraintRules();



    $('#locationIcon').on('click', function showLocationBox(){
        $('#locationBox').slideToggle();
    });

    $(document).on('click','.listItemButton',function(e) { //product info
        drillNavigation('about');
       // console.log(j$(this).attr('objId'));
       // e.preventDefault();
//       var productIds = [j$(this).attr('objId')];
//       var productResults = findProductsByIds(productIds);
//       selectedProd = productResults[0];
//       $('#productTitle').html(selectedProd.Name);
//       setupProduct(j$(this).attr('objId'));
//       $('.detailAddProduct').attr('id',j$(this).attr('objId'));
//       $('.detailAddProduct').attr('prodName',selectedProd.Name);
       // console.log(productResults);
       // loadProductInfoDialog(productResults[0]);

        $(document).off('click','.detailAddProduct').on('click','.detailAddProduct',function(){
            console.log('selecting product');
            //j$(this).toggleClass('selected-option');
            selectedProductId = j$(this).attr('Id');
            var prodName = j$(this).attr('prodName');
            var quantity = j$('.quantityDrillDown[objId="'+selectedProductId+'"]').val();
            console.log(quantity);
            j$('.spinner-'+selectedProductId).toggle();
            j$('.plus-'+selectedProductId).toggle();
            // j$(this).toggleClass('active');
            //j$(this).addClass('btn-success').addClass('glyphicon-ok');
            //j$('span.'+selectedProductId).addClass('btn-success');
            var options = '';
            options = options.substr(0,options.length - 1);

            // addProduct(selectedProductId,options,'true');
            toastr.success("Product Name", "Product Added");
//            addProductRemote(prodName,selectedProductId,options,quantity);

        });
    });
     
     $(document).off('click','.addToCart').on('click','.addToCart',function(){
        console.log('selecting product');
        //j$(this).toggleClass('selected-option');
        selectedProductId = j$(this).attr('Id');
//        var prodName = j$(this).attr('prodName');
//        var quantity = j$('input[objId="'+selectedProductId+'"] input[type="number"]').val();
//        console.log(quantity);
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
        toastr.success("Product Name", "Product Added");
         if(!$("#bar").is(":visible")){
            toggleIconBar();             
         }

        // addProduct(selectedProductId,options,'true');

//        addProductRemote(prodName,selectedProductId,options,1);
        
    });
     
    setupOverflow();

});

function setupOverflow() {
    $('.md-trigger').off('click').on('click', function() {
        
        $('.md-overlay').addClass('md-show');
        var overflowMenuId = '#'+$(this).attr('data-modal');
        var overflowMenu = $(overflowMenuId);
        overflowMenu.addClass('md-show');
        $('.md-overlay').off('click').on('click', function() {
            overflowMenu.removeClass('md-show');
            $('.md-overlay').removeClass('md-show');
        });
    });
}

function closedAllOverlays(callback){
    
    $('.overlay').addClass('closed');
    console.log('close overlays');
    $('.activeBarIcon').removeClass('activeBarIcon');
    callback();
}

function openOverlay(element,target) {
    console.log('open overlay '+target);
    console.log(element);
    if(openedOverlay != target) {
        if(target.substring(0, 1)  == '#') { //target is div
            $(element).toggleClass('activeBarIcon');
            $(target).css('height',contentSize+'px');
            $(target).css('max-height',contentSize+'px');
            $(target).toggleClass('closed');
        } else { //target is link
            console.log('link target');
            //sforce something
        }
        openedOverlay = target;
    }
    else {
        openedOverlay = ''; //reset opened overlay as it was closed   
    }
}


function toggleDrilldownPanel(button, panelId) {
    var panel  = $('#'+panelId);
    var toggleButton = $(button).find('span');
    panel.slideToggle('fast');
    console.log(panelId);
    toggleButton.toggleClass('glyphicon-chevron-up');
    toggleButton.toggleClass('glyphicon-chevron-down');
}

function toggleRulePanel(button, panelId) {
    var panel  = $('#'+panelId);
    var toggleButton = $(button).find('.ruleToggle > span');
    panel.slideToggle('fast');
    console.log(panelId);
    toggleButton.toggleClass('glyphicon-chevron-up');
    toggleButton.toggleClass('glyphicon-chevron-down');
}

function menuIconListener(){
 	console.log('clicked menu');
	//loadTree();
    if($("#sf1App").hasClass("menuOpen")){
//      	$('#menuWindow').removeClass('animate');
        $('#sf1App').removeClass('menuOpen');
    }
    else {
	    if($("#upper").is(":visible")){
	        $('#menuWindow').css('height',$(window).height()+'px');
//	        $('#menuWindow').css('top',0);
//            $('#sf1App').addClass('menuOpen');
	    }
	    else {
	        $('#menuWindow').css('height',windowSize+'px');
	        $('#menuWindow').css('top',menuBarHeight+'px');
	    }
	    //$('#menuWindow').show();
//	    $('#menuWindow').addClass('animate');
        $('#sf1App').addClass('menuOpen');
    }
}

function toggleSpinner(btnId) {
	if(btnId) {
		$('.title-'+btnId).toggle(); //hide btn text
    	$('.spinner-'+btnId).toggle(); //show spinner	
	}
}

function goToPricingPage() {
	//sforce.one.navigateToURL(pricingUrl);
    window.location = 'cart.html';
}
    
function goToCatalog() {
    //sforce.one.navigateToURL('/apex/mobileCartCatalog2?id={!propId}');
    window.location = 'app.html';
}

function toggleIconBar() {
    if($("#bar").is(":visible")){
        console.log('bar showing');
        $('.content').css('height',contentSize-actionBarHeight+menuBarHeight+'px');
        $('.overlay').css('height',contentSize-actionBarHeight+menuBarHeight+'px');
    }
    else {
        console.log('bar hidden');
        $('.content').css('height',contentSize-actionBarHeight+'px');
        $('.overlay').css('height',contentSize-actionBarHeight+'px');
    }
    $('#bar').slideToggle();
}

function toggleQuoteBar(){
    if($("#upper").is(":visible")){
      	console.log('hiding bar');
      	$("#upper").slideUp();
      	contentSize = windowSize - 50;
      	$('.content').css('height',contentSize+'px');
    }
    else {
    	console.log('showing bar');
        $("#upper").slideDown();
        contentSize = windowSize - 80;
        $('.content').css('height',contentSize+'px');
    }
}

function scrollToTop(){
	$('.content').animate({
		   scrollTop: 0
		}, 'slow');
}

function drillNavigation(target){
    $("#bigbox").removeClass(); 
    $('.container').removeClass('fixedPlace');
    $("#bigbox").addClass("transition "+target+"_inside");
     	if(target == 'home') {
       		$('#backIcon').hide();
     	}
     	else {
     		// $('#'+target+'_content').addClass('fixedPlace');
        	$('#backIcon').show();
     	}
}

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
(function(){
  var cache = {};
 
  this.tmpl = function tmpl(str, data){
    // Figure out if we're getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var fn = !/\W/.test(str) ?
      cache[str] = cache[str] ||
        tmpl(document.getElementById(str).innerHTML) :
     
      // Generate a reusable function that will serve as a template
      // generator (and which will be cached).
      new Function("obj",
        "var p=[],print=function(){p.push.apply(p,arguments);};" +
       
        // Introduce the data as local variables using with(){}
        "with(obj){p.push('" +
       
        // Convert the template into pure JavaScript
        str
          .replace(/[\r\t\n]/g, " ")
          .split("<%").join("\t")
          .replace(/((^|%>)[^\t]*)'/g, "$1\r")
          .replace(/\t=(.*?)%>/g, "',$1,'")
          .split("\t").join("');")
          .split("%>").join("p.push('")
          .split("\r").join("\\'")
      + "');}return p.join('');");
   
    // Provide some basic currying to the user
    return data ? fn( data ) : fn;
  };
})();



/* CART JS */

