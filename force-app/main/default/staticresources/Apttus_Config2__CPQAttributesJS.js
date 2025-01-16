/**************************************************************************************************************************************************************
 * Apttus Attributes JS file
 * @2015-2016 Apttus Inc. All rights reserved.
 * CPQAttributesJS
 *************************************************************************************************************************************************************/
/**
 * Process the following when an input changes:
 * <1> N-Matrix filter's
 * <2> Re-apply necessary Expressions and Rollups
 * <3> Process ABC rules
 * @param fieldName the fully qualified API Name of the changing input
 * @param isAttributeInput flag specifying if the input is an attribute value
 * @param contextIdentifier the primary identifier of the context line item
 * @param newValue the new value of the input 
 */
 j$ = jQuery.noConflict();
function processInputChange(fieldName, 
                            productMatricies,
                            cartLineSObjects,
                            fieldNameToElementId, 
                            isAttributeInput, 
                            contextIdentifier, 
                            newValue) {    
    //run matrix rules
    var modifiedByFilter  = filterAttributes(fieldName, productMatricies, fieldNameToElementId);
    //process expressions for modified by filter
    var expProcessedForContext = false;
    for(var modifiedName in modifiedByFilter) {        
        if(modifiedName == fieldName) { //running rules for context attribute
            expProcessedForContext = true;
        }

        var currentValue;
        var attributeElement = document.getElementById(fieldNameToElementId[modifiedName]);        
        if(j$(attributeElement).is('select')) {
          var selectedValues = [];
          for(var i=0, max=attributeElement.options.length; i < max; i++) {
            var option = attributeElement.options[i];
            if(option.selected
                && option.value != null
                && option.value != '') {
              selectedValues.push(option.text);
            }
          }

          currentValue = selectedValues.join(';');
        } else {
          currentValue = attributeElement.value;

        }

        processExpressions(fieldNameToElementId, cartLineSObjects, contextIdentifier);
    }

    //run expressions for context attribute
    if(expProcessedForContext != true) {
        if(isAttributeInput) {
            var qualfiedAPIName = j$.APTTUS.attributeValuePrefix+fieldName;
            var attributeElement = document.getElementById(fieldNameToElementId[qualfiedAPIName]);            
            if(j$(attributeElement).is('select')) {
              var selectedValues = [];
              for(var i=0, max=attributeElement.options.length; i < max; i++) {
                var option = attributeElement.options[i];
                if(option.selected
                  && option.value != null
                  && option.value != '') {
                  selectedValues.push(option.text);
                }
              }

              newValue = selectedValues.join(';');
            }

        }

        processExpressions(fieldNameToElementId, cartLineSObjects, contextIdentifier);
    }

    //run ABC rules
    processAttributeRules(contextIdentifier, fieldNameToElementId, cartLineSObjects);
}

/**
 * Filter the product attribute's by N-table value
 * @param fieldName the field name of the context attribute 
 * @return the fully qualified API name of modified atributes
 */
function filterAttributes(fieldName, productMatricies, fieldNameToElementId) {    
    var fieldAPIName = j$.APTTUS.attributeValuePrefix+fieldName;
    var matricies = productMatricies[fieldAPIName];
    var modifiedFields = {};
    if(typeof(matricies) !== 'undefined'
        && matricies != null) {
      for(var j=0; j < matricies.length; j++) {
          var items = [],
              index,
              i = 0,
              matrixInfo = matricies[j];
          for(var key in matrixInfo.columnInfo.columns) { //gather related inputs                
            if(matrixInfo.columnInfo.columns.hasOwnProperty(key)) {
              var fieldAPI = matrixInfo.columnInfo.columns[key];
              var fieldKey = j$.APTTUS.attributeValuePrefix+fieldAPI;
              var selectObject = j$(document.getElementById(fieldNameToElementId[fieldKey]));

              items.push(selectObject);
              if(fieldAPI == fieldName) {
                index = i;                    
              }

              modifiedFields[fieldKey] = fieldKey;
              i+=1;              
            }
          }

          var matrixFilter = new AptValueMatrixFilter(matrixInfo.hash);
          matrixFilter.filter(index, items, matrixInfo.hashKeys, matrixInfo.reverseKeys, false);

      }
    }

    return modifiedFields;
}

/**
 * Perform client side field updates and rollups
 * @param fieldAPIName the fully qualified field name
 * @param newValue the new value of the field
 * @param contextIdentifier the primary identifier of the context line item
 * @return true if info meets match conditions, false otherwise
 */
