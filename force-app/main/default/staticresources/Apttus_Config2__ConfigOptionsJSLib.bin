// Create a namespace for our custom functions
//YAHOO.namespace("force.com");

//YAHOO.force.com.globalCtx = new Object();
//YAHOO.force.com.clsNodes = new Array();
//YAHOO.force.com.selectedNode = new Object();

/**
 * Sets the selected node
 * @param ctxNode the context node
 */
YAHOO.force.com.setNode = function(ctxNode) {

	// save current selection
	YAHOO.force.com.selectedNode = ctxNode;

}										

/**
 * Hides the detail panel
 */
YAHOO.force.com.hideDetail = function() {
	YAHOO.force.com.detailPanel.hide();
	
} 

/**
 * Builds the detail panel.
 */
YAHOO.force.com.buildDetailPanel = function() {
	//document.body.className = document.body.className + " yui-pe-content";
	// create the detail panel
	YAHOO.force.com.detailPanel = new YAHOO.widget.Panel(
    "detailPanel",  // The id of our dialog container
	    { 
		    width              :   "auto",  // You can play with this until it's right
		    visible            :   false,   // Should be invisible when rendered
		    draggable          :   true,    // Make the dialog draggable
		    close              :   true,    // Include a close title button
		    modal              :   false,   // Make it modal
		    fixedcenter        :   true,    // Keep centered if window is scrolled
		    zindex             :   40,      // Make sure it's on top of everything
		    constraintoviewport:   true     // Constrain to viewport
	
	    }
	);

	// Render the panel to the document.body level of the DOM
	//YAHOO.force.com.detailPanel.render(document.body);
	YAHOO.force.com.detailPanel.render();

}

/**
 * Builds the tree
 */
YAHOO.force.com.buildTree = function() {

	// create tree
	YAHOO.force.com.tree = new YAHOO.widget.TreeView("treeDiv"); 
	YAHOO.force.com.tree.singleNodeHighlight = true;

	//get root node for tree:
	var root = YAHOO.force.com.tree.getRoot();
	var nodeStack = new Array();
	var parentNode;
	var parentName;
	var childNode;
	var obj;
	var objLabel;

	for (i=0; i < YAHOO.force.com.clsNodes.length; i++) {
		parentNode = root;
		obj = YAHOO.force.com.clsNodes[i];
		objParentId = obj.parentId;
		objLabel = obj.label;

		for(x=0; x < nodeStack.length; x++) {
			if (nodeStack[x].data.object.Id == objParentId) {
				parentNode = nodeStack[x];

				break;

			}

		}

		childNode = new YAHOO.widget.MenuNode({label: objLabel, object: obj}, parentNode, obj.expanded);

		if (obj.imageUrl.length > 0) {
			childNode.labelStyle = obj.Id;

		}

		childNode.multiExpand = true;

		if (obj.leaf == "true") {
			childNode.enableHighlight = true;
			YAHOO.util.Event.addListener(childNode.getElId(), "click", YAHOO.force.com.onClickHandler);

			if (obj.expanded == "true") {
				childNode.toggleHighlight();

			}

		} else {
			childNode.enableHighlight = false;

		}

		nodeStack.push(childNode);

	}		

	YAHOO.force.com.tree.subscribe('clickEvent',YAHOO.force.com.tree.onEventToggleHighlight); 

	// draw the tree
	YAHOO.force.com.tree.draw();

}	

/**
 * Handle leaf node click event
 */
YAHOO.force.com.onClickHandler = function(event) {

	// hide the detail panel
	YAHOO.force.com.hideDetail();

	// get the event target	
    var target = YAHOO.util.Event.getTarget(event);
	// get the context node
    var ctxNode = YAHOO.force.com.tree.getNodeByElement(target);

    if (!ctxNode) {
	// Cancel the display of the ContextMenu instance.
	this.cancel();

    }

	// set the selected node
	YAHOO.force.com.setNode(ctxNode);

	// if no node selected, abort
	if (!YAHOO.force.com.selectedNode) {
	// Cancel the display of the ContextMenu instance.
	this.cancel();

    }

	var hiLiteNodes = YAHOO.force.com.tree.getNodesByProperty('highlightState',1);   

	if (YAHOO.lang.isNull(hiLiteNodes)) {    
	invokedoGetGroupOptions(ctxNode.data.object.Id);

	} else {       
		if (ctxNode.highlightState == 1) {
			invokeDoClearOptions(ctxNode.data.object.Id);

		} else {
			invokedoGetGroupOptions(ctxNode.data.object.Id);

		}

	} 

}	

/**
 * Inject style element into dom for classifiction icons/images
 */
YAHOO.force.com.createStyle = function(classId, imageUrl) {
	var styleElm = document.getElementById(classId);

	if (styleElm == null) {
		styleElm = document.createElement('style');
		styleElm.setAttribute("type", "text/css");
		styleElm.setAttribute("id", classId);

		var styleAttrs = new String('.' + classId);

		styleAttrs = styleAttrs.concat(' {background-color:transparent;');
		styleAttrs = styleAttrs.concat('background-image:url(\'').concat(imageUrl).concat('\');');
		styleAttrs = styleAttrs.concat('display:block;');
		//styleAttrs = styleAttrs.concat('height:22px;');
		styleAttrs = styleAttrs.concat('padding-left:20px;');
		styleAttrs = styleAttrs.concat('background-repeat:no-repeat;');
		styleAttrs = styleAttrs.concat('background-position:left top;');
		styleAttrs = styleAttrs.concat('background-attachment:0;}');

		if(styleElm.styleSheet){// IE
			styleElm.styleSheet.cssText = styleAttrs;

		} else {// w3c
			var styleBody = document.createTextNode(styleAttrs);
			styleElm.appendChild(styleBody);

		}

		document.getElementsByTagName('head')[0].appendChild(styleElm);

	}

}		

/**
 * Launch doSelectGroupOption
 */
function invokeDoSelectOption(ctxOptionId, ctxGroupId) {
	//console.log((''+new Date()).split(' ')[4] + ' invokeDoSelectOption');
	// show the modal panel
	YAHOO.force.com.waitPanel.show();
	// dispatch the action
	sfdcDoSelectOption(ctxOptionId, ctxGroupId);

}

/**
 * Launch doGetGroupOptions
 */
function invokedoGetGroupOptions(ctxGrpNodeId) {

	// show the modal panel
	YAHOO.force.com.waitPanel.show();
	// dispatch the action
	sfcdDoGetGroupOptions(ctxGrpNodeId);

}

/**
 * Launch doClearOptions
 */
function invokeDoClearOptions(ctxGrpNodeId) {

	// show the modal panel
	YAHOO.force.com.waitPanel.show();
	// dispatch the action
	sfdcDoClearOptions(ctxGrpNodeId);

}

// Function called when the DOM is ready to create the dialog,
// render the dialog into the document body, add our dialog skin
// css to the body tag, and wire up the buttons on our dialog   
YAHOO.force.com.onDOMReady2 = function() {

	// add our custom skin css to the body tag
	document.body.className = document.body.className + " yui-skin-sam";					

	try {
		// build the tree
		YAHOO.force.com.buildTree();	
	} catch (ex) {
		// ignore - no records to display
	}						

	// build the detail panel
	YAHOO.force.com.buildDetailPanel();

}	

// build the tree as soon as the DOM is in a usable state
//YAHOO.util.Event.onDOMReady(YAHOO.force.com.onDOMReady2);   	
