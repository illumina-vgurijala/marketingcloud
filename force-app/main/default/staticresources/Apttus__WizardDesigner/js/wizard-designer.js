/**
 * Created by igallagher on 10/13/2015.
 */
;(function ( $, window, document, undefined ) {

    function requiredFieldStatusControl (options) {
        // use default empty function if none specified
        options['onStatusChange'] = (options['onStatusChange'] === undefined ?
            function(event, hasValue, $link, originalClickEvent) {} : options['onStatusChange']);

        var origEvent = options['$link'][0].onclick,
            originalEvents = [],
            changeButtonStatus = function(event, hasValue, $link, originalClickEvent) {

                if(hasValue) {
                    options['onStatusChange'](event, hasValue, $link, originalClickEvent);
                    UtilWizard.enableLink($link, originalClickEvent);
                } else {
                    options['onStatusChange'](event, hasValue, $link, originalClickEvent);
                    UtilWizard.disableLink($link);
                }

                $.each(options['relatedTabs'], function( index, value ) {
                    if(hasValue) {
                        UtilWizard.enableLink(value, originalEvents[index]);
                    } else {
                        UtilWizard.disableLink(value);
                    }
                });
            };

        // retrieve original click event of each tab and store
        $.each(options['relatedTabs'], function( index, value ) {
            originalEvents.push(value[0].onclick);
        });

        $(".required.text").requiredText({
            onFieldStatusChange: function(event, hasValue) {
                changeButtonStatus(event,
                    hasValue,
                    options['$link'],
                    origEvent);

            }
        });
    }
    window['requiredFieldStatusControl'] = requiredFieldStatusControl;



    function inputFieldTypeSection (options) {
        var defaults = {
            'ddlFieldClassDefaultValue': '',
            'ddlResDataTypeDefaultValue': '',
            'ddlObjectNameDefaultValue': '',
            'ddlFieldNameDefaultValue': '',
            'isListSearchString': ''
        };

        var settings = $.extend( {}, defaults, options );

        var onFieldTypeChange = function(fieldNameVal) {
            if(fieldNameVal != null
                && fieldNameVal != settings['ddlFieldNameDefaultValue']
                && fieldNameVal != settings['ddlResDataTypeDefaultValue']
                && fieldNameVal.indexOf(settings['isListSearchString']) > -1){ // is selected field name type list?
                settings['$liPicklistItems'].show();
            } else {
                settings['$liPicklistItems'].hide();
            }
        };

        var onObjectNameChange = function() {
            if(settings['$ddlObjectName'].val() != settings['ddlObjectNameDefaultValue']) { // has value selected?
                settings['$liFieldName'].show();

                //onFieldTypeChange(settings['$ddlFieldName'].val());
            } else {
                settings['$liFieldName'].hide();
                settings['$ddlFieldName'].val(settings['ddlFieldNameDefaultValue']).change();

                //settings['$liPicklistItems'].hide();
                //settings['$txtPicklistItems'].val('').change();
            }
        };

        var onFieldClassChange = function() {
            if(settings['$ddlFieldClass'].val() == settings['ddlFieldClassDefaultValue']){
                // hide and reset all controls to defaults
                settings['$liResDataType'].hide();
                settings['$ddlResDataType'].val(settings['ddlResDataTypeDefaultValue']).change();


                settings['$liObjectName'].hide();
                settings['$ddlObjectName'].val(settings['ddlObjectNameDefaultValue']).change();

                settings['$liFieldName'].hide();
                settings['$ddlFieldName'].val(settings['ddlFieldNameDefaultValue']).change();

                settings['$liPicklistItems'].hide();
                settings['$txtPicklistItems'].val('').change();
            } else if(settings['$ddlFieldClass'].val() == settings['ddlFieldClassObjectFieldValue']) { // display object field value controls
                // hide and reset data type field
                settings['$liResDataType'].hide();
                settings['$ddlResDataType'].val(settings['ddlResDataTypeDefaultValue']).change();

                settings['$liObjectName'].show();

                onObjectNameChange();
            } else if(settings['$ddlFieldClass'].val() == settings['ddlFieldClassInputFieldValue']) { // display wizard field value controls
                settings['$liObjectName'].hide();
                settings['$ddlObjectName'].val(settings['ddlObjectNameDefaultValue']).change();
                settings['$liResDataType'].show();

                onFieldTypeChange(settings['$ddlResDataType'].val());
            }
        };

        settings['$ddlFieldClass'].on("change", onFieldClassChange);
        settings['$ddlObjectName'].on("change", onObjectNameChange);
        settings['$ddlFieldName'].on("change", function(){
            onFieldTypeChange($(this).val());
        });
        settings['$ddlResDataType'].on("change", function(){
            onFieldTypeChange($(this).val());
        });

        // trigger initial change event for setup
        onFieldClassChange();
    }
    window['inputFieldTypeSection'] = inputFieldTypeSection;

    var sourceListItemId;
    window['sourceListItemId'] = sourceListItemId;
    
    function sortableList(options, $) {
        var $sortableList = $( "#" + options['sortableListId'] ),
            sourceIndex = -1,
            isFromLibrary = false,
            $maxLastPositionElement = (!options['cancelDropAfter'] ? null : $sortableList.find(options['cancelDropAfter']));

        $sortableList.droppable({accept: "#" + options['libraryListId'] + " li"}).sortable({
            start: function(event, ui){
                sourceIndex = ui.item.index();
            },
            receive: function(event, ui) {
                isFromLibrary = true;
            },
            update: function(event, ui) {
                var targetIndex = ui.item.index(),
                    maxIndex = -1,
                    widget;

                if($maxLastPositionElement != null) {
                    maxIndex = $maxLastPositionElement.index();

                    if(maxIndex >= 0 && targetIndex > maxIndex) {
                        ui.item.insertBefore($maxLastPositionElement);

                        // refresh widget after repositioning list element
                        widget = $sortableList.data("ui-sortable");
                        if (widget) widget._trigger("update", null, widget._uiHash(widget));

                        return;
                    }
                }

                if(isFromLibrary) {
                    isFromLibrary = false;

                    $sortableList.find('.empty-placeholder').remove();

                    options['onSortListChange'](event, ui, {
                        "targetIndex": targetIndex,
                        "sourceIndex": null,
                        "sourceItemId": window['sourceListItemId'],
                        "action": "clone"
                    });

                } else {
                    $sortableList.find('.empty-placeholder').remove();

                    options['onSortListChange'](event, ui, {
                        "targetIndex": ui.item.index(),
                        "sourceItemId": ui.item[0].id,
                        "sourceIndex": sourceIndex,
                        "action": "reorder"
                    });

                }
            },
            over: function(event, ui) {
                $sortableList.find('.empty-placeholder').hide();
            },
            out: function(event, ui) {
                $sortableList.find('.empty-placeholder').show();
            },
            stop: function(event, ui) {
                $sortableList.find('.empty-placeholder').remove();
            },
            cancel: '.std-step-cont',
            handle: ".handle",
        }).disableSelection();
    }
    window['sortableList'] = sortableList;

    function draggableClonableList(options, $) {
        var $draggableList = $( "#" + options['libraryListId'] + " li" );

        $draggableList.draggable({
            helper: "clone",
            connectToSortable: '#' + options['sortableListId'],
            start: function(event, ui) {
                $(ui.helper).addClass("ui-draggable-helper");
                window['sourceListItemId'] = ui.helper.prevObject[0].id;
                //ui.helper.context.id;
            }
        });
    }

    window['draggableClonableList'] = draggableClonableList;

    function highlightableList (options) {
        $(options['listSelector']).on("mouseover", function(){
            var $liEle = $(this),
                $moveIcon = $liEle.find(".move-icon"),
                $handle = $liEle.find(".handle"),
                $textData = $liEle.find(".text-data"),
                totalBtnWidth = 0;

            $liEle.addClass("mouse-over");

            $liEle.find(".controls a").each(function( index ) {
                totalBtnWidth += $(this).outerWidth();
            });

            totalBtnWidth += $moveIcon.outerWidth();

            $textData.width($liEle.width() - totalBtnWidth);
        });
        $(options['listSelector']).on("mouseout", function(){
            var $liEle = $(this),
                $textData = $liEle.find(".text-data");

            $liEle.removeClass("mouse-over");
            $textData.width("auto");
        });
    }
    window['highlightableList'] = highlightableList;


    function inputFormValidation (options) {
        var origEvent = options['$saveInputFormLink'][0].onclick,
            originalEvents = [],
            $txtInputName = $(options['txtInputName']),
            $ddlInputFieldClass = $(options['ddlInputFieldClassEnabled']),
            $ddlInputFieldName = $(options['ddlInputFieldName']),
            $ddlInputResponseDataType = $(options['ddlInputResDataType']),
            $txtInputPicklistItems = $(options['txtInputPicklistItems']),
            $ddlInputObjectName = $(options['ddlInputObjectName']),
            OBJECT_FIELD = options['OBJECT_FIELD'],
            WIZARD_INPUT_FIELD = options['WIZARD_INPUT_FIELD'],
            TYPE_PICKLIST = options['TYPE_PICKLIST'],
            TYPE_MULTIPICKLIST = options['TYPE_MULTIPICKLIST'],
            TYPE_PICKLIST_RADIO_BUTTON = options['TYPE_PICKLIST_RADIO_BUTTON'],
            inputFormIsValid = function(event, changeInfo) {
                var fieldClassVal = $ddlInputFieldClass.val(),
                    responseDataTypeVal = $ddlInputResponseDataType.val();

                if(UtilWizard.isNullOrEmpty($txtInputName.val()) || UtilWizard.isNullOrEmpty(fieldClassVal) || fieldClassVal == '--None--') {
                    return false;

                } else if(fieldClassVal == OBJECT_FIELD
                    && (UtilWizard.isNullOrEmpty($ddlInputObjectName.val()) || UtilWizard.isNullOrEmpty($ddlInputFieldName.val()))
                    || ($ddlInputObjectName.val() == '-- NONE --' || $ddlInputFieldName.val() == '-- NONE --')) {
                    return false;

                } else if(fieldClassVal == WIZARD_INPUT_FIELD) {
                    if(UtilWizard.isNullOrEmpty(responseDataTypeVal)) {
                        return false;

                    } else {
                        if((responseDataTypeVal == TYPE_PICKLIST
                            || responseDataTypeVal == TYPE_PICKLIST_RADIO_BUTTON
                            || responseDataTypeVal == TYPE_MULTIPICKLIST) &&
                            UtilWizard.isNullOrEmpty($txtInputPicklistItems.val())) {
                            return false;

                        }

                    }

                }

                return true;
            },
            formFieldUpdated = function(event, changeInfo) {
                var formValid = inputFormIsValid(event, changeInfo);
                if(!formValid) {
                    UtilWizard.disableLink(options['$saveInputFormLink']);
                } else {
                    UtilWizard.enableLink(options['$saveInputFormLink'], origEvent);
                }

                $.each(options['relatedTabs'], function( index, value ) {
                    if(formValid) {
                        UtilWizard.enableLink(value, originalEvents[index]);
                    } else {
                        UtilWizard.disableLink(value);
                    }
                });
            };

        // retrieve original click event of each tab and store
        $.each(options['relatedTabs'], function( index, value ) {
            originalEvents.push(value[0].onclick);
        });

        $txtInputName.activeChangeNotification({
            onFieldChange: formFieldUpdated
        });

        $ddlInputFieldClass.activeChangeNotification({
            onFieldChange: formFieldUpdated
        });

        $ddlInputResponseDataType.activeChangeNotification({
            onFieldChange: function(event, changeInfo) {
                formFieldUpdated(event, changeInfo);
                options['onInputControlDetailChange']();
            }
        });

        $txtInputPicklistItems.activeChangeNotification({
            onFieldChange: formFieldUpdated
        });

        $ddlInputObjectName.activeChangeNotification({
            onFieldChange: formFieldUpdated
        });

        this.rebindFieldName = function(){
            $ddlInputFieldName = $(options['ddlInputFieldName']);

            $ddlInputFieldName.activeChangeNotification({
                onFieldChange:  function(event, changeInfo) {
                    formFieldUpdated(event, changeInfo);
                    options['onInputControlDetailChange']();
                }
            });
        };

        this.rebindFieldName();

        $txtInputPicklistItems.on("change", function(){
            options['onInputControlDetailChange']();
        });

        // trigger field update on load
        formFieldUpdated();

        return this;
    }
    window['inputFormValidation'] = inputFormValidation;

    function searchableList($searchInput) {
        var $outerContainer = $searchInput.closest(".side-pane"),
            $searchableList = $outerContainer.find(".draggable-list");

        function compLibStepsSearch(searchText) {
            $searchableList.find("li").each(function(i,v) {
                var boxTitle = $(this).attr('search-text').toLowerCase();
                if (boxTitle.length) {
                    if (boxTitle.indexOf(searchText.toLowerCase()) >= 0) {
                        $(this).closest("li").stop(true,
                            true).show();
                    } else {
                        $(this).closest("li").stop(true,
                            true).hide();
                    }
                }
            });
        }

        $searchInput.on("keyup",function() {
            var str = $.trim($searchInput.val().toLowerCase());
            compLibStepsSearch(str);
        });
    }
    window['searchableList'] = searchableList;


    function dynamicLabelUpdater(options) {
        options['$txtField'].on("keyup DOMAttrModified propertychange change input", function() {
            // dynamically update breadcrumb as user edits wizard name
            var txtFieldVal = options['$txtField'].val(),
                defaultValue = options['$fieldLabel'].html();

            if(txtFieldVal === null || txtFieldVal === '') {
                options['$fieldLabel'].html(options['defaultNewValue']);
                return;
            }

            options['$fieldLabel'].text(txtFieldVal);


        });

    }
    window['dynamicLabelUpdater'] = dynamicLabelUpdater;

    window['promptConfirmDialog'] = function(options) {
        var settings,
            defaults = {
                onConfirm: function() {},
                onCancel: function() {},
                promptMessageText: "",
                alert: "",
                autoOpen: true,
                closeOnEscape: false,
                minWidth: 500,
                modal: true,
                position: {my: "center"},
                draggable: false,
                resizable: false,
                buttons: [
                    {
                        text: "Activate",
                        "class": "secondary-ctrl default",
                        click: function () {
                            settings.onConfirm();
                            $(this).dialog("close").dialog('destroy');

                        }
                    },
                    {
                        text: "Cancel",
                        "class": "secondary-ctrl",
                        click: function () {
                            settings.onCancel();
                            $(this).dialog("close").dialog('destroy');
                        }
                    }

                    ]
                };

        // deep merge user settings with defaults
        settings = $.extend( true, defaults, options );

        var dialogHtmlContent = '<div class="wizardItemAddWarning wizard--dialog"><div class="content"><i class="fa fa-exclamation-triangle warn--icon"></i><div class="content--header">' + settings.alert + '</div><div class="content--text">' + settings.promptMessageText + '</div></div></div>';

        // generate jQuery UI dialog and return handle
        var $dialog = $(dialogHtmlContent).dialog(settings);

        return $dialog;
    };

    window['promptSimpleAlert'] = function(options) {
        var settings,
            defaults = {
                onOkay: function(){},
                alertMessage: "Alert!",
                autoOpen: true,
                closeOnEscape: false,
                minWidth: 500,
                modal: true,
                position: { my: "center" },
                draggable: false,
                resizable: false,
                buttons: [
                    {
                        text: "OK",
                        class: "secondary-ctrl default",
                        click: function() {
                            settings.onOkay();
                            $( this ).dialog('close').dialog('destroy');
                        }
                    }
                ]
            };

        // deep merge user settings with defaults
        settings = $.extend( true, defaults, options );

        var dialogHtmlContent = '<div class="activation--dlg wizard--dialog"><div class="content"><i class="fa fa-exclamation-triangle warn--icon"></i><div class="content--text">' + settings.alertMessage + '</div></div></div>';

        // generate jQuery UI dialog and return handle
        var $dialog = $(dialogHtmlContent).dialog(settings);

        return $dialog;
    };

}(jQuery, window, document, undefined));


