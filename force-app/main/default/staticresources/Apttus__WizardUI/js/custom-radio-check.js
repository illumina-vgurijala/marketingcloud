(function($){
		  
		   var isIE = function() {
        var myNav = navigator.userAgent.toLowerCase();
        return (myNav.indexOf('msie') != -1) ? parseInt(myNav.split('msie')[1]) : false;
    }

    if (isIE() && isIE() < 9) {
        $("label").unbind('click').on('click', function() {
            $(this).find(':checkbox, :radio').prop('checked', $(this).find('input').prop('checked') ? true : false).change();
        });
    }
	
	$.fn.label_radio_check=function(){$(':radio').on('change',function(){setTimeout(function(){$(':radio:not(:checked)').closest('.label_radio').removeClass('r_on').addClass('r_off');$(':radio:checked').closest('.label_radio').removeClass('r_off').addClass('r_on');$(':radio:not(:disabled)').closest('.label_radio').removeClass('r_dis');$(':radio:disabled').closest('.label_radio').addClass('r_dis');},10)});$('span.label_radio').on('click',function(){$(this).find(':radio').attr('checked','checked');var radio_name=$(this).find(':radio').attr('name');$(':radio[name='+radio_name+']:not(:checked)').closest('.label_radio').removeClass('r_on').addClass('r_off');$(this).removeClass('r_off').addClass('r_on');});$(':checkbox').on('change',function(){setTimeout(function(){$(':checkbox:not(:checked)').closest('.label_check').removeClass('c_on').addClass('c_off');$(':checkbox:checked').closest('.label_check').removeClass('c_off').addClass('c_on');$(':checkbox:not(:disabled)').closest('.label_check').removeClass('c_dis');$(':checkbox:disabled').closest('.label_check').addClass('c_dis');},10)});$("span.label_check").on('click',function(){$(this).find(':checkbox').trigger('click');}).children().click(function(e){e.stopPropagation();});var d=document;var safari=(navigator.userAgent.toLowerCase().indexOf('safari')!=-1)?true:false;var gebtn=function(parEl,child){return parEl.getElementsByTagName(child);};var gebtn2=function(parEl,child){return $('.'+child)};var body=gebtn(d,'body')[0];body.className=body.className&&body.className!=''?body.className+' has-js':'has-js';if(!d.getElementById||!d.createTextNode)return;var ls=gebtn2(d,'label_check');for(var i=0;i<ls.length;i++){var l=ls[i];var inp=gebtn(l,'input')[0];if(inp.checked)
$(l).removeClass('c_off').addClass('c_on');else
$(l).removeClass('c_on').addClass('c_off');if($(inp).is(':disabled'))
$(l).addClass('c_dis');else
$(l).removeClass('c_dis');};var ls=gebtn2(d,'label_radio');for(var i=0;i<ls.length;i++){var l=ls[i];var inp=gebtn(l,'input')[0];if(inp.checked)
$(l).removeClass('r_off').addClass('r_on');else
$(l).removeClass('r_on').addClass('r_off');if($(inp).is(':disabled'))
$(l).addClass('r_dis');else
$(l).removeClass('r_dis');};};})(jQuery);