function processExpressions(fieldNameToElementId, cartLineSObjects, contextIdentifier) {
  var oldSObject = JSON.parse(JSON.stringify(cartLineSObjects[contextIdentifier]));
  var newSObject = cartLineSObjects[contextIdentifier];
  //set new value
  var newSObjects = {};
  var oldSObjects = {};
  for(fieldAPI in fieldNameToElementId) {
	  if(fieldNameToElementId.hasOwnProperty(fieldAPI)) {
		  var fieldPath = fieldAPI.split('.');
		  var curObject = newSObject;
		  var currObjectOld = oldSObject;
		  var i = 0, 
		      max = fieldPath.length -1;
		  for (; i < max; i++) {
		    if(typeof(curObject) === 'undefined'
		            || curObject == null) {
		        //console.log('Missing object, cannot process expressions');
		        return;
		    }
		    curObject = curObject[fieldPath[i]];
		    currObjectOld = currObjectOld[fieldPath[i]];
		  }

		  var attributeElement = document.getElementById(fieldNameToElementId[fieldAPI]);
		  var elemVal;
      if(j$(attributeElement).is('select')) {
        var selectedValues = [];
        for(var ii=0, max=attributeElement.options.length; ii < max; ii++) {
          var option = attributeElement.options[ii];
          if(option.selected
            && option.value != null
            && option.value != '') {
            selectedValues.push(option.text);
          }
        }

        elemVal = selectedValues.join(';');
      } else {
      	elemVal = j$(attributeElement).val();
      }

		  if(typeof(curObject[fieldPath[i]]) === 'number') {
		    curObject[fieldPath[i]] = parseFloat(elemVal);

		  } else {
		  	curObject[fieldPath[i]] = elemVal;
		  }

		  newSObjects[curObject.Id] = curObject;
  		oldSObjects[currObjectOld.Id] = currObjectOld;
		}
	}

  var itemsForUpdate = {};
  var expressionsForRecalculation = getExpressionsForRecalculation(newSObjects, 
                                                                   oldSObjects,
                                                                   newSObject.attributes.type,
                                                                   cartLineSObjects);
  for(expressionId in expressionsForRecalculation) {
    if(expressionsForRecalculation.hasOwnProperty(expressionId)) {
      var appliedExpressionSO = expressionsForRecalculation[expressionId];
      var expressionsForTarget = itemsForUpdate[appliedExpressionSO.targetPrimaryLineNumber];
      if(typeof(expressionsForTarget) === 'undefined' || 
          expressionsForTarget == null) {
        expressionsForTarget = {};
        itemsForUpdate[appliedExpressionSO.targetPrimaryLineNumber] = expressionsForTarget;
      }
      expressionsForTarget[appliedExpressionSO.Id] = appliedExpressionSO;
    }
  }

  //get lines items used to generate rollups
  var lineItemsForRollups = [];
  for(primaryLineId in cartLineSObjects) {
    if(primaryLineId != 0 &&
        cartLineSObjects.hasOwnProperty(primaryLineId)) {
      lineItemsForRollups.push(cartLineSObjects[primaryLineId]);
    }
  }

  //re-evaluate expressions
  evalCart(itemsForUpdate, cartLineSObjects, lineItemsForRollups, j$.APTTUS.nsPrefix);
  //update displayed attributes
  var expressionsForTarget = itemsForUpdate[contextIdentifier];      
  if(typeof(expressionsForTarget) !== 'undefined'
      && expressionsForTarget != null) {
    for(var expressionSOId in expressionsForTarget) {
      if(expressionsForTarget.hasOwnProperty(expressionSOId)) {
        var appliedExpressionSO = expressionsForTarget[expressionSOId];
        if(appliedExpressionSO.isFieldUpdate) {
          var fieldAPI = appliedExpressionSO.updateField,
              curObject = cartLineSObjects[contextIdentifier], 
              i = 0,
              path = fieldAPI.split('.'), 
              max = path.length -1;                  
          for (; i < max; i++) {
            curObject = curObject[path[i]];

          }

          var attributeElement = j$(document.getElementById(fieldNameToElementId[fieldAPI]));
          var attrMultiSelectLeft = document.getElementById(fieldNameToElementId[fieldAPI]+'_unselected');
          var attrMultiSelectRight = document.getElementById(fieldNameToElementId[fieldAPI]+'_selected');
          if(typeof(attributeElement) !== 'undefined'
              && attributeElement != null) {                
            //set value
            setValue(attributeElement, attrMultiSelectLeft, attrMultiSelectRight, curObject[path[i]]);
          }
        }
      }
    }
  }
}

/**
 * Process the ABC rule infos for speficied line
 * @param contextIdentifier the primary identifier of the context line item
 */
