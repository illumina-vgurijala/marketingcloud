var WizardBuilder = function(jsPlumb, 
                             initialWizard, 
                             sourceEndpoint, 
                             targetEndpoint) {
    // private local variables
    var _wizardBuilder = {},
        _row = 0,
        _submitAndPageStepCount = 0,
        _currentColumnPosition = [0],
        _renderedSteps = [],
        _$jsPlumbCont = null,
        _jsPlumbInstances = [],
        _wizards = [],
        _instance = null,
        _building = false,
        _cachedContainers = [],
        _isMovingConnection = false,
        _position = {left:15, top:15},
        _nodeHtmlTemplate = '<div class="tiny-drag-box tiny-drag-box-sub-level01 stepsSingle del-div item _jsPlumb_endpoint_anchor jsplumb-draggable" id="%ID%" style="display: block; top:%TOP%px; left:%LEFT%px;">';
            _nodeHtmlTemplate += '    <div class="tiny-drag-box-inner">';
            _nodeHtmlTemplate += '        <div class="tiny-drag-box-hdr">';
            _nodeHtmlTemplate += '            <div class="tiny-drag-action"></div>';
            _nodeHtmlTemplate += '        </div>';
            _nodeHtmlTemplate += '        <div class="tiny-drag-box-body">';
            _nodeHtmlTemplate += '            <h2 title="%NAME%">%NAME%</h2>';
            _nodeHtmlTemplate += '        </div>';
            _nodeHtmlTemplate += '        <div class="tiny-drag-box-footer">&nbsp;</div>';
            _nodeHtmlTemplate += '        <div class="clear"></div>';
            _nodeHtmlTemplate += '    </div>';
            _nodeHtmlTemplate += '</div>';
    
    var _initializeNewJsPlumbInstance = function(instance) {
        var basicType = {
            paintStyle: { strokeStyle: "red", lineWidth: 2 },
            hoverPaintStyle: { strokeStyle: "blue" },
            overlays: [
                "Arrow"
            ]
        };

        instance.registerConnectionType("basic", basicType);

        // suspend drawing and initialise.
        instance.batch(function () {});                             
    };

    var _getStartStep = function(stepName, steps) {
        for (var i = 0, len = steps.length; i < len; i++) {
            if (steps[i].id === stepName) return steps[i]; // Return as soon as the object is found
        }
        return null; // The object was not found
    }

    var _getInstanceByName = function(instanceName) {
        for (var i = 0, len = _jsPlumbInstances.length; i < len; i++) {
            if (_jsPlumbInstances[i].instanceName === instanceName) return _jsPlumbInstances[i]; // Return as soon as the object is found
        }
        return null; // The object was not found
    },
    _getWizardIndexById = function(wizardId) {
        for (var i = 0, len = _wizards.length; i < len; i++) {
            if (_wizards[i].wizardId === wizardId) return i; // Return as soon as the object is found
        }
        return null; // The object was not found
    },
    _getJsPlumbContainerContentIndex = function(placeholderContextId) {
        for(var i=0;i<_cachedContainers.length;i++) {
            if(_cachedContainers[i].placeholderContextId === placeholderContextId) return i;
        }

        return null
    },
    _getHeighestTopPosition = function() {
        var heighestVal = 0;

        _$jsPlumbCont.find(".tiny-drag-box.jsplumb-draggable").each(function(index, element){
            var pos = jQuery(element).position();
            if(pos.top > heighestVal) heighestVal = pos.top;
        });

        return heighestVal;
    },
    _resizeContainer = function() {
        heighestVal = _getHeighestTopPosition();

        _$jsPlumbCont.css('height', (heighestVal + 150));
    };

    _wizardBuilder.setContext = function(wizardID) {

        // if blank string passed then default to initial new wizard instance name
        if(wizardID === "") {
            wizardID = initialWizard;
        }

        var prevWizardId = null;
        
        if(_$jsPlumbCont !== null) {
            // get previous canvas container
            var $parentCont = _$jsPlumbCont.parent().parent();
            prevWizardId = $parentCont.data("tabid");

            // save/update previous container
            var containerIndex = _getJsPlumbContainerContentIndex(prevWizardId);
            
            if(prevWizardId !== null && containerIndex === null) {
                // insert new array entry
                _cachedContainers.push({
                    placeholderContextId:prevWizardId,
                    content:_$jsPlumbCont.children()
                });

                containerIndex = _cachedContainers.length - 1;
            } else {
                // update existing container contents
                _cachedContainers[containerIndex].content = _$jsPlumbCont.children();
            }
        }

        // get current wizard container
        _$jsPlumbCont = jQuery("div[data-tabid='" + wizardID + "']")
                            .find(".tiny-drag-drop-area-outr");

        
        _resizeContainer();
		jsPlumb.setContainer(_$jsPlumbCont);
		
        // _instance = jsPlumb.getInstance({
                        // // default drag options
                        // DragOptions: { cursor: 'pointer', zIndex: 2000 },
                        // // the overlays to decorate each connection with.  note that the label overlay uses a function to generate the label text; in this
                        // // case it returns the 'labelText' member that we set on each connection in the 'init' method below.
                        // ConnectionOverlays: [
                            // [ "Arrow", { location: 1 } ],
                            // [ "Label", {
                                // location: 0.1,
                                // id: "label",
                                // cssClass: "aLabel"
                            // }]
                        // ],
                        // Container:_$jsPlumbCont
                    // });

        var wizardElementIndex = _getWizardIndexById(wizardID);

        if(wizardElementIndex !== null) {
            _wizardBuilder.build(_wizards[wizardElementIndex].wizardData);
        }

/*

        // retrieve current container
        var containerIndex = _getJsPlumbContainerContentIndex(wizardID);

        jsPlumb.deleteEveryEndpoint();
        _$jsPlumbCont.empty();
        if(containerIndex !== null) {
            _$jsPlumbCont.append(_cachedContainers[containerIndex].content);
        }

*/      
        
    }

    _wizardBuilder.connectionInContext = null;

    var _attachEvents = function() {
        // clear all events
        jsPlumb.unbind();
        
        // listen for new connections; initialise them the same way we initialise the connections at startup.
        jsPlumb.bind("connection", function (connInfo, originalEvent) {
            if(_isMovingConnection) { 
                _isMovingConnection= false;
                return;
            }
            _wizardBuilder.connectionInContext = connInfo.connection;

            connInfo.connection.getOverlay("label").setLabel("<div class='rule-set-button' id='ruleset"+connInfo.connection.sourceId.substring(15) + "-" + connInfo.connection.targetId.substring(15)+"' data-sourceid='" + connInfo.connection.sourceId + "' data-targetid='" + connInfo.connection.targetId + "'>Edit Rule</div>");

            if(!_building) {
                isNew = true;

                var connectType = 'Go To Step';
                if(connInfo.connection.targetId.indexOf('_defaultStepSubmit') !== -1) {
                    connectType = 'Go To Submit';
                } else if(connInfo.connection.targetId.indexOf('_defaultStepPage') !== -1) {
                    connectType = 'Go To URL';
                } 

                addStepNavigation(connInfo.sourceId, connInfo.targetId, connectType);
                sourceNode = connInfo.sourceId;
                targetNode = connInfo.targetId;
            }
        });
        
        jsPlumb.bind("connectionMoved", function (info, originalEvent) {
            _isMovingConnection = true;
            _wizardBuilder.connectionInContext = info.connection;
            onBeforeRulePopup(info.connection.sourceId, info.connection.getParameter('rulesetId'));
        });

        jsPlumb.bind("connectionDetached", function (info, originalEvent) {
            deleteStepNavigation(info.connection.sourceId, info.connection.getParameter("rulesetId"));
        });

        jsPlumb.bind("click", function(connection, originalEvent) { 
            if(_building) return;

            _wizardBuilder.connectionInContext = connection;
            onBeforeRulePopup(connection.sourceId, connection.getParameter('rulesetId'));
        });
    };

    _wizardBuilder.setContext(initialWizard);

    //_initializeNewJsPlumbInstance(jsPlumb);

    _wizardBuilder.renderNewStep = function(stepID, $sectemp, ui) {
        var newState = $sectemp.attr('id', stepID).addClass('item').addClass("jsplumb-draggable");

        _$jsPlumbCont.append(newState);

        $of = _$jsPlumbCont.offset();
        _$jsPlumbCont.find(".tiny-drag-box.del-div:last").hide();
        _$jsPlumbCont.find(".tiny-drag-box.del-div:last").css({"top":(ui.offset.top-$of.top),"left":(ui.offset.left-$of.left)});
        _$jsPlumbCont.find(".tiny-drag-box.del-div:last").fadeIn();

        _addEndpoints(stepID, ["BottomLeft", "BottomCenter", "BottomRight"], ["TopLeft", "TopCenter", "TopRight"]);

        // make all the window divs draggable
        jsPlumb.draggable(jsPlumb.getSelector(".tiny-drag-drop-area-outr .tiny-drag-box"), { grid: [20, 20] });

        // method, or document.querySelectorAll:
        jsPlumb.draggable(document.querySelectorAll(".tiny-drag-box"), { grid: [20, 20] });

        var height = _getHeighestTopPosition();

        _$jsPlumbCont.animate({
                height: (height + 150) + "px"
            }, 500);
    };

    _wizardBuilder.build = function(wizard) {
        _row = 0;
        _currentColumnPosition = [0];
        _renderedSteps = [];

        if(wizard !== null && wizard.steps !== null) {
            var wizardElementIndex = _getWizardIndexById(wizard.placeholderId);

            if(wizardElementIndex !== null) {
                _wizards[wizardElementIndex].wizardData = wizard;
            } else {
                _wizards.push({
                    wizardId: wizard.placeholderId,
                    wizardData:wizard
                });
            }
            
            var startStep = _getStartStep(wizard.startStep, wizard.steps);
			
			if(startStep === null) return;
			
            jsPlumb.reset();
			_$jsPlumbCont.empty();

			_attachEvents();

			_building = true;

			// add start step to canvas
			var stepAdded = _drawStep(startStep);

			if(stepAdded !== null) {
				var stepId = stepAdded[0].id;
				stepAdded.find(".tiny-drag-box-body").append("<i class='delete-wiz-icon tooltip'></i>");
				stepAdded.find(".delete-wiz-icon").on("click", function(){
					deleteStepFromWizard(stepId);
				});
			}
			
			var result = {
				hasChildren: false,
				submitActionSteps: [],
				urlActionSteps: []
			};

			_drawChildren(wizard, startStep, result);
			
			// draw all remaining unlinked steps on second row
			_row++;
			
			jQuery.each(wizard.steps, function(index, step) {
				stepAdded = _drawStep(step);
				if(stepAdded !== null) {
					var stepId = stepAdded[0].id;
					stepAdded.find(".tiny-drag-box-body").append("<i class='delete-wiz-icon tooltip'></i>");
					stepAdded.find(".delete-wiz-icon").on("click", function(){
						deleteStepFromWizard(stepId);
					});
				}
			});
			
			// draw default Submit and Page steps
			if(result.hasChildren) _row++;

			_submitAndPageStepCount++;

			_drawStep({id:"_defaultStepSubmit" + _submitAndPageStepCount, name:"Submit"}, true, false);
			_drawStep({id:"_defaultStepPage" + _submitAndPageStepCount, name:"Page"}, true, false);

			for (var i = 0; i < result.submitActionSteps.length; i++) {
				_connectNodes(jsPlumb, 
					result.submitActionSteps[0].stepId, 
					"_defaultStepSubmit" + _submitAndPageStepCount, 
					{ rulesetId: result.submitActionSteps[0].rulesetId });
			}
			
			for (var i = 0; i < result.urlActionSteps.length; i++) {
				_connectNodes(jsPlumb, 
					result.urlActionSteps[0].stepId, 
					"_defaultStepPage" + _submitAndPageStepCount, 
					{ rulesetId: result.urlActionSteps[0].rulesetId });
			}


			// make all the window divs draggable
			jsPlumb.draggable(jsPlumb.getSelector(".tiny-drag-drop-area-outr .tiny-drag-box"), { grid: [20, 20] });

			// method, or document.querySelectorAll:
			jsPlumb.draggable(document.querySelectorAll(".tiny-drag-box"), { grid: [20, 20] });

			_resizeContainer();

			_building = false;
        }
    }

    var _addEndpoints = function (toId, sourceAnchors, targetAnchors) {
        for (var i = 0; i < sourceAnchors.length; i++) {
            var sourceUUID = toId + sourceAnchors[i];
            jsPlumb.addEndpoint(toId, sourceEndpoint, {
                anchor: sourceAnchors[i], uuid: sourceUUID
            });
        }
        for (var j = 0; j < targetAnchors.length; j++) {
            var targetUUID = toId + targetAnchors[j];
            jsPlumb.addEndpoint(toId, targetEndpoint, { anchor: targetAnchors[j], uuid: targetUUID });
        }
    };
    
    var _drawChildren = function(wizard, step, result) {
        _row++;
        
        jQuery.each(step.rulesets, function(index, ruleset) {
            jQuery.each(wizard.steps, function(index, currentStep) {
                if(ruleset.nextAction !== '' && currentStep.id === ruleset.nextAction) {
                    result.hasChildren = true;

                    stepAdded = _drawStep(currentStep);

                    if(stepAdded !== null) {
                        var stepId = stepAdded[0].id;
                        stepAdded.find(".tiny-drag-box-body").append("<i class='delete-wiz-icon tooltip'></i>");
                        stepAdded.find(".delete-wiz-icon").on("click", function(){
                            deleteStepFromWizard(stepId);
                        });
                    }

                    jsPlumb.connect({
                        source:step.id,
                        target:currentStep.id,
                        anchor:["BottomLeft", "Bottom", "BottomRight", "TopLeft", "Top", "TopRight"],
                        connector:sourceEndpoint.connector,
                        paintStyle: sourceEndpoint.paintStyle,
                        hoverPaintStyle: sourceEndpoint.hoverPaintStyle,
                        //endpointStyle: sourceEndpoint.paintStyle,
                        editable: true,
                        parameters: {
                            rulesetId: ruleset.placeholderId
                        }
                    });
                    
                    _drawChildren(wizard, currentStep, result);
                } else if("nextActionType" in ruleset
                    && ruleset.nextActionType === "Go To Submit") {
                    result.submitActionSteps.push({
                        stepId:step.id,
                        rulesetId:ruleset.placeholderId
                    });
                } else if("nextActionType" in ruleset
                    && ruleset.nextActionType === "Go To URL") {
                    result.urlActionSteps.push({
                        stepId:step.id,
                        rulesetId:ruleset.placeholderId
                    });
                }
            });
        });
        
        _row--;

    },
    _connectNodes = function(_instance, sourceStepId, targetStepId, parameters) {
        jsPlumb.connect({
            source:sourceStepId,
            target:targetStepId,
            anchor:["BottomLeft", "Bottom", "BottomRight", "TopLeft", "Top", "TopRight"],
            connector:sourceEndpoint.connector,
            paintStyle: sourceEndpoint.paintStyle,
            hoverPaintStyle: sourceEndpoint.hoverPaintStyle,
            editable: true,
            parameters: parameters
        });
    },
    _drawStep = function(step, includeTopEndPoints, includeBottomEndPoints) {
        includeTopEndPoints = typeof includeTopEndPoints !== 'undefined' ? includeTopEndPoints : true;
        includeBottomEndPoints = typeof includeBottomEndPoints !== 'undefined' ? includeBottomEndPoints : true;

        // check if step already rendered
        stepIndex = jQuery.inArray(step.id, _renderedSteps);

        if(_row > _currentColumnPosition.length - 1) _currentColumnPosition.push(0);

        if ( !~stepIndex ) {
            var _stepHtml = _nodeHtmlTemplate.replace(/%NAME%/g, step.name);
            _stepHtml = _stepHtml.replace(/%ID%/, step.id);
            _stepHtml = _stepHtml.replace(/%TOP%/, _position.top + (_row * 200));
            _stepHtml = _stepHtml.replace(/%LEFT%/, _position.left + _currentColumnPosition[_row]);
            
            var newState = jQuery(_stepHtml).appendTo(_$jsPlumbCont);
			
            $of = _$jsPlumbCont.offset();
            //alert(step.name + ' = ' + includeBottomEndPoints + ' - ' + includeTopEndPoints);
            _addEndpoints(step.id, (includeBottomEndPoints ? ["BottomLeft", "BottomCenter", "BottomRight"] : []), (includeTopEndPoints ? ["TopLeft", "TopCenter", "TopRight"] : []));

            // add step to list of rendered steps
            _renderedSteps.push(step.id);
            _currentColumnPosition[_row] += 250;

            return newState;
        };
        return null;
    };

    return _wizardBuilder;
};