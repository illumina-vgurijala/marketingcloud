/**
 *	Apttus Content Integration
 *	content.js
 *	 
 *	@2010-2011 Apttus Inc. All rights reserved.
 * 
 */

// constants

// publish content error
var cn_cERROR_PUBLISH_CONTENT = "Error publishing the content version:\n";


/**
 * Selects the content workspace name associated with the given agreement id
 * @param agreementId the agreement id to select the content workspace for 
 * @return the agreement content workspace name
 */
function cn_selectContentWorkspaceForAgreement(agreementId) {
	
	// get the content workspace name
	var result = sforce.apex.execute('Apttus.ComplyWebService',
									 'selectContentWorkspaceForAgreement',
									 {agreementId:agreementId});
	
	return result;
	
}

/**
 * Gets the list of content tag values for the given agreement id
 * @param agreementId the agreement id to get the tagvalues for
 * @return the list of content tagvalues
 */
function cn_getAgreementTagFieldValues(agreementId) {
	
	var tagValues = new Array();
	
	// get the tag field values
	var result = sforce.apex.execute('Apttus.ComplyWebService',
									 'getAgreementTagFieldValues',
									 {agreementId:agreementId});
	
	if (result != null && result != '') {
		var count = result.length;
		for (var i = 0; i < count; i++) {
			// create the list of tag values
			if (result[i].value) {
				tagValues.push(result[i].value);
			}
			
		}
		
	} 
	
	return tagValues;
	
}

/**
 * Publishes the given agreement attachment content
 * @param agreementId the agreement id to publish the content for
 * @param request the publish request
 * @return the content version object id
 */
function cn_publishContentForAgreement(agreementId, request) {
	
	// publish the agreement content
	var versionId = sforce.apex.execute('Apttus_Content.ContentWebService',
									    'publishContentForAgreement',
									    {agreementId:agreementId,
									     request:request});
	
	if (versionId == null || versionId == '') {
		throw(cn_cERROR_PUBLISH_CONTENT);
	} 
	
	return versionId;
	
}

/**
 * Publishes the given agreement large files content
 * @param agreementId the agreement id to publish the content for
 * @param previousStatusCategory the previous status category of an agreement.
 * @param previousStatus the previous status of an agreement.
 * @param asyncId the id of the async merge call
 * @param request the publish request
 */
function cn_prepareXAJSRequestForLargeFiles(agreementId, previousStatusCategory, previousStatus, asyncId, request) {

	var promise = new Promise( () => {
		sforce.apex.execute('Apttus_Content.ContentWebService',
								'publishContentForAgreementLargeFile',
								{agreementId:agreementId,
									previousStatusCategory:previousStatusCategory,
									previousStatus:previousStatus,
									asyncId:asyncId,
									request:request});
		resolve(true);
	});

	return promise;
	
}

