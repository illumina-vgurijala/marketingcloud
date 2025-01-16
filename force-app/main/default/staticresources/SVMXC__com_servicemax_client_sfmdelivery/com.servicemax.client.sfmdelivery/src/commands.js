/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function () {
    var sfmdeliverycommands = SVMX.Package("com.servicemax.client.sfmdelivery.commands");

    sfmdeliverycommands.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");

        sfmdeliverycommands.Class("GetPageLayout", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                if(request && request.additionalInfo && request.additionalInfo.targetId){
                    // With Checklists we get page layout from a field saved on the Checklist
                    // We know it is a checklist because we have additionalInfo with a targetId
                    // The PageLayout is stored on the SVMX.OrgNamespace + '__ChecklistMetaJSON__c' of a Checklist object
                    var childResponder = null;
                    var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
                    if(useJsr && useJsr === true){
                        childResponder = SVMX.create("com.servicemax.client.sfmdelivery.responders.GetExistingCheckListPageLayoutResponder",responder);
                    }else{
                        childResponder = childResponder = SVMX.create("com.servicemax.client.sfmdelivery.responders.GetExistingCheckListPageLayoutResponderOffline",responder);
                    }
                    var childRequest = {
                        recordId:request.recordId,
                        targetId:request.additionalInfo.targetId,
                        processId:request.processId,
                        qualify:false,
                        refreshData:false
                    };
                    this._executeOperationAsync(childRequest,childResponder,{
                        operationId:"SFMDELIVERY.GET_PAGEDATA"
                    });
                }else if(request && !request.processId && request.additionalInfo && request.additionalInfo.sfwActionType === "CHECKLIST"){
                    if(responder){
                        responder.result(this._generateStaticChecklistSelection());
                    }
                }else{
                    this._executeOperationAsync(request,responder,{
                        operationId:"SFMDELIVERY.GET_PAGELAYOUT"
                    });
                }
            },

            _generateStaticChecklistSelection: function () {
                var processTitle = TS.T("FSA002_TAG002", "Checklists");

                var layout = {
                    response: {
                        stringMap: [
                            {
                                value1: null,
                                value: "CHECKLIST LIST",
                                key: "PROCESSTYPE",
                                fieldsToNull: null
                        }
                    ],
                        sfmProcessType: "CHECKLIST LIST"
                    },
                    page: {
                        processTitle: processTitle,
                        header: {
                            sourceRecordId: null,
                            sections: [
                                {
                                    sectionDetail: {
                                        attributes: {
                                            type: SVMX.OrgNamespace + "__Page_Layout_Detail__c",
                                            url: "/services/data/v33.0/sobjects/SVMXC__Page_Layout_Detail__c/"
                                        },
                                        Name: "LIST_SECTION",
                                        Id: ""
                                    },
                                    fieldsToNull: null,
                                    fields: [
                                        {
                                            fieldsToNull: null,
                                            fieldEvents: [],
                                            fieldDetail: {
                                                attributes: {
                                                    type: SVMX.OrgNamespace + "__Page_Layout_Detail__c",
                                                    url: "/services/data/v33.0/sobjects/" + SVMX.OrgNamespace + "__Page_Layout_Detail__c/"
                                                },
                                                "Name": "LIST_SECTION_FIELD",
                                                "Id": "LIST_SECTION_FIELD_ID"
                                            },
                                            bubbleinfo: {
                                                response: {
                                                    tagId: null,
                                                    success: null,
                                                    stringMap: [],
                                                    StringLstMap: [],
                                                    stringFieldMap: [],
                                                    sobjectMap: [],
                                                    resultIds: [],
                                                    records: [],
                                                    profileData: null,
                                                    msgDetails: null,
                                                    messageType: null,
                                                    messages: [],
                                                    message: null,
                                                    MapStringMap: [],
                                                    lstQuestionBank: [],
                                                    lstFieldSetWithSorting: [],
                                                    lstChecklistInfo: [],
                                                    lstBizRuleInfo: [],
                                                    logMsg: null,
                                                    eventType: null,
                                                    docTemplate: null
                                                },
                                                fieldvalue: {
                                                    value1: null,
                                                    value: null,
                                                    key: null,
                                                    fieldsToNull: null
                                                },
                                                fieldapiname: null,
                                                bubbleinfo: []
                                            }
                                    }
                                ]
                            }
                        ],
                            pageEvents: [],
                            headerLayout: {
                                attributes: {
                                    type: SVMX.OrgNamespace + "__Page_Layout__c",
                                    url: "/services/data/v33.0/sobjects/" + SVMX.OrgNamespace + "__Page_Layout__c/xxxxxxxxxxxx"
                                },
                                "OwnerId": "",
                                "Name": "9999999999",
                                "LastModifiedDate": "2015-03-18T11:18:46.000+0000",
                                "LastModifiedById": "",
                                "IsDeleted": false,
                                "Id": "xxx",
                                "CreatedDate": "2015-03-01T12:58:46.000+0000",
                                "CreatedById": ""
                            },
                            "hdrLayoutId": "xxx",
                            "hdrData": null,
                            "fieldsToNull": null,
                            "enableAttachment": false,
                            "buttons": []
                        },
                        "fieldsToNull": null,
                        "details": [],
                        "businessRules": []
                    },
                    processTitle: processTitle
                };


                var sectionDetails = {
                    "__Field_Mapping__c": null,
                    "__Show_In_iPad__c": false,
                    "__Width__c": null,
                    "__Section__r": null,
                    "__Show_In_Web__c": false,
                    "__Related_Object_Name_Field__c": null,
                    "__Context_Source_Object__c": null,
                    "__Title__c": "List",
                    "__IsStandard__c": false,
                    "__Sequence__c": 1,
                    "__Section__c": null,
                    "__Page_Layout_Detail_Id__c": null,
                    "__Required__c": false,
                    "__Related_Object_Name__c": null,
                    "__Readonly__c": false,
                    "__Page_Layout__c": "",
                    "__Override_Related_Lookup__c": false,
                    "__Named_Search__c": null,
                    "__Named_Search__r": null,
                    "__Lookup_Query_Field__c": null,
                    "__Lookup_Context__c": null,
                    "__Field_API_Name__c": "Virtual_Field_1",
                    "__Display_Row__c": null,
                    "__Display_Column__c": null,
                    "__Detail_Type__c": "Section",
                    "__DataType__c": null,
                    "__No_Of_Columns__c": 1,
                    "__Enable_Chatter__c": false,
                    "__Control_Type__c": "Standard",
                    "__Maximum_Value__c": null,
                    "__Minimum_Value__c": null,
                    "__Use_For_SLA_Clock__c": false,
                    "__Enable_Comments__c": false,
                    "__Expression__c": null,
                    "__Question__c": null,
                    "__QuestionInfoJSON__c": null
                };

                var fieldDetail = {
                    "__Field_Mapping__c": null,
                    "__Show_In_iPad__c": false,
                    "__Width__c": null,
                    "__Section__r": {
                        attributes: {
                            type: SVMX.OrgNamespace + "__Page_Layout_Detail__c",
                            url: "/services/data/v33.0/sobjects/" + SVMX.OrgNamespace + "__Page_Layout_Detail__c/"
                        }
                    },
                    "__Show_In_Web__c": false,
                    "__Related_Object_Name_Field__c": null,
                    "__Context_Source_Object__c": null,
                    "__Title__c": null,
                    "__IsStandard__c": false,
                    "__Sequence__c": 1,
                    "__Section__c": "",
                    "__Page_Layout_Detail_Id__c": null,
                    "__Required__c": false,
                    "__Related_Object_Name__c": null,
                    "__Readonly__c": false,
                    "__Page_Layout__c": "",
                    "__Override_Related_Lookup__c": false,
                    "__Named_Search__c": null,
                    "__Named_Search__r": null,
                    "__Lookup_Query_Field__c": null,
                    "__Lookup_Context__c": null,
                    "__Field_API_Name__c": null,
                    "__Display_Row__c": null,
                    "__Display_Column__c": null,
                    "__Detail_Type__c": "List",
                    "__DataType__c": "reference",
                    "__No_Of_Columns__c": null,
                    "__Enable_Chatter__c": false,
                    "__Control_Type__c": "Standard",
                    "__Maximum_Value__c": null,
                    "__Minimum_Value__c": null,
                    "__Use_For_SLA_Clock__c": false,
                    "__Enable_Comments__c": false,
                    "__Expression__c": null
                };

                var fieldDetailAttributes = {
                    "__No_Of_Columns__c": 1
                };

                var headerLayout = {
                    "__Type__c": "Header",
                    "__Sequence__c": null,
                    "__Prompt_For_New_Event__c": false,
                    "__Enable_Attachments__c": false,
                    "__Enable_Chatter__c": false,
                    "__Show_Account_History__c": false,
                    "__Show_All_Sections_By_Default__c": false,
                    "__Show_Product_History__c": false,
                    "__Hide_Save__c": false,
                    "__Hide_Quick_Save__c": false,
                    "__Page_Layout_ID__c": "Checklist",
                    "__Page_Help__c": null,
                    "__Object_Name__c": SVMX.OrgNamespace + "__Checklist__c",
                    "__Multi_Add_Search_Object__c": null,
                    "__Multi_Add_Search_Field__c": null,
                    "__Multi_Add_Configuration__c": null,
                    "__IsStandard__c": false,
                    "__Enable_Service_Report_View__c": false,
                    "__Enable_Troubleshooting__c": false,
                    "__Enable_Service_Report_Generation__c": false,
                    "__Help_URL__c": "http://userdocs.servicemax.com:8080/ServiceMaxHelp/Summer14/en_us/svmx_redirector.htm?uid=SFM01_16",
                    "__Header_Reference_Field__c": null,
                    "__Header_Page_Layout__c": null,
                    "__Action_On_Zero_Lines__c": null,
                    "__Name__c": "Default Checklist Layout",
                    "__Allow_New_Lines__c": false,
                    "__Allow_Delete_Lines__c": false
                };

                this.__createOrgProperties(layout.page.header.sections[0].sectionDetail, sectionDetails);

                this.__createOrgProperties(fieldDetail.__Section__r, fieldDetailAttributes);
                this.__createOrgProperties(layout.page.header.sections[0].fields[0].fieldDetail, fieldDetail);

                this.__createOrgProperties(layout.page.header.headerLayout, headerLayout);

                return layout;
            },

            __createOrgProperties: function (obj, map) {
                for (var name in map) {
                    obj[SVMX.OrgNamespace + name] = map[name];
                }
            }


        }, {});

        sfmdeliverycommands.Class("GetLookupConfig", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_LOOKUPCONFIG"
                });
            }
        }, {});

        sfmdeliverycommands.Class("DescribeObject", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.DESCRIBE_OBJECT"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetRecordTypes", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_RECORD_TYPES"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetPageData", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_PAGEDATA"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetTemplateData", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_TEMPLATEDATA"
                });
            }
        }, {});

        sfmdeliverycommands.Class("CloseProcess", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.CLOSE_PROCESS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("RetrieveSettings", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.RETRIEVE_SETTINGS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetUserInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_USERINFO"
                });
            }
        }, {});

        // If The record needs therapy, return true
        sfmdeliverycommands.Class("GetRecordConflicted", com.servicemax.client.mvc.api.CommandWithResponder, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this.__base(request, responder);
                this._executeOperationAsync(request, this, {
                    operationId: "SFMDELIVERY.GET_RECORD_CONFLICTED"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetViewProcesses", com.servicemax.client.mvc.api.CommandWithResponder, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this.__base(request, responder);
                this._executeOperationAsync(request, this, {
                    operationId: "SFMDELIVERY.GET_VIEW_PROCESSES"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetRecordAlreadyOpen", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_RECORD_ALREADY_OPEN"
                });
            }
        }, {});

        sfmdeliverycommands.Class("SaveTargetRecordWarning", com.servicemax.client.mvc.api.CommandWithResponder, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.SAVE_TARGETRECORD_WARNING"
                });
            }
        }, {});

        sfmdeliverycommands.Class("SaveTargetRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
            __request: null,
            __responder: null,
            __inProgress: "",
            __saveResult: null,
            __logger: null,
            __constructor: function () {
                this.__base();
                this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-COMMAND-SAVE_TARGETRECORD");
                this.__businessRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.BusinessRuleValidator");
                this.__fieldUpdateRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.FieldUpdateRuleValidator");
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                if (request.deliveryEngine.getRoot()) {
                    //if any cell editor in list composite is active,
                    //complete editing before save is called.
                    request.deliveryEngine.getRoot().doBeforeSave();

                    //discard error ui if present on screen
                    request.deliveryEngine.getRoot().hideErrorUI(true, true);
                }

                this.__request = request;
                this.__responder = responder;

                this.saveToModel(request, responder);
            },

            saveToModel: function (request, responder) {
                var me = this,
                    ignoreValidations = request.additionalInfo.toModelOnly;
                //When calling from save, toModelOnly param will not be passed
                if (ignoreValidations == undefined || ignoreValidations == null) {
                    ignoreValidations = false;
                }

                // copy the changes from UI to model, if save failed, do not proceed
                var saved = request.deliveryEngine.saveToModel(true);

                // returnWarningsWithErrors indicates the caller UI wants to handle these errors.
                var returnWarningsWithErrors = request.additionalInfo.returnWarningsWithErrors;
                if (!saved.canContinue || (returnWarningsWithErrors && (saved.hasWarnings && !request.fieldValidatioConfirmed))) {
                    var currentApp = request.deliveryEngine.getEventBus(), evt;

                    // OLD WAY OF DOING THINGS: Finds the current registered error handler
                    if (request.deliveryEngine.getRoot()) {
                        request.deliveryEngine.getRoot().unblockApplication();
                        // notify about the error
                        evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.NOTIFY_APP_ERROR", this, {
                                request : {
                                    deliveryEngine : request.deliveryEngine,
                                    message : saved.errors
                                }, responder : {}});
                         currentApp.triggerEvent(evt);
                    }

                    // NEW WAY OF DOING THINGS: Let the UI layer subscribe to errors and handle the errors in a UI specific manner
                    else {
                        // notify about the error
                        evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.VALIDATION_ERROR", this, {
                                message : saved.errors, // Keep this two for compatibility with android impl, should use request.result.
                                warnings: saved.warnings,
                                request: {
                                    result: {
                                        errors: saved.errors,
                                        warnings: saved.warnings,
                                    },
                                    original: {
                                        request: request,
                                        responder: responder,
                                        context: me
                                    }
                                },
                                responder: me
                        });
                         currentApp.triggerEvent(evt);
                     }
                    return;
                }
                // In case of stopOnWarning, all warnings are already handled
                else if (ignoreValidations === false && !returnWarningsWithErrors) {
                    // check if there are any warnings.
                    var i, validations = saved.validations,
                        l = validations.length,
                        validation, additionalInfo, warnings = [];
                    for (i = 0; i < l; i++) {
                        validation = validations[i], additionalInfo = validation.additionalInfo;
                        if (additionalInfo && additionalInfo.isWarning === true) {
                            warnings.push(validation.message);
                        }
                    }

                    if (warnings.length > 0) {

                        // un block the UI
                        if (request.deliveryEngine.getRoot()) request.deliveryEngine.getRoot().unblockApplication();

                        l = warnings.length;
                        var msg = "";
                        for (i = 0; i < l; i++) {
                            msg += "<div>" + warnings[i] + "</div>";
                        }

                        var currentApp = request.deliveryEngine.getEventBus();
                        var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.SAVE_TARGETRECORD_WARNING", this, {
                                request: {
                                    message: msg,
                                    original: {
                                        request: request,
                                        responder: responder,
                                        context: me
                                    }
                                },
                                responder: me
                            });

                        currentApp.triggerEvent(evt);
                    } else {
                        me.__decideWhatToResolveBeforeSave(request, responder);
                    }
                } else {
                    me.__decideWhatToResolveBeforeSave(request, responder);
                }
            },

            __decideWhatToResolveBeforeSave: function (request, responder) {
                var disableAutoResolveLUP = SVMX.getClient().getApplicationParameter("svmx-sfm-disable-lookup-autoresolve");
                disableAutoResolveLUP = !!disableAutoResolveLUP;

                if (!disableAutoResolveLUP) {
                    this.__doResolveValuesBeforeSave(request, responder);
                } else {
                    this.__doResolveBusinessRulesBeforeSave(request, responder);
                }
            },
            __doResolveValuesBeforeSave : function(request, responder){
                // resolve data bindings for;
                // 01. look up fields
                var resolvedStatus = request.deliveryEngine.resolveModel(), // Calls resolveHandler on each fiels in header, then each details section
                  me = this,
                  i,
                  l,
                  unresolved = [],
                  unresolvedDependents = [],
                  detailsSections = [];

                // resolved status will be a header field or a details section
                if(resolvedStatus.length > 0){
                    // check for any unresolved values
                    l = resolvedStatus.length;
                    for(i = 0; i < l; i++){
                        if(!resolvedStatus[i].isResolved){
                            //Break children and parents up so parents can be found first
                            if(resolvedStatus[i].isDetailsSection) {
                                detailsSections.push(resolvedStatus[i]);
                            } else if(resolvedStatus[i].context.__metamodel && resolvedStatus[i].context.__metamodel.lookupContext){
                                //If we have a lookupContext, assume this is a dependent reference
                                unresolvedDependents.push(resolvedStatus[i]); // Only header dependents or details sections
                            } else {
                                unresolved.push(resolvedStatus[i]); // header parent or details section.
                            }
                        }
                    }

                    this.__resolveHeaderLookup(unresolved, unresolvedDependents, detailsSections, request, responder );
                }else{
                    this.__doResolveBusinessRulesBeforeSave(request, responder);
                }
            },
            __resolveHeaderLookup: function (unresolved, unresolvedDependents, detailsSections, request, responder) {
                var me = this;
                if (unresolved.length > 0 || unresolvedDependents.length > 0 || detailsSections.length > 0) {
                    var canContinueAfterResolve = true;
                    var paramsArray = [],
                        errorDetails = [];

                    // Header parent lookups
                    var d = this.__cycleResolveValuesBeforeSave(me, unresolved, paramsArray);
                    // Header dependent lookups
                    d = d.then(function (paramsArray) {
                        return me.__cycleResolveValuesBeforeSave(me, unresolvedDependents, paramsArray);
                    });
                    // Detail sections (each section will break up parent and dependents)
                    d = d.then(function (paramsArray) {
                        return me.__cycleResolveValuesBeforeSave(me, detailsSections, paramsArray);
                    });
                    d = d.done(function (paramsArray) {
                        var finishedParams = {
                            me: me,
                            paramsArray: paramsArray,
                            errorDetails: errorDetails,
                            canContinueAfterResolve: canContinueAfterResolve,
                            request: request,
                            responder: responder
                        };
                        me.__doResolveValuesBeforeSaveFinished(finishedParams);
                    });

                } else {
                    this.__doResolveBusinessRulesBeforeSave(request, responder);
                }
            },

            __cycleResolveValuesBeforeSave: function (context, unresolved, paramsArray) {
                var l = unresolved.length; // Number of sections
                var stackLength = l; // Number of sections
                var self = context;
                var deferred = SVMX.Deferred();

                if (l > 0) {
                    for (var i = 0; i < l; i++) {
                        unresolved[i].resolver.call(unresolved[i].context, {
                            handler: function (params, sectionDone) {
                                // When we are done with a section/tab we will pass no params (api.js)
                                // Headers will always have params (lookups.js)
                                params && paramsArray.push(params);

                                // When we are done with a section/tab this will be true else undefined
                                if (sectionDone) {
                                    stackLength--;
                                }

                                if (stackLength <= 0) {
                                    // Lookups done
                                    deferred.resolve(paramsArray);
                                }
                            }
                        });
                    }
                } else {
                    // Lookups done
                    deferred.resolve(paramsArray);
                }

                return deferred;
            },

            __doResolveValuesBeforeSaveFinished: function (params) {
                for (var k = 0; k < params.paramsArray.length; k++) {
                    if (params.paramsArray[k].countIsZero == true) {
                        // for child lines errorDetails is an Array
                        if (params.paramsArray[k].errorDetails instanceof Array) {
                            for (var n = 0; n < params.paramsArray[k].errorDetails.length; n++) {
                                params.errorDetails.push(params.paramsArray[k].errorDetails[n]);
                            }
                        } else {
                            params.errorDetails.push(params.paramsArray[k].errorDetails);
                        }
                    }

                    if (params.paramsArray[k].canContinueAfterResolve == false) {
                        params.canContinueAfterResolve = false;
                    }
                }

                if (params.request.additionalInfo.toModelOnly === true) {
                    params.request.deliveryEngine.saveToModel(false);
                    params.request.deliveryEngine.getRoot().unblockApplication();
                    return;
                }

                if (params.errorDetails.length == 0 && params.canContinueAfterResolve) {
                    if (params.request.deliveryEngine.getRoot().getDiscardUnresolvedLUPIndicatorAction().isVisible()) {
                        params.request.deliveryEngine.getRoot().getDiscardUnresolvedLUPIndicatorAction().hide();
                    }
                    // perform save again. TODO: May be we can execute only modified bindings
                    params.request.deliveryEngine.saveToModel(false);
                    params.me.__doResolveBusinessRulesBeforeSave(params.request, params.responder);
                } else {
                    if (!params.request.deliveryEngine.getRoot().getDiscardUnresolvedLUPIndicatorAction().isVisible()) {
                        params.request.deliveryEngine.getRoot().getDiscardUnresolvedLUPIndicatorAction().show();
                    }
                    params.request.deliveryEngine.getRoot().unblockApplication();
                    if (params.errorDetails.length > 0) {
                        var currentApp = params.request.deliveryEngine.getEventBus(),
                            evt;

                        // notify about the error
                        evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.NOTIFY_APP_ERROR", this, {
                                request: {
                                    deliveryEngine: params.request.deliveryEngine,
                                    message: params.errorDetails
                                },
                                responder: {}
                            });
                        currentApp.triggerEvent(evt);
                    }
                }
            },

            __doResolveFieldUpdateRulesBeforeSave: function (request, responder) {
                //Temporary fix block Formula fields in Android. Doing this way to avoid changes in VF to enable it Online
                if (!request.deliveryEngine.isFieldUpdatesEnabled()) {
                    return;
                }

                var fields = request.deliveryEngine.getMetaModel().getFieldTypes();
                var pageModel = request.deliveryEngine.getTargetData().getData();

                var rules = request.deliveryEngine.getMetaModel().getFieldUpdateRulesHash();
                var values = pageModel.getRawValues();

                var fieldUpdateRulesResult =
                    this.__fieldUpdateRuleValidator.evaluateFieldUpdateRules({
                        rules: rules,
                        data: values,
                        fields: fields,
                        pageModel: pageModel
                    });

                var hasValidationError = fieldUpdateRulesResult.errors.length || (fieldUpdateRulesResult.warnings.length && !request.confirmed);

                if (!hasValidationError) {
                    var updatableFields = this.__fieldUpdateRuleValidator.getUpdatableFields(rules);
                    request.deliveryEngine.getMetaModel().applyFieldUpdateResults(values,
                        fieldUpdateRulesResult.response, updatableFields, fields);

                    // LAP-5524, LAP-5084 Execute binding to refresh UI for formular data.
                    request.deliveryEngine.getTargetData().executeBinding();
                } else {
                    var currentApp = request.deliveryEngine.getEventBus();
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.FIELD_UPDATE_VALIDATION_ERROR", this, {
                            request: {
                                original: {
                                    request: request,
                                    responder: responder
                                },
                                deliveryEngine: request.deliveryEngine,
                                result: fieldUpdateRulesResult,
                                eventType: "onsave"
                            },
                            responder: {}
                        });
                    currentApp.triggerEvent(evt);
                }
                return hasValidationError;
            },

            __evalauteBusinessRules : function(request) {
                
                var fields = request.deliveryEngine.__page.getFieldTypes();
                var pageModel = request.deliveryEngine.getTargetData().getData();
                var values = pageModel.getRawValues();
                var rules = request.deliveryEngine.__page.getBusinessRulesHash();
                var recordTypeMaps = request.deliveryEngine.getPageMetaData().__recordTypesMap;

                var bizzRulesResult =
                    this.__businessRuleValidator.evaluateBusinessRules({
                        rules: rules,
                        data: values,
                        fields: fields,
                        pageModel: pageModel,
                        recordTypeMaps: recordTypeMaps
                });
                
                return bizzRulesResult;
            },

            __doResolveBusinessRulesBeforeSave: function (request, responder) {
                // First resolve field update rules
                if (this.__doResolveFieldUpdateRulesBeforeSave(request, responder)) {
                    return;
                }

                var businessRulesResult = this.__evalauteBusinessRules(request);

                var hasValidationError = businessRulesResult.errors.length || (businessRulesResult.warnings.length && !request.confirmed);

                if (hasValidationError) {
                    var currentApp = request.deliveryEngine.getEventBus();
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.ADV_VALIDATION_ERROR", this, {
                            request: {
                                original: {
                                    request: request,
                                    responder: responder
                                },
                                deliveryEngine: request.deliveryEngine,
                                result: businessRulesResult
                            },
                            responder: {}
                        });
                    return currentApp.triggerEvent(evt);
                }

                this.__doSave(request, responder);
            },

            __doSave: function (request, responder) {
                //animate the quick save icon
                var params = {
                    startSave: true,
                    eventType: request.additionalInfo.eventType
                };
                if (request.deliveryEngine.getRoot()) {
                    request.deliveryEngine.getRoot().updateQuickSaveIcon(params);
                }

                // check if before save event is configured
                var beforeSaveEventInfo = !SVMX.getClient().getApplicationParameter("svmx-sfm-disable-events") &&
                    request.deliveryEngine.getPageMetaData().getHeaderMetaModel().getPageEventInfoFor("Before Save");
                if (beforeSaveEventInfo) {
                    this.__inProgress = "Before Save";
                    this.__logger.info("Performing => " + this.__inProgress);
                    var currentApp = this.getEventBus();

                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.INVOKE_EVENTS", this, {
                            request: {
                                events: [beforeSaveEventInfo],
                                data: request.deliveryEngine.getTargetData().getData(),
                                metadata: request.deliveryEngine.getPageMetaData().getRawPageMetaData(),
                                deliveryEngine: request.deliveryEngine,
                                bypassSave: true,
                                additionalInfo: {
                                    processId: request.deliveryEngine.processId,
                                    nextStepId: request.deliveryEngine.nextStepId
                                }
                            },
                            responder: this
                        });
                    currentApp.triggerEvent(evt);
                } else {
                    this.__inProgress = "Save";
                    this.__logger.info("Performing => " + this.__inProgress);
                    this._executeOperationAsync(request, this, {
                        operationId: "SFMDELIVERY.SAVE_TARGETRECORD"
                    });
                }
            },

            result: function (data) {
                if (this.__inProgress == "Before Save") {
                    this.__inProgress = "Save";
                    this.__logger.info("Performing => " + this.__inProgress);
                    this._executeOperationAsync(this.__request, this, {
                        operationId: "SFMDELIVERY.SAVE_TARGETRECORD"
                    });
                } else if (this.__inProgress == "Save") {
                    this.__saveResult = data;

                    // check if after save event is configured
                    var afterSaveEventInfo = this.__saveResult.error ? false :
                        !SVMX.getClient().getApplicationParameter("svmx-sfm-disable-events") &&
                        this.__request.deliveryEngine.getPageMetaData().getHeaderMetaModel().getPageEventInfoFor("After Save");
                    if (afterSaveEventInfo) {
                        this.__inProgress = "After Save";
                        this.__logger.info("Performing => " + this.__inProgress);
                        var currentApp = this.getEventBus();

                        var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.INVOKE_EVENTS", this, {
                                request: {
                                    events: [afterSaveEventInfo],
                                    data: this.__request.deliveryEngine.getTargetData().getData(),
                                    metadata: this.__request.deliveryEngine.getPageMetaData().getRawPageMetaData(),
                                    deliveryEngine: this.__request.deliveryEngine,
                                    bypassSave: true,
                                    additionalInfo: {
                                        processId: this.__request.deliveryEngine.processId,
                                        nextStepId: this.__request.deliveryEngine.nextStepId
                                    }
                                },
                                responder: this
                            });
                        currentApp.triggerEvent(evt);
                    } else {
                        this.__responder.result(this.__saveResult);
                    }
                } else {
                    // After Save
                    this.__responder.result(this.__saveResult);
                }
            },

            fault: function (data) {
                // TODO:
            }
        }, {});

        sfmdeliverycommands.Class("SaveTargetAttachmentRecord", com.servicemax.client.mvc.api.CommandWithResponder, {

            __constructor: function () {
                this.__base();
            },
            
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.SAVE_TARGETATTACHMENTRECORD"
                });
            }
        }, {});

        /**
         * Special handling for checklist before save.
         */
        sfmdeliverycommands.Class("SaveChecklistTargetRecord", com.servicemax.client.sfmdelivery.commands.SaveTargetRecord, {
            __constructor: function () {
                this.__base();
            },

            saveToModel: function (request, responder) {
                var ignoreValidations = request.additionalInfo.toModelOnly;
                //When calling from save, toModelOnly param will not be passed
                if (ignoreValidations == undefined || ignoreValidations == null) {
                    ignoreValidations = false;
                }

                if (ignoreValidations) {
                    // Save to model without validation
                    var saved = request.deliveryEngine.saveToModel(false);
                    if (!saved.canContinue) {
                        return;  
                    } 
                    this.__doSave(request, responder);
                } else {
                    this.__executeValidationsAndBusinessRules(request, responder);
                }
            },

            __isSubmitEvent: function(request) {
                return request.additionalInfo.eventType === "validated save" ||
                    request.additionalInfo.eventType === "submit";
            },

            removeTheSkippedQuestionsFromSFMData: function(request) {

                var rawData = request.deliveryEngine.getTargetData().getData().getRawData().sfmData;
                var skippedQuestionList =  request.deliveryEngine.skippedQuestions;
                for (var skippedQuestionCount = 0; skippedQuestionCount < skippedQuestionList.length; skippedQuestionCount++) {
                    delete rawData[skippedQuestionList[skippedQuestionCount]];
                }
            },

            removeTheSkippedQuestionsFromValidationResult: function(request, validationResult) {

                var skippedQuestionList =  request.deliveryEngine.skippedQuestions;
                for (var errorIndex = validationResult.errors.length - 1; errorIndex>=0; errorIndex--) {
                    if (skippedQuestionList.indexOf(validationResult.errors[errorIndex].questionNumber) > -1) {
                        validationResult.errors.splice(errorIndex, 1);
                    }
                }
            },
            
            __executeValidationsAndBusinessRules : function (request, responder){

                var validationResult = request.deliveryEngine.saveToModel(true);
                this.removeTheSkippedQuestionsFromSFMData(request);
                this.removeTheSkippedQuestionsFromValidationResult(request, validationResult);
                var bizzRuleResult = this.__evalauteBusinessRules(request);

                if ((validationResult.errors.length === 0 && bizzRuleResult.errors.length === 0) && (bizzRuleResult.warnings.length === 0 || (bizzRuleResult.warnings.length && request.confirmed))) {
                    this.__doSave(request, responder);
                }else{

                    //Seggregate the errors and trigger the respective event to show in issue bar.
                    var formattedBizzRuleResult = this.__formatBizzRuleResults(request, bizzRuleResult);
                    var currentApp = request.deliveryEngine.getEventBus();
                    var mergedResults = this.__mergeValidationAndBizzRuleResults(validationResult, formattedBizzRuleResult);

                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.ADV_VALIDATION_ERROR", this, {
                                message :mergedResults.errors, // Keep this two for compatibility with android impl, should use request.result.
                                warnings: mergedResults.warnings,
                                request: {
                                    result: {
                                        errors: mergedResults.errors,
                                        warnings : mergedResults.warnings
                                    },
                                    original: {
                                        request: request,
                                        responder: responder,
                                        context: this
                                    }
                                },
                                responder: this
                        });

                    return currentApp.triggerEvent(evt);
                }

            },

            __mergeValidationAndBizzRuleResults : function (validationResultObj, bizzRuleResultObj){

                var uniqueBizzRuleErrors = this.__removeDuplicatesFromBizzRulesResults(validationResultObj.errors, bizzRuleResultObj.errors);
                validationResultObj.errors.push.apply(validationResultObj.errors, uniqueBizzRuleErrors);

                var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
                if((useJsr && useJsr === false)|| useJsr === undefined ){
                    SVMX.sort(validationResultObj.errors, "questionNumber");
                }

                var uniqueBizzRuleWarnings = this.__removeDuplicatesFromBizzRulesResults(validationResultObj.warnings, bizzRuleResultObj.warnings);
                validationResultObj.warnings.push.apply(validationResultObj.warnings, uniqueBizzRuleWarnings);
                if((useJsr && useJsr === false)|| useJsr === undefined ){
                  SVMX.sort(validationResultObj.warnings, "questionNumber");
                }

                return validationResultObj;
            },

            __removeDuplicatesFromBizzRulesResults : function (validationResult, bizzRuleResult) {

                var i =0;
                var len = validationResult.length;

                for (i ; i < len ;i++) {
                    var quesNumber = validationResult[i].questionNumber;

                    var res = SVMX.array.filter(bizzRuleResult, function(item){
                        return item.questionNumber === quesNumber;
                    });

                    if(res.length){
                        var itemIndex = SVMX.array.map(bizzRuleResult, function(item, index){
                            if (item.questionNumber === quesNumber) {
                                return index;
                            }
                        });
                        
                        if( itemIndex.length ){
                            bizzRuleResult.splice(itemIndex[0], 1);
                        }
                        
                    }
                }

                return bizzRuleResult;
            },

            __extractQuestionForFailedBizRules : function (bizRuleData) {

                var i = 0;
                var len = bizRuleData.length;
                var result = [];

                for(i ; i < len; i++){
                    var questionRef = bizRuleData[i].ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + '__Field_Name__c'];
                    var res = {};
                    res[questionRef] = bizRuleData[i].message;
                    result.push(res);
                }

                return result;
            },

            __formatBizzRuleResults : function (request, bizzRuleResult) {

                var result = {};
                result.errors = this.__getFormattedBizzRuleResult(request, bizzRuleResult.errors, "error");
                result.warnings = this.__getFormattedBizzRuleResult(request, bizzRuleResult.warnings, "warning");

                return result;
            },

            //Formats the erros/warnings similar to validation results
            __getFormattedBizzRuleResult : function(request, bizzRuleData, type){

                var questionWithMessage = this.__extractQuestionForFailedBizRules(bizzRuleData);
                var formattedResult = [];
                var i = 0;
                var len = questionWithMessage.length;
                var dataModel = request.deliveryEngine.__page.getDataModel();
                var bindings = dataModel.__allBindings;

                for (i ; i < len; i++){
                    var currentQuesWithError = questionWithMessage[i];
                    
                    for(var questionId in currentQuesWithError){
                        var questionBinding = SVMX.array.filter(bindings, function(item){ return item.__path === questionId; })

                        if (questionBinding.length) {
                                var question = questionBinding[0];
                                var msg = currentQuesWithError[questionId];
                                var params ={ 
                                                type : type,
                                                message : msg
                                            };
                                
                                if (question.__bizzRuleValidator && question.__bizzRuleValidator.handler) {
                                    formattedResult.push(question.__bizzRuleValidator.handler.call(question.__bizzRuleValidator.context, params));
                                }
                        }
                    }
                }

                return formattedResult;               
            },

            /**
             * Change our virtual question object back into a savable checklist object
             */
            __doSave: function (request, responder) {
                // Get our page layout
                request = request || {};
                request.additionalInfo = request.additionalInfo || {};

                var isSubmitEvent = this.__isSubmitEvent(request);

                // Reset activeSectionIndex to the first section on submit
                request.deliveryEngine.getPageMetaData().getChildNode("header").getData().activeSectionIndex = isSubmitEvent ? 0 : request.additionalInfo.activeSectionIndex;

                var pageLayout = request.deliveryEngine.getPageMetaData().getRawPageMetaData();
                pageLayout = (pageLayout) ? SVMX.toJSON(pageLayout) : "";

                // Get our raw data pointer (editing rawData is editing sfmData)
                var rawData = request.deliveryEngine.getTargetData().getData().getRawData().sfmData;

                var skippedQuestions = request.deliveryEngine.skippedQuestions; // skipped questions for exit criteria.

                // Pull out just question data
                var existCheckListJSONValue = SVMX.toObject(request.data.__data.sfmData[SVMX.OrgNamespace + '__ChecklistJSON__c'])  || {};
                var currentCheckListJSONValue = this.getCurrentSectionQuestion(request,request.deliveryEngine.getMetaModel().getQuestionData(rawData));
                var questions= Object.assign(existCheckListJSONValue, currentCheckListJSONValue);

                if (skippedQuestions && skippedQuestions.length) {
                    for (var skippedQuestionCount = 0; skippedQuestionCount < skippedQuestions.length; skippedQuestionCount++) {
                        delete questions[skippedQuestions[skippedQuestionCount]];
                    }
                }
                var questions = (questions) ? SVMX.toJSON(questions) : "";

                // Place or data on main checklist object
                rawData[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'] = pageLayout;
                rawData[SVMX.OrgNamespace + '__ChecklistJSON__c'] = questions;

                // If we do not have a what_id, fill it in
                if (!rawData[SVMX.OrgNamespace + '__What_Id__c']) {
                    rawData[SVMX.OrgNamespace + '__What_Id__c'] = request.sourceRecordId;
                }
                rawData[SVMX.OrgNamespace + '__ChecklistProcessID__c'] = request.additionalInfo.sfProcessId;

                // Flag to  do source update or skip agree
                request.skipAggressiveSync = !isSubmitEvent;
                request.doSourceObjectUpdate = isSubmitEvent;
                request.skipStatusMsg=true,

                // Status is dependent on status
                rawData[SVMX.OrgNamespace + '__Status__c'] = (isSubmitEvent) ? "Completed" : "In Process";

                if (isSubmitEvent) {
                    var userInfo = null;
                    if (request.deliveryEngine && request.deliveryEngine.getMetaModel() && request.deliveryEngine.getMetaModel().getUserInfo()) {
                        userInfo = request.deliveryEngine.getMetaModel().getUserInfo();
                    }

                    if (userInfo) {
                        var now = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime('Now', "YYYY-MM-DD", "HH:mm:ss");
                        var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
                        if(useJsr && useJsr === true){
                            //Fix for #036865. Converting CompletedOn to user's time zone
                            now = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(now,userInfo.TimezoneOffset,false);
                        }
                        rawData[SVMX.OrgNamespace + '__Completed_By__c'] = userInfo.UserId;
                        rawData[SVMX.OrgNamespace + '__Completed_On__c'] = now;
                    }
                }

                // Remove all the questions from sfmData, their existence is not needed anymore and when null caused errors online
                request.deliveryEngine.getMetaModel().removeQuestionData(rawData);

                this.__inProgress = "Save";
                    this.__logger.info("Performing => " + this.__inProgress);
                    this._executeOperationAsync(request, this, {
                        operationId: "SFMDELIVERY.SAVE_TARGETRECORD"
                });
            },

            //fetching current sections question
            getCurrentSectionQuestion : function(request, questions){
                var currentQuestions = {};
                if("undefined" === typeof request.additionalInfo.currentIndex){
                    return questions;
                }
                else if (request) {
                    var sections = request.deliveryEngine.__page.getChildNode('header').getChildNode('sections');
                    if(sections.length > request.additionalInfo.currentIndex){
                        var fields = sections[request.additionalInfo.currentIndex].getChildNode('fields');
                        var fieldLength = fields.length;
                        for(var fieldIndex = 0; fieldIndex < fieldLength; fieldIndex++) {
                            var fieldName = fields[fieldIndex].fieldName;
                            if(fieldName){
                                currentQuestions[fieldName] = questions[fieldName];
                            }
                        }
                    }
                }
                return currentQuestions;
            }

        }, {});

        sfmdeliverycommands.Class("ChecklistEntryCriteria", com.servicemax.client.mvc.api.CommandWithResponder, {
            __request: null,
            __responder: null,
            __logger: null,
            __constructor: function() {
                this.__base();
                this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-EVALUATE_CHECKLIST_ENTRY_CRITERIA");
                this.__businessRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.BusinessRuleValidator");
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {

                this.__request = request;
                this.__responder = responder;
                this.__executeEntryCriteriaBusinessRules(request, responder);
            },

            __executeEntryCriteriaBusinessRules: function(request, responder) {

                var rules = request.deliveryEngine.__page.getEntryExitCriteriaBusinessRuleHash(request);
                var sourceObjectName = null;
                var fields = {};

                for (var i = 0; i < rules.header.rules.length; i++) {
                    rules.header.rules[i].ruleInfo.bizRule[SVMX.OrgNamespace + "__Message_Type__c"] = "Error"; // Hardcoding to error message as this value is not coming as part of Biz rule.
                }

                if (rules.header && rules.header.rules && rules.header.rules.length > 0) {
                    sourceObjectName = rules.header.rules[0].ruleInfo.bizRule[SVMX.OrgNamespace + "__Source_Object_Name__c"]; // getting the Source Record Name.
                }

                if (sourceObjectName) {
                    var result = this.__modifySourceObectData(request.data);
                    fields[sourceObjectName] = result.sourceObjectFieldsDict;

                    // check for field level permission. If the biz rule source object field doesnt have field level permission, then the question on that field should not be executed.
                    for (var ruleCounter = rules.header.rules.length - 1; ruleCounter >= 0; ruleCounter--) {
                        var bizDetails = rules.header.rules[ruleCounter].ruleInfo.bizRuleDetails;
                        for (var bizRuleCounter = bizDetails.length - 1; bizRuleCounter >= 0; bizRuleCounter--) {
                            var fieldName = bizDetails[bizRuleCounter][SVMX.OrgNamespace + "__Field_Name__c"];
                            if (result.fieldValueData[fieldName] === undefined) {
                                bizDetails.splice(bizRuleCounter, 1);
                            }
                        }
                        if (bizDetails.length === 0) {
                            rules.header.rules.splice(ruleCounter, 1);
                        }
                    }
                    var bizzRulesResult =
                        this.__businessRuleValidator.evaluateEntryCriteriaBusinessRules({
                            rules: rules,
                            data: request.data,
                            fields: fields,
                            fieldValueData: result.fieldValueData
                        });

                    if (bizzRulesResult.skipSections && bizzRulesResult.skipSections.length > 0) {
                        var entryCriteriaFailedQuestions = this.__processSectionListToRemoveEntryCriteriaUnQualifiedSections(bizzRulesResult.skipSections);
                        this.deleteRulesofDeletedQuestions(request.deliveryEngine.__page, entryCriteriaFailedQuestions);
                    }
                }

                this.__responder.result(request.additionalInfo.eventType);
            },

            __modifySourceObectData: function(inData) {

                var sourceObjectFieldsDict = {};
                var fieldValueData = {};

                for (var i = 0; i < inData.length; i++) {
                    if (inData[i].key && inData[i].key.length > 0) {

                        if (inData[i].ftype.toLowerCase() === "reference") {
                            inData[i].value = inData[i].fieldsToNull;
                        } else {
                            inData[i].value = this.__convertFieldValue(inData[i].value, inData[i].ftype.toLowerCase());
                        }
                        fieldValueData[inData[i].key] = inData[i].value; // fieldName-value pair
                        sourceObjectFieldsDict[inData[i].key] = inData[i].ftype.toLowerCase(); // fieldName-fieldtype pair
                    }
                }

                var result = {
                    fieldValueData: fieldValueData,
                    sourceObjectFieldsDict: sourceObjectFieldsDict
                }

                return result;
            },

            __isDateObject: function(inDate) {
                if ((inDate instanceof Date) && (!isNaN(inDate.getTime()))) {
                    return true;
                }
                this.__logger.error("Invalid Date Object;", inDate);
                return false;
            },

            __convertFieldValue: function(inValue, inType) {
                switch (inType) {
                    case "date":
                        if (!inValue) return inValue;
                        //var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDate(inValue);
                        var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(inValue);
                        if (this.__isDateObject(d)) {
                            d.setHours(0, 0, 0);
                        }
                        return d;
                    case "datetime":
                        if (!inValue) return inValue;
                        //var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDate(inValue);
                        var d = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(inValue);
                        this.__isDateObject(d); // check if valid
                        return d;
                    case "boolean":
                        return inValue === "true" || inValue === true;
                    case "double":
                    case "percent":
                    case "currency":
                        if (typeof inValue === "string") {
                            return Number(inValue);
                        } else {
                            return inValue;
                        }
                    default:
                        return inValue;
                }
            },

            __processSectionListToRemoveEntryCriteriaUnQualifiedSections: function(errorList) {

                var sectionList = [];
                var questionList = [];
                for (var index = 0; index < errorList.length; index++) {
                    sectionList.push(errorList[index].ruleInfo.bizRule[SVMX.OrgNamespace + "__SM_Section__c"]);
                }
                var metaData = this.__request.deliveryEngine.getPageMetaData().getRawPageMetaData();
                if (metaData && metaData.page && metaData.page.header && metaData.page.header.sections && metaData.page.header.sections.length > 0) {
                    for (var lIndex = metaData.page.header.sections.length - 1; lIndex>=0; lIndex--) {
                        section = metaData.page.header.sections[lIndex];
                        if (section && section.sectionDetail && section.sectionDetail.Id && section.sectionDetail.Id.length > 0) {
                            if (sectionList.indexOf(section.sectionDetail.Id) > -1) {
                                //metaData.page.header.sections.splice(lIndex, 1);
                                section.sectionDetail[SVMX.OrgNamespace+'__Entry_Criteria__c'] = true;
                                for (var count = 0; count < section.fields.length; count++) {
                                    var fieldDetail = section.fields[count].fieldDetail;
                                    if (fieldDetail) {
                                        var questionObject = SVMX.toObject(fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]);
                                        questionList.push(questionObject.question.questionID);
                                    }
                                }
                            }
                        }
                    }
                }
                return questionList;
            },

            deleteRulesofDeletedQuestions: function(page, questionList){
                var rules = page._data.page.businessRules;
                for (var ruleCounter = rules.length - 1; ruleCounter >= 0; ruleCounter--) {
                    var rule = rules[ruleCounter];
                    if (rule.ruleInfo && rule.ruleInfo.bizRuleDetails && questionList.indexOf(rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + "__Field_Name__c"]) > -1) {
                        //1. If rule's question number is there in the skipped section, then remove the rule.
                        rules.splice(ruleCounter, 1);
                    }
                }
            }

        }, {});

        sfmdeliverycommands.Class("ChecklistExitCriteria", com.servicemax.client.mvc.api.CommandWithResponder, {
            __request: null,
            __responder: null,
            __logger: null,
            __constructor: function() {
                this.__base();
                this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-EVALUATE_CHECKLIST_EXIT_CRITERIA");
                this.__businessRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.BusinessRuleValidator");
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {

                this.__request = request;
                this.__responder = responder;
                this.__executeExitCriteriaBusinessRules(request, responder);
            },

            __executeExitCriteriaBusinessRules: function(request, responder) {

                var rules = request.deliveryEngine.__page.getEntryExitCriteriaBusinessRuleHash(request);
                var bizzRulesResult = null;
                    if (rules.header.rules.length > 0) {
                    var fields = request.deliveryEngine.__page.getFieldTypes();
                    var pageModel = request.deliveryEngine.getTargetData().getData();
                    var values = pageModel.getRawValues();
                    // var rules = request.deliveryEngine.__page.getBusinessRulesHash();
                    var recordTypeMaps = request.deliveryEngine.getPageMetaData().__recordTypesMap;

                    bizzRulesResult =
                        this.__businessRuleValidator.evaluateBusinessRules({
                            rules: rules,
                            data: values,
                            fields: fields,
                            pageModel: pageModel,
                            recordTypeMaps: recordTypeMaps
                    });             
                }
                this.__responder.result(bizzRulesResult?bizzRulesResult.errors:[]);
            }

        }, {});

        sfmdeliverycommands.Class("GetNextStepInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_NEXTSTEPINFO"
                });
            }
        }, {});

        sfmdeliverycommands.Class("InvokeEvents", com.servicemax.client.mvc.api.CommandWithResponder, {
            __currentEventIndex: 0,
            __allEvents: null,
            __responder: null,
            __request: null,
            __logger: null,
            __constructor: function () {
                this.__base();
                this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-COMMAND-INVOKE_EVENTS");
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                //if any cell editor in list composite is active,
                //complete editing before save is called.
                if (request.deliveryEngine.getRoot()) {
                    request.deliveryEngine.getRoot().doBeforeSave();
                }

                //discard error ui if present on screen
                if (request.deliveryEngine.getRoot()) {
                    request.deliveryEngine.getRoot().hideErrorUI(true, true);
                }

                this.__allEvents = request.events;
                this.__currentEventIndex = -1;
                this.__request = request;
                this.__responder = responder;

                // make sure that UI changes are persisted back to client model before
                // invoking the events.
                // There are cases when we do not have to perform save when one or more events
                // are executed. For example when SaveAction is performed, because save would
                // have been already executed.
                if (!request.bypassSave && request.deliveryEngine) {

                    // if save failed, do not proceed
                    var saved = request.deliveryEngine.saveToModel();
                    if (!saved.canContinue) return;

                } else {
                    SVMX.getLoggingService().getLogger().warning(
                        "Ignoring saveToModel() because either request.bypassSave is true OR deliveryEngine instance is missing");
                }

                this.__invokeNextEvent();
            },

            __invokeNextEvent: function () {
                this.__currentEventIndex++;
                var eventInfo = this.__allEvents[this.__currentEventIndex];

                this.__logger.info("Invoking event => " + SVMX.toJSON(eventInfo));
                this._executeOperationAsync({
                        event: eventInfo,
                        data: this.__request.data,
                        metadata: this.__request.metadata,
                        additionalInfo: this.__request.additionalInfo
                    },
                    this, {
                        operationId: "SFMDELIVERY.INVOKE_EVENT"
                    });
            },

            result: function (data) {
                if (this.__currentEventIndex == (this.__allEvents.length - 1)) {
                    // all events are done
                    this.__responder.result();
                } else {
                    this.__invokeNextEvent();
                }
            },

            fault: function (data) {
                // TODO:
            }
        }, {});

        sfmdeliverycommands.Class("AddRecords", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.ADD_RECORDS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("DeleteRecords", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.DELETE_RECORDS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetBubbleData", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_BUBBLEDATA"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetDetailMappedInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_DETAIL_MAPPEDINFO"
                });
            }
        }, {});

        sfmdeliverycommands.Class("LookupItemSelected", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.LOOKUP_ITEM_SELECTED"
                });
            }
        }, {});

        sfmdeliverycommands.Class("ChangeApplicationState", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                if (request.deliveryEngine) {
                    request.deliveryEngine.changeApplicationState(request.state);
                } else {
                    var stateHandler = SVMX.getCurrentApplication().getApplicationStateHandler();
                    stateHandler.changeApplicationState(request.state);
                }
            }
        }, {});

        sfmdeliverycommands.Class("NotifyApplicationError", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                if (request.deliveryEngine) {
                    request.deliveryEngine.notifyApplicationError(request);
                } else {
                    var errorHandler = SVMX.getCurrentApplication().getApplicationErrorHandler();
                    errorHandler.notifyApplicationError(request);
                }
            }
        }, {});

        sfmdeliverycommands.Class("NotifyQuickMessage", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                if (request.deliveryEngine) {
                    request.deliveryEngine.showQuickMessage(request.state);
                } else {
                    var msgHandler = SVMX.getCurrentApplication().getApplicationQuickMessageHandler();
                    msgHandler.showQuickMessage(request.message, request.duration, request.type);
                }
            }
        }, {});

        sfmdeliverycommands.Class("GetProductHistory", com.servicemax.client.mvc.api.Command, {

	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.GET_PRODUCT_HISTORY"});
	        }
	    }, {});

        sfmdeliverycommands.Class("GetOnlineProductHistory", com.servicemax.client.mvc.api.Command, {

            __constructor : function(){ this.__base(); },

            executeAsync : function(request, responder){
                this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.GET_ONLINE_PRODUCT_HISTORY"});
            }
        }, {});

        sfmdeliverycommands.Class("GetAccountHistory", com.servicemax.client.mvc.api.Command, {

            __constructor : function(){ this.__base(); },

            executeAsync : function(request, responder){
                this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.GET_ACCOUNT_HISTORY"});
            }
        }, {});

        sfmdeliverycommands.Class("GetOnlineAccountHistory", com.servicemax.client.mvc.api.Command, {

            __constructor : function(){ this.__base(); },

            executeAsync : function(request, responder){
                this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.GET_ONLINE_ACCOUNT_HISTORY"});
            }
        }, {});

        sfmdeliverycommands.Class("DownloadRecordOnDemand", com.servicemax.client.mvc.api.Command, {

            __constructor : function(){ this.__base(); },

            executeAsync : function(request, responder){
                this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.DOWNLOAD_RECORD_ON_DEMAND"});
            }
        }, {});

        sfmdeliverycommands.Class("ListAttachments", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.LIST_ATTACHMENTS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("ListOutputDocAttachments", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.LIST_OUTPUTDOC_ATTACHMENTS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("EditAttachment", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.EDIT_ATTACHMENT"
                });
            }
        }, {});

        sfmdeliverycommands.Class("DeleteAttachments", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.DELETE_ATTACHMENTS"
                });
            }
        }, {});

        sfmdeliverycommands.Class("AttachFile", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.ATTACH_FILE"
                });
            }
        }, {});

        sfmdeliverycommands.Class("OpenAttachment", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.OPEN_FILE"
                });
            }
        }, {});

        sfmdeliverycommands.Class("ShareAttachments", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.SHARE_ATTACHMENTS"
                });
            }
        }, {});

        /**
         * For mobile phones and tablets when a separate webview must be opened to view a link
         * and the target attribute of an anchor tag is not appropriate.
         *
         * No response returned since we do not really care if this succeeds or not, we just make a best effort.
         */
        sfmdeliverycommands.Class("OpenBrowser", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.OPEN_BROWSER"
                });
            }
        }, {});

        sfmdeliverycommands.Class("GetUrlAndParameters", com.servicemax.client.mvc.api.Command, {
            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.GET_URL_AND_PARAMETERS"
                });
            }
        }, {});

        /**
         * For mobile phones and tablets when a separate webview must be opened to view a link
         * and the target attribute of an anchor tag is not appropriate.
         *
         * No response returned since we do not really care if this succeeds or not, we just make a best effort.
         */
        sfmdeliverycommands.Class("OpenTelephone", com.servicemax.client.mvc.api.Command, {
            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.OPEN_TELEPHONE"
                });
            }
        }, {});

        /**
         * For mobile phones and tablets when a separate webview must be opened to view a link
         * and the target attribute of an anchor tag is not appropriate.
         *
         * No response returned since we do not really care if this succeeds or not, we just make a best effort.
         */
        sfmdeliverycommands.Class("OpenSMS", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.OPEN_SMS"
                });
            }
        }, {});

        /**
         * For mobile phones and tablets when a separate webview must be opened to view a link
         * and the target attribute of an anchor tag is not appropriate.
         *
         * No response returned since we do not really care if this succeeds or not, we just make a best effort.
         */
        sfmdeliverycommands.Class("OpenEmail", com.servicemax.client.mvc.api.Command, {

            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.OPEN_EMAIL"
                });
            }
        }, {});

        sfmdeliverycommands.Class("CheckIfConflict", com.servicemax.client.mvc.api.Command, {
            __constructor: function () {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function (request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMDELIVERY.CHECK_IF_CONFLICT"
                });
            }
        }, {});

        sfmdeliverycommands.Class("IsDodRecord", com.servicemax.client.mvc.api.Command, {

            __constructor : function(){ this.__base(); },

            executeAsync : function(request, responder){
                this._executeOperationAsync(request, responder, {operationId : "SFMDELIVERY.IS_DOD_RECORD"});
            }
        }, {});

    };
})();

// end of file