/*****      INLINE SCRIPT FROM PAGE      ******/
var clearCanvas = function(container) {
    var canvas = j$('.' + container +'--container');
    j$(canvas).empty();
    jsPlumb.reset();
}

var _renderSteps = function(wizard) {
    var wizard = JSON.parse(wizard),
        steps = wizard.Steps;

    clearCanvas('workflow');

    j$.each(steps, function(index) {
        var ul = j$('<ul class="step"></ul>'),
            stepHead = j$('<li class="step--head"></li>'),
            stepTitle = 'step: ' + steps[index].Name,
            exitNodeFlag = steps[index].Id === '0' || steps[index].Id === '1';

        j$(ul).attr('id', 'step--' + index);
        j$(stepHead).attr('id', steps[index].Id);
		j$(stepHead).attr('title', steps[index].Name);

        j$(stepHead).append(stepTitle);
        exitNodeFlag && j$(stepHead).addClass('step--exit');
        steps[index].Id === '1' && j$(stepHead).addClass('step--submit');
        steps[index].Id === '0' && j$(stepHead).addClass('step--abort');

        j$(ul).append(stepHead);

        // Draw Rules Blocks except for exit nodes
        if(!exitNodeFlag) {

            if(steps[index].Rulesets.length !== 0) {
                j$.each(steps[index].Rulesets, function(idx) {
                    var dataNxtId = '',
                        rule = {},
                        ruleTitle = '',
                        x = index + 1,
                        y = idx + 1;

                    rule = j$('<li class="step--rule"></li>');
                    ruleTitle += '<span class="rule--title"><span class="index">' + x + '.' + y + '</span>' + '<span class="goto">goto</span> ';
                    ruleTitle += '<span class="title--text">' + steps[index].Rulesets[idx].NextStepName + '</span></span>';

                    // ruleTitle = 'goto ' + steps[index].rulesets[idx].nextStepName;
                    j$(rule).append(ruleTitle);
                    rule.attr('id', steps[index].Rulesets[idx].Id);

                    // dataNxtId = (steps[index].rulesets[idx].nextActionType !== 'Go To Submit') ? steps[index].rulesets[idx].nextAction : 'step__submit';
                    dataNxtId = steps[index].Rulesets[idx].NextAction;
                    rule.attr('data-next-id', dataNxtId);
                    j$(ul).append(rule);
                });
            }

            else {
                var dataNxtId = '',
                    rule = {},
                    ruleTitle = '';

                rule = j$('<li class="step--rule"></li>');
                ruleTitle += '<span class="rule--title"><i class="fa fa-exclamation-circle pre-icon"></i><span class="goto">goto</span> ';
                ruleTitle += '<span class="title--text">' + getCustomLabels().DefaultRule + '</span></span>';

                rule.addClass('default--rule');
                rule.append(ruleTitle);
                rule.attr('id', 'default_rule_' + index);
                j$(ul).append(rule);
            }

        }

        j$('.workflow--container').append(ul);
    });

    // _appendExitNodes();
    _connectNodes();
    _addActionButtons(wizard);
    _bindEvents(wizard);
}

