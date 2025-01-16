/*
 * @Author: Sravan Panchangam
 * @Description: DCP-9865 ASOP Integration
 * @Date :2018/09/27
 * Modification Log:
 * ------------------------------------------------------------------------------------ 
 * Jitesh Lakhwani             6-July-2022            Code Scan fixes of Comments
 * 
 * ------------------------------------------------------------------------------------   
*/
@RestResource(urlMapping='/ApttusOrdersAttachmentReceiver/')
global with sharing class ApttusOrdersAttachmentReceiver extends ilib_RestReceiver {
    
    private static List<ApttusOrdersAttachmentWrapper.RequestBodyJson> lstAttachment;

    /*
    *  @description  : This method is for saving the attachments for orders
    *  @param        : NA
    *  @return       : void
    */
	@Httppost
    global static void insertAttachment()
    {
        // instantiate this class so that base class logic is available
        ApttusOrdersAttachmentReceiver instantiated = new ApttusOrdersAttachmentReceiver();
        // get the (non-static context) details
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);

        String strRestError = null;
        Id primaryRecordId;
        String erpCustomerId;

        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            
            primaryRecordId = insertAttachmentsImpl();
            erpCustomerId = getRelatedErpCustomerId('Apttus_Config2__Order__c', 'Apttus_QPConfig__ProposalId__r.Apttus_Proposal__Opportunity__r.Account', primaryRecordId);
        }
        catch (Exception e)
        {
            strRestError = UtilsRest.handleCustomRestError(e);
			instantiated.addFriendlyJsonToLog(log, lstAttachment);
        }
        
        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
			instantiated.addFriendlyJsonToLog(log, redactAttachmentBodies());
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, erpCustomerId, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('insertAttachment');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
            /*
            ilib_LogEvent.quickEmit(
                interfaceDetails.name + ' failed',
                new Map<String, String> { 'Error Description' => strRestError }
            );*/
        }
        ilib_LogEvent.emit();
    }

    private static List<ApttusOrdersAttachmentWrapper.RequestBodyJson> redactAttachmentBodies()
    {
        // NOTE: should this go in the wrapper?
        // remove the encoded attachment data from the JSON
        List<ApttusOrdersAttachmentWrapper.RequestBodyJson> lstRedactedAttachment = new List<ApttusOrdersAttachmentWrapper.RequestBodyJson>();
        for (ApttusOrdersAttachmentWrapper.RequestBodyJson reqBodyJson : lstAttachment)
        {
            ApttusOrdersAttachmentWrapper.RequestBodyJson clonedReqBodyJson = new ApttusOrdersAttachmentWrapper.RequestBodyJson();
            clonedReqBodyJson.Sales_Order_Number_Unique = reqBodyJson.Sales_Order_Number_Unique;
            clonedReqBodyJson.relatedAttachments = new List<ApttusOrdersAttachmentWrapper.RelatedAttachments>();
            lstRedactedAttachment.add(clonedReqBodyJson);

            for (ApttusOrdersAttachmentWrapper.RelatedAttachments relatedAttachement : reqBodyJson.relatedAttachments)
            {
                ApttusOrdersAttachmentWrapper.RelatedAttachments redactedAttachment = new ApttusOrdersAttachmentWrapper.RelatedAttachments();
                redactedAttachment.AttachmentFileName = relatedAttachement.AttachmentFileName;
                redactedAttachment.AttachmentVersionData = '(not logged)';
                clonedReqBodyJson.relatedAttachments.add(redactedAttachment);
            }
        }

        return lstRedactedAttachment;
    }

    private static void deserializeInputs(String jsonInput)
    {
        System.debug('ApttusOrdersAttachmentWrapper Before Unwrap::::'+jsonInput);
        lstAttachment =(List<ApttusOrdersAttachmentWrapper.RequestBodyJson>)System.JSON.deserialize(jsonInput, List<ApttusOrdersAttachmentWrapper.RequestBodyJson>.class);
        System.debug('ApttusOrdersAttachmentWrapper::::'+lstAttachment);
    }

    private static Id insertAttachmentsImpl()
    {
        list<ContentVersion> lstCVAttachments=new list<ContentVersion>();
        set<Id> setCVIds=new set<Id>();
        set<Id> setOrderIds=new set<Id>();
        Apttus_Config2__Order__c objOrder;
      
        if(!lstAttachment.isEmpty()){
            for(ApttusOrdersAttachmentWrapper.RequestBodyJson attachmentJson:lstAttachment){
                String salesOrderNumberUnique= attachmentJson.Sales_Order_Number_Unique;
                SYstem.debug('salesOrderNumberUnique from Recevier:'+salesOrderNumberUnique.trim());
                //Fetching the record from ApttusOrdersSelector for the ASOP Number which was sent in the Json
                objOrder = String.isNotBlank(salesOrderNumberUnique)?new ApttusOrdersSelector().fetchRecordForSalesOrderNumber(salesOrderNumberUnique.trim()):new Apttus_Config2__Order__c();
                System.debug('objOrder:'+objOrder);
                setOrderIds.add(objOrder.id);
                //Creating a new ContentVersion for each and every attachments and adding that to the list
                for(ApttusOrdersAttachmentWrapper.RelatedAttachments relatedAttachments:attachmentJson.getRelatedAttachments()){
                    ContentVersion attach=new ContentVersion();
                    attach.VersionData=EncodingUtil.base64Decode(relatedAttachments.attachmentVersionData);
                    attach.Title=relatedAttachments.AttachmentFileName;
                    attach.PathOnClient=relatedAttachments.AttachmentFileName;
                    lstCVAttachments.add(attach);
                }
            }
        }
        List<Contract_Order_Routing_Sheet__c> lstCors =  new CORSSelector().selectCORSForOrders(setOrderIds);
        System.debug('lstCVAttachments'+lstCVAttachments);

        //inserting the list of ContentVersion Attachments and after that fetching the ids
        if(!lstCVAttachments.isEmpty()){
            insert lstCVAttachments;
            for(ContentVersion attachmentIds:lstCVAttachments){
                setCVIds.add(attachmentIds.Id);
            }
        }
        System.debug('setCVIds:'+setCVIds);

        //Fetching the List of ContentDocumentIds for each of the inserted Attachments in the previous step
        List<ContentVersion> lstCVDocumentIds=setCVIds!=null?new ContentVersionsSelector().selectByContentVersionId(setCVIds):null;
        List<ContentDocumentLink> lstlinkAttachments=new List<ContentDocumentLink>();

        //Linking the Entity from ContentDocumentLink with the Id that we fetched from the ApttusOrdersSelector earlier
        //Linking the ContentDocumentId from List of DocumentIds from each attachment
        if(!lstCVDocumentIds.isEmpty())
        {
            for(ContentVersion cdId:lstCVDocumentIds)
            {
                ContentDocumentLink linkAttachments=new ContentDocumentLink();
                linkAttachments.ContentDocumentId=cdId.ContentDocumentId;
                linkAttachments.LinkedEntityId=objOrder.Id;                
                linkAttachments.ShareType='v';
                lstlinkAttachments.add(linkAttachments);
				For(Contract_Order_Routing_Sheet__c c: lstCors){
                    ContentDocumentLink linkAttachmentsToCors=new ContentDocumentLink();
                    linkAttachmentsToCors.ContentDocumentId=cdId.ContentDocumentId;
                    linkAttachmentsToCors.LinkedEntityId=c.id;
                    linkAttachmentsToCors.ShareType='I';   
                    lstlinkAttachments.add(linkAttachmentsToCors);                
                }       
            }

            if(!lstlinkAttachments.isEmpty())
            {
                insert lstlinkAttachments;
            }
        }
        
        System.debug('lstlinkAttachments'+lstlinkAttachments);

        return (objOrder != null ? objOrder.Id : null);
    }


}