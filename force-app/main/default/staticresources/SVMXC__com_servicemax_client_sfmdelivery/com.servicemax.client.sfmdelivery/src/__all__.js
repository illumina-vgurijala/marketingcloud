// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\commands.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\constants.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.constants
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var constantsImpl = SVMX.Package("com.servicemax.client.sfmdelivery.constants");

constantsImpl.init = function(){
	constantsImpl.Class("Constants", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		NO_VALUE 						: "noValue",
		RECORD_TYPE_ID 					: "RecordTypeId",
		PREF_LOGGING					: "LOGGING",
		LOOKUP_CALL_TYPE_BOTH			: "BOTH",
		LOOKUP_CALL_TYPE_DATA			: "DATA",
		LOOKUP_CALL_TYPE_META			: "META"
	});
}
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\countDownTimer.js
/*!
 * The Final Countdown for jQuery v2.0.4 (http://hilios.github.io/jQuery.countdown/)
 * Copyright (c) 2014 Edson Hilios
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
(function(factory) {
    "use strict";
    if (typeof define === "function" && define.amd) {
        define([ "jquery" ], factory);
    } else {
        factory(jQuery);
    }
})(function($) {
    "use strict";
    var PRECISION = 100;
    var instances = [], matchers = [];
    matchers.push(/^[0-9]*$/.source);
    matchers.push(/([0-9]{1,2}\/){2}[0-9]{4}( [0-9]{1,2}(:[0-9]{2}){2})?/.source);
    matchers.push(/[0-9]{4}([\/\-][0-9]{1,2}){2}( [0-9]{1,2}(:[0-9]{2}){2})?/.source);
    matchers = new RegExp(matchers.join("|"));
    function parseDateString(dateString) {
        if (dateString instanceof Date) {
            return dateString;
        }
        if (String(dateString).match(matchers)) {
            if (String(dateString).match(/^[0-9]*$/)) {
                dateString = Number(dateString);
            }
            if (String(dateString).match(/\-/)) {
                dateString = String(dateString).replace(/\-/g, "/");
            }
            return new Date(dateString);
        } else {
            throw new Error("Couldn't cast `" + dateString + "` to a date object.");
        }
    }
    var DIRECTIVE_KEY_MAP = {
        Y: "years",
        m: "months",
        w: "weeks",
        d: "days",
        D: "totalDays",
        H: "hours",
        M: "minutes",
        S: "seconds"
    };
    function strftime(offsetObject) {
        return function(format) {
            var directives = format.match(/%(-|!)?[A-Z]{1}(:[^;]+;)?/gi);
            if (directives) {
                for (var i = 0, len = directives.length; i < len; ++i) {
                    var directive = directives[i].match(/%(-|!)?([a-zA-Z]{1})(:[^;]+;)?/), regexp = new RegExp(directive[0]), modifier = directive[1] || "", plural = directive[3] || "", value = null;
                    directive = directive[2];
                    if (DIRECTIVE_KEY_MAP.hasOwnProperty(directive)) {
                        value = DIRECTIVE_KEY_MAP[directive];
                        value = Number(offsetObject[value]);
                    }
                    if (value !== null) {
                        if (modifier === "!") {
                            value = pluralize(plural, value);
                        }
                        if (modifier === "") {
                            if (value < 10) {
                                value = "0" + value.toString();
                            }
                        }
                        format = format.replace(regexp, value.toString());
                    }
                }
            }
            format = format.replace(/%%/, "%");
            return format;
        };
    }
    function pluralize(format, count) {
        var plural = "s", singular = "";
        if (format) {
            format = format.replace(/(:|;|\s)/gi, "").split(/\,/);
            if (format.length === 1) {
                plural = format[0];
            } else {
                singular = format[0];
                plural = format[1];
            }
        }
        if (Math.abs(count) === 1) {
            return singular;
        } else {
            return plural;
        }
    }
    var Countdown = function(el, finalDate, callback) {
        this.el = el;
        this.$el = $(el);
        this.interval = null;
        this.offset = {};
        this.instanceNumber = instances.length;
        instances.push(this);
        this.$el.data("countdown-instance", this.instanceNumber);
        if (callback) {
            this.$el.on("update.countdown", callback);
            this.$el.on("stoped.countdown", callback);
            this.$el.on("finish.countdown", callback);
        }
        this.setFinalDate(finalDate);
        this.start();
    };
    $.extend(Countdown.prototype, {
        start: function() {
            if (this.interval !== null) {
                clearInterval(this.interval);
            }
            var self = this;
            this.update();
            this.interval = setInterval(function() {
                self.update.call(self);
            }, PRECISION);
        },
        stop: function() {
            clearInterval(this.interval);
            this.interval = null;
            this.dispatchEvent("stoped");
        },
        pause: function() {
            this.stop.call(this);
        },
        resume: function() {
            this.start.call(this);
        },
        remove: function() {
            this.stop();
            instances[this.instanceNumber] = null;
            delete this.$el.data().countdownInstance;
        },
        setFinalDate: function(value) {
            this.finalDate = parseDateString(value);
        },
        update: function() {
            if (this.$el.closest("html").length === 0) {
                this.remove();
                return;
            }
            this.totalSecsLeft = this.finalDate.getTime() - new Date().getTime();
            this.totalSecsLeft = Math.ceil(this.totalSecsLeft / 1e3);
            this.totalSecsLeft = this.totalSecsLeft < 0 ? 0 : this.totalSecsLeft;
            this.offset = {
                seconds: this.totalSecsLeft % 60,
                minutes: Math.floor(this.totalSecsLeft / 60) % 60,
                hours: Math.floor(this.totalSecsLeft / 60 / 60) % 24,
                days: Math.floor(this.totalSecsLeft / 60 / 60 / 24) % 7,
                totalDays: Math.floor(this.totalSecsLeft / 60 / 60 / 24),
                weeks: Math.floor(this.totalSecsLeft / 60 / 60 / 24 / 7),
                months: Math.floor(this.totalSecsLeft / 60 / 60 / 24 / 30),
                years: Math.floor(this.totalSecsLeft / 60 / 60 / 24 / 365)
            };
            if (this.totalSecsLeft === 0) {
                this.stop();
                this.dispatchEvent("finish");
            } else {
                this.dispatchEvent("update");
            }
        },
        dispatchEvent: function(eventName) {
            var event = $.Event(eventName + ".countdown");
            event.finalDate = this.finalDate;
            event.offset = $.extend({}, this.offset);
            event.strftime = strftime(this.offset);
            this.$el.trigger(event);
        }
    });
    $.fn.countdown = function() {
        var argumentsArray = Array.prototype.slice.call(arguments, 0);
        return this.each(function() {
            var instanceNumber = $(this).data("countdown-instance");
            if (instanceNumber !== undefined) {
                var instance = instances[instanceNumber], method = argumentsArray[0];
                if (Countdown.prototype.hasOwnProperty(method)) {
                    instance[method].apply(instance, argumentsArray.slice(1));
                } else if (String(method).match(/^[$A-Z_][0-9A-Z_$]*$/i) === null) {
                    instance.setFinalDate.call(instance, method);
                    instance.start();
                } else {
                    $.error("Method %s does not exist on jQuery.countdown".replace(/\%s/gi, method));
                }
            } else {
                new Countdown(this, argumentsArray[0], argumentsArray[1]);
            }
        });
    };
});

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\engine.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.engine
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
    var engine = SVMX.Package("com.servicemax.client.sfmdelivery.engine");

engine.init = function(){

    // imports
    var CONSTANTS = com.servicemax.client.sfmdelivery.constants.Constants;
    var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");

    // end globals
    // end imports

    // globals
    var rootContainerIdCounter = 0;

    engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
        __logger : null, __sm : null, __page : null, __root : null,
        recordId : null, record : null, processId : null, __settings : null, returnUrl : null, nextStepId : null,
        __eventBus : null,  __navigationStack : null, __parentContainer : null, __rootContainerId : null,
        __view : null, __objectNameMap : null,  console : null,
        __extensions : null, isConflict : null, __clonedData : null, __modifiedFields : [],
        __clientType : null,


        __constructor : function(){
            this.__extensions = this.__loadExtensions();

            DatetimeUtils.setAmPmText(TS.T("FSA016_TAG005","AM"), TS.T("FSA016_TAG006", "PM"));

            this.__navigationStack = [];
            this.__base();
            this.__logger = SVMX.getLoggingService().getLogger("SFM-DEL-ENGINE-IMPL");
            var app = SVMX.getCurrentApplication();
            this.__clientType = SVMX.getClient().getApplicationParameter("client-type");

            //Checking theme type and if it's lightning, updating lightning specific app-config parameter values
            var themeService = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.themeservice").getInstance();
            var themeName = themeService.getCurrentTheme();
            if(themeName === 'LIGHTNING'){
                SVMX.getClient().addApplicationParameter("svmx-sfm-section-label-align", "top");
                SVMX.getClient().addApplicationParameter("svmx-sfm-section-label-style", "font-weight:normal");
            }

            // set up the application state handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application UI state will
            // be managed by SFMConsole itself.
            app.setApplicationStateHandler(this);

            // set up the application error handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application errors will
            // be managed by SFMConsole itself.
            app.setApplicationErrorHandler(this);

            // set up the application message UI handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application UI messages will
            // be managed by SFMConsole itself.
            //app.setApplicationMessageUIHandler(this);

            // set up the application quick message handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application quick messages will
            // be managed by SFMConsole itself.
            app.setApplicationQuickMessageHandler(app);

            engine.DeliveryEngineImpl.addEngine(this);

        },

        initAsync : function(options){
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
            this.__eventBus = SVMX.create("com.servicemax.client.sfmdelivery.impl.SFMDeliveryEngineEventBus", {});
            // create the named default controller.  Note that engine.js does not ever get nor use a pointer to this controller
            // The controller binds to all of the events listed in our manifest.json file and is able to receive those events
            // without engine.js doing anything more than instantiating this controller named instance.
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){

                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);

                    ni.createNamedInstanceAsync("SFMDELIVERY.VIEW",{ handler : function(view){
                        this.__view = view;
                        options.handler.call(options.context);
                    }, context: this, additionalParams: {eventBus: this.getEventBus()}});
                }, context : this});

            }, context : this, additionalParams : { eventBus : this.__eventBus }});

        },

        __loadExtensions : function() {
            var client = SVMX.getClient();
            var declaration = client.getDeclaration("com.servicemax.client.sfmdelivery.extension");
            var    definitions = client.getDefinitionsFor(declaration);
            var result = {};
            SVMX.array.forEach(definitions, function(def) {
                var extType = def.config["extension-type"];
                if (!result[extType]) result[extType] = [];
                result[extType].push(def);
            }, this);
            return result;
        },

        getExtensions : function(extType) {
            var candidates = this.__extensions[extType] || [];

            return SVMX.array.filter(candidates, function(extension) {
                try {
                    var config = extension.config;
                    var validator, validatorFn, cls, result;
                    var validator = config.validator;
                    if (!validator) return true;

                    cls = SVMX.getClass(config["class-name"]);
                    if (!cls) return false;
                    validatorFn = cls[validator];
                    if (!validatorFn) return false;

                    result = validatorFn(this.getPageMetaData(), this.getTargetData());
                    return result;
                } catch(e) {
                    this.__logger.error("Extension failed to validate: " + e + "; " + config["class-name"]);
                    return false;
                }
            }, this);
        },

        // part of the application state management
        // DEPRECATED SUM14
        __appCurrentState : "",

        /*
         * @param {Object} options
         *     @param {String} options.type: QUESTION, WARN, ERROR, INFO
         *     @param {String} options.text
         *     @param {[Object]} options.buttons Array of ["OK", "CANCEL", "YES", "NO"]
         *     @param {String} options.itemId Unique identifier of this message
         */
        showMessage : function(options){
            SVMX.getCurrentApplication().showMessage(options);
        },

        showQuickMessage : function(options){
            SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(options.message, 3000, options.type);
        },

        allowSyncPopUp : function() {
            var syncImpl = SVMX.getCurrentApplication().getSyncImpl();
            syncImpl.triggerEvent(new com.servicemax.client.lib.api.Event("EDITMODE_OUT", this, {}));
        },

        blockSyncPopUp : function() {
            var syncImpl = SVMX.getCurrentApplication().getSyncImpl();
            syncImpl.triggerEvent(new com.servicemax.client.lib.api.Event("EDITMODE_IN", this, {}));
        },

        notifyApplicationError : function(error){
            if(!error) return;

            var message = error.message;
            if(!(message instanceof Array)){
                message = [{message : message, msgDetail : error.msgDetail}];
            }

            if(this.__root){
                this.__root.showErrorUI(message);
            }else{
                var messageText = message[0].message;

                SVMX.getCurrentApplication().showMessage({
                    type: "CUSTOM",
                    title: TS.T("FSA008_TAG069", "Error"),
                    text: messageText,
                    buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}]
                });
            }
        },

        getEventBus : function(){
            return this.__eventBus;
        },

        __loadInternal : function(options){
            this.__parentContainer = options.container;
            this.__sourceRecordId = this.recordId = options.recordId;
            this.record = options.record; // only exists if passed by sfw
            this.processId = options.processId;

            this.additionalInfo = options.additionalInfo || {};

            this.nextStepId = options.nextStepId;
            this.returnUrl = options.returnUrl;
            this.onEngineReady = options.onEngineReady;
            this.onEngineRendered = options.onEngineRendered;
            this.requestClose = options.requestClose;
            this.onLoadFailed = options.onLoadFailed;
            this.console = options.console;


            if (this.additionalInfo.sfwActionType !== "CHECKLIST") {
                // check if this is a qualified transaction
                // assuming that this is not an on-demand load service
                var platformSpecifics = SVMX.getClient()
                    .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

                platformSpecifics.getQualificationInfo(this.recordId, this.record, this.processId, SVMX.proxy(this, "__onQualificationInfoResponse"));
            } else {
                // This is a Checklist Selection. No qualification needed since it is not tied to a processId
                this.__onQualificationInfoResponse({isSFMProcess: true, isQualified: true});
            }
        },
        __onQualificationInfoResponse: function(qInfo){
            var currentApp = this.getEventBus(), evt = null, me = this, deliveryEngine = this;
            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            // this test is not working correctly running via proxy for the online version
            if(!qInfo.isSFMProcess || !qInfo.isQualified){

                me.__logger.error("Not qualified!");
                var dt = platformSpecifics.getBasicDisplayTags(); // This is legacy code; these tags should be moved into main sfmdelivery dictionary.
                  SVMX.getCurrentApplication().showMessage({
                      type : "CUSTOM",
                      title : " ",
                      text:qInfo.errorMessage,
                      buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}],
                      handler: SVMX.proxy(this, function() {
                        // When this fails, either we are openning a new process, in which case we don't yet have a root and need
                        // to close the window, OR we are navigating to a new process or record (linked processes) and its failed,
                        // in which case we need to reset the recordId, processId, etc... even though the UI hasn't sd.
                        this.handleInplaceBackwardNavigation();
                    })
                  });

                if (this.onLoadFailed) this.onLoadFailed.handler.apply(this.onLoadFailed.context);
                this.unblockApplication();
            }else{
                // set up splash
                var pm = SVMX.getClient().getProgressMonitor();

                // TODO: Should not create splash directly. Instead should go via SplashManager or similar
                var sp = SVMX.create("com.servicemax.client.lib.core.MiniSplash", pm);
                pm.start({params : {stepTitle : "Loading SFM Delivery Engine..."}});
                // end splash

                // it is required that at least a process Id has to me provided!
                if(!me.processId && me.additionalInfo.sfwActionType !== "CHECKLIST"){
                    pm.finish();
                    evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.NOTIFY_APP_ERROR", me, {
                        request : {
                            deliveryEngine : deliveryEngine,
                            message : "Process Id is missing!"
                        }, responder : {}}); //no need to translate this.
                    currentApp.triggerEvent(evt);
                }else{
                    evt = SVMX.create(    "com.servicemax.client.lib.api.Event",
                                        "SFMDELIVERY.GET_USERINFO",
                                        me, {
                                            request : {},
                                            responder : SVMX.create("com.servicemax.client.sfmdelivery.responders.GetUserInfoResponder", me)
                                        }
                                    );
                    currentApp.triggerEvent(evt);
                    pm.finishStep({stepTitle : "Retrieving user information..."});
                }
            }
        },

        closeProcess : function() {
            var currentApp = this.getEventBus();

            // There is no currentApp if failed qualifying criteria
            if (currentApp && this.getRootContainerId()) {

                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.CLOSE_PROCESS", this, {
                        request : {
                            requesterId: this.getRootContainerId()
                        }
                    }
                );
                currentApp.triggerEvent(evt);
            }
        },

        // Call __cleanUp when we are resetting the engine for a new process and new data
        __cleanUp : function(){
            this.closeProcess();


            if(this.__root){
                this.__root.destroy();
                delete this.__root;
            }

            if(this.__page){
                this.__page.destroy();
                delete this.__page;
            }
        },

        // Call destroy when we are destroying engine so that it can be garbage collected
        destroy : function() {
            this.__cleanUp();
            delete this.record;

            /* Release the application state handlers; TODO: These handlers should never have existed */
            var app = SVMX.getCurrentApplication();
            app.setApplicationStateHandler(null);
            app.setApplicationErrorHandler(null);
            app.setApplicationQuickMessageHandler(null);

            var eventBus = this.getEventBus();
            if (eventBus) {
                delete eventBus.eventHandlers;
            }

            engine.DeliveryEngineImpl.removeEngine(this);
                SVMX.delayedDestroy(this);
        },


        doClose : function() {
            if (this.requestClose) {
                // when sfmconsole or other console app manager gets this call it will call onClose so we can destory everything and then will shut down the window.
                this.requestClose.handler.apply(this.requestClose.context);
            } else {
                var retUrl = this.returnUrl;
                if(retUrl && retUrl != ""){
                    if(retUrl.indexOf("%2F") != -1)
                        retUrl = "/" + retUrl.substring(3, retUrl.length); // decodeURI does't work! TODO:
                    if (SVMX.navigateToCheckExternal) {
                        SVMX.navigateToCheckExternal(retUrl, false);
                    }
                    else {
                        SVMX.navigateTo(retUrl);
                    }
                }
                SVMX.doLater(function() {
                    this.destroy();
                }, this);
            }
        },

        onCanClose : function(callback) {
            if (!this.__root || this.getPageMetaData().isDisplayOnly) callback(true);
            else this.__root.cancel(false, callback);
        },

        //maintain the navigation stack here, on every forward navigation maintain the process details
        //from where navigation was triggered.
        //on every backward navigation delete the entry of the process from where the navigation was triggered
        updateNavigationStack : function(navigationDirection, processDetails){
            if(navigationDirection){
                this.__navigationStack.push(processDetails);
            }else{
                return this.__navigationStack.pop();
            }
        },

        getNavigationStack :  function(){
            return this.__navigationStack;
        },

        handleInplaceForwardNavigation : function(params){
            this.closeProcess();

            //Save parent process title in navigation stack.
            //On the linked SFM edit process, update back button with title of the calling SFM, instead of 'Cancel'.
            var sfmProcessTitle = null;
            if(this.getPageMetaData() && this.getPageMetaData().getData()) {
                sfmProcessTitle = this.getPageMetaData().getData().processTitle;
            }

            //update the parent process details
            this.updateNavigationStack(true, {recordId : this.getSourceRecordId(), record: this.record, processId : this.processId, additionalInfo: this.additionalInfo, sfmProcessTitle: sfmProcessTitle});
            var recordId = params.recordId, record = params.record, processId = params.processId;
            var additionalInfo = params.additionalInfo || {};
            var container = this.__parentContainer;
            var onEngineReady = this.onEngineReady, onEngineRendered = this.onEngineRendered;
            var onLoadFailed = this.onLoadFailed;
            var options = {
                recordId : recordId,
                record: record,
                processId : processId,
                returnUrl : this.returnUrl,
                nextStepId : "",
                container : container,
                onEngineReady :onEngineReady,
                onEngineRendered : onEngineRendered,
                requestClose: this.requestClose,
                onLoadFailed: this.onLoadFailed,
                console: this.console,
                additionalInfo: additionalInfo
            };
            this.__loadInternal(options);
        },

        handleInplaceBackwardNavigation : function(){
            this.closeProcess();

            //delete the last entry in the stack
            var navDetails = this.updateNavigationStack(false);
            if (!navDetails) {
                this.doClose();
            } else {
                var recordId = navDetails.recordId, record = navDetails.record, processId = navDetails.processId;
                var additionalInfo = navDetails.additionalInfo || {};
                var container = this.__parentContainer;
                var onEngineReady = this.onEngineReady, onEngineRendered = this.onEngineRendered;
                var onLoadFailed = this.onLoadFailed;
                    var options = {
                        recordId: recordId,
                        record: record,
                        processId: processId,
                        returnUrl: this.returnUrl,
                        nextStepId: "",
                        container: container,
                        onEngineReady: onEngineReady,
                        onEngineRendered: onEngineRendered,
                        onLoadFailed: onLoadFailed,
                        requestClose: this.requestClose,
                        console: this.console,
                        additionalInfo: additionalInfo
                    };
                this.__loadInternal(options);
            }
        },

        navigateToViewprocess : function(params){
            this.closeProcess();

            var recordId = params.recordId;
            var record = params.record;
            var processId = params.processId;

            var additionalInfo = params.additionalInfo || {};
            var de = params.engine, container = de.getRootContainerId(), nextStepId = de.nextStepId;
            var returnUrl = de.returnUrl, onEngineReady = de.onEngineReady, onEngineRendered = de.onEngineRendered, onLoadFailed = de.onLoadFailed;

                var options = {
                    recordId: recordId,
                    record: record,
                    processId: processId,
                    returnUrl: this.returnUrl,
                    nextStepId: "",
                    container: container,
                    returnUrl: returnUrl,
                    nextStepId: nextStepId,
                    onEngineReady: onEngineReady,
                    onEngineRendered: onEngineRendered,
                    onLoadFailed: onLoadFailed,
                    requestClose: this.requestClose,
                    console: this.console,
                    additionalInfo: additionalInfo
                };
            this.__loadInternal(options);
        },

        appDataHasBeenUpdated : function(inData) {
            if (inData.engine == this) return;
            // Need to reload Checklist list page when checklist is edited.
            if (this.getMetaModel().getProcessType() === "CHECKLIST LIST") {
                    this.processPageData();
                    return;
            }
            if (inData.changedData) {
                for (var i = 0; i < inData.changedData.length; i++) {
                    var id = inData.changedData[i].Id;
                    if (id == this.recordId) {
                        // TODO: Need to place a warning in this page before replacing their data
                        // but we must replace their data or they can overwrite the last change with
                        // their stale data

                        this.processPageData();
                    }
                }
             }
        },


        run : function(options){

            this.__logger.debug("Finally running delivery engine!!!");
            var recordId   = options.SVMX_recordId || SVMX.getUrlParameter("SVMX_recordId");
            var record     = options.SVMX_record; // only exists if passed by sfw
            var processId  = options.SVMX_processId || SVMX.getUrlParameter("SVMX_processId");
            var returnUrl  = options.SVMX_retURL || SVMX.getUrlParameter("SVMX_retURL");
            var nextStepId = options.SVMX_NxtStepID || SVMX.getUrlParameter("SVMX_NxtStepID");
            var sfwActionType = options.SVMX_action || SVMX.getUrlParameter("SVMX_action");

            // For these if we were given the string null, lets make it official
            sfwActionType = (sfwActionType !== "null") ? sfwActionType : null;
            processId = (processId !== "null") ? processId : null;
            recordId = (recordId !== "null") ? recordId : null;

            var additionalInfo = options.additionalInfo || {};

            if (!additionalInfo.sfwActionType) {
                additionalInfo.sfwActionType = sfwActionType;
            }

            if (!options.additionalInfo) {
                // Information required by Checklists
                additionalInfo.targetId = SVMX.getUrlParameter("SVMX_targetId");
                additionalInfo.status = SVMX.getUrlParameter("SVMX_status");
                // Needed during creation of new Checklist records
                additionalInfo.sfProcessId = SVMX.getUrlParameter("SVMX_sfProcessId");
            }

            var isConsole = SVMX.getClient().getApplicationParameter("sfmconsole-runtime-mode") === "CONSOLE";

            if (!isConsole && !record && !recordId && "svmx_sfm_delivery_test_record" in window) {
                recordId = window["svmx_sfm_delivery_test_record"];
            }
            //TODO: DO WE ALSO NEED TO CHECK sfwActionType
            if (!isConsole && !processId && "svmx_sfm_delivery_test_process" in window) {
                processId = window["svmx_sfm_delivery_test_process"];
            }

            var options = {
                recordId : recordId,
                record : record,
                processId : processId,
                returnUrl : returnUrl,
                nextStepId : nextStepId,
                sfwActionType : sfwActionType,
                onEngineReady: options.onReady,
                onEngineRendered : options.onRendered,
                requestClose : options.requestClose,
                onLoadFailed : options.onLoadFailed,
                container : options.container,
                console : options.console,
                additionalInfo: additionalInfo
            };

            this.__loadInternal(options);
        },

        onGetUserInfoCompleted : function(userInfo){
            var me = this;
            // inform all the interested parties about the available user info
            //
            // Since user info is loaded by SFM delivery, it is the responsibility of the
            // delivery to trigger the related event. But CONSOLE owns this event.
            // !! TODO: Move this code to console when console takes over complete control.
            var client = SVMX.getClient();
            var evtUserInfo = SVMX.create("com.servicemax.client.lib.api.Event",
             "GLOBAL.HANDLE_USER_INFO", this, userInfo);
            client.triggerEvent(evtUserInfo);
            // end user info related event

            var pm = SVMX.getClient().getProgressMonitor();
            var currentApp = this.getEventBus();
            var sourceRecord  = null;

            if(this.__page && this.__page.__dataModel && this.__page.__dataModel.__data && this.__page.__dataModel.__data.__data && this.__page.__dataModel.__data.__data.sfmData){
                sourceRecord = this.__page.__dataModel.__data.__data.sfmData.sourceRecord;
            }
            /**
             * The first set of calls include
             * 01. Getting the display tags
             * 02. Get the page layout
             */
            //By default create eventcollection only with getpagelayout rest shud be created only if inplacenavigation is false
            var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection",currentApp,
            [
                SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.GET_PAGELAYOUT", this,
                    {
                        request : {
                            recordId : this.recordId,
                            processId : this.processId,
                            additionalInfo: this.additionalInfo,
                            sourceRecord: sourceRecord
                        }
                    }
                ),
                SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.GET_RECORD_ALREADY_OPEN", this,
                    {
                        request: {
                            recordId: this.recordId,
                            additionalInfo: this.additionalInfo
                        }
                    }
                )
            ]);

            if(this.getNavigationStack().length == 0){
                ec.addEvent(SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.RETRIEVE_SETTINGS", this, {request : {moduleId : "SFM002"}}));
            }

            pm.finishStep({stepTitle: "Retrieving pagelayout and settings..."});
            pm.start({params :{stepTitle : "Processing pagelayout and settings..."}});
            ec.triggerAll(function(evtCol){
                var items = evtCol.items(), size = items.length, i, forceReadonly;
                var sfmRootType = null;
                for(i = 0; i < size; i++){
                    var item = items[i];
                    if (item.type() === "SFMDELIVERY.GET_RECORD_ALREADY_OPEN") {
                        forceReadonly = item.response;
                    }
                }

                for(i = 0; i < size; i++){
                    var item = items[i];
                    if(item.type() == "SFMDELIVERY.GET_PAGELAYOUT") {
                        this.__cleanUp();

                        if (!SVMX.getClient().getApplicationParameter("svmx-sfm-delivery-disable-test-record-open")) {
                            if (forceReadonly && (item.response.response.sfmProcessType == "STANDALONE EDIT"
                                    || item.response.response.sfmProcessType == "SOURCE TO TARGET CHILD"
                                    || item.response.response.sfmProcessType == "CHECKLIST")) {
                                if (item.response.response.sfmProcessType == "CHECKLIST") {
                                    // Let us know this is a view process
                                    this.additionalInfo.specialProcessType = "VIEW";
                                } else {
                                    item.response.response.sfmProcessType = "VIEW RECORD";
                                }

                                this.showMessage({
                                    type: "CUSTOM",
                                    text: TS.T("FSA008_TAG123", "Opening as view-only because this record is already opened for editing"),
                                    buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}],
                                    handler: function() {}
                                });
                            }
                        }

                        // We have multiple specialized root containers, we will need to know which to load later.
                        sfmRootType = item.response.response.sfmProcessType;
                        if (sfmRootType && (sfmRootType === "CHECKLIST" || sfmRootType === "CHECKLIST LIST")) {
                            this.__page = SVMX.create( "com.servicemax.client.sfmdelivery.engine.SFMChecklistPageMetaModel", item.response, userInfo, this);
                            if(sfmRootType === "CHECKLIST"){
                                this.__page._sourceRecord = item.__event.data.request.sourceRecord;
                            }
                            if(item.__event.data.request.additionalInfo.targetId === undefined || item.__event.data.request.additionalInfo.targetId == null) {
                                this.__page.checklistStatus = 'Not Started';    
                            }
                        } else {
                            this.__page = SVMX.create( "com.servicemax.client.sfmdelivery.engine.SFMPageMetaModel", item.response, userInfo, this);
                        }

                        // XSS injection protection
                        if (this.__page && this.__page.getData() && this.__page.getData().processTitle) {
                            this.__page.getData().processTitle = Ext.String.htmlEncode(this.__page.getData().processTitle);
                        }

                        this.__objectNameMap = {
                            header: item.response.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"]
                        };
                        SVMX.array.forEach(item.response.page.details, function(item) {
                            this.__objectNameMap[item.DetailLayout.Id] =
                                item.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
                        },this);

                        this.__lookupDisplayFieldMap = item.response.lookupDisplayFieldMap;
                    }
                    else if(item.type() == "SFMDELIVERY.RETRIEVE_SETTINGS") {
                        this.__settings = SVMX.create("com.servicemax.client.sfmdelivery.engine.Settings", item.response);
                    }
                }

                /**
                 * initialize the page meta model
                 * 01. Describes the target object
                 */
                this.__page.initialize(function(){
                    pm.finishStep({stepTitle : "Processing pagelayout and settings..."});
                    pm.start({params : {stepTitle : "Starting to layout..."}});


                    // Create the root container
                    if(this.__rootContainerId == null || this.__rootContainerId == undefined){
                        this.__rootContainerId = "svmx_sfm_delivery_root_container" + rootContainerIdCounter++;
                    }
                    var options = {
                        id : this.__rootContainerId,
                        deliveryEngine : this,
                        consoleAppInstance: this.console
                    };

                    if(!this.__parentContainer){
                        options.renderTo = SVMX.getDisplayRootId();
                    }

                    var sfmroot = null;
                    if (sfmRootType && (sfmRootType === "CHECKLIST" || sfmRootType === "CHECKLIST LIST")) {
                        sfmroot = this.__view.createComponent("CHECKLISTROOTCONTAINER", options);
                    } else {
                        sfmroot = this.__view.createComponent("ROOTCONTAINER", options);
                    }

                    if (sfmroot) {
                        //var sfmroot = SVMX.create("com.servicemax.client.sfmdelivery.ui.desktop.impl.SFMRootContainer", options);
                        sfmroot.blockApplication();

                        // Defect #024823
                        // For View Record process, below methods will be called after setting data to model
                        if(sfmRootType != "VIEW RECORD"){
                            sfmroot.compose(this.__page);
                        }

                        this.__root = sfmroot;
                    }
                    //close the progress monitor
                    pm.finish();

                    // process the page data
                    this.processPageData();


                    if (this.onEngineReady) this.onEngineReady.handler.apply(this.onEngineReady.context);
                }, this);

            }, this);
        },

        getRootContainerId : function(){
            return this.__rootContainerId;
        },

        getObjectNameMap : function() {
            return this.__objectNameMap;
        },

        notifyDataChange: function(data) {
            if (this.recordId === data.recordId) {
                this.processPageData();
            }
        },

        processPageData : function(){
            var me = this;
            var currentApp = this.getEventBus();
            var processType = this.getMetaModel().getProcessType();
            var commandName = (processType === "CHECKLIST LIST") ? "SFMDELIVERY.GET_TEMPLATEDATA" : "SFMDELIVERY.GET_PAGEDATA";
            var qualify = true;

            // Temp until we figure out what data we will pass
            if (processType === "CHECKLIST" && this.additionalInfo ) {
                this.checklistId = this.additionalInfo.targetId; // The target Checklist__c record ID
                // this.record = null; // We do not want this for a checklist

                // We do not want to re-qualify.
                if (this.additionalInfo.qualify === false) {
                    qualify = false;
                }
            }

            var request = {
                recordId : this.recordId,
                targetId : this.checklistId, //Move to optional params
                // LAP-5812: The passed in record may still be used for qualification purpose.
                // But we always get new record since display name is based on Process Def.
                //record: this.record,
                processId : this.processId,
                qualify : qualify,
                refreshData : false,
                objectNameMap: this.getObjectNameMap(),
                lookupDisplayFieldMap: this.__lookupDisplayFieldMap,
                layout : this.getMetaModel().getDeliveryEngine().__page.getData()
            };

            //IF - ELSE condition must be removed. Just add qualify = true based on proper condition.
            if(this.getNavigationStack().length > 0){
                request.qualify = qualify;
                request.requesterId = this.getRootContainerId();
            }
            else{
                request.requesterId = this.getPageMetaData().isDisplayOnly ? null : this.getRootContainerId();
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                commandName, this, {
                    request : request,
                    responder : SVMX.create("com.servicemax.client.sfmdelivery.responders.GetPageDataResponder", this)
                });
            currentApp.triggerEvent(evt);

            // In certain cases the SFW needs to ensure all Child Line Items are loaded first.
            // In that case, we will run this later for only Work Orders
            var currObjName = this.record && this.record.attributes && this.record.attributes.type;
            var testObjName = SVMX.OrgNamespace + "__Service_Order__c";
            if (currObjName !== testObjName || (currObjName === testObjName && !SVMX.getClient().getApplicationParameter("InstallBase"))) {
                if (this.__root) this.__root.run();
            }
        },

        onGetPageDataCompleted : function(data){
            var me = this, isView = true;
            //SLA CLock
            if (this.getPageMetaData() && this.getPageMetaData().isDisplayOnly) {
                try {
                    var isSLAClockEnabled = SVMX.getClient().getApplicationParameter("enable-sla-clock");
                    if(this.__root && isSLAClockEnabled && data && data.__data){
                        var type = data.__data.pageDataSet.sobjectinfo.attributes.type;
                        var objType = this.__page.getObjectLabel(type);
                        if(objType == 'Work Order' || objType == 'Case'){
                            // Check and see if there is a SLA Clock definitions
                            var declaration = SVMX.getClient().getDeclaration("com.servicemax.client.sfmdelivery.slaclock");
                            if (declaration) {
                                var definitions = SVMX.getClient().getDefinitionsFor(declaration);
                                if (definitions && definitions.length > 0) {
                                    var definition = definitions[0];
                                    var slaClassName = definition.config['class-name'];
                                    this.slaclockobj = SVMX.create(slaClassName, {
                                        object_data    : data,
                                        object_settings : this.__settings.__data,
                                        container    : this.__root.__childrenCollection[0],
                                        objectType : objType,
                                        user_info : this.__page.__userInfo,
                                        rootId : this.getRootContainerId()
                                    });
                                }
                            }
                        }
                    }
                }
                catch(e)
                {
                     this.__logger.error("Warning : SLA CLOCK NOT SUPPORTED" , e);
                }
            }
            // End SLA CLock
            if(data.isQualified == false){
                this.unblockApplication();

                SVMX.getCurrentApplication().showMessage({
                    type: "CUSTOM",
                    title: " ",
                    text: TS.T("FSA008_TAG124", "Record saved successfully, but does not meet the qualification criteria for this SFM transaction any longer. This transaction will now close."),
                    buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}],
                    handler: SVMX.proxy(this, function(buttonId){
                        this.handleInplaceBackwardNavigation();
                    })
                });
                this.triggerViewLoadedEvent(isView, false, this);
                return;
            }
            if (data && data.getError()) {
            //Temporary Fix for empty pop up, data.getError returns empty array/object sometimes
                if($.isEmptyObject(data.getError()) == false){
                    this.unblockApplication();

                    SVMX.getCurrentApplication().showMessage({
                        type: "CUSTOM",
                        title: " ",
                        text: data.getError(),
                        buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}],
                        handler: SVMX.proxy(this, function(buttonId){
                            this.doClose();
                        })
                    });
                    this.triggerViewLoadedEvent(isView, false, this);
                    return;
                }
            }
            this.recordId = data.getValueFromPath("Id");
            delete this.record; // insure that any attempt to reload the record data doesn't use cached data

            var tableId, model = this.__page.getDataModel();

            if(this.__root && this.getMetaModel().getProcessType() == "VIEW RECORD" && !this.getTargetData().getData()){
                // Defect #024823
                // No need to execute bindings for View Record process,
                // RootContainer will execute those bindings while adding components
                this.__clonedData = SVMX.cloneObject(data.__data.sfmData.getRawValues());
                this.getTargetData().setData(data, false);
                this.__root.compose(this.__page);
                isView = true;
            }else{
                isView = false;
                if(this.__root && this.getMetaModel().getProcessType() == "VIEW RECORD"){
                    this.__modifiedFields = this.getModifiedFields(this.__clonedData, data.__data.sfmData.getRawValues());
                    this.__clonedData = SVMX.cloneObject(data.__data.sfmData.getRawValues());
                    isView = true;
                }
                this.getTargetData().setData(data, true, this.__modifiedFields, isView);
            }

            /**
            * Defect #023564
            * Reload sfw so sfwdata is updated and buttons will be re-enabled
            */
            if(this.__root && this.__root.__sfwPanel && this.__root.__sfwPanel.__sfw.doReload) {
                this.__root.__sfwPanel.__sfw.reload();
                this.__root.__sfwPanel.__sfw.doReload = false;
            }

            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "DATA_LOADED", this, this.__page.getDataModel());
            this.getEventBus().triggerEvent(evt);

            this.__userTrunk = data.__data.svmxConstants && SVMX.array.filter(data.__data.svmxConstants, function(item) {return item.key === "SVMX.USERTRUNK";})[0];
            if (this.__userTrunk) this.__userTrunk = this.__userTrunk.value;


            // set up the automation
            // TODO: SFMConsole should take over launching the automation client
            // This should be driven by parameters and on explicit conditional basis only
            if(com.servicemax.client.automation){
                var ac = new com.servicemax.client.automation.automationclient.impl.AutomationClient({root : this.__root});
                ac.run({tsPath : SVMX.getUrlParameter("svmx-testcase") || ""});
            }
            // end set up automation

            // if this page has  "On Load configured", trigger the event
            var eventInfo = this.__page.getHeaderMetaModel().getPageEventInfoFor("On Load");
            if(eventInfo){
                // block the UI
                this.blockApplication();
                var currentApp = this.getEventBus(), evt;

                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                 "SFMDELIVERY.INVOKE_EVENTS", this, {request : {
                    events : [eventInfo],
                    data : this.getTargetData().getData(),
                    metadata : this.getPageMetaData().getRawPageMetaData(),
                    deliveryEngine : this,
                    additionalInfo : {
                        sfmProcessId : this.processId,
                        nextStepId: this.nextStepId
                    }
                 }, responder : SVMX.create("com.servicemax.client.sfmdelivery.responders.InvokeEventsResponder", this)});
                currentApp.triggerEvent(evt);
            }

            var type = data.__data.pageDataSet.sobjectinfo.attributes.type;
            var displayType = this.__page.getObjectLabel(type);
            if (this.onEngineRendered) {
                var name = data.__data.pageDataSet.sobjectinfo.getNameValue ? data.__data.pageDataSet.sobjectinfo.getNameValue() || "" : "";

                if (this.__root.__sfwPanel) {
                    //rename sfw
                    var sfwTitle = this.__root.__sfwPanel.defaultTitle + ': '+ name;
                    // XSS protection
                    sfwTitle = Ext.String.htmlEncode(sfwTitle);

                    this.__root.__sfwPanel.setTitle(sfwTitle)
                }

                if (name) name = Ext.String.htmlEncode(name) + ": &nbsp;&nbsp;";
                this.onEngineRendered.handler.apply(
                     this.onEngineRendered.context,
                    [displayType,name + this.__page._data.processTitle]
                );
            }
            this.updateConflictState();


            if (this.getRoot()) {
                this.getRoot().onDataUpdated(this.getTargetData());

                // In certain cases the SFW needs to ensure all Child Line Items are loaded first.
                // In that case, we will run this later for only Work Orders
                var currObjName = this.getTargetData().getData().getRawData().sfmData.attributes.type;
                var testObjName = SVMX.OrgNamespace + "__Service_Order__c";
                if (currObjName === testObjName && SVMX.getClient().getApplicationParameter("InstallBase")) {
                    if (this.__root) this.__root.run();
                }

                // There's a strange lag (probably extjs) between this point and rendering
                // data
                SVMX.timer.job(this.getRoot().getId() + ".unblockApplication", 50, this, "unblockApplication");
                this.triggerViewLoadedEvent(isView, true, this);
            }

        },

        /**
         * Get the modified feild names by comparing 2 objects
         * @param  {array} oldData  object containing old data
         * @param  {array} newData  object containing new data
         * return array of modified field names.
         */
        getModifiedFields: function(oldData, newData){
            var result = [];
            for(var k in newData){
                    if(newData.hasOwnProperty(k)){
                        if(newData[k] !== oldData[k])
                            result.push(k);
                    }
            }
            return result;
        },

        triggerViewLoadedEvent : function(isView, sendWindowId, engContext){

            if(isView && this.__clientType && this.__clientType.toLowerCase() === 'laptop'){
                var currentApp = SVMX.getCurrentApplication(), data = null;

                if(sendWindowId){
                    data = engContext.requestClose.context;
                }

                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                     "SFMDELIVERY.VIEW_LOADED", engContext, data);
                currentApp.triggerEvent(evt);
            }
        },

        loadViewProcesses : function(record, loadViewProcessesCallback, includeCurrentView) {
            if (this.getPageMetaData().isDisplayOnly) {
                var currentApp = this.getEventBus();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                     "SFMDELIVERY.GET_VIEW_PROCESSES", this, {
                         request : {
                             record: record
                         },
                         responder:SVMX.proxy(this, "viewProcessesLoaded", loadViewProcessesCallback, includeCurrentView)
                 });
                 currentApp.triggerEvent(evt);
             }
        },

        viewProcessesLoaded: function(loadViewProcessesCallback, includeCurrentView, processes) {
            if (!includeCurrentView) {
                processes = SVMX.array.filter(processes, function(p) {
                    return this.processId != p.process_unique_id;
                }, this);
            }
            else {
                processes = SVMX.array.map(processes, function(p) {
                    p.isCurrentView = this.processId === p.process_unique_id;
                    return p;
                }, this);
            }

            this.getPageMetaData().setAssociatedViewProcesses(processes);
            if (this.getRoot()) {
                this.getRoot().setAssociatedViewProcesses(this.getPageMetaData().associatedViewProcesses);
            }

            if (loadViewProcessesCallback) {
                loadViewProcessesCallback(processes);
            }
        },

        updateConflictState : function() {
            var currentApp = this.getEventBus();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                 "SFMDELIVERY.GET_RECORD_CONFLICTED", this, {
                     request : {
                         recordId: this.recordId
                     },
                     responder: SVMX.proxy(this, "setConflictState")
             });
             currentApp.triggerEvent(evt);
        },

        setConflictState : function(inConflict) {
            var wasConflict = Boolean(this.__isConflict);
            this.__isConflict = Boolean(inConflict);
            if (this.getRoot()) this.getRoot().setConflictState(inConflict);
            if (inConflict && wasConflict != this.__isConflict && !this.getPageMetaData().isDisplayOnly) {
                this.showMessage({
                    type: SVMX.baseCSSPrefix + "sfmd-sync-conflict-medium-icon",
                    text: TS.T("FSA008_TAG125", "This record has changed on the server.  Editing this record may result in errors"),
                    buttons: [{text : TS.T("FSA016_TAG003", "OK"), itemId : "OK"}],
                    handler: function() {}
                });
            }
        },

        onInvokeEventsComplete : function(){
            // unblock the UI
            this.unblockApplication();
        },

        blockApplication : function(params) {
            var p = params || {newState : "block"};
            var currentApp = this.getEventBus();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                                  "SFMDELIVERY.CHANGE_APP_STATE", this, p);
            currentApp.triggerEvent(evt);
        },

        unblockApplication : function(params) {
            var p = params || {newState : "unblock"};
            var currentApp = this.getEventBus();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "SFMDELIVERY.CHANGE_APP_STATE", this, p);
            currentApp.triggerEvent(evt);
        },

        getTargetData : function(){
            return this.__page.getDataModel();
        },

        getPageMetaData : function(){
            return this.__page;
        },

        getMetaModel : function() {
            return this.__page;
        },

        saveToModel : function(validate){
            var ret = this.__page.getDataModel().readBindings(validate);
            return ret;
        },

        resolveModel : function(){
            var ret = this.__page.getDataModel().resolveBindings();
            return ret;
        },

        getSettings : function(){
            return this.__settings;
        },

        getRoot : function(){
            return this.__root;
        },

        getUserTrunk : function() {
            if (this.__userTrunk === null || this.__userTrunk === undefined) return "";
            return this.__userTrunk;
        },

        getSourceRecordId : function() {
            return this.__sourceRecordId;
        },

        // Probably will always be the same as sourceRecordId
        getRecordId : function() {
            return this.recordId;
        },

        isFieldUpdatesEnabled: function(){
            var isFieldUpdateEnabled = SVMX.getClient().getApplicationParameter("svmx-fieldvalue-updates-enable");
            if(isFieldUpdateEnabled === false){
                return false;
            }
            return true;
        },
        refreshFromServer:function(refreshFromServerOptions,viewRefreshCallbackOnDataReceived){

            var currentApp = this.getEventBus();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "SFMDELIVERY.DOWNLOAD_RECORD_ON_DEMAND", this, {
                    request: {
                        data: {
                            recordId: refreshFromServerOptions.recordId,
                            objectName: refreshFromServerOptions.objectName
                        },
                        callback:viewRefreshCallbackOnDataReceived
                    }
                });
            SVMX.getCurrentApplication().triggerEvent(evt);


        },
        isRecordDownloadedOnDemand:function(){
            var defResult=$.Deferred();
            var me=this;
            var currentApp = this.getEventBus();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "SFMDELIVERY.IS_DOD_RECORD", this, {
                    request : {
                        recordId: this.recordId
                    },
                    responder: function(dodStatusData){
                        if(dodStatusData && dodStatusData.length>0) {
                            defResult.resolve(true);
                        }
                        else {
                            defResult.resolve(false);
                        }
                    }
                });
            currentApp.triggerEvent(evt);

            return defResult;
        }
    },

    // Statics
    {
       engines : [],
       addEngine : function(e) {
           this.engines.push(e);
       },
       removeEngine : function(e) {
           SVMX.array.remove(this.engines, e);
       }
    });

    engine.Class("EngineUpdaterExtension", com.servicemax.client.lib.api.AbstractExtension, {
        perform : function(caller, inData){
            for (var i = 0; i < engine.DeliveryEngineImpl.engines.length; i++) {
                var e = engine.DeliveryEngineImpl.engines[i];
                e.appDataHasBeenUpdated(inData);
            }
            var d = new $.Deferred();
            d.resolve();
            return d;
        }
    });


    engine.Class("Settings", com.servicemax.client.lib.api.Object, {
        __data : null,
        __constructor : function(data){
            this.__data = {};

            var settings = data.stringMap, i, l = settings.length, s;
            for(i = 0; i < l; i++){
                s = settings[i];
                this.__data[s.key] = s.value;
            }
        },

        getSetting : function(key, type){
            var ret = this.__data[key];
            if(type && ret){
                if(type == 'bool'){
                    if(ret.toLowerCase() == 'true'){
                        ret = true;
                    }else{
                        ret = false;
                    }
                }
            }

            return ret;
        }
    }, {});

    ///////////////////////////////////////////// START - DATA MODEL ///////////////////////////////////////////////////
    engine.Class("SFMPageModel", com.servicemax.client.lib.api.Object, {
        __allBindings : null, __allBindingsHash : null,
        __data : null, __detailsBindings : null,
        __logger : null, __parent : null,
        __constructor : function(parent){
            this.__allBindings = [];
            this.__allBindingsHash = {};
            this.__detailsBindings = {};
            this.__parent = parent;
            this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-PAGE-MODEL");
        },
        destroy: function() {
            if (this.__data) this.__data.unbindContext(this);

            SVMX.array.forEach(this.__allBindings, function(item) {item.destroy();});
            SVMX.forEachProperty(this.__allBindingsHash, function(inKey, inValue) {inValue.destroy();});
            SVMX.forEachProperty(this.__detailsBindings, function(inKey, inValue) {inValue.destroy();});
            SVMX.delayedDestroy(this);
        },

        setData : function(data, bExecuteBinding, modifiedFieldNames, isViewProcess){
            this.__data = data;

            //Evaluate field update rules
            this.__parent.evaluateFieldUpdateRules();

            // set up the event listeners to get notified when data is updated
            this.__data.bind("MODEL_UPDATED", function(){
                this.executeBinding();
            }, this);

            this.__data.bind("DETAIL_RECORDS_ADDED", function(evt){
                this.__onNewRecordsAdded(evt.data);
            }, this);

            this.__data.bind("DETAIL_RECORDS_DELETED", function(evt){
                var bindingPath = evt.data.bindingPath, lines = evt.data.lines;
                this.__detailsBindings[bindingPath].onRecordsDeleted(lines);
            }, this);

            if(bExecuteBinding){
                if(isViewProcess){
                    //this condition is executed for view reload for MFL only
                    this.executeBindingForViewWithDetails(modifiedFieldNames);
                }
                else{
                    this.executeBinding();
                }
            }
        },

        __onNewRecordsAdded: function(data) {
              var bindingPath = data.bindingPath,
                layoutId = data.bindingPath.replace(/^details\./,""),
                lines = data.newRecords.lines,
                onSuccess = data.onSuccess,
                i,
                l = lines.length;

            for(i = 0; i < l; i++){
                var valueLine = lines[i];
                lines[i] = this.__restructureDetailLine(valueLine, bindingPath);
            }

            var deliveryEngine = this.__parent.getDeliveryEngine();
            var currentApp = deliveryEngine.getEventBus();
            var sfmProcessId = deliveryEngine.processId;
            var metamodel = SVMX.array.get(this.__parent.getData().page.details, function(item) {return item.dtlLayoutId == layoutId;});

            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.GET_DETAIL_MAPPEDINFO", this,
                    {request : {
                        processId : sfmProcessId, alias : layoutId
                    },
                     responder :
                        SVMX.create("com.servicemax.client.sfmdelivery.responders.GetDetailMappedInfoResponder", this, lines, data.bindingPath, onSuccess)});
            currentApp.triggerEvent(evt);

        },

        getModelRoot: function() {
            return this.__parent;
        },


        onGetDetailMappedInfoComplete : function(mappedInfo, params, bindingPath, callback){
            var metamodel = this.__parent.getDetailMetaModel().getDetail(bindingPath);
            var i, k, ml, l = params.length, rec, mappedValues = mappedInfo.mappedValues, j, mv, val;
            // can't evaluate CURRENTRECORD fields without first resolving CURRENTRECORDHEADER fields
            var mappedLiterals = mappedInfo.mappedLiterals.sort(function(a,b) {
                return  (a.value.match(/^SVMX.CURRENTRECORD\./)) ? 1 : -1;
            });

            /* TEST DATA; REMOVE WHEN SERVER HAS VALID DATA
            mappedLiterals = [
            {key: "SVMXC__End_Date_and_Time__c", value: "Today"},
            {key: "SVMXC__Consumed_From_Location__c", value: "SVMX.USERTRUNK"},
            {key: "SVMXC__Date_Received__c", value: "SVMX.CURRENTRECORD.SVMXC__End_Date_and_Time__c"},
            {key: "SVMXC__Date_Requested__c", value: "SVMX.CURRENTRECORDHEADER.LastModifiedDate"},
            {key: "SVMXC__Received_Country__c", value: "SVMX.CURRENTRECORDHEADER.SVMX__Country__c"}];*/

            var objectName = metamodel.objectName;
            var recordTypeInfos = this.getModelRoot().getRecordTypesFor(objectName);

            var dateFormat = metamodel.getRoot().getUserInfo().DateFormat;
            var timeFormat = metamodel.getRoot().getUserInfo().TimeFormat;
            var describeObject = metamodel.getRoot().objMetadataMap[objectName];
            var fields = describeObject.fields;

            // update reference fields
            SVMX.array.forEach(params, SVMX.proxy(this, function(rec, recordIndex) {
                var i,mv,val;

                // Copy in mappedValues for the current record.
                for(i = 0; i < mappedValues.length; i++){
                    var recordTypeEntry, recordTypeName;
                    mv = mappedValues[i];

                    // update the direct value
                    val = rec[mv.key];

                    // RecordTypeId mappings come as untranslated names and Ids, which must be mapped to the translated names
                    if (mv.key == "RecordTypeId") {
                        recordTypeEntry = SVMX.array.get(recordTypeInfos, function(recordTypeInfo) {return recordTypeInfo.fixedName == mv.value;});
                        if (recordTypeEntry) recordTypeName = recordTypeEntry.name;
                    }

                    if(val){
                        rec[mv.key] = mv.value;
                        // boolean handling
                        var fieldInfo = metamodel.getFieldInfo(mv.key);
                        if(fieldInfo && fieldInfo.datatype === "boolean"){
                            var tempValue = rec[mv.key + "__key"];
                            if(tempValue && tempValue.value != mv.value){
                                tempValue.key = mv.value;
                            }
                        }
                        if (mv.key == "RecordTypeId") rec[mv.key] = recordTypeName;
                    }

                    // update __key too
                    val = rec[mv.key + "__key"];
                    if(val && val.value != mv.value){
                         val.value = mv.value;
                         if (mv.key === "RecordTypeId") {
                             if (recordTypeEntry) {
                                 val.value = recordTypeEntry.name;
                                 val.key = recordTypeEntry.recordTypeId;
                             } else {
                                 val.key = "";
                             }
                         }
                    }
                }

                var displayMode, key, value, ml,  fieldDef;
                for(var i = 0; i <  mappedLiterals.length; i++){
                    ml = mappedLiterals[i];

                    var fieldName = mappedLiterals[i].key,
                        displayMode = null,
                        dtValue = rec[fieldName];

                    fieldDef = SVMX.array.filter(fields, function(f) {return f.name == fieldName})[0];

                    if(fieldDef) {
                        displayMode = fieldDef.type;
                    }
                    value = ml.value; // If none of the if statements below fire, then ml.value contains a literal value.
                    key = value;

                    // Its a date constant
                    if (SVMX.array.indexOf(["Now", "Today", "Tomorrow", "Yesterday"], ml.value) != -1) {
                        key = DatetimeUtils.macroDrivenDatetime(ml.value, "YYYY-MM-DD", "HH:mm:ss");
                        if (ml.value !== 'Now' && displayMode === 'datetime') {
                            key = DatetimeUtils.convertToTimezone(key, undefined, true);
                        }
                        //Changed so data is always parsable, it is now up to the UI layer to change to a displayable format
                        value = key;
                    } else if (SVMX.array.indexOf(["SVMX.NOW", "SVMX.TODAY", "SVMX.TOMORROW", "SVMX.YESTERDAY"], ml.value) != -1) {
                        key = DatetimeUtils.macroDrivenDatetime(ml.value.replace(/SVMX\./,""), "YYYY-MM-DD", "HH:mm:ss");
                        if (ml.value !== 'SVMX.NOW' && displayMode === 'datetime') {
                            key = DatetimeUtils.convertToTimezone(key, undefined, true);
                        }
                        value = key;
                    } else if (ml.value.match(/SVMX\.CURRENTRECORDHEADER\./)) {
                        var getFieldName = ml.value.match(/SVMX\.CURRENTRECORDHEADER\.(.*)/)[1];
                        var root = metamodel.getRoot();
                        var bindings = root.getDataModel().__allBindingsHash;
                        // Bindings exist if the editor for the field is in the UI,
                        // else there is no editor or binding and get it directly.
                        if (bindings[getFieldName]) {
                            value = bindings[getFieldName].__getter.call(bindings[getFieldName].__context);
                        } else {
                            value = root.getDeliveryEngine().getTargetData().getData().getRawValues()[getFieldName];
                        }
                        if(value && typeof value === 'object' && 'fieldapiname' in value && 'fieldvalue' in value){
                            value = value.fieldvalue.value;
                        }
                        key = value;
                    } else if (ml.value.match(/SVMX\.CURRENTRECORD\./)) {
                        var getFieldName = ml.value.match(/SVMX\.CURRENTRECORD\.(.*)/)[1];
                        if (rec[getFieldName + "__key"]) {
                            value = rec[getFieldName + "__key"].value;
                            key = rec[getFieldName + "__key"].key;
                        } else {
                            value = rec[getFieldName];
                            key = value;
                        }
                    } else if (ml.value.match(/SVMX\.USERTRUNK/)) {
                        //SER-5612
                        //engine cannot use offline specific code only, so add case
                        //if online
                        if (!com.servicemax.client.offline) {
                            value = metamodel.getRoot().getDeliveryEngine().getUserTrunk();
                            key = value; // TODO: this probably isn't right
                        } else {
                            var utils = com.servicemax.client.offline.sal.model.utils;
                            value = utils.SystemData.getUserInfo().UserTrunkDetail ? utils.SystemData.getUserInfo().UserTrunkDetail.Name : null;
                            key = utils.SystemData.getUserInfo().UserTrunkDetail ? utils.SystemData.getUserInfo().UserTrunkDetail.Id : null;
                        }
                    } else if (ml.value.match(/SVMX\.CURRENTUSERID/)) {
                        value = com.servicemax.client.offline.sal.model.utils.SystemData.getUserInfo().UserName;
                        key = com.servicemax.client.offline.sal.model.utils.SystemData.getUserInfo().UserId; // TODO: this probably isn't right
                    }

                    // get just the value to be displayed in the grid.
                    if (value === null || value === undefined){
                        key = value = "";
                    }

                    // If there is a mapping from date to datetime or datetime to date,
                    // fix the format.
                    if (displayMode === "date" && value && value.match(/\:/)) {
                        //Defect 030210: Commented this line. Since Literal was not working for different timezone and locale.
                        //value = DatetimeUtils.getFormattedDatetime(DatetimeUtils.parseDate(value), DatetimeUtils.getDefaultDateFormat());
                    } else if (displayMode === "datetime" && value && !value.match(/\:/)) {
                        value = DatetimeUtils.getFormattedDatetime(DatetimeUtils.parseDate(value), DatetimeUtils.getDefaultDatetimeFormat());
                    }
                    if (typeof value === "object" && "value" in value) {
                        rec[ml.key] = value.value;
                        // Avoid pointer errors of assigning this to be just  = value, which will propagate a single
                        // js pointer all over.
                        rec[ml.key + "__key"] = {value: value.value, key: value.key};
                    } else if (typeof value === "object" && "fieldvalue" in value) {
                        rec[ml.key] = value.fieldvalue.value;
                        rec[ml.key + "__key"] = {fieldvalue: {value: value.fieldvalue.value, key: value.fieldvalue.key}};
                    } else if (displayMode == "reference" && dtValue){
                        rec[ml.key] = dtValue;
                    }
                    else {
                        rec[ml.key] = value;

                        // get the value to be used to talk to salesforce or database.
                        if ((ml.key + "__key") in rec) {
                            rec[ml.key + "__key"].key = key;
                            rec[ml.key + "__key"].value = value;
                        } else {
                            rec[ml.key + "__key"] = {key: key, value: value};
                        }
                    }
                }
            }));

            this.__detailsBindings[bindingPath].onNewRecordsAdded({lines:params});

            callback();
        },


        __restructureDetailLine : function(valueLine, bindingPath){
            var name, valueLineKeys = {}, fieldValue = null, value;
            for(name in valueLine){

                if(name == "attributes" || name == "attributes__key") continue;
                if (name == "__new") {
                    valueLineKeys[name] = valueLine[name];
                } else {
                    var valueLineItem = valueLine[name];
                    if(valueLineItem && typeof(valueLineItem) == 'object'){
                        fieldValue = valueLineItem.fieldvalue;
                        if(fieldValue){
                            valueLineKeys[name + "__key"] = fieldValue;
                            value = this.__parent.getDetailMetaModel().getDetail(bindingPath)
                                        .translate(valueLineItem.fieldapiname, name == "RecordTypeId" && fieldValue.key ? fieldValue.key : fieldValue.value, fieldValue);
                            valueLineKeys[name] = value;
                        }
                    }
                }
            }

            for(name in valueLineKeys){
                valueLine[name] = valueLineKeys[name];
            }

            return valueLine;
        },

        resolveBindings : function(){
            var i , l = this.__allBindings.length, ret = [];
            for(i = 0; i < l; i++){
                ret.push( this.__allBindings[i].resolveBinding() );
            }
            return ret;
        },

        validateBindings : function(){
            var i , l = this.__allBindings.length, ret = [];
            for(i = 0; i < l; i++){
                ret.push( this.__allBindings[i].validateBinding() );
            }
            return ret;
        },

        readBindings : function(validate){
            var validations = [], errors = [], i, l,
                ret = {canContinue : true, validations : validations, hasWarnings: false};

            var warnings = [];
            if(validate){
                validations = this.validateBindings();
                ret.validations = validations;
                l = validations.length;
                for(i = 0; i < l; i++){
                    if(!validations[i].isValid){
                        errors.push(validations[i]);
                    }
                    else if (validations[i].additionalInfo) {
                        warnings.push(validations[i]);
                    }
                }
            }

            ret.errors = errors;
            ret.warnings = warnings;
            ret.hasWarnings = warnings.length > 0;

            // if there are any validation errors, do not proceed
            if(errors.length > 0){
                ret.canContinue = false;

                // Event triggering move to SaveTargetRecord command

            }else{
                l = this.__allBindings.length;
                for(i = 0; i < l; i++){
                    this.__allBindings[i].persistBinding();
                }
            }

            return ret;
        },

        getData : function(){
            return this.__data;
        },

        getValueFromPath : function(path){
            var value = this.__data.getValueFromPath(path);
            if(value && typeof(value) == 'object'){
                if (path == "RecordTypeId") {
                    value = value.fieldvalue.key;
                } else {
                    value = value.fieldvalue.value;
                }
            }
            return value;
        },

        setValueToPath : function(path, value){

            if(value && typeof(value) == 'object'){
                value = {fieldvalue : value};
            }
            this.__data.setValueToPath(path, value);
        },

        getReferenceValueFromPath : function(path){
            var value = this.__data.getValueFromPath(path);
            return value;
        },

        setReferenceValueToPath : function(path, value){
            this.__data.setValueToPath(path, value);
        },

        getDetailValueFromPath : function(path){

            var value = SVMX.toJSON(this.__data.getValueFromPath(path));
            value = SVMX.toObject(value) || {};
            var i, lines = value.lines || [],
                l = lines.length;
            for(i = 0; i < l; i++){
                var valueLine = lines[i];
                lines[i] = this.__restructureDetailLine(valueLine, path);
            }

            return value;
        },

        setDetailValueToPath : function(path, value){
            //value has details lines only. We need to overwrite the UI/list lines into the datamodel
            var actualData = this.__data.getValueFromPath(path), updatedRecords = this.updateRecords(actualData, value);
            this.__data.setValueToPath(path, updatedRecords);
        },

        updateRecords : function(modelRecords, uiRecords){
            //assumption is that the line count is maintained through out Add and Delete
            var i , l = uiRecords.lines.length, uiRecord = null, modelRecord = null;
            if(!modelRecords){
                modelRecords = { lines : [] }; //FSA sends modelRecords as null. Just a guard rail to avoid script errors.
            }
            var noIdRecords = SVMX.array.filter(modelRecords.lines, function(line) {return !line.Id;});
            for(i = 0; i < l; i++){
                uiRecord = uiRecords.lines[i];
                 modelRecord = SVMX.array.get(modelRecords.lines, function(line) {return line.Id && line.Id == uiRecord.Id;});
                 if (!modelRecord) modelRecord = noIdRecords.shift(); // If there's no Id, its a new record; just affiliate it with the first available Id-less record.
                for(var name in uiRecord){
                    // don't process __key as part of the loop
                    if(name.indexOf("__key", name.length - "__key".length) !== -1) continue;
                    if (name.indexOf("_") == 0) continue;

                    var item = uiRecord[name];
                    // Defect 018772: Boolean value was being skipped.
                    var itemByKey = uiRecord[name + "__key" ];
                    if(itemByKey !== undefined && itemByKey !== "" && itemByKey != null){
                        item = itemByKey;
                    }

                    var value = null;
                    if (name == "attributes") {
                        value = item;
                    } else if(item && typeof(item) == 'object'){
                        value = {fieldapiname :name, fieldvalue : {key : item.key , value : item.value}};
                    }else{
                        value = item;
                    }
                    //Defect Fix: 023639 : Too many quick saves might not give ext to update the model
                    if(modelRecord){
                        modelRecord[name] = value;
                    }
                }
            }
            return modelRecords;
        },

        executeBinding : function(){
            this.__logger.info("Executing data bindings...");
            var i , l = this.__allBindings.length;
            for(i = 0; i < l; i++){
                this.__allBindings[i].executeBinding();
            }
        },

        /**
         * Executes Binding For modified fields and all the details
         * @param  {array} modifiedFieldArray  Array containing the field names that got modified
         */
        executeBindingForViewWithDetails : function(modifiedFieldArray){
            var len = modifiedFieldArray.length, i, detailsBindings = [];
            for(i=0; i < len ;i++){
                var field = modifiedFieldArray[i];
                var bindingObj = SVMX.array.filter(this.__allBindings, function(item) {
                    return item.__path === field;
                });

                if(bindingObj.length > 0){
                    bindingObj[0].executeBinding();
                }
            }

            //execute bindings for all details
            detailsBindings = SVMX.array.filter(this.__allBindings, function(item) {
                    return item.__path.indexOf("details.") >= 0 ;
            });
            len =  detailsBindings.length;
            for(i =0 ; i < len ; i++){
                detailsBindings[i].executeBinding();
            }
        },

        createBinding : function(path, setter, getter, context){
            var binding = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelBinding",
                    this, path, setter, getter, context);
            this.__allBindings[this.__allBindings.length] = binding;
            this.__allBindingsHash[path] = binding;
            return binding;
        },

        createPicklistBinding : function(path, setter, getter, context){
            var binding = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelPicklistBinding",
                    this, path, setter, getter, context);
            this.__allBindings[this.__allBindings.length] = binding;
            this.__allBindingsHash[path] = binding;
            return binding;
        },

        createReferenceBinding : function(path, setter, getter, context){
            var binding = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelReferenceBinding",
                    this, path, setter, getter, context);
            this.__allBindings[this.__allBindings.length] = binding;
            this.__allBindingsHash[path] = binding;
            return binding;
        },

        createDetailBinding : function(path, setter, getter, context){
            var binding = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailBinding",
                    this, path, setter, getter, context);
            this.__allBindings[this.__allBindings.length] = binding;
            this.__detailsBindings[path] = binding;
            this.__allBindingsHash[path] = binding;
            return binding;
        },

        getRelatedBindingValue : function(fieldName, source){
            // TODO : Not getting called ???
        }
    }, {});

    engine.Class("SFMChecklistPageModel", com.servicemax.client.sfmdelivery.engine.SFMPageModel, {
        __constructor : function(parent){
            this.__base(parent);
        },

        setData : function(data, bExecuteBinding){
            // First extract all the question data from the JSON strings.
            var questionAnswers = {};
            if (data && data.__data && data.__data.pageDataSet) {
                // Just being careful
                data.__data.pageDataSet.sobjectinfo = data.__data.pageDataSet.sobjectinfo || {};
                data.__data.sfmData = data.__data.sfmData || {};

                if (data.__data.pageDataSet.sobjectinfo && data.__data.pageDataSet.sobjectinfo[SVMX.OrgNamespace + "__ChecklistJSON__c"]) {
                    try {
                        questionAnswers = SVMX.toObject(data.__data.pageDataSet.sobjectinfo[SVMX.OrgNamespace + "__ChecklistJSON__c"]);
                    } catch(e) {
                        console.error("Unable to parse question answers for record: " + (data && data._targetRecordId));
                    }
                } else if (data.__data.pageDataSet.sobjectinfo && data.__data.pageDataSet.sobjectinfo.LIST_SECTION_FIELD_ID) {
                    // Parse template selection records

                    data.__data.pageDataSet.sobjectinfo.LIST_SECTION_FIELD_ID.fieldvalue.value = this.__parseTemplateResults(data.__data.pageDataSet.sobjectinfo.LIST_SECTION_FIELD_ID.fieldvalue.value);
                    data.__data.sfmData.LIST_SECTION_FIELD_ID.fieldvalue.value = data.__data.pageDataSet.sobjectinfo.LIST_SECTION_FIELD_ID.fieldvalue.value
                } else {
                    if (data && data._targetRecordId) {
                        console.warn("No checklist data for record: " + data._targetRecordId);
                    }
                }

                var root = this.getModelRoot();
                var qTypes = {};
                if (root && root.getQuestionTypes) {
                    qTypes = root.getQuestionTypes();
                }

                // For every answer make it a real field in our data
                var qName, qValue, qT;
                for (qName in questionAnswers) {
                    qValue = questionAnswers[qName];
                    qT = qTypes[qName];
                    if (qValue && qValue.fieldvalue && (qT === "multi-select picklist" || qT === "picklist")) {
                        qValue = qValue.fieldvalue.key || qValue;
                    }

                    // data.__data.sfmData and data.__data.pageDataSet.sobjectinfo are references to each other
                    //data.__data.pageDataSet.sobjectinfo[qName] = {"fieldvalue" : {"key": qValue, "value" : qValue}};
                    data.__data.sfmData[qName] = qValue;
                }
            } else {
                console.error("Missing data to set for record: " + (data && data._targetRecordId));
            }
            var processType = this.__parent.getProcessType();
            if(processType.toUpperCase() === "CHECKLIST"){
                this.getDefaultValueFromQuestion();
            }
            this.__base(data, bExecuteBinding);
        },

        //fetching current sections question
        getDefaultValueFromQuestion : function(){
            this.defaultValues = {};
            var sections = this.__parent.getDeliveryEngine().__page.getChildNode('header').getChildNode('sections');
            var sectionsLenght = sections.length;
            for(var sectionIndex = 0; sectionIndex < sectionsLenght; sectionIndex++) {
                var section = sections[sectionIndex];
                var fields = section.getChildNode('fields');
                var fieldsLength = fields.length;
                for(var fieldIndex = 0; fieldIndex < fieldsLength; fieldIndex++) {
                    var field = fields[fieldIndex];
                    if(field.datatype.toUpperCase() === 'QUESTION'){
                        if(field.dynamicResponseField){
                            var fieldInfo =  field.defaultDyamicValue;
                            if(fieldInfo){
                                var value = fieldInfo.value;
                                if(field.questionType.toUpperCase() === 'DATETIME'){
                                    if(fieldInfo.ftype === 'DATE'){
                                        value = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(value, null, true);
                                    }
                                } else if(field.questionType.toUpperCase() === 'PICKLIST' || field.questionType.toUpperCase() ==='RADIO BUTTON'){
                                    value = this.getValueFromPicklist(fieldInfo);
                                }
                                 //Getting Date Object, Taking date from object and passing 
                                if(field.questionType.toUpperCase() === 'DATETIME' || field.questionType.toUpperCase() === 'DATE'){
                                    if (value && typeof value !== 'string' && (value instanceof Date)) {
                                        value = DatetimeUtils.getFormattedDatetime(value, 'DD-MM-YYYY HH:MM:SS');
                                    }
                                }
                                this.defaultValues[field.fieldName] = value;
                            } 
                        }
                        else if(!field.isliteralUsedInDefaultValue){
                            var defaultResponseset = field.defaultValueObject;
                            if(defaultResponseset){
                                if(field.questionType.toUpperCase() === 'NUMBER'){
                                    if(defaultResponseset.listOfDefaultValues && defaultResponseset.listOfDefaultValues.length > 0){
                                        //is number is valid or not, then we are 
                                        var number = this.isNumbericValue(defaultResponseset.listOfDefaultValues[0]);
                                        if(number){
                                            this.defaultValues[field.fieldName] = number;
                                        }
                                    }
                                } else if(field.questionType.toUpperCase() === 'DATETIME'){
                                    if(defaultResponseset.listOfDefaultValues && defaultResponseset.listOfDefaultValues.length > 0){
                                        this.defaultValues[field.fieldName] = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(defaultResponseset.listOfDefaultValues[0], null, true);
                                    }
                                } else if(field.questionType.toUpperCase() === 'MULTI-SELECT PICKLIST' || field.questionType.toUpperCase() === 'CHECKBOX'){
                                    this.defaultValues[field.fieldName] = defaultResponseset.listOfDefaultValues;
                                } else {
                                    if(defaultResponseset.listOfDefaultValues && defaultResponseset.listOfDefaultValues.length > 0){
                                        this.defaultValues[field.fieldName] = defaultResponseset.listOfDefaultValues.join();
                                    }   
                                }
                            }
                        } else {
                            var defaultResponseset = field.defaultValueObject;
                            if(defaultResponseset && defaultResponseset.literalValue){
                                var date = defaultResponseset.literalValue;
                                if(date === 'Tomorrow' || date === 'Now' || date === 'Today' || date === 'Yesterday'){
                                    date = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime(date, "YYYY-MM-DD", "HH:mm:ss");      
                                    if(field.questionType.toUpperCase() === 'DATETIME'){
                                        if(defaultResponseset.literalValue !== 'Now'){
                                            this.defaultValues[field.fieldName] =  com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(date, null, true);
                                        } else {
                                            this.defaultValues[field.fieldName] = date;
                                        }
                                    }else if(field.questionType.toUpperCase() === 'DATE'){
                                        this.defaultValues[field.fieldName] = date;
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return this.defaultValues;
        },

        getValueFromPicklist:function(fieldInfo){
            var value = '';
            if(fieldInfo){
                var value = fieldInfo.value;
                var picklistLabelValue = fieldInfo.picklistLabelValue;
                if(value && picklistLabelValue){
                    var picklistLabelValueLength = picklistLabelValue.length;
                    for (var index = 0; index < picklistLabelValueLength; index++) {
                        var pickRecord = picklistLabelValue[index];
                        if(pickRecord.value === value){
                            value = pickRecord.key;
                            break;
                        }
                    }
                }
            }
            return value;
        },

        isNumbericValue : function(value){
            var number;
            if(!isNaN(value) || (!isNaN(value) && value.toString().indexOf('.') != -1)){
                number = value;
            }
            return number;
        },

        getValueFromPath : function(path){
            var value = this.__data.getValueFromPath(path);
            // Multipicklists and checkbox groups of checklists want to save as an array.
            if(value && typeof(value) == 'object' && !(value instanceof Array)){
                if (path == "RecordTypeId") {
                    value = value.fieldvalue.key;
                } else {
                    value = value.fieldvalue.value;
                }
            } else if("undefined" === typeof value){
                value = this.getDefaultValue(path);
            }
            return value;
        },

        getAttachmentValueFromPath : function(path){
            var value = this.__data.__attachementData.getAttachmentValuefromPath(path);
            return value;
        },

        setAttachmentValueToPath : function(path, value){
            var value = this.__data.__attachementData.setAttachmentValueToPath(path, value);
            return value;
        },

        getDefaultValue : function(path) {
            var value;
            if(this.defaultValues){
                value = this.defaultValues[path];
            }
            return value;
        },

        _processDateToUserTimezone : function(datetime){
            var offset = this.__parent.getUserInfo().TimezoneOffset;
            return com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(datetime, offset, false);
        },

        createAttachmentBinding : function(path, setter, getter, context){
            var binding = SVMX.create('com.servicemax.client.sfmdelivery.engine.SFMPageModelAttachmentBinding',this, path, setter, getter, context);
            this.__allBindings[this.__allBindings.length] = binding;
            this.__allBindingsHash[path] = binding;
            return binding;
        },

        __parseTemplateResults : function(data) {
            data = data || [];
            var i, field, removeTemplate, hasTemplate, allowNew, len = data.length;
            var templateIds = {}, parsedData = [];

            // Remove templates if already have checklist in progress or completed
            // Add field allowNew with appropriate answer
            for (i = 0; i < len; i++) {
                field = data[i];
                removeTemplate = (field.status !== "Qualified");
                hasTemplate = (field.status === "Qualified");
                allowNew = (field.status !== "In Process");

                if (templateIds[field.processId]) {
                    // Should we remove the template record form list
                    templateIds[field.processId].removeTemplate = removeTemplate || templateIds[field.processId].removeTemplate;
                    // Should we allow generation of a new checklist
                    templateIds[field.processId].allowNew = (templateIds[field.processId].allowNew === false) ? false : allowNew;
                    // We have a template record for this process
                    templateIds[field.processId].hasTemplate = (templateIds[field.processId].hasTemplate === false) ? hasTemplate : true;
                } else {
                    templateIds[field.processId] = {allowNew: allowNew, removeTemplate: removeTemplate, hasTemplate: hasTemplate};
                }

                field.statusLabel = "";
                switch(field.status) {
                    case 'Qualified':
                        field.statusLabel = TS.T("FSA008_TAG116", "Not Started");
                        field.actionLabel = TS.T("TODO", "");
                        field.internalLabel = "";
                        break;
                    case 'In Process':
                        field.statusLabel = TS.T("FSA008_TAG117", "In Progress");
                        field.actionLabel = TS.T("TODO", "");
                        field.internalLabel = "";
                        break;
                    case 'Completed':
                        field.statusLabel = TS.T("FSA008_TAG118", "Completed");
                        field.actionLabel = TS.T("FSA008_TAG119", "Start New");
                        field.internalLabel = "Start New";
                        break;
                    default:
                        field.statusLabel = field.status;
                }
            }

            for (i = 0; i < len; i++) {
                field = data[i];
                if (field.status === "Qualified") {
                    // This is a template record, may not want to include it
                    if (!templateIds[field.processId].removeTemplate) {
                        // Must be have a template and not be In Process
                        field.allowNew = templateIds[field.processId].allowNew && templateIds[field.processId].hasTemplate;
                        parsedData.push(field);
                    }
                } else {
                    // This is a Checklist, only allow new if we have a Qualified template
                    field.allowNew = templateIds[field.processId].allowNew && templateIds[field.processId].hasTemplate;
                    if (!field.allowNew) {
                        // We can not Start New so clear the label
                        field.actionLabel = TS.T("TODO", "");
                    }

                    parsedData.push(field);
                }
            }

            // Now sort
            parsedData.sort(function(a, b) {
                var nameA = (a.processName) ? a.processName.toLowerCase() : "";
                var nameB = (b.processName) ? b.processName.toLowerCase() : "";
                if(nameA < nameB) return -1;
                if(nameA > nameB) return 1;

                // If name is equal, sort by status
                // Know statuses (In Process, Qualified,  Completed)
                var aStatus = (a.status === "In Process") ? 1 : (a.status === "Qualified") ? 2 : 3;
                var bStatus = (b.status === "In Process") ? 1 : (b.status === "Qualified") ? 2 : 3;

                if(aStatus < bStatus) return -1;
                if(aStatus > bStatus) return 1;

                //At this point, sort by date
                var dateA = (a.completionDate) ? a.completionDate.toLowerCase() : "";
                var dateB = (b.completionDate) ? b.completionDate.toLowerCase() : "";
                if(dateA < dateB) return -1;
                if(dateA > dateB) return 1;


                return 0;
            });

            return parsedData;
        }

    }, {});

    engine.Class("SFMPageModelBinding", com.servicemax.client.lib.api.Object, {
        __path : null, __setter : null, __getter : null, __context : null, __parent : null,
        _logger : null, __validator : null, __resolver : null, __bizzRuleValidator : null,

        __constructor : function(parent, path, setter, getter, context){
            this.__path = path;
            this.__setter = setter;
            this.__getter = getter;
            this.__context = context;
            this.__parent = parent;
            this._logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-PAGE-MODEL-BINDING");
        },

        destroy: function() {
        SVMX.delayedDestroy(this);
        },

        toString : function() {
            return this.__base(this.__path);
        },

        // validator = {handler : <>, context : <>}
        setValidator : function(validator){
            this.__validator = validator;
        },

        setBizRuleValidator : function(validator) {
            this.__bizzRuleValidator = validator;
        },

        // resolver = {handler : <>, context : <>}
        setResolver : function(resolver){
            this.__resolver = resolver;
        },

        // ret = {isResolved : true/false, resolver : <function>, context : <object>}
        resolveBinding : function(){
            var ret = {isResolved : true};

            if(this.__resolver && this.__resolver.handler){
                ret = this.__resolver.handler.call(this.__resolver.context);
            }

            return ret;
        },

        // ret = {isValid : true/false, message : ""}
        validateBinding : function(){
            var ret = {isValid : true};

            if(this.__validator && this.__validator.handler){
                ret = this.__validator.handler.call(this.__validator.context);
            }

            return ret;
        },

        executeBinding : function(){
            var value = this.__parent.getValueFromPath(this.__path);
            this._logger.info("Executing (set)binding for => " + this.__path);
            this.__setter.call(this.__context, value);
        },

        getValue : function(){
            var value = this.__getter.call(this.__context);
            return value;
        },

        setValue : function(value){
            this.__setter.call(this.__context, value);
        },

        persistBinding : function(){
            var value = this.__getter.call(this.__context);
            this.__parent.setValueToPath(this.__path, value);
        },

        //for currentRecord and currentRecordHeader
        getRelatedBindingValue : function(fieldName, currentRecord){
            //Defect SER-5130
            //Check if binding exists for the field name, then get the value
            var value = "";
            if (this.__parent.__allBindingsHash[fieldName]) {
               value = this.__parent.__allBindingsHash[fieldName].getValue();
            }
            //check the datatype
            var binding = this.__parent.__allBindingsHash[fieldName];
            // compositionMetamodel.datatype was returning Reference instead DateTime Hence changed to binding.__context.compositionMetamodel
            if (binding || this.__context.getCompositionMetamodel) {
                var compositionMetamodel = this.__context.getCompositionMetamodel ?
                    this.__context.getCompositionMetamodel() : binding.__context.compositionMetamodel;

                // apply formatting to be understood by SOQL query or SQL query. When target date is null
                // Online: x=null Offline: x=''
                if(compositionMetamodel.datatype == "datetime"){
                    var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
                    var timeZoneOffset = this.__parent.__parent.getUserInfo().TimezoneOffset;
                    value = platformSpecifics.getFormattedDateTimeValue(value, timeZoneOffset);
                } else if(compositionMetamodel.datatype == "date"){
                    var platformSpecifics = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
                    value = platformSpecifics.getFormattedDateValue(value);
            }
            }
            //For reference fields
            if(value && typeof(value) == 'object'){
                value = value.key;
            }

            return value;
        }
    }, {});
    
    engine.Class("SFMPageModelAttachmentBinding", com.servicemax.client.lib.api.Object, {
        __path : null, __setter : null, __getter : null, __context : null, __parent : null,
        _logger : null, __validator : null, __resolver : null, __bizzRuleValidator : null,

        __constructor : function(parent, path, setter, getter, context){
            this.__path = path;
            this.__setter = setter;
            this.__getter = getter;
            this.__context = context;
            this.__parent = parent;
            this._logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-PAGE-MODEL-BINDING");
        },

        executeBinding : function(){
            var value = this.__parent.getAttachmentValueFromPath(this.__path);
            this._logger.info("Executing (set)binding for => " + this.__path);
            this.__setter.call(this.__context, value);
        },

        persistBinding : function(){
            var value = this.__getter.call(this.__context);
            this.__parent.setAttachmentValueToPath(this.__path, value);
        },

        setValidator : function(obj){

        },

        destroy: function() {
            SVMX.delayedDestroy(this);
        },

        validateBinding : function(){
            var ret = {isValid : true};

            if(this.__validator && this.__validator.handler){
                ret = this.__validator.handler.call(this.__validator.context);
            }

            return ret;
        }

    }, {});

    engine.Class("SFMPageModelPicklistBinding", engine.SFMPageModelBinding, {

        __constructor : function(parent, path, setter, getter, context){
            this.__base(parent, path, setter, getter, context);
        },

        executeBinding : function(){
            var value = this.__parent.getValueFromPath(this.__path);
            this._logger.info("Executing (set)binding for => " + this.__path);
            // Defect: 12020 Allow invalid mappings that are set programatically but not by user
            this.__context.forceSelection = false;
            this.__setter.call(this.__context, value);
            this.__context.forceSelection = true;
        }
    }, {});

    engine.Class("SFMPageModelReferenceBinding", engine.SFMPageModelBinding, {

        __constructor : function(parent, path, setter, getter, context){
            this.__base(parent, path, setter, getter, context);
        },

        executeBinding : function(){
            var value = this.__parent.getReferenceValueFromPath(this.__path);

            this._logger.info("Executing (set) reference binding for => " + this.__path);
            if(value && typeof(value) == 'object'){
                value = {
                    key             : value.fieldvalue.key,
                    value             : value.fieldvalue.value,
                    isNameSyncData     : value.fieldvalue.isNameSyncData,
                    hasViewSFM         : value.fieldvalue.hasViewSFM
                };
                this.__setter.call(this.__context, value);
            } else {
                this.__setter.call(this.__context, value);
            }
        },

        getValue : function(){
            var value = this.__getter.call(this.__context);
            return value;
        },

        setValue : function(value, params){
            this.__setter.call(this.__context, value, params);
        },

        persistBinding : function(){
            var value = this.getValue(), res = {fieldvalue : {key : null, value : null}};
            if(value && typeof(value) == 'object'){
                res.fieldvalue.key = value.key;
                res.fieldvalue.value = value.value;
            }

            this.__parent.setReferenceValueToPath(this.__path, res);
        }
    }, {});

    engine.Class("SFMPageModelDetailBinding", engine.SFMPageModelBinding, {
        __path : null, __setter : null, __getter : null, __context : null, __parent : null,

        __constructor : function(parent, path, setter, getter, context){
            this.__base(parent, path, setter, getter, context);
        },

        executeBinding : function() {
            var value = this.__parent.getDetailValueFromPath(this.__path);
            this.__setter.call(this.__context, value);
        },

        getValue : function(){
            var value = this.__getter.call(this.__context);
            return value;
        },

        onNewRecordsAdded : function(records, onSuccess){
            this.__setter.call(this.__context, records, {type : "ADDED", onSuccess: onSuccess});
        },

        onRecordsDeleted : function(records){
            this.__setter.call(this.__context, records, {type : "DELETED"});
        },

        persistBinding : function(){
            var value = this.getValue();
            this.__parent.setDetailValueToPath(this.__path, value);
        }
    }, {});
    ///////////////////////////////////////////// END - DATA MODEL ///////////////////////////////////////////////////

    ///////////////////////////////////////////// START - LOOKUP ///////////////////////////////////////////////////
    engine.Class("SFMPageLookupModel", com.servicemax.client.lib.api.Object, {
        __refMetaModel : null, __callback : null, __lookupData : null,
        __constructor : function(refMetaModel){
            this.__refMetaModel = refMetaModel;
        },
        destroy: function() {
        SVMX.delayedDestroy(this);
        },

        getResultFieldsInfo : function(){
            var resultFieldsInfo = [], lookupData = this.__lookupData, fieldInfo = null;
            var fields = (lookupData) ? lookupData.namesearchinfo.namedSearch[0].namedSearchDetails[0].fields : [];
            for(var i = 0; i < fields.length; i++){

                // don't consider Id in results
                if(fields[i][SVMX.OrgNamespace + "__Search_Object_Field_Type__c"] == 'Result'
                        && fields[i][SVMX.OrgNamespace + "__Field_Name__c"] != "Id"){
                    fieldInfo = {
                        fieldLabel: this.__refMetaModel.getFieldLabelFromRelatedObject(fields[i][SVMX.OrgNamespace + "__Field_Name__c"]),
                        fieldType : this.__refMetaModel.getFieldTypeFromRelatedObject(fields[i][SVMX.OrgNamespace + "__Field_Name__c"]),
                        fieldName: fields[i][SVMX.OrgNamespace + "__Field_Name__c"],
                        fieldSequence: fields[i][SVMX.OrgNamespace + "__Sequence__c"]
                    };
                    resultFieldsInfo[resultFieldsInfo.length] = fieldInfo;
                }
            }
            resultFieldsInfo = SVMX.sort(resultFieldsInfo, "fieldSequence");
            return resultFieldsInfo;
        },

        getReferenceMetaModel : function(){
            return this.__refMetaModel;
        },

        getResultData : function(){
            var lookupData = this.__lookupData;
            var data = lookupData && lookupData.data;
            var j;
            var dl = (data) ? data.length : 0;
            var resultData = [];
            for(j = 0; j < dl; j++){
                var fm = data[j].FieldMap;
                if (!fm) continue;
                var k, fml = fm.length;
                var dataRow = {};
                for(k = 0; k < fml; k++){
                    var fmItem = fm[k];
                    if(fmItem.ftype == "Result" || fmItem.ftype == "Reference"){
                        // !!!ExtJS converts undefined to "" when added to store!!
                        dataRow[fmItem.key] = fmItem.value === undefined ? null : fmItem.value;

                        var fieldType = this.__refMetaModel.getFieldTypeFromRelatedObject(fmItem.key);
                        if(fieldType == "picklist"){
                            var plValues, l;
                            plValues = this.__refMetaModel.getPicklistValuesFromRelatedObject(fmItem.key);
                            l = plValues.length;
                            for(var i = 0; i < l; i++){
                                if(plValues[i].value == fmItem.value){
                                    dataRow[fmItem.key] = plValues[i].label;
                                    // Used later when mapping and translations are involved. Defect: 013436
                                    dataRow[fmItem.key + "__m"] = plValues[i].value;
                                    break;
                                }
                            }
                        }
                    }
                }
                resultData[resultData.length] = dataRow;
            }
            return resultData;
        },

        getDefaultColumnName : function(){
            var lookupData = this.__lookupData,
            searchHdr = lookupData.namesearchinfo.namedSearch[0].namedSearchHdr,
            defaultLookupColumnName = searchHdr[SVMX.OrgNamespace + "__Default_Lookup_Column__c"];

            if(!defaultLookupColumnName){
                defaultLookupColumnName = this.__refMetaModel.nameFieldName;
            }
            return defaultLookupColumnName;
        },

        getNameColumnName : function(){
            return this.__refMetaModel.nameFieldName;
        },

        getLookupObjectName : function(){
             return this.__refMetaModel.objectName;
        },

        getNameColumnNameLabel : function(objectName, nameField ){
            return this.__refMetaModel.getRoot().getLabel(objectName, nameField);
        },

        getLookupId : function(){
            var ret = this.__refMetaModel.namedSearchId;

            if(!ret){
                ret = this.__refMetaModel.objectName;
            }

            return ret;
        },

        // params = {keyword : "", searchOperator : "", bOverrideRelatedLookup : true/false}
        invoke : function(params, callback){
            var request = {}; this.__callback = callback;

            request.KeyWord = params.keyword;
            request.callType = params.callType;
            request.filtersToQuery = params.filtersToQuery;
            request.formFillFields = this.__refMetaModel.getRoot().__fieldMappings.getFieldList(this.__refMetaModel.fieldMappingId);
            request.userTrunk = params.userTrunk;
            request.SearchOperator = params.searchOperator ? params.searchOperator : "contains";
            request.priqChecked = params.priqChecked;
            request.searchOnlineRecord = params.searchOnlineRecord;

            var rid = this.__refMetaModel.namedSearchId;

            if(rid){
                request.LookupRecordId = rid;
                request.ObjectName = this.__refMetaModel.objectName;
            }else{
                request.ObjectName = this.__refMetaModel.objectName;
            }

            if(params.bOverrideRelatedLookup === false){
                var luc = this.__refMetaModel.lookupContext;
                if (luc) {
                    var contextvalue;
                    if (this.record) {
                        var contextValueKey = this.record[luc + "__key"], contextValueVal = this.record[luc];
                        contextvalue = contextValueKey === contextValueVal ? undefined: contextValueKey;
                    }
                    else {
                        contextvalue = this.__refMetaModel.lookupContextFieldInfo.getDataBinding().getValue();
                    }

                    var contextFieldDataType = this.__refMetaModel.lookupContextFieldInfo.datatype;
                    if (contextvalue && typeof(contextvalue) == 'object') {
                        // is a reference context
                        // Defect 017072. For extended edit,check if the extended edit flag is set to true. If it's true and
                        // the context value is not resolved then set the context value to undefined

                        //Defect 031201: Added && condition. since this condition was causing problem for picklist.
                        if(contextvalue.extendedEditExtra == true) {
                            contextvalue = (contextvalue.key === contextvalue.value  && contextFieldDataType === "reference") ? undefined : contextvalue.key;
                        } else {
                            //Defect 024250,
                            //If the lookupQueryField is name, context value has to be value and not ID.
                            if (this.__refMetaModel.lookupQueryField == "Name" ) {
                                  contextvalue = contextvalue.value;
                            }
                            else {
                                  contextvalue = contextvalue.key;
                            }
                        }
                    }
                    request.LookupContext = contextvalue;
                    request.LookupQueryField = this.__refMetaModel.lookupQueryField;
                    //request.LookupQueryContext = this.__refMetaModel.lookupContext;
                }
            }

            // call the service
            var currentApp = this.__refMetaModel.getRoot().getDeliveryEngine().getEventBus();;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.GET_LOOKUPCONFIG", this, {request : request,
                    responder : SVMX.create("com.servicemax.client.sfmdelivery.responders.GetLookupConfigResponder", this)});
            currentApp.triggerEvent(evt);
        },

        onGetLookupConfigComplete : function(data){
            this.__lookupData = data;

            // check if the related object is described or not.
            this.__refMetaModel.getRoot()
            .describeObject(
                this.__refMetaModel.objectName,
                {
                    handler : function(){
                       this.__callback.handler.call(this.__callback.context, data);
                               delete this.__callback;
                    },
                    context : this
                }
            );
        },

        /**
         * handles the lookup config error  by calling the callback handler.
         *
         * @param   {Object}    data    composite data object
         */
        onGetLookupConfigError : function(data) {
            this.__callback.handler.call(this.__callback.context, data);
        }
    }, {});

    ///////////////////////////////////////////// END - LOOKUP ///////////////////////////////////////////////////

    ///////////////////////////////////////////// START - METAMODEL ///////////////////////////////////////////////////
    engine.Class("SFMPageMetaModel", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        title : null, objMetadataMap : null, __dataModel : null, __initializeCallback : null, __initializeCallbackContext : null,
        __logger : null, __userInfo  : null, __deliveryEngine : null, __recordTypesMap : null,
        //__configSorting : null,

        destroy: function() {
            if (this.__dataModel) this.__dataModel.destroy();
            SVMX.delayedDestroy(this);
        },
        __constructor : function(data, userInfo, deliveryEngine){
            this.__logger = SVMX.getLoggingService().getLogger("SFMD-PAGE-META-MODEL");
            // pass parent as null here because this is the root
            this.__base(data, null);

            this.__userInfo = userInfo;
            this.__deliveryEngine = deliveryEngine;
            this.__recordTypesMap = {};



            var processType = this.getProcessType();
            this.isDisplayOnly = processType === "VIEW RECORD" ? true : false;

            // create a new instance of the page data model
            this.__dataModel = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModel", this);

            // FieldMappings
            this.__fieldMappings = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMFieldMappingModel", data);

            //Field Update Rule Validator
            this.__fieldUpdateRuleValidator = SVMX.create("com.servicemax.client.sfmbizrules.impl.FieldUpdateRuleValidator");

            // var sorting = {};
            // var i;
            // var stringMap = data.response.stringMap;
            // for(i = 0; i < stringMap.length; i++) {
            //     //value1 is sorting preferences
            //     //stringMap[i].key is the layout id
            //     if(stringMap[i].value1) {
            //         sorting[stringMap[i].key] = SVMX.toObject(stringMap[i].value1);
            //     }
            // }
            // this.__configSorting = sorting;
            //this.__configSorting = this.__retrieveSortingFields(data);
        },

        __retrieveSortingFields : function(data) {
            var sorting = {};
            var i;
            var stringMap = data.response.stringMap;
            for(i = 0; i < stringMap.length; i++) {
                //value1 is sorting preferences
                //stringMap[i].key is the layout id
                if(stringMap[i].value1) {
                    sorting[stringMap[i].key] = SVMX.toObject(stringMap[i].value1);
                }
            }

            return sorting;
        },
        /**
        * @method getSortingFields
        * get the sorting for a specific details layout
        *
        * @param key
        * details layout id
        */
        getSortingFields : function(key) {
            if(this.__configSorting[key]) {
                return this.__configSorting[key];
            }
            return null;
        },

        getDeliveryEngine : function(){
            return this.__deliveryEngine;
        },

        getDataModel : function(){
            return this.__dataModel;
        },

        getRawPageMetaData : function(){
            return this._data;
        },

        getUserInfo : function(){
            return this.__userInfo;
        },

        getObjectInfo : function(objectName){
            return this.objMetadataMap[objectName];
        },

        getObjectLabel : function(objectName){
            var objMetaData = this.getObjectInfo(objectName);
            return objMetaData.label;
        },

        getObjectNameField : function(objectName) {
            var objMetaData = this.getObjectInfo(objectName);
            var nameField = SVMX.array.get(objMetaData.fields, function(field) {
                return field.nameField;
            });
            return nameField.name;
        },

        getObjectPluralLabel : function(objectName){
            var objMetaData = this.getObjectInfo(objectName);
            return objMetaData.labelPlural;
        },

        // START - UI FIELDS related API
        getFieldInfo : function(objectName, field){
            //In case of hidden fields fieldDetail will be null hence the inner function
            function getFieldName(field){
                var ret = null;
                if(field.fieldDetail){
                    ret = field.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"]
                }else if(field.name){
                    ret = field.name;
                }

                return ret;
            }

            var fieldName = getFieldName(field), ret = null;
            ret = this.getFieldInfoFromName(objectName, fieldName);
            return ret;
        },

        getFieldInfoFromName : function(objectName, fieldName){
            var objMetaData = this.objMetadataMap[objectName], fields = objMetaData.fields, i, l = fields.length, ret = null;
            for(i = 0; i < l; i++){
                var fieldInfo = fields [i];
                if(fieldInfo.name == fieldName){
                    ret = fieldInfo;
                    break;
                }
            }
            return ret;
        },

        getFieldHelpText : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = field.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];
            if(fieldInfo != null){
                ret = fieldInfo.inlineHelpText;
            }
            return ret;
        },

        // Number of digits
        getPrecision : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = 0;
            if(fieldInfo){
                ret = fieldInfo.precision;
            }
            return ret;
        },

        // Number of decimal point precision to use; stupid salesforce terminology
        getScale : function(objectName, field) {
            var fieldInfo = this.getFieldInfo(objectName, field), ret = 0;
            if(fieldInfo){
                ret = fieldInfo.scale;
            }
            return ret;
        },

        getFieldLabel : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = field.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];
            if(fieldInfo != null){
                ret = fieldInfo.label;
            }

            return ret;
        },

        isFieldAccessible : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = false;
            if(fieldInfo){
                ret = fieldInfo.accessible;
            }
            return ret;
        },

        isFieldRequired : function(objectName, field){
            var ret = true, fieldInfo = this.getFieldInfo(objectName, field);
            if(fieldInfo != null){
                var isNillable = fieldInfo.nillable;
                ret = !isNillable;
            }
            return ret;
        },

        isFieldReadOnly : function(objectName, field){
            var ret = true, fieldInfo = this.getFieldInfo(objectName, field);
            if(fieldInfo != null){
                var isUpdateable = fieldInfo.updateable;
				ret = !isUpdateable;
            }
            return ret;
        },

        getControllingPicklist : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = null;

            if(fieldInfo && fieldInfo.dependentPicklist){
                ret = fieldInfo.controllerName;
            }
            return ret;
        },

        getAllPicklists : function(objectName){
            //Get all the fields of dataType "picklist" and "boolean" within the object.
            var allFields = this.objMetadataMap[objectName].fields;
            var i, l = allFields.length, picklistFields = [];

            for(i = 0; i < l; i++){
                if(allFields[i].dataType == 'picklist' || allFields[i].dataType == 'boolean'){
                    picklistFields.push(allFields[i]);
                }
            }

            return picklistFields;
        },

        getPicklistValues : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = [];
            if(fieldInfo != null){
                ret = fieldInfo.picklistValues;
            }
            return ret;
        },
        // END - UI FIELDS related API

        getPicklistValuesFromFieldName : function(objectName, fieldName){
            var fieldInfo = this.getFieldInfoFromName(objectName, fieldName), ret = [];
            if(fieldInfo){
                ret = fieldInfo.picklistValues;
            }
            return ret;
        },

        getLabel : function(objectName, fieldName){
            var objMetaData = this.getObjectInfo(objectName), fields = objMetaData.fields, i, l = fields.length, ret = fieldName;
            for(i = 0; i < l; i++){
                var fieldInfo = fields [i];
                if(fieldInfo.name == fieldName){
                    ret = fieldInfo.label;
                    break;
                }
            }
            return ret;
        },

        /**
         * !! This call works only with the SVMX Describe API because the name for the dataType attribute
         * in metadata API is 'type'. But this is a key word in APEX and hence cannot be used. 'dataType' is
         * used instead. Whenever we need to support metadata API, consider 'type' as well.
         */
        getFieldType : function(objectName, fieldName){
            var objMetaData = this.getObjectInfo(objectName), fields = objMetaData.fields, i, l = fields.length, ret = null;
            for(i = 0; i < l; i++){
                var fieldInfo = fields [i];
                if(fieldInfo.name == fieldName){
                    ret = fieldInfo.dataType;
                    break;
                }
            }
            return ret;
        },

        getFieldTypes : function() {
            var results = {};
            var i, objectName, currentObject, fields, field;
            var objMetadata = this.objMetadataMap;
            for (objectName in objMetadata) {
                results[objectName] = {};
                fields = objMetadata[objectName].fields;
                for (i = 0; i < fields.length; i++) {
                    field = fields[i];
                    results[objectName][field.name] = field.dataType || field.type;
                }
            }
            return results;
        },

        describeObject : function(objectName, callback){
            var objInfo = this.getObjectInfo(objectName);

            if(!objInfo){
                var currentApp = this.getDeliveryEngine().getEventBus();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.DESCRIBE_OBJECT", this, {request : {objectName : objectName},
                            responder : SVMX.create("com.servicemax.client.sfmdelivery.responders.DescribeObjectResponder",
                                                        objectName, this, {callback:callback})});
                currentApp.triggerEvent(evt);
            }else{
                callback.handler.call(callback.context);
            }
        },

        onDescribeObjectComplete : function(objectName, objectInfo, params){
            this.objMetadataMap[objectName] = objectInfo;
            params.callback.handler.call(params.callback.context);
        },

        initialize : function(cbHandler, context){
            this.__logger.info("initializing the meta model...");

            this.__initializeCallbackContext = context;
            this.__initializeCallback = cbHandler;

            // Describe the target object and child objects

            // header
            var objects = [this._data.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"]];

            // details
            var details = this._data.page.details, i, l = details.length;
            for(i = 0; i < l; i++){
                var detail = details[i];
                objects[i+1] = detail.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
            }

            // end describe list

            this.objMetadataMap = {};
            l = objects.length;
            var describeList = [];
            var duplicateDescribes = []; // Prevent calling objectDescribe any more than required. Object describe costs a lot of time and cpu.
            for(i = 0; i < l; i++){
                if (duplicateDescribes.indexOf(objects[i]) == -1) {
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMDELIVERY.DESCRIBE_OBJECT", this, {request : {objectName : objects[i]}});
                    describeList.push(evt);
                    duplicateDescribes.push(objects[i]);
                }
            }

            var currentApp = this.getDeliveryEngine().getEventBus();
            var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", currentApp, describeList);

            this.__logger.info("triggering request to describe objects");
            ec.triggerAll(this.onDescribeObjectsComplete, this);
        },

        onDescribeObjectsComplete : function(evtCol){
            var items = evtCol.items(), size = items.length, i;
            for(i = 0; i < size; i++){
                var item = items[i], objectName = item.getEventObj().data.request.objectName;
                var objMetadata = item.response;

                /*
                Fix for #016921.
                When the process type creates a new object from another object or as a standalone create,
                and the user doesn't have edit permission on the target object, but has create access,
                then give edit access for the creation process so that the user can modify object details
                while creating the new target object.
                */
                var processType = evtCol.__context._data.response.sfmProcessType;
                if((processType == "SOURCE TO TARGET ALL" || processType == "SOURCE TO TARGET CHILD" || processType == "STANDALONE CREATE") 
                    && objMetadata.createable == true && objMetadata.updateable == false) {
                    objMetadata.updateable = true;
                    for(var idx = 0; idx < objMetadata.fields.length; idx++) {
                        var eachField = objMetadata.fields[idx];
                        if(eachField.createable && !eachField.updateable) {
                            eachField.updateable = true;
                        }
                    }
                }
                this.objMetadataMap[objectName] = objMetadata;
            }
            // process the record type information
            this.__processRecordTypes(function(){
                // title will be embedded in the page
                this.title = SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" :
                  window["svmx_sfm_delivery_process_title"];
                if(!this.title) this.title = "";

                this._children["header"] =
                    SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageHeader", this._data.page.header, this);
                this._children["header"].initialize();

                this.initializeDetails();

            }, this);
        },

        __processRecordTypes : function(callback, context){

            var i, l, recordTypeIdFields = [], details = this._data.page.details, detail = null;

            recordTypeIdFields.push({objectName : this._data.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"]});
            l = details.length;
            for(i = 0; i < l; i++){
                detail = details[i];
                recordTypeIdFields.push({objectName : detail.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"]});
            }

            if(recordTypeIdFields.length > 0){
                var requestList = [], l = recordTypeIdFields.length;
                for(i = 0; i < l; i++){
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                            "SFMDELIVERY.GET_RECORD_TYPES", this, {request : {objectName : recordTypeIdFields[i].objectName}});
                    requestList[i] = evt;
                }

                var currentApp = this.getDeliveryEngine().getEventBus();
                var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", currentApp, requestList);

                this.__logger.info("triggering request to get record types");
                ec.triggerAll(function(evtCol){
                    var items = evtCol.items(), size = items.length, i;
                    for(i = 0; i < size; i++){
                        var item = items[i], objectName = item.getEventObj().data.request.objectName;
                        var recordTypes = item.response;
                        this.__recordTypesMap[objectName] = recordTypes;
                    }
                    callback.call(context);
                }, this);
            }else{
                callback.call(context);
            }
        },

        getRecordTypesFor : function(objectName){
            return this.__recordTypesMap[objectName];
        },

        getCurrentRecordTypeInfo : function(recordType, objectName){
            var ret = null, allRecordTypes = null, i, l;
            if(recordType){
                allRecordTypes = this.getRecordTypesFor(objectName);
                if(allRecordTypes){
                    l = allRecordTypes.length;
                    for(i = 0; i < l; i++){
                        if(allRecordTypes[i].recordTypeId == recordType){
                            ret = allRecordTypes[i];
                            break;
                        }
                    }
                }
            }
            return ret;
        },

        getProcessType : function(){
            return this._data.response.sfmProcessType;
        },

        getAssociatedViewProcesses : function(){
            return this._data.response.associatedViewProcesses;
        },

        setAssociatedViewProcesses : function(associatedViewProcesses) {
            var k, len, avpCollection = [];

            if(associatedViewProcesses){
                len = associatedViewProcesses.length;
            }else{
                len = 0;
            }

            for(k = 0; k < len; k++){
                var avp = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageAssociatedViewProcesses", associatedViewProcesses[k]);
                avpCollection.push(avp);
            }

            this.associatedViewProcesses = avpCollection;
        },

        resolveDependencies : function(){
            for(var i in this._children){
                this._children[i].resolveDependencies();
            }
        },

        initializeDetails : function(){
            this._children["details"] =
                SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetails", this._data.page.details, this);
            this._children["details"].initialize(this.onDetailsInitalizeComplete, this);
        },

        onDetailsInitalizeComplete : function(){

            // resolved metamodel dependencies (lookup, dependent picklist...)
            this.resolveDependencies();

            this.__initializeCallback.call(this.__initializeCallbackContext);
        },

        getHeaderMetaModel : function(){
            return this._children["header"];
        },

        getDetailMetaModel : function(){
            return this._children["details"];
        },

        getBusinessRules : function() {
            var rules = this._data.page.businessRules || [], res = [];
            rules.forEach(function(rule){
                if((rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] !== "Field Update Rule") && (rule.ruleInfo.bizRuleDetails.length > 0 && rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + "__Expression_Type__c"] === "Business_Rule")){
                    res.push(rule);
                }
            });
            return res;
        },          

        getBusinessRulesHash : function() {
            var rules = this.getBusinessRules();
            var result = this.__commonMethodForBusinessRule(rules);
            return result;
        },

        __commonMethodForBusinessRule : function(rules) {

            var i;
            var detailsArray = this.getData().page.details;
            var result = {header: {key: "", rules: []}};
            for (i = 0; i < detailsArray.length; i++) {
                var d = detailsArray[i];
                var id = d.DetailLayout[SVMX.OrgNamespace + "__Page_Layout_ID__c"];
                var name = d.DetailLayout[SVMX.OrgNamespace + "__Name__c"];
                var key = d.dtlLayoutId;
                result[id] = {key: key,
                                id: id,
                                name: name,
                                rules: []};
            }

            for (i = 0; i < rules.length; i++) {
                var r = rules[i];
                var recordName = r.aliasName;
                if (result[recordName]) {
                    result[recordName].rules.push(r);
                } else {
                    result.header.rules.push(r);
                }
            }

            return result;
        },

        getFieldUpdateRules : function() {
            var rules = this._data.page.businessRules || [], res = [];
            rules.forEach(function(rule){
                if((rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] === "Field Update Rule") || (rule.ruleInfo.bizRuleDetails.length > 0 && rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + "__Expression_Type__c"] === "Field_Update_Rule")){
                    res.push(rule);
                }
            });
            return res;
        },

        getFieldUpdateRulesHash : function() {
            var i;
            var rules = this.getFieldUpdateRules();
            var detailsArray = this.getData().page.details;
            var header = this.getData().page.header;
            var headerKey = header.headerLayout[SVMX.OrgNamespace + "__Page_Layout_ID__c"];

            var result = {header: {id: headerKey, key: header.hdrLayoutId, rules: []}};
            for (i = 0; i < detailsArray.length; i++) {
                var d = detailsArray[i];
                var id = d.DetailLayout[SVMX.OrgNamespace + "__Page_Layout_ID__c"];
                var name = d.DetailLayout[SVMX.OrgNamespace + "__Name__c"];
                var key = d.dtlLayoutId;
                result[id] = {key: key,
                                id: id,
                                name: name,
                                rules: []};
            }

            for (i = 0; i < rules.length; i++) {
                var r = rules[i];
                var recordName = r.aliasName;
                if (result[recordName]) {
                    result[recordName].rules.push(r);
                } else {
                    result.header.rules.push(r);
                }
            }
            return result;
        },

        evaluateFieldUpdateRules: function(){
            //Temporary fix block Formula fields in Android. Doing this way to avoid changes in VF to enable it Online
            if(!this.getDeliveryEngine().isFieldUpdatesEnabled()){
                return;
            }

            var fields = this.getFieldTypes();
            var pageModel = this.getDataModel().getData();

            var rules = this.getFieldUpdateRulesHash();
            var values = pageModel.getRawValues();

            var fieldUpdateRulesResult =
                this.__fieldUpdateRuleValidator.evaluateFieldUpdateRules({
                    rules: rules, data: values, fields: fields, pageModel: pageModel
                });

            var hasValidationError = fieldUpdateRulesResult.errors.length
                || (fieldUpdateRulesResult.warnings.length);

            if(!hasValidationError){
                var updatableFields = this.__fieldUpdateRuleValidator.getUpdatableFields(rules);
                this.applyFieldUpdateResults(values, fieldUpdateRulesResult.response, updatableFields, fields);
            }else{
                var currentApp = this.getDeliveryEngine().getEventBus();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.FIELD_UPDATE_VALIDATION_ERROR", this, {
                    request : {
                        original : {
                            request: {},
                            responder: {}
                        },
                        deliveryEngine : this.getDeliveryEngine(),
                        result : fieldUpdateRulesResult,
                        eventType: "onload"
                    },
                    responder : {}
                });
                return currentApp.triggerEvent(evt);
            }
        },

        applyFieldUpdateResults: function(inData, result, updatableFields, fields){
            var newValue, oldValue, value, key,
                data =  this.__fieldUpdateRuleValidator.getRawData(inData, this.getDataModel().getData(), false);

            result = this.__fieldUpdateRuleValidator.parseResult(result, updatableFields, fields)
            for(key in result){
                if(key !== 'details' && key in updatableFields){
                    newValue = result[key]; oldValue = data[key];

                    if(newValue !== oldValue){
                        value = inData[key];
                        if(value && typeof value === "object" && "fieldvalue" in value){
                            value.fieldvalue.key = newValue;
                            value.fieldvalue.value = newValue;
                        }else{
                            value = newValue;
                        }
                        inData[key] = value;
                    }
                }
            }

            if(!result.details || !inData.details) return;

            for(key in result.details){
                if(key in inData.details){
                    this.__applyChildFieldUpdateResults(inData.details[key].lines || [], result.details[key].lines || [], updatableFields.details[key] || {}, fields);
                }
            }
        },

        __applyChildFieldUpdateResults: function(inDataList, resultList, updatableFields, fields){
            var i, l = inDataList.length,
                data = {}, result = {};

            for(i = 0; i < l; i++){
                data[inDataList[i].Id] = inDataList[i];
            }

            l = resultList.length;
            for(i = 0; i < l; i++){
                result[resultList[i].Id] = resultList[i];
            }

            for(var key in result){
                if(key in data){
                    // Remove temporary provided record ids for newly created records.
                    if(data[key].Id && data[key].Id.indexOf( "tempChildId_" ) >= 0){
                        data[key].Id = result[key].Id = undefined;
                    }
                    this.applyFieldUpdateResults( data[key], result[key], updatableFields, fields );
                }
            }
        },

        getBindingHash : function() {
            return this.__dataModel.__allBindingsHash;
        },

        executeFieldMappings : function(metaModel, selectedData, optionalBindingsHash, optionalDataStore, optionalFieldTypes) {
            var bindingsHash = optionalBindingsHash || this.getBindingHash();
            var fieldTypes, objectName, p, fieldMapping;

            p = metaModel;
            if (optionalFieldTypes) {
                fieldTypes = optionalFieldTypes;
            } else {
                while(!p.getFieldTypes) p = p._parent;
                fieldTypes = p.getFieldTypes();
            }

            var model = this.getRoot().getDataModel();

            // Execute the field mappings
            fieldMapping = metaModel.getRoot().__fieldMappings;
            fieldMapping.forEachField(metaModel.fieldMappingId, function(inKey, inValue) {
                var fieldType = fieldTypes[inKey];
                var selectedValue;
                if (inValue.value) {
                    selectedValue = inValue.value;
                    switch(selectedValue) {
                        case "Tomorrow":
                        case "Yesterday":
                        case "Today":
                            selectedValue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime(selectedValue, "YYYY-MM-DD", "HH:mm:ss");
                            if (fieldType == "datetime") {
                                // Do an extra conversion, so the USER sees this as midnight for the macro on the day, rather than using midnight UTC for that day.
                                selectedValue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(selectedValue, null, true);
                            }
                            break;
                        case "Now":
                            selectedValue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime(selectedValue, "YYYY-MM-DD", "HH:mm:ss");
                            break;
                    }
                } else if (fieldType === "reference" && inValue.field + "__key" in selectedData) {
                    selectedValue = selectedData[inValue.field + "__key"];

                    if (!selectedValue && inValue.field2) {
                        selectedValue = selectedData[inValue.field2 + "__key"];
                    }
                    if (!selectedValue && inValue.field3) {
                        selectedValue = selectedData[inValue.field3 + "__key"];
                    }
                    if (selectedValue && typeof selectedValue == "object") {
                        selectedValue = {key: selectedValue.key, value: selectedValue.value};
                    }

                } else {
                    // Defect 013436: Use the value that is also appropriate for mapping picklists with translations first.
                    selectedValue = selectedData[inValue.field + "__m"];
                    if (!selectedValue) {
                        selectedValue = selectedData[inValue.field];
                    }
                    if (!selectedValue && inValue.field2) {
                        selectedValue = selectedData[inValue.field2];
                    }
                    if (!selectedValue && inValue.field3) {
                        selectedValue = selectedData[inValue.field3];
                    }
                }
                var binding = bindingsHash[inKey];
                if (binding) {
                    binding.setValue(selectedValue);
                } else if (optionalDataStore) {
                    optionalDataStore[inKey] = selectedValue;
                } else {
                    model.setValueToPath(inKey, selectedValue);
                }
            });
        },

        getRelatedBindingValue : function(fieldName, source){
            var l = this._data.page.header.sections.length, i;
            for(i = 0; i < l ; i++){
                var fldLen = this._data.page.header.sections[i].fields.length;
                for(var k = 0; k < fldLen; k++){
                    this._data.page.header.sections[i].fields[k]
                }
            }
            this._data.getRelatedBindingValue(fieldName, source);
        }
    }, {});

    engine.Class("SFMChecklistPageMetaModel", com.servicemax.client.sfmdelivery.engine.SFMPageMetaModel, {
        __constructor : function(data, userInfo, deliveryEngine){
            this.__base(data, userInfo, deliveryEngine);

            deliveryEngine = deliveryEngine || {};
            deliveryEngine.additionalInfo = deliveryEngine.additionalInfo || {};

            // Special handling to force this to be a view only
            if (deliveryEngine.additionalInfo.specialProcessType === "VIEW") {
                this.isDisplayOnly = true;
            }

            // create a new instance of the page data model.
            // Original must be replaced so we can handle parsing of specila checklist data
            this.__dataModel = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMChecklistPageModel", this);
        },

        initialize : function(cbHandler, context){
            this.__logger.info("initializing the meta model...");

            this.__initializeCallbackContext = context;
            this.__initializeCallback = cbHandler;
            this.objMetadataMap = {};

            // Describe the target object and child objects

            // header
            var objectName = this._data.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"];
            this.__buildDescribeObject(objectName);

            // Just in case the process tile is sent here
            this.title = SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" : window["svmx_sfm_delivery_process_title"];

            // Try to get title if not set or hide title-bar is false or undefined
            if (!this.title && !SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar")) {
                if (this._data && this._data.page && this._data.page.processTitle) {
                    this.title = this._data.page.processTitle;
                }
            }
            // Ensure title is not null
            this.title = (this.title) ? this.title : "";

            var currentApp = this.getDeliveryEngine().getEventBus();

            if (this._sourceRecord && this._sourceRecord.length > 0 && this.objMetadataMap[objectName]["fields"] && this.objMetadataMap[objectName]["fields"].length > 0 && this.objMetadataMap[objectName]["fields"][0]["dataType"] === "question" && this.checklistStatus === 'Not Started') {

                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.EVALUATE_ENTRY_CRITERIA", this, {
                        request: {
                            data: this._sourceRecord,
                            sourceRecordId: this.__deliveryEngine.getSourceRecordId(),
                            metadata: this.__deliveryEngine.getPageMetaData().getRawPageMetaData(),
                            deliveryEngine: this.__deliveryEngine,
                            additionalInfo: {
                                toModelOnly: false,
                                eventType: "Checklist_Section_Entry_Criteria",
                            }
                        },
                        responder: SVMX.create("com.servicemax.client.sfmdelivery.responders.ChecklistEntryResponder", this)
                    });

                currentApp.triggerEvent(evt);
            } else {
                this.continueIntializing();
            }
        },

        continueIntializing : function () {

            this._children["header"] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageHeader", this._data.page.header, this);
            this._children["header"].initialize();
            this.__initializeCallback.call(this.__initializeCallbackContext);
        },

        onEntryCriteriaExecutionComplete : function(){
            var me = this;
            var metaData = this.__deliveryEngine.getPageMetaData().getRawPageMetaData();
            if (this.__isAnySectionSatisfyEntryCriteria(metaData.page.header.sections)) {
                    this.continueIntializing();
            } else {
                var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");
                SVMX.getCurrentApplication().showMessage({
                    type: "CUSTOM",
                    title: " ",
                    text: TS.T("TAG116"),
                    buttons: [{
                        text: TS.T("TAG0066"),
                        itemId: "OK"
                    }],
                    handler: function(buttonId) {
                        me.closeAndGoBack();
                    }
                });
            }
        },

        __isAnySectionSatisfyEntryCriteria: function(sections) {
            var isSectionSatisfy = false;
            if(sections){
                var length = sections.length;
                for (var index = 0; index < length; index++) {
                    var section = sections[index];
                    var sectionDetail = section.sectionDetail;
                    if(sectionDetail){
                        var entryCriteria = sectionDetail[SVMX.OrgNamespace + "__Entry_Criteria__c"] || false ;
                        if(!entryCriteria){
                            isSectionSatisfy = true;
                            break;
                        }
                    }
                }
            }
            return isSectionSatisfy;
        },

        closeAndGoBack: function() {
            var navigationStack = this.getDeliveryEngine().getNavigationStack();
            if (navigationStack.length == 0) {
                this.__logger.info("Closing Checklist and going back");
                this.getDeliveryEngine().doClose();
            } else {
                this.getDeliveryEngine().handleInplaceBackwardNavigation();
            }
        },

        __getEntryCriteriaBusinessRule: function(ruleType) {

            ruleType = "Checklist_Section_Entry_Criteria";

            var rules = this._data.page.businessRules || [],
                res = [];
            var sections = this._data.page.header.sections || [],
                ruleIDs = [],
                ruleSectionIDs = {};

            sections.forEach(function(section) {

                if (section.sectionDetail && section.sectionDetail[SVMX.OrgNamespace + "__ServiceMax_Processes__r"]) {

                    var recordList = section.sectionDetail[SVMX.OrgNamespace + "__ServiceMax_Processes__r"].records;

                    recordList.forEach(function(record) {

                        if (record[SVMX.OrgNamespace + "__Rule_Type__c"] === ruleType && record[SVMX.OrgNamespace + "__Active__c"] === true) {
                            var ruleID = record[SVMX.OrgNamespace + "__Process3__c"];
                            ruleIDs.push(ruleID);
                            if(ruleSectionIDs[ruleID] === undefined){
                                ruleSectionIDs[ruleID] = [record[SVMX.OrgNamespace + "__SM_Section__c"]];
                            }else{
                                //same rule applied to multiple sections.
                                var sectionIDs =  ruleSectionIDs[ruleID];
                                sectionIDs.push(record[SVMX.OrgNamespace + "__SM_Section__c"]);
                            }
                        }

                    });
                }
            });

            rules.forEach(function(rule) {
                if ((rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] === ruleType) && (rule.ruleInfo.bizRuleDetails.length > 0) && (ruleIDs.indexOf(rule.ruleInfo.bizRule.Id) > -1)) {
                    var sectionIDs = ruleSectionIDs[rule.ruleInfo.bizRule.Id];
                    var section = sectionIDs.splice(0,1);
                    rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__SM_Section__c"] = section[0];
                    res.push(rule);
                }
            });
            return res;
        },    

        __getExitCriteriaBusinessRule: function(request) {

            var ruleType = request.additionalInfo.eventType;
            var recordList = request.sectionExitRules;
            var skippedQuestionList = request.additionalInfo.skippedQuestions || [];
            var rules = this._data.page.businessRules || [],
                res = [];
            var ruleIDs = [],
                ruleSectionIDs = {};

            recordList.forEach(function(record) {

                if (record[SVMX.OrgNamespace + "__Rule_Type__c"] === ruleType && record[SVMX.OrgNamespace + "__Active__c"] === true) {
                    var ruleID = record[SVMX.OrgNamespace + "__Process3__c"];
                    ruleIDs.push(ruleID);
                    var sectionIDs = {};
                        sectionIDs[SVMX.OrgNamespace + "__SM_Section__c"] = record[SVMX.OrgNamespace + "__SM_Section__c"];
                        sectionIDs[SVMX.OrgNamespace + "__SM_Target_Section__c"] = record[SVMX.OrgNamespace + "__SM_Target_Section__c"];
                        sectionIDs[SVMX.OrgNamespace + "__Sequence__c"] = record[SVMX.OrgNamespace + "__Sequence__c"];
                    
                    ruleSectionIDs[ruleID] = sectionIDs;
                }

            });

            rules.forEach(function(rule) {
                if ((rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] === ruleType) && (rule.ruleInfo.bizRuleDetails.length > 0) && (ruleIDs.indexOf(rule.ruleInfo.bizRule.Id) > -1) && (skippedQuestionList.indexOf(rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace +"__Field_Name__c"]) === -1)) {
                    var sectionDetails = ruleSectionIDs[rule.ruleInfo.bizRule.Id];
                    rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__SM_Section__c"] = sectionDetails[SVMX.OrgNamespace + "__SM_Section__c"];
                    rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__SM_Target_Section__c"] = sectionDetails[SVMX.OrgNamespace + "__SM_Target_Section__c"];
                    rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Sequence__c"] = sectionDetails[SVMX.OrgNamespace + "__Sequence__c"];
                    rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Message_Type__c"] = "Error";
                    rule.message = rule.ruleInfo.bizRule.Id; // Using this because removeDuplicate in BusinessRule class is filtering data based on the message type. Hence using Rule ID which will be unique for a section.
                    res.push(rule);
                }
            });
            return res;
        },        

        removeChecklistSkippedQuestionRules : function (rules) {
            for (var ruleCounter = rules.length - 1; ruleCounter>=0; ruleCounter--) {
                var rule = rules[ruleCounter];
                var questionID = rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + "__Field_Name__c"];
                if(this.__deliveryEngine.skippedQuestions.indexOf(questionID) > -1){ // if no value in the SFMdata that means it has not been answered.
                    rules.splice(ruleCounter, 1);
                }
            }                        
        },

        getEntryExitCriteriaBusinessRuleHash : function (request) {

            //ruleType can be entry or exit criteria string.
            var rules = null;
            if (request.additionalInfo.eventType === "Checklist_Section_Entry_Criteria") {
                rules = this.__getEntryCriteriaBusinessRule(request.additionalInfo.eventType);
            } else {
                rules = this.__getExitCriteriaBusinessRule(request);
            }
            var result = this.__commonMethodForBusinessRule(rules);
            return result;
        },

        getBusinessRules : function() {
            var rules = this._data.page.businessRules || [], res = [];
            rules.forEach(function(rule){
                if(((rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] !== "Field Update Rule") && (rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] !== "Checklist_Section_Entry_Criteria") && (rule.ruleInfo.bizRule[SVMX.OrgNamespace + "__Rule_Type__c"] !== "Checklist_Section_Exit_Criteria")) && (rule.ruleInfo.bizRuleDetails.length > 0 && rule.ruleInfo.bizRuleDetails[0][SVMX.OrgNamespace + "__Expression_Type__c"] === "Business_Rule")){
                    res.push(rule);
                }
            });
            return res;
        },

        getBusinessRulesHash : function() {
            var rules = this.getBusinessRules();
            this.removeChecklistSkippedQuestionRules(rules); // required to avoid DVR for Skipped sections in Checklist
            var result = this.__commonMethodForBusinessRule(rules);
            return result;
        },

        __commonMethodForBusinessRule : function(rules) {

            var i;
            var detailsArray = this.getData().page.details;
            var result = {header: {key: "", rules: []}};
            for (i = 0; i < detailsArray.length; i++) {
                var d = detailsArray[i];
                var id = d.DetailLayout[SVMX.OrgNamespace + "__Page_Layout_ID__c"];
                var name = d.DetailLayout[SVMX.OrgNamespace + "__Name__c"];
                var key = d.dtlLayoutId;
                result[id] = {key: key,
                                id: id,
                                name: name,
                                rules: []};
            }

            for (i = 0; i < rules.length; i++) {
                var r = rules[i];
                var recordName = r.aliasName;
                if (result[recordName]) {
                    result[recordName].rules.push(r);
                } else {
                    result.header.rules.push(r);
                }
            }

            return result;
        },

        getFieldInfo : function(objectName, field) {
            var ret = {};
            if (field && field.fieldDetail && field.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]) {
                ret = SVMX.toObject(field.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]);
            } else {
                // This is not a question so we assume this is for a CheckList List.
                ret = field;
            }

            return ret;
        },

        getFieldTypes : function() {
            var results = {};
            var i, objectName, currentObject, fields, field;
            var objMetadata = this.objMetadataMap;
            for (objectName in objMetadata) {
                results[objectName] = {};
                fields = objMetadata[objectName].fields;
                for (i = 0; i < fields.length; i++) {
                    field = fields[i];
                    //results[objectName][field.question.questionID] = field.question.responseType.toLowerCase();
                    results[objectName][field.question.questionID] = field.dataType;;
                }
            }

            return results;
        },

        getQuestionTypes : function() {
            var results = {};
            var i, objectName, currentObject, fields, field;
            var objMetadata = this.objMetadataMap;
            for (objectName in objMetadata) {
                fields = objMetadata[objectName].fields;
                for (i = 0; i < fields.length; i++) {
                    field = fields[i];
                    results[field.question.questionID] = field.question.responseType.toLowerCase();
                }
            }

            return results;
        },

        getQuestionNames : function() {
            var results = [];
            var i, objectName, currentObject, fields, field;
            var objMetadata = this.objMetadataMap;
            for (objectName in objMetadata) {
                fields = objMetadata[objectName].fields;
                for (i = 0; i < fields.length; i++) {
                    field = fields[i];
                    results.push(field.question.questionID)
                }
            }
            return results;
        },

        getQuestionData : function(data) {
            var qData = {};
            var names = this.getQuestionNames();
            var questionTypes = this.getQuestionTypes();
            var ret;
            for (var i = 0; i < names.length; i++) {
                value = data[ names[i] ];
                var qType = questionTypes[ names[i] ];
                // Do special handling of certain types.
                if (value && value.fieldvalue && (qType == "multi-select picklist" || qType == "picklist"|| qType == "checkbox")) {
                    value = value.fieldvalue.key;
                }

                //special handling for zero as its a falsy value in JS. Defect SS-1422
                if (qType == "number" && value === 0) {
                    value = "0";
                }
                
                qData[ names[i] ] = value || "";
                
            }

            return qData;
        },

        removeQuestionData : function(data) {
            var names = this.getQuestionNames();
            for (var i = 0; i < names.length; i++) {
                delete data[ names[i] ];
            }
        },

        getObjectLabel : function(objectName){
            var objMetaData = this.getObjectInfo(objectName);
            return objMetaData && objMetaData.label || "Unknown";
        },

        getPicklistValues : function(objectName, field){
            var fieldInfo = this.getFieldInfo(objectName, field), ret = [];
            if(fieldInfo != null){
                ret = fieldInfo.questionResponses;
                // Sort the results by sequence
                if (ret instanceof Array) {
                    ret.sort(function(a, b){
                        var aSeq = a.sequence || 0;
                        var bSeq = b.sequence || 0;
                        return aSeq - bSeq;
                    });
                }
            }
            return ret;
        },

        __buildDescribeObject: function(objectName) {
            //TODO: Are there reasons to fill in things other than fields?
            var objMetadata = {
                "activateable": false,
                  "childRelationships": [],
                  "fields": [],
                  "name": "Checklist__c",
                  "label": "Checklist",
                  "recordTypeInfos": [],
                  "recordTypeMapping": []
            };

            var i, l, i2, l2, section, field;
            var questionFieldName = SVMX.OrgNamespace + '__QuestionInfoJSON__c';
            if (this._data && this._data.page && this._data.page.header && this._data.page.header.sections
                    && this._data.page.header.sections.length > 0) {
                l = this._data.page.header.sections.length;
                for (i = 0; i < l; i++) {
                    section = this._data.page.header.sections[i];
                    var sectionDetail = section.sectionDetail;
                    if(!sectionDetail.hasOwnProperty(SVMX.OrgNamespace+'__Entry_Criteria__c')){
                        section.sectionDetail[SVMX.OrgNamespace+'__Entry_Criteria__c']= false;
                    }
                    if (section.fields && section.fields.length > 0) {
                        l2 = section.fields.length;
                        for (i2 = 0; i2 < l2; i2++) {
                            field = section.fields[i2];
                            if (field.fieldDetail && field.fieldDetail[questionFieldName]) {
                                var virtualField = SVMX.toObject(field.fieldDetail[questionFieldName]);
                                virtualField.dataType = "question";
                                objMetadata.fields.push(virtualField);
                            }
                        }
                    } else {
                        console.warn("Checklist Page Layout Section '"+i+"' Missing Questions");
                    }
                }
            } else {
                console.warn("Checklist Page Layout Missing Sections");
            }

            this.objMetadataMap[objectName] = objMetadata;
        }
    }, {});



    engine.Class("SFMFieldMappingModel", com.servicemax.client.lib.api.Object, {
        __mapping: null,
        __constructor : function(data){
            var mapping = this.__mapping = {};
            if (data.page.lstObjectMapInfo) {
                SVMX.array.forEach(data.page.lstObjectMapInfo, function(mapItem) {
                    var mappingSection = mapping[mapItem.mapId] = {};

                    SVMX.array.forEach(mapItem.objectMap.fields, function(inField) {
                        var source = inField.fieldMapRecord[SVMX.OrgNamespace + "__Source_Field_Name__c"];
                        if (source) {
                            mappingSection[inField.fieldMapRecord[SVMX.OrgNamespace + "__Target_Field_Name__c"]] = {
                                field: inField.fieldMapRecord[SVMX.OrgNamespace + "__Source_Field_Name__c"],
                                field2: inField.fieldMapRecord[SVMX.OrgNamespace + "__Preference_2__c"],
                                field3: inField.fieldMapRecord[SVMX.OrgNamespace + "__Preference_3__c"]
                            };
                        } else {
                            mappingSection[inField.fieldMapRecord[SVMX.OrgNamespace + "__Target_Field_Name__c"]] = {
                                value: inField.fieldMapRecord[SVMX.OrgNamespace + "__Display_Value__c"]
                            };
                        }
                    });
                });
            }
        },
        getFieldList : function(inMappingId) {
            var result = [];
            var section = this.__mapping[inMappingId];
            if (section) {
                SVMX.forEachProperty(section, function(key,value) {
                    if (value.field) result.push(value.field);
                    if (value.field2) result.push(value.field2);
                    if (value.field3) result.push(value.field3);
                });
            }
            return result;
        },
        forEachField : function(inMappingId,inCallback) {
            if (!inMappingId) return;
            var section = this.__mapping[inMappingId];
            if (section) {
                SVMX.forEachProperty(section, inCallback);
            }
        }

    }, {});

    engine.Class("SFMPageAssociatedViewProcesses",  com.servicemax.client.lib.api.Object, {
        title : null, processId : null,
        __constructor : function(data){
            this.initialize(data);
        },

        initialize : function(data){
            this.title = data.process_name;
            this.processId = data.process_unique_id;
        }
    });

    // Represents the layout and behaviors of the page header
    engine.Class("SFMPageHeader", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        objectName : null, actions : null, helpURL : "", hideQuickSave : false, hideSave : false, hideSaveAndNew : false,
        hideChatter : false, pageEvents : null, pageHelp : null, __recordTypeField : null, __currentRecordType : null,
        __controllingPicklistFields : null,

        __constructor : function(data, parent){
            this.__base(data, parent);
            this.pageEvents = [];
                this.__controllingPicklistFields = [];
        },
        destroy: function() {
            var sections = this.getChildNode("sections");
            if (sections) SVMX.array.forEach(sections, function(item) {item.destroy();});

            var actions = this.getChildNode("actions");
            if (actions) SVMX.array.forEach(actions, function(item) {item.destroy();});


            SVMX.destroy(this);
        },

        initialize : function(){
            var processType = this._parent.getProcessType();
            var specialView = false;
            // Special handling to force this to be a view only
            if (this.getRoot()
                    && this.getRoot().getDeliveryEngine()
                    && this.getRoot().getDeliveryEngine().additionalInfo
                    && this.getRoot().getDeliveryEngine().additionalInfo.specialProcessType === "VIEW") {
                specialView = true;
            }
            var isViewProcess = (specialView || processType == "VIEW RECORD" || processType == "CHECKLIST LIST");
            this.isDisplayOnly = isViewProcess;
            this.objectName = this._data.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"];
            this.helpURL = this._data.headerLayout[SVMX.OrgNamespace + "__Help_URL__c"];
            this.hideQuickSave = isViewProcess || this._data.headerLayout[SVMX.OrgNamespace + "__Hide_Quick_Save__c"] || (processType != "STANDALONE EDIT" && processType != "CHECKLIST");
            this.hideSave = isViewProcess || this._data.headerLayout[SVMX.OrgNamespace + "__Hide_Save__c"];
            this.hideSaveAndNew = (processType != "STANDALONE CREATE");
            this.hideChatter = (processType != "STANDALONE EDIT");
            this.pageHelp = this._data.headerLayout[SVMX.OrgNamespace + "__Page_Help__c"];

            //TODO : Check if this associated processes can be fetched directly here instead of SFMPageMetaModel.
            if(this.isDisplayOnly){
                this.associatedViewProcesses = this._parent.associatedViewProcesses;
            }

            // extract page events.
            var pageEvents = this._data.pageEvents, i, l = pageEvents.length, callType, eventType;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                eventType = pageEvents[i][SVMX.OrgNamespace + "__Event_Type__c"];

                if(eventType == "Before Save/Update" || eventType == "Before Save/Insert"){
                    eventType = "Before Save";
                }else if(eventType == "After Save/Update" || eventType == "After Save/Insert"){
                    eventType = "After Save";
                }

                callType = pageEvents[i][SVMX.OrgNamespace + "__Event_Call_Type__c"];
                if(!callType){
                    callType = "WEBSERVICE"; // default
                    pageEvents[i][SVMX.OrgNamespace + "__Event_Call_Type__c"] = callType;
                }

                if(!platformSpecifics.isEventSupported(pageEvents[i])) continue;

                this.pageEvents[this.pageEvents.length] = {
                    callType : callType,
                    target : pageEvents[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : eventType,
                    eventId : pageEvents[i].Id,
                    eventRawData : pageEvents[i]
                };
            }
            // end page events

            l = this._data.sections.length;
            var col = [];

            var isSLAClockEnabled = SVMX.getClient().getApplicationParameter("enable-sla-clock");
            for(i = 0; i < l; i++){
                if(isSLAClockEnabled || this._data.sections[i].sectionDetail) {
                    var section = this._data.sections[i];
                    var entryCriteriaFlag = section.sectionDetail[SVMX.OrgNamespace+'__Entry_Criteria__c'] || false;
                    if(!entryCriteriaFlag){
                        var eachCol = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageSection", this._data.sections[i], this);
                        eachCol.initialize();
                        if(eachCol){
                            col.push(eachCol);
                        }
                    }
                }
            }
            this._children["sections"] = SVMX.sort(col, "sequence");

            // setup recordtype field
            var rtf = this.getRecordTypeField();
            if(!rtf && this._children["sections"].length > 0){
                rtf = this.createHiddenRecordTypeField(this._children["sections"][0]);
                this.registerRecordTypeField(rtf);
            }
            // end setup recordtype field

            // setup controlling picklist and boolean/checkbox fields which are not modelled on UI.
            var modelledFields = this.getAllPageFields();
            var allPicklists = this._parent.getAllPicklists(this.objectName);
            var hiddenPicklistFields = [], controllingPicklistField, i, j, modelled;
            var l = allPicklists.length, mfl = modelledFields.length;

            for(i = 0; i < l; i++){
                modelled = false;
                for (j = 0; j < mfl; j++){
                    if(allPicklists[i].name == modelledFields[j].fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"]){
                        modelled = true;
                        break;
                    }
                }

                //if the picklist/checkbox field is not modelled on UI, add it to the hidden pl array
                if(!modelled){
                    hiddenPicklistFields.push(allPicklists[i]);
                }
            }

            var k, len =  hiddenPicklistFields.length;

            for(k = 0;  k < len; k++){
                controllingPicklistField = this.createHiddenControllingPicklistField(hiddenPicklistFields[k]);
                //push the hidden controlling pl field into controlling picklist array
                this.registerControllingPicklistField(controllingPicklistField);
            }

            // parse actions
            var buttons = this._data.buttons, button;
            l = buttons.length;
            col = [];
            for(i = 0; i < l; i++){
                if(platformSpecifics.isActionButtonVisible(buttons[i])){
                    button = col[col.length] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageAction", buttons[i], this);
                    button.initialize();
                }
            }
            this._children["actions"] = col;
            // end actions
        },

        //returns all the fields on the page/modelled
        getAllPageFields : function(){
            var sections = this._children["sections"], k, l = sections.length, i, fields = [];
            for(i = 0; i < l; i++){
                //iterate thru the fields, so it can be pushed into fields[] individually and not as
                //one array with n number of fields
                //TODO : Check if looping can be avoided
                for(k = 0; k < sections[i].getData().fields.length; k++){
                    fields.push(sections[i].getData().fields[k]);
                }
            }

            return fields;
        },

        getFieldTypes : function() {
            var fields = this.getAllFields();
            var results = {};
            for (var i = 0; i < fields.length; i++) {
                var f = fields[i];
                results[f.name] = f.type;
            }
            return results;
        },

        getAllFields : function() {
            var root = this.getRoot();
            var tableDef = root.objMetadataMap[this.objectName];
            var fields = tableDef ? tableDef.fields : [];
            return fields;
        },

        getPageEventInfoFor : function(eventType){
            var i, l = this.pageEvents.length, ret = null;
            for(i = 0;  i< l; i++){
                if(this.pageEvents[i].eventType == eventType){
                    ret = this.pageEvents[i];
                    break;
                }
            }

            return ret;
        },

        getAttachmentsHidden : function() {
            if (!this._data || !this._data.headerLayout[SVMX.OrgNamespace + "__Enable_Attachments__c"]) return true;
            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
            return !platformSpecifics.getAttachmentsEnabled();
        },

        getPrecision : function(field){
            return this._parent.getPrecision(this.objectName, field);
        },

        getScale : function(field){
            return this._parent.getScale(this.objectName, field);
        },

        getFieldLabel : function(field){
            return this._parent.getFieldLabel(this.objectName, field);
        },

        isFieldAccessible : function(field){
            return this._parent.isFieldAccessible(this.objectName, field);
        },

        isFieldRequired : function(field){
            return this._parent.isFieldRequired(this.objectName, field);
        },

        isFieldReadOnly : function(field){
            return this._parent.isFieldReadOnly(this.objectName, field);
        },

        getPicklistValues : function(field){
            return this._parent.getPicklistValues(this.objectName, field);
        },

        getControllingPicklist : function(field){
            return this._parent.getControllingPicklist(this.objectName, field);
        },

        resolveDependencies : function(){
            var sections = this._children["sections"], i, l = sections.length;
            for(i = 0; i < l; i++){
                sections[i].resolveDependencies();
            }
        },

        getFieldMetaInfoFromName : function(fieldName){
            return this._parent.getFieldInfoFromName(this.objectName, fieldName);
        },

        getFieldInfoFromName : function(fieldName){
            var sections = this._children["sections"], ret = null, i, l = sections.length;
            for(i = 0; i < l; i++){
                ret = sections[i].getFieldInfo(fieldName);
                if(ret) break;
            }
            return ret;
        },

        getControllingPicklistFieldDataFromName : function(fieldName){
            var ret = this.getFieldInfoFromName(fieldName);
            if(ret){
                ret = ret.getFieldData();
            }

            //TODO : add right comments
            if(!ret){
                var i, l = this.__controllingPicklistFields.length;
                for(i = 0 ; i < l; i++){
                    if(this.__controllingPicklistFields[i].fieldName == fieldName){
                        ret = this.__controllingPicklistFields[i].getFieldData();
                        break;
                    }
                }
            }
            return ret;
        },

        getLookupContextFieldInfo : function(fieldName){
            var sections = this._children["sections"], ret = null, i, l = sections.length;
            for(i = 0; i < l; i++){
                ret = sections[i].getFieldInfo(fieldName);
                if(ret) break;
            }
            return ret;
        },

        getObjectName : function(){
            return this.objectName;
        },

        createHiddenRecordTypeField : function(parentSection){
            if(this.__recordTypeField == null){
                this.__recordTypeField = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageRecordTypeField", null, parentSection);
                this.__recordTypeField.initialize();
            }

            return this.__recordTypeField;
        },

        createHiddenControllingPicklistField : function(picklistField){
            var fieldName = picklistField.name, parent = this.getRoot();
            var picklistField = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageHiddenPicklistField", picklistField, parent);
            picklistField.initialize(fieldName);

            return picklistField;
        },

        registerRecordTypeField : function(field){
            // register only once because it is created only once
            if(this.__recordTypeField == null){
                this.__recordTypeField = field;
            }
        },

        registerControllingPicklistField : function(field){
            // register all the cpl fields
            return this.__controllingPicklistFields.push(field);
        },

        getRecordTypeField : function(){
            return this.__recordTypeField;
        },

        getControllingPicklistFields : function(){
            return this.__controllingPicklistFields;
        },

        setCurrentRecordType : function(type){
            this.__currentRecordType = type;
        },

        getCurrentRecordTypeInfo : function(){
            return this._parent.getCurrentRecordTypeInfo(this.__currentRecordType, this.objectName);
        }
    }, {});


    // Represents the layout and behaviors of a page section
    engine.Class("SFMPageSection", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        title : null, colCount : 0, labelAlignment : "", labelStyle : "", sequence : 0,
        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        destroy: function() {
            var fields = this.getChildNode("fields");
            if (fields) SVMX.array.forEach(fields, function(item) {item.destroy();});
            SVMX.destroy(this);
        },

        initialize : function(){
            this.title = this._data.sectionDetail[SVMX.OrgNamespace + "__Title__c"];
            this.colCount = this.__extractColumnCount();
            this.labelAlignment = SVMX.getClient().getApplicationParameter("svmx-sfm-section-label-align");
            this.labelStyle = SVMX.getClient().getApplicationParameter("svmx-sfm-section-label-style");
            this.sequence = this._data.sectionDetail[SVMX.OrgNamespace + "__Sequence__c"];

            // parse the fields
            var i, l = this._data.fields.length, items = [], recordTypeField = null;
            for(i = 0; i < l; i++){
                var fld = this._data.fields[i];
                var datatype = fld.fieldDetail[SVMX.OrgNamespace + "__DataType__c"];
                var apiName = fld.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];
                var detailType = fld.fieldDetail[SVMX.OrgNamespace + "__Detail_Type__c"];

                if(apiName == CONSTANTS.RECORD_TYPE_ID){
                    recordTypeField = items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageRecordTypeField", fld, this);
                }else if(datatype == 'reference' && detailType === 'Question'){
                    // Special handling to force this to be a view only
                    if (this.getRoot()
                            && this.getRoot().getDeliveryEngine()
                            && this.getRoot().getDeliveryEngine().additionalInfo
                            && this.getRoot().getDeliveryEngine().additionalInfo.specialProcessType === "VIEW") {
                        fld.fieldDetail[SVMX.OrgNamespace + "__Readonly__c"] = true;
                    }

                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageQuestionField", fld, this);
                }else if(datatype == 'reference' && detailType === 'List'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageListField", fld, this);
                }else if(datatype == 'reference'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageReferenceField", fld, this);
                }else if(datatype == 'picklist'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPagePicklistField", fld, this);
                }else if(datatype == 'multipicklist'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageMultiPicklistField", fld, this);
                }else if(datatype == 'boolean'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageBooleanField", fld, this);
                }else{
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageField", fld, this);
                }
                items[i].initialize();
            }
            this._children["fields"] = items;

            if(recordTypeField != null){
                this._parent.registerRecordTypeField(recordTypeField);
            }

        },

        registerControllingPicklistField : function(field){
            return this._parent.registerControllingPicklistField(field);
        },

        __extractColumnCount : function(){
            var colCount = this._data.sectionDetail[SVMX.OrgNamespace + "__No_Of_Columns__c"] || 1;

            // check if there is a column count specified in the URL.
            var ccFromUrl = SVMX.getUrlParameter('column-count');
            if(ccFromUrl && ccFromUrl != ""){
                try{
                    ccFromUrl = parseInt(ccFromUrl);
                    if(!isNaN(ccFromUrl)){
                        colCount = ccFromUrl;
                    }
                }catch(e){}
            }

            return colCount;
        },

        getRecordTypeField : function(){
            return this._parent.getRecordTypeField();
        },

        getControllingPicklistFields : function(){
            return this._parent.getControllingPicklistFields();
        },

        setCurrentRecordType : function(type){
            this._parent.setCurrentRecordType(type);
        },

        getCurrentRecordTypeInfo : function(){
            return this._parent.getCurrentRecordTypeInfo();
        },

        getFieldLabel : function(field){
            return this._parent.getFieldLabel(field);
        },

        getPrecision : function(field){
            return this._parent.getPrecision(field);
        },

        getScale : function(field){
            return this._parent.getScale(field);
        },

        getObjectName : function(){
            return this._parent.getObjectName();
        },

        isFieldAccessible : function(field){
            return this._parent.isFieldAccessible(field);
        },

        isFieldRequired : function(field){
            return this._parent.isFieldRequired(field);
        },

        isFieldReadOnly : function(field){
            return this._parent.isFieldReadOnly(field);
        },

        getPicklistValues : function(field){
            return this._parent.getPicklistValues(field);
        },

        resolveDependencies : function(){
            var fields = this._children["fields"], i, l = fields.length;
            for(i = 0; i < l; i++){
                fields[i].resolveDependencies();
            }
        },

        getFieldInfoFromName : function(fieldName){
            return this._parent.getFieldInfoFromName(fieldName);
        },

        getFieldInfo : function(fieldName){
            var fields = this._children["fields"], ret = null, i, l = fields.length;
            for(i = 0; i < l; i++){
                if(fields[i].fieldName == fieldName){
                    ret = fields[i];
                    break;
                }
            }
            return ret;
        },

        getLookupContextFieldInfo : function(fieldName){
            return this._parent.getLookupContextFieldInfo(fieldName);
        },

        getControllingPicklist : function(field){
            return this._parent.getControllingPicklist(field);
        },

        getFieldMetaInfoFromName : function(fieldName){
            return this._parent.getFieldMetaInfoFromName(fieldName);
        },

        getControllingPicklistFieldDataFromName : function(fieldName){
            return this._parent.getControllingPicklistFieldDataFromName(fieldName);
        },

        getData : function(){
            return this._data;
        },

        //for currentRecord and currentRecordHeader
        getRelatedBindingValue : function(fieldName, source){
            //delegate to the parent
            this._parent.getRelatedBindingValue(fieldName, source);
        }
    }, {});

    engine.Class("SFMPageField", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        fieldName : null, fieldLabel : null, datatype : null, readOnly : false, required : false,
        sequence : 0, row : null, column : null, __dataBinding : null, fieldEvents : null,
        _logger : null, fieldWidth : 0, charLength : 0,
        __constructor : function(data, parent){
            this.__base(data, parent);
            this._logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-SFMPAGEFIELD");
        },
        destroy: function() {
        SVMX.destroy(this);
        },
        initialize : function(){
            this.fieldLabel = this.getFieldLabel();
            this.datatype = this._data.fieldDetail[SVMX.OrgNamespace + "__DataType__c"];
            this.readOnly = this._isFieldReadOnly();
            this.required = this._isFieldRequired();
            this.fieldName = this._data.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];
            //If the user does not have permission to the field, we will not have info.
            var fieldInfo = this.getRoot().getFieldInfo(this._parent.getObjectName(), this._data)
            this.charLength = fieldInfo ? fieldInfo.length : 0;


            this.row = this._data.fieldDetail[SVMX.OrgNamespace + "__Display_Row__c"];
            this.column = this._data.fieldDetail[SVMX.OrgNamespace + "__Display_Column__c"];
            this.fieldWidth = this._data.fieldDetail[SVMX.OrgNamespace + "__Width__c"];

            // fieldEvents
            this.fieldEvents = [];
            var fe = this._data.fieldEvents, i, l = fe.length;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                if(!platformSpecifics.isEventSupported(fe[i])) continue;

                this.fieldEvents[this.fieldEvents.length] = {
                    callType : fe[i][SVMX.OrgNamespace + "__Event_Call_Type__c"],
                    target : fe[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : fe[i][SVMX.OrgNamespace + "__Event_Type__c"],
                    eventId : fe[i].Id,
                    eventRawData : fe[i]
                };
            }
            // end fieldEvents

            // only for detail
            this.sequence = this._data.fieldDetail[SVMX.OrgNamespace + "__Sequence__c"];

            // double fields
            this.precision = this.getPrecision();
            this.scale = this.getScale();
        },

        getEventInfoFor : function(eventType){
            var i, l = this.fieldEvents.length, ret = null;
            for(i = 0;  i< l; i++){
                if(this.fieldEvents[i].eventType == eventType){
                    ret = this.fieldEvents[i];
                    break;
                }
            }
            return ret;
        },

        getFieldData : function(){
            return this._data;
        },

        getPrecision : function(){
            return this._parent.getPrecision(this._data);
        },

        getScale : function(){
            return this._parent.getScale(this._data);
        },

        getFieldLabel : function(){
            return this._parent.getFieldLabel(this._data);
        },

        isFieldAccessible : function(){
            return this._parent.isFieldAccessible(this._data);
        },

        _isFieldRequired : function(){
            //salesforce always returns required as true for boolean
            if(this.datatype == 'boolean') return false;

            var isRequired = this._parent.isFieldRequired(this._data);
            if(isRequired == false){
                isRequired = this._data.fieldDetail[SVMX.OrgNamespace + "__Required__c"];
            }

            return isRequired;
        },

        _isFieldReadOnly : function(){
            var isReadOnly = this._parent.isFieldReadOnly(this._data);
			if(isReadOnly == false){
				isReadOnly = this._data.fieldDetail[SVMX.OrgNamespace + "__Readonly__c"];
			}
            return isReadOnly;
        },

        getPicklistValues : function(){
            SVMX.getLoggingService().getLogger().warning("SFMPageField::getPicklistValues() is deprecated!");
            return SVMX.cloneObject(this._parent.getPicklistValues(this._data));
        },

        createBinding : function(setter, getter, context){
            this.__dataBinding = this.getRoot().getDataModel().createBinding(this.fieldName, setter, getter, context);
            return this.__dataBinding;
        },

        createAttachmentBinding : function(setter, getter, context){
            this.__dataBinding = this.getRoot().getDataModel().createAttachmentBinding(this.fieldName, setter, getter, context);
            return this.__dataBinding;
        },

        getDataBinding : function(){
            if(this.__dataBinding){
                return this.__dataBinding;
            }else{
                return this._parent.getDataBinding();
            }
        }
    }, {});

    engine.Class("SFMPagePicklistField", engine.SFMPageField, {
        isDependentPickList : false, controllingPicklist : null,

        __constructor : function(data, parent){
            this.__base(data, parent);
            this.isDependentPickList = false;
        },

        initialize : function(){
            this.__base();
            this.controllingPicklist = this._parent.getControllingPicklist(this._data);
            if(this.controllingPicklist){
                this.isDependentPickList = true;
            }
        },

        registerControllingPicklistField : function(field){
            return this._parent.registerControllingPicklistField(field);
        },

        __getParentIndexFor : function(value){
            var cpInfo = this._parent.getFieldInfoFromName(this.controllingPicklist);
            var plValues = this._parent.getPicklistValues(cpInfo.getFieldData()), i, l = plValues.length, ret = -1;
            for(i = 0; i < l; i++){
                if(plValues[i].value === value){
                    ret = i;
                    break;
                }
            }

            return ret;
        },

        __getParentPicklistEntryFor : function(value){
            var cpInfo = this._parent.getControllingPicklistFieldDataFromName(this.controllingPicklist), ret = null;

            if(cpInfo){
                var plValues = this._parent.getPicklistValues(cpInfo), i, l = plValues.length;
                for(i = 0; i < l; i++){
                    if(plValues[i].value === value){
                        ret = plValues[i];
                        break;
                    }
                }
            }
            return ret;
        },

        getPicklistEntryLabelFor : function(value){

            // find the corresponding translation
            var plValues = this.getPicklistValues({}, true), i, l = plValues.length, displayValue = "";

            if(value !== undefined && value !== null){
                for(i = 0; i < l; i++){
                    if(plValues[i].value == value){
                        displayValue = plValues[i].label;
                        break;
                    }
                }
            }
            // end translation

            return displayValue;
        },

        getPicklistValues : function(params, ignoreDependency){
            var plValues = this._parent.getPicklistValues(this._data), ret = plValues, i, l, j, k;
            // If readonly, return full pick list since it is needed for reverse lookup from value to lable. See defect 017076
            if(this.isDependentPickList && !ignoreDependency && !this.isDisplayOnly){
                ret = [];
                if(params){
                    // get the selected parent value entry
                    var parentEntry = this.__getParentPicklistEntryFor(params.value);
                    if(parentEntry){
                        var dpInfo = parentEntry.dependendPicklist;
                        if(dpInfo){
                            l = dpInfo.length;

                            // get the right dependent picklist index array for this parent value and this field
                            for(i = 0; i < l; i++){
                                if(dpInfo[i].fieldAPIName == this.fieldName){
                                    var dpValueIndices = dpInfo[i].value;
                                    if(dpValueIndices){
                                        // value will be a string of ; separated indexes
                                        dpValueIndices = dpValueIndices.split(';');
                                        var plValuesLength = plValues.length;
                                        for(j = 0, k = 0; j < plValuesLength; j++){
                                            if(dpValueIndices[k] == j){
                                                ret.push(plValues[j]);
                                                k++;
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            // filter the values further if record type information is available
            var currentRecordType = this._getCurrentRecordTypeInfo(params);
            if(currentRecordType){
                var picklistForRecordType = this._extractPicklistFromRecordTypeInfo(currentRecordType);
                if(picklistForRecordType && picklistForRecordType.length > 0){
                    var filteredRet = [], rtLength = picklistForRecordType.length;
                    l = ret.length;
                    for(i = 0; i < l; i++){
                        for(j = 0; j < rtLength; j++){
                            if(ret[i].value == picklistForRecordType[j].value){
                                filteredRet.push(ret[i]);
                                break;
                            }
                        }
                    }
                    ret = filteredRet;
                }
            }
            // end filter based on record type information

            // include the no value
            var noValue = TS.T("FSA008_TAG065","--None--");
            ret = SVMX.cloneObject(ret);
            ret.splice(0,0, {label : noValue, value : CONSTANTS.NO_VALUE});
            // end no value

            return ret;
        },

        _getCurrentRecordTypeInfo : function(params){
            return this._parent.getCurrentRecordTypeInfo();
        },

        _extractPicklistFromRecordTypeInfo : function(recordTypeInfo){
            if (!recordTypeInfo.picklistsForRecordType) return [];
            var ret  = null, picklistsForRecordType = recordTypeInfo.picklistsForRecordType, i, l = picklistsForRecordType.length,
                values, j, k;
            for(i = 0; i < l; i++){
                if(picklistsForRecordType[i].picklistName == this.fieldName){
                    values = picklistsForRecordType[i].picklistValues;
                    break;
                }
            }

            if(values){
                var plValues = this._parent.getPicklistValues(this._data);
                var picklistValueIndices = values[0].value;
                if(picklistValueIndices){
                    var picklistValueIndexArray = picklistValueIndices.split(";");
                    var plValuesLength = plValues.length;
                    ret = [];
                    for(j = 0, k = 0; j < plValuesLength; j++){
                        if(picklistValueIndexArray[k] == j){
                            ret.push(plValues[j]);
                            k++;
                        }
                    }
                }
            }

            return ret;
        },

        createBinding : function(setter, getter, context){
            this.__dataBinding = this.getRoot().getDataModel().createPicklistBinding(this.fieldName, setter, getter, context);
            return this.__dataBinding;
        },

        getControllerBinding : function(){
            var cpInfo, cpMetaInfo, ret = null;
            cpMetaInfo = this._parent.getFieldMetaInfoFromName(this.controllingPicklist);
            cpInfo = this._parent.getControllingFieldInfo(this.controllingPicklist);

            if(cpInfo){
                ret = cpInfo.getDataBinding();
            }

            return ret;
        },

        getRecordTypeField : function(){
            return this._parent.getRecordTypeField();
        },

        getControllingPicklistFields : function(){
            if(this._parent.getControllingPicklistFields() != undefined){
                return this._parent.getControllingPicklistFields();
            }
        },

        resolveDependencies : function(){
            var cpInfo, cpMetaInfo;
            if(this.isDependentPickList){
                cpMetaInfo = this._parent.getFieldMetaInfoFromName(this.controllingPicklist);
                cpInfo = this._parent.getFieldInfoFromName(this.controllingPicklist);
                if(cpInfo){
                    cpInfo.bind("CHANGED", this._parentValueChanged, this);
                    cpInfo.bind("AFTER_CHANGED", this._afterValueChanged, this);
                }else{
                    // register for change of hidden controlling picklist(not modelled on UI)
                    var hiddenControllingPicklist = this.getControllingPicklistFields();
                    var i, l = hiddenControllingPicklist.length;
                    if(cpMetaInfo && cpMetaInfo.name){
                        for(i = 0; i < l; i++){
                            if(hiddenControllingPicklist[i]._data.name == cpMetaInfo.name){
                                hiddenControllingPicklist[i].bind("CHANGED", this._parentValueChanged, this);
                                hiddenControllingPicklist[i].bind("AFTER_CHANGED", this._afterValueChanged, this);
                            }
                        }
                    }
                    // this is a dependent picklist, but the controlling picklist is not modeled.
                    // so make this picklist a non-dependent picklist
                    //this.isDependentPickList = false;
                    this._logger.warning(this.fieldName
                        + " is a dependent picklist but the controlling picklist is not modeled!");
                }
            }else{

                if(this.shouldParticipateInDependencyChain()){
                    // register for change of record type. available either via explicitly modeled view element or via field mapping
                    var recordTypeField = this.getRecordTypeField();
                    if(recordTypeField){
                        recordTypeField.bind("CHANGED", this._parentValueChanged, this);
                        recordTypeField.bind("AFTER_CHANGED", this._afterValueChanged, this);
                    }
                }
            }
        },

        _parentValueChanged : function(evt){
            // notify the listeners
            var evtChanged = SVMX.create("com.servicemax.client.lib.api.Event",
                 "PARENT_CHANGED", this, evt.data);
               this.triggerEvent(evtChanged);
               // end notify
        },

        _afterValueChanged : function(evt){
            // notify the listeners
            var evtChanged = SVMX.create("com.servicemax.client.lib.api.Event",
                 "AFTER_CHANGED", this, evt.data);
               this.triggerEvent(evtChanged);
               // end notify
        },

        shouldParticipateInDependencyChain : function(){
            return true;
        }
    }, {});

    engine.Class("SFMPageBooleanField", engine.SFMPageField, {

        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        resolveDependencies : function(){
            // register for change of record type. available either via explicitly modeled view element or via field mapping
            var recordTypeField = this._parent.getRecordTypeField();
            if(recordTypeField){
                recordTypeField.bind("CHANGED", this._parentValueChanged, this);
                recordTypeField.bind("AFTER_CHANGED", this._afterValueChanged, this);
            }
        },

        _parentValueChanged : function(evt){
            // notify the listeners
            var evtChanged = SVMX.create("com.servicemax.client.lib.api.Event",
                 "PARENT_CHANGED", this, evt.data);
               this.triggerEvent(evtChanged);
               // end notify
        },

        _afterValueChanged : function(evt){
            // notify the listeners
            var evtChanged = SVMX.create("com.servicemax.client.lib.api.Event",
                 "AFTER_CHANGED", this, evt.data);
               this.triggerEvent(evtChanged);
               // end notify
        }
    }, {});

    engine.Class("SFMPageMultiPicklistField", engine.SFMPagePicklistField, {

        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        initialize : function(){
            this.__base();
        }
    }, {});

    engine.Class("SFMPageRecordTypeField", engine.SFMPagePicklistField, {
        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        initialize : function(){
            if(this._data == null){
                this.fieldName = "RecordTypeId";
                this._initializeHiddenMode();
            }else{
                this.__base();
            }
            this.datatype = 'recordtype';
            this.fieldLabel = TS.T("FSA008_TAG126", "Record Type");
        },

        _initializeHiddenMode : function(){
            // run in the hidden mode when field is not modeled explicitly but may come via mapping
            var recordType = null;
            this.__dataBinding = this.getRoot().getDataModel().createBinding(
                this.fieldName, function(value){
                    // setter
                    recordType = value;
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                                 "CHANGED", this, {value : recordType});
                    this.triggerRecordTypeChanged(evt);
                }, function(){
                    // getter
                    return recordType;
                }, this);
        },

        getPicklistValues : function(params, ignoreDependency){
            var objName = this._parent.getObjectName(), recordTypes = this.getRoot().getRecordTypesFor(objName),
                noValue = TS.T("FSA008_TAG065","--None--"),
                ret = [{label : noValue, value : CONSTANTS.NO_VALUE}], i, l = recordTypes.length;

            for(i = 0; i < l; i++){
                ret.push({label : recordTypes[i].name, value : recordTypes[i].recordTypeId});
            }

            return ret;
        },

        triggerRecordTypeChanged : function(evtData){
            var recordType = evtData.data.value;
            if(recordType === CONSTANTS.NO_VALUE){
                // clear the record type
                recordType = null;
            }
            this._parent.setCurrentRecordType(recordType);
            this.triggerEvent(evtData);
        },

        shouldParticipateInDependencyChain : function(){
            return false; // does not have a parent, so no need to participate
        }
    }, {});

    engine.Class("SFMPageHiddenPicklistField", engine.SFMPagePicklistField, {
        __constructor : function(data, parent){
            this.__base(data, parent);
        },
        initialize : function(){
            this.fieldName = this._data.name;
            var plValue = null;
            this.__dataBinding = this.getRoot().getDataModel().createBinding(
                this.fieldName, function(value){
                    // setter
                    //the controlling field can also be a checkbox, in such scenario the
                    //checkbox is treated like a picklist with true and false being possible values
                    //Convert the boolean value to string in such a scenario.
                    if(typeof(value) == "boolean"){
                        plValue = value.toString();
                    }else{
                        plValue = value;
                    }

                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                                 "CHANGED", this, {value : plValue});
                    this.triggerHiddenPicklistChanged(evt);
                }, function(){
                    // getter
                    var ret = plValue;
                    if(this._data.dataType =='boolean'
                        && (plValue === undefined || plValue === null || plValue === "")) {
                        ret = !!plValue;
                    }

                    return ret    ;
                }, this);
        },

        triggerHiddenPicklistChanged : function(evtData){
            this.triggerEvent(evtData);
        }
    }, {});

    engine.Class("SFMPageReferenceField", engine.SFMPageField, {
        objectName : null, namedSearchId : null, bOverrideRelatedLookup : true, lookupContext : null,
        lookupQueryField : null, lookupContextFieldInfo : null, __lookupModel : null, enableRecentItems : false,
        nameFieldName : null, fieldMappingId: null,

        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        initialize : function(){
            this.__base();
            // information required to trigger look up
            this.objectName             = this._data.fieldDetail[SVMX.OrgNamespace + "__Related_Object_Name__c"];         // OBJECTNAME
            this.namedSearchId             = this._data.fieldDetail[SVMX.OrgNamespace + "__Named_Search__c"];                 // RECORDID
            this.bOverrideRelatedLookup = this._data.fieldDetail[SVMX.OrgNamespace + "__Override_Related_Lookup__c"];
            this.lookupQueryField         = this._data.fieldDetail[SVMX.OrgNamespace + "__Lookup_Query_Field__c"];         // FIELDNAME
            this.lookupContext             = this._data.fieldDetail[SVMX.OrgNamespace + "__Lookup_Context__c"];             // CONTEXTVALUE
            this.nameFieldName             = this._data.fieldDetail[SVMX.OrgNamespace + "__Related_Object_Name_Field__c"]; // Name Field Name
            this.fieldMappingId            = this._data.fieldDetail[SVMX.OrgNamespace + "__Field_Mapping__c"]; // ID of the Field Mapping

            this.autoResolveLookup  = this.getRoot().getDeliveryEngine().getSettings().getSetting("SET001", 'bool');
            this.enableRecentItems = this.getRoot().getDeliveryEngine().getSettings().getSetting("SET003", 'bool');
            // end look up info
        },

        createBinding : function(setter, getter, context){
            this.__dataBinding = this.getRoot().getDataModel().createReferenceBinding(this.fieldName, setter, getter, context);
            return this.__dataBinding;
        },

        resolveDependencies : function(){
            if(this.lookupContext){
                this.lookupContextFieldInfo = this._parent.getLookupContextFieldInfo(this.lookupContext);
            }
        },

        getLookupModel : function(createNew){
            if(this.__lookupModel == null){
                this.__lookupModel = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageLookupModel", this);
            }

            if(createNew){
                this.__lookupModel = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageLookupModel", this);
            }

            return this.__lookupModel;
        },

        getFieldLabelFromRelatedObject : function(fieldName){
            return this.getRoot().getLabel(this.objectName, fieldName);
        },

        getFieldTypeFromRelatedObject : function(fieldName){
            return this.getRoot().getFieldType(this.objectName, fieldName);
        },

        getRelatedObjectLabel : function(){
            return this.getRoot().getObjectLabel(this.objectName);
        },

        getRelatedObjectPluralLabel : function(){
            return this.getRoot().getObjectPluralLabel(this.objectName);
        },

        getPicklistValuesFromRelatedObject : function(fieldName){
            return this.getRoot().getPicklistValuesFromFieldName(this.objectName, fieldName);
        }
    }, {});

///todo: n
    engine.Class("SFMPageQuestionField", engine.SFMPageField, {
        __fieldInfo : {},

        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        initialize : function() {


            if (this._data.fieldDetail && this._data.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]) {
                this.__fieldInfo = SVMX.toObject(this._data.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]);
            }

            this.fieldLabel = this.getFieldLabel();
            this.datatype = this.__getDataType();
            this.readOnly = this._isFieldReadOnly();
            this.required = this._isFieldRequired();
            this.fieldName = this.__getFieldName();
            this.isDisplayOnly = this._isFieldReadOnly();
            this.defaultValueObject = this.__getDefaultValue();
            this.isliteralUsedInDefaultValue = this.isliteralUsedInDefaultValue();
            this.questionType = this.getQuestionDataType();
            this.dynamicResponseField = this.getDynamicResponseField();
            this.questionSFID = this.getQuestionId();
            this.questionName = this.getQuestionName();
            this.isDescriptionRequired = this.getDescriptionRequired();
            this.charLength = this.__fieldInfo && this.__fieldInfo.question && this.__fieldInfo.question.length? this.__fieldInfo.question.length : 0;
            var sourceFieldObject = this.getFieldObject(this.dynamicResponseField);
            if(sourceFieldObject){
                this.defaultDyamicValue = sourceFieldObject;
            }


            this.row = this._data.fieldDetail[SVMX.OrgNamespace + "__Sequence__c"];
            this.column = 1;
            this.fieldWidth = this._data.fieldDetail[SVMX.OrgNamespace + "__Width__c"];

            // fieldEvents
            this.fieldEvents = [];
            var fe = this._data.fieldEvents, i, l = fe.length;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                if(!platformSpecifics.isEventSupported(fe[i])) continue;

                this.fieldEvents[this.fieldEvents.length] = {
                    callType : fe[i][SVMX.OrgNamespace + "__Event_Call_Type__c"],
                    target : fe[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : fe[i][SVMX.OrgNamespace + "__Event_Type__c"],
                    eventId : fe[i].Id,
                    eventRawData : fe[i]
                };
            }
            // end fieldEvents

            // only for detail
            this.sequence = this._data.fieldDetail[SVMX.OrgNamespace + "__Sequence__c"];

            // double fields
            this.precision = this.getPrecision();
            this.scale = this.getScale();
        },

        getFieldObject : function(fieldName){
            var parent = this._parent._parent._parent._sourceRecord;
            if(parent){
                var fieldLength = parent.length;
                var fieldInfo ;
                for(var fieldIndex = 0; fieldIndex < fieldLength; fieldIndex++) {
                    var field = parent[fieldIndex];
                    if(field.key === fieldName){
                        fieldInfo = field;
                        break;
                    }
                }
            }
            return fieldInfo;
        },

        __getDataType : function() {
            var dataType = "";

            if (this._data && this._data.fieldDetail[SVMX.OrgNamespace + "__Detail_Type__c"]) {
                dataType = this._data.fieldDetail[SVMX.OrgNamespace + "__Detail_Type__c"];
                dataType = dataType && dataType.toLowerCase();
            }

            return dataType;
        },

        __getQuestionInfo : function(field) {
            var value = null;

            if (field && this.__fieldInfo && this.__fieldInfo.question) {
                value = this.__fieldInfo.question[field] || null;
            }

            return value;
        },

        __getFieldName : function() {
            return this.__getQuestionInfo("questionID");
        },

        _isFieldReadOnly : function(){
            var isReadOnly = this._data.fieldDetail[SVMX.OrgNamespace + "__Readonly__c"];

            return isReadOnly;
        },

        _isFieldRequired: function() {
                //salesforce always returns required as true for boolean
                if (this.datatype == 'boolean')
                    return false;

                var isRequired = this._data.fieldDetail[SVMX.OrgNamespace + "__Required__c"];

                return isRequired;
         },

        getQuestionType : function() {
            var value = this.__getQuestionInfo("responseType");
            value = value && value.toLowerCase();

            return value;
        },

        getFieldLabel : function() {
            return this.__getQuestionInfo("question");
        },

        getPrecision : function() {
            return this.__getQuestionInfo("precision") || 0;
        },

        getScale : function() {
            return this.__getQuestionInfo("scale") || 0;
        },

        getHelpURL : function() {
            var helpURL = this.__getQuestionInfo("helpURL") || undefined;
            //If helpURL is defined
            //then do a sanity check of url
            //i.e. if it doesn't contains http:// then prepend the same to it
            var pattern = /^((http|https):\/\/)/;
           var testHelpURL = helpURL!=undefined?helpURL.toLowerCase():undefined;
           if(testHelpURL && testHelpURL.length > 0 && !pattern.test(testHelpURL)){
                helpURL = 'http://'+helpURL;
           }
            return helpURL;
        },

        isFieldRequired : function(){
            return this.required;
        },

        isFieldAccessible : function(){
            return this.__getQuestionInfo("active") || false;
        },

        __getDefaultValue : function(){
            var defaultValue;
            if(this.__fieldInfo.defaultChecklistRes && this.__fieldInfo.defaultChecklistRes[SVMX.OrgNamespace  + '__SM_Default_Response__c']){ 
                defaultValue = SVMX.toObject(this.__fieldInfo.defaultChecklistRes[SVMX.OrgNamespace  + '__SM_Default_Response__c']);
            }
            return defaultValue;
        },

        isliteralUsedInDefaultValue : function(){
            var isliteraUsed = false;
            if(this.__fieldInfo.defaultChecklistRes && this.__fieldInfo.defaultChecklistRes[SVMX.OrgNamespace + '__SM_Is_literal_Used__c']){
                isliteraUsed = this.__fieldInfo.defaultChecklistRes[SVMX.OrgNamespace + '__SM_Is_literal_Used__c'];
            }
             return isliteraUsed;
        },

        getQuestionDataType: function(){
            return this.__getQuestionInfo("responseType");
        },

        getDynamicResponseField : function(){
            var dynamicResponse;
            if(this._data.fieldDetail[SVMX.OrgNamespace + '__SM_Checklist_Source_Field_API_Name__c']){
                dynamicResponse = this._data.fieldDetail[SVMX.OrgNamespace + '__SM_Checklist_Source_Field_API_Name__c'];
            }
            return dynamicResponse;
        },

        getQuestionId : function(){
            var questionID = this._data.fieldDetail[SVMX.OrgNamespace +'__Question__c'];
            return questionID;
        },

        getQuestionName: function(){
            var questionID = this._data.fieldDetail.Name;
            return questionID;
        },

        getDescriptionRequired: function(){
            var isDescriptionRequired = false;
            if(this.__fieldInfo.question){
                isDescriptionRequired = this.__fieldInfo.question.descriptionRequired;
            }
            return isDescriptionRequired;
        }

    }, {});

    engine.Class("SFMPageListField", engine.SFMPageField, {
        __fieldInfo : {},

        __constructor : function(data, parent){
            this.__base(data, parent);
        },

        initialize : function() {
            if (this._data.fieldDetail && this._data.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]) {
                this.__fieldInfo = SVMX.toObject(this._data.fieldDetail[SVMX.OrgNamespace + "__QuestionInfoJSON__c"]);
            }

            this.fieldLabel = this.getFieldLabel();
            this.datatype = this.__getDataType();
            this.readOnly = this._isFieldReadOnly();
            this.required = this._isFieldRequired();
            this.fieldName = this.__getFieldName();
            this.isDisplayOnly = this._isFieldReadOnly();

            this.charLength = 0; // Info not relevant to this field type


            this.row = this._data.fieldDetail[SVMX.OrgNamespace + "__Sequence__c"];
            this.column = 1;
            this.fieldWidth = this._data.fieldDetail[SVMX.OrgNamespace + "__Width__c"];

            // fieldEvents
            this.fieldEvents = [];
            var fe = this._data.fieldEvents, i, l = fe.length;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                if(!platformSpecifics.isEventSupported(fe[i])) continue;

                this.fieldEvents[this.fieldEvents.length] = {
                    callType : fe[i][SVMX.OrgNamespace + "__Event_Call_Type__c"],
                    target : fe[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : fe[i][SVMX.OrgNamespace + "__Event_Type__c"],
                    eventId : fe[i].Id,
                    eventRawData : fe[i]
                };
            }
            // end fieldEvents

            // only for detail
            this.sequence = this._data.fieldDetail[SVMX.OrgNamespace + "__Sequence__c"];

            // double fields
            this.precision = this.getPrecision();
            this.scale = this.getScale();
        },

        __getDataType : function() {
            var dataType = "list"; // For now, there is only one type

            return dataType;
        },

        __getFieldName : function() {
            return this._data.fieldDetail["Id"] || "" ;
        },

        _isFieldReadOnly : function(){
            var isReadOnly = this._data.fieldDetail[SVMX.OrgNamespace + "__Readonly__c"];

            return isReadOnly;
        },

        getFieldLabel : function() {
            return ""; // List labels for now don't exist
        },

        getPrecision : function() {
            return 0;
        },

        getScale : function() {
            return 0;
        },

        isFieldAccessible : function(){
            return true; //TODO: Sort where to get this info
        }
    }, {});

    engine.Class("SFMPageAction", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        title : null, events : null,
        destroy: function() {
        SVMX.destroy(this);
        },
        __constructor : function(data, parent){
            this.__base(data, parent);
            this.events = [];
        },

        initialize : function(){
            this.title = this._data.buttonDetail[SVMX.OrgNamespace + "__Title__c"];
            var buttonEvents = this._data.buttonEvents, i, l = buttonEvents.length;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                if(!platformSpecifics.isEventSupported(buttonEvents[i])) continue;

                this.events[this.events.length] = {
                    callType : buttonEvents[i][SVMX.OrgNamespace + "__Event_Call_Type__c"],
                    target : buttonEvents[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : buttonEvents[i][SVMX.OrgNamespace + "__Event_Type__c"],
                    eventId : buttonEvents[i].Id,
                    eventRawData : buttonEvents[i]
                };
            }
        }
    }, {});

    // Represents a set of details
    engine.Class("SFMPageDetails", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        __path : null,
        __constructor : function(data, parent){
            this.__base(data, parent);
            this.__path = "details";
        },
        destroy: function() {
        var details = this.getChildNode("details");
        if (details) SVMX.array.forEach(details, function(item) {item.destroy();});
        SVMX.destroy(this);

        },
        initialize : function(cbHandler, context){

            var i, l = this._data.length, items = [];
            for(i = 0; i < l; i++){
                items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetail", this._data[i], this);
                items[i].initialize();
            }
            this._children["details"] = SVMX.sort(items, "sequence");

            // the sfm page model has index starting from  > 1 and non-sequential !!!! re-factor them
            l = this._children["details"].length;
            for(i = 0; i < l; i++){
                this._children["details"][i].afterSort(i+1); // page model index starts from 1
            }

            cbHandler.call(context);
        },

        getCurrentRecordTypeInfo : function(recordType, objectName){
            return this._parent.getCurrentRecordTypeInfo(recordType, objectName);
        },

        getFieldLabel : function(objectName, field){
            return this._parent.getFieldLabel(objectName, field);
        },

        getPrecision : function(objectName, field){
            return this._parent.getPrecision(objectName, field);
        },

        getScale : function(objectName, field){
            return this._parent.getScale(objectName, field);
        },

        isFieldAccessible : function(objectName, field){
            return this._parent.isFieldAccessible(objectName, field);
        },

        isFieldRequired : function(objectName, field){
            var result = this._parent.isFieldRequired(objectName, field);
            if (!result) {
                result = field.fieldDetail[SVMX.OrgNamespace + "__Required__c"];
            }
            return result;
        },

        isFieldReadOnly : function(objectName, field){
            return this._parent.isFieldReadOnly(objectName, field);
        },

        getPicklistValues : function(objectName, field){
            return this._parent.getPicklistValues(objectName, field);
        },

        getControllingPicklist : function(objectName, field){
            return this._parent.getControllingPicklist(objectName, field);
        },

        getAllPicklists : function(objectName){
            //Get all the fields of dataType "picklist" and "boolean" within the object.
            var allFields = this._parent.objMetadataMap[objectName].fields;
            var i, l = allFields.length, picklistFields = [];

            for(i = 0; i < l; i++){
                if(allFields[i].dataType == 'picklist' || allFields[i].dataType == "boolean"){
                    picklistFields.push(allFields[i]);
                }
            }

            return picklistFields;
        },

        getFieldMetaInfoFromName : function(objectName, fieldName){
            return this._parent.getFieldInfoFromName(objectName, fieldName);
        },

        resolveDependencies : function(){
            var details = this._children["details"], i, l = details.length;
            for(i = 0; i < l; i++){
                details[i].resolveDependencies();
            }
        },

        getParent : function(){
            return this._parent;
        },

        getDetail : function(path){
            var details = this._children["details"], i, l = details.length, ret = null;
            for(i = 0; i < l; i++){
                if(details[i].layoutId == path.split(".")[1]){
                    ret = details[i];
                    break;
                }
            }

            return ret;
        },

        getPath : function(){
            return this.__path;
        },

        getControllingPicklistFieldDataFromName : function(objectName, fieldName){
            //TODO : Revisit this logic during details cpl impementation
            var ret = this._parent.getFieldInfoFromName(objectName, fieldName);

            if(!ret){
                var i, l = this.__controllingPicklistFields.length;
                for(i = 0 ; i < l; i++){
                    if(this.__controllingPicklistFields[i].fieldName == fieldName){
                        ret = this.__controllingPicklistFields[i].getFieldData();
                        break;
                    }
                }
            }
            return ret;
        },

        //for currentRecord and currentRecordHeader
        getRelatedBindingValue : function(fieldName, source, params){
            var value= "";

            //delegate to the parent   final place for detail - currentrecord
            if(source == "CURRENTRECORD"){
                if(params && params.valueHash){
                    var fieldObj = params.valueHash[fieldName + "__key"];
                    if(fieldObj != null && fieldObj != undefined && fieldObj != "" && typeof(fieldObj) == 'object'){
                        value = fieldObj.key;
                        if(params.isDateTime){
                            //format the datetime value
                            value = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(value);

                            var timeZoneOffset = params.userInfo.TimezoneOffset;

                            var platformSpecifics = SVMX.getClient()
                                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

                            //apply formatting to be understood by SOQL or SQL query
                            value = platformSpecifics.getFormattedDateTimeValue(value, timeZoneOffset);
                        }else if(params.isDateOnly){
                            var platformSpecifics = SVMX.getClient()
                                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
                            value = platformSpecifics.getFormattedDateValue(value);
                        }
                    }else{
                        value = params.valueHash[fieldName];
                    }
                }
            }else{
                //for currentrecordheader TODO : shud be ideally done on header
                value = this.getRoot().__dataModel.__allBindingsHash[fieldName].getValue();
                var binding = this.getRoot().__dataModel.__allBindingsHash[fieldName];

                // Format for SOOQL or SQL.
                // For blank values Online: x=null vs OFFLINE x=''
                var bindingContext = binding.__context;
                if (bindingContext != null) {
                    var contextMetaModle = (bindingContext.getCompositionMetamodel && bindingContext.getCompositionMetamodel()) || bindingContext.compositionMetamodel;
                    if(contextMetaModle.datatype == "datetime"){
                        var platformSpecifics = SVMX.getClient()
                            .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
                        var timeZoneOffset = this.getRoot().getUserInfo().TimezoneOffset;
                        value = platformSpecifics.getFormattedDateTimeValue(value, timeZoneOffset);
                    } else if(contextMetaModle.datatype == "date"){
                        var platformSpecifics = SVMX.getClient()
                            .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();
                        value = platformSpecifics.getFormattedDateValue(value);
                    }
                }

                if(value && typeof(value) == 'object'){
                    value = value.key;
                }
            }

            return value;
        }
    }, {});

    engine.Class("SFMPageDetail", com.servicemax.client.sfmconsole.api.CompositionMetaModel, {
        __logger: null,
        title : "", sequence : 0, allowNewLines : false, allowDeleteLines : false, actionOnZeroLines : "",
        objectName : "", layoutId : null, __dataBinding : null,
        __allColumnDataBindings : null, __allColumnDataBindingsHash: null,
        colCount : 0, labelAlignment : null, events : null, labelStyle : null, __recordTypeField : null,
        multiAddSearchObject : null, multiAddSearchField : null, enableRecentItems : true,
        __controllingPicklistFields : [],
        __constructor : function(data, parent){
            this.__base(data, parent);
            this.__logger = SVMX.getLoggingService().getLogger("SFMDELIVERY-PAGE-DETAIL-MODEL");
            this.events = [];
        },
        destroy: function() {
            var fields = this.getChildNode("fields");
            if (fields) SVMX.array.forEach(fields, function(item) {item.destroy();});
            SVMX.destroy(this);
        },

        initialize : function(){
            this.__allColumnDataBindings = [];
            this.__allColumnDataBindingsHash = {};

            // required to show extended edit
            this.colCount = 1;
            this.labelAlignment = SVMX.getClient().getApplicationParameter("svmx-sfm-section-label-align");
            this.labelStyle = SVMX.getClient().getApplicationParameter("svmx-sfm-section-label-style");
            // end extended edit

            this.title = this._data.DetailLayout[SVMX.OrgNamespace + "__Name__c"];
            this.sequence = this._data.DetailLayout[SVMX.OrgNamespace + "__Sequence__c"];
            this.allowNewLines = this._data.DetailLayout[SVMX.OrgNamespace + "__Allow_New_Lines__c"];
            this.allowDeleteLines = this._data.DetailLayout[SVMX.OrgNamespace + "__Allow_Delete_Lines__c"];

            // possible values are Allow, Warn, Disallow
            this.actionOnZeroLines = this._data.DetailLayout[SVMX.OrgNamespace + "__Action_On_Zero_Lines__c"];

            this.objectName = this._data.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
            this.layoutId = this._data.DetailLayout.Id;
            this.multiAddSearchField = this._data.DetailLayout[SVMX.OrgNamespace + "__Multi_Add_Search_Field__c"];
            this.multiAddSearchObject = this._data.DetailLayout[SVMX.OrgNamespace + "__Multi_Add_Search_Object__c"];

            this.enableRecentItems = this.getRoot().getDeliveryEngine().getSettings().getSetting("SET003", 'bool');

            var k, modelledLinkedProcesses = this._data.linkedProcesses, linkedProCollection = [];
            if(modelledLinkedProcesses){
                len = modelledLinkedProcesses.length;
            }else{
                len = 0;
            }

            for(k = 0; k < len; k++){
                var lp = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailLinkedProcess", modelledLinkedProcesses[k]);
                linkedProCollection.push(lp);
            }

            this.linkedProcesses = SVMX.sort(linkedProCollection, "sequence");

            // parse the events
            var detailEvents = this._data.events, i, l = detailEvents.length;

            var platformSpecifics = SVMX.getClient()
                .getServiceRegistry().getService("com.servicemax.client.platformspecifics").getInstance();

            for(i = 0; i < l; i++){

                if(!platformSpecifics.isEventSupported(detailEvents[i])) continue;

                this.events[this.events.length] = {
                    callType : detailEvents[i][SVMX.OrgNamespace + "__Event_Call_Type__c"],
                    target : detailEvents[i][SVMX.OrgNamespace + "__Target_Call__c"],
                    eventType : detailEvents[i][SVMX.OrgNamespace + "__Event_Type__c"],
                    eventId : detailEvents[i].Id,
                    eventRawData : detailEvents[i]
                };
            }
            // end events

            // parse the fields
            l = this._data.fields.length;
            var items = [];
            for(i = 0; i < l; i++){
                var fld = this._data.fields[i], datatype = fld.fieldDetail[SVMX.OrgNamespace + "__DataType__c"],
                apiName = fld.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];;

                if(apiName == CONSTANTS.RECORD_TYPE_ID){
                    this.__recordTypeField = items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailRecordTypeField", fld, this);
                }else if(datatype == 'reference'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailReferenceField", fld, this);
                }else if(datatype == 'picklist'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailPicklistField", fld, this);
                }else if(datatype == 'multipicklist'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailMultiPicklistField", fld, this);
                }else if(datatype == 'datetime' || datatype == 'date'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailDatetimeField", fld, this);
                }/*else if(datatype == 'boolean'){
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailBooleanField", fld, this);
                }*/else{
                    items[i] = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailField", fld, this);
                }

                items[i].initialize();
            }

            if(this.__recordTypeField == null){
                this.__recordTypeField = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailRecordTypeField", null, this);
                this.__recordTypeField.initialize();
            }

            // setup controlling picklist and boolean/checkbox fields which are not modelled on UI.
            var modelledFields = this.getAllDetailFields();
            var allPicklists = this._parent.getAllPicklists(this.objectName);
            var hiddenPicklistFields = [], controllingPicklistField, i, j, modelled;
            var l = allPicklists.length, mfl = modelledFields.length;

            for(i = 0; i < l; i++){
                modelled = false;
                for (j = 0; j < mfl; j++){
                    if(allPicklists[i].name == modelledFields[j].fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"]){
                        modelled = true;
                        break;
                    }
                }
                if(!modelled){
                    hiddenPicklistFields.push(allPicklists[i]);
                }
            }

            var k, hplfl =  hiddenPicklistFields.length;

            for(k = 0;  k < hplfl; k++){
                controllingPicklistField = this.createHiddenControllingPicklistField(hiddenPicklistFields[k]);
                //push the hidden controlling pl field into controlling picklist array
                this.registerControllingPicklistField(controllingPicklistField);
            }
            //end

            this._children["fields"] = SVMX.sort(items, "sequence");
        },

        getAllFieldData : function() {
            return this._children.fields;
        },

        getAllDetailFields : function(){
            return this._data.fields;
        },

        getAllObjectFieldTypes : function() {
            var allFieldTypes = {};
            SVMX.array.forEach(this.getRoot().getObjectInfo(this.objectName).fields, function(field) {
                allFieldTypes[field.name] = field.type;
            }, this);
            return allFieldTypes;
        },

        getFieldTypes : function() {
            var fields = this.getAllDetailFields();
            var results = {};
            for (var i = 0; i < fields.length; i++) {
                var f = fields[i];
                results[f.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"]] =
                    f.fieldDetail[SVMX.OrgNamespace + "__DataType__c"];
            }
            return results;
        },

        getAllFieldTypes : function() {
            var objDescribe = this.getRoot().objMetadataMap[this.objectName];
            var fields = objDescribe ? objDescribe.fields : [];
            var fieldTypes = {};
            SVMX.array.forEach(fields, function(field) {
                fieldTypes[field.name] = field.type;
            }, this);
            return fieldTypes;
        },

        registerControllingPicklistField : function(field){
            // register all the cpl fields
            return this.__controllingPicklistFields.push(field);
        },

        getControllingPicklistFieldDataFromName : function(fieldName){
            //TODO : Revisit this logic during details cpl impementation
            return this._parent.getControllingPicklistFieldDataFromName(this.objectName, fieldName);
        },

        createHiddenControllingPicklistField : function(picklistField){
            var fieldName = picklistField.name, parent = this.getRoot();
            var picklistField = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageDetailHiddenPicklistField", picklistField, this);
            picklistField.initialize(fieldName);

            return picklistField;
        },

        afterSort : function(sortIndex){
            this.sequence = this._data.DetailLayout[SVMX.OrgNamespace + "__Sequence__c"] = sortIndex;
        },

        getEventInfoFor : function(eventType){
            var i, l = this.events.length, ret = null;
            for(i = 0;  i< l; i++){
                if(this.events[i].eventType == eventType){
                    ret = this.events[i];
                    break;
                }
            }
            return ret;
        },

        getRecordTypeField : function(){
            return this.__recordTypeField;
        },

        getControllingPicklistFields : function(){
            return this.__controllingPicklistFields;
        },

        getCurrentRecordTypeInfo : function(recordType){
            return this._parent.getCurrentRecordTypeInfo(recordType, this.objectName);
        },

        getObjectName : function(){
            return this.objectName;
        },

        getPrecision : function(field){
            return this._parent.getPrecision(this.objectName, field);
        },

        getScale : function(field){
            return this._parent.getScale(this.objectName, field);
        },

        getFieldLabel : function(field){
            return this._parent.getFieldLabel(this.objectName, field);
        },

        isFieldAccessible : function(field){
            return this._parent.isFieldAccessible(this.objectName, field);
        },

        isFieldRequired : function(field){
            return this._parent.isFieldRequired(this.objectName, field);
        },

        isFieldReadOnly : function(field){
            return this._parent.isFieldReadOnly(this.objectName, field);
        },

        getPicklistValues : function(field){
            return this._parent.getPicklistValues(this.objectName, field);
        },

        getControllingPicklist : function(field){
            return this._parent.getControllingPicklist(this.objectName, field);
        },

        getFieldMetaInfoFromName : function(fieldName){
            return this._parent.getFieldMetaInfoFromName(this.objectName, fieldName);
        },

        createBinding : function(setter, getter, context){
            this.__dataBinding = this.getRoot().getDataModel().createDetailBinding(this._parent.getPath() + "." + this.layoutId, setter, getter, context);
            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        },

        resolveDependencies : function(){
            var fields = this._children["fields"], i, l = fields.length;
            for(i = 0; i < l; i++){
                fields[i].resolveDependencies();
            }
        },

        getFieldInfo : function(fieldName){
            var fields = this._children["fields"], ret = null, i, l = fields.length;
            for(i = 0; i < l; i++){
                if(fields[i].fieldName == fieldName){
                    ret = fields[i];
                    break;
                }
            }
            return ret;
        },

        getControllingFieldInfo : function(fieldName){
            var fieldInfo = this.getFieldInfo(fieldName);
            //for hidden pl fields getFieldInfo will return null hence lookp thru the set of
            //registered controlling pl fields in __controllingPicklistFields[]
            if(!fieldInfo){
                 var i, l = this.__controllingPicklistFields.length;
                 for(i = 0; i < l; i++){
                     if(fieldName == this.__controllingPicklistFields[i].fieldName){
                         fieldInfo = this.__controllingPicklistFields[i];
                         break;
                     }
                 }
            }

            return fieldInfo;
        },

        getFieldInfoFromName : function(fieldName){
            return this.getFieldInfo(fieldName);
        },

        getControllingPicklistFieldDataFromName : function(fieldName){
            return this._parent.getControllingPicklistFieldDataFromName(this.objectName, fieldName);
        },

        getLookupContextFieldInfo : function(fieldName, contextSource){
            var ret = null;
            if(contextSource == "CURRENT_RECORD"){
                // get from the same line level
                ret = this.getFieldInfo(fieldName);
            }else if(contextSource == "PARENT_RECORD"){
                // get from the header record
                ret = this._parent.getParent().getHeaderMetaModel().getLookupContextFieldInfo(fieldName);
            }else{
                ret = this.getFieldInfo(fieldName);
                SVMX.getLoggingService().getLogger("SFMPageDetail").warn("Unknown context source type, defaulting to current record! =>" + contextSource);
            }
            return ret;
        },

        getBindingHash : function() {
            return this.__allColumnDataBindingsHash;
        },

        __addBinding : function(path, binding) {
            this.__allColumnDataBindings[this.__allColumnDataBindings.length] = binding;
            this.__allColumnDataBindingsHash[path] = binding;
        },

        createColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createHiddenColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelHiddenFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createPicklistColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailPicklistFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createMultiPicklistColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailMultiPicklistFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createRecordTypeColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailRecordTypeFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createHiddenPicklistColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailHiddenPicklistFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createReferenceColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailReferenceFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        createDatetimeColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailDatetimeFieldBinding", this, path);
            this.__addBinding(path, ret);
            return ret;
        },

        /*createBooleanColumnBinding : function(path){
            var ret = SVMX.create("com.servicemax.client.sfmdelivery.engine.SFMPageModelDetailBooleanFieldBinding", this, path);
            this.__allColumnDataBindings[this.__allColumnDataBindings.length] = ret;
            return ret;
        },*/

        resetRowBindingContext : function(){
            this.__currentRowContext = null;
            var i , bindings = this.__allColumnDataBindings, l = bindings.length;
            for(i = 0; i < l; i++){
                bindings[i].setContextInternal(null);
            }
        },

        setRowBindingContext : function(context){
            this.__currentRowContext = context;
            var i , bindings = this.__allColumnDataBindings, l = bindings.length;
            for(i = 0; i < l; i++){
                bindings[i].setContextInternal(context);
            }
        },

        setExtendedEditRowBindingContext : function(context) {
            this.__extendedEditData = SVMX.cloneObject(context.raw);
            this.setRowBindingContext(context);
        },

        executeBindings : function(){
            var i , bindings = this.__allColumnDataBindings, l = bindings.length;
            for(i = 0; i < l; i++){
                bindings[i].executeBinding();
            }
        },

        persistBindings : function(){
            // if it is a view transaction then there is no need to persist the binding
            if(this.isDisplayOnly) return;

            // persist bindings of record type so that the picklist resolution happens properly
            this.getRecordTypeField().getDataBinding().persistBinding();

            var i , bindings = this.__allColumnDataBindings, l = bindings.length;
            for(i = 0; i < l; i++){
                bindings[i].persistBinding();
            }
        },

        extendedEditPersistBindings : function() {
            // For data not managed via bindings, we need to update
            // the store with these values
            var unboundData = this.__extendedEditData;
            var store = this.__currentRowContext;
            var boundFieldNames = SVMX.array.map(this.getAllDetailFields(), function(item) {
                return item.fieldDetail[SVMX.OrgNamespace + "__Field_API_Name__c"];
            });
            var fieldTypes = this.getAllObjectFieldTypes();
            SVMX.forEachProperty(unboundData, function(inKey, inValue) {
                if (SVMX.array.indexOf(boundFieldNames, inKey) == -1 && fieldTypes[inKey]) {
                    if (unboundData[inKey + "__key"]) {
                        store.raw[inKey + "__key"] = store.data[inKey + "__key"] = unboundData[inKey + "__key"];
                        store.set(inKey, inValue);
                    } else {
                        store.set(inKey, inValue);
                    }
                }
            });
            this.persistBindings();
        },

        // Phone design only
        validateFields: function() {
            var errors = [];
            SVMX.array.forEach(this.__allColumnDataBindings, function(binding) {
                // If user does not have permission to a field, it will not have a validator.
                // This is to allow sloppy ServiceMax configurations.
                if (binding.__validator) {
                    var result = binding.__validator.handler.call(binding.__validator.context);
                    if (!result.isValid) errors.push(result);
                }
            });
            return errors
        },

        translate : function(fieldName, fieldValue, fieldValueObj){
            var fieldInfo = this.getFieldInfoFromName(fieldName), ret = fieldValue, plValues, i, j,l;
            var translateDatesDisabled = SVMX.getClient().getApplicationParameter("svmx-sfm-disable-translate-dates");

            // translate only for the fields that are modeled.
            if(fieldInfo && fieldInfo.fieldName == CONSTANTS.RECORD_TYPE_ID){
                var rt = this.getCurrentRecordTypeInfo(fieldValue);
                if(rt){
                    ret = rt.name;
                    fieldValueObj.value = ret;
                }
            }else if(fieldInfo && fieldInfo.datatype == 'picklist'){
                plValues = this.getPicklistValues(fieldInfo.getFieldData()), l = plValues.length;
                for(i = 0; i < l; i++){
                    if(plValues[i].value == fieldValue){
                        ret = plValues[i].label;
                        break;
                    }
                }
            }else if(fieldInfo && fieldInfo.datatype == 'multipicklist' && fieldValue){
                fieldValue = fieldValue.split(';');
                ret = "";
                plValues = this.getPicklistValues(fieldInfo.getFieldData()), l = plValues.length;
                var fl = fieldValue.length, translatedPlvalues = [];
                for(j = 0; j < fl; j++){
                    for(i = 0; i < l; i++){
                        if(plValues[i].value == fieldValue[j]){
                             translatedPlvalues.push(plValues[i].label);
                        }
                    }
                }
                ret = translatedPlvalues.join(";");
            }else if(fieldInfo && fieldInfo.datatype == 'date' && fieldValue && !translateDatesDisabled){

                //var format = fieldInfo.getRoot().getUserInfo().DateFormat;
                //ret = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(fieldValue, "YYYY-MM-DD");
                //Changed so data is always parsable, it is now up to the UI layer to change to a displayable format
                //fieldValueObj.key = ret;
                //fieldValueObj.value = ret;
                fieldValueObj.key = fieldValue;
                fieldValueObj.value = fieldValue;
            }else if(fieldInfo && fieldInfo.datatype == 'datetime' && fieldValue && !translateDatesDisabled){
                //var dateFormat = fieldInfo.getRoot().getUserInfo().DateFormat;
                //var timeFormat = fieldInfo.getRoot().getUserInfo().TimeFormat;
                //ret = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(fieldValue, "YYYY-MM-DD[T]HH:mm:ss[Z]");
                //Changed so data is always parsable, it is now up to the UI layer to change to a displayable format
                //fieldValueObj.key = ret;
                //fieldValueObj.value = ret;
                fieldValueObj.key = fieldValue;
                fieldValueObj.value = fieldValue;
            }else if(fieldInfo && (fieldInfo.datatype == 'textarea' || fieldInfo.datatype == 'string') && fieldValue){
                if(ret){
                    // Value should always be a string
                    if(typeof ret !== "string") ret = "" + ret + "";
                    ret = ret.split("<").join("&lt;");
                    ret = ret.split(">").join("&gt;");
                    ret = ret.split('"').join("&quot;");
                }
            }

            return ret;
        },


        executeFieldMappings : function(metaModel, selectedData) {
            var bindingsHash = this.getBindingHash();
            var p = this._parent;
            while (!p.executeFieldMappings) p = p._parent;
            if (p.executeFieldMappings) {
                var allFieldTypes = this.getAllObjectFieldTypes();
                p.executeFieldMappings(metaModel, selectedData, bindingsHash,
                    this.__extendedEditData, allFieldTypes);
            }
        },

        // TODO: engine.js should not know anything about ExtJS stores, nor how to interact with them.
        // TODO: Should take in an sfmdetail that supports getValue and setValue.  And there should not be an executeGridFieldMappings method, only
        // a SINGLE executeFieldMappings method that perhaps should be a method of the FieldMapping class itself.
        executeGridFieldMappings : function(metaModel, inSelectedData, inRecord) {
            if (!inRecord) return;
            var fieldTypes = this.getAllFieldTypes();
            var fieldMapping = this.getRoot().__fieldMappings;
            var data = inRecord.data;

            var dateFormat = this.getRoot().getUserInfo().DateFormat;
            var timeFormat = this.getRoot().getUserInfo().TimeFormat;
            var hrsFormat = com.servicemax.client.lib.datetimeutils.DatetimeUtil.isFormat24HourTime(timeFormat);
            //TODO: Not sure if we need to change for Phone date Value Mapping
            fieldMapping.forEachField(metaModel.fieldMappingId, function(inKey, inValue) {
                var fieldType = fieldTypes[inKey];
                var newvalue;
                if (inValue.value) {
                    newvalue = inValue.value;
                    switch(newvalue) {
                        case "Tomorrow":
                        case "Yesterday":
                        case "Today":
                            newvalue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime(newvalue, "YYYY-MM-DD", "HH:mm:ss");
                            if (fieldType == "datetime") {
                                // Do an extra conversion, so the USER sees this as midnight for the macro on the day, rather than using midnight UTC for that day.
                                newvalue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(newvalue, null, true);
                            }
                            break;
                        case "Now":
                            newvalue = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime(newvalue, "YYYY-MM-DD", "HH:mm:ss");
                            break;
                    }

                    data[inKey + "__key"]  = {key:newvalue, value:newvalue};
                } else if (fieldType === "reference" && inValue.field + "__key" in inSelectedData) {
                    var tmpval = inSelectedData[inValue.field + "__key"];

                    if (!tmpval && inValue.field2) {
                        tmpval = inSelectedData[inValue.field2 + "__key"];
                    }
                    if (!tmpval && inValue.field3) {
                        tmpval = inSelectedData[inValue.field3 + "__key"];
                    }

                    if (tmpval) {
                        data[inKey + "__key"] = {key: tmpval.key, value: tmpval.value};
                        newvalue = data[inKey + "__key"].value;
                    } else {
                        newvalue = tmpval;
                    }

                    newvalue = data[inKey + "__key"].value;
                } else {
                    // Defect 013436: Use the value that is also appropriate for mapping picklists with translations first.
                    newvalue = inSelectedData[inValue.field + "__m"]; // Base value to save
                    if (!newvalue) {
                        newvalue = inSelectedData[inValue.field];
                    }
                    // TODO: Figure out if this should be newvalue == null || newvalue === ""
                    if (!newvalue && inValue.field2) {
                        newvalue = inSelectedData[inValue.field2];
                    }
                    if (!newvalue && inValue.field3) {
                        newvalue = inSelectedData[inValue.field3];
                    }
                    data[inKey + "__key"] = {key:newvalue, value:newvalue}; // our value
                }
                inRecord.set(inKey, newvalue);    // Updates the grid cell
            });

        },

        //for currentRecord and currentRecordHeader
        getRelatedBindingValue : function(fieldName, source, data){
            //delegate to the parent

            var params;
            if(source == "CURRENTRECORD" && this.getFieldInfo(fieldName)){
                var userInfo = this.getFieldInfo(fieldName).getRoot().getUserInfo();

                if(this.getFieldInfo(fieldName).datatype == "datetime"){
                    params = {valueHash : data, isDateTime : true, userInfo : userInfo, isDateOnly : false};
                }else if(this.getFieldInfo(fieldName).datatype == "date"){
                    params = {valueHash : data, isDateOnly : true, userInfo : userInfo};
                }else{
                    params = {valueHash : data, isDateTime : false, isDateOnly : false};
                }

                return this._parent.getRelatedBindingValue(fieldName, source, params)
            }else {
                return this._parent.getRelatedBindingValue(fieldName, source);
            }
        },


        addNew : function(sfmdetail) {
            var deliveryEngine = this.getRoot().getDeliveryEngine();
            var sfmProcessId = deliveryEngine.processId

            this.__logger.info("Performing addNew()");

            //invoke loading mask
            deliveryEngine.blockApplication();

            var currentApp = deliveryEngine.getEventBus(), evt;

            evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "SFMDELIVERY.ADD_RECORDS", this,
                {request : {
                    processId : sfmProcessId,
                    alias : this.layoutId,
                    data : deliveryEngine.getTargetData().getData(),
                    objectName : this.objectName
                },
                 responder :
                    SVMX.create("com.servicemax.client.sfmdelivery.responders.AddRecordsResponder", this, [], sfmdetail)});
            currentApp.triggerEvent(evt);
        },

        // TODO: Take a look at selection and selectedData to verify its nothing Extjs specific; anything Extjs specific should be handled via callback
        addMultipleNew : function(sfmdetail, selection, selectedData) {
            var deliveryEngine = this.getRoot().getDeliveryEngine();
            var sfmProcessId = deliveryEngine.processId
            this.__logger.info("Performing multiAdd()");

            //invoke loading mask
            deliveryEngine.blockApplication();

            var multiAddFieldRecordIds = [], i, l = selection.length, multiAddFieldRecordValues = [];
            for(i = 0; i < l; i++){
                multiAddFieldRecordIds.push(selection[i].key);

                // also push the values. This can be used to create new records from cached add record template
                multiAddFieldRecordValues.push(selection[i].value);
            }

            var currentApp = deliveryEngine.getEventBus(), evt;
            evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "SFMDELIVERY.ADD_RECORDS", this,
                {request : {
                    processId : sfmProcessId,
                    alias : this.layoutId,
                    multiAddFieldApiName : this.multiAddSearchField,
                    multiAddFieldRecordIds : multiAddFieldRecordIds,
                    multiAddFieldRecordValues : multiAddFieldRecordValues,
                    data : deliveryEngine.getTargetData().getData(),
                    objectName : this.objectName
                },
                 responder :
                    SVMX.create("com.servicemax.client.sfmdelivery.responders.AddRecordsResponder", this, selectedData, sfmdetail)});
            currentApp.triggerEvent(evt);
        },

        onAddRecordsComplete : function(data, multiAddData, sfmdetail) {
            var deliveryEngine = this.getRoot().getDeliveryEngine(),
                currentApp = deliveryEngine.getEventBus(),
                evt = null;
            if (multiAddData && multiAddData.length) {
                var p = this;
                while (!p.executeFieldMappings) p = p._parent;
                var fieldInfo = this.getFieldInfo(this.multiAddSearchField);

                // TODO: engine.js should know nothing about ExtJS, and should not be operating upon its store object
                var store = sfmdetail.getStore();
                var storeSize = store.getCount();

                for (var i = 0; i < multiAddData.length; i++) {
                    var item = store.getAt(storeSize - multiAddData.length + i);
                    p.executeGridFieldMappings(fieldInfo, multiAddData[i], item);
                }
            }

            // check if an "After Add Record" event is configured for this detail
            var afterAddRecordEventInfo = this.getEventInfoFor("After Add Record");
            this.__sfmdetail = sfmdetail;
            this.__dataLength = data.length;
            if (SVMX.getClient().getApplicationParameter("svmx-sfm-disable-events")) afterAddRecordEventInfo = null;
            if (afterAddRecordEventInfo) {
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMDELIVERY.INVOKE_EVENTS", this, {
                    request: {
                        events: [afterAddRecordEventInfo],
                        data: deliveryEngine.getTargetData().getData(),
                        metadata: deliveryEngine.getPageMetaData().getRawPageMetaData(),
                        deliveryEngine: deliveryEngine,
                        additionalInfo: {
                            processId: deliveryEngine.processId,
                            nextStepId: this.getRoot().getDeliveryEngine().nextStepId
                        }
                    },
                    responder: SVMX.create("com.servicemax.client.sfmdelivery.responders.InvokeEventsResponder", this)
                });
                currentApp.triggerEvent(evt);
            } else {
                deliveryEngine.unblockApplication();

                // start editing the newly added row. if it is a multi-add, start editing the first newly added row
                sfmdetail.onAddRecordsComplete(data.length, data);
            }
        },

        onInvokeEventsComplete : function(){
            var deliveryEngine = this.getRoot().getDeliveryEngine();

            // unblock the UI
            deliveryEngine.unblockApplication();
            this.__sfmdetail.onAddRecordsComplete(this.__dataLength);
            this.__sfmdetail = null;
            this.__dataLength = null;
        }
    }, {});

    engine.Class("SFMPageDetailLinkedProcess",  com.servicemax.client.lib.api.Object, {
        title : null, processId : null, sequence : null,
        __constructor : function(data){
            this.initialize(data);
        },

        initialize : function(data){
            this.title = data.title;
            this.processId = data.processId;
            this.sequence = data.sequence;
        }
    });

    engine.Class("SFMPageDetailField", engine.SFMPageField, {
        __constructor : function(data, parent){ this.__base(data, parent); },
        destroy: function() {
        SVMX.destroy(this);
        },

        initialize : function(){
            this.__base();
            this.createDetailBinding(this.fieldName);
        },

        // called when performing extended edit
        createBinding : function(setter, getter, context){
            this.__dataBinding.setter = setter;
            this.__dataBinding.getter = getter;
            this.__dataBinding.bindingContext = context;
            return this.__dataBinding;
        },

        createDetailBinding : function(path){
            if(!this.__dataBinding)
                this.__dataBinding = this._parent.createColumnBinding(path);

            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        }
    }, {});

    engine.Class("SFMPageDetailPicklistField", engine.SFMPagePicklistField, {
        __constructor : function(data, parent){ this.__base(data, parent); },
        initialize : function(){
            this.__base();
            this.createDetailBinding(this.fieldName);
        },

        // called when performing extended edit
        createBinding : function(setter, getter, context){
            this.__dataBinding.setter = setter;
            this.__dataBinding.getter = getter;
            this.__dataBinding.bindingContext = context;
            return this.__dataBinding;
        },

        createDetailBinding : function(path){
            if(!this.__dataBinding){
                this.__dataBinding = this._parent.createPicklistColumnBinding(path);
                this.__dataBinding.field = this;
            }

            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        },

        _parentValueChanged : function(evt){
            this.__base(evt);

            // this method is trigger while in extended edit too... do not persist until explicitly forced by persisteBindings

            // in the order of priority, first check if the value can be read from UI, if not, then check
            // in the row context
            var value = null;
            if(this.getDataBinding().getter){
                value = this.getDataBinding().getLocalValue();
                if(value) value = value.value;
            }else{
                value = this.getDataBinding().getValue();
            }

            // this usually happens when using cell editors
            if(evt.data.persistInDataModel){
                var plValues = this.getPicklistValues({value : evt.data.value}), value = plValues[0].value;
                this.getDataBinding().persistBinding({key : value, value : value});
            }

            // notify any dependents
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "CHANGED", this, {value : value, persistInDataModel : evt.data.persistInDataModel,
                    passOnInformation : evt.data.passOnInformation});
            this.triggerEvent(evt);
            // end notify dependents
        },

        _getCurrentRecordTypeInfo : function(params){
            var ret = null;
            if(params && params.passOnInformation && params.passOnInformation.recordType){
                // if some one is passing this information, use it
                ret = this._parent.getCurrentRecordTypeInfo(params.passOnInformation.recordType);
            }else{
                if(this.__dataBinding){
                    var dataContext = this.__dataBinding.getContext();
                    if(dataContext){
                        var rt = dataContext.data[CONSTANTS.RECORD_TYPE_ID + "__key"] || dataContext.data[CONSTANTS.RECORD_TYPE_ID];
                        if(rt){
                            var rtId = null;
                            if(typeof(rt) == 'string'){
                                rtId = rt;
                            }else{
                                rtId = rt.key;
                            }
                            ret = this._parent.getCurrentRecordTypeInfo(rtId);
                        }
                    }
                }
            }

            return ret;
        },

        triggerEvent : function(evt){
            if(!evt.data.passOnInformation){
                // if there is no passOnInformation (on record type), try to create one only if;
                // 01. the data binding is currently assigned with setter and getter. This happens usually during extended edit.
                // 02. there is a record type field modeled. This is the only way a record type can be changed on the UI.
                var rtBinding = this.getRecordTypeField().getDataBinding();
                if(rtBinding && rtBinding.setter){
                    var rtBinding = this.getRecordTypeField().getDataBinding();
                    if(rtBinding){
                        var rt = rtBinding.getLocalValue();
                        if(rt !== undefined){
                            evt.data.passOnInformation = {recordType : rt.key};
                        }
                    }
                }
            }

            this.__base(evt);
        }
    }, {});

    engine.Class("SFMPageDetailMultiPicklistField", engine.SFMPageDetailPicklistField, {
        __constructor : function(data, parent){ this.__base(data, parent); },

        createDetailBinding : function(path){
            if(!this.__dataBinding){
                this.__dataBinding = this._parent.createMultiPicklistColumnBinding(path);
                this.__dataBinding.field = this;
            }

            return this.__dataBinding;
        },

        getPicklistEntryLabelFor : function(value){
            // find the corresponding translation
            var plValues = this.getPicklistValues({}, true), i, j, l = plValues.length, displayValue = "";

            if(value !== undefined && value !== null){
                var mplValue = value.split(';'), len = mplValue.length;

                for(i = 0; i < l; i++){
                    for(j = 0; j < len; j++){
                        if(plValues[i].value == mplValue[j]){
                            displayValue = plValues[i].label  + ";" + displayValue;
                        }
                    }
                }
                //if there is a trailing ';' remove it
                if(displayValue.charAt(displayValue.length -1) == ';'){
                    displayValue = displayValue.substring(0, displayValue.length - 1)
                }
            }
            // end translation

            return displayValue;
        }
    }, {});

    engine.Class("SFMPageDetailRecordTypeField", engine.SFMPageRecordTypeField, {
        __constructor : function(data, parent){ this.__base(data, parent); },
        initialize : function(){
            this.__base();

            if(this._data != null){
                this.createDetailBinding(this.fieldName);
            }
        },

        _initializeHiddenMode : function(){
            this.__dataBinding = this._parent.createHiddenColumnBinding(this.fieldName);
        },

        // called when performing extended edit
        createBinding : function(setter, getter, context){
            this.__dataBinding.setter = setter;
            this.__dataBinding.getter = getter;
            this.__dataBinding.bindingContext = context;
            return this.__dataBinding;
        },

        createDetailBinding : function(path){
            if(!this.__dataBinding){
                this.__dataBinding = this._parent.createRecordTypeColumnBinding(path);
                this.__dataBinding.field = this;
            }

            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        },

        triggerRecordTypeChanged : function(evtData){
            var recordType = evtData.data.value;
            if(recordType === CONSTANTS.NO_VALUE){
                // clear the record type
                recordType = null;
            }

            evtData.data.passOnInformation = {recordType : recordType};
            this.triggerEvent(evtData);
        },

        _getCurrentRecordTypeInfo : function(params){
            // do nothing
            return null;
        }
    }, {});

    engine.Class("SFMPageDetailHiddenPicklistField", engine.SFMPageHiddenPicklistField, {
        __constructor : function(data, parent){ this.__base(data, parent); },
        initialize : function(){
            this.fieldName = this._data.name;
            this.__dataBinding = this._parent.createHiddenPicklistColumnBinding(this.fieldName);

            var plValue = null, me = this;
            this.__dataBinding.setter = function(value){
                // setter
                //the controlling field can also be a checkbox, in such scenario the
                //checkbox is treated like a picklist with true and false being possible values
                //Convert the boolean value to string in such scenario.
                if(typeof(value) == "boolean"){
                    plValue = value.toString();
                }else{
                    plValue = value;
                }

                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                                 "CHANGED", me, {value : plValue});
                me.triggerHiddenPicklistChanged(evt);
            };

            this.__dataBinding.getter = function(){
                // getter
                var ret = plValue;
                if(me._data.dataType =='boolean'
                    && (plValue === undefined || plValue === null || plValue === "")) {
                    ret = !!plValue;
                }

                return ret;
            };
        }
    }, {});

    engine.Class("SFMPageDetailReferenceField", engine.SFMPageReferenceField, {
        contextSource : null,
        __constructor : function(data, parent){ this.__base(data, parent); },
        initialize : function(){
            this.__base();
            this.contextSource = this._data.fieldDetail[SVMX.OrgNamespace + "__Context_Source_Object__c"];
            this.createDetailBinding(this.fieldName);
        },

        // called when performing extended edit
        createBinding : function(setter, getter, context){
            this.__dataBinding.setter = setter;
            this.__dataBinding.getter = getter;
            this.__dataBinding.bindingContext = context;

            return this.__dataBinding;
        },

        createDetailBinding : function(path){
            if(!this.__dataBinding){
                this.__dataBinding  = this._parent.createReferenceColumnBinding(path);
            }

            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        },

        resolveDependencies : function(){
            if(this.lookupContext){
                this.lookupContextFieldInfo = this._parent.getLookupContextFieldInfo(this.lookupContext, this.contextSource);
            }
        }

    }, {});

    engine.Class("SFMPageDetailDatetimeField", engine.SFMPageField, {
        contextSource : null,
        __constructor : function(data, parent){ this.__base(data, parent); },

        initialize : function(){
            this.__base();
            this.createDetailBinding(this.fieldName);
        },

        // called when performing extended edit
        createBinding : function(setter, getter, context){
            this.__dataBinding.setter = setter;
            this.__dataBinding.getter = getter;
            this.__dataBinding.bindingContext = context;

            return this.__dataBinding;
        },

        createDetailBinding : function(path){
            if(!this.__dataBinding){
                this.__dataBinding  = this._parent.createDatetimeColumnBinding(path);
            }

            return this.__dataBinding;
        },

        getDataBinding : function(){
            return this.__dataBinding;
        }

    }, {});


    ////////////////////////// START - SPECIAL DATA BINDING CLASSES FOR LIST ////////////////////////////////
    /**
     * These are dummy classes which are required to satisfy certain data binding contracts with the rest of
     * application. For example, SFMLookupModel. Also, they are not true model binding since data is bound
     * at the detail list level and not at the individual column level. Hence are they are managed separately
     * by the fields themselves and not are not part of the global binding chain.
     */
    engine.Class("SFMPageModelDetailFieldBinding", com.servicemax.client.lib.api.Object, {
        _path : null, _parent : null, _context : null, setter : null, getter : null, bindingContext : null,
        __constructor : function(parent, path){
            this._path = path;
            this._parent = parent;
        },

        getValue : function(){
            var value = null;
            if (this.bindingContext != null && this.getter != null) {
              value = this.getter.call(this.bindingContext);
            }
            else {
               // Inline editing need use this to find lookup context value.
               value = this.getValueFromContext();
            }
            return value;
        },

        getValueFromContext : function(){
            var value = null;
            if(this._context){
                value = this._context.data[this._path];
                if(this._context.data[this._path + "__key"]){
                    value = this._context.data[this._path + "__key"];
                }

                if(value && typeof(value) == 'object'){
                    if(value.hasOwnProperty('value') && value.hasOwnProperty('key')) {
                        value = value.value;
                    }
                    else {
                        function getValueOfKey(property) {
                            var returnValue = null;
                            if(property && typeof(property) === 'object'){
                                if(property.hasOwnProperty('value') && property.hasOwnProperty('key')) {
                                    returnValue = property.value;
                                }
                                else {
                                    for(var eachProperty in property) {
                                        returnValue = getValueOfKey(property[eachProperty]);
                                        if(returnValue) break;
                                    }
                                }
                            }
                            return returnValue;
                        }

                        for(var eachProperty in value) {
                            var returnValue = getValueOfKey(value[eachProperty]);
                            if(returnValue) { 
                                value = returnValue;
                                break;
                            }
                        }
                    }
                }
            }

            return value;
        },

        setValue : function(value, params){
            if (this.setter) this.setter.call(this.bindingContext, value, params);
        },

        setValidator : function(callback){
            this.__validator = callback; // used by phone design
        },

        setBizRuleValidator : function() {
            //Dummy implementation. Used only checklist only. Added dummy method as extended edit/detail view uses it
        },

        setResolver : function(resolver){
            //TODO
        },

        setContext : function(context){
            this._parent.setRowBindingContext(context);
        },

        resetContext : function(){
            this._parent.resetRowBindingContext();
        },

        setContextInternal : function(context){
            this._context = context;
            if(!context){
                this.setter = null;
                this.getter = null;
                this.bindingContext = null;
            }
        },

        executeBinding : function(){
            var value = this.getValueFromContext();
            //TODO : if must be removed
            if(this.setter){
                this.setter.call(this.bindingContext, value);
            }
        },

        getLocalValue : function(){
            return this.getter.call(this.bindingContext);
        },

        persistBinding : function(){
            // Extended edit dialog fields where isAccessable returns false will not have a getter.
            if (this.getter) {
                var value = this.getter.call(this.bindingContext);

                if(typeof(value) == 'object' && value != null && value != undefined){
                    this._context.data[this._path + "__key"] = value;
                    this._context.set(this._path, value.value);
                }else{

                    // prepare the display value accordingly
                    var compositionMetamodel = this.bindingContext.getCompositionMetamodel ?
                        this.bindingContext.getCompositionMetamodel() : this.bindingContext.compositionMetamodel;
                    var displayValue = com.servicemax.client.sfmdelivery.utils.SFMUtils
                        .prepareDataForDisplay(value, compositionMetamodel.datatype);

                    this._context.data[this._path + "__key"] = {key :value , value : value};
                    this._context.set(this._path, displayValue);
                }
            }
        },

        getContext : function(){
            return this._context;
        },

        //for currentRecord and currentRecordHeader
        getRelatedBindingValue : function(fieldName, source){
            //delegate to the parent
            var data = null;
            var returnValue = null;
            var rawValue = null;
            var context = this.getContext();
            if(context){
                data = SVMX.cloneObject(this.getContext().data);
                if (source == "CURRENTRECORD") {
                     var binding =  this._parent.__allColumnDataBindingsHash[fieldName];
                     if (binding && binding.getter) {
                         data[fieldName + "__key"] = binding.getter.call(binding.bindingContext);
                         data[fieldName] = data[fieldName] && typeof data[fieldName] == "object" ? data[fieldName].key : data[fieldName];
                     }
                }
            }

            // Defect 024327.
            // When CURRENTRECORD*.dateField was blank, need to pass correct value to SAL.
            // Offline needs x='', Online needs x=null
            // By fixing PlatformSpecifics to return the correct value for blank dates we did not
            // want to loose that data at this point
            var relatedBindingValue = this._parent.getRelatedBindingValue(fieldName, source, data);
            //var rawValue = context && context.raw[fieldName];
            if(this.getContext()) {
                rawValue = this.getContext().raw[fieldName];
            }
            returnValue = relatedBindingValue;

            if (!relatedBindingValue && rawValue) {
                returnValue = rawValue;
            }

            return returnValue;
        }
    }, {});

    engine.Class("SFMPageModelHiddenFieldBinding", engine.SFMPageModelDetailFieldBinding, {
        __constructor : function(parent, path){
            this.__base(parent, path);
            this.setValidator({context: this, handler: function(){ return {isValid: true};}});
        },

        persistBinding : function(){ },
        executeBinding : function(){ },
        setValue : function(value){ },
        getValue : {},
        getLocalValue : function(){
            /**
             * !!! DO NOT RETURN ANYTHING FROM HERE. AN 'UNDEFINED' VALUE INDICATES THAT THIS IS A HIDDEN BINDING !!!
             */
        }
    }, {});

    engine.Class("SFMPageModelDetailPicklistFieldBinding", engine.SFMPageModelDetailFieldBinding, {
        field : null,
        __constructor : function(parent, path){
            this.__base(parent, path);
        },

        getValue : function(){
            var value = this.__base();
            return value;
        },

        executeBinding : function(){
            var value = this.getValueFromContext();
            //TODO : if must be removed
            if(this.setter){

                // Defect: 12020 Allow invalid mappings that are set programatically but not by user
                if (this.bindingContext) this.bindingContext.forceSelection = false;
                this.setter.call(this.bindingContext, value);
                if (this.bindingContext) this.bindingContext.forceSelection = true;
            }
        },

        persistBinding : function(value){
            // a value will be passed, for example, when triggering a dependent picklist chain
            if(value === undefined)
                value = this.getter.call(this.bindingContext);
            if (value === undefined || (this.field === undefined || this.field == null)) {
                // Defect 018772: Undefined value comes from hidden field, do not update context.
                // Defect 019318: We do not want to persist this field since it was hidden
                return;
            }

            var displayValue = "";

            if(value && value.value){
                displayValue = this.field.getPicklistEntryLabelFor(value.value);
            }

            this._context.data[this._path + "__key"] = value;
            this._context.set(this._path, displayValue);
        }
    }, {});

    engine.Class("SFMPageModelDetailMultiPicklistFieldBinding", engine.SFMPageModelDetailPicklistFieldBinding, {
        field : null,
        __constructor : function(parent, path){
            this.__base(parent, path);
        },

        persistBinding : function(value){
            // a value will be passed, for example, when triggering a dependent picklist chain
            if(value === undefined)
                value = this.getter.call(this.bindingContext);
            if (value === undefined || (this.field === undefined || this.field == null)) {
                // Defect 018772: Undefined value comes from hidden field, do not update context.
                // Defect 019318: We do not want to persist this field since it was hidden
                return;
            }

            // Defect 018773: For multi pick list, fieldValue, not the labels are stored in the record.
            //  This has been done for Single PickList, hence override the persistBinding.
            var fieldValue = "";

            if(value && value.value){
                fieldValue = value.value;
            }

            this._context.data[this._path + "__key"] = value;
            this._context.set(this._path, fieldValue);
        }
    }, {});

    engine.Class("SFMPageModelDetailRecordTypeFieldBinding", engine.SFMPageModelDetailPicklistFieldBinding, {
        field : null,
        __constructor : function(parent, path){
            this.__base(parent, path);
        },

        getValueFromContext : function(){
            var value = null;
            if(this._context){
                value = this._context.data[this._path];
                if(this._context.data[this._path + "__key"]){
                    value = this._context.data[this._path + "__key"];
                }

                if(value && typeof(value) == 'object'){
                    value = value.key;
                }
            }

            return value;
        },

        persistBinding : function(value){
            if(value === undefined)
                value = this.getter.call(this.bindingContext);

            if(value){
                this._context.data[this._path + "__key"] = value;
                this._context.set(this._path, value.value);
            }
        }
    }, {});

    engine.Class("SFMPageModelDetailHiddenPicklistFieldBinding", engine.SFMPageModelDetailPicklistFieldBinding, {
        field : null,
        __constructor : function(parent, path){
            this.__base(parent, path);
            this.setValidator({context: this, handler: function(){ return {isValid: true};}});
        },

        getValueFromContext : function(){
            var value = null;
            if(this._context && this._context.data && this._context.data[this._path] !== undefined){
                value = this._context.data[this._path];
            } else if (this._context && this._context.raw && this._context.raw[this._path] !== undefined) {
                // Defect 019318
                // We need to be able to get non-displayed values for dependent picklists etc..
                value = this._context.raw[this._path];
            }

            return value;
        },

        setContextInternal : function(context){
            this._context = context;
            if(!context){
                this.bindingContext = null;
            }
        }

    }, {});

    engine.Class("SFMPageModelDetailReferenceFieldBinding", engine.SFMPageModelDetailFieldBinding, {
        __constructor : function(parent, path){
            this.__base(parent, path);
        },

        getValueFromContext : function(){
            if(this._context){
                return SVMX.cloneObject(this._context.data[this._path + "__key"]);
            }else{
                return null;
            }
        },

        executeBinding : function(){
            var value = this.getValueFromContext();
            this.setter.call(this.bindingContext, value);
        },

        persistBinding : function(){
            var value = this.getter.call(this.bindingContext);
            this._context.data[this._path + "__key"] = value;
            this._context.set(this._path, value.value);
        }
    }, {});

    engine.Class("SFMPageModelDetailDatetimeFieldBinding", engine.SFMPageModelDetailFieldBinding, {
        __constructor : function(parent, path){
            this.__base(parent, path);
        },

        persistBinding : function(){
            var value = this.getter.call(this.bindingContext);
            this._context.data[this._path + "__key"] = {key :value , value : value}
            this._context.set(this._path, value);
        }
    }, {});
    ////////////////////////////////////////////// END - SPECIAL BINDING /////////////////////////////////////////
};
})();

