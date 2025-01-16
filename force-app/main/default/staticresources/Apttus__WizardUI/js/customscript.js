var setTabTrackWidth= function(tabUlWidth) {
	tabUlWidth = (typeof tabUlWidth !== 'undefined' ? tabUlWidth : jQuery("ul.inner-tabs-wrapper").width());

	var $wizardCont = jQuery(".wizard-content:visible"),
		$wizardParentCont = $wizardCont.parent();

	var rightPad = $wizardParentCont.outerWidth() - $wizardParentCont.width();

	var width = $wizardParentCont.parent().width() - (rightPad + 30) - $wizardCont.find(".wizard-tab-panel").outerWidth();

	// if scrollbars display adjust div width
	if(tabUlWidth > width){
		//jQuery(".inner-tabs-wrapper-outr").height(originalTabHeight);
		$wizardCont.find(".inner-tabs-wrapper-outr").css({
			height: originalTabHeight + scrollBarWidth,
			marginBottom: 0
		});
	}else{
		//jQuery(".inner-tabs-wrapper-outr").height(originalTabHeight + scrollBarWidth);
		$wizardCont.find(".inner-tabs-wrapper-outr").css({
			height: originalTabHeight,
			marginBottom: scrollBarWidth
		});
	}

	$wizardCont.find(".inner-tabs-wrapper-box").eq(0).width(width);
};

function getScrollbarWidth() 
{
	var div = jQuery('<div style="width:50px;height:50px;overflow:hidden;position:absolute;top:-200px;left:-200px;"><div style="height:100px;"></div></div>'); 
	jQuery('body').append(div); 
	var w1 = jQuery('div', div).innerWidth(); 
	div.css('overflow-y', 'auto'); 
	var w2 = jQuery('div', div).innerWidth(); 
	jQuery(div).remove();
	var scrollBarW = (w1 - w2);
	
	if(scrollBarW <= 0){
		return 17;
	}
	
	return scrollBarW;
}

var scrollBarWidth,
	originalTabHeight;

jQuery(document).ready(function() {
	scrollBarWidth = getScrollbarWidth();
	originalTabHeight = jQuery("ul.inner-tabs-wrapper").height();

	var renameSaved = false;
    jQuery("#renameSave").on("click", function() {
        renameSaved = true;
        jQuery.fancybox.close();
    });

    jQuery(document).on("click", ".edit-field.active .edit-blue-pancil", function() {
        var that = jQuery(this);
        var currentName = that.parent().find('.edit-text').text();
        jQuery('#rename-modal-dialog #newName').val(currentName);
        renameSaved = false;
        jQuery.fancybox({
            'titlePosition': 'inside',
            'transitionIn': 'none',
            'transitionOut': 'none',
            'href': '#rename-modal-dialog',
            afterShow: function() { return; },
            afterClose: function() { 
                if(true == renameSaved) {
                    var newVal = jQuery('#newName').val();
                    that.parent().find('.edit-text').text(newVal);
                    var tabId = jQuery(that).closest(".edit-field").attr("data-tabid");
                    var tabContainer = jQuery(".content-panel-outr:visible").find(".tab-container[data-tabid=" + tabId + "]");
                    tabContainer.find(".properties-information-panel .input-info").val(newVal);
                }
                return;
            }
        });
    });
});
function validateText(value) {
	if(value.length < 1) {
		alert("Value cannot be blank");
		return false; 
	} else {
	  return true; 
	}
 }
 
 function replaceUnderscores(value) {
	  value = value.replace("_", " ");
	  return value;
 }
function onChangeStepContext(oldContext, newContext, componentCount) {
	if(0 < componentCount) {
		if(confirm('Are you sure you want to update the context? This will remove all components from this step')) {
			updateStepContext();
		} else {
			resetStepContext(oldContext);
		}
	} else {
		updateStepContext();
	}
}

function onChangeWizardContext(oldContext, newContext, componentCount) {
	if(0 < componentCount) {
		if(confirm('Are you sure you want to update the context? This will remove all steps from this Wizard')) {
			updateWizardContext();
		} else {
			resetWizardContext(oldContext);
		}
	} else {
		updateWizardContext();
	}
}

function onActivateWizard() {
	if(confirm('Are you sure you want to activate this Wizard? You wont be able to edit this wizard any more')) {
		activateWizard();
	}
}

var wizardsData = [],
	currentWizardID = null,
	wizardTabsCount,
	$activeTab;

function refreshWizardStepNavigations(wizardJsonStr) {
	//var wizardJson = retrieveWizard(JSON.parse(wizardJsonStr));
	var wizardJson = JSON.parse(wizardJsonStr);
	currentWizardID = wizardJson.placeholderId;

	recalculateTabs();

	wizardBldr.setContext(currentWizardID);
	wizardBldr.build(wizardJson);
}

function recalculateTabs() {
	// get tabs count
	$tabList = jQuery(".wizard-content:visible ul.inner-tabs-wrapper");
	wizardTabsCount = $tabList.find(".edit-field").length;
	var tabsLength = 157 + ((wizardTabsCount - 1) * 160);
	tabsLength = tabsLength + 5;
	$tabList.width(tabsLength);
	setTabTrackWidth(tabsLength);
}

function retrieveWizard(wizardData) {
	for(var i=0;i<wizardsData.length;i++){
		if(wizardsData[i].placeholderId === wizardData.placeholderId) {
			wizardsData[i] = wizardData;
			return wizardsData[i];
		}
	}

	wizardsData.push(wizardData);
	return wizardData;
}

function getCachedWizardById(wizardPlaceHolderId){
	for(var i=0;i<wizardsData.length;i++){
		if(wizardsData[i].placeholderId === wizardPlaceHolderId)
			return wizardsData[i];
	};
}

function setWizardInContext(currentWizard) {
	console.log("setWizardInContext");

	wizardBldr.setContext(currentWizard);
}

function popupRuleModal(canPopup) {
	if(!canPopup) return;

	jQuery.fancybox({
		'titlePosition': 'inside',
		'transitionIn': 'none',
		'transitionOut': 'none',
		'href': '#rule-modal-dialog',
		afterShow: function() {
			jQuery("#removeConnection").on("click", function() {
				jQuery.fancybox.close();
			});
		},
		afterClose: function() {
			closePopup();
			// if(isNew && !isSavingConnection) {
			//     jsPlumb.detach(wizardBldr.connectionInContext);
			//     isNew = false;
			// }

			// isSavingConnection = false;
			// jQuery("#removeConnection").off("click");
			// ruleCount = 1;
			// while(jQuery('#rulesTbl > tbody > tr').length > 3) {
			//     jQuery('#rulesTbl > tbody > tr:last').prev().remove();
			// }
			
		}
	});
 }

 function closeRulesetPopup(isSaved) {
	if(!isSaved) {
		jsPlumb.detach(wizardBldr.connectionInContext);
	}
	jQuery("#removeConnection").off("click");
	onAfterRulePopupClose();
 }

function greenFade(x) {
    x.animate({
        backgroundColor: "#c9f9c9"
    }, 1).animate({
        backgroundColor: "",
        queue: false
    }, 1000);
}

// this is the paint style for the connecting lines..
    var connectorPaintStyle = {
            lineWidth: 2,
            strokeStyle: "#7098ac",
            joinstyle: "round",
            outlineColor: "white",
            outlineWidth: 2
        },
    // .. and this is the hover style.
        connectorHoverStyle = {
            lineWidth: 2,
            strokeStyle: "#456676",
            outlineWidth: 2,
            outlineColor: "white"
        },
        endpointHoverStyle = {
            fillStyle: "#456676",
            strokeStyle: "#456676"
        },
    // the definition of source endpoints (the small blue ones)
        sourceEndpoint = {
            endpoint: "Dot",
            paintStyle: {
                strokeStyle: "#7098ac",
                fillStyle: "white",
                radius: 7,
                lineWidth: 2
            },
            isSource: true,
            // defines how connectors wrap and flow
            connector: [ "Flowchart", { stub: [20, 30], gap: 10, cornerRadius: 5, alwaysRespectStubs: true } ],
            connectorStyle: connectorPaintStyle,
            hoverPaintStyle: endpointHoverStyle,
            connectorHoverStyle: connectorHoverStyle,
            dragOptions: {},
            overlays: [
                [ "Label", {
                    location: [0.5, 1.5],
                    label: "",
                    cssClass: "endpointSourceLabel"
                } ]
            ]
        },
    // the definition of target endpoints (will appear when the user drags a connection)
        targetEndpoint = {
            endpoint: "Dot",
            paintStyle: { fillStyle: "#7098ac", radius: 8 },
            hoverPaintStyle: endpointHoverStyle,
            maxConnections: -1,
            dropOptions: { hoverClass: "hover", activeClass: "active" },
            isTarget: true,
            overlays: [
                [ "Label", { location: [0.5, -0.5], label: "", cssClass: "endpointTargetLabel" } ]
            ]
        };

var i = 1;
var jsPlumbInstance;
var isNew = false;
var isSavingConnection = false;
var ruleCount = 1;
var ruleRow;
var wizardBldr;

var elePosition = {
        	offset: {
        		top:415,
        		left:15
        	}
        };

