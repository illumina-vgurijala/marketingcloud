/**
 * This file needs a description 
 * @class com.servicemax.client.sfmopdocdelivery.utils
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var sfmopdocdeliveryutil = SVMX.Package("com.servicemax.client.sfmopdocdelivery.utils");

sfmopdocdeliveryutil.init = function(){
	sfmopdocdeliveryutil.Class("SFMOPDOCUtils", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		localeInfo : {
			"en_US" : { "DS" : "." , "TS" : ","},
			"en_GB" : { "DS" : "." , "TS" : ","},
			"en_AU" : { "DS" : "." , "TS" : ","},
			"en_NZ" : { "DS" : "." , "TS" : ","},
			"fr" : { "DS" : "," , "TS" : " "},
			"fr_BE" : { "DS" : "," , "TS" : "."},
			"fr_CA" : { "DS" : "," , "TS" : " "},
			"fr_CH" : { "DS" : "." , "TS" : "'"},
			"fr_FR" : { "DS" : "," , "TS" : " "},
			"fr_LU" : { "DS" : "," , "TS" : " "},
			"fr_MC" : { "DS" : "," , "TS" : " "},
			"pt_BR" : { "DS" : "," , "TS" : "."},
			"pt_AO" : { "DS" : "," , "TS" : "."},
			"pt_PT" : { "DS" : "," , "TS" : "."},
			"pt" : { "DS" : "," , "TS" : "."},
			"es" : { "DS" : "," , "TS" : "."},
			"es_AR" : { "DS" : "," , "TS" : "."},
			"es_BO" : { "DS" : "," , "TS" : "."},
			"es_CL" : { "DS" : "," , "TS" : "."},
			"es_CO" : { "DS" : "," , "TS" : "."},
			"es_CR" : { "DS" : "." , "TS" : ","},
			"es_DO" : { "DS" : "." , "TS" : ","},
			"es_EC" : { "DS" : "," , "TS" : "."},
			"es_ES" : { "DS" : "," , "TS" : "."},
			"es_GT" : { "DS" : "." , "TS" : ","},
			"es_HN" : { "DS" : "." , "TS" : ","},
			"es_MX" : { "DS" : "." , "TS" : ","},
			"es_PA" : { "DS" : "." , "TS" : ","},
			"es_PE" : { "DS" : "," , "TS" : "."},
			"es_PR" : { "DS" : "." , "TS" : ","},
			"es_PY" : { "DS" : "," , "TS" : "."},
			"es_SVUS" : { "DS" : "." , "TS" : ","},
			"es_UY" : { "DS" : "," , "TS" : "."},
			"es_VE" : { "DS" : "," , "TS" : "."},
			"de" : { "DS" : "," , "TS" : "."},
			"de_AT" : { "DS" : "," , "TS" : "."},
			"de_CH" : { "DS" : "." , "TS" : "'"},
			"de_DE" : { "DS" : "," , "TS" : "."},
			"de_LU" : { "DS" : "," , "TS" : "."},
			"ja" : { "DS" : "." , "TS" : ","},
			"ja_JP" : { "DS" : "." , "TS" : ","},
			"zh" : { "DS" : "." , "TS" : ","},
			"zh_CN" : { "DS" : "." , "TS" : ","},
			"zh_SG" : { "DS" : "." , "TS" : ","},
			"zh_TW" : { "DS" : "." , "TS" : ","},
			"zh_HK" : { "DS" : "." , "TS" : ","},
			"zh_CN" : { "DS" : "." , "TS" : ","},
			"zh_MO" : { "DS" : "." , "TS" : ","},
			"ko" : { "DS" : "." , "TS" : ","},
			"ko_KR" : { "DS" : "." , "TS" : ","},
			"it" : { "DS" : "," , "TS" : "."},
			"it_CH" : { "DS" : "." , "TS" : "'"},
			"it_IT" : { "DS" : "," , "TS" : "."},
			"nl" : { "DS" : "," , "TS" : "."},
			"nl_BE" : { "DS" : "," , "TS" : "."},
			"nl_NL" : { "DS" : "," , "TS" : "."},
			"nl_SR" : { "DS" : "," , "TS" : "."}
		},	
		
		localeFormat : function(locale, value, scale){		
			var formattedValue;
			var DS = ".", TS = ","; 
			if(this.localeInfo[locale] !== undefined && this.localeInfo[locale] !== null && this.localeInfo[locale]){
				var currLocaleInfo = this.localeInfo[locale];
				DS = currLocaleInfo.DS;
				TS = currLocaleInfo.TS;
			}
			formattedValue = this.__formatNumber(value, DS, TS, scale);			
			return formattedValue;
		
		},
		
		__formatNumber : function(value, decimalSeparator, thousandSeparator, scale) {
			var valStr;
			if (!isNaN(scale)) {
				valStr = value.toFixed(scale);
			}
			else {
				valStr = value.toString();
			}
		    var parts = valStr.split(".");
		    return parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, thousandSeparator) + (parts[1] ? decimalSeparator + parts[1] : "");
		},

		htmlEncoding : function(str) {
			 return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
		}			
		
	});
}	
})();

// end of file
