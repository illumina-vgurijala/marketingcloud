// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfm.app.utils\src\impl.js
/**
 * This file needs a description 
 * @class com.servicemax.client.sfm.app.utils.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */
//
(function(){
	
	var impl = SVMX.Package("com.servicemax.client.sfm.app.utils.impl");
	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		
		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize : function(){
			com.servicemax.client.sfm.app.utils.pricingdefinition.init();
		},
		initialize : function(){},
		afterInitialize : function(){}
		
	}, {});
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfm.app.utils\src\pricingdefinition.js
/**
 * This file needs a description 
 * @class com.servicemax.client.sfm.app.utils.pricingdefinition
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */
//
(function(){
	
	var pricingDef = SVMX.Package("com.servicemax.client.sfm.app.utils.pricingdefinition");
	var escapeDuringFormat = true;
pricingDef.init = function(){
	var orgNameSpace = SVMX.OrgNamespace;	
	
	$EXPR.getPricingDefinition = function(context, callback){
		var i, detailRecords = context.detailRecords, l = detailRecords.length, 
				allParts = new ListOfValueMap("PARTS"), allLabor = new ListOfValueMap("LABOR"), allLaborParts = new ListOfValueMap("LABORPARTS");
		for(var i = 0; i < l; i++){
			var records = detailRecords[i].records, j, recordslength = records.length;
			for(j = 0; j < recordslength; j++){
				var record = records[j].targetRecordAsKeyValue, length = record.length, k;
				var lineType = getItemForDetailRecordKey("Line_Type__c", record);
				if(lineType != null && lineType.value != null){
					if(lineType.value == "Parts"){
						var product = getItemForDetailRecordKey("Product__c", record);
						allParts.addToValues(product.value);
					}else if (lineType.value == "Labor"){
						var laborItem = getItemForDetailRecordKey("Activity_Type__c", record);
						allLabor.addToValues(laborItem.value);
						
						var laborPartItem = getItemForDetailRecordKey("Product__c", record);
						if(laborPartItem) allLaborParts.addToValues(laborPartItem.value);
					}
				}
			}
		}

		var recordIdItem = context.headerRecord.records[0].targetRecordId;
		var recordId = new SingleValueMap("WORKORDER", recordIdItem);
		
		var reqData = recordId.getStringAsXML() + allParts.getStringAsXML() + allLabor.getStringAsXML() + allLaborParts.getStringAsXML();
		
		var currencyIsoCodeItem = getItemForDetailRecordKey("CurrencyIsoCode", context.headerRecord.records[0].targetRecordAsKeyValue);
		if(currencyIsoCodeItem != ""){
			var currencyIsoCode = new SingleValueMap("WORKORDERCURRENCYISO", currencyIsoCodeItem.value);
			reqData += currencyIsoCode.getStringAsXML();
		}

		// get the sal service factory
		var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
		servDef.getInstanceAsync({handler : function(service){
			var p = {type : "SOAP", endPoint : "INTF_WebServicesDef", nameSpace : $EXPR.getOrgNamespace()};
			var sm = service.createServiceManager(p);
			var plRequest = sm.createService();
			
			plRequest.bind("REQUEST_COMPLETED", function(evt){ 
				var xml = $.parseXml(evt.data, true);
		        var messageXML = xml.getFirstElementByTagName(
		            "message", "http://soap.sforce.com/schemas/class/"+ getOrgNameSpace(orgNameSpace) + "INTF_WebServicesDef");
		       
		       	var message = getTextDataFromXML(messageXML);
		       	
		        var messageObj = $EXPR.toObject(message);
		        callback(messageObj);
			}, this);
			
			plRequest.callMethodAsync({methodName : "PCAL_getPricingDefinition_WS", data : reqData});
		}, context : {}});
	}
	
	//case get price
	$EXPR.getCasePricingDefinition = function(context, callback){
		var i, detailRecords = context.detailRecords, l = detailRecords.length, 
				allActivities = new ListOfValueMap("ACTIVITY");
		for(var i = 0; i < l; i++){
			var records = detailRecords[i].records, j, recordslength = records.length;
			for(j = 0; j < recordslength; j++){
				var record = records[j].targetRecordAsKeyValue, length = record.length, k;
				var lineType = getItemForDetailRecordKey("Type__c", record);
				if(lineType != null && lineType.value != null){
					if(lineType.value == "Activity"){
						var activityItem = getItemForDetailRecordKey("Activity_Type__c", record);
						allActivities.addToValues(activityItem.value);						
					}
				}
			}
		}

		var recordIdItem = context.headerRecord.records[0].targetRecordId;
		var recordId = new SingleValueMap("CASE", recordIdItem);
		
		var reqData = recordId.getStringAsXML() + allActivities.getStringAsXML();
		
		var currencyIsoCodeItem = getItemForDetailRecordKey("CurrencyIsoCode", context.headerRecord.records[0].targetRecordAsKeyValue);
		if(currencyIsoCodeItem != ""){
			var currencyIsoCode = new SingleValueMap("CASECURRENCYISO", currencyIsoCodeItem.value);
			reqData += currencyIsoCode.getStringAsXML();
		}

		// get the sal service factory
		var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
		servDef.getInstanceAsync({handler : function(service){
			var p = {type : "SOAP", endPoint : "INTF_WebServicesDef", nameSpace : $EXPR.getOrgNamespace()};
			var sm = service.createServiceManager(p);
			var plRequest = sm.createService();
			
			plRequest.bind("REQUEST_COMPLETED", function(evt){ 
				var xml = $.parseXml(evt.data, true);
		        var messageXML = xml.getFirstElementByTagName(
		            "message", "http://soap.sforce.com/schemas/class/"+ getOrgNameSpace(orgNameSpace) + "INTF_WebServicesDef");
		        
		        var message = getTextDataFromXML(messageXML);

		        var messageObj = $EXPR.toObject(message);
		        callback(messageObj);
			}, this);
			
			plRequest.callMethodAsync({methodName : "PCAL_getCasePricingDefinition_WS", data : reqData});
		}, context : {}});
	}		
	
	////////////////////// GET PRICE SPECIFIC CODING ///////////////
	function ListOfValueMap(key){
		this.key = key;
		this.allValues = {};
		this.addToValues = function(value){ 
			if(!value) return;
			
			this.allValues[value] = value; 
		}
		
		this.getStringAsXML = function(){
			var template = "<valueMap><key>{0}</key>{1}</valueMap>";
			var valuesTemplate = "<values>{0}</values>";
			var i, values = "", ret = "";
			for(i in this.allValues){
				values += format(valuesTemplate, this.allValues[i]);
			}
			escapeDuringFormat = false;
			ret = format(template, this.key, values);
			escapeDuringFormat = true;
			return ret;
		}
	}
	
	function getItemForDetailRecordKey(key, record){
		
		//add ORGNAMESPACE__ only if the key ends with __c
		if(key.indexOf("__c", key.length - "__c".length) !== -1)
			key = orgNameSpace + "__" + key;
		
		var length = record.length, k, ret = "";
		for(k = 0; k < length; k++){
			var fld = record[k];
			if(fld.key == key){
				ret = fld;
				break;
			}
		}
		return ret;
	}
	
	function SingleValueMap(key, value){
		this.key = key;
		this.value = value;
		
		this.getStringAsXML = function(){
			var template = "<valueMap><key>{0}</key><value>{1}</value></valueMap>";
			var ret = format(template, this.key, this.value);
			return ret;
		}
	}
	
	function format(){
		if(arguments.length == 0 ) return "";
		
		var formatted = arguments[0];	// first parameter is the string to be formated
		var splCharsReplacedStr;
		
	    for (var i = 1; i < arguments.length; i++) {
	        var regexp = new RegExp('\\{'+ (i - 1) +'\\}', 'gi');
	        
	        splCharsReplacedStr = arguments[i];
	        
	        if(escapeDuringFormat){
		        //check and update for any special characters.
		        splCharsReplacedStr = updateSpecialCharacter(arguments[i]);
	        }
	        
	        formatted = formatted.replace(regexp, splCharsReplacedStr);
	    }
	    return formatted;
	}	
	
	function updateSpecialCharacter(value)
	{
		if( value != undefined && value != null)
		{
			value = value.split("&").join("&amp;");
			value = value.split("<").join("&lt;");
		}	

		return value;
	}	
	
	$EXPR.getOrgNamespace = function(){
		var ons = getOrgNameSpace(orgNameSpace);
		// strip off the trailing /
		if(ons != "") ons = ons.substring(0, ons.length - 1);
		return ons;
	};
	
	
	function getOrgNameSpace(orgNameSpace){
		if(orgNameSpace != null && orgNameSpace != '') return orgNameSpace + "/";
		else return "";
	}

	function getTextDataFromXML(xmlData) {
 		var result = "";
 		if(xmlData && xmlData.firstChild){
		
			if(xmlData.firstChild.nodeValue){
				result = xmlData.firstChild.nodeValue;
			}
			else if(xmlData.firstChild.textContent && xmlData.normalize){
				xmlData.normalize(xmlData.firstChild);
				result = xmlData.firstChild.textContent;
			}

		}
		return result;
	}
	
	////////////////// END GET PRICE SPECIFIC CODING ///////////////
	
};	
	
})();

// end of file