function addSteps(){
	var $sectemp = jQuery(".rule-plan-box-template .tiny-drag-box.stepsSingle").clone();
    $sectemp.find(".tiny-drag-box-body h2").html("Test Step");
    $sectemp.addClass("del-div");

    wizardBldr.renderNewStep('flowchartWindow' + i, $sectemp, elePosition);

	elePosition.offset.left += 180;

	i++;
}

function wizardTabEnter(){
	//window.setTimeout(addSteps, 2500);
	//window.setTimeout(addSteps, 3500);
}

jQuery(document).ready(function($) {
	 ruleRow = $('#rulesTbl > tbody > tr:last').prev().clone();

	/*  initialize jsPlumb  */
	jsPlumb.ready(function() {
		jsPlumb.importDefaults({
		  ConnectionOverlays: [
				[ "Arrow", { location: 1 } ],
				[ "Label", {
					location: 0.1,
					id: "label",
					cssClass: "aLabel"
				}]
			],
		  DragOptions : { cursor: 'pointer', zIndex: 2000 },
		  Endpoints : [ [ "Dot", { radius:7 } ], [ "Dot", { radius:11 } ] ],
		  EndpointStyles : [{ fillStyle:"#225588" }, { fillStyle:"#558822" }]
		});
		// instantiate wizard builder class
    	wizardBldr = WizardBuilder(jsPlumb, 
                                   currentWizardID,
                                   sourceEndpoint, 
                                   targetEndpoint);

	});



var waitForFinalEvent = (function () {
  var timers = {};
  return function (callback, ms, uniqueId) {
    if (!uniqueId) {
      uniqueId = "Don't call this twice without a uniqueId";
    }
    if (timers[uniqueId]) {
      clearTimeout (timers[uniqueId]);
    }
    timers[uniqueId] = setTimeout(callback, ms);
  };
})();	
	
$(".input-step-block textarea").niceScroll();							
 var setScroll = function(){
	if($("#rule-overlay:visible").length)
	$("#rule-overlay").getNiceScroll().resize();
	if($("textarea:visible").length)
	$("textarea").getNiceScroll().resize();

}

jQuery.fn.center = function () {
    this.css("position","absolute");
    this.css("top", Math.max(0, (($(window).height() - $(this).outerHeight()) / 2) + 
                                                $(window).scrollTop()) + "px");
    this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) + 
                                                $(window).scrollLeft()) + "px");
    return this;
}


$.fn.wrapInTag = function(opts) {
  
  var tag = opts.tag || 'strong',
      words = opts.words || [],
      regex = RegExp(words.join('|'), 'gi'),
      replacement = '<'+ tag +'>$&</'+ tag +'>';
  
  return this.html(function() {
    return $(this).text().replace(regex, replacement);
  });
};

	$('.tooltip').tipsy({ gravity: 's'});
	$('.tooltip-n').tipsy({ gravity: 'n'});
	$('.tooltip-w').tipsy({ gravity: 'w'});
	$('.tooltip-e').tipsy({ gravity: 'e'});
	$('.tooltip-sw').tipsy({ gravity: 'sw'});
	$('.tooltip-se').tipsy({ gravity: 'se'});
	$('.tooltip-nw').tipsy({ gravity: 'nw'});
	$('.tooltip-ne').tipsy({ gravity: 'ne'});

	$('body').label_radio_check();
	
	
	$( "#tabs" ).tabs();
	$( "#wizard-tabs" ).tabs();
	$( "#preview-step-information" ).tabs();

	
	$(document).on("click",".preview-group",function(){
		$clone = $(this).closest(".drag-model-body").find(".group-panel-placeholder").clone();
		
		if($(this).closest(".drag-model-body").hasClass("table-view-layout")){
				$("#group-table-preview-outr").find(".group-table-preview .group-table-wrap").html($clone);
					$clone.find(".rpt-table-row-outr").draggable({
					  axis: "x",
					  cursor: "move",
						start: function(event, ui) {
							start = ui.position.left;
						},
						stop: function(event, ui) {
							stop = ui.position.left;
							if((start < stop))
							$lr = "left-move";
							else
							$lr = "right-move";
							
							$clone.find(".rpt-table-row-outr").closest('.rpt-table-format').removeClass("left-move right-move");
							$clone.find(".rpt-table-row-outr").closest('.rpt-table-format').addClass($lr);
						}
					});

				$.fancybox({
						'titlePosition': 'inside',
						'transitionIn': 'none',
						'transitionOut': 'none',
						'href': '#group-table-preview-outr',
						afterShow: function () {
							$("#group-table-preview-outr").niceScroll({
								cursorcolor: "#B2B2B2",
								cursorwidth: "7px",
								zindex: "999999",
								autohidemode: true,
						   });
						}
					
					});
			
		}else{	
				$("#group-preview-overlay").find(".wizard-process-panel-left").html($clone);
				$.fancybox({
							'titlePosition': 'inside',
							'transitionIn': 'none',
							'transitionOut': 'none',
							'href': '#group-preview-overlay',
							afterShow: function () {
								//alert('hii');
								$("#group-preview-overlay").niceScroll({
									cursorcolor: "#B2B2B2",
									cursorwidth: "7px",
									zindex: "999999",
									autohidemode: true,
							   });
							}
						
						});

		
		
		}
	});
	
	
	
	/** Group Enhancments Ends ***/		
	
	$("#zoomSlider").slider({
		 orientation: "vertical",
				  range: "min",
				  min:0.07,
				  max: 1.2,
				  step: 0.001,
				  value: 0.9,
			//this gets a live reading of the value and prints it on the page
			slide: function(event, ui) {
			  $("#ratingResult").text(ui.value);
				$('.rule-plan-box-outr').css({
				  '-webkit-transform' : 'scale(' + ui.value + ',' + ui.value + ')',
				  '-moz-transform'    : 'scale(' + ui.value + ',' + ui.value + ')',
				  '-ms-transform'     : 'scale(' + ui.value + ',' + ui.value + ')',
				  '-o-transform'      : 'scale(' + ui.value + ',' + ui.value + ')',
				  'transform'         : 'scale(' + ui.value + ',' + ui.value + ')'
				});
				
			}
	  });
	
	
	/*-- Text Area auto-resize --*/
	
	// $('textarea.autoresize').autosize();
	 $('.autoresize').on('keyup', function() {
        if ($.trim($(this).val()).length) {
            $(this).autosize();
        }
    });
    $('.autoresize').on('blur', function() {
        if (!$.trim($(this).val()).length) {
            $(this).trigger('autosize.destroy');
        }
    });
	
	$(".submit-model-view").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#submit-model'
    });
	$(".akgmnt-model-view").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#akgmnt-model'
    });
	
	$(".add-rule-wizard").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#rule-model2'
    });
	$(".preview-step-two").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#preview-step-two',
		afterShow: function () {
			$("#preview-step-two").niceScroll({
				cursorcolor: "#B2B2B2",
				cursorwidth: "7px",
				zindex: "999999",
				autohidemode: true,
		   });
		}
		
    });
	$(".preview-step-three").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#preview-step-three',
		afterShow: function () {
			$("#preview-step-three").niceScroll({
				cursorcolor: "#B2B2B2",
				cursorwidth: "7px",
				zindex: "999999",
				autohidemode: true,
		   });
		}
    });
	$(".preview-step-four").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#preview-step-four',
		afterShow: function () {
			$("#preview-step-four").niceScroll({
				cursorcolor: "#B2B2B2",
				cursorwidth: "7px",
				zindex: "999999",
				autohidemode: true,
		   });
		}
    });
	$(".preview-step-five").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#preview-step-five',
		beforeShow: function () {
			$("#preview-step-five").niceScroll({
				cursorcolor: "#B2B2B2",
				cursorwidth: "7px",
				zindex: "999999",
				autohidemode: true,
		   });
		}
    });
	
	
	/** For Step Tab Preview Overlay  **/
	$(".preview-step").fancybox({
        'titlePosition': 'inside',
        'transitionIn': 'none',
        'transitionOut': 'none',
        'href': '#preview-step-information',
		afterShow: function () {
			$("#preview-step-information").niceScroll({
				cursorcolor: "#B2B2B2",
				cursorwidth: "7px",
				zindex: "999999",
				autohidemode: true,
		   });
		}
		
    });
	
	
	$('.datepicker').datepicker();
	
	/****  RuleSet Tab ***/
	$(".rule-set-wrapper").niceScroll({
        cursorcolor: "#B2B2B2",
        cursorwidth: "7px",
        zindex: "1000",
        autohidemode: true,
    });
	$("#rule-overlay").niceScroll({
        cursorcolor: "#B2B2B2",
        cursorwidth: "7px",
        zindex: "999999",
        autohidemode: true,
    });
	$(".input-step-block .sbOptions").niceScroll({
        cursorcolor: "#B2B2B2",
        cursorwidth: "7px",
        zindex: "999999",
        autohidemode: true,
    });
	
	$('.rule-set-wrapper .rule-plan-box-outr').width($(".rule-set-wrapper .rule-plan-box-sub-outr").length*$(".rule-set-wrapper .rule-plan-box-sub-outr:not(:first)").outerWidth(true));
