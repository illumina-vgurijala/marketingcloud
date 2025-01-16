var SVMXObject = $.inherit({}, {__constructor : function(){}}, {});

var SOAPRequestCollection = $.inherit(SVMXObject, {
	
	__params : null,
	__responses : null,
	__callstack : null,
	__async : true,

	responseHandler : null,
	
	__constructor : function(params){
		this.__params = params;
	},
	invokeAll : function() {
		if(this.__params instanceof Array){
			this.__responses = new Array(this.__params.length);
			this.__async = true;
		}else{
			this.__responses = new Array(this.__params.params.length);
			this.__async = this.__params.async;
			this.__params = this.__params.params;
		}
		
		this.__callstack = [];
		var pi = 0, i = 0, param = null, sr = null;
		if(this.__async == true){


			for(pi in this.__params){
				param = this.__params[pi];
				if(param.batch && param.batch.values instanceof Array){
					var batchSize = param.batch.size; 
					var reqCount = ( param.batch.values.length / batchSize ) + (( param.batch.values.length % batchSize ) == 0 ? 0 : 1);
					var brParams = [];
					
					for(var br = 0; br < reqCount; br++){
						var brDataStartIndex = br * batchSize;
						var brData = param.batch.values.slice(brDataStartIndex, brDataStartIndex + batchSize)
						var svmxMAPForLines = new SVMXMap(param.batch.key,null,null,null,brData);
						var reqToCreate = new INTF_SFMRequest(null, null, this.doClone(param.data.valueMap), null);
						reqToCreate.valueMap[param.data.valueMap.length] = svmxMAPForLines;
						var brParam  = {props : {orgNameSpace: param.props.orgNameSpace, sessionId : param.props.sessionId, endPointName: param.props.endPointName, communityPrefix : param.props.communityPrefix}, 
													methodName : param.methodName, data : reqToCreate , options : {}};
						brParams[br] = brParam;
					}
					var me = this;
					var src = new SOAPRequestCollection({async : false, params : brParams});
					src.responseHandler = { handler : function(target){
						var allResponses = target.__responses;
						me.handleResponse(target, allResponses);
					} };
					src.__COLLECTION__INDEX__ = i++;
					this.__callstack.push(src);
					src.invokeAll();
				}else{
					sr = new SOAPRequest(param.props);

					sr.responseHandler = { context : this, handler : this.handleResponse};
					sr.errorHandler = {context : this, handler : this.handleError};
					sr.__COLLECTION__INDEX__ = i++;
					this.__callstack.push(sr);
					sr.invoke(param.methodName, param.data, param.options);
				}
			}
		}else{
			this.__invokeRequest({index : 0, param : this.__params[0]}); 
		}
	},
	
	/////////////////////////// INDIVIDUAL CALLERS / EVENT HANDLERS ////////////////////////
	
	doClone : function(arr){
		var newObj = (arr instanceof Array) ? [] : {};
		for (i in arr) 
		{
			if (i == 'clone') continue;
			if (arr[i] && typeof arr[i] == "object") 
			{
				newObj[i] = this.doClone(arr[i]);
			} 
			else 
				newObj[i] = arr[i]
		} 
		return newObj;
	},
	
	__invokeRequest : function(req){
		var me = this, index = req.index;
		var sr = new SOAPRequest(req.param.props);
		sr.__COLLECTION__INDEX__ = index;
		var handlers = { 
			handleResponse : function(sr, r) {
				me.__responses[sr.__COLLECTION__INDEX__] = r;
				if(sr.__COLLECTION__INDEX__ == (me.__params.length - 1)){
					if(me.responseHandler.context)
						me.responseHandler.handler.call(me.responseHandler.context);
					else
						me.responseHandler.handler({target : me});
				}else{
					setTimeout(function(){
						me.__invokeRequest({ index : index + 1, param : me.__params[index + 1]});
					}, 0);
				}
			}, 
			
			handleError : function(sr, xhr, e) {
				debugger;
			}
		};
		
		sr.responseHandler = { context : handlers, handler : handlers.handleResponse};
		sr.errorHandler = {context : handlers, handler : handlers.handleError};
		sr.__COLLECTION__INDEX__ = req.index;
		this.__callstack.push(sr);
		sr.invoke(req.param.methodName, req.param.data, req.param.options);
	},
	/////////////////////// END INDIVIDUAL ///////////////////////////////////////
	
	///////////////////////////////    GLOBAL EVENT HANDLERS   ///////////////////
	getAllResponses : function(){
		return this.__responses;
	},
	
	handleResponse : function(sr, r){
	
		this.__responses[sr.__COLLECTION__INDEX__] = r;
		
		// at the end
		this.doPostHandle();
	},
	
	handleError : function(sr, xhr, e){
		
		this.__responses[sr.__COLLECTION__INDEX__] = null;
		
		// at the end
		this.doPostHandle();
	},
	
	doPostHandle : function (){
		this.__callstack.pop();
		if(this.__callstack.length == 0){
			if(this.responseHandler.context)
				this.responseHandler.handler.call(this.responseHandler.context);
			else
				this.responseHandler.handler({target : this});
		}
	}
	//////////////////// END GLOBAL ////////////////////////////
	
	}, 
	
	{}
);