function processAttributeRules(contextIdentifier, attributeIdByField, cartLineSObjects) {
  var lineSO = cartLineSObjects[contextIdentifier];
  var hasRequiredValue = {};
  var invalidConstraint = {};  
  //set cart lines for evaluation
  evalCart.setCartLines(cartLineSObjects);

  //iterate through all rules...
  for(var ruleId in j$.APTTUS.attributeRules) {    
    if(j$.APTTUS.attributeRules.hasOwnProperty(ruleId)) {
      var ruleCondition = j$.APTTUS.attributeRules[ruleId];
      var meetsRuleCondition = getMeetsRuleConditions(ruleCondition.conditionExpression, [lineSO]);

      for(var index=0; index < ruleCondition.actions.length; index++) {
        var ruleInfo = ruleCondition.actions[index];
        var qualifiedFieldName = j$.APTTUS.attributeValuePrefix+ruleInfo.fieldAPI;
        var attributeElementId = attributeIdByField[qualifiedFieldName];      
        var attributeElement = document.getElementById(attributeElementId);
        var attrMultiSelectLeft = document.getElementById(attributeElementId+'_unselected');
        var attrMultiSelectRight = document.getElementById(attributeElementId+'_selected');
        if(attributeElement == null) {
          continue;

        }
        
        //Constrain the picklist values
        if(ruleInfo.isConstraintAction) {
          var meetsCondition = meetsRuleCondition && getMeetsRuleConditions(ruleInfo.conditionExpression, [lineSO]);
          if(meetsCondition) {
            if(j$(attributeElement).is('select')) {
              var availableValues = [];
              if(ruleInfo.valueExpression != null) {              
                availableValues = _eval(ruleInfo.valueExpression, [lineSO]).result.split(';');
              }

              //constrain values
              constrainPicklist(attributeElement, 
                                attrMultiSelectLeft,
                                attrMultiSelectRight,
                                availableValues);
            }

            invalidConstraint[qualifiedFieldName] = false;
          } else {
            if(typeof(invalidConstraint[qualifiedFieldName]) === 'undefined') {
              invalidConstraint[qualifiedFieldName] = true;
            } else {
              invalidConstraint[qualifiedFieldName] = invalidConstraint[qualifiedFieldName] && true;
            }
          }
        //Default value by expression
        } else if(ruleInfo.isDefaultAction) {
          if(typeof(attributeElement) !== 'undefined') {
            var hasValue = ruleInfo.defaultedByExpression == true && ruleInfo.autoUpdateDefault == false;
            if(meetsRuleCondition && 
                  !hasValue) {
              if(j$(attributeElement).is('select')) {                         
                for(var i=0, max=attributeElement.options.length; i < max; i++) {
                  var option = attributeElement.options[i];
                  if(option.value != null && option.value != ''
                        && option.selected) {
                    hasValue = true;
                  }
                }
              } else {
                hasValue = attributeElement.value != null && attributeElement.value != '';              
              }
            }

            if(meetsRuleCondition &&
                !hasValue) { //if no value, test condition and set new value
              var meetsCondition = getMeetsRuleConditions(ruleInfo.conditionExpression, [lineSO]);                
              if(meetsCondition && 
                  ruleInfo.valueExpression != null) {//set default value
                  setValue(attributeElement, 
                           attrMultiSelectLeft,
                           attrMultiSelectRight,
                           _eval(ruleInfo.valueExpression, [lineSO]).result);
                //bypass future updates
                ruleInfo.defaultedByExpression = true;
                //default set by rule, no lone required
                hasRequiredValue[qualifiedFieldName] = false;
              }            
            }
          }                        
        //Make attribute hidden
        } else if(ruleInfo.isHiddenAction) {
          var attributeTR = j$(attributeElement).closest('tr');
          var preceedingTR = attributeTR.prev('tr');
          attributeTR.show();
          j$(attributeElement).attr('hiddenByRule', false);
          //preceedingTR.show();

          var meetsCondition = getMeetsRuleConditions(ruleInfo.conditionExpression, [lineSO]);
          if(meetsRuleCondition &&
                meetsCondition) {  
              //check against value expression (may have addition conditions)
              meetsCondition = getMeetsRuleConditions(ruleInfo.valueExpression, [lineSO]);
            if(meetsCondition) {
              attributeTR.hide();
              j$(attributeElement).attr('hiddenByRule', true);
              //preceedingTR.hide();           
            }
          }
        //Make attribute read only
        } else if(ruleInfo.isReadOnlyAction) {
          var meetsCondition = getMeetsRuleConditions(ruleInfo.conditionExpression, [lineSO]);
          var isMultiSelect = attrMultiSelectRight != null;

          var leftArrow = document.getElementById(attributeElementId+'_left_arrow');
          var rightArrow = document.getElementById(attributeElementId+'_right_arrow');        
          //restore editability
          j$(attributeElement).removeClass('readOnlyIput');
          //re-enable column clicks
          var nearestColumn = j$(attributeElement).closest('td');
          if(nearestColumn.attr('onClick')) {
            nearestColumn.attr('onClick', nearestColumn.attr('onClick').replace(new RegExp('.*replaceThis; ', 'g'),''));
            if(nearestColumn.attr('onClick').trim() === '') {
              nearestColumn.removeAttr('onClick'); //remove the click event
            }
          }

          if(!isMultiSelect) {
            j$(attributeElement).removeAttr('disabled');
            j$(attributeElement).addClass('readOnlyIput');
          } else {
            j$(leftArrow).css('opacity', 1);
            j$(rightArrow).css('opacity', 1);          
            j$(attrMultiSelectLeft).removeAttr('disabled');
            j$(attrMultiSelectRight).removeAttr('disabled');            
          }

          if(meetsRuleCondition &&
              meetsCondition) {              
              if(meetsCondition) {
                if(!isMultiSelect) {                  
                  j$(attributeElement).attr('disabled', true);
                } else {
                  j$(leftArrow).css('opacity', 0.5);
                  j$(rightArrow).css('opacity', 0.5);
                  
                  j$(attrMultiSelectLeft).attr('disabled', true);
                  j$(attrMultiSelectRight).attr('disabled', true);
                }

                var onClickStr = 'return false; replaceThis; '                
                var nearestColumn = j$(attributeElement).closest('td');
                var existingClickString = nearestColumn.attr('onClick') || '';
                nearestColumn.attr('onClick', onClickStr + existingClickString);
              }              
          }
        //Make attribute required
        } else if(ruleInfo.isRequiredAction) {        
          var isMultiSelect = attrMultiSelectRight != null;
          var requiredElement = isMultiSelect ? attrMultiSelectLeft : attributeElement;
          var requiredBlock = j$(requiredElement).prev('.requiredBlock');
          requiredBlock.hide();

          var meetsCondition = getMeetsRuleConditions(ruleInfo.conditionExpression, [lineSO]);
          if(meetsRuleCondition &&
                meetsCondition) {
            if(requiredBlock.length > 0) {
              requiredBlock.show();

            } else { //create required block            
              //update display

              if(j$(requiredElement).parent().hasClass('apt-select-wrap')) {
                j$(requiredElement).parent().addClass('requiredInput');
                j$(requiredElement).parent().prepend('<div class="requiredBlock" style="background-color: #c00;">');
              } else {              
                j$(requiredElement).wrap('<div class="requiredInput">').parent().prepend('<div class="requiredBlock" style="background-color: #c00;">');
              }
            }

            //flag requirements, for button/link disabling
            if(j$(requiredElement).is('select')) { 
              if(isMultiSelect) {
                hasRequiredValue[qualifiedFieldName] = attrMultiSelectRight.options.length == 0;
              } else {
                hasRequiredValue[qualifiedFieldName] = requiredElement.value == null || requiredElement.value == '';
              }
            } else {
              if(j$(requiredElement).val() == null ||
                  j$(requiredElement).val().trim() == '') {
                hasRequiredValue[qualifiedFieldName] = true;
              }
            }
          }
        }
      }
    }
    
    //if no longer constrained, restore values
    for(fieldAPIName in invalidConstraint) {
      if(invalidConstraint.hasOwnProperty(fieldAPIName)) {
        if(invalidConstraint[fieldAPIName] == true) {
          var attributeElementId = attributeIdByField[fieldAPIName];
          var attributeElement = document.getElementById(attributeElementId);
          if(j$(attributeElement).is('select')) {
            var attrMultiSelectLeft = document.getElementById(attributeElementId+'_unselected');
            var attrMultiSelectRight = document.getElementById(attributeElementId+'_selected');
            //constrain the attribute
            constrainPicklist(attributeElement, 
                              attrMultiSelectLeft,
                              attrMultiSelectRight,
                              null);
          }
        }
      }
    }
  }

  //double check if has required value since default could have been applied
  var disableInputs = false;
  for(fieldAPIName in hasRequiredValue) {
    if(hasRequiredValue.hasOwnProperty(fieldAPIName)) {
      if(hasRequiredValue[fieldAPIName] == true) {
        disableInputs = true;
      }
    }
  }

  //disable buttons if required actions
  toggleButtonsAndLinks(disableInputs);
}