var _connectNodes = function() {
    var rulesList = j$('.step--rule'),
        stub = 20,
        container = j$('.workflow--container');

    jsPlumb.ready(function() {

        jsPlumb.setContainer(container);

        j$.each(rulesList, function(index) {
            var currentNodeId = j$( this ).attr('id'),
                anchorDirs = [],
                connector = [];

            if(j$(this).hasClass('default--rule')) {
                var id = j$( this ).closest('.step').next('.step').find('.step--head').attr('id');
                anchorDirs = ["Bottom", "Top"];
                nextNodeId = j$('#' + id);
                connector = ["Straight"];
            }
            else {
                anchorDirs = (index % 2 === 0) ? ["LeftMiddle", "LeftMiddle"] : ["RightMiddle", "RightMiddle"];
                nextNodeId = j$( this ).attr('data-next-id');
                connector = ["Flowchart", { alwaysRespectStubs: true, stub: stub, cornerRadius: 3 }]
            }

            jsPlumb.importDefaults({
                ConnectionOverlays: [
                    [ "Arrow", { location: 1, width: 10, length: 10 } ]
                ]
            });

            jsPlumb.connect({
                source: currentNodeId,
                target: nextNodeId,
                anchors: anchorDirs,
                connector: connector,
                cssClass: "blueLine",
                endpointStyle: "blank"
            });
            if(stub >= 100) {
                stub -= 5;
            }
            else {
                stub += 10;
            }
        });
    });
}