var SOAPRequest = $.inherit(SVMXObject, {
	
	requestLine1 : "", requestLine2 : "", orgNameSpace : "", sessionId : "", endPointName : "", communityPrefix : "",
	
	__constructor : function(props){
		this.requestLine1 = "<se:Envelope xmlns:se=\"http://schemas.xmlsoap.org/soap/envelope/\">";
		this.requestLine2 = "</se:Envelope>";
		this.orgNameSpace = props.orgNameSpace;
		this.sessionId = props.sessionId;
		this.endPointName = props.endPointName;
		this.communityPrefix = props.communityPrefix;
	},
	
	invoke : function(methodName, data, options){
		debugger;
		var me = this;
		var async = options && (options.async != undefined) ? options.async : true;
		var request = this.requestLine1 + this.__getHeader() + this.__getBody(methodName, data) + this.requestLine2;
		if(this.orgNameSpace != null && this.orgNameSpace != '')
		{
			var strURL = this.communityPrefix+"/services/Soap/class/";
			var res = $.ajax({type: "POST", url: strURL + this.orgNameSpace + "/" + this.endPointName, data: request, async: async,
				success: function(data, status) {
					if(me.responseHandler) me.responseHandler.handler.call(me.responseHandler.context, me, data);
				}, contentType: "text/xml", headers : {SOAPAction : methodName},
				error : function(xhr, status, e){
					debugger;
					if(me.errorHandler) me.errorHandler.handler.call(me.errorHandler.context, me, xhr, e);
				}
			});
		}
		else
		{
			var strURL = this.communityPrefix+"/services/Soap/class/";
			var res = $.ajax({type: "POST", url: strURL + this.endPointName, data: request, async: async,
				success: function(data, status) {
					if(me.responseHandler) me.responseHandler.handler.call(me.responseHandler.context, me, data);
				}, contentType: "text/xml", headers : {SOAPAction : methodName},
				error : function(xhr, status, e){
					debugger;
					if(me.errorHandler) me.errorHandler.handler.call(me.errorHandler.context, me, xhr, e);
				}
			});
		}
		
		if(!async) return res;
	},
	
	__getHeader : function(){
		if(this.orgNameSpace != null && this.orgNameSpace != '')
		{
			return 	  "<se:Header xmlns:sfns=\"http://soap.sforce.com/schemas/package/" + this.orgNameSpace + "/" + this.endPointName + "\">"
				+ "<sfns:SessionHeader>" + "<sessionId>"
				+ this.sessionId
				+ "</sessionId>" + "</sfns:SessionHeader>" + "</se:Header>";
		}
		else
		{
			return 	  "<se:Header xmlns:sfns=\"http://soap.sforce.com/schemas/package/" + this.endPointName + "\">"
				+ "<sfns:SessionHeader>" + "<sessionId>"
				+ this.sessionId
				+ "</sessionId>" + "</sfns:SessionHeader>" + "</se:Header>";
		}
	},
	
	__getBody : function(methodName, data){
		if(this.orgNameSpace != null && this.orgNameSpace != '')
		{
			var bodyLine1 = "<se:Body><" + 
				methodName + " xmlns=\"http://soap.sforce.com/schemas/package/" + this.orgNameSpace + "/" + this.endPointName + "\">";
		}
		else
		{
			var bodyLine1 = "<se:Body><" + 
				methodName + " xmlns=\"http://soap.sforce.com/schemas/package/" + this.endPointName + "\">";
		}
		var bodyLine2 = "</" + methodName + "></se:Body>";
		return bodyLine1 + this.__getRequest(data) + bodyLine2;
	},
	
	__getRequest : function(data){
		var dh = new DataHandler();
		return "<request>" + dh.marshall(data) + "</request>";
	},
	
	__getResponse : function(data){
		var reader = new sforce.XmlReader(data.documentElement);
		var envelope = reader.getEnvelope();
		var body = reader.getBody();
		var operation = reader.getFirstElement(body);
		if (operation === null) {
			throw "Unable to find operation response element";
		}
		var resultArray = [];
		var children = operation.childNodes;
		for (var i = 0; i < children.length; i++) {
			if (children[i].nodeType != 1) {
				continue;
			}
			if (reader.isNameValueNode(children[i])) {
				resultArray.push(reader.getTextValue(children[i]));
			} else {
				resultArray.push(reader.toXmlObject(children[i]));
			}
		}
		return resultArray;
	}
},  {}

);	