//wizard-overlay-box
//info-wizard

$(document).on("click", ".info-wizard", function() {
		var top = $(this).offset().top;
		var left = $(this).offset().left;
		$(".wizard-overlay-box").css({"top":top -234,"left":left +15}).show();
});
	
	  /*--Properties Flyout Box --*/
    $(document).on("click", ".dropdown-label", function() {
        $isActive = $(this).hasClass("active");
        $this = $(this);
        if ($isActive) {
            setTimeout(function() {
                $this.removeClass("active");
                $this.find(".toggle-arrow").removeClass(
                    "active");
            }, 400);
        } else {
            $this.addClass("active");
            $this.find(".dropdown-label .down-arrow").addClass("active");
        }
        $(".properties-information-panel").slideToggle();
    });
    $(document).on("click", ".cancel-properties", function() {
        $this = $(this);
        $this.closest(".properties-information-panel").slideUp(function() {
            $this.closest(".edit-input-heading").find(".dropdown-label").removeClass("active");
            $this.closest(".edit-input-heading").find(".dropdown-label").removeClass("active");
        })
    });
	
 $(".wizard-search-form .collapse").on("click", function() {
		$(".wizard-search-form .collapse").not($(this)).each(function(){
			if(!$(this).hasClass("expand")){		
				$(this).addClass("expand");
				$(this).closest(".wizard-search-form").find(".search-inner-wrapper").slideUp();
			}
		});
		
		$(this).toggleClass("expand");
		$(".tipsy").remove();
		if($(this).hasClass("expand")){
			$(this).attr("title","Collapse");
			}else {
			//$(this).attr("title","Expand");	
			}
					
		
        $(this).closest(".wizard-search-form").find(".search-inner-wrapper").slideToggle(function(){
			
            $(".wizard-list-outr .wizard-list-box").getNiceScroll().resize();
		});
    });
	
	$(document).on("click",".rich-tab-active",function(){
	setTimeout(function(){
	$(".wizard-list-outr .wizard-list-box").getNiceScroll().resize();
	},200);
		
	});
	
	 /*--------------Steps Page functions-----------------*/
    function compLibStepsSearch(x, y) {
        y.find(".wizard-list-box").find("li").each(function(i,v) {
			var boxTitle = $(this).find(".information-text").attr('search-text').toLowerCase();
            if (boxTitle.length) {
                if (boxTitle.indexOf(x.toLowerCase()) >= 0) {
					$(this).closest("li").stop(true,
                        true).show();
                } else {
                    $(this).closest("li").stop(true,
                        true).hide();
                }
            }
        });
    }
	
	function resetSetHeight(){
		$(".wizard-sidebar").css("min-height",$(".content-panel-outr:visible").height());
	}
    $(".rich-tab-header").on("click",function() {
		resetSetHeight();
   });
   
   $(".wizard-search-form-input .search-field").on("keyup",function() {
            var conDiv = $(this).closest(".search-inner-wrapper");
            var str = $.trim($(this).val().toLowerCase());
            compLibStepsSearch(str, conDiv);
   });
 
 
 
	 /*--------------Steps Page functions-----------------*/
    function compLibStepsSearchCW(x, y) {
        y.find(".wizard-flow-box").each(function(i,v) {
			var boxTitle = $(this).find(".wizard-flow-info h4")
                .text().toLowerCase();
            if (boxTitle.length) {
                if (boxTitle.indexOf(x.toLowerCase()) >= 0) {
                   /* $(this).closest("li").find(".information-text").wrapInTag({
					  tag: 'strong',
					  words: [x]
					});*/
					$(this).closest(".wizard-flow-box").stop(true,true).show();
                } else {
                    $(this).closest(".wizard-flow-box").stop(true,
                        true).hide();
                }
            }
        });
    }

   
   $(".dashboard-search-outr .search-input").on("keyup",function() {
           
		   var conDiv = $(".ui-tabs-panel:visible");
            var str = $.trim($(this).val().toLowerCase());
            compLibStepsSearchCW(str, conDiv);
   }); 
 
 
 
    var owlTab = ".content-panel-outr:visible .inner-tabs-wrapper";
    var sExpTabs = false;
	var occ = $(".content-panel-outr:visible");
    /*Check if Ellipsis Active*/
    function isEllipsisActive(e) {
        return (e.offsetWidth < e.scrollWidth);
    }

    function setToolTipTabs() {
       $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field .edit-text").each(
            function(e) {
                $tabTxt = $.trim($(this).text());
                if ($tabTxt.length > 25) {
                    $(this).addClass("tooltip");
                    $(this).attr("title", $tabTxt);
                } else {
                    $(this).removeClass("tooltip");
                    $(this).removeAttr("title");
                    $(this).removeAttr("original-title");
                }
            });
       $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field.active").each(
            function(e) {
                $(this).find(".edit-blue-pancil").addClass(
                    "tooltip");
                $(this).find(".edit-blue-pancil").attr("title",
                    "Edit");
            });
        $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field.disabled-state").each(
            function(e) {
                $(this).find(".edit-blue-pancil").removeClass(
                    "tooltip");

                $(this).find(".edit-blue-pancil").removeAttr(
                    "title");
                $(this).find(".edit-blue-pancil").removeAttr(
                    "original-title");
            });
        $(".tooltip").tipsy({
            gravity: 's'
        });
    };
    /* Add Tag */
    function refreshOwl() {
        setToolTipTabs();
    }
        /* Add Tag */

    function addItemOwlOTG(x, y) {
        $(x).prepend(y);
    }
	
    $(document).on("change", ".input-components select", function() {
        $thisVal = $.trim($(this).val());
        if ($thisVal.length) {
            $(this).closest(".input-select-field").next(
                ".input-select-field").show();
        } else {
            $(this).closest(".input-select-field").nextAll(
                ".input-select-field").hide();
            $(".input-select-field .moreCategoriesSelect").each(
                function() {
                   // $(this).selectbox("detach").val("").selectbox();
                });
        }
        if ($(this).closest(".tab-container").find(
            ".input-select-field .input-response").is(
            ":visible")) $(this).closest(".tab-container").find(
            ".save-tab").removeAttr("disabled");
        else $(this).closest(".tab-container").find(".save-tab")
            .attr("disabled", "disabled");
    });
    $(document).on("click", ".edit-tab-shadow", function() {
        $(this).toggleClass("active");
        $(this).closest(".edit-tab-wrapper").find(
            ".tab-drop-down").slideToggle();
    }); 
	
	
	$(document).on("click", ".show-progress-bar", function() {
       $(".progressing-state").center();
	   $(".progressing-state").fadeIn();
	   setTimeout(function(){ 
			$(".progressing-state").fadeOut();						
		}, 2000);
    });
	
	
    $(document).on("click", ".new-wizard,.save-step-tab", function() {
        $(".content-panel-outr:visible").find(".create-new-input,.create-new-step").removeAttr(
            "disabled");
        $tid = $(this).closest(".tab-container").attr(
            "data-tabid");
        $tabname = $(".content-panel-outr:visible").find(".edit-field[data-tabid].active").find(
            ".edit-text").text();
        $(".content-panel-outr:visible").find(".info-bg.dynamic-input,.basic-info-bg.dynamic-input").fadeIn();
        $(".content-panel-outr:visible").find(".info-bg.dynamic-input,.basic-info-bg.dynamic-input").find(
            ".information-text").html($tabname);
        greenFade($(".content-panel-outr:visible").find(".info-bg.dynamic-input,.basic-info-bg.dynamic-input"));
        
		$(".content-panel-outr:visible").find(".properties-information-panel .input-info").val($tabname);
		$(".content-panel-outr:visible").find(".properties-information-panel .label-info").val($(".content-panel-outr:visible").find(".tab-label-textarea .label-info").val());
		$('html,body').animate({
            scrollTop: 0
        }, 'slow');
    });
	
	
	   $(document).on("click", ".save-wizard-tab", function() {
			$(".content-panel-outr:visible").find(".create-new").removeAttr(
				"disabled");
			$tid = $(this).closest(".tab-container").attr(
				"data-tabid");
			$tabname = $(".content-panel-outr:visible").find(".edit-field[data-tabid].active").find(
				".edit-text").text();
			$(".content-panel-outr:visible").find(".dynamic-input").fadeIn();
			$(".content-panel-outr:visible").find(".dynamic-input").find(".information-text").html($tabname);
			greenFade($(".content-panel-outr:visible").find(".dynamic-input"));
			
			$(".content-panel-outr:visible").find(".properties-information-panel .input-info").val($tabname);
			$(".content-panel-outr:visible").find(".properties-information-panel .label-info").val($(".content-panel-outr:visible").find(".tab-label-textarea .label-info").val());
			$('html,body').animate({
				scrollTop: 0
			}, 'slow');
		});
	

	
	$(".go-to-top").click(function(){
		$('html,body').animate({
            scrollTop: 0
        }, 'slow');			   
	});
	
	$(window).scroll(function() {
		$st = $(window).scrollTop();
		if($(".rich-tabpanel-content-position:visible").length){
		$ss = $(".rich-tabpanel-content-position:visible").offset().top;
		$sc = $st-$ss;
		$sh = parseInt($(".content-panel-outr:visible .wizard-content").attr("data-height"))-$ss;
//		console.log($st+"=>="+$ss);
		if(!$(".content-panel-outr:visible .stickem").hasClass("pinned")){
			if($st>$ss){
				if($st<$sh)
				$(".stickem").css("margin-top",$sc);
			}else{
			$(".stickem").removeAttr("style");
			}
			}
		}
		if($st> 250)
		$(".go-to-top").fadeIn();
		else
		$(".go-to-top").fadeOut();
		
	});
	
    $(document).on("click",".create-new-step", function() {
        
		$(this).closest(".content-panel-outr").find(".inner-tabs-wrapper").find("li.edit-field.active").each(
            function(i, v) {
                $(this).find(".edit-blue-cancel:visible").trigger(
                    "click");
                $(this).addClass("disabled-state").removeClass(
                    "active tooltip");
                $(this).find(".edit-blue-pancil").removeAttr(
                    "original-title");
                $(this).find(".edit-blue-pancil").removeClass(
                    "tooltip");
            });
        $(".tipsy").remove();
        /*Tab Start*/
		$tabType = $(this).closest(".content-panel-outr").find(".input-tab-template").attr("data-pagetabs");
		
        $tabClone = $(this).closest(".content-panel-outr").find(".input-tab-template").find(
            "li.edit-field").clone();
        $tabId = "00" + ($(this).closest(".content-panel-outr").find(".inner-tabs-wrapper").find(
            "li.edit-field").length + 1);
        $tabClone.find(".edit-text").html($tabType+" " + ($(".content-panel-outr:visible").find(
                ".inner-tabs-wrapper").find("li.edit-field")
            .length + 1));
        $tabClone.find(".edit-input-text").closest(
            "li.edit-field").attr("data-tabid", $tabId);
        $(this).closest(".content-panel-outr").find(".tab-drop-down ul").prepend(
            '<li> <a href="javascript:void(0);" data-tabid="' +
            $tabId + '" >'+$tabType+" "+ ($(this).closest(".content-panel-outr").find(".inner-tabs-wrapper").find(
                "li.edit-field").length + 1) + '</a></li>');
        addItemOwlOTG(owlTab, $tabClone);
        /*Tab Stop*/
        /*TabContainer Start*/

		$tabContClone = $(this).closest(".content-panel-outr").find(".tab-container-template").find(".tab-container").clone();
		
        $tabContClone.attr("data-tabid", $tabId);
        $(this).closest(".content-panel-outr").find(".tab-container-wrapper").find(".tab-container").hide();
		$(this).closest(".content-panel-outr").find(".tab-container-wrapper").append($tabContClone);
		
        refreshOwl();
		requiredNameDragDrop();
    });
    $(".expand-plus").on("click", function() {
        $(this).toggleClass("active");
        $(this).closest("h3").next(".component-library-expand").slideToggle();
    });
    /* Tabber */
    $(document).on("click", ".edit-field.disabled-state", function() {
		
		$(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field.active").each(
            function(i, v) {
                $(this).find(".edit-blue-cancel:visible").trigger(
                    "click");
                $(this).addClass("disabled-state").removeClass(
                    "active tooltip");
                $(this).find(".edit-blue-pancil").removeAttr(
                    "original-title");
                $(this).find(".edit-blue-pancil").removeClass(
                    "tooltip");
				
            });
        $tabId = $(this).attr("data-tabid");
        $(this).removeClass("disabled-state").addClass("active");
        $(this).find(".edit-blue-pancil").addClass("tooltip");
        $(this).find(".edit-blue-pancil").attr("title", "Edit");
        $(".content-panel-outr:visible").find(".tab-container-wrapper").find(".tab-container").hide();
        $(".content-panel-outr:visible").find(".tab-container-wrapper").find(
            ".tab-container[data-tabid=" + $tabId + "]").show();
        //setTimeout(function(){
        $(".content-panel-outr:visible").find(".edit-field.disabled-state").find(
            ".edit-blue-pancil").removeAttr("title");
        //console.log("runnnn");
        //}, 100);
		$(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field.disabled-state").removeAttr("style");
    });
	
	
	 /* Tabber */
    $(document).on("click", ".edit-field.disabled-state", function() {
        $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field.active").each(
            function(i, v) {
                $(this).find(".edit-blue-cancel:visible").trigger(
                    "click");
                $(this).addClass("disabled-state").removeClass(
                    "active tooltip");
                $(this).find(".edit-blue-pancil").removeAttr(
                    "original-title");
                $(this).find(".edit-blue-pancil").removeClass(
                    "tooltip");
            });
        $tabId = $(this).attr("data-tabid");
        $(this).removeClass("disabled-state").addClass("active");
        $(this).find(".edit-blue-pancil").addClass("tooltip");
        $(this).find(".edit-blue-pancil").attr("title", "Edit");
        $(".tab-container-wrapper").find(".tab-container").hide();
        $(".tab-container-wrapper").find(
            ".tab-container[data-tabid=" + $tabId + "]").show();
        //setTimeout(function(){
        $(".edit-field.disabled-state").find(
            ".edit-blue-pancil").removeAttr("title");
        //console.log("runnnn");
        //}, 100);
    });
	
    /* Tab Select */
    $(document).on("click", ".tab-drop-down li", function() {
		$(".content-panel-outr:visible").find(".tab-drop-down li").removeClass("active");
        $(this).addClass("active");
        $tabid = $(this).find("a").attr("data-tabid");
		$(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field[data-tabid]").removeAttr("style");
        $dli = $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find(
            "li.edit-field[data-tabid=" + $tabid + "]").detach();
        $(".content-panel-outr:visible").find(".inner-tabs-wrapper").prepend($dli);
        //$(".edit-tab-outer").find("li.edit-field[data-tabid]").not(".active").find(".edit-blue-pancil").removeAttr("original-title");
        $(".content-panel-outr:visible").find(".inner-tabs-wrapper").find("li.edit-field[data-tabid=" +
            $tabid + "]").trigger("click");
        $(this).closest(".edit-tab-wrapper").find(
            ".edit-tab-shadow").removeClass("active");
        $(this).closest(".tab-drop-down").slideUp();
        console.log($(".inner-tabs-wrapper").find("li.edit-field[data-tabid=" + $tabid + "]").length);
		greenFade($(".inner-tabs-wrapper").find("li.edit-field[data-tabid=" + $tabid + "]"));
        refreshOwl();
    });
    /*--------------Steps Page functions START-----------------*/
/*    function compLibStepsSearch(x, y) {
        y.find(".wizard-list-box").find(".drag-bg").each(function(i,
            v) {
            var boxTitle = $(this).find(".information-text")
                .text().toLowerCase();
            if (boxTitle.length) {
                if (boxTitle.indexOf(x.toLowerCase()) >= 0) {
                    $(this).closest(".drag-bg").stop(true,
                        true).show();
                } else {
                    $(this).closest(".drag-bg").stop(true,
                        true).hide();
                }
            }
        });
    }*/
    $(document).on("keyup", ".component-library-expand .search-field",
        function() {
            $conDiv = $(".component-library-expand");
            $str = $.trim($(this).val().toLowerCase());
           // compLibStepsSearch($str, $conDiv);
        });

   
  	$(".step-outr-panel .drag-drop-panel-outr").sortable({
        handle: ".switch-icon",
        axis: "y"
    });
	
   // $(".required-box-container").disableSelection();
    $(document).on("click", ".required-box .delete-icon", function() {
        $(this).closest(".required-box").slideUp(function() {
			$(this).remove();
			if(!$(".drag-drop-box-outer .required-box").length)
			$(".view-by").slideUp();
			
			$(".tipsy").remove();
        });
    });
    /*--------------Steps Page functions STOP-----------------*/
	 
	 
	 //$(".wizard-list-outr, .rule-list-outr").resizable({
	 $(" .rule-list-outr").resizable({												   
        handles: "s",
        resize: function(event, ui) {
            $ht = $(this).height();
            $(this).find(".wizard-list-box, .rule-list-box").height($ht);
        },
        stop: function(event, ui) {
            $(this).find(".wizard-list-box, .rule-list-box").getNiceScroll().resize();
            $(".wizard-list-outr .wizard-list-box, .rule-list-outr .rule-list-box").getNiceScroll()
                .resize();
        },
		  minHeight: 30,
		   maxHeight: 200
    });
    $(".wizard-list-outr .wizard-list-box, .rule-list-outr .rule-list-box,.rule-plan-box-outr.show-rules").niceScroll({
        cursorcolor: "#B2B2B2",
        cursorwidth: "7px",
        zindex: "1000",
        autohidemode: false,
    });
	
	$("textarea").on("keypress",function(){
					$(this).getNiceScroll().resize();					 
										 })
	 
	 
	  /*-- Drag n Drop START --*/
    function enableSorting(x) {
        $temp = "";
        $temp = $(".required-box-template").find(".row-group-outer")
            .clone();
        //$addtemp = $(".required-box-template").find(".add-area-here").clone(); 
        $(".drag-inner-box").find(
            ".new-group-drag.row-grid-section").append($temp);
        $(".drag-inner-box").find(".row-group-outer").removeClass(
            "lastAddRow");
        $(".drag-inner-box").find(".add-area-here").remove();
        //$(".drag-inner-box").find(".row-group-outer:last").append($addtemp);
        $(".drag-inner-box").find(".row-group-outer:last").addClass(
            "lastAddRow");
        $(".new-group-drag .row-group-outer.inner-cell").each(
            function() {
                if (!$(this).hasClass("lastAddRow")) {
                    if (!$(this).find(".inner-cell").length) $(
                        this).remove();
                }
            });
    }
    $isdrag = false;

    function requiredNameSortable() {
        if ($(".new-group-right").length) {
            $(
                ".wizard-list-box .drag-bg,.row-group-outer.inner-cell"
            ).sortable({
                helper: 'clone',
                revert: true,
                containment: 'document',
                //tolerance: "intersect",
                placeholder: 'drop-role-box',
                connectWith: ".row-group-outer.inner-cell",
                receive: function(event, ui) {
                    $dragclone = $(ui.item).clone();
                    $inputtype = $dragclone.attr(
                        "data-inputtype");
                    $inputname = $dragclone.attr(
                        "data-inputname");
                    if ($inputtype == 'streetNo') {
                        $reqboxclone = $(
                            ".required-box-template"
                        ).find(
                            ".required-name-text.select-box.inner-cell"
                        ).clone();
                      //  $reqboxclone.find(
                      //      ".moreCategoriesSelectTemp"
                      //  ).selectbox();
                    } else {
                        $reqboxclone = $(
                            ".required-box-template"
                        ).find(
                            ".required-name-text.text-box.inner-cell"
                        ).clone();
                    }
                    $reqboxclone.attr("data-inputtype",
                        $inputtype);
                    $reqboxclone.attr("data-inputname",
                        $inputname);
                    $reqboxclone.find(
                        ".required-name-text .first-name,.input-name"
                    ).html($inputname);
                    //console.log($isdrag);
                    if ($isdrag) {
                        $(this).append($reqboxclone);
                        $(this).find(".inner-input").remove();
                    }
                    if ($(event.target).find(
                        ".inner-cell").length < 3) $(
                        event.target).addClass(
                        "inner-cell");
                    else $(event.target).removeClass(
                        "inner-cell");
                    if ($(".drag-inner-box").find(
                        ".row-group-outer:last").find(
                        ".row-grid-section.inner-cell"
                    ).length < 3) {
                        enableSorting($(event.target));
                        requiredNameSortable();
                    }
					
					
                },
                stop: function(event, ui) {
                    //console.log($isdrag);
                    if ($isdrag) $(this).sortable(
                        'cancel');
                    /*
			$(".drag-inner-box").removeClass("dragging");
			else{*/
                    $(".drag-inner-box .lastAddRow").find(
                        ".add-area-here").remove();
                },
                start: function(event, ui) {
                    if ($(event.target).closest(
                        ".wizard-list-outr").length) {
                        $isdrag = true;
                    } else {
                        $isdrag = false;
                        $(event.target).addClass(
                            "inner-cell")
                    }
                    // console.log($isdrag);
                    $(".drag-inner-box").addClass(
                        "dragging");
                    // $(event.target).addClass("inner-cell xxxxxxxxxxxxxxxxxx")
                },
                over: function(event, ui) {
                    if ($(event.target).hasClass(
                        "lastAddRow")) {
                        $addtemp = $(
                            ".required-box-template"
                        ).find(".add-area-here").clone();
                        if (!$(
                            ".drag-inner-box .lastAddRow"
                        ).find(".add-area-here").length)
                            $(
                                ".drag-inner-box .lastAddRow"
                            ).find(".drop-role-box").append(
                                $addtemp);
                    } else {
                        $(".drag-inner-box").find(
                            ".add-area-here").remove();
                    }
                }
            }).disableSelection();
            $('body').label_radio_check();
        }
    }

    function requiredNameDragDrop() {
      //  if ($(".single-group-right").length) {
            $(".wizard-list-outr").find(".drag-bg").draggable({
                //  use a helper-clone that is append to 'body' so is not 'contained' by a pane
                helper: function() {
                    return $(this).clone().appendTo(
                        'body').css({
                        'zIndex': 5
                    });
                },
                revert: 'invalid',
                cursor: 'move',
                containment: "document"
            });
            $(".drag-drop-area-outr").droppable({
                accept: ".drag-bg",
                activeClass: "ui-state-hover",
                hoverClass: "ui-state-active",
                drop: function(event, ui) {
                    if (!ui.draggable.hasClass("dropped")) {
                        $dragclone = $(ui.draggable).clone();
                        $inputtype = $dragclone.attr("data-inputtype");
                        $inputname = $dragclone.attr("data-inputname");
                        
						if($inputtype=="agreement"){
						$reqboxclone = $(".template-container").find(".drag-model.agreement-panel").clone();
						 $reqboxclone.find(".input-name,.name-heading").html($inputname);
						}else if($inputtype=="agreementtarget"){
						$reqboxclone = $(".template-container").find(".drag-model.agreement-target-panel").clone();
						 $reqboxclone.find(".input-name,.name-heading").html($inputname);
						}else if($inputtype=="account"){
						$reqboxclone = $(".template-container").find(".drag-model.account-panel").clone();
						 $reqboxclone.find(".input-name,.name-heading").html($inputname);
						}else if($inputtype=="ndatype"){
						$reqboxclone = $(".template-container").find(".drag-model.ndatype-panel").clone(); 
						$reqboxclone.find(".input-name,.name-heading").html($inputname);
						}else{
						$reqboxclone = $(".template-container").find(".drag-model.template-type-panel").clone();
						 $reqboxclone.find(".required-name-text .first-name,.input-name,.name-heading").html($inputname);
						}
						
						$reqboxclone.attr("data-inputtype",$inputtype);
                        $reqboxclone.attr("data-inputname",$inputname);
                       // $reqboxclone.find(".required-name-text .first-name,.input-name,.name-heading").html($inputname);
                       // $reqboxclone.find(".moreCategoriesSelectDynamic").selectbox();
						$reqboxclone.hide();
						 $(".content-panel-outr:visible .tab-container:visible").find(".drag-drop-panel-outr").append($reqboxclone);
                        $reqboxclone.slideDown();
						newRulesSortable();
						 $('.tooltip').tipsy({
							gravity: 's'
						});
						$(".view-by").slideDown();
						$(".content-panel-outr:visible").find(".wizard-content").attr("data-height",$(".content-panel-outr:visible").find(".wizard-content").height());
						resetSetHeight();
						$(this).closest(".content-panel-outr:visible").find(".save-step-tab").removeAttr("disabled");
						$(".drag-model").show();
                    }
                }
            });
     //   }
    }

    function newRulesSortable() {
        $(
            ".steps-library-box .new-rules-library,.rule-set-box-drop"
        ).sortable({
            helper: 'clone',
            revert: true,
            containment: 'document',
            tolerance: "intersect",
            placeholder: 'ui-state-highlight',
            connectWith: ".rule-set-box-drop",
            receive: function(event, ui) {
                //console.log($('.rule-set-box-drop').is(":hover"));
                $rulesetboxclone = $(
                    ".rule-date-template").find(
                    ".rule-set-box").clone();
                $(this).find(".new-rules-library").remove();
                $(this).append($rulesetboxclone);
                $(this).removeClass("rule-set-box-drop");
                $(this).sortable({
                    disabled: true
                });
                //$( ".steps-library-box.rule-set-box-drop").append($(ui).item);
            },
            stop: function(event, ui) {
                $(this).sortable('cancel');
            }
        }).disableSelection();
        $('body').label_radio_check();
    }
    requiredNameSortable();
    requiredNameDragDrop();
    newRulesSortable();
    /*-- Drag n Drop STOP --*/ 
	 
	 
	 
	$(document).mouseup(function(e) {
        var container = $(".dropdown-label,.properties-information-panel");
        if (!container.is(e.target) // if the target of the click isn't the container...
            && container.has(e.target).length === 0) // ... nor a descendant of the container
        {
            $(".properties-information-panel").slideUp(function() {
                $(".dropdown-label").removeClass(
                    "active");
                $(".dropdown-label").find(
                    ".toggle-arrow").removeClass(
                    "active");
            });
        }
        var container = $(".icon-edit,.create-edit-tooltip");
        if (!container.is(e.target) // if the target of the click isn't the container...
            && container.has(e.target).length === 0) // ... nor a descendant of the container
        {
            //$(".properties-information-panel").slideUp(function(){
            $(".icon-edit").removeClass("active");
            $(".create-edit-tooltip").hide("active");
            //});

        }
        var container = $(
            ".li-rule li,.drag-inner-box.rule-sets-popup");
        if (!container.is(e.target) // if the target of the click isn't the container...
            && container.has(e.target).length === 0) // ... nor a descendant of the container
        {
            $(".rule-sets-popup").fadeOut();
            $(".fader-bg").fadeOut();
            $(".personal-information-box").removeClass(
                "z-index-large");
        }
        var container = $(".edit-tab-wrapper");
        if (!container.is(e.target) // if the target of the click isn't the container...
            && container.has(e.target).length === 0) // ... nor a descendant of the container
        {
            $(".edit-tab-shadow").removeClass("active");
            $(".edit-tab-wrapper .tab-drop-down").slideUp();
        }
    });
	
	
	/**Comparison button**/
	$(".comparison-outer .equal-box").on("click",function(){
		$(".comparison-outer .equal-box").removeClass("active");
		$(this).addClass("active");
		$(this).closest(".comparison-outer").find(".com-two-box").fadeToggle();									   
	});
	
	$(".com-two-box .inner-box").on("click",function(){
		if($(this).hasClass("this-equal")){
		$(this).closest(".comparison-outer").find(".equal-box.active").addClass("this-equal").removeClass("this-notequal");
		//$(this).closest(".comparison-outer").find(".equal-box.active").html("=");
		}else if($(this).hasClass("this-notequal")){
		$(this).closest(".comparison-outer").find(".equal-box.active").addClass("this-notequal").removeClass("this-equal");
		//$(this).closest(".comparison-outer").find(".equal-box.active").html("=");
		}
		$(this).closest(".comparison-outer").find(".equal-box").removeClass("active");
		$(this).closest(".com-two-box").fadeOut();
	});
	
	$(".rule-saved").on("click",function() {
		$(".drag-model.rule-edited-panel").slideDown();		
		$(".step-outr-panel .drag-drop-panel-outr").sortable({
	        handle: ".switch-icon",
	        axis: "y"
	    });			
 		$.fancybox.close();	
	});
	
	$('.fancyClose').on('click', function() {
	    $.fancybox.close();
	});

	$("#saveConnection").on('click', function(){
		isSavingConnection = true;
		$.fancybox.close();
	});
	
	$("#addAnotherRule").on("click", function(e){
		ruleCount++;

		ruleRow.find("td").eq(0).html(ruleCount + '.');

		$('#rulesTbl > tbody > tr:last').before(ruleRow[0].outerHTML);

		$("#advancedExpression").val($("#advancedExpression").val() + " OR " + ruleCount);
	});



	$(".wizard-list-box .basic-info-bg").on("click",function(){
		return;
		$cont = $(".tiny-drag-drop-area-outr");
		$ttext = $(this).find(".information-text").text();
		$sectemp = $(".drag-section-template").find(".tiny-drag-box").clone();
		$sectemp.find(".tiny-drag-box-body h2").html($ttext);
		$sectemp.hide();
		$cont.find(".tiny-drag-drop-area:eq(0)").before($sectemp);
		$sectemp.slideDown();
	});
	$(".add-rule-plus").on("click",function(){
		$rCount = 0;
		$cont = $(this).closest(".fancybox-inner");									
		$clonetemp = $cont.find(".rule-template .one-rule-box").clone();
		//$clonetemp.find(".moreCategoriesSelectDynamic").selectbox();
		$clonetemp.hide();
		$cont.find(".rules-wrapper").append($clonetemp);
		$clonetemp.slideDown();
		$(this).closest(".fancybox-inner").css({"height":"auto"});
		$rCount = $cont.find(".rules-wrapper .one-rule-box").length;
		newRuleSugg();
		$('.tooltip').tipsy({ gravity: 's'});
		$("#rule-overlay").getNiceScroll().resize();
	});
	$("td").click(function(){
		$(".rule-set-wrapper").getNiceScroll().resize();
		
		})
	
	
	$(".rule-set-saved").on("click",function(){
		return;									 
		$cont = $(".rule-wizard-panel-outr");
		$cu = 0;
		$(this).closest(".fancybox-inner").find(".rules-wrapper .one-rule-box").each(function(i){
			$rt = $(this).find(".rule-inner-select select").val();
			$crt = $(this).find(".criteria-rule input[type=text]").val();
			$crtv = $(this).find(".criteria-value select").val();
			$gts = $(this).find(".go-to-step input[type=text]").val();
			$wt = $(this).find(".go-to-step").attr("data-wizardtype");
			
			$ruleclone = $cont.find(".rule-placement-template").find(".rule-date").clone();	
			$ruleclone.find(".first-arrow").html("Rule 1."+(i+1)+":");
			$ruleclone.find(".rt-go-to-step").html($rt);
			$ruleclone.find(".rt-agreement").html($crt);
			$ruleclone.find(".rt-nda").html($crtv);
			$ruleclone.find(".rt-aad").html($gts);
			$rnum = $ruleclone.find(".first-arrow").text();
			$rl = "00"+$cont.find(".rule-placement-wrapper").find(".rule-date").length;
			$ruleclone.attr("data-rsid",$rl);
			$cont.find(".rule-placement-wrapper").append($ruleclone);
			
			$conta = $(".rule-plan-box-outr.show-rules");
			$sw =250;
			$conta.find(".rule-plan-box-wrapper .rule-plan-box-sub-outr").each(function(){
			$sw = $sw+250;
			})
			$conta.find(".rule-plan-box-wrapper").width($sw);
			
			$rsc = "";
			if($wt == "Steps")
			$rsc = $conta.find(".rule-plan-box-template .rule-plan-box-sub-outr.stepsLibrary").clone();
			else if($wt == "Wizard")
			$rsc = $conta.find(".rule-plan-box-template .rule-plan-box-sub-outr.wizardLibrary").clone();
			else
			$rsc = $conta.find(".rule-plan-box-template .rule-plan-box-sub-outr.stepsLibrary").clone();
			
			$rsc.find(".rule-plan-label span").html($rnum.replace("", ":"));
			$rsc.attr("data-rsid",$rl);
			
			if($.trim($gts).length){
				$cu++;
				
				$rsc.find(".tiny-drag-box-body h2").html($gts);
				$conta.find(".rule-plan-box-wrapper").append($rsc);
				$(".rule-wizard-panel-out-stick").show();
			}
			//$(".rule-wizard-panel-outr,.tiny-drag-box-sub-level01,.rule-plan-box-outr,.rule-plan-outer").slideDown();
			$(".rule-wizard-panel-outr,.rule-plan-box-outr").slideDown();
			
			if($cu>2)
			$("#temp-rule-block").slideDown();
			
			console.log($cu);
			
			$(".tiny-drag-drop-area").slideUp(function(){
				$(".rule-plan-box-outr.show-rules").getNiceScroll().resize();	
				
				});
			$(".save-wizard-tab").removeAttr("disabled");
		});	
		$('.tooltip').tipsy({ gravity: 's'});
		setTimeout(function(){
		$("#rule-overlay").getNiceScroll().resize();	
		 }, 1000);						 
	});
	
	/* Delete rule*/
	
	$(document).on("click",".rule-date .delete-icon,.tiny-drag-box .delete-icon",function(){
		$rid = $(this).closest("*[data-rsid]").attr("data-rsid");
		$("#temp-rule-block,#drag-stick").slideUp();
		$("*[data-rsid="+$rid+"]").slideUp(function(){
			$(this).remove();
			if($(".rule-placement-wrapper .rule-date").length<1){
			$(".rule-wizard-panel-outr,.rule-begin-stick-inner.rule-wizard-panel-out-stick").slideUp();
			$(".tiny-drag-drop-area").slideDown();
			}
		});
		$(".tipsy").remove();
	});
	
	
	$(document).on("click",".del-box .popup-delete",function(){
		$(this).closest(".one-rule-box").remove();
		$(".tipsy").remove();
	})

	
	var sourceNode = "";
	var targetNode = "";

function wizardDragDrop() {
      //  if ($(".wizard-tab:visible").length) {
            
			$(".wizard-list-box").find(".basic-info-bg").draggable({
                //  use a helper-clone that is append to 'body' so is not 'contained' by a pane
                helper: function() {
                    return $(this).clone().appendTo(
                        'body').css({
                        'zIndex': 5
                    });
                },
                revert: 'invalid',
                cursor: 'move',
                containment: "document",
				start: function( event, ui ) {
					$this = $(this);
					$isDrop = false;
					$sectemp = "";
					$(".tiny-drag-drop-area-outr").droppable({
							accept: ".basic-info-bg",
							activeClass: "ui-state-hover",
							hoverClass: "ui-state-active",
							drop: function(event, ui) {
								if (!ui.draggable.hasClass("dropped")) {
									$isDrop = true;
									$dragclone = $(ui.draggable).clone();
									$cont = $(".tiny-drag-drop-area-outr");
									$ttext = $dragclone.find(".information-text").text();
									//$sectemp = $(".rule-plan-box-template .tiny-drag-box.stepsSingle").clone();
									
									if($this.closest(".wizard-list-box").hasClass("wizard-drag-list-box-ul")){
										$sectemp = $(".rule-plan-box-template .tiny-drag-box.wizard-drag-list-box-panel").clone();
									} else {
										$sectemp = $(".rule-plan-box-template .tiny-drag-box.stepsSingle").clone();
									}
									
									
									$sectemp.find(".tiny-drag-box-body h2").html($ttext);
									$sectemp.addClass("del-div");

				    				$(".save-wizard-tab").removeAttr("disabled");
									$('.tooltip').tipsy({ gravity: 's'});
								}
								/*$cont.find(".wizard-dragged-content").sortable({
									  axis: "y",
									  helper: function(event, elm) {
										console.log(elm);
										return $(elm).clone().position({
										  my: "left",
										  at: "left",
										  of: elm.parent()
										});
									  }
									});*/
								
							}
							});
				$(".wizard-dragged-content").droppable({
							accept: ".basic-info-bg",
							activeClass: "ui-state-hover",
							hoverClass: "ui-state-active",
							drop: function(event, ui) {
								if (!ui.draggable.hasClass("dropped")) {
									$isDrop = true;
									$dragclone = $(ui.draggable).clone();
									$cont = $(".tiny-drag-drop-area-outr");
									$ttext = $dragclone.find(".information-text").text();
									//$sectemp = $(".rule-plan-box-template .tiny-drag-box.stepsSingle").clone();
									
									if($this.closest(".wizard-list-box").hasClass("wizard-drag-list-box-ul")){
									$sectemp = $(".rule-plan-box-template .tiny-drag-box.wizard-drag-list-box-panel").clone();
									}else{
									$sectemp = $(".rule-plan-box-template .tiny-drag-box.stepsSingle").clone();

									}
									
									
									$sectemp.find(".tiny-drag-box-body h2").html($ttext);
									//$sectemp.hide();
									$sectemp.find(".rule-begin-stick-inner").remove();
									$sectemp.addClass("del-div disable-box");
									//$(".content-panel-outr.wizard-tab").append($sectemp);
									
                                    $("#drag-stick").slideDown();
				   					$(".save-wizard-tab").removeAttr("disabled");
									$('.tooltip').tipsy({ gravity: 's'});
								}
								
							}
						});
				
						$(".rpt-table-row").droppable({
							accept: ".basic-info-bg",
							activeClass: "ui-state-hover",
							hoverClass: "ui-state-active",
							drop: function(event, ui) {
								if (!ui.draggable.hasClass("dropped")) {
									$dragclone = $(ui.draggable).clone();
									$cont = $(".tiny-drag-drop-area-outr");
									$sectemp = $(".step-lib-group-templates .group-box-wdgt").clone();
									$sectemp.hide();
									$(this).append($sectemp);
									$sectemp.slideDown();
									$(this).closest(".drag-model-body").find(".save-group").removeAttr("disabled");
								}
								
							}
							});
				
						$(".group-drag-panel").droppable({
							accept: ".basic-info-bg",
							activeClass: "ui-state-hover",
							hoverClass: "ui-state-active",
							drop: function(event, ui) {
								if (!ui.draggable.hasClass("dropped")) {
									$sectemp = $(".step-lib-group-templates .group-box-wdgt").clone();
									$sectemp.hide();
		$(this).closest(".drag-model-body").find(".group-panel-placeholder .rpt-table-row-outr").append("<div class='rpt-table-row'></div>");
$(this).closest(".drag-model-body").find(".group-panel-placeholder .rpt-table-row:last").append($sectemp);
									$sectemp.slideDown();
									$(this).closest(".drag-model-body").find(".save-group").removeAttr("disabled");
								}
								
							}
							});
			
			
				
					 },stop: function( event, ui ) {
						if($isDrop) {
							wizardBldr.renderNewStep('flowchartWindow' + i, $sectemp, ui);
						
							i++;
						}
	
					}
            });
          
			 $(".rule-list-box").find(".rule-bg").draggable({
                //  use a helper-clone that is append to 'body' so is not 'contained' by a pane
                helper: function() {
                    return $(this).clone().appendTo(
                        'body').css({
                        'zIndex': 5
                    });
                },
                revert: 'invalid',
                cursor: 'move',
                containment: "document",
				start: function( event, ui ) {
							$dd = $(this).closest(".rule-list-box").attr("data-dropdiv");
							console.log($("."+$dd+":visible").length);
							$("."+$dd+":visible").droppable({
							accept: ".rule-bg",
							activeClass: "ui-state-hover",
							hoverClass: "ui-state-active",
							drop: function(event, ui) {
								if (!ui.draggable.hasClass("dropped")) {
									if($dd == "tiny-drag-drop-area"){
									$.fancybox({
										'titlePosition': 'inside',
										'transitionIn': 'none',
										'transitionOut': 'none',
										'href': '#rule-model2'
									});
									}else if($dd == "drag-drop-area-outr"){
									$.fancybox({
										'titlePosition': 'inside',
										'transitionIn': 'none',
										'transitionOut': 'none',
										'href': '#rule-model'
									});
									}
								}
								$('.tooltip').tipsy({ gravity: 's'});
							}
							});
							
								$(".tiny-drag-box").droppable({
										accept: ".rule-bg",
										activeClass: "ui-state-hover",
										hoverClass: "ui-state-active",
										drop: function(event, ui) {
											if (!ui.draggable.hasClass("dropped")) {
												
												$sectemp = $(".rule-plan-box-template .rule-plan-label-temp").clone();
												
												$sectemp.find("span").html("Rule "+($(".rule-plan-label:visible").length+1));
												if(!$(this).find(".rule-plan-label").length)
												$(this).append($sectemp);
												
												$('.tooltip').tipsy({ gravity: 's'});
											}
											
										}
								});	
					 }
            });
        
    }
	
	wizardDragDrop();
	newRuleSugg();
/*	
	$( ".tiny-drag-drop-area-outr" ).resizable({
    handles: 's'});*/
	
	$(".rule-set-wrapper .rule-plan-box-outr").draggable({
                cursor: 'move'													 
	});
	
	$(document).on("click",".delete-icon",function(){
		$(this).closest(".del-div").slideUp(function(){
			$(this).remove();
		});
	})
	
	$(document).on("click",".save-group",function(){
		  $val = $(this).closest(".drag-model").find(".drag-model-header .drag-model-heading").text();
		  $(".basic-info-bg:eq(0) span").html($val);
		  greenFade($(".basic-info-bg:eq(0)"));
		  $('html,body').animate({
            scrollTop: 0
        }, 'slow');
	});
	
	$(document).on("click",".new-group",function(){
		 $clone = $(".new-group-layout-template .drag-model.group-panel").clone();
		 $clone.hide();
		 $(".group-panel-wrapper").append($clone);
		 $clone.slideDown();
		 $clone.label_radio_check();
	});
	
	$(".rich-tabhdr-cell-inactive").on("click",function(){
		wizardDragDrop();
		newRuleSugg();
	});
	
		$(document).mouseup(function (e) {
			var container = $(".wizard-overlay-box");
	
			if (!container.is(e.target) // if the target of the click isn't the container...
					&& container.has(e.target).length === 0) // ... nor a descendant of the container
			{
					container.hide();
					
			}
    
});
	
	$rc = $(".rule-overlay-outr-template .rule-overlay-outr").clone(); 
	 $(".rule-set-wrapper .rule-plan-box").each(function(ind){
	  $ts = ind+1;
	  //console.log($ts);
	  $(this).find("li.rule-list").each(function(index){
	   $tss = index+1;
	   $rc = $(".rule-overlay-outr-template .rule-overlay-outr").clone(); 
	   $rc.find(".first-arrow").html("Rule "+$ts+"."+$tss+":");
	   $(this).append($rc);
	  });
	 });
	 
	 $(".rule-list").on("click",function(){
	  $(".rule-list").not($(this)).removeClass("active");
	  $(this).addClass("active");
	 });
	 
	 	 
	 $(".rule-overlay-outr .close-rule-window").on("click",function(){
		$(this).closest(".rule-list").removeClass("active");															
	 });
	 
	 /*-----------------------*/
	 
	 $(".add-address").on("click",function(){
		$clone = $(".wizard-process-panel-left-template .wizard-process-panel-left").clone();
		$clone.hide();
		$(".wizard-process-panel-left-wrapper").append($clone);
		$clone.slideDown();
		//$clone.find(".moreCategoriesSelectDynamic").selectbox();
	});
	 
	 
	 $(".view-wizard-design").on("click",function(){
		$(".wizard-tab-main-panel").show();
     	$("html, body").animate({scrollTop:652}, '800');
		$(".wizard-design-tab a").trigger("click");
	 });
	 
	 $(".create-wizard-design").on("click",function(){ 
     	$(".wizard-tab-main-panel").show();
     	$("html, body").animate({scrollTop:652}, '800');
		$(".wizard-design-tab a").trigger("click");
	 });
	  
	  $(".my-wizard-design").on("click",function(){ 
     	$(".wizard-tab-main-panel").show();
		$("html, body").animate({scrollTop:652}, '800');
		$(".my-wizard-tab a").trigger("click");
	 });
	 
	 
	 $(document).on("click",".table-layout-option",function(){
		if($(this).is(":checked")){
			$(this).closest(".drag-model-body").addClass("table-view-layout"); 
			$ww = 0;
			$(this).closest(".drag-model-body").find(".rpt-table-format").width($(this).closest(".drag-model-body").width());
			$(this).closest(".drag-model-body").find(".rpt-table-row").each(function(){
				$(this).find(".group-box-wdgt").each(function(){
					$ww = $ww + $(this).outerWidth(true)+40;
					console.log("11111-"+$ww+"-----"+$(this).outerWidth(true));
					})
			})
			$(this).closest(".drag-model-body").find(".rpt-table-row-outr").width($ww);
			$lr = "";
			$this = $(this);
			$(this).closest(".drag-model-body").find(".rpt-table-format").addClass("right-move")
			$(this).closest(".drag-model-body").find(".rpt-table-row-outr").draggable({
			  axis: "x",
			  cursor: "move",
				start: function(event, ui) {
					start = ui.position.left;
				},
				stop: function(event, ui) {
					stop = ui.position.left;
					if((start < stop))
					$lr = "left-move";
					else
					$lr = "right-move";
					
					$this.closest(".drag-model-body").find(".rpt-table-row-outr").closest('.rpt-table-format').removeClass("left-move right-move");
					$this.closest(".drag-model-body").find(".rpt-table-row-outr").closest('.rpt-table-format').addClass($lr);
				}
			});
			
		}else{
			$(this).closest(".drag-model-body").removeClass("table-view-layout");
			
			$(this).closest(".drag-model-body").find(".rpt-table-format").removeClass("left-move right-move")
			$(this).closest(".drag-model-body").find(".rpt-table-row-outr").draggable( "destroy" );
			$(this).closest(".drag-model-body").find(".rpt-table-row-outr").css("width","100%");
			$(this).closest(".drag-model-body").find(".rpt-table-format,.rpt-table-row-outr").removeAttr("style");	
		}
	});
	 
	// jQuery("html, body").animate({scrollTop:100}, '500');
	 
	$(".preview-step-two").click(function(){
		$(".address-wrapper").html("");
		$(".wizard-process-panel-left-wrapper:visible .wizard-process-panel-left").each(function(){
			$(this).find("*[data-ffname]").each(function(){
					$vn = $(this).attr("data-ffname");
					if($.trim($(this).val()).length)
					$vv = $.trim($(this).val());
					else
					$vv = "--";
					$addf = '<div class="user-info-row"><div class="user-info-label">'+$vn+'</div><div class="user-info-value">'+$vv+'</div></div>';	
					$(".address-wrapper").append($addf);											
			});	
			$(".address-wrapper").append("<div class='divider-addr'></div>");	
		});								  
	});
	
	$(".preview-step-three").click(function(){
		$(".wizard-process-panel-left-wrapper:visible .wizard-process-panel-left").each(function(){
			$rr = $(".user-information-details.contactDetail .user-info-row");
			$rr.find(".user-info-value").eq(0).html($(this).find("[data-ffname=001]").val());
			$rr.find(".user-info-value").eq(1).html($(this).find("[data-ffname=002]").val());
			$rr.find(".user-info-value").eq(2).html($(this).find("[data-ffname=003]").val());
			$rr.find(".user-info-value").eq(3).html($(this).find("[data-ffname=004]:checked").val());
			$rr.find(".user-info-value").eq(4).html($(this).find("[data-ffname=005]:checked").val());
			$rr.find(".user-info-value").eq(5).html($(this).find("[data-ffname=006]").val());
			$rr.find(".user-info-value").eq(6).html($(this).find("[data-ffname=007]").val());	
		});								  
	});	
	
	$(".preview-step-four").click(function(){
		$(".wizard-process-panel-left-wrapper:visible .wizard-process-panel-left").each(function(){
			$rr = $(".user-information-details.dpi .user-info-row");
			$rr.find(".user-info-value").eq(0).html($(this).find("[data-ffname=001]:checked").val());
			$rr.find(".user-info-value").eq(1).html($(this).find("[data-ffname=002]:checked").val());
		});								  
	});	
	
	
	$(".preview-step-five").click(function(){
		$(".wizard-process-panel-left-wrapper:visible .wizard-process-panel-left").each(function(){
			$rr = $(".user-information-details.lad .user-info-row");
			$rr.find(".user-info-value").eq(0).html($(this).find("[data-ffname=001]:checked").val());
		});								  
	});	
	
	$(".select-file-upload").on("click",function(){
		$(this).closest(".choose-file-area").find(".select-filepath").trigger("click");
	});
	
	/* Set dynamic height to wizard-list-box START */
	
	
	var setWizardListBoxHeight = function(){
		$ht = $(".wizard-content:visible").height();
		$(".wizard-sidebar:visible").find(".wizard-list-box").css("max-height",$ht);
	};
	
	
	$(window).resize(function () {
		waitForFinalEvent(function(){
		  setTabTrackWidth();
		}, 500, "resizetabWidth");
	});
	
	setTimeout(function(){
		setTabTrackWidth();
		setWizardListBoxHeight();	
	}, 500);
	
	$(document).on("click",".collapse,.rich-tab-header",function(){
		setWizardListBoxHeight();								 
	});
	
	
	
	
	
	
	
	/* Set dynamic height to wizard-list-box STOP */
	
	
	function readURL(input) {
        if (input.files && input.files[0]) {
            var reader = new FileReader();

            reader.onload = function (e) {
                $(input).closest(".choose-file-area").find("img").attr('src', e.target.result);
            }

            reader.readAsDataURL(input.files[0]);
        }
    }
	$(".choose-file-area").find('input[type=file]').change(function () {
		readURL(this);
	});
	
	
	
	 
	 var availableTags = [
      "Account 1",
      "Account 2",
      "BASIC",
      "C"
    ];
    $( ".show-results" ).autocomplete({
      source: availableTags
    });
	
	var availableWizards = [
      "Wizard 1",
      "Wizard 2",
      "DTNWizard_CPQdemo 1",
      "DTNWizard_CPQdemo 2",
      "Form Wizard",
	  "Wizard Form"
    ];
    $( ".show-wizards-list" ).autocomplete({
      source: availableWizards,
	   select: function( event, ui ) {
		compLibStepsSearchCW(ui.item.value, $(".ui-tabs-panel:visible"));   
		},
      create: function( event, ui ) {
       $(this).autocomplete("widget").addClass("dashboard-ui-autocomplete");
      }
    });
	
	var availableAccounts = [
      "CCLR0001341",
      "ACLR0001393",
      "BCLR00033991",
	  "FCLR0005531A",
      "YCLR0025003D",
      "ZCLR00383257"
	  ];
    $( ".show-account-list" ).autocomplete({
      source: availableAccounts,
	   select: function( event, ui ) {
		compLibStepsSearchCW(ui.item.value, $(".ui-tabs-panel:visible"));   
		},
      create: function( event, ui ) {
       $(this).autocomplete("widget").addClass("account-ui-autocomplete");
      }
    });
	 
	 
	 var availableCustomer = [
      "Andrew",
      "Chuck",
      "David",
	  "jonh Smith",
      "Neleson",
      "George"
	  ];
    $( ".show-customer-list" ).autocomplete({
      source: availableCustomer,
	   select: function( event, ui ) {
		compLibStepsSearchCW(ui.item.value, $(".ui-tabs-panel:visible"));   
		},
      create: function( event, ui ) {
       $(this).autocomplete("widget").addClass("customer-ui-autocomplete");
      }
    });
	
	 var availableEmployee = [
      "Andrew",
      "Chuck",
      "David",
	  "jonh Smith",
      "Neleson",
      "George"
	  ];
    $( ".show-employee-list" ).autocomplete({
      source: availableEmployee,
	   select: function( event, ui ) {
		compLibStepsSearchCW(ui.item.value, $(".ui-tabs-panel:visible"));   
		},
      create: function( event, ui ) {
       $(this).autocomplete("widget").addClass("employee-ui-autocomplete");
      }
    });
	 
	 
});