var _addActionButtons = function(wizard) {
    if(!wizard.isReadonly) {
        var stepsDom = j$('.workflow--container .step');
        // Go through all the step blocks in the DOM
        j$.each(stepsDom, function() {
            var stepHead = j$( this ).find('.step--head'),
                stepRule = j$( this ).find('.step--rule'),
                addBtn = j$('<div class="step--add--btn fa fa-plus"></div>');

            stepHead.hasClass('step--exit') !== true && stepHead.append(addBtn);
            // Add action buttons to all the rules
            j$.each(stepRule, function() {
                var actionDiv = j$('<div class="rule--actions"><div class="rule--edit">' + getCustomLabels().Edit + '</div><div class="rule--delete">' + getCustomLabels().Delete + '</div></div>');
                if( j$(this).hasClass('default--rule') ) {
                    actionDiv = j$('<div class="rule--actions"><div class="rule--new">' + getCustomLabels().New + '</div></div>');
                }
                j$( this ).append(actionDiv);
            });
        });
    }
    else {
        var stepsDom = j$('.workflow--container .step');
        // Go through all the step blocks in the DOM
        j$.each(stepsDom, function() {
            var stepHead = j$( this ).find('.step--head'),
                stepRule = j$( this ).find('.step--rule');

            // Add View buttons to all non-default rules
            j$.each(stepRule, function() {
                var actionDiv = j$('<div class="rule--actions"><div class="rule--edit">' + getCustomLabels().View + '</div></div>');
                !j$(this).hasClass('default--rule') && j$( this ).append(actionDiv);
            });
        });
    }
}

