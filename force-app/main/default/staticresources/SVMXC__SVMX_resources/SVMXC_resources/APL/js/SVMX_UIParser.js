var SVMXUI = $.inherit({}, {__constructor : function(){}}, {});

var SVMXUIActualModel = $.inherit(SVMXUI, {
	gridFields: new Object(),
	gridData: new Object(),
	gridHeaderData: new Object(),
	additionalInformation: new Object(),
	searchFields: new Object(),
	mapFilterData: new Object(),
	latestUniqueId: null,
	relatedData: new Object(),
	isAdditionalInfoAvailable: false,
	isRelatedTable: false,
	isGridSearchAllowed: true,
	gridDataProperty: 'orderLineRecord',
	relatedDataProperty: 'serialNumbers',

	__constructor : function(props){
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
						record.Id = 'UNIQUEID_' + uniqueCount;
						uniqueCount++;
					}
					if(this.isAdditionalInfoAvailable)
						this.__makeMapForAdditionalInformation(record.Id, data[valueCount].isEnableSerializedTracking, data[valueCount].isProductStockable);
					if(this.isGridSearchAllowed)
						this.__makeMapForProductSearch(record);
					this.gridData[record.Id] = this.__buildOrderLine(record);
					if(this.isRelatedTable)
						this.relatedData[record.Id] = this.__buildRelatedData(data[valueCount][this.relatedDataProperty]);
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
	__buildRelatedData : function(data){
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
				objSerialNumbers[lstSerialNumbers[serialCount].serialNumber] = lstSerialNumbers[serialCount];
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
	
	__makeMapForAdditionalInformation : function(key, isEnableSerializedTracking, isProductStockable){
		var additionalInfo = new Object;
		if(isEnableSerializedTracking != null)
			additionalInfo.isEnableSerializedTracking = isEnableSerializedTracking;
		else
			additionalInfo.isEnableSerializedTracking = false;
		if(isProductStockable != null)
			additionalInfo.isProductStockable = isProductStockable;
		else
			additionalInfo.isProductStockable = false;
		this.additionalInformation[key] = additionalInfo;
	},
	
	__populateConfigurationInformation : function(configurations){
		for (var i=0; i< configurations.length; i++)
		{
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
					document.getElementById('docattribute'+l).innerHTML = '<span class="fieldsH">' + documentAttribute[l-1].key + ': </span><span class="valueH">' + documentAttribute[l-1].value + '</span>';
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
}, {}
);

var UIDesigner = $.inherit(SVMXUI, {
	UIElement : "", paintFields : new Object(), displayRecords : new Object(),
	
	__constructor : function(props){
		debugger;
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
            	document.getElementById(elements[field].UIid).innerHTML = data[elements[field].field];
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
				table_header.innerHTML = this.paintFields[key].label;
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
		table_col.appendChild(this.__populatedivElementForField(field, record, key, recordKey));
		return table_col;
	},
	
	__populatedivElementForField :  function(field, record, key, recordKey){
		value = document.createElement('div');
		value.innerHTML = this.__populateContentForField(field, record, key);
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
            			content = actualModel.availablePickListValues[key].replace(record[field.name] + '"', record[field.name] + '" selected="selected"');
            		}
            	}
            	else
            		content = record[field.name];
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
					content = '<img src="' + imageDir + 'SVMXC_resources/APL/images/arrowRight.png" onclick="buildSerialNumberUI(\'' + record.Id + '\')" style="cursor: pointer; cursor: hand"/>';
				}
			}
			else
				content = '';
		}
		return content;
	}
}, {}
);
// end of file