///////////////////////////////////////////// END - METAMODEL ///////////////////////////////////////////////////

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfmdeliveryImpl = SVMX.Package("com.servicemax.client.sfmdelivery.impl");

	sfmdeliveryImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize : function(){
			// this is the place to
			// 01. Initialize the packages which depend on APIs from other modules
			com.servicemax.client.sfmdelivery.constants.init();
			com.servicemax.client.sfmdelivery.responders.init();
			//Below are requires to load before initialize for the sfmdelivery.ui.** modules
			com.servicemax.client.sfmdelivery.utils.init();
			com.servicemax.client.sfmdelivery.operationutils.init();
		},

		initialize : function(){

			//TODO: Not so good to initialize sub packages here.
			// Need to figure out a way to chain initializations
			com.servicemax.client.sfmdelivery.commands.init();
			com.servicemax.client.sfmdelivery.engine.init();
			//com.servicemax.client.sfmdelivery.slaclock.init();
			//com.servicemax.client.sfmdelivery.attachments.init();
		},

		afterInitialize : function(){

			var serv = SVMX.getClient().getServiceRegistry()
								.getService("com.servicemax.client.preferences").getInstance();
			serv.addPreferenceKey("SFMD-EXT-TEXT-AREA");
			serv.addPreferenceKey("SFMD-EXT-EDIT");
			serv.addPreferenceKey("SFMD-LUP-WINDOW");
		}

	}, {});

	sfmdeliveryImpl.Class("SFMUIElementsCreationHelper", com.servicemax.client.lib.api.Object, {
		__constructor : function(){},

		doCreate : function(className, config){
			var obj = Ext.create(className, config);
			obj.__self = Ext.ClassManager.getClass(obj);
			return obj;
		}
	}, {});

	sfmdeliveryImpl.Class("SFMDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__de : null,
		__constructor : function(de){
			this.__base();
			this.__de = de;
		},

		triggerEvent : function(e) {
			SVMX.getLoggingService().getLogger("SFMDeliveryEngineEventBus").info("Trigger event : " + e.type);
			return this.__base(e);
		},

		getDeliveryEngine : function(){
			return this.__de;
		}

	}, {});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\operationutils.js
