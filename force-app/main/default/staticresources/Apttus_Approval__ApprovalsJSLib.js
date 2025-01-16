/**
 *	Apttus Approvals Management
 *	ApprovalsJSLib.js
 *	 
 *	@2011-2020 Apttus Inc. All rights reserved.
 * 
 */

/**
 * Show error message dialog
 */
function ap_erroralert(msg, exception) {
    
	try {
        var emsg = null;
        var efld = null;
        var estc = null;
        var etid = null;

        try {
            var hasErrors = (exception.errors!=null);
            var hasFault = (exception.faultcode!=null);
            //alert("hasErrors="+hasErrors+"\nhasFault="+hasFault);

            if (hasErrors) {
                emsg = exception.errors.message;
                efld = exception.errors.fields;
                estc = exception.errors.statusCode;

            } else if (hasFault) {
                emsg = exception.faultcode;
                efld = exception.faultstring;
                
            } else {
                emsg = exception.message;
                efld = exception.fields;
                estc = exception.statusCode;
            }
            
        } catch(ex) {
            emsg = exception.errors.message;
            efld = exception.errors.fields;
            estc = exception.errors.statusCode;
        }

        var estr = msg;
        var estrdb = estr;
        
        if (emsg!=null && emsg!="") {
            estr += "\nmessage: "+emsg;
            estrdb += "<br>message: "+emsg;
        }
        if (efld!=null && efld!="") {
            estr += "\nfields: "+efld;
            estrdb += "<br>fields: "+efld;
        }
        if (estc!=null && estc!="") {
            estr += "\nstatusCode: "+estc;
            estrdb += "<br>statusCode: "+estc;
        }
        if (etid!=null && etid!="") {
            estr += "\ntargetObjectId: "+etid;
            estrdb += "<br>targetObjectId: "+etid;
        }
        
        alert(estr);
        
    } catch(ex) {
        alert(msg+"\n"+exception);
        
    }
    
}

/**
 * Submit given approval context
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @return <code>true</code> if successful
 */
function ap_submitForApprovals(sObjectType, sObjectId) {
	// submit approvals
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'submitForApprovals',
									 {sObjectType:sObjectType,
									  sObjectId:sObjectId});

	if (result == null || result == '') {
		throw(ap_cERROR_SUBMIT_APPROVALS);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Submit given approval context
 * @param ctxObjParams the list of context object parameters
 * @return <code>true</code> if successful
 */
/*function ap_submitForApprovalsBulk(ctxObjParams) {
	
	//---------------------------------------------------------------
	// create submission comments
	var submitComments1 = new sforce.Xml("SubmissionComments");
	submitComments1.commentsLevel = "Process";
	submitComments1.commentsCount = 1;
	submitComments1.processName = 'ProcessName';
	submitComments1.processCommentLabel = 'ProcessLabel';
	submitComments1.processCommentMandatory = false;
	submitComments1.processComment = 'Test Comment 1';
		
	var submitComments2 = new sforce.Xml("SubmissionComments");
	submitComments2.commentsLevel = "Process";
	submitComments2.commentsCount = 1;
	submitComments2.processName = 'ProcessName';
	submitComments2.processCommentLabel = 'ProcessLabel';
	submitComments2.processCommentMandatory = false;
	submitComments2.processComment = 'Test Comment 2';
		
	var submitComments3 = new sforce.Xml("SubmissionComments");
	submitComments3.commentsLevel = "Process";
	submitComments3.commentsCount = 1;
	submitComments3.processName = 'ProcessName';
	submitComments3.processCommentLabel = 'ProcessLabel';
	submitComments3.processCommentMandatory = false;
	submitComments3.processComment = 'Test Comment 3';
		
	// create context objects parameters
	var ctxObjParamsArray = new Array();

	var ctxBulkParam1 = new sforce.Xml("BulkCtxObjectParam");
	ctxBulkParam1.ctxSObjectType = 'Apttus__APTS_Agreement__c';
	ctxBulkParam1.ctxSObjectId = 'a013l00000sS1JM';
	ctxBulkParam1.comments = submitComments1;
	
	ctxObjParamsArray.push(ctxBulkParam1);

	var ctxBulkParam2 = new sforce.Xml("BulkCtxObjectParam");
	ctxBulkParam2.ctxSObjectType = 'Apttus__APTS_Agreement__c';
	ctxBulkParam2.ctxSObjectId = 'a013l00000sTaSL';
	ctxBulkParam2.comments = submitComments2;
		
	ctxObjParamsArray.push(ctxBulkParam2);

	var ctxBulkParam3 = new sforce.Xml("BulkCtxObjectParam");
	ctxBulkParam3.ctxSObjectType = 'Apttus__APTS_Agreement__c';
	ctxBulkParam3.ctxSObjectId = 'a013l00000sTaSQ';
	ctxBulkParam3.comments = submitComments3;
	
	ctxObjParamsArray.push(ctxBulkParam3);
	//---------------------------------------------------------------
	
	// submit approvals bulk
	sforce.debug.trace=true;
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'submitForApprovalsBulk',
									 {ctxObjParams:ctxObjParamsArray});
    
    if (result == null || result == '') {
		throw(ap_cERROR_SUBMIT_APPROVALS);
		
	} 	
	
	return result.valueOf();		
}*/

/**
 * Submit given approval context
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @return <code>true</code> if successful
 */
function ap_submitForAdhocApprovals(sObjectType, sObjectId) {
	// submit approvals
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'submitForAdhocApprovals',
									 {sObjectType:sObjectType,
									  sObjectId:sObjectId});

	if (result == null || result == '') {
		throw(ap_cERROR_SUBMIT_APPROVALS);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Preview given approval context
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @return <code>true</code> if successful
 */
function ap_previewApprovals(sObjectType, sObjectId) {
	
	// preview approvals
	//sforce.debug.trace=true;
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'previewApprovals',
									 {sObjectType:sObjectType,
									  sObjectId:sObjectId});

	if (result == null || result == '') {
		throw(ap_cERROR_PREVIEW_APPROVALS);		
	} 	
	
	return result.valueOf();	
}

/**
 * Preview given adhoc approval context
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @return <code>true</code> if successful
 */
function ap_previewAdhocApprovals(sObjectType, sObjectId) {
	
	// preview adhoc approvals
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'previewAdhocApprovals',
									 {sObjectType:sObjectType,
									  sObjectId:sObjectId});

	if (result == null || result == '') {
		throw(ap_cERROR_PREVIEW_APPROVALS);		
	} 	
	
	return result.valueOf();	
}