var DataObject = $.inherit({}, {__constructor : function(){} }, {});

var INTF_Request = $.inherit(DataObject, {
	valueMap : null,
	__constructor : function(valueMap){ this.valueMap = valueMap;}
} ,
{
	__metadata : [{name : "Element", inobj : "valueMap", type : "class:SVMXMap", indata : "valueMap", cardinality : "N"}]
}
);


var INTF_SFMRequest = $.inherit(DataObject, {
	eventName : "",
	eventType : null,
	valueMap : null,
	aplOrder : null,
	values : null,
	
	__constructor : function(eventName, eventType, valueMap, aplOrder, values){ this.eventType = eventType; this.eventName = eventName; this.valueMap = valueMap; this.aplOrder = aplOrder; this.values = values;}
} ,
{
	__metadata : [{name : "Element", inobj : "eventName", type: "text", indata : "eventName"},
				  {name : "Element", inobj : "eventType", type: "text", indata : "eventType"},
				  {name : "Element", inobj : "values", type: "text", indata : "values", cardinality : "N"},
				  {name : "Element", inobj : "aplOrder", type: "class:APL_Order", indata : "aplOrder"},
	              {name : "Element", inobj : "valueMap", type : "class:SVMXMap", indata : "valueMap", cardinality : "N"}]
}
);

var SVMXMap = $.inherit(DataObject, {
	key : "",
	value : "",
	valueMap : null,
	records : null,
	values : null,
	
	__constructor : function(key, value, valueMap, records, values){ this.value = value; this.key = key; this.valueMap = valueMap; this.records = records; this.values = values;}
}, 

{
	__metadata : [{name : "Element", inobj : "key", type: "text", indata : "key"},
	              {name : "Element", inobj : "value", type : "text", indata : "value"},
	              {name : "Element", inobj : "valueMap", type : "class:SVMXMap", indata : "valueMap", cardinality : "N"},
				  {name : "Element", inobj : "values", type: "text", indata : "values", cardinality : "N"},
	              {name : "Element", inobj : "records", type : "object:sObject", indata : "records", cardinality : "N"}]	
}
);

var APL_Order = $.inherit(DataObject, {
	orderHdrRecord : null,
	svmxProcess : null,
	orderLines : null,
	configData : null,
	
	__constructor : function(orderHdrRecord, svmxProcess, orderLines, configData){ this.orderHdrRecord = orderHdrRecord; this.svmxProcess = svmxProcess; this.orderLines = orderLines; this.configData = configData;}
}, 

{
	__metadata : [{name : "Element", inobj : "orderHdrRecord", type: "object:SVMXPX1__RMA_Shipment_Order__c", indata : "orderHdrRecord"},
	              {name : "Element", inobj : "svmxProcess", type : "object:SVMXPX1__ServiceMax_Processes__c", indata : "svmxProcess"},
	              {name : "Element", inobj : "orderLines", type : "class:APL_OrderLineCollection", indata : "orderLines", cardinality : "N"},
	              {name : "Element", inobj : "configData", type : "object:SVMXPX1__ServiceMax_Config_Data__c", indata : "configData", cardinality : "N"}]	
}
);

