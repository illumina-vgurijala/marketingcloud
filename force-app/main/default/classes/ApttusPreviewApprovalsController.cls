/**
* @author Govind Dubey
* @date :   2018-07-23
* @description :   US-2638: Submitter Experience - Preview Approvals
*                  Retrieving Original proposal Line Items from Recycle Bin after preview operation 
*                  so admins should not empty out recycle bin during Quotation
* Modification Log:
* ------------------------------------------------------------------------------------ 
*       Govind Dubey         2018-07-23            Original Version  
*       Govind Dubey         2018-08-17            Modified logic for DCP-10119  
*       Roopal Verma         2019-07-05            DCP-25340, Added condtion for promotion approval   
*       Govind Dubey         2019-09-24            DCP-30062, SonarQube Issue fixes done
*       Jitesh Lakhwani      6-July-2022           Code Scan fixes of Comments
*       Gerardo Garcia       2024-01-24            CMCM-5310 added skip flags on triggers. 
*  ------------------------------------------------------------------------------------    
*/
public with sharing class ApttusPreviewApprovalsController {
    private static final String LOG_TITLE = 'ApttusPreviewApprovalsController';
    private static final String TRANS_REGION_STEPSEQUENCE = '1';
    private static final String TRANS_BORDER = 'Trans Border';
    private static final String TRANS_BORDER_UC_KEY = 'UC';
    private static final String TRANS_BORDER_SOLDTO_KEY = 'Sold To';
    private static final String TRANS_BORDER_DISTRIBUTOR_KEY = 'Distributor';
    private static final String TRANS_REGION_KEY = 'Region';
    private static final String BORDER_STEPNAME_SEPARATOR = 'Border';
    private static final String PROMOTION = 'Promotion';//DCP-25340
    public List<Apttus_Approval__Approval_Request__c> lstApprovalRequest{get;set;}
    public List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItem{get;set;}
    public List<ApprovalRequestWrapper> lstApprovalRequestWrapper {get;set;}
    public Map<String,ApprovalRequestWrapper> stringToApprovalRequestWrap;
    public Map<Id,String> idToUserTitle;
    public Id idQuotation{get;set;}
    public Apttus_Proposal__Proposal__c objQuotation{get;set;}
    public Map<String,Set<String>> objectNameToSetOfFields;
    public String strRegion;
    public Boolean boolPreview{set;get;}
    public boolean boolShowApprovalMessage {get; set; }
    public string approvalMessage {get; set; }
    public String strStepNameForMessage = '';

    /**
     * @description: ApttusPreviewApprovalsController Constructor.
     * @param        : NA
     * @return       : void
    */
    public ApttusPreviewApprovalsController(){
        boolPreview = false;
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
    }
    /*
    *  @author       : Govind Dubey
    *  @description  : To create approval Request records and display on the page
    *  @param        : NA
    *  @return       : void
    */
    public void previewApprovals(){
        ilib_LogEvent.info(LOG_TITLE + '.previewApprovals()');
        boolPreview = true;

        Set<Id> setOriginalProposalLineItem = new Set<Id>();

        // Modified as part of DCP-30062, SonarQube Fixes
        idQuotation = (Id)ApexPages.currentPage().getParameters().get('businessObjectId').escapeHtml4();
        Id idConfigRequest = (Id)ApexPages.currentPage().getParameters().get('id').escapeHtml4();

        if(idQuotation != null & idConfigRequest != null) {

            // skip triggers
            setSkipTriggers(true);

            // Delete quote lines that would be later recovered after preview.
            setOriginalProposalLineItem = deleteQuoteLines(idQuotation);

            if(!Test.isRunningTest()){
                ilib_LogEvent.info('Sync starting');
                Boolean isSuccessSync = Apttus_QPConfig.QPConfigWebService.syncConfiguration(idConfigRequest);
                ilib_LogEvent.info('Sync Ended:' + isSuccessSync);
                ilib_LogEvent.info('previewApprovals starting');
                Boolean isSuccessPreview = Apttus_Approval.ApprovalsWebService.previewApprovals('Apttus_Proposal__Proposal__c',idQuotation);
                ilib_LogEvent.info('previewApprovals Ended:' + isSuccessPreview);
            }
        }

        lstProposalLineItem = getQuotationLines(idQuotation)?.values();
        lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id>{idQuotation});
        ilib_LogEvent.info('@@@ lstApprovalRequest.size() --> ' + lstApprovalRequest.size());

        Set<Id> setUserId = new Set<Id>();
        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest){
            setUserId.add(objAppReq.Apttus_Approval__Assigned_To_Id__c);
        }

        idToUserTitle = new Map<Id,String>();
        for(User objUser: new UsersSelector().selectByUserId(setUserId)){
           idToUserTitle.put(objUser.Id, objUser.Title);
        }

        stringToApprovalRequestWrap = new Map<String,ApprovalRequestWrapper>();
        lstApprovalRequestWrapper = new List<ApprovalRequestWrapper>();

        Set<String> setIndirectRecordTypeName = new Set<String>{Label.IndirectReOrder,Label.IndirectFieldServices,Label.OpportunityRTIndirectStandard};

        Boolean booIndirectDeal = false;

        String strRegionKey = '';

        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest){
            ilib_LogEvent.info('objAppReq.Apttus_Approval__Step_Name__c'+objAppReq.Apttus_Approval__Step_Name__c);
            if(objAppReq.Apttus_Approval__Step_Name__c.contains('MFN')){
				strStepNameForMessage = 'MFN_Approval';
			}
            //To determine the region field to be used to displayed
            if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER)){
                booIndirectDeal = setIndirectRecordTypeName.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName);
                if(!booIndirectDeal){
                    if(math.mod(Integer.valueOf(objAppReq.Apttus_Approval__SubstepSequence__c),2)==0 && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null){
                        strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                        strRegionKey = TRANS_BORDER_UC_KEY;
                    }
                    else if(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null){
                        strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c;
                        strRegionKey = TRANS_BORDER_SOLDTO_KEY;
                    }
                }
                else{
                    if(math.mod(Integer.valueOf(objAppReq.Apttus_Approval__SubstepSequence__c),2)==0 && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c!=null){
                        strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c;
                        strRegionKey = TRANS_BORDER_DISTRIBUTOR_KEY;
                    }
                    else if(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null){
                        strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                        strRegionKey = TRANS_BORDER_UC_KEY;
                    }
                }
            }
            else if(objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) || objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)){
                if(String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                if(String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c;
                if(String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c;
            }else{
                strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null?objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c:null;
            }
            String strApproverDetail = objAppReq.Apttus_Approval__Assigned_To_Name__c;
            String strApprovalLabel = objAppReq.Apttus_Approval__StepLabel__c;
            String strApprovalStepName = objAppReq.Apttus_Approval__Step_Name__c;
            if(idToUserTitle.containsKey(objAppReq.Apttus_Approval__Assigned_To_Id__c) && idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c) != null)
                strApproverDetail = strApproverDetail + ', ' + idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c);
            String strStepName;
            if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !booIndirectDeal)
                strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(')')+' '+strRegionKey+')';
            else if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && booIndirectDeal)
                strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(BORDER_STEPNAME_SEPARATOR)+TRANS_REGION_KEY+' '+strRegionKey+')';
            else
                strStepName = objAppReq.Apttus_Approval__Step_Name__c;
            if(!stringToApprovalRequestWrap.containsKey(strStepName+strRegion)){
                if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER))
                    stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,true,false));
                else if(!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message))
                        stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,false));
                    else if(objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)) //DCP-25340, Added condition for promotion
                                stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,true));
                        else
                            stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,true,false,false));
                lstApprovalRequestWrapper.add(stringToApprovalRequestWrap.get(strStepName+strRegion));
            }else{
                ApprovalRequestWrapper objApprovalRequestWrapper = new ApprovalRequestWrapper();
                objApprovalRequestWrapper = stringToApprovalRequestWrap.get(strStepName+strRegion);
                if(objApprovalRequestWrapper != null){
					if(UtilsSettings.CPQCLM_RO_Approver_Steps.contains(objAppReq.Apttus_Approval__Step_Name__c)){
                            objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(integer.valueof(objAppReq.Apttus_Approval__Sequence__c) + 1));
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameCPQSalesApprovalRule)) { //CMCM-4444
                            objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                            objApprovalRequestWrapper.lstApprovalLabel.add(strApprovalLabel);
                            objApprovalRequestWrapper.lstApprovalStepName.add(strApprovalStepName);
                        }
                        else if(!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) && !objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)){ //DCP-25340, Added condition for promotion
                            objApprovalRequestWrapper.lstApprovalSequence.add(objAppReq.Apttus_Approval__Sequence__c);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if(!objApprovalRequestWrapper.lstApprovalSequence.isEmpty() && !objApprovalRequestWrapper.lstApprovalSequence.contains(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER)){
                            objApprovalRequestWrapper.lstApprovalSequence.add(objAppReq.Apttus_Approval__StepLabel__c);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if(objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) || objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)){
                            objApprovalRequestWrapper.lstApprovalSequence.add(TRANS_REGION_STEPSEQUENCE);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if(objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)){ //DCP-25340, Added condition for promotion
                           objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(objAppReq.Promo_Approval_Seq__c));
						   objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        } 
                        
                }
            }
        }

        // deleting new Proposal line Items which are added because of SyncCart API
        delete lstProposalLineItem;
        
        // switch back Proposal(quotation) before/after update
        setSkipTriggers(false);

        showApprovalMessages();

        undeleteQuotationLines(setOriginalProposalLineItem);

        ilib_LogEvent.emit();
    }
   /*
  *  @author : Kush
    *  @description  : Added for DCP-4949 MFN story
   */
    public void showApprovalMessages()
    {
        ilib_LogEvent.info(LOG_TITLE + '.showApprovalMessages()');
        List<Apttus_Proposal__Proposal__c> lstQuotation = new ApttusProposalsSelector().selectById(new Set<Id>{idQuotation});
        objQuotation = lstQuotation.get(0);
        approvalMessage = '';
        for (Conga_Approvals_Message__mdt objApprovalMessage : [SELECT ID, Approval_Category__c, Approval_Message__c FROM Conga_Approvals_Message__mdt])
        {
            ilib_LogEvent.info('Approval_Category__c: '+ objApprovalMessage.Approval_Category__c);
            if(strStepNameForMessage == objApprovalMessage.Approval_Category__c)	{
                ilib_LogEvent.info('Approval_Message__c: ' + objApprovalMessage.Approval_Message__c);
                boolShowApprovalMessage = true;
                approvalMessage += '</b>' + objApprovalMessage.Approval_Message__c;
            }
        }
    }

    /**
     * @author: Gerardo Garcia
     * @description: Switch On/Off Quotation before/after update And Quotations Lines after delete Triggers.
     */
    private void setSkipTriggers(Boolean value) {
        ApttusProposals.skipUpdateTrigger = value;
        ApttusProposalLineItems.skipAfterDelete = value;
    }

    private Map<Id, Apttus_Proposal__Proposal_Line_Item__c> getQuotationLines(Id quotationId){
        return new Map<Id, Apttus_Proposal__Proposal_Line_Item__c>([SELECT Id FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Apttus_Proposal__Proposal__c = :quotationId]);
    }

    private void undeleteQuotationLines(Set<Id> originalQuotationLines) {
        List<Apttus_Proposal__Proposal_Line_Item__c> ogQuotationLines = [SELECT Id FROM Apttus_Proposal__Proposal_Line_Item__c WHERE Id IN :originalQuotationLines ALL ROWS];
        if(ogQuotationLines?.size() > 0) {
            undelete ogQuotationLines;
        }
    }

    private Set<Id> deleteQuoteLines(Id quotationId) {
        Map<Id, Apttus_Proposal__Proposal_Line_Item__c> quoteLines = getQuotationLines(quotationId);
        Set<Id> quoteLinesId = quoteLines.keySet();
        if(quoteLines.values().size() > 0) {
            delete quoteLines.values();
        }
        return quoteLinesId;
    }
}