/**
 * Cancel given approval context
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @return <code>true</code> if successful
 */
function ap_cancelApprovals(sObjectType, sObjectId) {		
	// cancel approvals
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'cancelApprovals',
									 {sObjectType:sObjectType,
									  sObjectId:sObjectId});	

	if (result == null || result == '') {
		throw(ap_cERROR_CANCEL_APPROVALS);
		
	} 	
	
	return result.valueOf();	
}

/**
 * Submit given approval context using JS Remoting
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @param last boolean indicating whether this is the last
 *	       qued transaction
 * @param retry retry on failure count
 * @return <code>false</code>
 */
function ap_remoteSubmitForApprovals(sObjectType, sObjectId, last, retry) {
	Visualforce.remoting.Manager.invokeAction(
		j$.APTTUS.RemoteActionSubmitApprovals,
		sObjectType, sObjectId,
		function(result, event) {			
			if (!event.status) {

				retry = typeof retry !== 'undefined' ? retry : 0;

				if(retry < 5) {					
					ap_remoteSubmitForApprovals(sObjectType, sObjectId, last, ++retry);
				} else {
					throw(ap_cERROR_SUBMIT_APPROVALS);
				}
							
			} else if(last) {
				invokeDoneProcessEach();               
			}
		},
		{buffer: false, escape: true, timeout: 120000}
	);

	return false;
}

/**
 * Preview given approval context using JS Remoting
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @param last boolean indicating whether this is the last
 *	       qued transaction
 * @param retry retry on failure count
 * @return <code>false</code> 
 */
function ap_remotePreviewApprovals(sObjectType, sObjectId, last, retry) {
	Visualforce.remoting.Manager.invokeAction(
		j$.APTTUS.RemoteActionPreviewApprovals,
		sObjectType, sObjectId,
		function(result, event) {					
			if (!event.status) {

				retry = typeof retry !== 'undefined' ? retry : 0;

				if(retry < 5) {					
					ap_remotePreviewApprovals(sObjectType, sObjectId, last, ++retry);
				} else {
					throw(ap_cERROR_PREVIEW_APPROVALS);
				}	

			} else if(last) {
				invokeDoneProcessEach();               
			}


		},
		{buffer: false, escape: true, timeout: 120000}
	);

	return false;
}

