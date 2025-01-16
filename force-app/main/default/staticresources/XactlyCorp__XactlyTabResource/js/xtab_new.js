/*
 *
 *xactly tab js
 * Copyrights-2013@Xactlycorp.com
 * @author rdas
 *
 * */

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
var obj = {
    divs : ["q1", "q2", "q3", "q4", "yr"]
    
}
/*var loadSection = function(elem, name){
    
    var divs = ["q1", "q2", "q3", "q4", "yr"];
    var i;
    for(i in divs){
        if(divs[i] != name){
            $('.'+divs[i]).hide(); 
        }else{
            $('.'+divs[i]).fadeIn('slow');
        }
    }
    
   clearSelection();
    
     $('.'+name+'-btn').each(function(){
                $(this).addClass('xtab-selected-quarter');
    });
}*/

var loadSection = function(elem, name, section){
    
    var i;
    for(i in obj.divs){
        if(obj.divs[i] != name){
            $('.'+obj.divs[i]+'-'+section).addClass('xtab-hidden');
			
			if($('.'+obj.divs[i]+'-'+section+'-btn').hasClass('xtab-selected-quarter')){
				$('.'+obj.divs[i]+'-'+section+'-btn').removeClass('xtab-selected-quarter');
			}
			
        }else{
            $('.'+obj.divs[i]+'-'+section).removeClass('xtab-hidden');
			$('.'+obj.divs[i]+'-'+section+'-btn').addClass('xtab-selected-quarter');
        }
    }
    
  // clearSelection();
    
 /*    $('.'+name+'-btn').each(function(){
                $(this).addClass('xtab-selected-quarter');
    });*/
}

var clearSelection = function(){
    $('.xtab-selected-quarter').each(function(){
        $(this).removeClass('xtab-selected-quarter');
    });
}

/*properties for attainment gauges*/
 var opts = {
                lines : 12, // The number of lines to draw
                angle : 0, // The length of each line
                lineWidth : 0.42, // The line thickness
                pointer : {
                    length : 0.75, // The radius of the inner circle
                    strokeWidth : 0.035, // The rotation offset
                    color : '#000000' // Fill color
                },
                limitMax : 'true', // If true, the pointer will not go past the end of the gauge
                colorStart : '#4BCA81', // Colors
                colorStop : '#4BCA81', // just experiment with them
                strokeColor : '#F4F6F9', // to see which ones work best for you
                generateGradient : true,
           };
 /*function to be called after incentive statement DOM is loaded*/
  var resetSlidingMenu=function(){
            
             var canvas_elements = document.getElementsByClassName('gauges-canvas');
                for (var i = 0; i < canvas_elements.length; ++i) {
                    var target = canvas_elements[i];
                    // your canvas element
                    var title=$(target).attr('title');                    
                    title=title.replace(',', '');
                    title=title.replace('\'', '');
                    var gauge = new Gauge(target).setOptions(opts);
                    gauge.maxValue =100;// set max gauge value
                    gauge.animationSpeed = 175;// set animation speed (32 is default value)
                    var gaugeVal=parseInt(title,10);
                    console.log(gaugeVal);
                    if(gaugeVal > 100){
                        //gauge.maxValue =gaugeVal;//reset the max value if it is more than 100%
                        gauge.set(100);
                    }else if(gaugeVal <= 0){ 
                         gauge.set(0.01);
                    }else{
                         gauge.set(gaugeVal);
                    }
                    
                }                               
       
            
 	}
  
  $(function(){
            resetSlidingMenu();
            if($('.drop-desktop').is(':visible') == true){
                 $('.drop-desktop').dropdown('toggle');
            }
            if($('.drop-mobile').is(':visible') == true){
                 $('.drop-mobile').dropdown('toggle');
            }
           
        });

 var loadParticipantData = function(event,elem){
            event.preventDefault();
            $('#pageLoaderBottom').show();
            loadStatement($(elem).attr('href'));
        }
        
        var createGauges = function(){
            $('#pageLoaderBottom').hide();
            resetSlidingMenu();        
            
            if($('.drop-desktop').is(':visible') == true){
                 $('.drop-desktop').dropdown('toggle');
            }
            if($('.drop-mobile').is(':visible') == true){
                 $('.drop-mobile').dropdown('toggle');
            }
        }
		
		
/*
ipad issue fix
script shared by salesforce support
case id=5003000000ahG3WAAU
*/

var a = navigator.userAgent;
if ((a.indexOf('Salesforce') != -1) && (a.indexOf('iPhone') != -1 || a.indexOf('iPad') != -1) && (a.indexOf('Safari') == -1)) {
var s = document.createElement('style');
if ((a.indexOf('OS/8') != -1 || a.indexOf('OS 8') != -1)) {
s.innerHTML = "html,html body{overflow:auto;-webkit-overflow-scrolling:touch;}body{position:absolute;left:0;right:0;top:0;bottom:0;}";
} else if ((a.indexOf('OS/9') != -1 || a.indexOf('OS 9') != -1)) {
s.innerHTML = "html,html body{overflow:scroll;-webkit-overflow-scrolling:touch;zindex:0;}body{position:absolute;left:0;right:0;top:0;bottom:0;}";
}
document.getElementsByTagName('head')[0].appendChild(s);
}