/**
 * Constrain the picklist values
 * @param selectElement the main select element
 * @param multiSelectLeft the left hand select element (multi-select picklist)
 * @param multiSelectRight the right hand select element (multi-select picklist)
 * @param availableValues array of avaialble values
 */ 
function constrainPicklist(selectElement, multiSelectLeft, multiSelectRight, availableValues) { 
  var valuesSet = {}; //build unique set of available value
  var availableCount = 0;
  var removeConstraints = availableValues == null;
  if(!removeConstraints) {
    for(var i=0; i < availableValues.length; i++) {
      valuesSet[availableValues[i]] = availableValues[i];
      availableCount += 1;
    }
  }

  if(typeof(multiSelectRight) !== 'undefined' 
      && multiSelectRight != null) {
    if(selectElement.options != null 
        && selectElement.options.length > 0) {
      var reSortLeft = false;
      for(var i=0, max = selectElement.options.length; i < max; i++) {
        var option = selectElement.options[i];
        var optionValue = option.value;
        if(optionValue != null && optionValue != '') {
          if(removeConstraints || 
              typeof(valuesSet[optionValue]) !== 'undefined') { //re-enable option
          	j$(multiSelectLeft).find('option[value="'+i+'"]').removeAttr('disabled');
	          if(availableCount === 1) {
	          	if(!option.selected) {
	          		j$(multiSelectLeft).find('option[value="'+i+'"]').appendTo(j$(multiSelectRight));
	          			//set re-sort flag
              		reSortLeft = true;
	          	}
	          }
          } else {
            if(!option.selected) {
              j$(multiSelectLeft).find('option[value="'+i+'"]').attr('disabled', true);
            } else { //de-select invalid option 
              option.selected = false;
              //move from right hand list back to left and disable it
              j$(multiSelectRight).find('option[value="'+i+'"]').attr('disabled', true)
                                                                .appendTo(j$(multiSelectLeft));
              //set re-sort flag
              reSortLeft = true;
            }
          }
        }
      }

      if(reSortLeft) { //sort left hand list
        j$(multiSelectLeft).append(j$(multiSelectLeft).find('option').sort(function(left, right) {
          return j$(left).val() < j$(right).val() ? -1 : 1;
        }));
      }       
    } 
  } else {
    for(var i=0, max = selectElement.options.length; i < max; i++) {
      var option = selectElement.options[i];
      var optionValue = option.value;
      if(optionValue != null && optionValue != '') {        
        if(removeConstraints ||
            typeof(valuesSet[optionValue]) !== 'undefined') { //re-enable option
          if(availableCount === 1) { //only available option, select it
          	option.selected = true;
          }
          j$(option).show();
        } else {
          j$(option).hide();
          //remove selection
          option.selected = false;
        }
      }          
    }
  }
}

/**
 * Get the applied expression infos ordered by their source ids
 * @return infos ordered by source object id
 */
function getAppliedExpressionsBySourceId() {
  var appliedInfoBySourceId;
  if(typeof(j$.APTTUS.appliedExpressionInfos) !== 'undefined'
        && j$.APTTUS.appliedExpressionInfos != null) {        
    appliedInfoBySourceId = {};
    for(var i =0; i < j$.APTTUS.appliedExpressionInfos.length; i++) {
      var info = j$.APTTUS.appliedExpressionInfos[i];
      if(typeof(info.sourceIds) !== 'undefined'
            && info.sourceIds != null) {
        var sourceIds = JSON.parse(info.sourceIds);
        for(var j=0; j < sourceIds.length; j++) {
          var infosForSource = appliedInfoBySourceId[sourceIds[j]];            
          if(typeof(infosForSource) == 'undefined') {
            infosForSource = {};
            appliedInfoBySourceId[sourceIds[j]] = infosForSource;
          }

          infosForSource[info.Id] = info;
        }
      }
    }
  }

  return appliedInfoBySourceId;
}

/**
 * Check if the ABC info meets the rule conditions
 * Note: missing/not specified match condition is treated as "true"
 * @param expressionInfo the ABC rule info
 * @param contextSObjects array of objects for evaluation
 * @return true if info meets match conditions, false otherwise
 */