var _afterRulesEdit = function(isStepRule, parentName) {
    var addRuleContent = j$('.addRuleContent');

    j$('.dialogContainer').dialog({
        autoOpen: true,
        resizable: false,
        closeOnEscape: false,
        minWidth: 800,
        modal: true,
        position: { my: "center" },
        draggable: false,
        open: function() {
            j$('.custom--titlebar .title--text').html(getCustomLabels().RuleFor + ' ' + parentName);
        }
    });
}


var _bindEvents = function(wizard) {

    // Add Step Rule Button Click Handler
    j$('.workflow--container').off('click', '.step--add--btn')
        .on('click', '.step--add--btn', function() {
            var stepId = j$( this ).closest('.step--head').attr('id');
            onStepRulesetCreate(stepId);
        });

    // New Step Rule Button Click Handler
    j$('.workflow--container').off('click', '.rule--new')
        .on('click', '.rule--new', function() {
            var stepId = j$( this ).closest('.step').find('.step--head').attr('id');
            onStepRulesetCreate(stepId);
        });

    // Add Input Rule Button Click Handler
    j$('.step--container').off('click', '.step--add--btn')
        .on('click', '.step--add--btn', function() {
            var inputId = j$( this ).closest('.step--head').attr('id');
            onInputRulesetCreate(inputId);
        });

    // New Input Rule Button Click Handler
    j$('.step--container').off('click', '.input--new')
        .on('click', '.input--new', function() {
            var inputId = j$( this ).closest('.step').find('.step--head').attr('id');
            onInputRulesetCreate(inputId);
        });

    // Edit Step Rule Button Click Event
    j$('.workflow--container').off('click', '.rule--edit')
        .on('click', '.rule--edit', function() {
            var ruleId = j$( this ).closest('.step--rule').attr('id'),
                stepId = j$( this ).closest('.step').find('.step--head').attr('id');
            onStepRulesetEdit(stepId, ruleId);
        });

    // Edit Input Rule Button Click Event
    j$('.step--container').off('click', '.input--edit')
        .on('click', '.input--edit', function() {
            var ruleId = j$( this ).closest('.step--input').attr('id'),
                inputId = j$( this ).closest('.step').find('.step--head').attr('id');
            onInputRulesetEdit(inputId, ruleId);
        });


    // Delete Step Rule Button Click Event
    j$('.workflow--container').off('click', '.rule--delete')
        .on('click', '.rule--delete', function() {
            var ruleId = j$( this ).closest('.step--rule').attr('id'),
                stepId = j$( this ).closest('.step').find('.step--head').attr('id');
            onStepRulesetDelete(stepId, ruleId);
        });

    // Edit Input Rule Button Click Event
    j$('.step--container').off('click', '.input--delete')
        .on('click', '.input--delete', function() {
            var ruleId = j$( this ).closest('.step--input').attr('id'),
                inputId = j$( this ).closest('.step').find('.step--head').attr('id');
            onInputRulesetDelete(inputId, ruleId);
        });

    var _afterRulesDelete = function() {
        // alert('After Step Delete is executed');
        onDeleteRule();
    }
}

