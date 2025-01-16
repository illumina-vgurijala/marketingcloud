/**
 * @description This file acts as a bridge between the native Flex container and the browser.
 * 
 * @author Indresh MS
 */

(function(){
	if(window.$EXPR == undefined || window.$EXPR == null) window.$EXPR = {};
	
	/////////////////////////////// CORE ///////////////////////////
	var flexObj = null, sessionId = null, orgNameSpace = null;
	
	// set up the global parameters
	window.SVMXInitExpressionEngine = function(params){
		var app = params.app;
		if(typeof(app) == 'string')
			flexObj = getAppInstance(app);
		else
			flexObj = app;
		
		sessionId = params.sessionId;
		orgNameSpace = params.orgNameSpace;
	}
	
	/**
	 * The core API method to evaluate the JS expression
	 * 
	 * @param expression String the expression that needs to be evaluated
	 * @param context Object the contextual data that this expression works on
	 * @param callId String the unique identifier assigned to a particular call. This serves as a index to the call back function
	 */
	window.SVMXEvalExpression = function(expression, context, callId){
		// simulate the asynchronous nature by executing the rest of the method on a timeout
		setTimeout(function(){
			var callbackContext = {
					callId : callId,
					handler : function(result){
						
						// handleJSExpressionResult is a registered call back method within the "Flex" part of the bridge
						flexObj.handleJSExpressionResult(result, this.callId);		
					}
			};
			
			try{
			// trigger the evaluation
			$EXPR.executeExpression(
				expression, context, callbackContext.handler, callbackContext, true);
			}catch(e){
				$EXPR.Logger.error("Error while performing EVAL! Please check for syntax error in the JS snippet! =>" + e);
				callbackContext.handler(context);
			}
		}, 0);
	};
	
	// query the flash object instance based on the embedding broswer type
	function getAppInstance(name){
	    if (navigator.appName.indexOf ("Microsoft") !=-1) {
	        if(navigator.appVersion.indexOf("MSIE 9.0") != -1) {
				return document[name];
			}else{
				return window[name];
			}
	    } else {
	        return document[name];
	    }
	}
	
	/////////////////////////// END CORE ///////////////////////////
	
	////////////////////// GET PRICE SPECIFIC CODING ///////////////
	$EXPR.getOrgNamespace = function(){
		var ons = getOrgNameSpace(orgNameSpace);
		// strip off the trailing /
		if(ons != "") ons = ons.substring(0, ons.length - 1);
		return ons;
	};
	
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
		
		var sr = new SOAPRequest({orgNameSpace : orgNameSpace, sessionId : sessionId, 
		            endPointName : "INTF_WebServicesDef"});
		sr.invoke("PCAL_getPricingDefinition_WS", reqData, 
		    {handler : function(data){
		        var xml = $.parseXml(data, true);
		        var messageXML = xml.getFirstElementByTagName(
		            "message", "http://soap.sforce.com/schemas/class/"+ getOrgNameSpace(orgNameSpace) + "INTF_WebServicesDef");
		        var message = "";
		        
		        // FF Bug https://bugzilla.mozilla.org/show_bug.cgi?id=194231
		        if(messageXML.firstChild.textContent && messageXML.normalize) {
		        	messageXML.normalize(messageXML.firstChild);
		        	message = messageXML.firstChild.textContent;
		        } else if(messageXML.firstChild.nodeValue) {
		        	message = messageXML.firstChild.nodeValue;
		        }
		        // end FF bug
		        
		        var messageObj = $EXPR.toObject(message);
		        callback(messageObj);
		    }, error : function(){
		    	callback();
		    }, context : {}});
	}
	
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
			ret = format(template, this.key, values);
			return ret;
		}
	}
	
	function SingleValueMap(key, value){
		this.key = key;
		this.value = value;
		
		this.getStringAsXML = function(){
			var template = "<valueMap><key>{0}</key><value>{1}</value></valueMap>";
			ret = format(template, this.key, this.value);
			return ret;
		}
	}
	
	function format(){
		if(arguments.length == 0 ) return "";
		
		var formatted = arguments[0];	// first parameter is the string to be formated
		
	    for (var i = 1; i < arguments.length; i++) {
	        var regexp = new RegExp('\\{'+ (i - 1) +'\\}', 'gi');
	        formatted = formatted.replace(regexp, arguments[i]);
	    }
	    return formatted;
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
	
	function getOrgNameSpace(orgNameSpace){
		if(orgNameSpace != null && orgNameSpace != '') return orgNameSpace + "/";
		else return "";
	}
	////////////////// END GET PRICE SPECIFIC CODING ///////////////
})();