/**
 * Utilities used by sfmdeliveryoperations.js where online and offline versions of these methods
 * are shared.
 * @class com.servicemax.client.sfmdelivery.operationutils
 * @author Michael Kantor, etc...
 * @since       : The minimum version where this file is supported
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){
    var utils = SVMX.Package("com.servicemax.client.sfmdelivery.operationutils");

utils.init = function(){
    var CONSTANTS = com.servicemax.client.sfmdelivery.constants.Constants;


    utils.Class("Utilities", com.servicemax.client.lib.api.Object, {}, {
        /*
         * @param {Object} request
         * @param {AddRecordsResponder} responder
         * @param {Object} data
         * @param {Object} objectInfo
         * @param {String} cacheKey. If falseish, no caching.
         * @param {AddRecords} operation Operation instance
         */
        addRecords_processData : function(inParams){

                // add record template to cache
                if(inParams.cacheKey){
                    var module = inParams.request.additionalInfo.module.instance;
                    module.setItemToCache(inParams.cacheKey, inParams.data);
                    SVMX.getLoggingService().getLogger("SFM-SAL-MODEL-AddRecords")
                            .info("Adding record template for <" + inParams.request.alias + "> to cache");
                }
                // end cache

                // update the boolean types. they can have "undefined" values
                function getFieldFromTemplate(template, fieldName){
                    var fields = template[0].bubbleInfo, i, l = fields.length, field, ret = null;
                    for(i = 0; i < l; i++){
                        field = fields[i];
                        if(field.fieldapiname == fieldName){
                            ret = field;
                            break;
                        }
                    }
                    return ret;
                }

                var i, field, fields = inParams.objectInfo.fields, l = fields.length;

                for(i = 0; i < l; i++){
                    field = fields[i];
                    if(field.dataType == 'boolean'){
                        var fldObj = getFieldFromTemplate(inParams.data, field.name);
                        if(!fldObj){
                            // insert
                            inParams.data[0].bubbleInfo[inParams.data[0].bubbleInfo.length] = {
                                fieldapiname : field.name,
                                fieldvalue : {key : "false", value : "false"}
                            };
                        }
                    }
                    
                }
                // end update boolean

                // if this is a multi add request
                inParams.data = this.addRecord_doMultiAdd(inParams.request, inParams.data, inParams.optionalNewIds);
                // end multi add request

        inParams.request.data.addNewDetailRecords(inParams.data, inParams.request.alias, function() {
        inParams.onSuccess(inParams.data);
        SVMX.destroy(inParams); // Something about this callback keeps it from being garbage collected; and all of the data contained by inParams along with it
        });
        },

        addRecord_doMultiAdd : function(request, template, optionalNewIds){
            var ret = template;

            if(request.multiAddFieldRecordIds && request.multiAddFieldRecordIds.length > 0){
                var multiAddFieldRecordIds = request.multiAddFieldRecordIds, recArray = [],
                    multiAddFieldRecordValues = request.multiAddFieldRecordValues, i, l = multiAddFieldRecordIds.length,
                    multiAddFieldApiName = request.multiAddFieldApiName;

                for(i = 0; i < l; i++){
                    recArray[i] = this.addRecord_mergeFieldToRecordTemplate(SVMX.cloneObject(template[0]),
                        {apiName : multiAddFieldApiName, key : multiAddFieldRecordIds[i], value : multiAddFieldRecordValues[i]});

                    if (optionalNewIds) {
                        recArray[i].sobjectinfo.Id = optionalNewIds[i];
                    }
                }

                ret = recArray;
            }

            return ret;
        },

        addRecord_mergeFieldToRecordTemplate : function(template, fieldInfo){
            var fields = template.bubbleInfo, i, l = fields.length, field, targetField = null;
            for(i = 0; i < l; i++){
                field = fields[i];
                if(field.fieldapiname == fieldInfo.apiName){
                    targetField = field;
                    break;
                }
            }

            if(!targetField){
                // target field not found in the template! should not happen
                targetField = {fieldapiname : fieldInfo.apiName, fieldvalue : {}};
                fields[fields.length] = targetField;
            }

            targetField.fieldvalue = {key : fieldInfo.key, value : fieldInfo.value};
            return template;
        },

        replaceLiteralsWithValue : function(criteria, refMetaModel, key, addQuotes){
            //TODO : Non-performant, check for better solns
            var pfc = criteria;
            if(pfc != null && pfc != undefined && pfc != ""){
                var constant = "[SVMX.CURRENTRECORD.", constant1 = "[SVMX.CURRENTRECORDHEADER.";

                //avoiding multiple quotes for offline
                if(pfc.indexOf("'"+constant) > 0 || pfc.indexOf("'"+ constant1) > 0){
                    addQuotes = false;
                }

                for(var i = 0; i < pfc.length; i++){
                    var index = pfc.indexOf(constant), fieldName;
                    if(index > -1){
                        pfc = pfc.replace(constant, "*");
                        var ind = pfc.indexOf("*"), con = "]", ind1 = pfc.indexOf(con, ind);
                        if(ind > -1){
                            fieldName = pfc.substring(ind, ind1);
                            fieldName1 = fieldName.replace("*", "");
                            fieldName = fieldName + con;

                            var actualValue = refMetaModel.getDataBinding().getRelatedBindingValue(fieldName1, "CURRENTRECORD");
                            actualValue = (actualValue === CONSTANTS.NO_VALUE || null) ? '' : actualValue;

                            //adding quotes to work offline
                            if(addQuotes) {
                                actualValue = "'" + actualValue + "'";
                            }

                            pfc = pfc.replace(fieldName, actualValue);
                        }
                    }
                }

                for(var i = 0; i < pfc.length; i++){
                    var index = pfc.indexOf(constant1), fieldName;
                    if(index > -1){
                        pfc = pfc.replace(constant1, "*");
                        var ind = pfc.indexOf("*"), con = "]", ind1 = pfc.indexOf(con, ind);
                        if(ind > -1){
                            fieldName = pfc.substring(ind, ind1);
                            fieldName1 = fieldName.replace("*", "");
                            fieldName = fieldName + con;

                            var actualValue = refMetaModel.getDataBinding().getRelatedBindingValue(fieldName1, "CURRENTRECORDHEADER");
                            actualValue = (actualValue === CONSTANTS.NO_VALUE || null) ? '' : actualValue;

                            //adding quotes to work offline
                            if(addQuotes) {
                                actualValue = "'" + actualValue + "'";
                            }
                            pfc = pfc.replace(fieldName, actualValue);
                        }
                    }
                }
            }


            return pfc;
        },

        replaceBoolToString : function(string){
            //TODO : Non-performant, check for better solns

            var trueIndex = string.indexOf('=true');
            if(trueIndex > -1){
                string = string.replace(/=true/g, '=\'true\'');
            }

            var falseIndex = string.indexOf('=false');
            if(falseIndex > -1){
                string = string.replace(/=false/g, '=\'false\'');
            }

            return string;
        },

        extractDefWithFiltersToQuery : function(request, lookupDef){
            var j, k, m, n, len = lookupDef.advFilters.length, filtersToQuery = request.filtersToQuery, found = false, indexes = [];
            if(filtersToQuery != undefined){
                for(j = 0; j < len; j++){
                    found = false;
                    for(k = 0; k < filtersToQuery.length; k++){
                        if(lookupDef.advFilters[j].key == filtersToQuery[k]){
                            found = true;

                            var constant = "SVMX.USERTRUNK", userTrunk = request.userTrunk;

                            if(lookupDef.advFilters[j].filterCriteria.indexOf(constant) > -1){
                                lookupDef.advFilters[j].filterCriteria = lookupDef.advFilters[j].filterCriteria.replace(constant, userTrunk);
                            }
                        }
                    }
                    if(!found){
                        indexes.push(j);
                    }
                }
            }else{
                for(j = 0; j < len; j++){
                    if(lookupDef.advFilters[j].defaultOn == true || lookupDef.advFilters[j].defaultOn == "true"){
                        found = true;
                        var constant = "SVMX.USERTRUNK", userTrunk = request.userTrunk;

                        if(lookupDef.advFilters[j].filterCriteria.indexOf(constant) > -1){
                            lookupDef.advFilters[j].filterCriteria = lookupDef.advFilters[j].filterCriteria.replace(constant, userTrunk);
                        }
                    }else{
                        found = false;
                    }

                    if(!found){
                        indexes.push(j);
                    }
                }
            }

            //delete the advfilters that do not match the ID
            for(m = 0; m < indexes.length; m++ ){
                delete lookupDef.advFilters[indexes[m]];
            }

            //delete leaves empty spaces in array, chk and assign it back the the lookupDef.advfilters array
            var tempArray = [];
            for(n = 0; n < len; n++){
                if(lookupDef.advFilters[n]){
                    tempArray.push(lookupDef.advFilters[n]);
                }
            }

            lookupDef.advFilters = tempArray;

            return lookupDef;
        },

        processDescribeResult : function (describeResult, describeLayoutResult){
            // process record types
            describeResult.recordTypeMapping = [];
            if(describeLayoutResult){
                // single objects are not converted to array while un-marshalling
                if(!(describeLayoutResult.recordTypeMappings instanceof Array)) {
                    describeLayoutResult.recordTypeMappings = [describeLayoutResult.recordTypeMappings];
                }

                var rtmappings = describeLayoutResult.recordTypeMappings, i, l = rtmappings.length, rtm,
                    picklistsForRecordType;
                for(i = 0; i < l; i++) {
                    rtm = rtmappings[i];
                    picklistsForRecordType = rtm.picklistsForRecordType;

                    if(!picklistsForRecordType) {
                        picklistsForRecordType = [];
                    }

                    // single objects are not converted to array while un-marshalling
                    if(!(picklistsForRecordType instanceof Array)) {
                        picklistsForRecordType = [picklistsForRecordType];
                    }

                    rtm.picklistsForRecordType = processPicklistsForRecordType(picklistsForRecordType, describeResult);
                    describeResult.recordTypeMapping.push(rtm);
                }
            }
            // end record types

            // process dependent fields
            var i, fields = describeResult.fields, l = fields.length, field, cname, cfield;
            for(i = 0; i < l; i++){
                field = fields[i];
                if(field.dependentPicklist){
                    cname = field.controllerName;
                    cfield = getField(cname, describeResult);
                    if(cfield){
                        updateControllingPicklistWithDependents(cfield, field);
                    }
                }
            }
            // end process dependent fields

            function updateControllingPicklistWithDependents(cfield, dfield){
                var cvalues = cfield.picklistValues, i, l = cvalues.length, validForBytes,
                    j, dvalues = dfield.picklistValues, c = dvalues.length, isValid,
                    dependentPicklistArray, dependentPicklistInfo, k, s;

                for(i = 0; i < l; i++){

                    if(!cvalues[i].dependendPicklist){ cvalues[i].dependendPicklist = []; }

                    dependentPicklistArray = cvalues[i].dependendPicklist;

                    for(j = 0; j < c; j++){
                        validForBytes = dvalues[j].validFor; isValid = checkIfBytesAreValid(validForBytes, i);

                        if(isValid){
                            dependentPicklistInfo = null; s = dependentPicklistArray.length;
                            for(k = 0; k < s; k++){
                                if(dependentPicklistArray[k].fieldAPIName == dfield.name){
                                    dependentPicklistInfo = dependentPicklistArray[k];
                                    break;
                                }
                            }

                            if(!dependentPicklistInfo){
                                dependentPicklistInfo = {fieldAPIName : dfield.name, value : ""};
                                dependentPicklistArray.push(dependentPicklistInfo);
                            }

                            dependentPicklistInfo.value += j + ";";
                        }
                    }

                    // before proceeding with the next value, cleanup the trailing semi-colon
                    for(j = 0; j < dependentPicklistArray.length; j++){
                        var finalValue = dependentPicklistArray[j].value;
                        if(finalValue.length > 0){
                            if(SVMX.stringEndsWith(finalValue, ";")){
                                finalValue = finalValue.substring(0, finalValue.length - 1);
                            }
                            dependentPicklistArray[j].value = finalValue;
                        }
                    }
                }
            }

            /**
             *  Overcome issues with SFDC SOAP API Issues and Bugs
             * @param inputBytes
             * @param parentIndex
             * @returns {boolean}
             */
            function checkIfBytesAreValid(inputBytes, parentIndex){

                var bitsCount = inputBytes.length * 6, bitValuesArray = [], i, bitIndexInByte, bteIndex, b, biteValue;
                var base64IndexTable = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

                for (i = 0; i < bitsCount; i++) {

                    // the byte to pull the bit from
                    var remindValue = i % 6;
                    var quoValue = (i - remindValue) / 6;

                    if(quoValue < 0){
                        bteIndex = Math.ceil(quoValue);
                    }else {bteIndex = Math.floor(quoValue)};

                    bitIndexInByte = 5 - (i % 6);

                    b = inputBytes[bteIndex], biteValue = base64IndexTable.indexOf(b);
                    bitValuesArray.push( ((biteValue >> bitIndexInByte) & 1) );
                }

                return bitValuesArray[parentIndex] == 1;
            }

            function processPicklistsForRecordType(picklistsForRecordType, describeResult){
                var i, l = picklistsForRecordType.length, picklistForRecordType,
                    j, c, index, value;

                for(i = 0; i < l; i++){
                    picklistForRecordType = picklistsForRecordType[i];
                    var picklistName = picklistForRecordType.picklistName;
                    var picklistValues = picklistForRecordType.picklistValues;

                    // single objects are not converted to array while un-marshalling
                    if(!(picklistValues instanceof Array)) {
                    if (picklistValues === undefined) {
                        picklistValues = [];
                    } else {
                        picklistValues = [picklistValues];
                    }
                    }
                    c = picklistValues.length; value = "";
                    for(j = 0; j < c; j++){
                        value += getPicklistValueIndex(picklistName, picklistValues[j].value, describeResult) + ";";
                    }

                    if(value.length > 0){
                        value = value.substring(0, value.length - 1);
                    }

                    picklistForRecordType.picklistValues = [{value : value}];
                }

                return picklistsForRecordType;
            }

            function getPicklistValueIndex(name, value, describeResult){
                var field = getField(name, describeResult), ret = 0, plValues, i, l;

                if(field){
                    plValues = field.picklistValues; l = plValues.length;
                    for(i = 0; i < l; i++){
                        if(plValues[i].value == value){
                            ret = i;
                            break;
                        }
                    }
                }

                return ret;
            }

            function getField(name, describeResult){
                var ret = null, fields = describeResult.fields, i, l = fields.length;
                for(i = 0; i < l; i++){
                    if(fields[i].name == name){
                        ret = fields[i];
                        break;
                    }
                }
                return ret;
            }
        }
    });

    utils.Class("SFMTargetRecord", com.servicemax.client.lib.api.Object, {
        __data : null, __metadata : null, __additionalInfo : null,
        __constructor : function(data, metadata, additionalInfo){
            this.__data = data;
            this.__metadata = metadata;
            this.__additionalInfo = additionalInfo;
        },

        getParentObjectName : function(){
            return this.__metadata.page.header.headerLayout[SVMX.OrgNamespace + "__Object_Name__c"];
        },

        getHeaderLayoutId : function(){
            return this.__metadata.page.header.hdrLayoutId;
        },

        getProcessType : function(){
            return this.__metadata.response.sfmProcessType;
        },


        getHeaderRecords : function(){
            var ret = [], data = this.__data.getRawData().sfmData,arrayOfRecords = [];
            var ptype = this.getProcessType();
            if(ptype == "CHECKLIST" && data){
              var status = data[SVMX.OrgNamespace +'__Status__c'];
              //not started status
              if((!data.hasOwnProperty("Id") || data.Id==undefined) && data.hasOwnProperty([SVMX.OrgNamespace +'__ChecklistMetaJSON__c'])) {
                  var sizeOfMetaJson = 120000;
                  var metaJson = data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                  var groupId = new Date().getTime();
                  var sequenceForRowIndex = 1;
                  if(metaJson.length>sizeOfMetaJson) {
                        var checkListMetaJsonChunks = SVMX.splitLongStringToChunkArray(metaJson,sizeOfMetaJson);
                        for(var metaJsonChunkIndex = 0; metaJsonChunkIndex < checkListMetaJsonChunks.length; metaJsonChunkIndex++)
                        {
                             var clonedChecklistRecord = SVMX.cloneObject(data);
                             clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'] = checkListMetaJsonChunks[metaJsonChunkIndex];
                             if(metaJsonChunkIndex>0){
                                 delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistJSON__c'];
                             }
                             clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Sequence__c'] = sequenceForRowIndex;
                             clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'] = groupId;

                             arrayOfRecords.push(clonedChecklistRecord);
                             sequenceForRowIndex++;
                        }
                    } 
                    else {
                         data[SVMX.OrgNamespace +'__SM_Sequence__c'] = sequenceForRowIndex;
                         data[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'] = groupId;
                    }
                }//Completed status
                else if(data.hasOwnProperty("Id") && this.__additionalInfo && this.__additionalInfo.hasOwnProperty("lstSobjectinfo") && data[SVMX.OrgNamespace +'__Status__c']=="Completed") {
                      var checklistRelatedRecord = this.__additionalInfo["lstSobjectinfo"];
                      if(checklistRelatedRecord.length>0) {
                        delete data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                        arrayOfRecords.push(data);
                      }
                      for (var index =1 ;index<checklistRelatedRecord.length;index++) {
                            var checkListRecord = checklistRelatedRecord[index];
                            var clonedChecklistRecord = SVMX.cloneObject(data);
                            delete clonedChecklistRecord["Id"];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__ChecklistJSON__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Sequence__c'];
                            delete clonedChecklistRecord[SVMX.OrgNamespace +'__SM_Checklist_Group_Id__c'];
                            clonedChecklistRecord["Id"] = checkListRecord["Id"];
                            clonedChecklistRecord["Name"] = checkListRecord["Name"];
                            arrayOfRecords.push(clonedChecklistRecord);
                      }
                }//In Process status or completed status with single record
                else {
                        delete data[SVMX.OrgNamespace +'__ChecklistMetaJSON__c'];
                }
            }

            if(arrayOfRecords.length==0) {
              arrayOfRecords.push(data);
            }

            SVMX.array.forEach(arrayOfRecords, function(data) {
              var record = { targetRecordAsKeyValue : [] }, keyValue = null;
              ret.push(record);
              SVMX.forEachProperty(data, function(inKey, inValue) {
                    if (inKey == "attributes" || inKey.indexOf("_") === 0 || typeof inValue === "function" || inValue && typeof inValue == "object" && !("fieldvalue" in inValue)) return;

                    if(inKey == 'sourceRecordID') return;

                    var item = data[inKey];
                    keyValue = null;
                    if(typeof(item) == 'object' && item !== undefined && item !== null){
                        keyValue = {key : inKey, value : item.fieldvalue.key, value1 : item.fieldvalue.value};
                    }else{
                        // special fields which are undefined or empty string MUST not be sent
                        // Defect Fix : 026449 (record type either undefined / empty string should be skipped)
                        if(!(inKey == "RecordTypeId" && (item === undefined || !(item)))){
                                keyValue = {key : inKey, value : item};
                        }
                    }

                    if(keyValue){
                          record.targetRecordAsKeyValue[record.targetRecordAsKeyValue.length] = keyValue;
                    }
                });
            });

            return ret;
        },

        getDetailRecords : function(){
            var ret = [], details = this.__data.getRawData().sfmData.details, detailRecords = null, detailId = null;

            for(detailId in details){
                ret[ret.length] = {}; // set up the details array
            }

            for(detailId in details){
                    var detailMetaData = this.getDetailMetadata(detailId), keyValue = null, detailRecordId = null, detailSourceRecordId = null,
                        detailLines = details[detailId].lines, i, l = detailLines.length, line = null, record = null;

                    detailRecords = {};
                    detailRecords.aliasName = detailMetaData.dtlLayoutId;
                    detailRecords.pageLayoutId = detailMetaData.dtlLayoutId;
                    detailRecords.objName = detailMetaData.DetailLayout[SVMX.OrgNamespace + "__Object_Name__c"];
                    detailRecords.parentColumnName = this.getDetailParentColumnName(detailMetaData);
                    detailRecords.records = [];
                    detailRecords.deleteRecID = this.getDetailDeletedRecords(detailId);

                    // preserve the order!!
                    ret[detailMetaData.DetailLayout[SVMX.OrgNamespace + "__Sequence__c"] - 1] = detailRecords;

                    for(var i = 0; i < l; i++){
                        line = detailLines[i], record = {};

                        detailRecordId = line.Id;
                        if(detailRecordId)
                            record.targetRecordId = detailRecordId;

                        detailSourceRecordId = line.sourceRecordID;
                        if(detailSourceRecordId){
                            record.sourceRecordId = detailSourceRecordId;
                        }

                        record.targetRecordAsKeyValue = [];

                        var from__Key = false;
                        for(var key in line){

                            from__Key = false;

                            // don't process __key and sourceRecordID explicitly; nor private properties
                            if(key == "attributes" || key == 'sourceRecordID' || key.indexOf("_") === 0 || key.indexOf("__key", key.length - "__key".length) !== -1) continue;

                            var item = line[key];

                            // check if there is an __key for this item
                            if(line[key + "__key"]){
                                item = line[key + "__key"];
                                from__Key = true;
                            }

                            keyValue = null;
                            if(typeof(item) == 'object' && item !== undefined && item !== null){
                                if(from__Key){
                                    keyValue = {key : key, value : item.key, value1 : item.value};
                                }else{
                                    keyValue = {key : key, value : item.fieldvalue.key, value1 : item.fieldvalue.value};
                                }
                            }else{
                                // special fields which are undefined or empty string MUST not be sent
                                // Defect Fix : 026449 (record type either undefined / empty string should be skipped)
                                if(!(key == "RecordTypeId" && (item === undefined || !(item)))){
                                    keyValue = {key : key, value : item};
                                }
                            }

                            if(keyValue){
                                record.targetRecordAsKeyValue[record.targetRecordAsKeyValue.length] = keyValue;
                            }

                        }
                        detailRecords.records[detailRecords.records.length] = record;
                    }
            }
            return ret;
        },

        getDetailDeletedRecords : function(detailId){
            var ret = [], allDeletedRecords = this.__data.getDeletedRecords(), i, l = allDeletedRecords.length,
                    deletedRecord;
            for(i = 0; i < l; i++){
                deletedRecord = allDeletedRecords[i];
                if(deletedRecord.alias == detailId){
                    ret.push(deletedRecord.id);
                }
            }
            return ret;
        },

        getDetailMetadata : function(detailId){
            var ret = null, details = this.__metadata.page.details, i, l = details.length;

            for(i = 0; i < l; i++){
                if(details[i].dtlLayoutId == detailId){
                    ret = details[i];
                    break;
                }
            }
            return ret;
        },

        getDetailParentColumnName : function(detailMetaData){
            var ret = null, detailId = detailMetaData.dtlLayoutId,
                        parentColumnMap = this.__metadata.response.stringMap, i, l = parentColumnMap.length;
            for(i = 0; i < l; i++){
                if(parentColumnMap[i].key == "PROCESSTYPE") continue;

                if(parentColumnMap[i].key == detailId){
                    ret = parentColumnMap[i].value;
                    break;
                }
            }

            return ret;
        },

        getRequest : function(){
            var request = {headerRecord : {}};
            request.sfmProcessId = this.__additionalInfo.sfmProcessId || this.__additionalInfo.processId;
            request.eventType = this.__additionalInfo.eventType;
            request.headerRecord.objName = this.getParentObjectName();
            request.headerRecord.pageLayoutId = this.getHeaderLayoutId();
            request.headerRecord.records = this.getHeaderRecords();
            request.detailRecords = this.getDetailRecords();

            // do process type specific
            var ptype = this.getProcessType();
            if(ptype == "STANDALONE EDIT" || ptype == "STANDALONE CREATE"){
                request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
            }else if(ptype == "SOURCE TO TARGET ALL"){
                var targetRecordId = this.__data.getTargetRecordId();
                if(targetRecordId){
                    request.headerRecord.records[0].targetRecordId = targetRecordId;
                    var trkv = request.headerRecord.records[0].targetRecordAsKeyValue;
                    trkv[trkv.length] = {key : "Id", value : targetRecordId};
                }
                request.headerRecord.records[0].sourceRecordId = this.__data.getSourceRecordId();
            }else if(ptype == "SOURCE TO TARGET CHILD"){
                request.headerRecord.records[0].targetRecordId = this.__data.getTargetRecordId();
                request.headerRecord.records[0].sourceRecordId = this.__data.getTargetRecordId();

            }else if(ptype == "VIEW RECORD"){
                // TODO:
            }else if(ptype == "CHECKLIST"){
                // TODO:
                var me = this;
                if(request.eventType === "validated save") {
                  request.eventType = "save checklist";
                }
                SVMX.array.forEach(request.headerRecord.records, function(headerRecord) {
      								headerRecord["sourceRecordId"] = me.__data.getSourceRecordId();
      					});
            }
            // end process specific

            return request;
        }
    }, {});

    utils.Class("SFMTargetAttachmentRecord", com.servicemax.client.lib.api.Object, {
        __data : null, __metadata : null, __additionalInfo : null, _sourceRecordId:null, __attachmentData: null,
        __constructor : function(request, metadata, additionalInfo){
            this.__data = request.data;
            this.__additionalInfo = request.additionalInfo;
            this.__deletedId = [];
            this.__metadata = metadata;
            this.__attachmentData = request.data.__attachementData;
            this._sourceRecordId = request.data._sourceRecordId;
        },

        getParentObjectName : function(){
            return SVMX.OrgNamespace + "__SM_Checklist_Attachment__c";
        },

        getHeaderLayoutId : function(){
            return this.__metadata.page.header.hdrLayoutId;
        },

        getProcessType : function(){
            return this.__metadata.response.sfmProcessType;
        },

        getHeaderRecords : function(){
            var ret = [];
            if(this.__attachmentData){
                var recordList = this.__attachmentData.unSyncedRecord;
                if(recordList && recordList.length > 0){
                    var recordListLength = recordList.length;
                    for (var index = 0; index < recordListLength; index++) {
                        var attachmentRecord = recordList[index];
                        if(attachmentRecord.hasOwnProperty(SVMX.OrgNamespace + '__SM_Internal_Question_ID__c')){ //Deleted record only.
                            ret.push(this.getChecklistAttachment(attachmentRecord));
                        } 
                    }
                }
            }
            return ret;
        },

        getChecklistAttachment : function(record){
            var recordList = [];
            var targetRecordAsKeyValue = {'targetRecordAsKeyValue':recordList, 'sourceRecordId': this._sourceRecordId};
            var recordKey = Object.keys(record);
            var recordLength = recordKey.length;
            for (var index = 0; index < recordLength; index++) {
                recordList.push(this.getfieldObject(recordKey[index],record[recordKey[index]]));
            }
            return targetRecordAsKeyValue;
        },

        getfieldObject : function(key, value){
            var field = {'key': key, 'value': value};
            return field;
        },

        getDeleteAttachmentID: function(){
            var ids = [];
            if(this.__attachmentData){
                var deleteRecord = this.__attachmentData.__deletedRecords;
                if(deleteRecord){
                    var recordKey = Object.keys(deleteRecord);
                    var recordLength = recordKey.length;
                    for (var index = 0; index < recordLength; index++) {
                        var record = deleteRecord[recordKey[index]];
                        if(record){
                            ids.push(record['Id']);
                        }
                    }
                }
            }
            return ids;
        },

        getRequest : function(){
            var request = {headerRecord : {}};
            request.sfmProcessId = this.__additionalInfo.sfProcessId || this.__additionalInfo.processId;
            request.eventType = this.__additionalInfo.eventType;
            request.headerRecord.objName = this.getParentObjectName();
            request.headerRecord.pageLayoutId = this.getHeaderLayoutId();
            request.headerRecord.records = this.getHeaderRecords();
            request.detailRecords = [];
            request.headerRecord.deleteRecID = this.getDeleteAttachmentID();
            return request;
        }
    }, {});

};

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\responders.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.responders
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var sfmdeliveryresponders = SVMX.Package("com.servicemax.client.sfmdelivery.responders");