var closeRulesetDialog = function(isError, isCancel, isStepRuleset, json, isReadonly) {
    if(isCancel) {
        j$('.dialogContainer').dialog('close').dialog("destroy");
    } else if(!isError) {
        j$('.dialogContainer').dialog('close').dialog("destroy");
        if(isStepRuleset) {
            _renderSteps(json);
        } else {
            _renderStepInputs(json, isReadonly);
        }
    } else {
        alert(getCustomLabels().FailedToSaveRuleset);
    }
}


var _renderStepInputs = function(step, isReadonly) {
    var step = JSON.parse(step),
        inputs = step.Inputs;

    clearCanvas('step');

    j$.each(inputs, function(index) {
        var ul = j$('<ul class="step extra--wide"></ul>'),
            stepHead = j$('<li class="step--head"></li>'),
            stepTitle = inputs[index].Name;

        j$(ul).attr('id', 'step--' + index);
        j$(stepHead).attr('id', inputs[index].Id);
		j$(stepHead).attr('title', stepTitle);

        j$(stepHead).append(stepTitle);
        j$(ul).append(stepHead);

        // Draw Input Blocks
        if(inputs[index].Rulesets.length !== 0) {
            j$.each(inputs[index].Rulesets, function(idx) {
                var input = {},
                    inputTitle = '',
                    x = index+1,
                    y = idx+1,
                    focusObj = ( inputs[index].Rulesets[idx].FocusObject !== null) ? inputs[index].Rulesets[idx].FocusObject : '',
                    objRecordType = ( inputs[index].Rulesets[idx].ObjectRecordType !== null) ? inputs[index].Rulesets[idx].ObjectRecordType : '';

                input = j$('<li class="step--input"></li>');
                inputTitle += '<span class="input--title"><span class="index">' + x + '.' + y + '</span>' + inputs[index].Rulesets[idx].RuleType + ' <span class="input--ctx">' + focusObj + '</span>' + ' <span class="input--ctx--type">' + objRecordType + '</span></span>';

                j$(input).attr('title', j$(inputTitle).text());
                j$(input).append(inputTitle);
                input.attr('id', inputs[index].Rulesets[idx].Id);
                j$(ul).append(input);
            });
        }

        else {
            var input = {},
                inputTitle = '';

            input = j$('<li class="step--input"></li>');
            inputTitle += '<span class="input--title"><i class="fa fa-exclamation-circle pre-icon"></i> ';
            inputTitle += '<span class="title--text">' + getCustomLabels().DefaultInput + '</span></span>';

            input.addClass('default--input');
            input.append(inputTitle);
            input.attr('id', 'default_input_' + index);
            j$(ul).append(input);
        }

        j$('.step--container').append(ul);
    });

    _addStepActionButtons(isReadonly);
    _bindEvents(step);
}