/**
 * Cancel given approval context using JS Remoting
 * @param sObjectType the approval context sobject type 
 * @param sObjectId the approval context sobject identifier
 * @param last boolean indicating whether this is the last
 *	       qued transaction
 * @param retry retry on failure count
 * @return <code>false</code> 
 */
function ap_remoteCancelApprovals(sObjectType, sObjectId, last, retry) {
	Visualforce.remoting.Manager.invokeAction(
		j$.APTTUS.RemoteActionCancelApprovals,
		sObjectType, sObjectId,
		function(result, event) {			
			
			if (!event.status) {
				retry = typeof retry !== 'undefined' ? retry : 0;

				if(retry < 5) {					
					ap_remoteCancelApprovals(sObjectType, sObjectId, last, ++retry);
				} else {
					throw(ap_cERROR_CANCEL_APPROVALS);
				}	
				
			} else if(last) {
				invokeDoneProcessEach();                
			}
		},
		{buffer: false, escape: true, timeout: 120000}
	);

	return false;
}

/**
 * Approve the given approval request
 * @param requestId the approval request id
 * @param comments the approval request comments
 * @return <code>true</code> if successful
 */
function approveRequest(requestId, comments) {
	// approve request
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'approveRequest',
									 {requestId:requestId,
									  comments:comments});

	if (result == null || result == '') {
		throw(ap_cERROR_APPROVE_REQUEST);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Approve the given approval requests
 * @param reqActionParams the list of request action parameters
 * @return <code>true</code> if successful
 */
function approveRequestBulk(reqActionParams) {

	// create request action parameters
	/*var reqActionParamsArray = new Array();

	var reqActionParam1 = new sforce.Xml("BulkActionRequest");
	reqActionParam1.requestId = 'a013l00000sS1JM';
	reqActionParam1.comments = 'comment 1';
	
	reqActionParamsArray.push(reqActionParam1);

	var reqActionParam2 = new sforce.Xml("BulkActionRequest");
	reqActionParam2.requestId = 'a013l00000sTaSL';
	reqActionParam2.comments = 'comment 2;
		
	reqActionParamsArray.push(reqActionParam2);

	var reqActionParam3 = new sforce.Xml("BulkActionRequest");
	reqActionParam3.requestId = 'a013l00000sTaSQ';
	reqActionParam3.comments = 'comment 3;
	
	reqActionParamsArray.push(reqActionParam3);*/
	
	// approve requests bulk
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'approveRequestsBulk',
									 {requestActionParams:reqActionParams});

	if (result == null || result == '') {
		throw(ap_cERROR_APPROVE_REQUEST);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Reject the given approval request
 * @param requestId the approval request id
 * @param comments the approval request comments
 * @return <code>true</code> if successful
 */
function rejectRequest(requestId, comments) {
	// reject request
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'rejectRequest',
									 {requestId:requestId,
									  comments:comments});

	if (result == null || result == '') {
		throw(ap_cERROR_REJECT_REQUEST);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Add comments to the given approval request
 * @param requestId the approval request id
 * @param comments the approval request comments
 * @return <code>true</code> if successful
 */
function addCommentsToRequest(requestId, comments) {
	// add comments to request
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'addCommentsToRequest',
									 {requestId:requestId,
									  comments:comments});

	if (result == null || result == '') {
		throw(ap_cERROR_ADDCOMMENTS_REQUEST);
		
	} 	
	
	return result.valueOf();		
}

/**
 * Copies the given attachment sobject to the destination parent
 * @param destParentId the destination parent sobject id to copy the attachment sobject to 
 * @param attId the attachment sobject id to copy 
 * @return <code>true</code> if the copy was successful, <code>false</code> otherwise
 */
function ap_copyAttachment(destParentId, attId) {
	
	// copy attachment child object
	var result = sforce.apex.execute('Apttus_Approval.ApprovalsWebService',
									 'copyAttachment',
									 {destParentId:destParentId,
									  attId:attId});
	
	if (result == null || result == '') {
		throw(ap_cERROR_ATTACHMENT_COPY);
		
	} 
	
	return result.valueOf();
	
}

/**
 * Igonore enter key press
 */
function aptIgnoreEnterKey(event){ 
	var keyCode; 
	if (event && event.which) { 
		// Use for Firefox and Chrome 
		keyCode = event.which; 

	} else { 
		// Use for IE 
	    keyCode = event.keyCode;

	}
	if (keyCode == 13) {
		return false; 
	}
	
	return true; 
	
}  
