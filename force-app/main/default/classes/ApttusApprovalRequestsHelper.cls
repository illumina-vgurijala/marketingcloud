/**
*    @author Nesar Mohan
*    @date   2022-06-02
*    @description    DCP-53207: Helper class to stamp Legal comments from Approval Request record to Quote record, generateAndAttachPDF and createContentDocumentAndLink logic
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*        Nesar Mohan                  2022-06-20           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ApttusApprovalRequestsHelper {
    private static final String LOG_TITLE = 'ApttusApprovalRequestsHelper';
    private static final String FEATURE_FLAG_APPROVAL_COMMENTS = 'SalesApprovalsCommentsLogging';

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to populate Legal Comments On Quote record
    *  @PARAM :         Map<Id,Id>
    *  @RETURN:         void
    */

    public void populateCommentsOnQuote(Map<Id,Id> mapProposalRequestIdtoQuoteId) {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push(LOG_TITLE + 'populateCommentsOnQuote()');
        if (!Feature.isOn(FEATURE_FLAG_APPROVAL_COMMENTS)) {
            ilib_LogEvent.info('Feature disabled for populating comments on quote, exiting....');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return;
        }
        List<Apttus_Approval__Approval_Request__c> lstApprovalRequestRecords = new ApttusApprovalRequestsSelector().selectByApprovalRequestId(mapProposalRequestIdtoQuoteId.keySet());
        Map<Id,String> mapQuoteWithComments = new Map<Id,String>();
        Pattern p = Pattern.compile(System.Label.LegalApproverCommentsPattern);

        for(Apttus_Approval__Approval_Request__c approvalReqObj : lstApprovalRequestRecords) {
            if(approvalReqObj.Apttus_Approval__Assigned_To_Type__c == NULL || approvalReqObj.Apttus_Approval__Assigned_To_Id__c == NULL) { continue; }
            if(approvalReqObj.Apttus_Approval__Assigned_To_Name__c == System.Label.LegalQueueName) {
                if(String.isBlank(approvalReqObj.Apttus_Approval__Approver_Comments__c)) {
                    mapQuoteWithComments.put(approvalReqObj.Apttus_QPApprov__ProposalId__c,NULL);
                }
                else {
                    String strComments = approvalReqObj.Apttus_Approval__Approver_Comments__c.replace('\r\n', ' ');
                    strComments = strComments.replace('\n', ' ');
                    strComments = strComments.replace('\r', ' ');
                    Matcher m = p.matcher(strComments);
                    List<String> matches = new List<String>();
                    while (m.find()) {
                        matches.add(m.group());
                        mapQuoteWithComments.put(approvalReqObj.Apttus_QPApprov__ProposalId__c,matches[0]);
                    }
                }
            }
        }

        if(!mapQuoteWithComments.isEmpty()) {
            queryQuoteAndAddComments(mapQuoteWithComments);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to Query Quote, Update comments field
    *  @PARAM :         Map<Id,String>
    *  @RETURN:         void
    */

    public void queryQuoteAndAddComments(Map<Id,String> mapQuoteWithComments) {
      List<Apttus_Proposal__Proposal__c> lstQuoteQueried = new List<Apttus_Proposal__Proposal__c>();
      lstQuoteQueried = new ApttusProposalsSelector().selectById(mapQuoteWithComments.keySet());

      List<Apttus_Proposal__Proposal__c> lstQuoteToBeUpdated = new List<Apttus_Proposal__Proposal__c>();

      for(Apttus_Proposal__Proposal__c objQuoteRecord: lstQuoteQueried) {
        Apttus_Proposal__Proposal__c objQuote = new Apttus_Proposal__Proposal__c(id=objQuoteRecord.id);
        objQuote.Open_Offer_Legal_Approver_Comments__c = mapQuoteWithComments.get(objQuoteRecord.Id); // populate legal approver comments
        lstQuoteToBeUpdated.add(objQuote);
      }

      if(!lstQuoteToBeUpdated.isEmpty()) {
        Database.SaveResult [] updateResult = Database.update(lstQuoteToBeUpdated, false);
        ApexExceptions.emitUpdateErrorsWithRelatedRecord(updateResult,LOG_TITLE+'.queryQuoteAndAddComments()',lstQuoteToBeUpdated);
      }
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Method to generate and attach pdf in afterupdate context of apttusapprovalrequest
    *  @PARAM :         Set<Id>
    *  @RETURN:         void
    */

    public void generateAndAttachPDF(Set<Id> setAppReqId) {
        List<Apttus_Approval__Approval_Request__c> lstApprovalReq = new ApttusApprovalRequestsSelector().selectByApprovalRequestId(setAppReqId);
        Map<Id,ContentVersion> mapUpdAppReqIdToCV = new Map<Id,ContentVersion>();
        List<ContentDocumentLink> listOfCDLink = new List<ContentDocumentLink>();
        List<ContentVersion> listofCV = new List<ContentVersion>();
        Set<Id> setCVId = new Set<Id>();


        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalReq) {
            PageReference page = new PageReference('/apex/ApttusSubmitForApprovalPdfPage');
            page.getParameters().put('sObjectId', objAppReq.Id);
            Blob pdfBlob;
            if(Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Unit.Testing');
            } else {
                pdfBlob = page.getContentAsPDF();
            }

            mapUpdAppReqIdToCV = createContentDocumentAndLink(objAppReq, pdfBlob);

        }

        listofCV.addAll(mapUpdAppReqIdToCV.values());
        insert listofCV;
        setCVId = UtilsCollection.getSetOfIds(listofCV,'Id');

        List<ContentVersion> listOfContentVersion = new ContentVersionsSelector().selectByContentVersionId(setCVId);

        if(listOfContentVersion!=null && !listOfContentVersion.isEmpty()) {
            for (Id objAppReq : mapUpdAppReqIdToCV.keyset()) {
                for(ContentVersion cv : listOfContentVersion) {
                    if(mapUpdAppReqIdToCV.get(objAppReq).Id == cv.Id) {
                        ContentDocumentLink cdl;
                        cdl = new ContentDocumentLink();
                        cdl.ContentDocumentId = cv.ContentDocumentId;
                        cdl.LinkedEntityId = objAppReq;
                        cdl.ShareType = 'I';
                        listOfCDLink.add(cdl);
                    }
                }
            }
        }

        if(listOfCDLink != null && !listOfCDLink.isEmpty())
        insert listOfCDLink;
  }

    /*
    *  @author: Nesar Mohan
    *  @description: Method to create content version
    *  @return: Map of approval request Is and content version document
    *  @param: Apttus_Approval__Approval_Request__c object, Blob
    */

    public static Map<Id,ContentVersion> createContentDocumentAndLink(Apttus_Approval__Approval_Request__c objAppReq, Blob  body) {
        Map<Id,ContentVersion> mapAppRewToLstCV = new Map<Id,ContentVersion>();

        if(body != null) {

            ContentVersion cv = new ContentVersion();
            cv.ContentLocation = 'S';
            cv.versionData = body;
            cv.Title = 'Approval Request - '+objAppReq.name + ' - ' +objAppReq.Apttus_Approval__Assigned_To_Name__c+'.pdf';
            cv.PathOnClient = 'Approval Request - '+objAppReq.name + ' - ' +objAppReq.Apttus_Approval__Assigned_To_Name__c+'.pdf';

            mapAppRewToLstCV.put(objAppReq.Id, cv);

        }

        return mapAppRewToLstCV;

    }

}