var _addStepActionButtons = function(isReadonly) {
    if(!isReadonly) {
        var stepsDom = j$('.step--container .step');
        // Go through all the step blocks in the DOM
        j$.each(stepsDom, function() {
            var stepHead = j$( this ).find('.step--head'),
                stepInput = j$( this ).find('.step--input'),
                addBtn = j$('<div class="step--add--btn fa fa-plus"></div>');

            stepHead.append(addBtn);
            // Add action buttons to all the inputs
            j$.each(stepInput, function() {
                var actionDiv = j$('<div class="input--actions"><div class="input--edit">' + getCustomLabels().Edit + '</div><div class="input--delete">' + getCustomLabels().Delete + '</div></div>');
                if( j$(this).hasClass('default--input') ) {
                    actionDiv = j$('<div class="input--actions"><div class="input--new">' + getCustomLabels().New + '</div></div>');
                }
                j$( this ).append(actionDiv);
            });
        });
    }
    else {
        var stepsDom = j$('.step--container .step');
        // Go through all the step blocks in the DOM
        j$.each(stepsDom, function() {
            var stepHead = j$( this ).find('.step--head'),
                stepInput = j$( this ).find('.step--input');

            // Add view buttons to all non-default inputs
            j$.each(stepInput, function() {
                var actionDiv = j$('<div class="input--actions"><div class="input--edit">' + getCustomLabels().View +'</div></div>');
                !j$(this).hasClass('default--input') && j$( this ).append(actionDiv);
            });
        });
    }

}

