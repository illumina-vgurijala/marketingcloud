(function(){
	
/////////////////////////////////////////////////// START - PARTS FUNCTIONS ////////////////////////////////////////////
function processPartLine(record, pb, recordType, params){
	var linePriceField = getItemForDetailRecordKey("Total_Estimated_Price__c", record);
	var unitPriceField = getItemForDetailRecordKey("Estimated_Price2__c", record);
	var discountField = getItemForDetailRecordKey("Discount__c", record);
	var product = getItemForDetailRecordKey("Product__c", record);
	var up = getUnitPriceForPart(product, pb, recordType);
	var coverageField = getItemForDetailRecordKey("Covered__c", record);
	
	// update the fields
	unitPriceField.value = up;
	linePriceField.value = params.quantity * up;
	
	if(!applyServiceOffering(coverageField, params.so, "Parts_Discount_Covered__c", "Parts_Discount_Not_Covered__c"))
		applyWarranty(coverageField, params.warranty, "Material_Covered__c");
	
	var discount = getPartDiscount(product, pb);
	discountField.value = discount;
}

function getUnitPriceForPart(product, pb, recordType){
	var ret = -1, pbKey = null;
	// check if a special pricing is available as part of service contract
	ret = getUnitPriceFromPartsSpecialPricing(product, pb);
	if(ret == -1){
		
		// check if a service contract exists. Assumption is that if no contract is available, then
		// this item will NOT be available
		var recordTypeInfo = getFromPriceBookDefinition(pb, "RECORDTYPEINFO_PARTS_CONTRACT");
		if(recordTypeInfo){
			pbKey = getPriceBookIdForRecordType(recordType, recordTypeInfo);
			
			if(pbKey){
				ret = getUnitPriceFromPartsPricing(pbKey, pb, product);
			}
		}
	}

	if(ret == -1){ // no price book is available for this record type under service contract, switch to basic calculation
		ret = getBasicUnitPriceForPart(product, pb, recordType);
	}
	
	if(ret == -1){   // last resort => standard price book
		ret = getStandardUnitPriceForPart(product, pb, recordType);
	}
	
	if(ret == -1) ret = 0;
	
	return ret;
}

function getStandardUnitPriceForPart(product, pb, recordType){
	var recordTypeInfo = getFromPriceBookDefinition(pb, "RECORDTYPEINFO_PARTS_STANDARD"), ret = -1, pbKey = null;
	if(recordTypeInfo){
		if(recordTypeInfo){
			pbKey = getPriceBookIdForRecordType(recordType, recordTypeInfo);
		}
	}
	
	if(pbKey){
		ret = getUnitPriceFromPartsPricing(pbKey, pb, product);
	}
	return ret;
}

function getBasicUnitPriceForPart(product, pb, recordType){
	var recordTypeInfo = getFromPriceBookDefinition(pb, "RECORDTYPEINFO_PARTS"), ret = -1, pbKey = null;
	if(recordTypeInfo){
		if(recordTypeInfo){
			pbKey = getPriceBookIdForRecordType(recordType, recordTypeInfo);
		}
	}
	
	if(pbKey){
		ret = getUnitPriceFromPartsPricing(pbKey, pb, product);
	}
	return ret;
}

function getUnitPriceFromPartsSpecialPricing(product, pb){
	var specialPricing = getFromPriceBookDefinition(pb, "CONTRACT_SPECIALPARTSPRICING");
	if(specialPricing){
		var allSpecialPricing = specialPricing.data, l = allSpecialPricing.length, i, ret = -1;
		for(i = 0; i < l; i++){
			if( allSpecialPricing[i][getQualifiedFieldName("Product__c")] == product.value){
				ret = allSpecialPricing[i][getQualifiedFieldName("Price_Per_Unit__c")];
				$EXPR.Logger.info("A special price is available for PRODUCT => " + product.value);
				break;
			}
			
		}
	}
	return ret;
}

/**
 * @returns price if a matching pricebook is found, -1 otherwise
 */
function getUnitPriceFromPartsPricing(pbKey, pb, product){

	var partsPricingInfo = getFromPriceBookDefinition(pb, "PARTSPRICING");
	if(partsPricingInfo){
		var allProductsInfo = partsPricingInfo.data, l = allProductsInfo.length, i, ret = -1;
		for(i = 0; i < l; i++){
			
			if(pbKey == allProductsInfo[i].Pricebook2Id && allProductsInfo[i].Product2Id == product.value){
				ret = allProductsInfo[i].UnitPrice;
				break;
			}
		}
	}
	return ret;
}

function getPartDiscount(product, pb){
	var prodDefinitionInfo = getFromPriceBookDefinition(pb, "PRODUCT_DEFINITION"), prodDefinition = null, ret = 0;
	if(prodDefinitionInfo){
		var allProdDefinitionInfo = prodDefinitionInfo.data, i, l = allProdDefinitionInfo.length;
		for(i = 0; i < l; i++){
			if(allProdDefinitionInfo[i].Id == product.value){
				prodDefinition = allProdDefinitionInfo[i];
				break;
			}
		}
	}
	
	if(prodDefinition){
		var discountDefinitionInfo = getFromPriceBookDefinition(pb, "CONTRACT_PARTSDISCOUNT");
		if(discountDefinitionInfo){
			var allDiscountDefinitionInfo = discountDefinitionInfo.data, j, dlength = allDiscountDefinitionInfo.length, bfound = true;
			for(j = 0; j < dlength; j++){
				bfound = false;
				var discountDefinition = allDiscountDefinitionInfo[j];
				if(discountDefinition[getQualifiedFieldName("Product__c")] == prodDefinition['Id']){
					bfound = true;
				}else if(discountDefinition[getQualifiedFieldName("Product_Family__c")] == prodDefinition['Family']){
					bfound = true;
				}else if(discountDefinition[getQualifiedFieldName("Product_Line__c")] == prodDefinition[getQualifiedFieldName('Product_Family__c')]){
					bfound = true;
				}
				
				if(bfound){
					ret = discountDefinition[getQualifiedFieldName("Discount_Percentage__c")];
					break;
				}
			}
		}
	}
	return ret;
}
/////////////////////////////////////////////////// END - PARTS FUNCTIONS //////////////////////////////////////////////

/////////////////////////////////////////////////// START - LABOR FUNCTIONS ////////////////////////////////////////////
function processLaborLine( record, pb, recordType, params){
	var linePriceField = getItemForDetailRecordKey("Total_Estimated_Price__c", record);
	var unitPriceField = getItemForDetailRecordKey("Estimated_Price2__c", record);
	var activityType = getItemForDetailRecordKey("Activity_Type__c", record);
	var up = getUnitPriceForLabor(activityType, pb, recordType, record);
	var coverageField = getItemForDetailRecordKey("Covered__c", record);
	
	if(up == null){
		$EXPR.Logger.warn("No labor price found for activity =>" + activityType.value);
		return;
	}

	var rateType = up.rateType, rate = 0, duration, estimateDuration;
	var regularRate = up.regularRate;
	
	if(rateType == "Per Hour"){
		
		var startDate = getItemForDetailRecordKey("Start_Date_and_Time__c", record);
		var endDate = getItemForDetailRecordKey("End_Date_and_Time__c", record);
		var minDuration = up.minimumUnit;
		
		if(startDate == null || startDate.value == null || startDate.value == "" 
			|| endDate == null || endDate.value == null || endDate.value == ""){
			estimateDuration = params.quantity;
		}else{
			// calculate time
			startDate = getDateFromString(startDate.value);
			endDate = getDateFromString(endDate.value);
			var diff = (endDate - startDate) / (1000.0 * 60.0 * 60.0);
			if(diff > 0){
				estimateDuration = Math.ceil(diff);
			}else{
				estimateDuration = params.quantity;
			}
		}
		duration = (minDuration > estimateDuration) ? minDuration : estimateDuration;
		rate = duration * regularRate;
	}else{
		// flat rate
		rate = regularRate;
		linePriceField.value = rate;
		params.quantityField.value = 1;
		unitPriceField.value = rate;
	}
		
	// update the fields
	unitPriceField.value = regularRate;
	linePriceField.value = rate;
	
	if(!applyServiceOffering(coverageField, params.so, "Labor_Discount_Covered__c", "Labor_Discount_Not_Covered__c"))
		applyWarranty(coverageField, params.warranty, "Time_Covered__c");	
}

function getUnitPriceForLabor(activityType, pb, recordType, record){
	var ret = null, pbKey = null;

	// check if a special pricing is available as part of service contract
	ret = getUnitPriceFromLaborSpecialPricing(activityType, pb, record);
	if(ret == null){
		// Check if a service contract exists. Assumption is that if no contract is available, then
		// this item will NOT be available
		var recordTypeInfo = getFromPriceBookDefinition(pb, "RECORDTYPEINFO_LABOR_CONTRACT");
		if(recordTypeInfo){
			pbKey = getPriceBookIdForRecordType(recordType, recordTypeInfo);
			
			if(pbKey){
				ret = getUnitPriceFromLaborPricing(pbKey, pb, activityType, record);
			}
		}
	}
	
	// get the price book corresponding to record type and do the basic calculation
	if(ret == null)
		ret = getBasicUnitPriceForLabor(activityType, pb, recordType, record);
	
	return ret;
}

function getBasicUnitPriceForLabor(activityType, pb, recordType, record){
	var recordTypeInfo = getFromPriceBookDefinition(pb, "RECORDTYPEINFO_LABOR"), ret = null, pbKey = null;
	if(recordTypeInfo){
		pbKey = getPriceBookIdForRecordType(recordType, recordTypeInfo);
	}
	
	if(pbKey){
		ret = getUnitPriceFromLaborPricing(pbKey, pb, activityType, record);
	}
	return ret;
}

function getUnitPriceFromLaborSpecialPricing(activityType, pb, record){
	var specialPricing = getFromPriceBookDefinition(pb, "CONTRACT_SPECIALLABORPRICING");
	if(specialPricing){
		var allSpecialPricing = specialPricing.data, l = allSpecialPricing.length, i, ret = null;
		for(i = 0; i < l; i++){
			var pricing = allSpecialPricing[i];
			if( pricing[getQualifiedFieldName("Activity_Type__c")] == activityType.value){
				
				ret = extractLaborPricing(pricing, record);
				if(ret) break;
			}
		}
	}
	
	if(ret) $EXPR.Logger.info("A special price is available for LABOR => " + activityType.value);
	
	return ret;
}

function getUnitPriceFromLaborPricing(pbKey, pb, activityType, record){

	var laborPricingInfo = getFromPriceBookDefinition(pb, "LABORPRICING"), ret = null;
	if(laborPricingInfo){
		
		// get the price book corresponding to the product type
		var allLaborPricingInfo = laborPricingInfo.data, l = allLaborPricingInfo.length, i;
		for(i = 0; i < l; i++){
			var pricing = allLaborPricingInfo[i];
			if(pbKey == pricing[getQualifiedFieldName("Price_Book__c")] 
					&& pricing[getQualifiedFieldName("Activity_Type__c")] == activityType.value){
				
				ret = extractLaborPricing(pricing, record);
				if(ret) break;
			}
		}
	}
	return ret;
}

function extractLaborPricing(pricing, record){
	var isAssociatedWithProduct = !!pricing[getQualifiedFieldName("Activity_Product__c")], ret = null;
	if(isAssociatedWithProduct){
		var product = getItemForDetailRecordKey("Product__c", record);
		if(product && product.value && (pricing[getQualifiedFieldName("Product__c")] == product.value) ){
			ret = {
					rateType    : pricing[getQualifiedFieldName("Unit__c")],
					regularRate : pricing[getQualifiedFieldName("Regular_Rate__c")],
					minimumUnit : pricing[getQualifiedFieldName("Minimum_Labor__c")]
			};
		}
	}else{
		ret = {
				rateType    : pricing[getQualifiedFieldName("Unit__c")],
				regularRate : pricing[getQualifiedFieldName("Regular_Rate__c")],
				minimumUnit : pricing[getQualifiedFieldName("Minimum_Labor__c")]
		};
	}
	return ret;
}
/////////////////////////////////////////////////// END - LABOR FUNCTIONS //////////////////////////////////////////////

/////////////////////////////////////////////////// START - EXPENSE FUNCTIONS //////////////////////////////////////////
function processExpenseLine(record, pb, params){
	var expenseType = getItemForDetailRecordKey("Expense_Type__c", record);
	if(expenseType != "" && expenseType.value != null && expenseType.value != ""){
		var expenseInfo = getFromPriceBookDefinition(pb, "CONTRACT_EXPENSE"), expenseDetail = null;
		if(expenseInfo){
			var allExpensesInfo = expenseInfo.data, l = allExpensesInfo.length, i;
			for(i = 0; i < l; i++){
				if( allExpensesInfo[i][getQualifiedFieldName("Expense_Type__c")] == expenseType.value){
					expenseDetail = allExpensesInfo[i];
					break;
				}
			}
			
			if(expenseDetail != null){
				var linePriceField = getItemForDetailRecordKey("Total_Estimated_Price__c", record);
				var unitPriceField = getItemForDetailRecordKey("Estimated_Price2__c", record);
				var discountField = getItemForDetailRecordKey("Discount__c", record);
				var unitPriceField = getItemForDetailRecordKey("Estimated_Price2__c", record);
				
				var rate = expenseDetail[getQualifiedFieldName("Rate__c")];
				var rateType = expenseDetail[getQualifiedFieldName("Unit__c")];
				
				if(rateType == "Per Unit"){
					unitPriceField.value = rate;
					linePriceField.value = params.quantity * rate;
				}else if(rateType == "Flat Rate"){
					linePriceField.value = rate;
					params.quantityField.value = 1;
					unitPriceField.value = rate;
				}else if(rateType == "Actuals"){
					// TODO:
				}else if(rateType == "Discount"){
					// TODO:
				}else{
					//Markup TODO:
				}
				
				var coverageField = getItemForDetailRecordKey("Covered__c", record);
				if(!applyServiceOffering(coverageField, params.so, "Expense_Discount_Covered__c", "Expense_Discount_Not_Covered__c"))
					applyWarranty(coverageField, params.warranty, "Expenses_Covered__c");
			}
		}	
	}
}
/////////////////////////////////////////////////// END - EXPENSE FUNCTIONS ////////////////////////////////////////////

/////////////////////////////////////////////////// START - UTILITY FUNCTIONS //////////////////////////////////////////
function applyWarranty(coverageField, warranty, wField){
	if(warranty)
		coverageField.value = warranty[getQualifiedFieldName(wField)];
	else
		$EXPR.Logger.info("No Warranty found.");
}

function applyServiceOffering(coverageField, so, coveredField, notCoveredField){
	var applied = false, coverage = null, fld = null;
	if(so){
		if(so.isCovered){
			fld = coveredField;
		}else{
			fld = notCoveredField;
		}
		
		coverage = so[getQualifiedFieldName(fld)];
		if(coverage == null) 
			coverage = 0;
		
		coverageField.value = coverage;
		applied = true;
	}else
		$EXPR.Logger.info("No Service Offering found.");
	
	return applied;
}

function getPriceBookIdForRecordType(recordType, recordTypeInfo){
	var rtype2PriceBookMap = recordTypeInfo.valueMap, l = rtype2PriceBookMap.length, i, pbKey = null;
	for(i = 0; i < l; i++){
		var rtype2PriceBook = rtype2PriceBookMap[i];
		if(rtype2PriceBook.key == recordType.value){
			pbKey = rtype2PriceBook.value;
			break;
		}
	}
	
	return pbKey;
}

function getFromPriceBookDefinition(pb, key){
	var i, l = pb.length, ret = null;
	for(i = 0; i < l; i++){
		if(pb[i].key == key){
			ret = pb[i];
			break;
		}
	}
	return ret;
}

function getWarrantyDefinition(pb){
	
	var wDef = getFromPriceBookDefinition(pb, "WARRANTYDEFINITION"), ret = null;
	if(wDef) ret = wDef.data[0];
	
	return ret;
}

function getServiceOffering(pb){
	
	var so = getFromPriceBookDefinition(pb, "CONTRACT_SERVICEOFFERING"), ret = null;
	if(so) {
		ret = so.data[0];
		ret.isCovered = so.value == "COVERED" ? true : false;
	}
	
	return ret;
}

function getItemForDetailRecordKey(key, record){
	
	//add ORGNAMESPACE__ only if the key ends with __c
	if(key.indexOf("__c", key.length - "__c".length) !== -1){
		key = $EXPR.getOrgNamespace() + "__" + key;
	}
	
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

function getQualifiedFieldName(name){
	return $EXPR.getOrgNamespace() + "__" + name;
}

function getDateFromString(dateStr){
	var dt = dateStr.split(" ");
	var date = dt[0].split("-");
	var time = dt[1].split(":")
	return new Date(parseInt(date[0]), parseInt(date[1]), parseInt(date[2]), 
			parseInt(time[0]), parseInt(time[1]), parseInt(time[2]));
}

// hack to get around mixed ID lengths
function get15CharId(id){
	if(id && id.length == 18)
		id = id.substring(0, 15);
	
	return id;
}
/////////////////////////////////////////////////// END - UTILITY FUNCTIONS //////////////////////////////////////////

/////////////////////////////////////////////////// START - PRICING RULE FUNCTIONS ///////////////////////////////////
function getPricingRuleInfo(pb){
	var contractDefinitionInfo = getFromPriceBookDefinition(pb, "CONTRACT_DEFINITION"), ret  = null, pricingRuleInfo = null;
	if(contractDefinitionInfo){
		pricingRuleInfo = getFromPriceBookDefinition(pb, "CONTRACT_PRICINGRULES");
		if(pricingRuleInfo && pricingRuleInfo.data.length > 0){
			ret = pricingRuleInfo.data;
		}
	}
	return ret;
}

function executePricingRules(pricingRuleInfo, pb){
	debugger;
	/*var i, l = pricingRuleInfo.length, appliedPricingRule = null;
	for(i = 0; i < l; i++){
		var pricingRule = pricingRuleInfo[i];
		var expression = getExpression(pricingRule, pb);
		if(!expression){
			appliedPricingRule = pricingRule;
			break;
		}else{
			var expressionLines = expression.data, j, elength = expressionLines.length, exp = [];
			
			// TODO: Sort expression lines
			for(j = 0; j < elength; j++){
				var expressionLine = expressionLines[j];
				var field = expressionLine[getQualifiedFieldName("Field_Name__c")];
				var operator = expressionLine[getQualifiedFieldName("Operator__c")];
				var operand = expressionLine[getQualifiedFieldName("Operand__c")];
				
				if(operator == "starts"){
					exp[j] = $FORMAT("$STARTS_WITH({1}, \"{2}\")", field, operand);
				}else if(operator == "contains"){
					exp[j] = $FORMAT("$CONTAINS({1}, \"{2}\")", field, operand);
				}else if(operator == "eq"){
					exp[j] = $FORMAT("$EQUALS({1}, \"{2}\")", field, operand);
				}else if(operator == "ne"){
					exp[j] = $FORMAT("$NOT_EQUALS({1}, \"{2}\")", field, operand);
				}else if(operator == "gt"){
					exp[j] = $FORMAT("$GREATER_THAN({1}, \"{2}\")", field, operand);
				}else if(operator == "ge"){
					exp[j] = $FORMAT("$GREATER_THAN_OR_EQUAL_TO({1}, \"{2}\")", field, operand);
				}else if(operator == "lt"){
					exp[j] = $FORMAT("$LESS_THAN({1}, \"{2}\")", field, operand);
				}else if(operator == "le"){
					exp[j] = $FORMAT("$LESS_THAN_OR_EQUAL_TO({1}, \"{2}\")", field, operand);
				}
			}
			
			var advancedExpression = expresson.value;
			if(!advancedExpression || advancedExpression == null){
				advancedExpression = "(";
				for(k = 0; k < exp.length; k++){
					advancedExpression += k + " AND ";
				}
				
				// remove the last AND
				advancedExpressions = advancedExpressions.substring(0, advancedExpressions.length - 4);
			}
			
			// replace apex conditional operators with JS operators
			advancedExpressions = advancedExpressions.replace("AND", "&&").replace("OR", "||");
			var jsExpression = $FORMAT(advancedExpressions, exp[j]);
		}
	}
	return appliedPricingRule;*/
}

function getExpression(pricingRule, pb){
	var expressionId = pricingRule[getQualifiedFieldName("Named_Expression__c")], ret = null;
	if(expressionId){
		var expressionsInfo = getFromPriceBookDefinition(pb, "RULES"), allExpressions = expressionsInfo.valueMap, l = allExpressions.length, i;
		for(i = 0; i < l; i++){
			var expression = allExpressions[i];
			if(get15CharId(expression.key) == get15CharId(expressionId)){
				ret = expression;
				break;
			}
		}
	}
	return ret;
}
/////////////////////////////////////////////////// END - PRICING RULE FUNCTIONS /////////////////////////////////////

function applyPriceBook(context, pb){
	
	// check whether the work order has a pricing rule
	var pricingRuleInfo = getPricingRuleInfo(pb);
	if(pricingRuleInfo){
		executePricingRules(pricingRuleInfo, pb);
	}
	
	var i, detailRecords = context.detailRecords, l = detailRecords.length;
	var warranty = getWarrantyDefinition(pb);
	var so = getServiceOffering(pb);
	for(var i = 0; i < l; i++){
		var records = detailRecords[i].records, j, recordslength = records.length;
		for(j = 0; j < recordslength; j++){
			var record = records[j].targetRecordAsKeyValue, length = record.length, k;
			
			// do not process if the line item has this value set to true
			var usePriceBook = getItemForDetailRecordKey("Use_Price_From_Pricebook__c", record);
			if(usePriceBook != "" && usePriceBook.value != "true") continue;
			
			var lineType = getItemForDetailRecordKey("Line_Type__c", record);
			var recordType = getItemForDetailRecordKey("RecordTypeId", record);
			
			// calculate the quantity
			var quantityField = getItemForDetailRecordKey("Estimated_Quantity2__c", record);
			var quantity = 0;
			try{ 
				quantity = parseInt(quantityField.value); 
				if( isNaN(quantity) ) quantity = 0;
			} catch(e){ }
			// end quantity
			
			if(lineType.value == "Parts"){
				processPartLine(record, pb, recordType, {quantity : quantity, warranty : warranty, so : so});
			}else if (lineType.value == "Labor"){
				processLaborLine(record, pb, recordType, {quantity : quantity, warranty : warranty, quantityField : quantityField, so : so});
			}else if (lineType.value == "Expenses"){
				processExpenseLine(record, pb, {quantity : quantity, warranty : warranty, quantityField : quantityField, so : so});
			}else if(lineType.value == "Travel"){
				//applyWarranty(discountField, warranty, "Travel_Covered__c");
			}
				
		}
	}
}

/**
 * Snippet start.
 * @param context the transaction data context. Note that 'context' is a pre-defined variable, defined by the 
 *        expression engine. Do not overwrite!
 * @param callback function called back once the price book definition is obtained
 * @return the modified transaction context
 */
$EXPR.getPricingDefinition(context, function(pb){
	try{
		if(!pb){
			$EXPR.Logger.error("Could not get the price book definition!");
			$RETURN(context);
		}else{
			applyPriceBook(context, pb);
			$RETURN(context);
		}
	}catch(e){
		$EXPR.Logger.error("There was an error while performing get price => " + e);
		$RETURN(context);
	}
});
})();