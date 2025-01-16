//var DIALOG_WIDTH = '100%';
//var IFRAME_HEIGHT = '100%';
//var DIALOG_STYLE = "<style>.SeismicDialogCloseButton {position: absolute;right: 10px;top: 6px;} #[!seismicDialogId].overlayDialog .middle{background: #ffffff} .SeismicButtonDialog {overflow: hidden; height: 1000px; width: 100%;} .SeismicButtonDialog .miniRequester{overflow: hidden; border: none; width: 100%; height: " + IFRAME_HEIGHT + ";}</style>";
//var DIALOG_NAME_PREFIX = 'SeismicButton_';
//var PARAMETER_SEISMIC_DIALOG_ID = "[!seismicDialogId]";
var URL_TEMPLETE = 'https://[!apexBaseUrl]/apex/SeismicRequester?id=[!ObjectId]&btnName=[!buttonApiName]&pageUrl=[!pageUrl]&miniDistribution=1&inline=1';
var PARAMETER_APEX_BASE_URL = "[!apexBaseUrl]";
var PARAMETER_OBJECT_ID = "[!ObjectId]";
var PARAMETER_BUTTON_API_NAME = "[!buttonApiName]";
var PARAMETER_PAGE_URL = "[!pageUrl]";

function openSeismicRequesterDialog(title, apexBaseUrl, objectId, buttonApiName, pageUrl) {
	var url = URL_TEMPLETE.replace(PARAMETER_APEX_BASE_URL, apexBaseUrl || '')
	    			.replace(PARAMETER_OBJECT_ID, encodeURIComponent(objectId) || '')
	    			.replace(PARAMETER_BUTTON_API_NAME, encodeURIComponent(buttonApiName) || '')
	    			.replace(PARAMETER_PAGE_URL, encodeURIComponent(pageUrl) || '');
	return window.location.href = url;
}	

/*function openSeismicRequesterDialog(title, apexBaseUrl, objectId, buttonApiName, pageUrl) {
	parent.seismicButtonDialogMap = parent.seismicButtonDialogMap || {};
	var dialog = parent.seismicButtonDialogMap[buttonApiName];

	var canReuse = false;
	if(dialog) {
		var root = dialog.getContentElement();		
		var iframe = _findIframeRecursively(root);		
		if(iframe) {
			iframe.src = dialog.seismicRequesterUrl; // Refresh page every time
	    	dialog.show();
	    	canReuse = true;
		}
	}
	
	if(!canReuse) {
	    var parentBoxName = DIALOG_NAME_PREFIX + Math.random().toString().replace(".", "");
	    dialog = new SimpleDialog(parentBoxName, true);
	    
	    parent.seismicButtonDialogMap[buttonApiName] = dialog;
	    
	    parent[parentBoxName] = dialog;
	    dialog.setTitle(title || '');
	    dialog.createDialog();
	    dialog.setWidth(DIALOG_WIDTH);
	    var url = URL_TEMPLETE.replace(PARAMETER_APEX_BASE_URL, apexBaseUrl || '')
	    			.replace(PARAMETER_OBJECT_ID, encodeURIComponent(objectId) || '')
	    			.replace(PARAMETER_BUTTON_API_NAME, encodeURIComponent(buttonApiName) || '')
	    			.replace(PARAMETER_PAGE_URL, encodeURIComponent(pageUrl) || '');
	    
	    dialog.seismicRequesterUrl = url;
	    var dialogStyle = DIALOG_STYLE.replace(PARAMETER_SEISMIC_DIALOG_ID, parentBoxName);
	    var html = dialogStyle + "<div class='SeismicButtonDialog'><iframe class='miniRequester' border='0' src='" + url + "'/></div>";
	    dialog.setContentInnerHTML(html);
	    dialog.setupDefaultButtons();
	    dialog.show();
	    
	    var topRight = dialog.dialog.getElementsByClassName("topRight");
	    if(topRight && topRight[0]){
	    	var b = document.createElement("button");
	    	b.className = "btn SeismicDialogCloseButton";
	    	b.onclick = function(){
		    	parent[parentBoxName].hide();		    	
				var root = dialog.getContentElement();		
				var iframe = _findIframeRecursively(root);		
				if(iframe) {
					iframe.src = '';
				}
				
		    	return false;
	    	};
	    	
	    	b.innerHTML = 'X';
	    	topRight[0].appendChild(b);
	    }
    }
}

function _findIframeRecursively(dom) {
	if(dom && dom.children) {
		for(var i = 0; i < dom.children.length; i++) {
			var child = dom.children[i];
			
			if(child.className == 'miniRequester') {
				return child;
			}
			
			var childResult = _findIframeRecursively(child);
			
			if(childResult) {
				return childResult;
			}
		}
	}
}*/