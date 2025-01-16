(function(){
	
	/* {
	 	sfmProcessId : "",
	 	eventType : ""
	 	headerRecord : {
					parentColumnName : "",
					pageLayoutId : "",
					objName : "",
					records : [
						{	targetRecordId : "", 
							targetRecordAsKeyValue : [
								{ key : "". value : "", value1 : ""}
							]
						}
					]
				}, 
				
		detailRecords : [
			{	parentColumnName : "",
				aliasName : "",
				pageLayoutId : "",
				objName : "",
				deleteRecID : [""]
				records : [
					{	targetRecordId : "", 
						sourceRecordId : "",
						targetRecordAsKeyValue : [
							{ key : "". value : "", value1 : ""}
						]
					}
				]
			}
		]
	} */
			
	var sfmTargetRecordImpl = SVMX.Package("com.servicemax.client.sal.model.sfmdelivery.targetrecord.impl");
	
	sfmTargetRecordImpl.Class("SFMTargetRecord", com.servicemax.client.lib.api.Object, {
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
			var ret = [], data = this.__data.getRawData().sfmData, record = { targetRecordAsKeyValue : [] }, keyValue = null;

			for(var key in data){
				if(key == "details" || key == "attributes" || key == 'sourceRecordID') continue;
				
				var item = data[key];
				keyValue = null;
				if(typeof(item) == 'object' && item !== undefined && item !== null){
					keyValue = {key : key, value : item.fieldvalue.key, value1 : item.fieldvalue.value};
				}else{
					
					// special fields which are undefined MUST not be sent
					if(!(key == "RecordTypeId" && item === undefined)){
						keyValue = {key : key, value : item};
					}
				}
				
				if(keyValue){
					record.targetRecordAsKeyValue[record.targetRecordAsKeyValue.length] = keyValue;	
				}

			}
			ret[ret.length] = record;
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
						for(key in line){
							
							from__Key = false;
							
							// don't process __key and sourceRecordID explicitly
							if(key == "attributes" || key == 'sourceRecordID' || key.indexOf("__key", key.length - "__key".length) !== -1) continue;
							
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
								// special fields which are undefined MUST not be sent
								if(!(key == "RecordTypeId" && item === undefined)){
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
			request.sfmProcessId = this.__additionalInfo.sfmProcessId;
			request.eventType = this.__additionalInfo.eventType;
			request.headerRecord.objName = this.getParentObjectName();
			request.headerRecord.pageLayoutId = this.getHeaderLayoutId();
			request.headerRecord.records = this.getHeaderRecords();
			request.detailRecords = this.getDetailRecords();
			
			// do process type specific
			var ptype = this.getProcessType();
			if(ptype == "EDIT"){
				request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
			}else if(ptype == "SOURCETOTARGET"){
				var targetRecordId = this.__data.getTargetRecordId();
				if(targetRecordId){ 
					request.headerRecord.records[0].targetRecordId = targetRecordId;
					var trkv = request.headerRecord.records[0].targetRecordAsKeyValue;
					trkv[trkv.length] = {key : "Id", value : targetRecordId};
				}	
				request.headerRecord.records[0].sourceRecordId = this.__data.getSourceRecordId();
			}else if(ptype == "SOURCETOTARGETONLYCHILDROWS"){
				request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
				request.headerRecord.records[0].sourceRecordId = this.__data.getTargetRecordId();
			}else if(ptype == "STANDALONE CREATE"){
				// TODO:
			}else if(ptype == "VIEW RECORD"){
				// TODO:
			}
			// end process specific
			
			return request;
		}
	}, {});
})();

// end of file

