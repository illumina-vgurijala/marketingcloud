function pickupValue(additionalToValueStr, ccValueStr, bccValueStr) {        
        var delimiterValue = ';';        
        var p24 = document.getElementsByClassName('p24')[0];
        var p4 = document.getElementsByClassName('p4')[0];
        var p5 = document.getElementsByClassName('p5')[0];            
        if(additionalToValueStr != '') {
            if (p24.value != '') {
                p24.value += delimiterValue;
            }
            p24.value += additionalToValueStr;
        }
        if(ccValueStr != '') {
            
            if (p4.value != '') {
                p4.value += delimiterValue;
            }
            p4.value += ccValueStr;
        }
        if(bccValueStr != '') {
            if (p5.value != '') {
               p5.value += delimiterValue;
            }
            p5.value += bccValueStr;
        }
    	closePopup();
	}