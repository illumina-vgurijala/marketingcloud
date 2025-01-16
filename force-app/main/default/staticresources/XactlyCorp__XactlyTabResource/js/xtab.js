/*
 *
 *xactly tab js
 * Copyrights-2013@Xactlycorp.com
 * @author rdas
 *
 * */
/*intialize the cover flow sliding menu*/
var enableSlidingMenu=function(){
	if($('#contentSlider-2 ul').find('li').size() > 0){
		$('#contentSlider-2').coverFlow({
				'initialFocus' : 0, //the index of the slide you want to be focused on load
				'speed' : 200, // the speed of the animation
				'addClasses' : "", //classes to add to the slider
				afterChange : function(index) {					
					
				} //executes after the slide has changed
			});	
	}else{
		return false;
	}
	
}

jQuery(".rankingGroupSelect").live("click", function(event) {
	event.preventDefault();
	var endPointUrl = jQuery(this).children('input[type=hidden]').val();
	wait();
	setTimeout(reloadRankingData(endPointUrl), 1000);
});

/*method to animate the attainment progress bar*/
var initProgressBar = function() {
	jQuery('.repui-progressbar').each(function() {
		//initialize the progress bar
		jQuery(this).progressbar({
			value : 0.01
		})

		var _parcent = "";
		_parcent = jQuery.trim(jQuery(this).next(".attainment").text());
		jQuery(this).children('.ui-progressbar-value').animate({
			width : _parcent,
			queue : false
		}, 3000)
	})
}
/*method to load the incentive statement post login*/
var loadIncentiveStatement = function() {
	var loggedIn = $("#isLoggedIn").val();
	var showData = $("#isShowData").val();
	if (loggedIn == 'true') {
		wait();
		loadStatement();
	}
}
/*method to load the individual ranking pod*/
var loadRankingPod = function() {
	var loggedIn = $("#isLoggedIn").val();
	var showData = $("#isShowData").val();
	if (loggedIn == 'true' && showData == 'false') {
		wait();
		reloadRankingPod();
	}
}
/*method to load the team ranking detail data*/
var loadRankingData = function() {
	var loggedIn = $("#isLoggedIn").val();
	var showData = $("#isShowRanking").val();
	if (loggedIn == 'true' && showData == 'true') {
		wait();
		var endPointUrl = '';
		reloadRankingData(endPointUrl)

	} else {
		return false;
	}
}
/*jquery block UI for ajax loader image*/
var wait = function() {
	$.blockUI({
		message : $("#pageLoader"),
		showOverlay : false,
		css : {
			border : 'none',
			padding : '15px',
			background: 'transparent',
			height : '40px'

		}
	});
}
/*method to call post ajax*/
var waitBottom=function(){
	setTimeout(wait(),1000);
}
var ajaxCompleteBottom=function(){
	 ajaxComplete();
}
/*method to call post ajax*/
var ajaxComplete = function() {
	$.unblockUI();
	var loggedIn = $("#isLoggedIn").val();
	var showRanking=$("#isShowRanking").val();
	
	/*if($('.msgDiv').find('.error-component').length > 0){
		$('.main-container').remove();
	}*/
	if (loggedIn == 'false') {
		
		/*$(".links-div").hide();
		$("#trophy-icon-dark").hide();
		$("#trophy-icon-transparent").fadeIn('slow');
		$("#attainment-count").hide();*/
		$("#sliderMenu").remove();
	}else if(showRanking=='false'){
		$("#trophy-icon-dark").hide();
		$("#trophy-icon-transparent").fadeIn('slow');
		$("#attainment-count").css('display','none');
	} else {
		return false;
	}
}
/*enable trophy icon if 100% attainment count >0 */
var enableTrophyIcon = function() {
	var _attainmentCount = 0;

	_attainmentCount = $("#attainmentCount").val();

	if (_attainmentCount >= 1) {
		$("#attainment-count").css('display','inline-block');
		$("#attainment-count").text(_attainmentCount);
		$("#trophy-icon-transparent").hide();
		$("#trophy-icon-dark").fadeIn('slow');
	} else {
		$("#trophy-icon-dark").hide();
		$("#trophy-icon-transparent").fadeIn('slow');
	}

}
/*scripts to execute on document ready*/
$(document).ready(function(){

	var loggedIn = $("#isLoggedIn").val();
	var showStatement = $("#isShowData").val();
	var showRanking=$("#isShowRanking").val();
	//loadIncentiveStatement();
	
	if(loggedIn==='true' && showRanking==='true'){
		jQuery('.repui-progressbar').each(function() {
		//initialize the progress bar
		jQuery(this).progressbar({
			value : 0.01
		})

		var _parcent = jQuery.trim(jQuery(this).next(".attainment").text());
		jQuery(this).children('.ui-progressbar-value').animate({
			width : _parcent,
			queue : false
			}, 1500)
		})
		
		
		enableSlidingMenu();
		loadRankingData();
	}else if(loggedIn==='true' && showStatement==='true'){
			resetSlidingMenu();		
		
	}	
$("#show-statement").on("click", function(event) {
		//disable normal link behaviour
		$(this).children('img').addClass('link-show-statement');
		$("#show-ranking").children('img').removeClass('link-show-ranking');
		

});
$("#show-ranking").on("click", function(event) {
			$(this).children('img').addClass('link-show-ranking');
			$("#show-statement").children('img').removeClass('link-show-statement');			
			
		

});
	/*scrips to show hide diff quarter values for incentive statement page. TODO::Can it be Re factored?*/
			$("#payment-q1").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#quota-q1').attr('class',styleClass);
                $(".q2, .q3, .q4").hide();                
                $(".q1").fadeIn('slow');
            })
            
             $("#payment-q2").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#quota-q2').attr('class',styleClass);
                $(".q1, .q3, .q4").hide();                
                $(".q2").fadeIn('slow');
            })
            $("#payment-q3").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#quota-q3').attr('class',styleClass);
                $(".q1, .q2, .q4").hide();                
                $(".q3").fadeIn('slow');
            })
            $("#payment-q4").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#quota-q4').attr('class',styleClass);
                $(".q1, .q2, .q3").hide();                
                $(".q4").fadeIn('slow');
            })
            
            
            
            $("#quota-q1").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#payment-q1').attr('class',styleClass);
                $(".q2, .q3, .q4").hide();                
                $(".q1").fadeIn('slow');
            })
            
             $("#quota-q2").live("click",function(event){               
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#payment-q2').attr('class',styleClass);
                $(".q1, .q3, .q4").hide();                
                $(".q2").fadeIn('slow');
            })
            $("#quota-q3").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#payment-q3').attr('class',styleClass);
                $(".q1, .q2, .q4").hide();                
                $(".q3").fadeIn('slow');
            })
            $("#quota-q4").live("click",function(event){                
                var styleClass=$('.xtab-selected-quarter').attr('class');
                $('.xtab-selected-quarter').attr('class','');
                $(this).attr('class',styleClass);
                $('#payment-q4').attr('class',styleClass);
                $(".q1, .q2, .q3").hide();                
                $(".q4").fadeIn('slow');
            })

});


