/*
 * jQuery Coverflow like Slider v0.1
 * http://www.fraser-hart.co.uk
 * http://blog.fraser-hart.co.uk
 *
 * Copyright 2013, Fraser Hart
 * Free to use and abuse under the MIT license.
 * http://www.opensource.org/licenses/mit-license.php
 */

(function($) {
	$.fn.coverFlow = function(options) {
		//default settings
		var settings = $.extend({
			initialFocus : 0,
			speed : 200,
			addClasses : "",
			afterChange : function afterChange() {
			}
		}, options);

		var elems = this.find("ul").first().find("li");
		var allowSlide = true;
		this.addClass('coverFlow').wrap('<div class="coverFlowWrapper ' + settings.addClasses + '" style="height: ' + this.css('height') + '; width: ' + this.css('width') + '; float: left; position: relative;margin-left: 24px;" />');
		var numberOfSlides = parseInt(elems.length), eachWidth = parseInt(elems.css("width").replace("px", "")), eachBorder = parseInt(elems.css("border-right-width")) + parseInt(elems.css("border-left-width")), eachMargin = parseInt(elems.css("margin-right")) + parseInt(elems.css("margin-left")), eachPadding = parseInt(elems.css("padding-right")) + parseInt(elems.css("padding-left")), totalItemWidth = eachWidth + eachMargin, totalWidth = totalItemWidth * numberOfSlides, elementToMove = $(this).find('ul'), initialFocusPos = 0;

		/**
		 * Show/hide the left/right nav based on the position
		 * @param  elementToMove //the element to move
		 */
		function showHideNav(elementToMove) {
			var prevBtn = elementToMove.parent().parent().parent().find('.coverFlowNav').not('.next'), nextBtn = elementToMove.parent().parent().parent().find('.coverFlowNav.next');
			if ($(window).width() <= 640) {
				if (parseInt(elementToMove.css("margin-left").replace("px", "")) ==0) {
					prevBtn.hide();
				} else {
					prevBtn.fadeIn('slow');
				};

				var overlap = totalWidth - elementToMove.parent().width();
				if (parseInt(elementToMove.css("margin-left").replace('px', '')) <= -overlap) {
					nextBtn.hide();
				} else {
					nextBtn.fadeIn('slow');
				}
			} else {
				if (parseInt(elementToMove.css("margin-left").replace("px", "")) >= totalItemWidth * 2) {
					prevBtn.hide();
				} else {
					prevBtn.fadeIn('slow');
				};

				var overlap = totalWidth - elementToMove.parent().width() + (totalItemWidth * 2);
				if (parseInt(elementToMove.css("margin-left").replace('px', '')) <= -overlap) {
					nextBtn.hide();
				} else {
					nextBtn.fadeIn('slow');
				}
			}

		}

		/**
		 * Animates the slider
		 * @param  animateTo //the the left-margin to animate to
		 */
		function doAnimate(animateTo) {
			elementToMove.animate({
				"margin-left" : animateTo
			}, settings.speed, 'swing', function() {
				showHideNav(elementToMove);
				allowSlide = true;
				settings.afterChange(elementToMove.find('li.selected').index());
			});
		}

		if ($(window).width() <= 640){
			
			if($(this).attr('id')!='contentSlider-2'){
				//$(this).parent().not('.rank-slider').before('<div class="coverFlowNav"></div><div class="coverFlowNav next" style="margin-left: 732px;"></div>');
				/*add bulleted nav links on incentive attainment summary for mobile devices*/
				$(this).parent().append('<div id="coverFlow-bullet-div" class="coverFlow-bullet-div"></div>');				
				for(var i=1; i<=numberOfSlides; i++){
					if(i==1){
						$('#coverFlow-bullet-div').append('<span class="coverFlow-bullet-span selected-bullet" title="'+i+'"></span>');
					}else{
						$('#coverFlow-bullet-div').append('<span class="coverFlow-bullet-span" title="'+i+'"></span>');
					}					
				}								
				$(this).parent().find('ul').width(totalWidth).find('li:eq(' + settings.initialFocus + ')').addClass('selected');
			}else{
				
				$(this).parent().find('ul').width(totalWidth).find('li:eq(' + settings.initialFocus + ')').addClass('selected');
			}		
		}else{
			$(this).parent().before('<div class="coverFlowNav"></div><div class="coverFlowNav next" style="margin-left: 725px;"></div>');
			$(this).parent().find('ul').width(totalWidth).find('li:eq(' + settings.initialFocus + ')').addClass('selected');
		}
		
		doAnimate(initialFocusPos);

		$(".coverFlowNav").on("click", function() {
			if (allowSlide == true) {
				allowSlide = false;
				var direction = $(this).hasClass('next') ? "-" : "+";
				var elementToMove = $(".coverFlowWrapper").find('.coverFlow ul');

				doAnimate(direction + "=" + totalItemWidth);
			}
		});

		/*
		 * custom xtab script
		 * on click events for the bulleted sliders on mobile devices		 
		 * */
		$(".coverFlow-bullet-span").on("click", function(event){
			if (allowSlide == true) {
				allowSlide = false;
				//event.preventDefault();				
				var currentSelection=$('.selected-bullet');
				var currentSlide=parseInt(currentSelection.attr('title'));
				var direction = (parseInt($(this).attr('title')) > currentSlide) ? "-" : "+";
				var elementToMove = $(".coverFlowWrapper").find('.coverFlow ul');
				currentSelection.removeClass('selected-bullet');
				$(this).addClass('selected-bullet');
				var numberOfSlidesToMove=0;
				if(parseInt($(this).attr('title'))>=currentSlide){
					numberOfSlidesToMove=parseInt($(this).attr('title')) - currentSlide;
				}else{
					numberOfSlidesToMove=currentSlide - parseInt($(this).attr('title'));
				}
				
				doAnimate(direction + "=" + numberOfSlidesToMove*totalItemWidth);
			}
		});
		
		$(this).parent().on("click", "li", function() {
			/*custom handling of ranking slider for mobile devices*/
			if($(this).parent().parent().attr('id')=='contentSlider-2'){
				
				if ($(window).width() <= 640){
					allowSlide = false;
					$(this).parent().find('li.selected').removeClass('selected');
					$(this).addClass('selected');
					newleftpos = -parseInt($(this).parent().children().index(this) * 205);//totalItemWidth);
					doAnimate(newleftpos);
				}else {
					$(this).parent().find('li.selected').removeClass('selected');
					$(this).addClass('selected');
				}
			}else{
				return false;
			}

		});

		showHideNav($(this).find('ul'));
	};
})(jQuery); 