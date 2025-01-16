	//set the properties and actions of the remove dialog
	function promptDelete(){
		j$( "#dialog-confirm" ).dialog({
			resizable: false,
			modal: true,
			buttons: {
			"{!$Label.Delete}": function() {
					doDeleteRule();
					j$( this ).dialog( "close" );
				},
				Cancel: function() {
					j$( this ).dialog( "close" );
	
				}
	
			}
  	
  		});
	
	}

	function isDark( color ) {
	    var match = /rgb\((\d+).*?(\d+).*?(\d+)\)/.exec(color);
	    return parseFloat(match[1])
	         + parseFloat(match[2])
	         + parseFloat(match[3])
	           < (3 * (256 / 2)); // r+g+b should be less than half of max (3 * 256)
	}	
				
		function updateFieldList()
		{
			//alert('hello');
			doUpdateFieldList();
		}
		
		/**
		 * Initializes the call
		 */
		function initCall() {
			
			try {
				sforce.connection.sessionId = "{!$Api.Session_ID}"; //to avoid session timeout
				} catch(e) {
					ap_erroralert(ap_cERROR_UNKNOWN,e);
				}
				
		}
						
		function getDependentOptions (objName, ctrlFieldName, depFieldName) 
		{
			initCall();
			// Isolate the Describe info for the relevant fields
			var objDesc = sforce.connection.describeSObject(objName);
			var ctrlFieldDesc, depFieldDesc;
			var found = 0;
			for (var i=0; i<objDesc.fields.length; i++) {
				var f = objDesc.fields[i];
				if (f.name == ctrlFieldName) {
				ctrlFieldDesc = f;
				found++;
				} else if (f.name == depFieldName) {
				depFieldDesc = f;
				found++;
				}
				if (found==2) break;
			}
 
			// Set up return object
			var dependentOptions = {};
			var ctrlValues = ctrlFieldDesc.picklistValues;
			for (var i=0; i<ctrlValues.length; i++) {
			dependentOptions[ctrlValues[i].label] = [];
			}
 
			var base64 = new sforce.Base64Binary("");
			function testBit (validFor, pos) 
			{
				var byteToCheck = Math.floor(pos/8);
				var bit = 7 - (pos % 8);
				return ((Math.pow(2, bit) & validFor.charCodeAt(byteToCheck)) >> bit) == 1;
			}

			// For each dependent value, check whether it is valid for each controlling value
			var depValues = depFieldDesc.picklistValues;
			for (var i=0; i<depValues.length; i++) {
				var thisOption = depValues[i];
				var validForDec = base64.decode(thisOption.validFor);
				for (var ctrlValue=0; ctrlValue<ctrlValues.length; ctrlValue++) 
				{
					if (testBit(validForDec, ctrlValue)) 
					{
						dependentOptions[ctrlValues[ctrlValue].label].push(thisOption.label);
					}
				}
			}
			
			return dependentOptions;
		}
 
	 	function updateDependentPickListHandler(fieldNameGuidanceType)
	 	{
	 		var fnGuidanceType = document.getElementById(fieldNameGuidanceType);
			var OBJ_NAME = "{!ObjName}";
			var CTRL_FIELD_NAME = "{!CtrlFieldName}";
			var DEP_FIELD_NAME = "{!DepFieldName}";
			var options = getDependentOptions(OBJ_NAME, CTRL_FIELD_NAME, DEP_FIELD_NAME);
			//console.debug(options);
			var strOptions=JSON.stringify(options);
			doUpdateDependentPickListJs(strOptions,fnGuidanceType.value);
	 		
	 	}		
