var SVMXObject = $.inherit({}, {__constructor : function(){}}, {});

var SOAPRequest = $.inherit(SVMXObject, {
	
	requestLine : "",
	
	__constructor : function(props){
		this.requestLine = "<se:Envelope xmlns:se=\"http://schemas.xmlsoap.org/soap/envelope/\">"
						     + "<se:Header xmlns:sfns=\"http://soap.sforce.com/schemas/package/{0}{1}\">"
							     + "<sfns:SessionHeader><sessionId>{2}</sessionId></sfns:SessionHeader>" 
							 + "</se:Header>"
							 + "<se:Body><{3} xmlns=\"http://soap.sforce.com/schemas/package/{0}{1}\">"
							     + "<request>{4}</request>"
							 + "</{3}></se:Body>"
						 + "</se:Envelope>";

		this.orgNameSpace = props.orgNameSpace;
		this.sessionId = props.sessionId;
		this.endPointName = props.endPointName;
	},
	
	invoke : function(methodName, data, options){
		var me = this;
		var async = options && (options.async != undefined) ? options.async : true;
		
		var request = this.__getRequest(this.requestLine, this.__getOrgNamespace(), 
		                                                   this.endPointName,
		                                                   this.sessionId,
		                                                   methodName,
		                                                   data
		                                                   );
		
		var res = $.ajax({type: "POST", url: "/services/Soap/class/" + this.__getOrgNamespace() + this.endPointName, data: request, async: async,
			success: function(data, status) {
				options.handler.call(options.context, data);
			}, contentType: "text/xml", headers : {SOAPAction : methodName},
			error : function(xhr, status, e){
				options.error.call(options.context);
			}
		});
		
		if(!async) return res;
	},
	
	__getRequest : function(){
		if(arguments.length == 0 ) return "";
		
		var formatted = arguments[0];	// first parameter is the string to be formated
		
	    for (var i = 1; i < arguments.length; i++) {
	        var regexp = new RegExp('\\{'+ (i - 1) +'\\}', 'gi');
	        formatted = formatted.replace(regexp, arguments[i]);
	    }
	    return formatted;
	},
	
	__getOrgNamespace : function(){
		if(this.orgNameSpace != null && this.orgNameSpace != '') return this.orgNameSpace + "/";
		else return "";
	}
},  {}

);	

// end of file