function newRuleSugg(){
 jQuery(function($) {
 $.widget( "custom.catcomplete", $.ui.autocomplete, {
    _create: function() {
      this._super();
      this.widget().menu( "option", "items", "> :not(.ui-autocomplete-category)" );
	// console.log($(this));
	  // $(this).next(".newrulesugg").html($(this).autocomplete("widget"));
	
    },
    _renderMenu: function( ul, items ) {
      var that = this,
        currentCategory = "";
      $.each( items, function( index, item ) {
        var li;
        if ( item.category != currentCategory ) {
          ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
          currentCategory = item.category;
        }
        li = that._renderItemData( ul, item );
        if ( item.category ) {
          li.attr( "aria-label", item.category + " : " + item.label );
        }
      });
    }
  });
  
    var data = [
      { label: "annhhx10", category: "Steps" },
      { label: "annk K12", category: "Steps" },
      { label: "annttop C13", category: "Steps" },
      { label: "anders andersson", category: "Wizard" },
      { label: "andreas andersson", category: "Wizard" },
      { label: "andreas johnson", category: "Wizard" }
    ];
 
   $( ".go-to-step .search-field-popup" ).catcomplete({
      delay: 0,
      source: data,
      create: function( event, ui ) {
       $(this).catcomplete("widget").addClass("rule-ui-autocomplete");
      },
      select: function( event, ui ) {
        $(this).closest(".go-to-step").attr("data-wizardtype",ui.item.category);
		//console.log(ui.item.label+"===="+ui.item.category);

      }
    });
    });
}