function getMeetsRuleConditions(expressionInfo, contextSObjects) {
    var meetsCondition = true;
    if (expressionInfo != null) {
      var translated = 
        expressionInfo.replace(/(\$([.$A-Za-z0-9_]*|(\[.*\]))*)/g, function(match, p1, p2, p3, offset, originalString) {
          if (offset == 0) {
            return '{' + match + '}';
          } else if (originalString[offset -1] != '{' 
              && originalString[offset + match.length + 1] != '}') {
            return '{' + match + '}';

          }

          return match;
        });

        meetsCondition = _eval(translated, contextSObjects).result;
    }

    return meetsCondition;
}

/**
 * Get the object corresponding to field name
 * @param contextSO the "starting" sObject
 * @param fieldAPIName the fully qualified field API name
 * @return the object specified by fieldName
 */
function getObjectFromField(contextSO, fieldAPIName) {
  //set new value
  var path = fieldAPIName.split('.');
  var curObject = contextSO;
  for (var i = 0, max = path.length -1; i < max; i++) {
    if(typeof(curObject) !== 'undefined'
          && curObject != null) {
      curObject = curObject[path[i]];
    }        
  }

  return curObject;

}

/**
 * Get the value from sourceField
 * @param object the sObject
 * @param sourceField the fully qualified field API name
 * @return the value specified by sourceField
 */
function getValue(object, sourceField) {     
  var path = sourceField.split('.');
  var curObject = object;
  for (var i = 0; i < path.length; i++) {
    curObject = curObject[path[i]];
  }

  return curObject;

}

/**
 * Check if the source object has changed
 * @param newObject the object
 * @param oldObject the old object
 * @param expressionInfo the expression details
 * @return the object specified by fieldName
 */
function isSourceChanged(newObject, oldObject, expressionInfo) {
  var isSourceChanged = false;

  var sourceFields;
  if(typeof(expressionInfo.sourceFields) !== 'undefined'
        && expressionInfo.sourceFields != null) {        
    sourceFields = JSON.parse(expressionInfo.sourceFields)[newObject.Id];
  }

  if(typeof(sourceFields) !== 'undefined' && sourceFields != null) {      
    for(var i=0; i < sourceFields.length; i++) {
      if(getValue(oldObject, sourceFields[i]) != getValue(newObject, sourceFields[i])) {
        isSourceChanged = true;
        break; // prevent unecessary looping
      }
    }
  }

  return isSourceChanged;
}

/**
 * Get the expressions which need to be re-evaluated
 * @param newObject the new object
 * @param oldObject the old object
 * @param sObjectType the sObject type
 * @param cartLineSObjects all cart lines
 * @return the expressions which need recalculation
 */ 
function getExpressionsForRecalculation(newSObjects, oldSObjects, sObjectType, cartLineSObjects) { 
  var expressionsForRecalculation = {};
  for(sObjectId in oldSObjects) {
    if(oldSObjects.hasOwnProperty(sObjectId)) {         
      var newSObject = newSObjects[sObjectId];
      var infosBySourceId = getAppliedExpressionsBySourceId();
      var sourceExpressionInfos = infosBySourceId[sObjectId];          
      if(typeof(sourceExpressionInfos) !== 'undefined' &&
            sourceExpressionInfos != null) {            
        var oldSObject = oldSObjects[sObjectId];
        for(infoId in sourceExpressionInfos) {
          if(sourceExpressionInfos.hasOwnProperty(infoId)) {
            var appliedExpressionInfo = sourceExpressionInfos[infoId];                
            if(!appliedExpressionInfo.locked) {
              if(isSourceChanged(newSObject, oldSObject, appliedExpressionInfo)) {
                expressionsForRecalculation[appliedExpressionInfo.Id] = appliedExpressionInfo;                    
              }
            }
          }
        }
      }
    }
  }

  //get related re-calculations
  var modifiedByExpressions = getModifiedByExpression(expressionsForRecalculation, cartLineSObjects);
  for(var infoId in modifiedByExpressions) {
    if(modifiedByExpressions.hasOwnProperty(infoId)) {          
      expressionsForRecalculation[infoId] = modifiedByExpressions[infoId];

    }
  }

  var hasPendingCalculations = false;
  for(var appliedInfoId in expressionsForRecalculation) {
    if(expressionsForRecalculation.hasOwnProperty(appliedInfoId)) {
      hasPendingCalculations = true;
      break;
    }
  }

  //if there are exressions for re-calculation, 
  //re calculate rollups and field updates which use rollups
  if(hasPendingCalculations) {
    for(var i =0; i < j$.APTTUS.appliedExpressionInfos.length; i++) {
      var info = j$.APTTUS.appliedExpressionInfos[i];
      if(info.isRollup
            || info.usesRollup) {
        expressionsForRecalculation[info.Id] = info;

      }
    }
  }

  return expressionsForRecalculation;
}

/**
 * Get the expressions which are dependent on specified infos (recurssive)
 * @param infos the new object
 * @param modified the map dependent infos (initially empty) 
 * @return expressions which are dependent on those specified by infos
 */ 
