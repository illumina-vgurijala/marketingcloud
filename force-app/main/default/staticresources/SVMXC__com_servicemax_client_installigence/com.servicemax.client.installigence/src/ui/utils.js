/**
 * 
 */

(function(){
    
    var utilsImpl = SVMX.Package("com.servicemax.client.installigence.utils");

utilsImpl.init = function(){
    
   utilsImpl.Class("dependentPickList", com.servicemax.client.lib.api.Object, {
      
	   __constructor : function(config){ 
            this.__base(); 
            this.calcualteDependentPickList(config.param);
        },
        
        calcualteDependentPickList : function(objectDescribeResult){
        	// Add pickList value true, false for boolean fields
        	objectDescribeResult = this.__PopulatePickListValuesForBoolean(objectDescribeResult); 
        	var i, fields = objectDescribeResult.fields, l = fields.length, field, cname, cfield, masterPickListVsDependentPickList = [];
			for(i = 0; i < l; i++){
				field = fields[i];
				if(field.dependentPicklist){
					var masterDependentObj = {masterField : field.controllerName, dependentField : field.name};
        			masterPickListVsDependentPickList.push(masterDependentObj);
					cname = field.controllerName;
					cfield = this.__getField(cname, objectDescribeResult);
					if(cfield){
						this.__updateControllingPicklistWithDependents(cfield, field);
					}
				}
			}
			objectDescribeResult.masterPickListVsDependentPickList = masterPickListVsDependentPickList;
		},
        
        __PopulatePickListValuesForBoolean : function(objectDescribeResult){
        	var i, fields = objectDescribeResult.fields, l = fields.length;
        	for(i = 0; i < l; i++){
        		if(fields[i].type === "boolean"){
        			var falseValObj = {label:"false", value:"false"};
        			var trueValObj = {label:"true", value:"true"};
        			fields[i].picklistValues.push(falseValObj);
        			fields[i].picklistValues.push(trueValObj);
        		}
        	}
        	return objectDescribeResult;
        },
        
        __updateControllingPicklistWithDependents : function(cfield, dfield){
			var cvalues = cfield.picklistValues, i, l = cvalues.length, validForBytes,
				j, dvalues = dfield.picklistValues, c = dvalues.length, isValid,
				dependentPicklistArray, dependentPicklistInfo, k, s;

			for(i = 0; i < l; i++){

				if(!cvalues[i].dependendPicklist){ cvalues[i].dependendPicklist = []; }

				dependentPicklistArray = cvalues[i].dependendPicklist;

				for(j = 0; j < c; j++){

					validForBytes = dvalues[j].validFor; isValid = this.checkIfBytesAreValid(validForBytes, i);

					if(isValid){
						dependentPicklistInfo = null; s = dependentPicklistArray.length;
						for(k = 0; k < s; k++){
							if(dependentPicklistArray[k].fieldAPIName == dfield.name){
								dependentPicklistInfo = dependentPicklistArray[k];
								break;
							}
						}

						if(!dependentPicklistInfo){
							dependentPicklistInfo = {fieldAPIName : dfield.name, value : ""};
							dependentPicklistArray.push(dependentPicklistInfo);
						}

						dependentPicklistInfo.value += j + ";";
					}
				}

				// before proceeding with the next value, cleanup the trailing semi-colon
				for(j = 0; j < dependentPicklistArray.length; j++){
					var finalValue = dependentPicklistArray[j].value;
					if(finalValue.length > 0){
						if(SVMX.stringEndsWith(finalValue, ";")){
							finalValue = finalValue.substring(0, finalValue.length - 1);
						}
						dependentPicklistArray[j].value = finalValue;
					}
				}
			}
		},

		/**
         *  Overcome issues with SFDC SOAP API Issues and Bugs
         * @param inputBytes
         * @param parentIndex
         * @returns {boolean}
         */
         checkIfBytesAreValid : function(inputBytes, parentIndex){

            var bitsCount = inputBytes.length * 6, bitValuesArray = [], i, bitIndexInByte, bteIndex, b, biteValue;
            var base64IndexTable = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

            for (i = 0; i < bitsCount; i++) {

                // the byte to pull the bit from
                var remindValue = i % 6;
                var quoValue = (i - remindValue) / 6;

                if(quoValue < 0){
                    bteIndex = Math.ceil(quoValue);
                }else {bteIndex = Math.floor(quoValue)};

                bitIndexInByte = 5 - (i % 6);

                b = inputBytes[bteIndex], biteValue = base64IndexTable.indexOf(b);
                bitValuesArray.push( ((biteValue >> bitIndexInByte) & 1) );
            }

            return bitValuesArray[parentIndex] == 1;
        },

        __getField : function(name, describeResult){
        	var ret = null, fields = describeResult.fields, i, l = fields.length;
			for(i = 0; i < l; i++){
				if(fields[i].name == name){
					ret = fields[i];
					break;
				}
			}
			return ret;
		}
        
    }, {});
    
};

})();

// end of file