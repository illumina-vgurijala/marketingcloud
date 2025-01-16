var SVMXUI = $.inherit({}, {__constructor : function(){}}, {});

var SVMXUIActualModel = $.inherit(SVMXUI, {
	gridFields: new Object(),
	gridData: new Object(),
	gridHeaderData: new Object(),
	additionalInformation: new Object(),
	searchFields: new Object(),
	mapFilterData: new Object(),
	mapSecondaryPrimary: new Object(),
	mapSecondaryGrouping: new Object(),
	mapGroupTwoFields: new Object(),
	mapKeyValues: new Object(),
	latestUniqueId: null,
	mapKeyValue: new Object(),
	relatedData: new Object(),
	isSecondaryGroupingAllowed: false,
	isSecondaryGroupingField: false,
	isAdditionalInfoAvailable: false,
	isRelatedTable: false,
	isGridSearchAllowed: true,
	isSecondarySearchAllowed: false,
	isGroupTwoFieldsEnabled: false,
	groupTwoFieldsField1: null,
	groupTwoFieldsField2: null,
	requestAttribute: new Array(),
	customMethodOnLineFunction : null,
	gridDataProperty: 'orderLineRecord',
	relatedDataProperty: 'serialNumbers',
	uniqueIdField: null,

	__constructor : function(props){
		this.gridData = new Object();
		this.gridHeaderData = new Object();
		this.additionalInformation = new Object();
		this.relatedData = new Object();
		this.latestUniqueId = null;
		
		if(props.uniqueIdField != null)
			this.uniqueIdField = props.uniqueIdField;
		if(props.gridFields != null)
			this.gridFields = props.gridFields;
		if(props.searchFields != null)
			this.searchFields = props.searchFields;
		if(props.gridDataProperty != null)
			this.gridDataProperty = props.gridDataProperty;
		if(props.isRelatedTable != null)
		{
			this.isRelatedTable = props.isRelatedTable;
			if(props.relatedDataProperty != null)
				this.relatedDataProperty = props.relatedDataProperty;
		}
		if(props.isAdditionalInfoAvailable != null)
			this.isAdditionalInfoAvailable = props.isAdditionalInfoAvailable;
		if(props.isGridSearchAllowed != null)
			this.isGridSearchAllowed = props.isGridSearchAllowed;
		if(props.isSecondarySearchAllowed != null)
			this.isSecondarySearchAllowed = props.isSecondarySearchAllowed;
		if(props.isSecondaryGroupingAllowed != null)
			this.isSecondaryGroupingAllowed = props.isSecondaryGroupingAllowed;
		if(props.isSecondaryGroupingField != null)
			this.isSecondaryGroupingField = props.isSecondaryGroupingField;
		if(props.isGroupTwoFieldsEnabled != null)
			this.isGroupTwoFieldsEnabled = props.isGroupTwoFieldsEnabled;
		if(props.groupTwoFieldsField1 != null)
			this.groupTwoFieldsField1 = props.groupTwoFieldsField1;
		if(props.groupTwoFieldsField2 != null)
			this.groupTwoFieldsField2 = props.groupTwoFieldsField2;
		if(props.customMethodOnLineFunction != null)
			this.customMethodOnLineFunction = props.customMethodOnLineFunction;
	},
	
	__buildModel : function(data){
		var uniqueCount = 0;
		if(data != null)
		{
			var data = this.__getArray(data);
			for (var valueCount=0; valueCount< data.length; valueCount++)
			{
				if(data[valueCount][this.gridDataProperty] != null)
				{
					var record = data[valueCount][this.gridDataProperty];
					if(record.Id == null || record.Id == '')
					{
						if(this.uniqueIdField != null)
							record.Id = record[this.uniqueIdField];
						else
							record.Id = 'UNIQUEID_' + uniqueCount;
						uniqueCount++;
					}
					if(this.isAdditionalInfoAvailable)
						this.__makeMapForAdditionalInformation(record.Id, data[valueCount].isEnableSerializedTracking, data[valueCount].isProductStockable, data[valueCount].clonedFromId, data[valueCount].serialNumbers);
					if(this.isGridSearchAllowed)
						this.__makeMapForProductSearch(record);
					this.gridData[record.Id] = this.__buildOrderLine(record);
					if(this.isRelatedTable)
						this.relatedData[record.Id] = this.__buildRelatedData(record.Id, data[valueCount][this.relatedDataProperty]);
				}
			}
		}
		else
		{
			showError('No lines available for the process. This may be due to the expressions configured on the process.')
		}
	},
	// Build the order lines from record
	__buildOrderLine : function(data){
		var actualRecord = {};
		for(key in this.gridFields)
		{
			if(this.gridFields[key].reference && data[this.gridFields[key].reference] != null)
			{
				var ref = data[this.gridFields[key].reference];
				actualRecord[key] = data[this.gridFields[key].name];
				for(refKey in this.gridFields[key].referencefields)
				{
					actualRecord[this.gridFields[key].reference+'.'+this.gridFields[key].referencefields[refKey].name] = ref[this.gridFields[key].referencefields[refKey].name];
				}
			}
			else if(data[this.gridFields[key].name])
			{
				actualRecord[this.gridFields[key].name] = data[this.gridFields[key].name];
			}
			else if(this.gridFields[key].defaultvalue != null && (this.gridFields[key].type == 'text' || this.gridFields[key].type == 'number'))
			{
				actualRecord[this.gridFields[key].name] = this.gridFields[key].defaultvalue;
			}
		}
		return actualRecord;
	},
	// Build the serial number model from records
	__buildRelatedData : function(recordId, data){
		if(data != null)
		{
			var lstSerialNumbers = new Array;
			var objSerialNumbers = new Object;
			// If the list of serial number has only one record
			if(!data.length && data != null)
			{
				lstSerialNumbers = [data];
			}
			else
			{
				lstSerialNumbers = data;
			}
			for (var serialCount = 0; serialCount < lstSerialNumbers.length; serialCount++)
			{
				if(this.customMethodOnLineFunction != null)
				{
					//var funcCall = this.customMethodOnLineFunction + "(" + recordId + ", " + lstSerialNumbers[serialCount] + ");";
					//var ret = eval(funcCall);
					window[this.customMethodOnLineFunction](recordId, lstSerialNumbers[serialCount]);
				}
				if(this.isGroupTwoFieldsEnabled == true)
				{
					var qty = 0;
					var groupKey;
					if(this.groupTwoFieldsField1 != null && this.groupTwoFieldsField2 != null)
					{
						groupKey = this.groupTwoFieldsField1+''+this.groupTwoFieldsField2;
					}
					else if(this.groupTwoFieldsField1 != null)
					{
						groupKey = this.groupTwoFieldsField1;
					}
					
					if(this.mapGroupTwoFields[lstSerialNumbers[serialCount][groupKey]] == null)
					{
						if(lstSerialNumbers[serialCount].availableCount != null)
							qty = parseInt(lstSerialNumbers[serialCount].availableCount);
						this.mapGroupTwoFields[lstSerialNumbers[serialCount][groupKey]] = qty;
					}
				}
				if(this.isSecondaryGroupingAllowed == true)
				{
					var productIds = new Array();
					if(this.mapSecondaryGrouping[recordId] != null)
					{
						productIds = this.mapSecondaryGrouping[recordId];
					}
					if(productIds == null || !SVMXContains(productIds,lstSerialNumbers[serialCount][this.isSecondaryGroupingField]))
					{
						productIds.push(lstSerialNumbers[serialCount][this.isSecondaryGroupingField]);
						this.mapSecondaryGrouping[recordId] = productIds;
					}
				}
				objSerialNumbers[lstSerialNumbers[serialCount].serialNumber] = lstSerialNumbers[serialCount];
				if(this.isSecondarySearchAllowed == true)
				{
					var lineIds = new Array();
					if(this.mapSecondaryPrimary[lstSerialNumbers[serialCount].serialNumber] != null)
					{
						lineIds = this.mapSecondaryPrimary[lstSerialNumbers[serialCount].serialNumber];
					}
					lineIds.push(recordId);
					this.mapSecondaryPrimary[lstSerialNumbers[serialCount].serialNumber] = lineIds;
				}
			}
			return objSerialNumbers;
		}
		else
			return null;
	},
	
	__getArray : function(data){
		var resp = new Array;
		if(!data.length && data != null)
		{
			resp = [data];
		}
		else
			resp = data;
		return resp;
	},
	
	__makeMapForProductSearch : function(record){
		if(record.SVMXC__Product__r)
		{
			var productRef = record.SVMXC__Product__r;
			// Build the reference list for product
			for(key in this.searchFields)
			{
				if(this.mapFilterData[productRef[this.searchFields[key].name]] == null)
				{
					this.mapFilterData[productRef[this.searchFields[key].name]] = new Array();
				}
				this.mapFilterData[productRef[this.searchFields[key].name]].push(record.Id);
			}
		}
	},
	
	__makeMapForAdditionalInformation : function(key, isEnableSerializedTracking, isProductStockable, clonedFromId, serialNumber){
		var additionalInfo = new Object;
		if(isEnableSerializedTracking != null)
			additionalInfo.isEnableSerializedTracking = isEnableSerializedTracking;
		else
			additionalInfo.isEnableSerializedTracking = false;
		if(isProductStockable != null)
			additionalInfo.isProductStockable = isProductStockable;
		else
			additionalInfo.isProductStockable = false;
		if(clonedFromId != null)
			additionalInfo.clonedFromId = clonedFromId;
		if(serialNumber != null)
			additionalInfo.serialNumber = serialNumber;
		this.additionalInformation[key] = additionalInfo;
	},
	
	__populateConfigurationInformation : function(configuration){
		var configurations = new Array;
		if(!configuration.length && configuration != null)
		{
			configurations = [configuration];
		}
		else
			configurations = configuration;
			
		for (var i=0; i< configurations.length; i++)
		{
			if(configurations[i].key == "REQUESTATTRIBUTE")
			{
				if(this.requestAttribute != null && this.requestAttribute.length > 0 && configurations[i].valueMap != null)
				{
					var keyValue = new Array();
					if(!configurations[i].valueMap.length)
						keyValue = [configurations[i].valueMap];
					else
						keyValue = configurations[i].valueMap;
					for (var j = 0; j < keyValue.length; j++)
					{
						this.requestAttribute.push(keyValue[j]);
					}
				}
				else
					this.requestAttribute = configurations[i].valueMap;
			}
			if(configurations[i].key == "MAPKEYVALUE")
			{
				var keyValue = new Array();
				if(!configurations[i].valueMap.length)
					keyValue = [configurations[i].valueMap];
				else
					keyValue = configurations[i].valueMap;
				for (var j = 0; j < keyValue.length; j++)
				{
					if(keyValue[j].key != null && keyValue[j].key != '')
					this.mapKeyValue[keyValue[j].key] = keyValue[j].value;;
				}
			}
			if(configurations[i].key == "MAPKEYVALUES")
			{
				var keyValue = new Array();
				if(!configurations[i].valueMap.length)
					keyValue = [configurations[i].valueMap];
				else
					keyValue = configurations[i].valueMap;
				for (var j = 0; j < keyValue.length; j++)
				{
					if(keyValue[j].key != null && keyValue[j].values != null && keyValue[j].values != '')
					{
						var values = new Array();
						if(!keyValue[j].values.length || typeof keyValue[j].values == "string")
							values = [keyValue[j].values];
						else
							values = keyValue[j].values;
						this.mapKeyValues[keyValue[j].key] = values;
					}
					else if(keyValue[j].key != null && keyValue[j].valueMap != null && keyValue[j].valueMap != '')
					{
						if(!keyValue[j].valueMap.length)
						{
							this.mapKeyValues[keyValue[j].key] = [keyValue[j].valueMap];
						}
						else
							this.mapKeyValues[keyValue[j].key] = keyValue[j].valueMap;
					}
				}
			}
			if(configurations[i].key == "COLUMNINFO")
			{
				this.gridFields = eval(configurations[i].value);
			}
			else if(configurations[i].key == "DOCUMENTATTRIBUTE")
			{
				var documentAttribute = configurations[i].valueMap;
				if(documentAttribute != null)
				for(var l=1; l<= documentAttribute.length; l++)
				{
					if(documentAttribute[l-1].value == null)
						documentAttribute[l-1].value = ''
					document.getElementById('docattribute'+l).innerHTML = '<span class="fieldsH">' + documentAttribute[l-1].key + ': </span><span class="valueH">' + this.htmlEntitiesReplace(documentAttribute[l-1].value) + '</span>';
				}
			}
			else if(configurations[i].key == "HEADERATTRIBUTE")
			{
				var documentAttribute = configurations[i].valueMap;
				if(documentAttribute != null)
				for(var l=1; l<= documentAttribute.length; l++)
				{
					this.gridHeaderData[documentAttribute[l-1].key] = documentAttribute[l-1].value;
				}
			}
			else if(configurations[i].key == "AVAILABLELOCATIONS")
			{
				buildLocationValues(configurations[i].valueMap);
			}
			else if(configurations[i].key == "DEFAULTLOCATION")
			{
				actualModel.defaultDeliveryLocationId = configurations[i].value.split('~|~', 2)[0];
			}
		}
	},
	htmlEntitiesReplace: function(value) {
            return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }
}
);

