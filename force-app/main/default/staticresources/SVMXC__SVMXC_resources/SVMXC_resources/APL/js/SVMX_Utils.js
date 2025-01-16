SVMXBGProcessor = {
	nextProcessId : null,
	currentRecordId : null,
	message : "",
	
	load : function()
	{
		sr.errorHandler = {handler : function(e, me)
		{
			showError('Save Action Failed: Status Code ' + me.status + ' :' + me.responseText);
			return false;
		}}
		sr.responseHandler = {handler : function(e, me)
		{
			var result = sr.__getResponse(me);
			for (var j=0; j< result.length; j++)
			{
				debugger;
				if(result[j].success == 'true')
				{
					top.location = result[j].message;
				}
			}
		}}
		SVMXloader.message = this.message;
		SVMXloader.load();
		var valueMap = [new SVMXMap("SVMX_processId", this.nextProcessId), new SVMXMap("SVMX_recordId", this.currentRecordId)];
        var request = new INTF_SFMRequest('', '', valueMap, null);
		sr.invoke("INTF_GetNextStepURL_WS", request);
	}
}

SVMXloader = {
	loaderid : "",
	action : null,
	message : "",
	property1 : null,
	property2 : "",
	
	loadWithMessage : function(message)
	{
		this.message = message;
		this.load();
	},
	
	load : function()
	{
		uiComp = document.getElementById(this.loaderid);
		uiComp.style.display = 'block';
		hideMessage();
		try{
			if(this.message != null && this.message != '')
				document.getElementById(this.loaderid + 'Message').innerHTML = this.message;
		}catch(err){}
		if(this.action != null)
			this.dispatchAction();
	},
	
	loaded : function()
	{
		uiComp = document.getElementById(this.loaderid);
		uiComp.style.display = 'none';
		if(this.action != null)
			this.action = null;
	},
	
	dispatchAction : function()
	{
	    //Create the function call from function name and parameter.
		if(this.property1 != null)
			var funcCall = this.action + "();";
		else
			var funcCall = this.action + "(" + this.property1 + ");";
		 
		//Call the function
		var ret = eval(funcCall);
	}
};

function showError(message, animate)
{
	var uiComp = document.getElementById('errorMessage');
	uiComp.innerHTML = message;
	uiComp = document.getElementById('showMessage');
	uiComp.innerHTML = '';
	uiComp = document.getElementById('SVMXerrorConsole');
	if(animate != null && animate == 'FADEIN')
	{
		$("#SVMXerrorConsole").animate({
			height: 'show'
		}, 1000 );
	}
	else
	{
		uiComp.style.display = 'block';
	}
}
function showMessage(message)
{
	var uiComp = document.getElementById('showMessage');
	uiComp.innerHTML = message;
	uiComp = document.getElementById('errorMessage');
	uiComp.innerHTML = '';
	uiComp = document.getElementById('SVMXerrorConsole');
	uiComp.style.display = 'block';
}

function hideMessage(animate)
{
	uiComp = document.getElementById('SVMXerrorConsole');
	if(animate != null && animate == 'FADEOUT')
	{
		$("#SVMXerrorConsole").animate({
				height: 'hide'
		}, 1000 );
	}
	else
	{
		uiComp.style.display = 'none';
	}
}
function showContent()
{
	var uiComp = document.getElementById('SVMXcontentArea');
	uiComp.style.display = 'block';
}

function showContainer(divId)
{
	var uiComp = document.getElementById(divId);
	uiComp.style.display = 'block';
}

function showProductTextBox()
{
	var Container = document.getElementById('productCodeContainer');
	Container.style.display = 'block';
	Container = document.getElementById('availableProductContainer');
	Container.style.display = 'none';
}
function showProductPicklist()
{
	var Container = document.getElementById('productCodeContainer');
	Container.style.display = 'none';
	Container = document.getElementById('availableProductContainer');
	Container.style.display = 'block';
}

function SVMXContains(element, key)
{
	for (var i = 0; i < element.length; i++) {
		if (element[i] == key) {
			return true;
		}
	}
	return false;
}

function setLocalStorage(key, value)
{
	localStorage.setItem(key, JSON.stringify(value));
}
function getLocalStorage(key)
{
	if(localStorage.getItem(key))
	{
		return eval('(' + localStorage.getItem(key) + ')');
	}
}
function removeLocalStorage(key)
{
	localStorage.removeItem(key);
}

// Invoking custom events
function performCustomEvent(eventType, processType, sucessEvent)
{
	if(sucessEvent == null || sucessEvent == '') sucessEvent = 'invokeDone';
	if(actualModel.mapKeyValue != null && actualModel.mapKeyValue[eventType] != null)
	{
		var eventDetails = actualModel.mapKeyValue[eventType].split(':');
		if(eventDetails == null || eventDetails.length == null  || eventDetails.length != 3)
		{
		}
		else
		{
			var srAfterReceipt = new SOAPRequest({orgNameSpace: eventDetails[0], sessionId : __sfdcSessionId, endPointName: eventDetails[1]});
			var valueMap = [new SVMXMap("SVMX_processId", processId), new SVMXMap("SVMX_recordId", recordId), new SVMXMap("SVMX_processType", processType)];
			var requestAfterReceipt = new INTF_SFMRequest('', eventType, valueMap, null);
			srAfterReceipt.errorHandler = {handler : function(e, me)
			{
				SVMXloader.loaded();
				updateErrorForAllLines();
				showError('Save action failed while invoking custom events(Status Code ' + me.status + ') :' + me.responseText);
				return false;
			}}
			srAfterReceipt.responseHandler = {handler : function(e, me)
			{
				var result = srAfterReceipt.__getResponse(me);
				for (var j=0; j< result.length; j++)
				{
					if(result[j].success == 'true')
					{
						var funcCall = sucessEvent + "();";
						var ret = eval(funcCall);
					}
					else
					{
						SVMXloader.loaded();
						showError(result[j].message);
						return false;
					}
				}
			}}
			srAfterReceipt.invoke(eventDetails[2], requestAfterReceipt);
		}
	}
	else
	{
		var funcCall = sucessEvent + "();";
		var ret = eval(funcCall);
	}
}

function clearErrorMessage()
{
	actualModel.errorMessage = "";
}