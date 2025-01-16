
function XMLObj(data, bHandleNamespaces) {
	this.xmlDoc = null;
	this.xmlData = data;
	this.namespaces = {};
	
	this.extractNamespaces = function (element){
		var nsURI = element.namespaceURI;
		var nsPrefix = element.prefix;
		
		if(nsPrefix && nsPrefix != "")
		this.namespaces[nsPrefix] = nsURI;
		
		var cn = element.childNodes;
		for(var cni=0; cni <cn.length; cni++){
			this.extractNamespaces(cn[cni]);
		}
	};
	
	this.getElementName = function(element){
		return element.nodeName;
	};
	
	this.getFirstChildElement = function(element){
		var ret  = null;
		var children = this.getChildElements(element);
		if(children && children.length > 0)
			ret = children[0];
		
		return ret;
	};
	
	this.getChildElements = function(element){
		var ret = [];
		var cn = element.childNodes;
		
		// filter out only element nodes
		for(var i = 0; i < cn.length; i++){
			if(cn[i].nodeType == 1)		// 1 means Node.ELEMENT_NODE
				ret[ret.length] = cn[i];
		}
		return ret;
	};
	
	this.getFirstElementByTagName = function(tagName, nameSpace, parentElement){
		var ret = this.getElementsByTagName(tagName, nameSpace, parentElement);
		if(ret && ret.length > 0)
			return ret[0];
		else
			return null;
	};
	
	this.getElementsByTagName = function(tagName, nameSpace, parentElement){
		var ret = null;
		
		if(!parentElement)
			parentElement = this.documentElement;
		
		if ($.browser.msie) {
			var nsp = this.getPrefix4NS(nameSpace);
			if(nsp != "")
				tagName = nsp + ":" + tagName;
				
			ret = parentElement.getElementsByTagName(tagName);
		}
		else {
			if (!nameSpace) {
				ret = parentElement.getElementsByTagName(tagName);
			}
			else 
				ret = parentElement.getElementsByTagNameNS(nameSpace, tagName);
		}
		return ret;
	};
	
	this.getAttributeValueAsInt = function(name, nameSpace, element){
		var ret = this.getAttributeValue(name, nameSpace, element);
		if(ret)
			ret = parseInt(ret);
		else
			ret = 0;
		
		return ret;
	};
	
	this.getAttributeValue = function(name, nameSpace, element){
		var ret = null;
		
		if(element){
			if($.browser.msie){
				var nsp = this.getPrefix4NS(nameSpace);
				if(nsp != "")
					name = nsp + ":" + name;
				
				ret = element.getAttribute(name);
			}else{
				if (!nameSpace) {
					ret = element.getAttribute(name);
				}
				else 
					ret = element.getAttributeNS(nameSpace, name);
			}
		}
		return ret;
	};
	
	// this will be used only when running in IE.
	this.getPrefix4NS = function(nameSpace){
		var ret = "";
		
		if(nameSpace && nameSpace != ""){
			for (var nsp in this.namespaces) {
				if (this.namespaces[nsp] == nameSpace) {
					ret = nsp;
					break;
				}
			}
		}
		return ret;
	};
	
	//TODO: Need a better way to identify the input - XML OR String
	var type = typeof(this.xmlData);
	if (type == "string") {
		if ($.browser.msie) {
			this.xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
			this.xmlDoc.async = "false";
			this.xmlDoc.loadXML(this.xmlData);
		}
		else {
			parser = new DOMParser();
			this.xmlDoc = parser.parseFromString(this.xmlData, "text/xml");
		}
	}else{
		this.xmlDoc = this.xmlData;
	}
	
	this.documentElement = this.xmlDoc.documentElement;
	
	if(!bHandleNamespaces)
		return;
	
	// IE has a problem that it does not support XML with namespaces. So, doing it manually
	this.extractNamespaces(this.xmlDoc.documentElement);
}