function getModifiedByExpression(infos, cartLineSObjects,  modified) {
  modified = modified || {};
  var infosBySourceId = getAppliedExpressionsBySourceId();
  for(infoId in infos) {
    if(infos.hasOwnProperty(infoId)) {
      var appliedInfo = infos[infoId];
      if(appliedInfo.isFieldUpdate) {//field updates are only performed on line items
        var targetSO =  getObjectFromField(cartLineSObjects[appliedInfo.targetPrimaryLineNumber], 
                                           appliedInfo.updateField);
        var sourceExpressionInfos = infosBySourceId[targetSO.Id];
        if(typeof(sourceExpressionInfos) !== 'undefined' &&
          sourceExpressionInfos != null) {
          for(infoId in sourceExpressionInfos) {
            if(sourceExpressionInfos.hasOwnProperty(infoId)) {
              var sourceInfo = sourceExpressionInfos[infoId];                
              if(!sourceInfo.locked) {
                var sourceFields = JSON.parse(sourceInfo.sourceFields)[targetSO.Id];
                for(var i=0; i < sourceFields.length; i++) {
                  var sourceField = sourceFields[i];
                  var appliedSourceField = appliedInfo.updateField.split('.');                      
                  if(sourceField == appliedSourceField[appliedSourceField.length -1]) {
                    modified[sourceInfo.Id] = sourceInfo;
                    if(sourceInfo.isFieldUpdate) { //grab any additional updates
                      var infoMap = {};
                      infoMap[sourceInfo.Id] = sourceInfo;
                      var additional = getModifiedByExpression(infoMap, cartLineSObjects, modified);
                      for(additionalInfoId in additional) {
                        if(additional.hasOwnProperty(additionalInfoId)) {
                          modified[additionalInfoId] = additional[additionalInfoId];
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  return modified;

}

/**
 * Set the value for the attribute input
 * @param item the context input
 * @param multiSelectLeft the left side select element (multi-select picklist)
 * @param multiSelectRight the right side select element (multi-select picklist)
 * @param value the new value 
 */ 
function setValue(item, multiSelectLeft, multiSelectRight, value) {
    var itemSO = j$(item);    
    if(!itemSO.is('select')) {      
      itemSO.val(value);
    } else {
      if(multiSelectRight != null) {
        var valueArray = value.split(';');
        var valueSet = {};
        for(var i=0, max=valueArray.length; i < max; i++) {
          valueSet[valueArray[i]] = valueArray[i];
        }

        var resortRight = false;
        for(var i=0, max=item.options.length; i < max; i++) {
          var option = item.options[i];
          if(option.value != null
                && option.value != '') {
            if(typeof(valueSet[option.value]) !== 'undefined') { //move from left side to right side
              var leftOptionItem = j$(multiSelectLeft).find('option[value="'+i+'"]');
              if(leftOptionItem.length > 0) {
                leftOptionItem.appendTo(j$(multiSelectRight));
                resortRight = true;
              }

              //select the option
              option.selected = true;
            }
          }
        }

        //re-sort
        if(resortRight) {
          j$(multiSelectRight).append(j$(multiSelectRight).find('option').sort(function(left, right) {
            return j$(left).val() < j$(right).val() ? -1 : 1;
          }));
        }
      } else {
        itemSO.val(value);        
      }
    }
}

function AptValueMatrixFilter(data) {
    this.init(data);

}

AptValueMatrixFilter.prototype = {
    init: function(data) {
        this.data = new BitString( data );        
        this.dataLength = this.data.length;
        //fetch pad count, from end of data (3 bits)
        this.padCount = this.data.get(this.dataLength - 3, 3);
        //get node count (20 bits ending at length - 3 bits)
        this.nodeCount = this.data.get(this.dataLength - 23, 20);
        //get directory size (20 bits ending at length - 23 bits)
        this.directorySize = this.data.get(this.dataLength - 43, 20);
        //calculate directory start index
        this.directoryStart = this.directorySize <= 0 ? 0 : this.dataLength - this.padCount - this.directorySize - 43;
        //calculate the label sizes (4 bits, after trie bit vector)
        this.labelSize = this.data.get(this.nodeCount * 2 + 1, 4);
        // The position of the first bit of the data in 0th node.
        this.letterStart = this.nodeCount * 2 + 5;
        // set L2 directory size
        this.l2Size = 15;
        // set L1 directory size
        this.l1Size = this.l2Size*this.l2Size;
        // calculate L1 bits width
        this.l1Bits = Math.floor(Math.log(this.nodeCount * 2 + 1) / Math.log(2)) + 1;
        // calculate L2 bits width
        this.l2Bits = Math.floor(Math.log(this.l1Size) / Math.log(2)) + 1;
        // calculate bits in directory entry
        this.sectionBits = (this.l1Size / this.l2Size - 1) * this.l2Bits + this.l1Bits;
    },

    /**
      Retrieve the root node. You can use this node to obtain all of the other
      nodes in the trie.
      */
    getRoot: function() {
        return this.getNodeByIndex(0);

    },

    /**
       Retrieve the FrozenTrieNode of the trie, given its index in level-order.
      */
    getNodeByIndex: function(index, parentNode) {        
        // retrieve the node letter.   
        var letterOffset = this.letterStart + ((index-1) * this.labelSize);    
        var letter = this.data.get(letterOffset, this.labelSize);
        // get index of first child
        var firstChild = this.select(0, index+1) - index;
        // Nodes are encoded in level order, so child of first node
        // must be past the 0 in this position
        var childOfNextNode = this.select( 0, index + 2) - index - 1;

        return new AptValueMatrixNode(this, index, letter, firstChild, parentNode, childOfNextNode - firstChild);
    },

    /**
      Returns the position of the y'th 0 or 1 bit, depending on the "which"
      parameter.
      */
    select: function(which, y) {
        var high = this.nodeCount * 2 + 1;        
        var low = -1;
        var val = -1;

        while (high - low > 1) {
            var probe = (high + low) / 2 | 0;            
            var rank = this.rank(which, probe);

            if (rank === y) {
                // We have to continue searching after we have found it,
                // because we want the _first_ occurrence.
                val = probe;
                high = probe;
            } else if (rank < y) {
                low = probe;
            } else {
                high = probe;
            }
        }

        return val;
    },

    /**
      Returns the number of 1 or 0 bits (depending on the "which" parameter) to
      to and including position x.
      */
    rank: function(which, x) {
        if ( which === 0 ) {
            return x - this.rank(1, x) + 1;
        }

        var rank = 0;              
        var o = x;
        var sectionPos = 0;

        if (o >= this.l1Size ) {
            sectionPos = (o / this.l1Size | 0) * this.sectionBits;
            rank = this.data.get(this.directoryStart + (sectionPos - this.l1Bits), this.l1Bits);
            //calculate bits which have not been summarized
            o = o % this.l1Size;            
        }

        if (o >= this.l2Size) {
            sectionPos += (o / this.l2Size | 0) * this.l2Bits;
            rank += this.data.get(this.directoryStart + (sectionPos - this.l2Bits), this.l2Bits);
        }

        rank += this.data.count(x - x % this.l2Size, x % this.l2Size + 1);

        return rank;
    },

    /**
      Look-up a word in the trie.
      */
    filter: function(position, items, hashKeys, reverseKeys, reset) {
        var level = 0;
        var nodesForLevel = this.getRoot().getChildren();
        while(level < items.length && 
                nodesForLevel.length > 0) {           
            var levelSize = nodesForLevel.length;

            //var nodeKey = items[level].find(':selected').get(0).getAttribute('key');
            var hasNodeKey = false;            
            var nodeKeys = {};// = jQuery(items[level]).find(':selected').get(0);
            var levelInput = items[level].get(0);
            if(typeof(levelInput) === 'undefined') {
              return; //missing columns

            }

            var inputId = jQuery(levelInput).attr('id');                      
            var isMultiSelect = document.getElementById(inputId+'_selected') != null;

            if(!jQuery(levelInput).is('select')) {
              var nodeKey = reverseKeys[levelInput.value];              
              //if we find a key, store it
              if(typeof(nodeKey) != 'undefined'
                      && nodeKey != null) {
                nodeKeys[nodeKey] = nodeKey;
                hasNodeKey = true;
              }
            } else {
              
              for(var i=0, max=levelInput.options.length; i < max; i++) {
                var option = levelInput.options[i];
                if(option.selected
                      && option.value != null
                      && option.value != '') {
                  if(isMultiSelect) {
                    hasNodeKey = true;
                    nodeKeys[option.value] = option.value;

                  }  else { //regular picklist use node key
                    var nodeKey = option.getAttribute('key');
                    if(typeof(nodeKey) == 'undefined'
                        || nodeKey == null) {
                      nodeKey = reverseKeys[option.value];
                    }

                    //store node key
                    if(typeof(nodeKey) != 'undefined'
                            && nodeKey != null) {                      
                      hasNodeKey = true;
                      nodeKeys[nodeKey] = nodeKey;
                    }
                  }
                }
              }
            }

            //console.log('level=' + level + '  nodeKey=' + nodeKey + ' node.letter==' + node.letter);
            if(reset ||
               !hasNodeKey) { //wildcards                
                if(level < items.length - 1) {
                    for(var i=0; i < levelSize; i++) {                    
                        var node = nodesForLevel.shift();                        
                        var children = node.getChildren();
                        for(var j=0; j < children.length; j++) {                        
                            //add back for next level inspection
                            var child = children[j];
                            nodesForLevel.push(child);
                        }
                    }
                }
            } else {
                for(var i=0; i < levelSize; i++) {
                    var node = nodesForLevel.shift();
                    var splitLetter = [node.letter];
                    if(jQuery(levelInput).is('select')) {                                            
                      if(isMultiSelect) {
                        splitLetter = hashKeys[node.letter].split(';');

                      }
                    }

                    for(var p=0; p < splitLetter.length; p++) {
                      var letter = splitLetter[p];
                      //var keyCode = reverseKeys[letter];                      
                      if(typeof(nodeKeys[letter]) !== 'undefined') { //matching node
                        if(level == items.length - 1) {
                            nodesForLevel.push(node);

                        } else { //willd check next level
                            var children = node.getChildren();
                            for(var j=0; j < children.length; j++) {                        
                                //add back for next level inspection
                                var child = children[j];                        
                                nodesForLevel.push(child);
                            }
                        }
                      }
                    }
                }                    
            }

            level+=1;
        }
        //console.log('results=');
        //console.log(nodesForLevel);

        //populate dropdowns
        var addedColumns = {};
        var addedColumnLabels = {};
        if(typeof(items) !== 'undefined' 
                && items != null) {                
            for(var i = level -1; i >= 0; i--) {                
                addedColumns[i] = [];
                addedColumnLabels[i] = [];

                var availableValues = [];
                var item = items[i];
                var levelSize = nodesForLevel.length;
                for(var j=0; j < levelSize; j++) {
                    var node = nodesForLevel.shift();
                    if(typeof(addedColumns[i][node.letter]) === 'undefined') {                       
                        var optionValue = hashKeys[node.letter];
                        if(jQuery(item).is('select')) {
                          var elementId = jQuery(item).attr('id');
                          var attrMultiSelectRight = document.getElementById(elementId+'_selected');
                          if(attrMultiSelectRight != null) {
                            var splitOptions = optionValue.split(';');
                            availableValues = availableValues.concat(splitOptions);                           
                          } else {
                            availableValues.push(optionValue);
                          }
                        } else {
                          availableValues.push(optionValue);

                        }

                        addedColumns[i][node.letter] = true;
                        addedColumnLabels[i][optionValue] = node.letter;
                    }

                    var parentNode = node.getParent();
                    if(parentNode != null) {
                        nodesForLevel.push(parentNode);

                    }
                }

                //cannot filter on non-picklist type element
                if(jQuery(item).is('select')) {
                  var elementId = jQuery(item).attr('id');
                  var attrMultiSelectLeft = document.getElementById(elementId+'_unselected');
                  var attrMultiSelectRight = document.getElementById(elementId+'_selected');
                  constrainPicklist(item.get(0), 
                                    attrMultiSelectLeft,
                                    attrMultiSelectRight,
                                    availableValues);
                }
            }
        }
    }
};

/**
  This class is used for traversing the succinctly encoded trie.
  */
function AptValueMatrixNode(trie, index, letter, firstChild, parent, childCount) {
    this.trie = trie;
    this.index = index;
    this.letter = letter;
    this.firstChild = firstChild;
    this.parent = parent;
    this.childCount = childCount;
    this.children = null;
}

AptValueMatrixNode.prototype = {
    /**
      Returns the number of children.
      */
    getChildCount: function() {
        return this.childCount;
    },

    /**
      Returns the FrozenTrieNode for the given child.    
      @param index The 0-based index of the child of this node. For example, if
      the node has 5 children, and you wanted the 0th one, pass in 0.
    */
    getChild: function(index) {
        var result = null;        
        return this.trie.getNodeByIndex(this.firstChild + index, this);

    },
        
    /**
      Returns the FrozenTrieNode for all children
    */
    getChildren: function() {
        if(this.children == null) {
            this.children = [];
            for(var i=0; i < this.childCount; i++) {
                this.children.push(this.getChild(i));
            }
        }

        return this.children;
    },

    /**
      Return the parent node
    */
    getParent: function() {        
        return this.parent;
    }
};

BitString.MaskTop = [
    0x3f, 0x1f, 0x0f, 0x07, 0x03, 0x01, 0x00 
];

BitString.BitsInByte = [ 
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4, 1, 2, 2, 3, 2, 3, 3, 4, 2,
    3, 3, 4, 3, 4, 4, 5, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3,
    3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3,
    4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4,
    3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5,
    6, 6, 7, 1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5, 2, 3, 3, 4, 3, 4,
    4, 5, 3, 4, 4, 5, 4, 5, 5, 6, 2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5,
    6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 2, 3, 3, 4, 3, 4, 4, 5,
    3, 4, 4, 5, 4, 5, 5, 6, 3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 3,
    4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7, 4, 5, 5, 6, 5, 6, 6, 7, 5, 6,
    6, 7, 6, 7, 7, 8 
];

BitString.AlphabetDigits = {
    "A" : 0, "B" : 1, "C" : 2, "D" : 3, "E" : 4, "F" : 5, 
    "G" : 6, "H" : 7, "I" : 8, "J" : 9, "K" : 10, "L" : 11, 
    "M" : 12, "N" : 13, "O" : 14, "P" : 15, "Q" : 16, "R" : 17, 
    "S" : 18, "T" : 19, "U" : 20, "V" : 21, "W" : 22, "X" : 23, 
    "Y" : 24, "Z" : 25, "a" : 26, "b" : 27, "c" : 28, "d" : 29, 
    "e" : 30, "f" : 31, "g" : 32, "h" : 33, "i" : 34, "j" : 35, 
    "k" : 36, "l" : 37, "m" : 38, "n" : 39, "o" : 40, "p" : 41, 
    "q" : 42, "r" : 43, "s" : 44, "t" : 45, "u" : 46, "v" : 47, 
    "w" : 48, "x" : 49, "y" : 50, "z" : 51, "0" : 52, "1" : 53, 
    "2" : 54, "3" : 55, "4" : 56, "5" : 57, "6" : 58, "7" : 59, 
    "8" : 60, "9" : 61, "-" : 62, "_" : 63
};

/**
 * Given a string of data, the BitString class supports
 * reading or counting a number of bits from an arbitrary position in the
 * string.
 */     
function BitString(str) {
    this.init(str);

}

BitString.prototype = {
    encodingWidth:6,
    init: function( str ) {
        this.bytes = str;
        this.length = this.bytes.length * this.encodingWidth;
    },
    /**
     * Returns the internal string of bytes
     */
    getData: function() {
        return this.bytes;

    },

    /**
     * Returns a decimal number, consisting of a certain number, numDigits, of bits
     * starting at a certain position, startPosition.
     */
    get: function(startPosition, numDigits) {
        // case 1: bits lie within the given byte
        if ((startPosition % this.encodingWidth) + numDigits <= this.encodingWidth) {
            return (BitString.AlphabetDigits[ this.bytes[ startPosition / this.encodingWidth | 0] ] & BitString.MaskTop[ startPosition % this.encodingWidth ]) >> 
                (this.encodingWidth - startPosition % this.encodingWidth - numDigits);

        // case 2: bits lie incompletely in the given byte
        } else {
            var result = (BitString.AlphabetDigits[ this.bytes[startPosition / this.encodingWidth | 0]] & 
                BitString.MaskTop[ startPosition % this.encodingWidth]);

            var remainder = this.encodingWidth - startPosition % this.encodingWidth;
            startPosition += remainder;
            numDigits -= remainder;

            while (numDigits >= this.encodingWidth) {
                result = (result << this.encodingWidth) | BitString.AlphabetDigits[this.bytes[ startPosition / this.encodingWidth | 0]];
                startPosition += this.encodingWidth;
                numDigits -= this.encodingWidth;
            }

            if (numDigits > 0) {
                result = (result << numDigits) | (BitString.AlphabetDigits[this.bytes[startPosition / this.encodingWidth | 0]] >> 
                    (this.encodingWidth - numDigits));
            }

            return result;
        }
    },

    /**
        Counts the number of bits set to 1 starting at position p and
        ending at position startPosition + numDigits
     */
    count: function(startPosition, numDigits) {
        var count = 0;
        while(numDigits >= 8) {
            count += BitString.BitsInByte[this.get(startPosition, 8)];
            startPosition += 8;
            numDigits -= 8;
        }

        return count + BitString.BitsInByte[this.get(startPosition, numDigits)];
    }

};