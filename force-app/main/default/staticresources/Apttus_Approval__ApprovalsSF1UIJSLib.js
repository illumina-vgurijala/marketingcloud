// This to make sure jQuery doesn't conflict with any other JS libraries
j$ = jQuery.noConflict();

//Bar heights (need to be set here to set positioning on runtime)    
var quoteBarHeight = 46;
var menuBarHeight = 46;
var actionBarHeight = 46;
    
    
var windowSize = j$(window).height();
var windowWidth = j$(window).width();
var hideProductImages = 'true';
var fixedBarMode = true;

//console.log('window height: '+j$(window).height());
//console.log('window width: '+j$(window).width());
    

var openedOverlay = '';
var drillDownFunction;
var drillDownObjId = '';
var drillDownStepRequestObj;


var contentSize = windowSize; //1px for weird semi-transparent border bug


j$( "<style type=\"text/css\">#menuWindow { height:"+windowSize+"px; }</style>").appendTo( "head" );
//$( "<style type=\"text/css\">#cartInformation { right:-"+windowWidth+"px; }</style>").appendTo( "head" );

if(hideProductImages){
    j$( "<style type=\"text/css\">.productImage { display: none !important; }</style>").appendTo( "head" );
}

j$( "<style type=\"text/css\">#upper { height:"+quoteBarHeight+"px; line-height:"+quoteBarHeight+"px; }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">#bar { height:"+(menuBarHeight+1)+"px; line-height:"+menuBarHeight+"px; }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">.content { height: "+contentSize+"px; }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">#overflow { height: "+j$(window).height()+"px; }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">.component { height: "+windowSize+"px }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">.overlayBody { height: "+contentSize-100+"px }</style>").appendTo( "head" );
j$( "<style type=\"text/css\">.overlay { top:"+(quoteBarHeight+menuBarHeight+2)+"px !important; }</style>").appendTo( "head" );




//$('#cartInformation').css('right','-'+windowWidth+'px');
//$('#menuWindow').css('left','-'+windowWidth+'px');
// j$('div[data-role="page"]').on("pageinit",function() {
// 	// checkConstraintRules();
//   console.log('pageinit');
// });


j$(document).ready(function(){

	//j$('div[data-role="page"]').on("pageinit",function() {
    //console.log('sf1 header ready');  
    //console.log(windowWidth);
    j$( "<style type=\"text/css\">.content { height: "+contentSize-actionBarHeight+"px !important; }</style>").appendTo( "head" );
    //console.log('content size = '+contentSize);

    j$('.content').css('height',contentSize+'px');
    j$('.component').css('height',contentSize+'px');
	//$('#quoteInfoFields').css('height',contentSize-100+'px');
    j$('.overlayBody').css('height',contentSize-actionBarHeight+'px');
    //$('#list').css('height',contentSize-20);

	//console.log('j$='+j$);
	//console.log('setup event handler for backIcon...');
    //j$(document).on("click", "#backIcon", function(){
	//	drillNavigation('home');
	//});
	//j$("#backIcon").bind("click", function() {
	//	drillNavigation('home');
	//});

    // listener activates spinners on buttons
    //console.log('setup event handler for spinner...');
    //j$('.has-spinner').off('click').on('click',function spinnerListener(){
    //	var btnId = j$(this).attr('Id');
    //	toggleSpinner(btnId)
    //});
	
	//console.log('setup overflow...');
    setupOverflow();

});


/**
 * Navigate back and forth between views
 * @param  {[type]} target [description]
 * @return {[type]}        [description]
 */
function drillNavigation(target){
	//console.log('drillNavigation, target='+target);  
    j$("#bigbox").removeClass(); 
    j$('.container').removeClass('fixedPlace');
    j$("#bigbox").addClass("transition "+target+"_inside");
 	if(target == 'home') {
   		j$('#backIcon').hide();
 	}
 	else {
 		// $('#'+target+'_content').addClass('fixedPlace');
    	j$('#backIcon').show();
 	}
	//console.log('drillNavigation COMPLETE.');  
}


/**
 * Setup overflow menu
 * @return {[type]} [description]
 */
function setupOverflow() {
    j$('.md-trigger').off('click').on('click', function() {
        j$('.md-overlay').addClass('md-show');
        var overflowMenuId = '#'+j$(this).attr('data-modal');
        var overflowMenu = j$(overflowMenuId);
        overflowMenu.addClass('md-show');
        j$('.md-overlay').off('click').on('click', function() {
            overflowMenu.removeClass('md-show');
            j$('.md-overlay').removeClass('md-show');
        });
        j$('.closeOverflow').off('click').on('click', function() {
            overflowMenu.removeClass('md-show');
            j$('.md-overlay').removeClass('md-show');
        });
    });
}


function drillDownSetup(element) {
	//console.log('element='+element);
	drillNavigation('about');
	//console.log('drilling down');
	
	drillDownObjId = j$(element).attr('objId');
	//console.log('drillDownObjId='+drillDownObjId);
	
	//console.log('drillDownFunction='+drillDownFunction);
	if (drillDownFunction) {
	    drillDownFunction(drillDownObjId,drillDownStepRequestObj);    
	}
}

/**
 * Close overflow menus
 * @return {[type]} [description]
 */
function  closeOverflow() {
    j$('.md-modal').removeClass('md-show');
    j$('.md-overlay').removeClass('md-show');
}

/**
 * Close header overlays and open one if requested
 * @param  {Function} callback [description]
 * @return {[type]}            [description]
 */
function closedAllOverlays(callback){
    j$('.overlay').addClass('closed');
    //console.log('close overlays');
    j$('.aptActiveBarIcon').removeClass('aptActiveBarIcon');
    if(callback) {
        callback();    
    }
    
}

/**
 * Open a particular header overlay
 * @param  {[type]} element [description]
 * @param  {[type]} target  [description]
 * @return {[type]}         [description]
 */
function openOverlay(element,target) {
    //console.log('open overlay '+target);
    //console.log(element);
    if(openedOverlay != target) {
        if(target.substring(0, 1)  == '#') { //target is div
            j$(element).toggleClass('aptActiveBarIcon');
            j$(target).css('height',contentSize+'px');
            j$(target).css('max-height',contentSize+'px');
            j$(target).toggleClass('closed');
        } else { //target is link
            //console.log('link target');
            //sforce something
        }
        openedOverlay = target;
    }
    else {
        openedOverlay = ''; //reset opened overlay as it was closed   
    }
}

/**
 * Toggle the visibility of a particular panel in the drilldown
 * @param  {[type]} button  [description]
 * @param  {[type]} panelId [description]
 * @return {[type]}         [description]
 */
function toggleDrilldownPanel(button, panelId) {
    var panel  = j$('#'+panelId);
    var toggleButton = j$(button).find('span');
    panel.slideToggle('fast');
    //console.log(panelId);
    toggleButton.toggleClass('glyphicon-chevron-up');
    toggleButton.toggleClass('glyphicon-chevron-down');
}


/**
 * Toggle visibility of the suggested products for a rule
 * @param  {[type]} button  [description]
 * @param  {[type]} panelId [description]
 * @return {[type]}         [description]
 */
function toggleRulePanel(button, panelId) {
    var panel  = j$('#'+panelId);
    var toggleButton = j$(button).find('.ruleToggle > span');
    panel.slideToggle('fast');
    //console.log(panelId);
    toggleButton.toggleClass('glyphicon-chevron-up');
    toggleButton.toggleClass('glyphicon-chevron-down');
}

/**
 * Shows the push menu
 * @return {[type]} [description]
 */
function menuIconListener(){
  //console.log('clicked menu');
  if(j$.APTTUS.enableCategoryTree) {
    loadTree();
    j$('#browseCategoriesIcon').show();
  } else {
    j$('#browseCategoriesIcon').hide();
  }
    if(j$("#header").hasClass("aptMenuOpen")){
        j$('#menuWindow').removeClass('openMenu');
        j$('#header').removeClass('aptMenuOpen');
        j$('#pageContainer').removeClass('aptMenuOpen');
        j$('.overlay').removeClass('aptMenuOpen');
    }
    else {
      if(j$("#upper").is(":visible")){
          j$('#menuWindow').css('height',j$(window).height()+'px');
//          $('#menuWindow').css('top',0);
//            $('#sf1App').addClass('aptMenuOpen');
      }
      else {
          j$('#menuWindow').css('height',windowSize+'px');
          j$('#menuWindow').css('top',menuBarHeight+'px');
      }
      //$('#menuWindow').show();
        j$('#menuWindow').addClass('openMenu');
        j$('#header').addClass('aptMenuOpen');
        j$('#pageContainer').addClass('aptMenuOpen');
        j$('.overlay').addClass('aptMenuOpen');
    }
}

/**
 * Toggle spinner visibility for a particular button
 * @param  {[type]} btnId [description]
 * @return {[type]}       [description]
 */
function toggleSpinner(btnId) {
	if(btnId) {
		j$('.title-'+btnId).toggle(); //hide btn text
    j$('.spinner-'+btnId).toggle(); //show spinner	
	}
}

function goToPricingPage() {
  //console.log(pricingUrl);
	sforce.one.navigateToURL(pricingUrl);
}
    
function goToCatalog() {
    //console.log(catalogUrl);
    sforce.one.navigateToURL(catalogUrl);
}

/**
 * Toggle the visibility of the quote bar
 * @return {[type]} [description]
 */
function toggleQuoteBar(){
    if(j$("#upper").is(":visible")){
      	//console.log('hiding bar');
      	j$("#upper").slideUp();
      	contentSize = windowSize - 50;
      	j$('.content').css('height',contentSize+'px');
    }
    else {
    	//console.log('showing bar');
        j$("#upper").slideDown();
        contentSize = windowSize - 80;
        j$('.content').css('height',contentSize+'px');
    }
}

/**
 * Toggle Icon Bar
 * @return {[type]} [description]
 */
function toggleIconBar() {
    if(j$("#bar").is(":visible")){
        //console.log('bar showing');
        j$('.content').css('height',contentSize-actionBarHeight+menuBarHeight+'px');
        j$('.overlay').css('height',contentSize-actionBarHeight+menuBarHeight+'px');
    }
    else {
        //console.log('bar hidden');
        j$('.content').css('height',contentSize-actionBarHeight+'px');
        j$('.overlay').css('height',contentSize-actionBarHeight+'px');
    }
    j$('#bar').slideToggle();
}


/**
 * Scroll to the top of the page
 * @return {[type]} [description]
 */
function scrollToTop(){
	j$('.content').animate({
		   scrollTop: 0
		}, 'slow');
}

/**
 * Javascript Templating
 * Originally by John Resig - http://ejohn.org/ - MIT Licensed
 * @return {[type]} [description]
 */
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

