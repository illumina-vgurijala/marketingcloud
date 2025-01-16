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