var APL_OrderLineCollection = $.inherit(DataObject, {
	serialNumbers : null,
	clonedFromId : null,
	isEnableSerializedTracking : false,
	isProductStockable : false,
	orderLineRecord : null,
	reconciliationAction : null,
	uniqueIdForClient: null,
	
	__constructor : function(serialNumbers, orderLineRecord, reconciliationAction, isEnableSerializedTracking, isProductStockable, clonedFromId, uniqueIdForClient){ this.serialNumbers = serialNumbers; this.reconciliationAction = reconciliationAction; this.orderLineRecord = orderLineRecord; this.isEnableSerializedTracking = isEnableSerializedTracking; this.isProductStockable = isProductStockable; this.clonedFromId = clonedFromId; this.uniqueIdForClient = uniqueIdForClient;}
}, 

{
	__metadata : [{name : "Element", inobj : "serialNumbers", type: "object:APL_SerialCollection", indata : "serialNumbers", cardinality : "N"},
	              {name : "Element", inobj : "uniqueId", type: "text", indata : "isProductStockable"},
	              {name : "Element", inobj : "availableCount", type: "text", indata : "isProductStockable"},
	              {name : "Element", inobj : "allocatedCount", type: "text", indata : "isProductStockable"},
	              {name : "Element", inobj : "isEnableSerializedTracking", type: "text", indata : "isProductStockable"},
	              {name : "Element", inobj : "isProductStockable", type: "text", indata : "isProductStockable"},
	              {name : "Element", inobj : "orderLineRecord", type : "object:SVMXPX1__RMA_Shipment_Line__c", indata : "orderLineRecord"},
	              {name : "Element", inobj : "reconciliationAction", type : "text", indata : "reconciliationAction"},
				  {name : "Element", inobj : "clonedFromId", type : "text", indata : "clonedFromId"},
				  {name : "Element", inobj : "uniqueIdForClient", type : "text", indata : "uniqueIdForClient"}]	
}
);

var DataHandler = $.inherit(SVMXObject,{
	
	__constructor : function(){},
	marshall : function(data) {
		return this.__domarshall(data);
	},
	
	__domarshall : function(obj){
		var md = obj.__self.__metadata;
		var ret = "";
		for(var i = 0; i < md.length; i++){
			var m = md[i];
			var source = m.inobj;
			var target = m.indata;
			if(obj[source] == null)
				continue;
			if(m.name == "Element"){
				if(m.type == "text"){
					if(this.__isCollection(m))
					{
						for(var k = 0; k < obj[source].length; k++)
						{
							ret += "<" + m.indata + ">" + updateSpecialCharacter(obj[source][k]) + "</" + m.indata+ ">"
						}
					}
					else
					{
						ret += "<" + m.indata + ">" + updateSpecialCharacter(obj[source]) + "</" + m.indata + ">";
					}
				}else if (this.__isClassType(m))
				{
					if(this.__isCollection(m)){
						//if(obj[source] != null)
							ret += this.__marshallCollection(m, obj);
					}else{
						//if(obj[source] != null)
							ret += "<" + m.indata + ">" + this.__domarshall(obj[source]) + "</" + m.indata + ">";
					}
				}else if (this.__isObjectType(m))
				{
					//if(obj[source] != null)
					{
						if(!obj[source].length)
						{
							ret += this.__objectToXML(m, obj[source]);
						}
						else
						{
							for (var valueCount=0; valueCount< obj[source].length; valueCount++)
							{
								ret += this.__objectToXML(m, obj[source][valueCount]);
							}
						}
					}
				}
			}
		}
		
		return ret;
	},
	
	__isClassType : function(m){
		if(m.type.indexOf("class:") != -1) return true;
	},
	
	__isObjectType : function(m){
		if(m.type.indexOf("object:") != -1) return true;
	},
	
	__isCollection : function(m){
		if(m.cardinality && m.cardinality == "N") return true;
	},
	
	__marshallCollection : function(m, obj){
		var cls = this.__getClass(m.type);
		var target = obj[m.inobj];
		var ret = "";
		for(var i = 0; i < target.length; i++){
			var item = target[i];
			var val = this.__domarshall(item);
			ret += "<" + m.indata + ">" + val + "</" + m.indata+ ">"
		}
		
		return ret;
	},
	
	__objectToXML : function(m, obj)
	{
		var ret = "";
		var val = "";
		for(var key in obj)
		{
			if(obj[key] instanceof Function || key.indexOf('__r') >= 0)
				continue
			if(obj[key] != null)
				val += "<" + key + ">" + updateSpecialCharacter(obj[key]) + "</" + key+ ">"
		}
		ret += "<" + m.indata + ">" + val + "</" + m.indata+ ">";
		
		return ret;
	},
	
	__getClass : function(name){
		return window[name.split(":")[1]];
	}
},{});
function updateSpecialCharacter(obj)
{
	if( obj != undefined && obj != null)
	{
		var keyword = obj.toString();
		keyword = keyword.replace(/&/g, '&amp;'); 
		keyword = keyword.replace(/\'/g,'&apos;');
		keyword = keyword.replace(/</g,'&lt;');
		keyword = keyword.replace(/>/g,'&gt;');
		return keyword;
	}	
	return obj;
}
// end of file