/*properties for attainment gauges*/
 var opts = {
                lines : 12, // The number of lines to draw
                angle : 0.15, // The length of each line
                lineWidth : 0.44, // The line thickness
                pointer : {
                    length : 0.73, // The radius of the inner circle
                    strokeWidth : 0.038, // The rotation offset
                    color : '#000000' // Fill color
                },
                limitMax : 'false', // If true, the pointer will not go past the end of the gauge

                colorStart : '#F7901E', // Colors
                colorStop : '#F7901E', // just experiment with them
                strokeColor : '#E0E0E0', // to see which ones work best for you
                generateGradient : true
           };
 /*function to be called after incentive statement DOM is loaded*/
  var resetSlidingMenu=function(){
            
             var canvas_elements = document.getElementsByClassName('gauges-canvas');
                for (var i = 0; i < canvas_elements.length; ++i) {
                    var target = canvas_elements[i];
                    // your canvas element
                    var title=$(target).attr('title');
                    title=title.replace(',', '');
                    var gauge = new Gauge(target).setOptions(opts);
                    gauge.maxValue =100;// set max gauge value
                    gauge.animationSpeed = 32;// set animation speed (32 is default value)
                    /*
                     * DRC-306: fix issue with negative atainment value
                     */
                    if(title!=null && title!='' && title.indexOf('-') > -1){
                    	gauge.set(0);
                    }else{
                    	var gaugeVal=parseInt(title,10);
                    	if(gaugeVal > 100){
                        	gauge.maxValue =gaugeVal;//reset the max value if it is more than 100%
                    	}
                    	gauge.set(gaugeVal);
                    }                    
                }  
            
           if($('#contentSlider ul').find('li').size() > 0){
           		$('#contentSlider').coverFlow({
                'initialFocus' : 0, //the index of the slide you want to be focused on load
                'speed' : 200, // the speed of the animation
                'addClasses' : "custom-slider-container", //classes to add to the slider
                afterChange : function(index) {                   
                } //executes after the slide has changed
            });
           }  else{
           	console.log('slider not created');
           	 	return false;
           }                                
                        
            
            
 	}