var UIDesigner = $.inherit(SVMXUI, {
	UIElement : "", paintFields : new Object(), displayRecords : new Object(),
	
	__constructor : function(props){
		if(props.UIElement != null)
			this.UIElement = props.UIElement;
		if(props.paintFields != null)
			this.paintFields = props.paintFields;
		if(props.displayRecords != null)
			this.displayRecords = props.displayRecords;
	},
	
	__paintElementUI : function(elements, data){
        for(field in elements)
        {
        	if(data[elements[field].field] != null)
            	document.getElementById(elements[field].UIid).innerHTML = this.htmlEntitiesReplace(data[elements[field].field]);
        }
	},
	
	__paintGridUI : function(){
		table = document.createElement('table');
		table.setAttribute('width', "100%");
		table.setAttribute('id', "table"+this.UIElement);
		table_headeritem = document.createElement('thead');
		table_headerrow = document.createElement('tr');
		for(key in this.paintFields)
		{
			if(this.paintFields[key].displayable == true)
			{
				table_header = document.createElement('th');
				table_header.innerHTML = this.htmlEntitiesReplace(this.paintFields[key].label);
				table_headerrow.appendChild(table_header);
			}
		}
		table_headeritem.appendChild(table_headerrow);
		table.appendChild(table_headeritem);
		table_item = document.createElement('tbody');
		if(this.displayRecords && this.displayRecords != null)
		for(recordKey in this.displayRecords)
		{
			var record = this.displayRecords[recordKey];
			table_item.appendChild(this.__populateRowForRecord(record, recordKey));
			table.appendChild(table_item);
		}
		var delivery = document.getElementById(this.UIElement);
		delivery.innerHTML = "";
		delivery.appendChild(table);
	},
	
	__populateRowForRecord : function(record, recordKey){
		table_row = document.createElement('tr');
		table_row.setAttribute('id', record.Id);
		for(key in this.paintFields)
		{
			if(this.paintFields[key].displayable == true)
			{
				table_row.appendChild(this.__populateColumnForField(this.paintFields[key], record, key, recordKey));
			}
		}
		return table_row;
	},
	
	__populateColumnForField : function(field, record, key, recordKey){
		table_col = document.createElement('td');
		if(field.width && field.width != null)
			table_col.setAttribute('style', "width=" + field.width);
		table_col.appendChild(this.__populatedivElementForField(field, record, key, recordKey));
		return table_col;
	},
	
	__populatedivElementForField :  function(field, record, key, recordKey){
		value = document.createElement('div');
		value.innerHTML = this.htmlEntitiesReplace(this.__populateContentForField(field, record, key));
		if(field.reference)
		{
			// Building show item template
			if(record[key] != null && record[key] != '')
			{
				value.setAttribute('id', record[key]);
			}
		}
		else
		{
			value.setAttribute('id', key + '_' + recordKey);
		}
		return value;
	},
	
	__populatedivStringForField :  function(field, record, key, recordKey){
		value = '<div';
		if(field.reference)
		{
			// Building show item template
			if(record[key] != null && record[key] != '')
			{
				value += ' id="' + record[key] + '">';
			}
		}
		else
		{

			value += ' id="' + key + '_' + recordKey + '">';
		}
		value += this.__populateContentForField(field, record) + '</div>';
		return value;
	},
	
	__populateContentForField : function(field, record, key){
		content = '';
		if(field.reference)
		{
			// Building show item template
			if(record[key] != null && record[key] != '')
			{
				content = record[field.reference+'.Name'];
			}
			else
				content = '';
		}
		else
		{
			if(record[field.name] != null && record[field.name] != '')
			{
            	// If picklist and it has predefined values populate and select the given values
            	if(field.type == 'picklist')
            	{
            		if(actualModel.availablePickListValues[key] != null)
            		{
						var selectOption = '<select>';
						if(field.onchange != null && field.onchange != '')
						{
							selectOption = '<select id="' + key + '_' + recordKey + '"' + 'onchange="' + field.onchange + '">';
						}
            			selectOption += actualModel.availablePickListValues[key].replace(record[field.name] + '"', record[field.name] + '" selected="selected"');
						selectOption += '</select>';
						content = selectOption;
            		}
            	}
            	else
				{
					if(field.type == 'hyperlink')
					{
						if(field.target == null || field.target == '')
							content = '<a href="/' + record[field.linkField] + '" target="_blank">' + record[field.name] + '</a>';
						else
							content = '<a href="/' + record[field.linkField] + '" target="' + field.target + '">' + record[field.name] + '</a>';
					}
					else
						content = record[field.name];
				}
			}
			else if(typeof(field.defaultvalue) == 'object' || field.defaultvalue != null)
			{
				if(field.type == 'text')
					content = field.defaultvalue;
				else if(field.type == 'number')
					content = (field.defaultvalue).toString();
				else if(field.type == 'checkbox')
				{
				
					if(field.defaultvalue == 1)
						content = '<input type="checkbox" checked="checked"/>';
					else
						content = '<input type="checkbox" />';
				}
				else if(field.type == 'picklist')
				{
					var selectOption = '<select>';
					if(field.onchange != null && field.onchange != '')
					{
						selectOption = '<select ' + 'onchange="' + field.onchange + '">';
					}
					for(fieldOptions in field.defaultvalue)
					{
						selectOption += '<option value="' + field.defaultvalue[fieldOptions].key + '">' + field.defaultvalue[fieldOptions].value + '</option>';
					}
					selectOption += '</select>';
					content = selectOption;
				}
				else if(field.type == 'image')
				{
					var imageDir = '{!$Resource.SVMXC_resources}';
					content = '<img src="' + imageDir + 'SVMXC_resources/APL/images/' + field.imageURL + '" onclick="buildSerialNumberUI(\'' + record.Id + '\')" style="cursor: pointer; cursor: hand"/>';
				}
			}
			else
				content = '';
		}
		return content;
	},
	htmlEntitiesReplace: function(value) {
            return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }
}, {}
);
// end of file
