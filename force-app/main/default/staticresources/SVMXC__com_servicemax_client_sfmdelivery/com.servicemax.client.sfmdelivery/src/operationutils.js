/**
 * Utilities used by sfmdeliveryoperations.js where online and offline versions of these methods
 * are shared.
 * @class com.servicemax.client.sfmdelivery.operationutils
 * @author Michael Kantor, etc...
 * @since       : The minimum version where this file is supported
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){
    var utils = SVMX.Package("com.servicemax.client.sfmdelivery.operationutils");

utils.init = function(){
    var CONSTANTS = com.servicemax.client.sfmdelivery.constants.Constants;


    utils.Class("Utilities", com.servicemax.client.lib.api.Object, {}, {
        /*
         * @param {Object} request
         * @param {AddRecordsResponder} responder
         * @param {Object} data
         * @param {Object} objectInfo
         * @param {String} cacheKey. If falseish, no caching.
         * @param {AddRecords} operation Operation instance
         */
        addRecords_processData : function(inParams){

                // add record template to cache
                if(inParams.cacheKey){
                    var module = inParams.request.additionalInfo.module.instance;
                    module.setItemToCache(inParams.cacheKey, inParams.data);
                    SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-AddRecords")
                            .info("Adding record template for <" + inParams.request.alias + "> to cache");
                }
                // end cache

                // update the boolean types. they can have "undefined" values
                function getFieldFromTemplate(template, fieldName){
                    var fields = template[0].bubbleInfo, i, l = fields.length, field, ret = null;
                    for(i = 0; i < l; i++){
                        field = fields[i];
                        if(field.fieldapiname == fieldName){
                            ret = field;
                            break;
                        }
                    }
                    return ret;
                }

                var i, field, fields = inParams.objectInfo.fields, l = fields.length;

                for(i = 0; i < l; i++){
                    field = fields[i];
                    if(field.dataType == 'boolean'){
                        var fldObj = getFieldFromTemplate(inParams.data, field.name);
                        if(!fldObj){
                            // insert
                            inParams.data[0].bubbleInfo[inParams.data[0].bubbleInfo.length] = {
                                fieldapiname : field.name,
                                fieldvalue : {key : "false", value : "false"}
                            };
                        }
                    }
                    
                }
                // end update boolean

                // if this is a multi add request
                inParams.data = this.addRecord_doMultiAdd(inParams.request, inParams.data, inParams.optionalNewIds);
                // end multi add request

        inParams.request.data.addNewDetailRecords(inParams.data, inParams.request.alias, function() {
        inParams.onSuccess(inParams.data);
        SVMX.destroy(inParams); // Something about this callback keeps it from being garbage collected; and all of the data contained by inParams along with it
        });
        },

        addRecord_doMultiAdd : function(request, template, optionalNewIds){
            var ret = template;

            if(request.multiAddFieldRecordIds && request.multiAddFieldRecordIds.length > 0){
                var multiAddFieldRecordIds = request.multiAddFieldRecordIds, recArray = [],
                    multiAddFieldRecordValues = request.multiAddFieldRecordValues, i, l = multiAddFieldRecordIds.length,
                    multiAddFieldApiName = request.multiAddFieldApiName;

                for(i = 0; i < l; i++){
                    recArray[i] = this.addRecord_mergeFieldToRecordTemplate(SVMX.cloneObject(template[0]),
                        {apiName : multiAddFieldApiName, key : multiAddFieldRecordIds[i], value : multiAddFieldRecordValues[i]});

                    if (optionalNewIds) {
                        recArray[i].sobjectinfo.Id = optionalNewIds[i];
                    }
                }

                ret = recArray;
            }

            return ret;
        },

        addRecord_mergeFieldToRecordTemplate : function(template, fieldInfo){
            var fields = template.bubbleInfo, i, l = fields.length, field, targetField = null;
            for(i = 0; i < l; i++){
                field = fields[i];
                if(field.fieldapiname == fieldInfo.apiName){
                    targetField = field;
                    break;
                }
            }

            if(!targetField){
                // target field not found in the template! should not happen
                targetField = {fieldapiname : fieldInfo.apiName, fieldvalue : {}};
                fields[fields.length] = targetField;
            }

            targetField.fieldvalue = {key : fieldInfo.key, value : fieldInfo.value};
            return template;
        },

        replaceLiteralsWithValue : function(criteria, refMetaModel, key, addQuotes){
            //TODO : Non-performant, check for better solns
            var pfc = criteria;
            if(pfc != null && pfc != undefined && pfc != ""){
                var constant = "[SVMX.CURRENTRECORD.", constant1 = "[SVMX.CURRENTRECORDHEADER.";

                //avoiding multiple quotes for offline
                if(pfc.indexOf("'"+constant) > 0 || pfc.indexOf("'"+ constant1) > 0){
                    addQuotes = false;
                }

                for(var i = 0; i < pfc.length; i++){
                    var index = pfc.indexOf(constant), fieldName;
                    if(index > -1){
                        pfc = pfc.replace(constant, "*");
                        var ind = pfc.indexOf("*"), con = "]", ind1 = pfc.indexOf(con, ind);
                        if(ind > -1){
                            fieldName = pfc.substring(ind, ind1);
                            fieldName1 = fieldName.replace("*", "");
                            fieldName = fieldName + con;

                            var actualValue = refMetaModel.getDataBinding().getRelatedBindingValue(fieldName1, "CURRENTRECORD");
                            actualValue = (actualValue === CONSTANTS.NO_VALUE || null) ? '' : actualValue;

                            //adding quotes to work offline
                            if(addQuotes) {
                                actualValue = "'" + actualValue + "'";
                            }

                            pfc = pfc.replace(fieldName, actualValue);
                        }
                    }
                }

                for(var i = 0; i < pfc.length; i++){
                    var index = pfc.indexOf(constant1), fieldName;
                    if(index > -1){
                        pfc = pfc.replace(constant1, "*");
                        var ind = pfc.indexOf("*"), con = "]", ind1 = pfc.indexOf(con, ind);
                        if(ind > -1){
                            fieldName = pfc.substring(ind, ind1);
                            fieldName1 = fieldName.replace("*", "");
                            fieldName = fieldName + con;

                            var actualValue = refMetaModel.getDataBinding().getRelatedBindingValue(fieldName1, "CURRENTRECORDHEADER");
                            actualValue = (actualValue === CONSTANTS.NO_VALUE || null) ? '' : actualValue;

                            //adding quotes to work offline
                            if(addQuotes) {
                                actualValue = "'" + actualValue + "'";
                            }
                            pfc = pfc.replace(fieldName, actualValue);
                        }
                    }
                }
            }


            return pfc;
        },

        replaceBoolToString : function(string){
            //TODO : Non-performant, check for better solns

            var trueIndex = string.indexOf('=true');
            if(trueIndex > -1){
                string = string.replace(/=true/g, '=\'true\'');
            }

            var falseIndex = string.indexOf('=false');
            if(falseIndex > -1){
                string = string.replace(/=false/g, '=\'false\'');
            }

            return string;
        },

        extractDefWithFiltersToQuery : function(request, lookupDef){
            var j, k, m, n, len = lookupDef.advFilters.length, filtersToQuery = request.filtersToQuery, found = false, indexes = [];
            if(filtersToQuery != undefined){
                for(j = 0; j < len; j++){
                    found = false;
                    for(k = 0; k < filtersToQuery.length; k++){
                        if(lookupDef.advFilters[j].key == filtersToQuery[k]){
                            found = true;

                            var constant = "SVMX.USERTRUNK", userTrunk = request.userTrunk;

                            if(lookupDef.advFilters[j].filterCriteria.indexOf(constant) > -1){
                                lookupDef.advFilters[j].filterCriteria = lookupDef.advFilters[j].filterCriteria.replace(constant, userTrunk);
                            }
                        }
                    }
                    if(!found){
                        indexes.push(j);
                    }
                }
            }else{
                for(j = 0; j < len; j++){
                    if(lookupDef.advFilters[j].defaultOn == true || lookupDef.advFilters[j].defaultOn == "true"){
                        found = true;
                        var constant = "SVMX.USERTRUNK", userTrunk = request.userTrunk;

                        if(lookupDef.advFilters[j].filterCriteria.indexOf(constant) > -1){
                            lookupDef.advFilters[j].filterCriteria = lookupDef.advFilters[j].filterCriteria.replace(constant, userTrunk);
                        }
                    }else{
                        found = false;
                    }

                    if(!found){
                        indexes.push(j);
                    }
                }
            }

            //delete the advfilters that do not match the ID
            for(m = 0; m < indexes.length; m++ ){
                delete lookupDef.advFilters[indexes[m]];
            }

            //delete leaves empty spaces in array, chk and assign it back the the lookupDef.advfilters array
            var tempArray = [];
            for(n = 0; n < len; n++){
                if(lookupDef.advFilters[n]){
                    tempArray.push(lookupDef.advFilters[n]);
                }
            }

            lookupDef.advFilters = tempArray;

            return lookupDef;
        },

        processDescribeResult : function (describeResult, describeLayoutResult){
            // process record types
            describeResult.recordTypeMapping = [];
            if(describeLayoutResult){
                // single objects are not converted to array while un-marshalling
                if(!(describeLayoutResult.recordTypeMappings instanceof Array)) {
                    describeLayoutResult.recordTypeMappings = [describeLayoutResult.recordTypeMappings];
                }

                var rtmappings = describeLayoutResult.recordTypeMappings, i, l = rtmappings.length, rtm,
                    picklistsForRecordType;
                for(i = 0; i < l; i++) {
                    rtm = rtmappings[i];
                    picklistsForRecordType = rtm.picklistsForRecordType;

                    if(!picklistsForRecordType) {
                        picklistsForRecordType = [];
                    }

                    // single objects are not converted to array while un-marshalling
                    if(!(picklistsForRecordType instanceof Array)) {
                        picklistsForRecordType = [picklistsForRecordType];
                    }

                    rtm.picklistsForRecordType = processPicklistsForRecordType(picklistsForRecordType, describeResult);
                    describeResult.recordTypeMapping.push(rtm);
                }
            }
            // end record types

            // process dependent fields
            var i, fields = describeResult.fields, l = fields.length, field, cname, cfield;
            for(i = 0; i < l; i++){
                field = fields[i];
                if(field.dependentPicklist){
                    cname = field.controllerName;
                    cfield = getField(cname, describeResult);
                    if(cfield){
                        updateControllingPicklistWithDependents(cfield, field);
                    }
                }
            }
            // end process dependent fields

            function updateControllingPicklistWithDependents(cfield, dfield){
                var cvalues = cfield.picklistValues, i, l = cvalues.length, validForBytes,
                    j, dvalues = dfield.picklistValues, c = dvalues.length, isValid,
                    dependentPicklistArray, dependentPicklistInfo, k, s;

                for(i = 0; i < l; i++){

                    if(!cvalues[i].dependendPicklist){ cvalues[i].dependendPicklist = []; }

                    dependentPicklistArray = cvalues[i].dependendPicklist;

                    for(j = 0; j < c; j++){
                        validForBytes = dvalues[j].validFor; isValid = checkIfBytesAreValid(validForBytes, i);

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
            }

            /**
             *  Overcome issues with SFDC SOAP API Issues and Bugs
             * @param inputBytes
             * @param parentIndex
             * @returns {boolean}
             */
            function checkIfBytesAreValid(inputBytes, parentIndex){

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
            }

            function processPicklistsForRecordType(picklistsForRecordType, describeResult){
                var i, l = picklistsForRecordType.length, picklistForRecordType,
                    j, c, index, value;

                for(i = 0; i < l; i++){
                    picklistForRecordType = picklistsForRecordType[i];
                    var picklistName = picklistForRecordType.picklistName;
                    var picklistValues = picklistForRecordType.picklistValues;

                    // single objects are not converted to array while un-marshalling
                    if(!(picklistValues instanceof Array)) {
                    if (picklistValues === undefined) {
                        picklistValues = [];
                    } else {
                        picklistValues = [picklistValues];
                    }
                    }
                    c = picklistValues.length; value = "";
                    for(j = 0; j < c; j++){
                        value += getPicklistValueIndex(picklistName, picklistValues[j].value, describeResult) + ";";
                    }

                    if(value.length > 0){
                        value = value.substring(0, value.length - 1);
                    }

                    picklistForRecordType.picklistValues = [{value : value}];
                }

                return picklistsForRecordType;
            }

            function getPicklistValueIndex(name, value, describeResult){
                var field = getField(name, describeResult), ret = 0, plValues, i, l;

                if(field){
                    plValues = field.picklistValues; l = plValues.length;
                    for(i = 0; i < l; i++){
                        if(plValues[i].value == value){
                            ret = i;
                            break;
                        }
                    }
                }

                return ret;
            }

            function getField(name, describeResult){
                var ret = null, fields = describeResult.fields, i, l = fields.length;
                for(i = 0; i < l; i++){
                    if(fields[i].name == name){
                        ret = fields[i];
                        break;
                    }
                }
                return ret;
            }
        }
    });

    utils.Class("SFMTargetRecord", com.servicemax.client.lib.api.Object, {
        __data : null, __metadata : null, __additionalInfo : null,
        __constructor : function(data, metadata, additionalInfo){
            this.__data = data;
            this.__metadata = metadata;
            this.__additionalInfo = additionalInfo;
        },

        getParentObjectName : function(){
            return this.__metadata.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"];
        },

        getHeaderLayoutId : function(){
            return this.__metadata.page.header.hdrLayoutId;
        },

        getProcessType : function(){
            return this.__metadata.response.sfmProcessType;
        },


        getHeaderRecords : function(){
            var ret = [], data = this.__data.getRawData().sfmData,arrayOfRecords = [];
            var ptype = this.getProcessType();
            if(ptype == "CHECKLIST" && data){
              var status = data[SVMX.OrgNamespace +'__Status__c'];
              //not started status
              if((!data.hasOwnProperty("Id") || data.Id==undefined) && data.hasOwnProperty([SVMX.OrgNamespace +'__ChecklistMetaJSON__c'])) {
                  var sizeOfMetaJson = 120000;
                  var metaJson = data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                  var groupId = new Date().getTime();
                  var sequenceForRowIndex = 1;
                  if(metaJson.length>sizeOfMetaJson) {
                        var checkListMetaJsonChunks = SVMX.splitLongStringToChunkArray(metaJson,sizeOfMetaJson);
                        for(var metaJsonChunkIndex = 0; metaJsonChunkIndex < checkListMetaJsonChunks.length; metaJsonChunkIndex++)
                        {
                             var clonedChecklistRecord = SVMX.cloneObject(data);
                             clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'] = checkListMetaJsonChunks[metaJsonChunkIndex];
                             if(metaJsonChunkIndex>0){
                                 delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistJSON__c'];
                             }
                             clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Sequence__c'] = sequenceForRowIndex;
                             clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'] = groupId;

                             arrayOfRecords.push(clonedChecklistRecord);
                             sequenceForRowIndex++;
                        }
                    } 
                    else {
                         data[SVMX.OrgNamespace +'__SM_Sequence__c'] = sequenceForRowIndex;
                         data[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'] = groupId;
                    }
                }//Completed status
                else if(data.hasOwnProperty("Id") && this.__additionalInfo && this.__additionalInfo.hasOwnProperty("lstSobjectinfo") && data[SVMX.OrgNamespace +'__Status__c']=="Completed") {
                      var checklistRelatedRecord = this.__additionalInfo["lstSobjectinfo"];
                      if(checklistRelatedRecord.length>0) {
                        delete data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                        arrayOfRecords.push(data);
                      }
                      for (var index =1 ;index<checklistRelatedRecord.length;index++) {
                            var checkListRecord = checklistRelatedRecord[index];
                            var clonedChecklistRecord = SVMX.cloneObject(data);
                            delete clonedChecklistRecord["Id"];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistJSON__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Sequence__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'];
                            clonedChecklistRecord["Id"] = checkListRecord["Id"];
                            clonedChecklistRecord["Name"] = checkListRecord["Name"];
                            arrayOfRecords.push(clonedChecklistRecord);
                      }
                }//In Process status or completed status with single record
                else {
                        delete data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                }
            }

            if(arrayOfRecords.length==0) {
              arrayOfRecords.push(data);
            }

            SVMX.array.forEach(arrayOfRecords, function(data) {
              var record = { targetRecordAsKeyValue : [] }, keyValue = null;
              ret.push(record);
              SVMX.forEachProperty(data, function(inKey, inValue) {
                    if (inKey == "attributes" || inKey.indexOf("_") === 0 || typeof inValue === "function" || inValue && typeof inValue == "object" && !("fieldvalue" in inValue)) return;

                    if(inKey == 'sourceRecordID') return;

                    var item = data[inKey];
                    keyValue = null;
                    if(typeof(item) == 'object' && item !== undefined && item !== null){
                        keyValue = {key : inKey, value : item.fieldvalue.key, value1 : item.fieldvalue.value};
                    }else{
                        // special fields which are undefined or empty string MUST not be sent
                        // Defect Fix : 026449 (record type either undefined / empty string should be skipped)
                        if(!(inKey == "RecordTypeId" && (item === undefined || !(item)))){
                                keyValue = {key : inKey, value : item};
                        }
                    }

                    if(keyValue){
                          record.targetRecordAsKeyValue[record.targetRecordAsKeyValue.length] = keyValue;
                    }
                });
            });

            return ret;
        },

        getDetailRecords : function(){
            var ret = [], details = this.__data.getRawData().sfmData.details, detailRecords = null, detailId = null;

            for(detailId in details){
                ret[ret.length] = {}; // set up the details array
            }

            for(detailId in details){
                    var detailMetaData = this.getDetailMetadata(detailId), keyValue = null, detailRecordId = null, detailSourceRecordId = null,
                        detailLines = details[detailId].lines, i, l = detailLines.length, line = null, record = null;

                    detailRecords = {};
                    detailRecords.aliasName = detailMetaData.dtlLayoutId;
                    detailRecords.pageLayoutId = detailMetaData.dtlLayoutId;
                    detailRecords.objName = detailMetaData.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
                    detailRecords.parentColumnName = this.getDetailParentColumnName(detailMetaData);
                    detailRecords.records = [];
                    detailRecords.deleteRecID = this.getDetailDeletedRecords(detailId);

                    // preserve the order!!
                    ret[detailMetaData.DetailLayout[SVMX.OrgNamespace + "__Sequence__c"] - 1] = detailRecords;

                    for(var i = 0; i < l; i++){
                        line = detailLines[i], record = {};

                        detailRecordId = line.Id;
                        if(detailRecordId)
                            record.targetRecordId = detailRecordId;

                        detailSourceRecordId = line.sourceRecordID;
                        if(detailSourceRecordId){
                            record.sourceRecordId = detailSourceRecordId;
                        }

                        record.targetRecordAsKeyValue = [];

                        var from__Key = false;
                        for(var key in line){

                            from__Key = false;

                            // don't process __key and sourceRecordID explicitly; nor private properties
                            if(key == "attributes" || key == 'sourceRecordID' || key.indexOf("_") === 0 || key.indexOf("__key", key.length - "__key".length) !== -1) continue;

                            var item = line[key];

                            // check if there is an __key for this item
                            if(line[key + "__key"]){
                                item = line[key + "__key"];
                                from__Key = true;
                            }

                            keyValue = null;
                            if(typeof(item) == 'object' && item !== undefined && item !== null){
                                if(from__Key){
                                    keyValue = {key : key, value : item.key, value1 : item.value};
                                }else{
                                    keyValue = {key : key, value : item.fieldvalue.key, value1 : item.fieldvalue.value};
                                }
                            }else{
                                // special fields which are undefined or empty string MUST not be sent
                                // Defect Fix : 026449 (record type either undefined / empty string should be skipped)
                                if(!(key == "RecordTypeId" && (item === undefined || !(item)))){
                                    keyValue = {key : key, value : item};
                                }
                            }

                            if(keyValue){
                                record.targetRecordAsKeyValue[record.targetRecordAsKeyValue.length] = keyValue;
                            }

                        }
                        detailRecords.records[detailRecords.records.length] = record;
                    }
            }
            return ret;
        },

        getDetailDeletedRecords : function(detailId){
            var ret = [], allDeletedRecords = this.__data.getDeletedRecords(), i, l = allDeletedRecords.length,
                    deletedRecord;
            for(i = 0; i < l; i++){
                deletedRecord = allDeletedRecords[i];
                if(deletedRecord.alias == detailId){
                    ret.push(deletedRecord.id);
                }
            }
            return ret;
        },

        getDetailMetadata : function(detailId){
            var ret = null, details = this.__metadata.page.details, i, l = details.length;

            for(i = 0; i < l; i++){
                if(details[i].dtlLayoutId == detailId){
                    ret = details[i];
                    break;
                }
            }
            return ret;
        },

        getDetailParentColumnName : function(detailMetaData){
            var ret = null, detailId = detailMetaData.dtlLayoutId,
                        parentColumnMap = this.__metadata.response.stringMap, i, l = parentColumnMap.length;
            for(i = 0; i < l; i++){
                if(parentColumnMap[i].key == "PROCESSTYPE") continue;

                if(parentColumnMap[i].key == detailId){
                    ret = parentColumnMap[i].value;
                    break;
                }
            }

            return ret;
        },

        getRequest : function(){
            var request = {headerRecord : {}};
            request.sfmProcessId = this.__additionalInfo.sfmProcessId || this.__additionalInfo.processId;
            request.eventType = this.__additionalInfo.eventType;
            request.headerRecord.objName = this.getParentObjectName();
            request.headerRecord.pageLayoutId = this.getHeaderLayoutId();
            request.headerRecord.records = this.getHeaderRecords();
            request.detailRecords = this.getDetailRecords();

            // do process type specific
            var ptype = this.getProcessType();
            if(ptype == "STANDALONE EDIT" || ptype == "STANDALONE CREATE"){
                request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
            }else if(ptype == "SOURCE TO TARGET ALL"){
                var targetRecordId = this.__data.getTargetRecordId();
                if(targetRecordId){
                    request.headerRecord.records[0].targetRecordId = targetRecordId;
                    var trkv = request.headerRecord.records[0].targetRecordAsKeyValue;
                    trkv[trkv.length] = {key : "Id", value : targetRecordId};
                }
                request.headerRecord.records[0].sourceRecordId = this.__data.getSourceRecordId();
            }else if(ptype == "SOURCE TO TARGET CHILD"){
                request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
                request.headerRecord.records[0].sourceRecordId = this.__data.getTargetRecordId();

            }else if(ptype == "VIEW RECORD"){
                // TODO:
            }else if(ptype == "CHECKLIST"){
                // TODO:
                var me = this;
                if(request.eventType === "validated save") {
                  request.eventType = "save checklist";
                }
                SVMX.array.forEach(request.headerRecord.records, function(headerRecord) {
      								headerRecord["sourceRecordId"] = me.__data.getSourceRecordId();
      					});
            }
            // end process specific

            return request;
        }
    }, {});

    utils.Class("SFMTargetAttachmentRecord", com.servicemax.client.lib.api.Object, {
        __data : null, __metadata : null, __additionalInfo : null, _sourceRecordId:null, __attachmentData: null,
        __constructor : function(request, metadata, additionalInfo){
            this.__data = request.data;
            this.__additionalInfo = request.additionalInfo;
            this.__deletedId = [];
            this.__metadata = metadata;
            this.__attachmentData = request.data.__attachementData;
            this._sourceRecordId = request.data._sourceRecordId;
        },

        getParentObjectName : function(){
            return SVMX.OrgNamespace + "__SM_Checklist_Attachment__c";
        },

        getHeaderLayoutId : function(){
            return this.__metadata.page.header.hdrLayoutId;
        },

        getProcessType : function(){
            return this.__metadata.response.sfmProcessType;
        },

        getHeaderRecords : function(){
            var ret = [];
            if(this.__attachmentData){
                var recordList = this.__attachmentData.unSyncedRecord;
                if(recordList && recordList.length > 0){
                    var recordListLength = recordList.length;
                    for (var index = 0; index < recordListLength; index++) {
                        var attachmentRecord = recordList[index];
                        if(attachmentRecord.hasOwnProperty(SVMX.OrgNamespace + '__SM_Internal_Question_ID__c')){ //Deleted record only.
                            ret.push(this.getChecklistAttachment(attachmentRecord));
                        } 
                    }
                }
            }
            return ret;
        },

        getChecklistAttachment : function(record){
            var recordList = [];
            var targetRecordAsKeyValue = {'targetRecordAsKeyValue':recordList, 'sourceRecordId': this._sourceRecordId};
            var recordKey = Object.keys(record);
            var recordLength = recordKey.length;
            for (var index = 0; index < recordLength; index++) {
                recordList.push(this.getfieldObject(recordKey[index],record[recordKey[index]]));
            }
            return targetRecordAsKeyValue;
        },

        getfieldObject : function(key, value){
            var field = {'key': key, 'value': value};
            return field;
        },

        getDeleteAttachmentID: function(){
            var ids = [];
            if(this.__attachmentData){
                var deleteRecord = this.__attachmentData.__deletedRecords;
                if(deleteRecord){
                    var recordKey = Object.keys(deleteRecord);
                    var recordLength = recordKey.length;
                    for (var index = 0; index < recordLength; index++) {
                        var record = deleteRecord[recordKey[index]];
                        if(record){
                            ids.push(record['Id']);
                        }
                    }
                }
            }
            return ids;
        },

        getRequest : function(){
            var request = {headerRecord : {}};
            request.sfmProcessId = this.__additionalInfo.sfProcessId || this.__additionalInfo.processId;
            request.eventType = this.__additionalInfo.eventType;
            request.headerRecord.objName = this.getParentObjectName();
            request.headerRecord.pageLayoutId = this.getHeaderLayoutId();
            request.headerRecord.records = this.getHeaderRecords();
            request.detailRecords = [];
            request.headerRecord.deleteRecID = this.getDeleteAttachmentID();
            return request;
        }
    }, {});

};

})();
