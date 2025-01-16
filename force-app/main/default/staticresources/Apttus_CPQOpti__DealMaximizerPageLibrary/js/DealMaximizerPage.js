	<script type="text/javascript">
    
        var j$ = jQuery.noConflict();
        // add slide toggle effects dynamically
      	// click binding is on a div with id = id***Header and action is on
        // div with id = id***Block where *** is identical for both divs
        j$(document).ready(function(){
            j$( 'div[id$="Header"]' ).each(function(){
            	
                var thisId = j$(this).attr('id');
                if(!j$(this).hasClass('noArrow')){
                	j$(this).addClass('sectionDown');
                }
                if ( (/^id/).test(thisId)){
                    var headerId = j$(this).attr('id');
                    
                    var bodyId = headerId.replace('Header','Block');
                    
                    j$(this).click(function(){
                    	/*
                    	alert('headerId: ' + headerId);	
                    	alert('bodyId: ' + bodyId);	
                    	alert(j$(this).attr('id'));
                    	alert(j$('#'+bodyId).text());
                    	alert(j$('#idDealBlock').text());
                    	j$('#idDealBlock').slideToggle(400);
                    	*/
                    	
                        j$('#'+bodyId).slideToggle(400);
                        if(!j$(this).hasClass('noArrow')){
	                        if(j$(this).hasClass('sectionUp')){
	                        	j$(this).addClass('sectionDown');
	                        	j$(this).removeClass('sectionUp');
	                        }else{
	                        	j$(this).removeClass('sectionDown');
	                        	j$(this).addClass('sectionUp');
	                        }
	                  	}
                    })
                }
            })
        })

    </script>

	<script>            

	    function roundNumber(number, digits) {
        
            number = number.toString().replace(',', '');
            var multiple = Math.pow(10, digits);
            var rndedNum = Math.round(number * multiple) / multiple;
            //alert(rndedNum);
            
            return rndedNum;
        }
        
        function calcAdditionalDiscount(actionType,fieldNameBuyPrice, fieldNameSellPrice, fieldNameDiscount){
                
                //var fnBuyPrice = document.getElementById(fieldNameBuyPrice);
                var fnSellPrice = document.getElementById(fieldNameSellPrice);
                var fnDiscount = document.getElementById(fieldNameDiscount);
                
            if(actionType == "calcDiscount"){
                if(fnSellPrice.value>=0 && fieldNameBuyPrice>0){
                    var dcount=((fieldNameBuyPrice - fnSellPrice.value)/fieldNameBuyPrice) * 100;
                    fnDiscount.value = roundNumber(dcount,2);
                }
                
            }else if(actionType == "calcSellPrice"){

                if(fnDiscount.value!='' && fieldNameBuyPrice>0){
                    
                    var sp=fieldNameBuyPrice - (fieldNameBuyPrice * (fnDiscount.value/100));
                    fnSellPrice.value  = roundNumber(sp,2);
                }
                                
            }
        }
        
	</script>	