sfmdeliveryresponders.init = function(){

	sfmdeliveryresponders.Class("GetPageLayoutResponder", com.servicemax.client.mvc.api.Responder, {

		__constructor : function() { this.__base(); },

		result : function(data) {

			// YUI Compressor cribs
			//debugger;

			alert("Done!");
		},

		fault : function(data) {

		}

	}, {});

	sfmdeliveryresponders.Class("GetExistingCheckListPageLayoutResponder", com.servicemax.client.mvc.api.Responder, {
		__parentResponder : null,
		__constructor : function(parentResponder) {
			this.__base();
			this.__parentResponder = parentResponder;
		},

		result : function(data) {
			data = data || {};
			data.__data = data.__data || {};
			data.__data.sfmData = data.__data.sfmData || {};

			var json = data.__data.sfmData[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'];
			var obj = null;
			if (json) {
				try {
					obj = SVMX.toObject(json);
				} catch (e) {
					console.warn("Unable to parse Checklist page layout.");
				}
			}

			if (this.__parentResponder && obj) {
				this.__parentResponder.result(obj);
			} else {
				this.fault(data);
			}

		},

		fault : function(data) {
			if (this.__parentResponder) {
				this.__parentResponder.fault(data);
			}
		}

	}, {});
    sfmdeliveryresponders.Class( "GetExistingCheckListPageLayoutResponderOffline" , com.servicemax.client.mvc.api.Responder , {
        __parentResponder:null ,
        __constructor:function ( parentResponder ) {
            this.__base();
            this.__parentResponder = parentResponder;
        } ,
        result:function ( data ) {
            data = data || {};
            data.__data = data.__data || {};
            data.__data.sfmData = data.__data.sfmData || {};
            var me = this;
            var recordData = data.__data.sfmData;
            var CheckListChunkUtilsRef = com.servicemax.client.offline.sal.model.utils.CheckListChunkUtils;
            var combinedJson = CheckListChunkUtilsRef.getCombinedChecklistData( recordData );
            combinedJson.then( function ( cJson ) {
                var chkListMetaJsonColumn = SVMX.getCustomFieldName( 'ChecklistMetaJSON' );
                //Re assign the JSON Columns
                data.__data.sfmData[chkListMetaJsonColumn] = cJson[chkListMetaJsonColumn];
                var json = data.__data.sfmData[chkListMetaJsonColumn];
                var obj = null;
                if ( json ) {
                    try {
                        obj = SVMX.toObject( json );
                    } catch ( e ) {
                        console.warn( "Unable to parse Checklist page layout." );
                    }
                }
                if ( me.__parentResponder && obj ) {
                    me.__parentResponder.result( obj );
                } else {
                    me.fault( data );
                }
            } );
        } ,
        fault:function ( data ) {
            if ( this.__parentResponder ) {
                this.__parentResponder.fault( data );
            }
        }
    } , {} );

	sfmdeliveryresponders.Class("GetPageDataResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onGetPageDataCompleted(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("ReloadPageDataAndNavigateResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __params : null,
		__constructor : function(parent, params) {
			this.__base();
			this.__parent = parent;
			this.__params = params;
		},

		result : function(data) {
				this.__parent.onReloadPageDataAndNavigateCompleted(data, this.__params);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("GetUserInfoResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onGetUserInfoCompleted(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("GetLookupConfigResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
			this.__parent.onGetLookupConfigComplete(data);
		},

        /**
         * Calls the parent error/fault handler {engine.js}
         *
         * @param   {Object}    data    composite data object
         */
		fault : function(data) {
			this.__parent.onGetLookupConfigError(data);
		}

	}, {});

	sfmdeliveryresponders.Class("GetNextStepInfoResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onGetNextStepInfoComplete(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("DescribeObjectResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __objectName : null, __params : null,
		__constructor : function(objectName, parent, params) {
			this.__base();
			this.__parent = parent;
			this.__objectName = objectName;
			this.__params = params;
		},

		result : function(data) {
				this.__parent.onDescribeObjectComplete(this.__objectName, data, this.__params);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("SaveTargetRecordResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __actionType : null,
		__constructor : function(parent, actionType, additionalInfo) {
			this.__base();
			this.__parent = parent;
			this.__actionType = actionType;
			this.__additionalInfo = additionalInfo;
		},

		result : function(data) {
			this.__parent.onSaveTargetRecordComplete({
			    data : data,
			    actionType : this.__actionType,
			    additionalInfo : this.__additionalInfo,
			    error : data.error});
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("QuickSaveTargetRecordResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onQuickSaveTargetRecordComplete(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("InvokeEventsResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onInvokeEventsComplete();
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("AddRecordsResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__multiSelectData: null,
		__sfmdetail: null,
		__constructor : function(parent, data, sfmdetail) {
			this.__base();
			this.__parent = parent;
			this.__multiSelectData = data;
			this.__sfmdetail = sfmdetail;
		},

		result : function(data) {
			this.__parent.onAddRecordsComplete(data, this.__multiSelectData, this.__sfmdetail);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("DeleteRecordsResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onDeleteRecordsComplete(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("GetBubbleDataResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __request : null,
		__constructor : function(parent, request) {
			this.__base();
			this.__parent = parent;
			this.__request = request;
		},

		result : function(data) {
				this.__parent.onGetBubbleDataComplete(data, this.__request);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("GetDetailMappedInfoResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __params : null, __callback : null, __bindingPath: null,
		__constructor : function(parent, params, bindingPath, callback) {
			this.__base();
			this.__parent = parent;
			this.__params = params;
			this.__bindingPath = bindingPath;
			this.__callback = callback;
		},

		result : function(data) {
				this.__parent.onGetDetailMappedInfoComplete(data, this.__params, this.__bindingPath, this.__callback);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("ListAttachmentsResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __params : null,
		__constructor : function(parent, params) {
			this.__base();
			this.__parent = parent;
			this.__params = params;
		},

		result : function(data) {
				this.__parent.onListAttachmentsComplete(data, this.__params);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("DeleteAttachmentsResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __params : null,
		__constructor : function(parent, params) {
			this.__base();
			this.__parent = parent;
			this.__params = params;
		},

		result : function(data) {
				this.__parent.onDeleteAttachmentsSuccess(data, this.__params);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("SelectFileToUploadResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null, __params : null,
		__constructor : function(parent, params) {
			this.__base();
			this.__parent = parent;
			this.__params = params;
		},

		result : function(data) {
			this.__parent.onFileSelectedForUpload(data, this.__params);
		},

		fault : function(data) {
			this.__parent.onFileSelectedForUploadError(data);
		}

	}, {});

	sfmdeliveryresponders.Class("ChecklistEntryResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onEntryCriteriaExecutionComplete(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});

	sfmdeliveryresponders.Class("ChecklistExitResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

		result : function(data) {
				this.__parent.onExitCriteriaExecutionComplete(data);
		},

		fault : function(data) {
			// TODO:
		}

	}, {});


};
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfmdelivery\src\utils.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfmdelivery.utils
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfmdeliveryutil = SVMX.Package("com.servicemax.client.sfmdelivery.utils");

sfmdeliveryutil.init = function(){
	// imports
	var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");
	// end imports

	/**
	 * Class to provide all the utility methods for SFMDelivery.
	 * Currently contains util functions fadein, fadeout, required and invalid messages
	 */
	sfmdeliveryutil.Class("SFMUtils", com.servicemax.client.lib.api.Object, {
			__constructor : function(){
				//TODO :
			}
		}, {
			fadeIn : function(elId){
				var lIntr = setInterval(function(){
					lCurrentOpacity += .2;
					$("#" + elId).css("opacity", lCurrentOpacity <= 1.0 ? lCurrentOpacity : 1.0);

					if(lCurrentOpacity >= 1.0){
						clearInterval(lIntr);
					}

				}, 50), lCurrentOpacity = 0;
			},

			fadeOut : function(elId, optionalCallback){
				var lIntr = setInterval(function(){
					lCurrentOpacity -= .2;
					$("#" + elId).css("opacity", lCurrentOpacity >= 0.0 ? lCurrentOpacity : 0.0);

					if(lCurrentOpacity <= 0.0){
						clearInterval(lIntr);
						if (optionalCallback) optionalCallback();
					}

				}, 50), lCurrentOpacity = 1;
			},

			//message to be displayed in error ui comp when required field is empty
			requiredFieldErrMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG127", "Required field is blank:") + " " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when required field is empty
			requiredFieldDescriptionMessage : function(fieldLabel){
				var msg = TS.T("FSA002_TAG030", "Required description field") + ": " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when invalid data is entered in a field
			invalidFieldErrMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG128", "Invalid value in field:") + " " + fieldLabel;
				return msg;
			},

			//message to be displayed in error ui comp when field length exceeds maximum
			exceedsLengthFieldMessage : function(fieldLabel){
				var msg = TS.T("FSA008_TAG120", "Exceeds maximum length: ") + " " + fieldLabel;
				return msg;
			},

			prepareDataForDisplay : function(data, type){
				if(type == "textarea" || type == "string"){
					if(data){
						data = data.split("<").join("&lt;");
				    	data = data.split(">").join("&gt;");
				    	data = data.split('"').join("&quot;");
					}
				}
				return data;
			},

			prepareDataForEdit : function(data, type){
				return data;
			}
	});
}
})();
// end of file