var promptFirstAdd = function() {

    if(!window.sessionStorage.getItem('warnedOnFirstDragDropInWizard')) {
        //TODO: alert('Warning');
        j$('.wizardItemAddWarning').dialog({
            autoOpen: true,
            closeOnEscape: false,
            minWidth: 500,
            modal: true,
            position: { my: "center" },
            draggable: false,
            resizable: false,
            buttons: [
                {
                    text: getCustomLabels().Ok,
                    "class": "secondary-ctrl default",
                    click: function() {
                        j$( this ).dialog('close').dialog("destroy");
                    }
                }
            ]
        });
        window.sessionStorage.setItem('warnedOnFirstDragDropInWizard', true);
    } else {
        return;
    }
}

var promptActivation = function(active) {
    j$("#promptActionDialog").dialog({
        autoOpen: true,
        closeOnEscape: false,
        minWidth: 500,
		modal: true,
        position: { my: "center" },
        draggable: false,
        resizable: false,
        buttons: [
            {
                text: getCustomLabels().Activate,
                "class": "secondary-ctrl default",
                click: function() {
                    onActivateWizard();
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return true;
                }
            },
            {
                text: getCustomLabels().Cancel,
                "class": "secondary-ctrl",
                click: function() {
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return false;
                }
            }

        ]
    });
    return false;
}

var promptDeactivation = function(active) {
    j$("#promptDeactionDialog").dialog({
        autoOpen: true,
        closeOnEscape: false,
        minWidth: 500,
        modal: true,
        position: { my: "center" },
        draggable: false,
        resizable: false,
        buttons: [
            {
                text: getCustomLabels().Deactivate,
                "class": "secondary-ctrl default",
                click: function() {
                    onDeactivateWizard();
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return true;
                }
            },
            {
                text: getCustomLabels().Cancel,
                "class": "secondary-ctrl",
                click: function() {
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return false;
                }
            }

        ]
    });
    return false;
}

var promptEditWarning = function(index) {
    j$('.edit--warning--dlg').dialog({
        autoOpen: true,
        closeOnEscape: false,
        minWidth: 500,
        modal: true,
        position: { my: "center" },
        draggable: false,
        resizable: false,
        buttons: [
            {
                text: getCustomLabels().Ok,
                "class": "secondary-ctrl default",
                click: function() {
                    onGotoStep(index);
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return true;
                }
            },
            {
                text: getCustomLabels().Cancel,
                "class": "secondary-ctrl",
                click: function() {
                    j$( this ).dialog( "close" ).dialog("destroy");
                    return false;
                }
            }

        ]
    });
    return false;
}

var onUserNavigate = function(action, wizardDesignId, wizardDesignName, wizardId, stepDesignId, stepDesignName) {
	var payload = { action: action, 
					data: { wizardDesignId: wizardDesignId, 
 						    wizardDesignName: wizardDesignName, 
						    wizardId: wizardId, 
						    stepDesignId: stepDesignId, 
						    stepDesignName: stepDesignName
						  } 
				  };
	switch(action) {
		case 'onwizardnext':
			if(!stepDesignId) {
				payload.data.stepDesignName = getCustomLabels().Review;
				
			}
			break;
			
	}
	
	try {
		window.parent.postMessage(JSON.stringify(payload), '*');
		
	} catch(ex) {
		console.log(ex.message);
	}
}

/* below function is added to override the standard salesforce function in main.js to fix the scroll issue
   we have when an filtered lookup is added on the Page
*/
ForeignKeyInputElement.prototype.afterLoad = function() {
    var a = !1,
        c = !!sfdcPage && sfdcPage.hasRun;
    if (this.referredDomIds)
        for (var b = this, d = 0; d < this.referredDomIds.length; d++) {
            var e = ForeignKeyInputElement.allElements[this.referredDomIds[d]];
            e ? (e.onChangeListeners.push(this), ForeignKeyInputElement.disableAndAddClearButton(e), a = a || e.blurred) : (e = getElementByIdCS(this.referredDomIds[d])) && addEvent(e, "change", function() {
                b.validate()
            })
        }
    this.initAutoComplete();    
    a && !c 
};