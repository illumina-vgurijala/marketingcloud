/**
* @author Satya Swain
* @date   2018-07-25
* @description    US-1963: Submitter Experience - Quote Summary on Submit for Approval
* Modification Log:
* ------------------------------------------------------------------------------------
*       Satya Swain         2018-07-25            Original Version  
*       Govind Dubey        2018-07-31            For DCP-5311 Buttons actions
*.      Govind Dubey        2018-08-17            Modified logic of previewQuotations method for DCP-10119
*       Govind Dubey        2018-09-05            Added uploadFile logic for DCP-11487
*       Govind Dubey        2019-04-10            Added logic to hide Shipping in Close quarters and Terms on screen/email for DCP-24000
*       Rahul Sharma        2019-04-16            Added logic for handle catalyst custom permission
*       Roopal Verma        2019-07-05            DCP-25340, Added logic for Promotion Approvals
*       Govind Dubey        2019-09-23            DCP-29855, Fixed Combination Changes
*       Roopal Verma        2020-03-20            DCP-34075, Email attachment on apttus approval requst
*       Roopal Verma        2020-04-03            Sonarqube fixes
*       Todd Newman         2021-03-17            DCP-45737: add ilib logging
*       Satya Swain         2021-05-28            TASK0588285 : Removed Catalyst Functionality References
*       Dushyant Srivastava 2022-02-22            DCP-52265: Fixes for Email Attachments.
*       Prem Ranjan         2022-05-04            CodeScan Fix (APEX) Unused Local Variable
*       Aman Tyagi          2022-03-31            Codescan Fixes
*       Khushbu Vasani      2022-06-13            DCP-54390 : populate submitted by role
*       Adyasha Satapathy   2022-10-12            Codescan Fixes(Method Naming Convention)
*       Rishi Sharma        2023-01-04            DCP-58707: Restrict Quotes with previous year pricing from expiring after the yearly price change date
*       Rishi Sharma        2023-01-16            Codescan Fixes(Unused If Statements)
*       Priya Mukherjee     2023-09-21            CMCM-2874 Display Discount Reason Code Definitions when Quoting in CPQ
*       Raja Babu           2023-10-13            TASK0963077 (CMCM-3642) <added check to make discount reason required for listed approval rule in metadata recod is Apttus_Approval_Step_Name>
*       Rajbabu Boopalan    2023-10-20            CMCM-2523 Annual Price changes
*       Rajbabu Boopalan    2023-11-03            CMCM-4516 - All Selector methods reafactoring (replace selectors with plain SOQL queries) to handle CPU timeout error.
*       Rajbabu Boopalan    2023-11-09            CMCM-3594 Justifiction reason required for promotion with approval.
*       Sai Pasumarthy      2024-09-09            DGP-954 Ability to display Term(Months) in Full Line Item Details section of Emails.
*       Akash Kumar         2024-09-17            DGP-499 Validate whether the user has access to read the message containing link to marginal analysis data
*       Sai Pasumarthy      2024-10-03            DGP-982 Q125: Phase 2 - CPQ UI/UX Refinement - More Details in Previous/Next Approver Section
* -------------------------------------------------------------------------------------------------------------------
*/
public with sharing class ApttusSubmitForApprovalController {

    private static final String LOG_TITLE = 'SubmitForApproval';

    private static final String EMAILTYPE_ASSIGNMENT = 'assignment';
    private static final String EMAILTYPE_REASSIGNMENT = 'reassignment';
    private static final String EMAILTYPE_ESCALATION = 'escalation';
    private static final String EMAILTYPE_NOTIFYONLY = 'notifyOnly';
    private static final String TRANS_REGION_STEPSEQUENCE = '1';
    
    private static final String TRANS_BORDER = 'Trans Border';
    private static final String TRANS_BORDER_UC_KEY = 'UC';
    private static final String TRANS_BORDER_SOLDTO_KEY = 'Sold To';
    private static final String TRANS_BORDER_DISTRIBUTOR_KEY = 'Distributor';
    private static final String TRANS_REGION_KEY = 'Region';
    private static final String BORDER_STEPNAME_SEPARATOR = 'Border';
    private static final String PROMOTION = 'Promotion';//DCP-25340
    private static final String HTTPS = 'https://';                                          //SonarQube Fix
    private static final String REDIRECT_URL = '/apex/ApttusQuotationRedirect?id=';          //SonarQube Fix
    private static final string LOG_TITLE_APTTUSPROPOSALPOPROLEQUEUE = 'ApttusProposalPopulateRoleQueueable';
    private static final String APPROVEREJECT = 'approveReject';//DGP-41 SB
    public List<Apttus_Proposal__Proposal__c> lstQuotation {get;set;}
    public List<Apttus_Approval__Approval_Request__c> lstApprovalRequest {get;set;}
    public List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItem {get;set;}
    public List<ApprovalRequestWrapper> lstApprovalRequestWrapper {get;set;}
    public Map<String,ApprovalRequestWrapper> stringToApprovalRequestWrap;
    public Map<Id,String> idToUserTitle;
    public Map<Id,String> idToUserDept;
    public String strQuoteId {get;set;} //public String strQuoteId {get{return strQuoteId != null ? strQuoteId :'';} set;}  Added by SB
    public Apttus_Proposal__Proposal__c objQuotation {get;set;}
    public boolean boolSkipPreviewApprovalsAPI = false;
    public String strQuoteURL {get;set;}
    public String strBaseURL {get;set;}
    public String strApproveRejectURL {get;set;}
    public String strCommentURL {get;set;}
    public Apttus_Approval__Approval_Request__c objApprovalRequest {get;set;}
    public List<Apttus_Approval__Approval_Request__c> lstPreviousApprover {get;set;}
    public List<Apttus_Approval__Approval_Request__c> lstNextApprover {get;set;}
    transient public Map<Id,ApprovalRequestWrapper> mapPrevApprovalRequestWrap {get;set;} //DGP-982
    transient public Map<Id,ApprovalRequestWrapper> mapNextApprovalRequestWrap {get;set;} //DGP-982
    public String strPreviousApproverName='';
    public String strNextApproverName='';
    public String strRegion;
    public string strFileName { get; set; }
    public boolean boolFoundDiscountApprovals {get;set;}
    public string strEmailType {get;set;}
	public string strAppReqId;
    public List<Apttus_Approval__Approval_Request__c>lstAppReq;
    public static final String MFN_APPROVAL = 'MFN_Approval'; //DCP-49429
    public static final String DSM_APPROVAL_AFTER_PRICE_CHANGE = 'DSM_Approval_After_PriceChange'; //DCP-58707
    public static final String STRING_CODE_PARAMETER_PRICE_CHANGE_DATE = 'Annual_Pricing_Change'; //DCP-58707
    public static final String OPPORTUNITY_TYPE_REORDER_NON_CONSORTIUM_CONSUMABLE = 'Reorder - Non Consortium Consumable';//CMCM-2523
    public static final String OPPORTUNITY_TYPE_STANDARD_SALE = 'Standard Sale';//CMCM-2523
    public static final String APTTUS_PROPOSAL_PROPOSAL = 'Apttus_Proposal__Proposal__c';
    //Display variable for PLI columns
    public boolean boolShipping1Q { get; set; }
    public boolean boolShipping2Q { get; set; }
    public boolean boolContractTerm { get; set; }
    public boolean boolConsortium { get; set; }
    public boolean boolShowApprovalMessage {get; set; }
    public string approvalMessage {get; set; }
    public boolean boolBdrReview {get; set; }
    public boolean showRequestShortTem {get; set;}
    public boolean boolOoccViolation {get; set;}
    public string approverDept {get; set;}
    public string approverLvl {get;set;}
    //DGP-499
    public boolean boolShowMarginalAnalysisMessage {get; set;}
    public String currUser;
    //CMCM-9066
    public List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItemApplicableToCurrentApproval {get;set;}
    public List<Id> lineItemIds = new List<Id>(); //CMCM-9066
    public static final String FINANCE='Finance';
    public static final Integer THREE=3;
    //DCP-29855 - Display Product Indicator
    public boolean boolBundleProductIndicator {get;set;}

    //CMCM-2874
    public Map<String, String> customMetadataMap { get; set; }
    public String selectedDiscountReasonDefinition { get; set; }

    //CMCM-2523
    // --- boolVTDOneDayPriorToAPCD = flag to indicate that Valid To Date(VTD) will be set as One day before Annual Price Change Date(APCD)
    public Boolean boolVTDOneDayPriorToAPCD {get; set;}
    public Date dtValidToDate {get;set;}
    public Boolean boolNoApprovalsAutoPopulateVTD {get;set;}
    
    //CMCM-3594
    public boolean hasPromotionApprovalStep {get;set;}
    
    //DGP-373
    public string strcomment {get;set;}
    //DGP-954
    public Boolean hasContractTerm {get;set;}
    /*
    * @Author: Satya Swain
    * @Description : apttus controller class
    */
    public ApttusSubmitForApprovalController()
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        boolShipping1Q = false;
        boolShipping2Q = false;
        boolContractTerm = false;
        boolBdrReview = false;
        boolBundleProductIndicator = false;////DCP-29855
        boolShowApprovalMessage = false;
        approvalMessage = '';
        boolOoccViolation =false;
        boolVTDOneDayPriorToAPCD =false;
        hasPromotionApprovalStep =false; //CMCM-3594
        hasContractTerm =false; //DGP-954
        boolShowMarginalAnalysisMessage = false;//DGP-499
    }

        /*
    *  @author       : Kush
    *  @description  : To call preview Quotation method
    *  @param        : NA
    *  @return       : String
    */
    public string getLoadData()
    {
        ilib_LogEvent.push(LOG_TITLE + '.getLoadData');
        boolSkipPreviewApprovalsAPI = true;
        previewQuotations();
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return '';
    }


    /*
    *  @author       : Satya Swain
    *  @description  : To create Quotation records and display on the page
    *  @param        : NA
    *  @return       : pageReference
    */
    
    
    public pageReference previewQuotations()
    {
        ilib_LogEvent.push(LOG_TITLE + '.previewQuotations');
		
        boolFoundDiscountApprovals = false;
        strQuoteId = strQuoteId != null ? strQuoteId : (Id)ApexPages.currentPage().getParameters().get('amp;sObjectId') != null ? (Id)ApexPages.currentPage().getParameters().get('amp;sObjectId') : (Id)ApexPages.currentPage().getParameters().get('sObjectId') ;
        String recPageMode = (String)ApexPages.currentPage().getParameters().get('amp;pageMode') != null ? (String)ApexPages.currentPage().getParameters().get('amp;pageMode') : (String)ApexPages.currentPage().getParameters().get('pageMode') ;
        if(recPageMode == APPROVEREJECT)
        {
            objApprovalRequest = new Apttus_Approval__Approval_Request__c(Id = (Id)ApexPages.currentPage().getParameters().get('id'));
        }
        //system.debug('(Id)ApexPages.currentPage().getParameters =>' + (Id)ApexPages.currentPage().getParameters());
        system.debug('(Id)ApexPages.currentPage().getParameters =>' + ApexPages.currentPage().getParameters());
        //CMCM-4516
        //lstQuotation = new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        lstQuotation = selectByQuoteId(new Set<Id>{strQuoteId});
        objQuotation = lstQuotation.get(0);
        showApprovalMessages();
        checkForOpenOfferViolations();
        ilib_LogEvent.message('boolSkipPreviewApprovalsAPI :' + boolSkipPreviewApprovalsAPI);
        ilib_LogEvent.message('Apttus_Proposal__Approval_Stage__c :' + objQuotation.Apttus_Proposal__Approval_Stage__c);

        if (!Test.isRunningTest() && boolSkipPreviewApprovalsAPI == false && objQuotation.Apttus_Proposal__Approval_Stage__c == Label.ProposalApprovalStatusApprovalRequired) {
            Apttus_Approval.ApprovalsWebService.previewApprovals(APTTUS_PROPOSAL_PROPOSAL,strQuoteId);
        }
		//DGP-954
        if(objQuotation.Term_Years__c > 0){
            hasContractTerm = true;
        }

        boolConsortium = objQuotation.Quote_Sub_Type__c.contains(Label.OpportunityTypeConsortium) && !(objQuotation.Quote_Sub_Type__c.contains('Non Consortium'));
       
        strBaseURL = System.URL.getSalesforceBaseUrl().getHost();
        if (boolSkipPreviewApprovalsAPI)
        {
            strApproveRejectURL = HTTPS+strBaseURL+'/apex/CustomQuoteApprovalSummary?id='+objApprovalRequest.Id+'&pageMode=approveReject' + '&sObjectId=' + strQuoteId;
            strCommentURL = HTTPS+strBaseURL+'/apex/Apttus_Approval__ApprovalSummaryLaunch?id='+objApprovalRequest.Id+'&pageMode=addComment';
        }
        
        //CMCM-4516
        // lstProposalLineItem = new ApttusProposalLineItemsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        lstProposalLineItem = proposalsSelectByQuoteId(new Set<Id>{strQuoteId});
        if (!lstProposalLineItem.isEmpty())
        {
            for (Apttus_Proposal__Proposal_Line_Item__c objPLI : lstProposalLineItem) {
                if (objPLI.Shipping_In_1Q_After_Close_Quarter__c != null && objPLI.Shipping_In_1Q_After_Close_Quarter__c != 0) boolShipping1Q = true;
                if (objPLI.Shipping_In_2Q_After_Close_Quarter__c != null && objPLI.Shipping_In_2Q_After_Close_Quarter__c != 0) boolShipping2Q = true;
                if (objPLI.Term_Months__c != null && objPLI.Term_Months__c != 0 ) boolContractTerm = true;                
                ////DCP-29855 - Display Product Indicator
                if (objPLI.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && boolBundleProductIndicator == false) boolBundleProductIndicator = true;
                if((objPLI.Signed_Open_Offer__c || objPLI.Open_Offer_Comparison_Customer__c) && objPLI.Open_Offer_Product__c)
                    showRequestShortTem = true;
            }
        }

        //CMCM-4516
        //lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        Set<id> setQuoteIds = new Set<id>();
        Map<Id, Apttus_Approval__Approval_Request__c > idToApprovalRequest = new Map<Id, Apttus_Approval__Approval_Request__c >(); //DGP-499
        setQuoteIds.add(strQuoteId);
        string queryApprovalReq = 'SELECT Id,Name,Apttus_Approval__Assigned_To_Id__c,Apttus_QPApprov__ProposalId__c,Apttus_Approval__Status_Link__c,Apttus_Approval__Assigned_To_Name__c,Apttus_Approval__Sequence__c,Apttus_Approval__Step_Name__c,'
            +' Apttus_Approval__Approval_Status__c,Apttus_Approval__Approver_Comments__c,Apttus_Approval__StepLabel__c,Apttus_Approval__StepSequenceString__c,Apttus_Approval__ChildObjectId__c,Promo_Approval_Seq__c,Formula_Sub_Sequence__c,'
            +' Apttus_Approval__SubstepSequence__c,Apttus_Approval__Related_Agreement__c,CreatedById,Apttus_Approval__Initial_Submitter__c, Apttus_QPApprov__ProposalId__r.Region_Distributor__c, Apttus_QPApprov__ProposalId__r.Region_Sold_To__c,'
            +' Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c, Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName, Apttus_Approval__SubmissionComment1__c'
            +' FROM Apttus_Approval__Approval_Request__c '
            +' WHERE Apttus_QPApprov__ProposalId__c IN :setQuoteIds AND Apttus_Approval__Assigned_To_Type__c != NULL AND Apttus_Approval__Assigned_To_Id__c != NULL '
            +' ORDER BY Apttus_Approval__StepSequenceString__c ASC, Formula_Sub_Sequence__c ASC NULLS FIRST, Apttus_Approval__StepLabel__c ASC NULLS FIRST';
        lstApprovalRequest = Database.query(queryApprovalReq);
        System.debug('lstApprovalRequest =>' + lstApprovalRequest);
        Set<Id> setUserId = new Set<Id>();
        lstPreviousApprover = new List<Apttus_Approval__Approval_Request__c>();
        lstNextApprover = new List<Apttus_Approval__Approval_Request__c>();
        mapNextApprovalRequestWrap = new Map<Id,ApprovalRequestWrapper>(); //DGP-982
        mapPrevApprovalRequestWrap = new Map<Id,ApprovalRequestWrapper>(); //DGP-982
        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest) {
            System.debug('lstApprovalRequest =>' + objAppReq.Apttus_Approval__Assigned_To_Id__c);
            idToApprovalRequest.put(objAppReq.Id, objAppReq);
            if(String.isEmpty(objAppReq.Apttus_Approval__Assigned_To_Id__c)) { //DGP-982 codescan: fixed nested if's
                break;
            } else {
                setUserId.add(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                if (objApprovalRequest==null) {
                    break;
                } else {
                    currentApprover(objApprovalRequest,objAppReq,lstProposalLineItem,lstApprovalRequest);
                    if (objApprovalRequest.Id != objAppReq.Id && !strNextApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && (objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusAssigned || objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusNotSubmitted)){ //DCP-25340, Added non submitted status condition
                        lstNextApprover.add(objAppReq);
                        strNextApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                        //DGP-982 Start   
                        if (!mapNextApprovalRequestWrap.containsKey(objAppReq.Id)) {
                            mapNextApprovalRequestWrap.put(objAppReq.Id, 
                            new ApprovalRequestWrapper(
                                Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),
                                objAppReq.Apttus_Approval__Step_Name__c, objAppReq,
                                objAppReq.Apttus_Approval__Assigned_To_Name__c,
                                objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c, false, false, false));
                        }
                        //DGP-982 End
                    } else if (!strPreviousApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && objAppReq.Apttus_Approval__Approval_Status__c == Label.QuotationApprovalStatusApproved) {
                            lstPreviousApprover.add(objAppReq);
                            strPreviousApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                        //DGP-982 Start
                        if (!mapPrevApprovalRequestWrap.containsKey(objAppReq.Id)) {
                            mapPrevApprovalRequestWrap.put(objAppReq.Id, new ApprovalRequestWrapper(
                                Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),
                                objAppReq.Apttus_Approval__Step_Name__c, objAppReq,
                                objAppReq.Apttus_Approval__Assigned_To_Name__c,
                                objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c, false, false, false));
                        }
                        //DGP-982 End
                    }
                }
            }
        }
        if(objApprovalRequest!=null && idToApprovalRequest.get(objApprovalRequest.Id) != null){//DGP - 499 (doing null check in submit for approval screen)
        	boolShowMarginalAnalysisMessage = showMarginalAnalysisMessage(idToApprovalRequest.get(objApprovalRequest.Id));       
            strQuoteURL = HTTPS+strBaseURL+'/lightning/cmp/c__viewSalesMarginDataLWC?c__quoteId='+strQuoteId+'&c__approvalRequestId=' + objApprovalRequest.Id;
        }
        lstProposalLineItemApplicableToCurrentApproval = ApttusProposalLineItemsSelector.proposalsSelectByQuoteIdCurrApprval(lineItemIds);       

        idToUserTitle = new Map<Id,String>();
        idToUserDept = new Map<Id,String>();
        //CMCM-4516
        //for (User objUser: new UsersSelector().selectByUserId(setUserId)) {
        for (User objUser: selectByUserId(setUserId)) {
            idToUserTitle.put(objUser.Id, objUser.Title);
            idToUserDept.put(objUser.Id, objUser.Department);
        }

    
        
        approverDept = idToUserDept.get(currUser);                
        
        List<Group> queue = new List<Group>();
        queue = [Select Id, Name From Group where Type =: 'Queue' and Id =: currUser];
        if(queue.size() >0){
            approverDept = queue[0].Name;
            
        }

        stringToApprovalRequestWrap = new Map<String,ApprovalRequestWrapper>();
        lstApprovalRequestWrapper = new List<ApprovalRequestWrapper>();
        Set<String> setIndirectRecordTypeName = new Set<String>{Label.IndirectReOrder,Label.IndirectFieldServices,Label.OpportunityRTIndirectStandard};
        Boolean booIndirectDeal;
        String strRegionKey='';
        ilib_LogEvent.message('lstApprovalRequest :'+lstApprovalRequest);
        List<String> apApproverNameList = Code_Parameter__mdt.getInstance('Apttus_Approval_Step_Name').Value__c.split(';');
        if (!lstApprovalRequest.isEmpty())
        {
            for (Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest)
            {
                //To determine the region field to be used to displayed
                if (objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER))
                {
                    booIndirectDeal = setIndirectRecordTypeName.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName);
                    if (!booIndirectDeal) {
                        if (math.mod(Integer.valueOf(objAppReq.Apttus_Approval__SubstepSequence__c),2)==0 && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null) {
                            strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                            strRegionKey = TRANS_BORDER_UC_KEY;
                        }
                        else if (objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null) {
                                strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c;
                                strRegionKey = TRANS_BORDER_SOLDTO_KEY;
                        }
                    }
                    else
                    {
                        if (math.mod(Integer.valueOf(objAppReq.Apttus_Approval__SubstepSequence__c),2)==0 && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c!=null) {
                            strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c;
                            strRegionKey = TRANS_BORDER_DISTRIBUTOR_KEY;
                        }
                        else if (objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null) {
                                strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                                strRegionKey = TRANS_BORDER_UC_KEY;
                        }
                    }
                }
                else if (objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) || objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)) {
                    if (String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Ultimate_Consignee__c;
                    if (String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c;
                    if (String.isNotEmpty(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c!=null && objAppReq.Apttus_Approval__StepLabel__c.contains(objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c)) strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Distributor__c;
                } else {
                    strRegion = objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c!=null?objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c:null;
                }
                String strApproverDetail = objAppReq.Apttus_Approval__Assigned_To_Name__c;
                String strApprovalLabel = objAppReq.Apttus_Approval__StepLabel__c;
                String strApprovalStepName = objAppReq.Apttus_Approval__Step_Name__c;

                if (idToUserTitle.containsKey(objAppReq.Apttus_Approval__Assigned_To_Id__c) && idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c) != null)
                    strApproverDetail = strApproverDetail + ', ' + idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                String strStepName;
                if (objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !booIndirectDeal)
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(')')+' '+strRegionKey+')';
                else if (objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && booIndirectDeal)
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(BORDER_STEPNAME_SEPARATOR)+TRANS_REGION_KEY+' '+strRegionKey+')';
                else
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c;

                if (!stringToApprovalRequestWrap.containsKey(strStepName+strRegion))
                {
                    if(apApproverNameList.contains(objAppReq.Apttus_Approval__Step_Name__c)){
                        boolFoundDiscountApprovals = true;
                    }
                    //CMCM-3594 - When quote has an approval step for promotion
                    if(String.isNotBlank(objAppReq.Apttus_Approval__Step_Name__c) && objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)){
                        hasPromotionApprovalStep = true;
                    }
                    if (objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER))
                        stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,true,false));
                    else if (!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message))
                            stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,false));
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)) //DCP-25340, Added condition to put value in ApprovalRequestWrapper for promotion approval
                                stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,true));
                            else
                                stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,true,false,false));
                    lstApprovalRequestWrapper.add(stringToApprovalRequestWrap.get(strStepName+strRegion));
                   
                }
                else
                {
                    ApprovalRequestWrapper objApprovalRequestWrapper = new ApprovalRequestWrapper();
                    objApprovalRequestWrapper = stringToApprovalRequestWrap.get(strStepName+strRegion);
                    if (objApprovalRequestWrapper != null)
                    {
                        if (UtilsSettings.CPQCLM_RO_Approver_Steps.contains(objAppReq.Apttus_Approval__Step_Name__c)) {
                            objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(integer.valueof(objAppReq.Apttus_Approval__Sequence__c) + 1));
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameCPQSalesApprovalRule)) { //CMCM-4444
                            objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                            objApprovalRequestWrapper.lstApprovalLabel.add(strApprovalLabel);
                            objApprovalRequestWrapper.lstApprovalStepName.add(strApprovalStepName);
                        }  
                        else if (!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) &&  !objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)) { //DCP-25340, Added promotion condition
                            objApprovalRequestWrapper.lstApprovalSequence.add(objAppReq.Apttus_Approval__Sequence__c);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (!objApprovalRequestWrapper.lstApprovalSequence.isEmpty() && !objApprovalRequestWrapper.lstApprovalSequence.contains(objAppReq.Apttus_Approval__StepLabel__c) && objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER)) {
                            objApprovalRequestWrapper.lstApprovalSequence.add(objAppReq.Apttus_Approval__StepLabel__c);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) || objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)) {
                            objApprovalRequestWrapper.lstApprovalSequence.add(TRANS_REGION_STEPSEQUENCE);
							objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)) { //DCP-25340, Added promotion condition
                           objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(objAppReq.Promo_Approval_Seq__c));
						   objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }              
                    }
                }
            }
            
            ilib_LogEvent.emit();
            return null;
        }else if (boolVTDOneDayPriorToAPCD && lstApprovalRequest.isEmpty()){
            if (!objQuotation.Is_Updated_By_System__c) {
                objQuotation.Is_Updated_By_System__c = true;
            }
            boolNoApprovalsAutoPopulateVTD = true;
            ilib_LogEvent.message('No Approvals only show VTD null message');
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return null;
        }
        else if (boolSkipPreviewApprovalsAPI == false && objQuotation.Sales_Discretionary_Approval_Error__c == null)
        {
            //PRB0049202 - To prevent re-triggering quote auto-generation process if quotation has already been generated
            if(objQuotation.Apttus_Proposal__Approval_Stage__c == Label.QuoteStageApprovalRequired || objQuotation.Apttus_Proposal__Approval_Stage__c == Label.QuoteStageInReview){
                objQuotation.Apttus_QPApprov__Approval_Status__c  = Label.QuotationApprovalStatusApproved;
                objQuotation.Apttus_Proposal__Approval_Stage__c  = Label.QuotationApprovalStatusApproved;
                if (!objQuotation.Is_Updated_By_System__c) {
                    objQuotation.Is_Updated_By_System__c = true;
                }
                update objQuotation;

                //54390
                ApttusProposalPopulateRoleQueueable queueableClassInstance = new ApttusProposalPopulateRoleQueueable(lstQuotation,UserInfo.getUserId());
                ilib_Queueablethread queueableThread = new ilib_Queueablethread(LOG_TITLE_APTTUSPROPOSALPOPROLEQUEUE);
                queueableThread.logAndQueue(queueableClassInstance, LOG_TITLE_APTTUSPROPOSALPOPROLEQUEUE, 'execute');
                ilib_QueueableManager.enqueueJob(queueableThread); 
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            PageReference objPageReference = new pageReference('/'+objQuotation.Id);
            return objPageReference;
        }
        if (objQuotation.Apttus_Proposal__Approval_Stage__c == Label.ProposalApprovalStatusApprovalRequired)
        {
             ilib_LogEvent.pop();
             ilib_LogEvent.emit();
            return null;
        }
        else
        {
             ilib_LogEvent.pop();
             ilib_LogEvent.emit();

            PageReference objPageReference = new pageReference(REDIRECT_URL+objQuotation.Id+'&attachment=false');
            return objPageReference;
        }        
    }
    /*
    *  @author       : Vinay
    *  @description  : 
    *  @param        : NA
    *  @return       : PageReference
    */
    private void currentApprover(Apttus_Approval__Approval_Request__c objApprovalRequest1, Apttus_Approval__Approval_Request__c objAppReq1,List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItem1,List<Apttus_Approval__Approval_Request__c> lstApprovalRequest1){
        
        if(objApprovalRequest1.Id == objAppReq1.Id){
            currUser=objAppReq1.Apttus_Approval__Assigned_To_Id__c;
                    approverLvl=objAppReq1.Apttus_Approval__StepLabel__c;

                    Set < string > statusApproval = new Set < string > {
                        'Assigned',
                        'Reassigned'
                    };
            //CMCM-9066 
            if(statusApproval.contains(objAppReq1.Apttus_Approval__Approval_Status__c)){

            for(Apttus_Approval__Approval_Request__c temp : lstApprovalRequest1){
                if(temp.Apttus_Approval__Approval_Status__c != 'Approved' && temp.Apttus_Approval__Approval_Status__c != 'Not Submitted'){                      
                                   for(Apttus_Proposal__Proposal_Line_Item__c tempLines : lstProposalLineItem1 ) {
                                       if(tempLines.Approval_Level_Record_Owner__c!=null && tempLines.Apttus_Proposal__Proposal__r.Transborder_Flag__c ==false){
                                            String[] strArray= temp.Apttus_Approval__StepLabel__c.split(' ');
                                            
                                            Integer appLevl;  //variable to hold step label number

                                           if(strArray[0].isNumeric())  appLevl = Integer.valueOf(strArray[0]);
                                           else if(strArray.size()==THREE  && strArray[2].isNumeric()) appLevl = Integer.valueOf(strArray[2]);

                                            if(strArray[0]==FINANCE) appLevl=appLevl+1;

                                             if(Integer.valueOf(tempLines.Approval_Level_Record_Owner__c)!=1 && (appLevl <= Integer.valueOf(tempLines.Approval_Level_Record_Owner__c)))
                                               { lineItemIds.add(tempLines.Id);
                                                  
                                                 System.debug('tempLines Id  '+tempLines.Id+'  appLevl  '+appLevl+'   Approval Level From Line Item  '+Integer.valueOf(tempLines.Approval_Level_Record_Owner__c));
                                               }
                                        }
                                   }
                                   

                          

                    
                }

                }
                
                }


            }
            
            
        }
        
    /*
    *  @author       : Govind Dubey
    *  @description  : Submit for Approval
    *  @param        : NA
    *  @return       : PageReference
    */
    public pageReference submitForApproval()
    {
        ilib_LogEvent.setTitle(LOG_TITLE + '.submitForApproval');
        Id idProcess = Apttus_Approval.ApprovalsWebService.selectApprovalProcess(APTTUS_PROPOSAL_PROPOSAL, strQuoteId);
        getTemplateIDsForProcess(idProcess);
 
        if(!objQuotation.Is_Updated_By_System__c){
            objQuotation.Is_Updated_By_System__c = true;
        }
        if(boolVTDOneDayPriorToAPCD){
            objQuotation.Apttus_Proposal__ExpectedEndDate__c = dtValidToDate;
        }
        update objQuotation;

        PageReference objPageReference = new pageReference(REDIRECT_URL+objQuotation.Id+'&attachment=false');
        
        if (!Test.isRunningTest() && objQuotation.Apttus_Proposal__Approval_Stage__c == Label.ProposalApprovalStatusApprovalRequired){
            Apttus_Approval.ApprovalsWebService.submitForApprovals(APTTUS_PROPOSAL_PROPOSAL, strQuoteId);   
            ilib_BatchManager.executeBatch(new SubmitForApprovalBatch(strQuoteId), 100);
        }

        //DCP-54390
        ApttusProposalPopulateRoleQueueable queueableClassInstance = new ApttusProposalPopulateRoleQueueable(lstQuotation,UserInfo.getUserId());
        ilib_Queueablethread queueableThread = new ilib_Queueablethread(LOG_TITLE_APTTUSPROPOSALPOPROLEQUEUE);
        queueableThread.logAndQueue(queueableClassInstance, LOG_TITLE_APTTUSPROPOSALPOPROLEQUEUE, 'execute');
        ilib_QueueableManager.enqueueJob(queueableThread);

        ilib_LogEvent.emit();
        return objPageReference;
    }


    /*
    *  @author       : Govind Dubey
    *  @description  : Cancel button redirection
    *  @param        : NA
    *  @return       : PageReference
    */
    public pageReference cancel()
    {
        boolBdrReview = true;
        PageReference objPageReference = new pageReference('/'+objQuotation.Id);
        return objPageReference;
    }

    /*
    *  @author       : Govind Dubey
    *  @description  : Display Attachment Section
    *  @param        : NA
    *  @return       : NA
    */
    public PageReference displayAttachments()
    {
        if(!objQuotation.Is_Updated_By_System__c){
            objQuotation.Is_Updated_By_System__c = true;
        }
        if(boolVTDOneDayPriorToAPCD){
            objQuotation.Apttus_Proposal__ExpectedEndDate__c = dtValidToDate;
        }
        update objQuotation;
        PageReference objPageReference = new pageReference(REDIRECT_URL+objQuotation.Id+'&attachment=true');
        return objPageReference;
    }

    /*
    *  @author       : Govind Dubey
    *  @description  : Call submitWithAttachment API
    *  @param        : process id
    *  @return       : Map of Email Type to Template id
    */
    private static Map<String, ID> getTemplateIDsForProcess(ID idProcess)
    {
         ilib_LogEvent.push('getTemplateIDsForProcess');

        // template names by email type
        Map<String, String> emailTypeToTemplateNames = new Map<String, String>();
        // template ids by email type
        Map<String, ID> emailTypeToTemplateIds = new Map<String, ID>();
        
        // STEP I - get the process sobject
        //CMCM-4516
        // List<Apttus_Approval__Approval_Process__c> lstApprovalProcesses = new ApprovalProcessesSelector().selectById(new Set<Id>{idProcess});
        List<Apttus_Approval__Approval_Process__c> lstApprovalProcesses = approvalProcessesSelectById(new Set<Id>{idProcess});
        if (!lstApprovalProcesses.isEmpty()) {
            Apttus_Approval__Approval_Process__c objApprovalProcess = lstApprovalProcesses[0];
            
            // STEP II - get the email template name for each email type
                       
            // get the assignment template
            String assignTemplateName = (!nullOrEmpty(objApprovalProcess.Apttus_Approval__Assignment_Email_Template__c) 
                                         ? objApprovalProcess.Apttus_Approval__Assignment_Email_Template__c.trim(): null);
            
            // add to the template lookup
            emailTypeToTemplateNames.put(EMAILTYPE_ASSIGNMENT, assignTemplateName);
            
            // get the reassignment template
            String strReassignTemplateName = (!nullOrEmpty(objApprovalProcess.Apttus_Approval__Reassignment_Email_Template__c) 
                                           ? objApprovalProcess.Apttus_Approval__Reassignment_Email_Template__c.trim(): null);
            
            // add to the template lookup
            emailTypeToTemplateNames.put(EMAILTYPE_REASSIGNMENT, strReassignTemplateName);
            
            // get the escalation template
            String strEscalationTemplateName = (!nullOrEmpty(objApprovalProcess.Apttus_Approval__Escalation_Email_Template__c) 
                                             ? objApprovalProcess.Apttus_Approval__Escalation_Email_Template__c.trim(): null);
            
            // add to the template lookup
            emailTypeToTemplateNames.put(EMAILTYPE_ESCALATION, strEscalationTemplateName);
            
            // get the notify only template
            String strNotifyTemplateName = (!nullOrEmpty(objApprovalProcess.Apttus_Approval__NotifyOnly_Email_Template__c) 
                                         ? objApprovalProcess.Apttus_Approval__NotifyOnly_Email_Template__c.trim(): null);
            
            // add to the template lookup
            emailTypeToTemplateNames.put(EMAILTYPE_NOTIFYONLY, strNotifyTemplateName);
            // STEP III - get the ids associated with each template name
            Map<String, ID> nameToTemplateIds = getTemplateIDsForUniqueNames(emailTypeToTemplateNames.values());
            // STEP IV - associate the template id to each email type
            for (String strEmailType : emailTypeToTemplateNames.keySet()) {
                // get the template name
                String strTemplateName = emailTypeToTemplateNames.get(strEmailType);
                // add the template id
                emailTypeToTemplateIds.put(strEmailType, nameToTemplateIds.get(strTemplateName));
            }                
        }

         ilib_LogEvent.message('templates queried and mapped');
         ilib_LogEvent.pop();
        return emailTypeToTemplateIds;
    }

    /*
    *  @author       : Govind Dubey
    *  @description  : Gets the map of email template sobject ids for the given list of template name or unique name
    *  @param        : lstTemplateNameOrUniqueNames the list of template names or the unique names
    *  @return       : the map of email template sobject ids keyed by template name
    */
    private static Map<String, ID> getTemplateIDsForUniqueNames(List<String> lstTemplateUniqueNames)
    {
        Map<String, ID> nameToTemplateIds = new Map<String, ID>();
        // create a lookup set
        Set<String> setTemplateLookup = new Set<String>(lstTemplateUniqueNames);
        //CMCM-4516
        //List<EmailTemplate> lstEmailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(lstTemplateUniqueNames);
        List<EmailTemplate> lstEmailTemplate = [SELECT id,Name,DeveloperName,FolderId,TemplateType,Markup,Subject,encoding,isActive,HtmlValue,Body FROM EmailTemplate WHERE DeveloperName IN :lstTemplateUniqueNames];
        // get the email template sobject id for the template name or unique name
        for (EmailTemplate objEmailTemplate : lstEmailTemplate) {
            // get the lookup key
            String strLookupKey = (setTemplateLookup.contains(objEmailTemplate.DeveloperName)? objEmailTemplate.DeveloperName : objEmailTemplate.Name);
            // add the template id to the collection
            nameToTemplateIds.put(strLookupKey, objEmailTemplate.Id);
        }
        return nameToTemplateIds;       
    }

    /*
    *  @author       : Govind Dubey
    *  @description  : Checks if the given string value is null or empty.
    *  @param        : strValue the string to check
    *  @return       : true if the string value is null or empty, false otherwise
    */
    private static Boolean nullOrEmpty(String strValue) {
        // check if null or zero length string
        return String.isBlank(strValue);   //Performance Fix     
    }

	/*
    *  @author       : Roopal Verma
    *  @description  : Setting values for attaching pdf
    */
    public pageReference addEmailPDFAttachment()
    {
         ilib_LogEvent.setTitle(LOG_TITLE + '.addEmailPDFAttachment');

        boolFoundDiscountApprovals = false;
        strAppReqId = strAppReqId != null ? strAppReqId : (Id)ApexPages.currentPage().getParameters().get('sObjectId');

        lstAppReq = new ApttusApprovalRequestsSelector().selectByApprovalRequestId(new Set<Id>{strAppReqId});
        Apttus_Approval__Approval_Request__c objApprovalReq = new Apttus_Approval__Approval_Request__c();
        objApprovalReq = lstAppReq.get(0);

        strQuoteId = objApprovalReq.Apttus_QPApprov__ProposalId__r.Id;

        //CMCM-4516
        //lstQuotation = new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        lstQuotation = selectByQuoteId(new Set<Id>{strQuoteId});
        objQuotation = lstQuotation.get(0);
        boolConsortium = objQuotation.Quote_Sub_Type__c.contains(Label.OpportunityTypeConsortium) && !(objQuotation.Quote_Sub_Type__c.contains('Non Consortium'));
       
        if(boolSkipPreviewApprovalsAPI){
            strBaseURL = System.URL.getSalesforceBaseUrl().getHost();
        }
        
        //CMCM-4516
        // lstProposalLineItem = new ApttusProposalLineItemsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        lstProposalLineItem = proposalsSelectByQuoteId(new Set<Id>{strQuoteId});
        if(!lstProposalLineItem.isEmpty()){
            for(Apttus_Proposal__Proposal_Line_Item__c objPLI : lstProposalLineItem){
                if(objPLI.Shipping_In_1Q_After_Close_Quarter__c != null && objPLI.Shipping_In_1Q_After_Close_Quarter__c != 0) boolShipping1Q = true;
                if(objPLI.Shipping_In_2Q_After_Close_Quarter__c != null && objPLI.Shipping_In_2Q_After_Close_Quarter__c != 0) boolShipping2Q = true;
                if(objPLI.Term_Months__c != null && objPLI.Term_Months__c != 0 ) boolContractTerm = true;                
                ////DCP-29855 - Display Product Indicator
                if(objPLI.Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c == Label.ProductConfigTypeBundle && boolBundleProductIndicator == false) boolBundleProductIndicator = true;
            }
        }
        lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id>{strQuoteId});
        
        Set<Id> setUserId = new Set<Id>();
        lstPreviousApprover = new List<Apttus_Approval__Approval_Request__c>();
        lstNextApprover = new List<Apttus_Approval__Approval_Request__c>();
        mapNextApprovalRequestWrap = new Map<Id,ApprovalRequestWrapper>(); //DGP-982
        mapPrevApprovalRequestWrap = new Map<Id,ApprovalRequestWrapper>(); //DGP-982
        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest)
        {
            if(!String.isEmpty(objAppReq.Apttus_Approval__Assigned_To_Id__c))
            {
                setUserId.add(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                if(objApprovalReq.Id != objAppReq.Id && !strNextApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && (objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusAssigned || objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusNotSubmitted)){ //DCP-25340, Added non submitted status condition
                    lstNextApprover.add(objAppReq);
                    strNextApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                    //DGP-982 Start   
                    if (!mapNextApprovalRequestWrap.containsKey(objAppReq.Id)) {
                        mapNextApprovalRequestWrap.put(objAppReq.Id, new ApprovalRequestWrapper(
                            Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),
                            objAppReq.Apttus_Approval__Step_Name__c, objAppReq,
                            objAppReq.Apttus_Approval__Assigned_To_Name__c,
                            objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c, false, false, false));
                    }
                    //DGP-982 End
                } else if(!strPreviousApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && objAppReq.Apttus_Approval__Approval_Status__c == Label.QuotationApprovalStatusApproved){  
                        lstPreviousApprover.add(objAppReq);
                        strPreviousApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                    //DGP-982 Start
                    if (!mapPrevApprovalRequestWrap.containsKey(objAppReq.Id)) {
                        mapPrevApprovalRequestWrap.put(objAppReq.Id, new ApprovalRequestWrapper(
                            Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),
                            objAppReq.Apttus_Approval__Step_Name__c, objAppReq,
                            objAppReq.Apttus_Approval__Assigned_To_Name__c,
                            objAppReq.Apttus_QPApprov__ProposalId__r.Region_Sold_To__c, false, false, false));
                    }
                    //DGP-982 End
                    }
            }
        }

        idToUserTitle = new Map<Id,String>();
        //CMCM-4516
        //for(User objUser: selectByUserId(setUserId)) { 
        for(User objUser: new UsersSelector().selectByUserId(setUserId)) {
            idToUserTitle.put(objUser.Id, objUser.Title);
        }
        
        stringToApprovalRequestWrap = new Map<String,ApprovalRequestWrapper>();
        lstApprovalRequestWrapper = new List<ApprovalRequestWrapper>();
        Set<String> setIndirectRecordTypeName = new Set<String>{Label.IndirectReOrder,Label.IndirectFieldServices,Label.OpportunityRTIndirectStandard};
        Boolean booIndirectDeal;
        String strRegionKey='';
        List<String> apApproverNameList = Code_Parameter__mdt.getInstance('Apttus_Approval_Step_Name').Value__c.split(';');
        if(!lstApprovalRequest.isEmpty()){
            for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest){
                
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
                system.debug('Step Name ' + strApprovalStepName);
                if(idToUserTitle.containsKey(objAppReq.Apttus_Approval__Assigned_To_Id__c) && idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c) != null)
                    strApproverDetail = strApproverDetail + ', ' + idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                String strStepName;
                if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !booIndirectDeal)
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(')')+' '+strRegionKey+')';
                else if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && booIndirectDeal)
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c.substringBefore(BORDER_STEPNAME_SEPARATOR)+TRANS_REGION_KEY+' '+strRegionKey+')';
                else
                    strStepName = objAppReq.Apttus_Approval__Step_Name__c;
                if(!stringToApprovalRequestWrap.containsKey(strStepName+strRegion)) {
                    if(apApproverNameList.contains(objAppReq.Apttus_Approval__Step_Name__c)) {
                        boolFoundDiscountApprovals = true;
                    }
                    if(objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER))
                        stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,true,false));
                    else if(!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message))
                            stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,false));
                        else if(objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)) //DCP-25340, Added condition to put value in ApprovalRequestWrapper for promotion approval
                                stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,true));
                            else
                                stringToApprovalRequestWrap.put(strStepName+strRegion, new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,true,false,false));
                    lstApprovalRequestWrapper.add(stringToApprovalRequestWrap.get(strStepName+strRegion));                    
                } else {
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
                        else if(!objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameTransregionLeadership) && !objAppReq.Apttus_Approval__Step_Name__c.contains(TRANS_BORDER) && !objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION) && !objAppReq.Apttus_Approval__Step_Name__c.contains(Label.Post_Pricing_Message)){ //DCP-25340, Added promotion condition
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
                        else if(objAppReq.Apttus_Approval__Step_Name__c.contains(PROMOTION)){ //DCP-25340, Added promotion condition
                           objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(objAppReq.Promo_Approval_Seq__c));
                           objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }                        
                    }
                }
            }
        }

        ilib_LogEvent.emit();
        return null;
    }
    /*
    *  @author       : Kush
    *  @description  : Show message when MFN approval is in Place
    */

    public void showApprovalMessages()
    {
        ilib_LogEvent.push(LOG_TITLE + '.showApprovalMessages');
        Integer quoteDiscount = 5000000;
        objQuotation = lstQuotation.get(0);
        set<String> setApprovalMessage = new set<String> ();
        
        for (Conga_Approvals_Message__mdt objApprovalMessage : Conga_Approvals_Message__mdt.getAll().values())
        {
            if(objQuotation.Approval_Category__c != NULL && objQuotation.Approval_Category__c != '' && objQuotation.Approval_Category__c.contains(objApprovalMessage.Approval_Category__c))
            {
                if(objQuotation.Approval_Category__c.contains(MFN_APPROVAL))
                {
                    ilib_LogEvent.message('Kush *** objQuotation ' + objApprovalMessage.Approval_Message__c);
                    boolShowApprovalMessage = true;
                    setApprovalMessage.add(System.label.UI_ErrorMessage_MFNApprovalPage);
                }
                //DCP-58707
                if(objQuotation.Approval_Category__c.contains(DSM_APPROVAL_AFTER_PRICE_CHANGE)){
                    ilib_LogEvent.message('DSM Approval Message' + objApprovalMessage.Approval_Message__c);
                    boolShowApprovalMessage = true;
                    setApprovalMessage.add(System.label.UI_ErrorMessage_ValidToDateApprovalPage);
                 }
            }
            
        }
        //CMCM-2523
        Code_Parameter__mdt codeParameterAPCDThresholdDays = Code_Parameter__mdt.getInstance('Annual_Price_Change_Threshold');
        integer apcdThresholdDays = integer.valueOf(codeParameterAPCDThresholdDays.Value__c);
        Code_Parameter__mdt codeParameterAutoSetValidToDateThresholdDays = Code_Parameter__mdt.getInstance('Auto_Set_ValidToDate_Threshold');
        integer autoSetValidToDateThresholdDays = integer.valueOf(codeParameterAutoSetValidToDateThresholdDays.Value__c);
        Map<Id,Datetime> proposalIdToAPCDate = new AnnualPricingScheduleHelper().getAnnualPriceChangeDatebyProposal(new List<Apttus_Proposal__Proposal__c> {objQuotation}, null);
        Datetime dtmAnnualPriceChange = (proposalIdToAPCDate != null && proposalIdToAPCDate.containsKey(objQuotation.id)) ? proposalIdToAPCDate.get(objQuotation.id):null;
        Date dtAnnualPriceChange = dtmAnnualPriceChange != null ? dtmAnnualPriceChange.dateGmt():null;
        ilib_LogEvent.message('Annual Price Change Date :' + dtAnnualPriceChange);
        ilib_LogEvent.message('Price List Id :' + objQuotation.Apttus_QPConfig__PriceListId__c);
        ilib_LogEvent.message('Pricing Date :' + objQuotation.Apttus_QPConfig__PricingDate__c);
        ilib_LogEvent.message('Quote_Sub_Type__c :' + objQuotation.Quote_Sub_Type__c);
        ilib_LogEvent.message('ExpectedEndDate :' + objQuotation.Apttus_Proposal__ExpectedEndDate__c);

        if(objQuotation.Apttus_QPConfig__PriceListId__c != null 
            && objQuotation.Apttus_QPConfig__PricingDate__c!= null
            && dtmAnnualPriceChange != null
            && objQuotation.Apttus_QPConfig__PricingDate__c < dtmAnnualPriceChange
            && (objQuotation.Quote_Sub_Type__c == OPPORTUNITY_TYPE_REORDER_NON_CONSORTIUM_CONSUMABLE 
            || objQuotation.Quote_Sub_Type__c == OPPORTUNITY_TYPE_STANDARD_SALE)
            && dtmAnnualPriceChange >= Date.today()
            && (objQuotation.Apttus_Proposal__ExpectedEndDate__c == null && Date.today() + apcdThresholdDays >= dtmAnnualPriceChange)){
                setApprovalMessage.add(System.label.UI_Message_ValidToDateApprovalPage);
                boolShowApprovalMessage = true;
                boolVTDOneDayPriorToAPCD = true;
                dtValidToDate = dtAnnualPriceChange - autoSetValidToDateThresholdDays;
            }
        approvalMessage = String.join(new List<String> (setApprovalMessage), '<br/>');
        if(objQuotation.Quote_Total_Value_Prior_To_DiscountUSD__c > quoteDiscount) {
            boolBdrReview = true;
        }
        ilib_LogEvent.pop();
    }
    /*
    *  @author       : Himanshu
    *  @description  : To update flag for Open Offer Conditions
    *  @param        : NA
    *  @return       : Na
    */
    public void checkForOpenOfferViolations()
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkForOpenOfferViolations');
        objQuotation = lstQuotation.get(0);
        ilib_LogEvent.message('Quote_Has_Open_Offer_Product :' + objQuotation.Quote_Has_Open_Offer_Product__c);
        ilib_LogEvent.message('Quote_For_Open_Offer_Customer :' + objQuotation.Quote_For_Open_Offer_Customer__c);
        ilib_LogEvent.message('Open_Offer_Discount_Violation_Type :' + objQuotation.Open_Offer_Discount_Violation_Type__c);

        if(objQuotation.Quote_Has_Open_Offer_Product__c && objQuotation.Quote_For_Open_Offer_Customer__c && (objQuotation.Open_Offer_Discount_Violation_Type__c == System.Label.DiscountExceededByFifteen || objQuotation.Open_Offer_Discount_Violation_Type__c == System.Label.DiscountExceeded)) {
            boolOoccViolation = true;
        }
        ilib_LogEvent.pop();
    }
   
    
    /*
    *  @author       : Priya Mukherjee
    *  @description  : Fetch the mapping of Discount reason and discount definition from Custom metadata
    *  @param        : NA
    *  @return       : Na
    */
    public void updateDiscountReasonDefinition() {
        customMetadataMap = new Map<String, String>();
        List<Discount_Reason_to_Definition_Mapping__mdt> metadataRecords = [SELECT Discount_Reason__c, Discount_Reason_Definition__c FROM Discount_Reason_to_Definition_Mapping__mdt LIMIT 20];
        for(Discount_Reason_to_Definition_Mapping__mdt record : metadataRecords) {
            customMetadataMap.put(record.Discount_Reason__c, record.Discount_Reason_Definition__c);
        }

        selectedDiscountReasonDefinition = customMetadataMap.get(objQuotation.Discount_Reason__c);
        
    }
    
    //CMCM-4516
    private static List<Apttus_Proposal__Proposal__c> selectByQuoteId(Set<ID> setQuoteIds) {
        return [SELECT Payment_Term_Description__c,Total_Number_Of_Samples__c,Apttus_Proposal__Opportunity__r.Rev_Rec_Terms__c,Apttus_Proposal__Opportunity__r.Consortium__r.Minimum_Sample_Amount__c,Apttus_Proposal__Opportunity__r.Name,
            Apttus_Proposal__Opportunity__r.AccountId,Apttus_Proposal__Opportunity__r.Account.ERP_Customer_Id__c,Apttus_Proposal__Opportunity__r.Account.BillingCountry,Apttus_Proposal__Opportunity__r.Account.BillingCountryCode,
            Apttus_Proposal__Opportunity__r.Ultimate_Consignee__c,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.ERP_Customer_Id__c,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountry,
            Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.BillingCountryCode,Apttus_Proposal__Opportunity__r.Distributor__c,Apttus_Proposal__Opportunity__r.Distributor__r.ERP_Customer_Id__c,
            Apttus_Proposal__Opportunity__r.RecordType.DeveloperName,Apttus_Proposal__Opportunity__r.StageName,Apttus_Proposal__Opportunity__r.Probability,Apttus_Proposal__Opportunity__r.Account.Apttus_Config2__PaymentTermId__c,
            Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c,Apttus_Proposal__Account__r.Territory_Region__c,Ultimate_Consignee__r.Territory_Region__c,Distributor__r.Territory_Region__c,
            Apttus_Proposal__Opportunity__r.Contract_Number__c,Apttus_Proposal__Opportunity__r.Transborder_Flag__c,Distributor__r.BillingCountry,Distributor__r.BillingCountryCode,Apttus_Proposal__Account__r.BillingCountry,
            Apttus_Proposal__Account__r.BillingCountryCode,Ultimate_Consignee__r.BillingCountry,Ultimate_Consignee__r.BillingCountryCode,Ultimate_Consignee__r.OwnerId,Distributor__r.OwnerId,Apttus_Proposal__Account__r.OwnerId,
            Apttus_Proposal__Opportunity__r.Account.Name,Apttus_Proposal__Opportunity__r.Sales_Area_Sold_To__c,Bill_To__r.ERP_Customer_Id__c,Apttus_Proposal__Opportunity__r.Sales_Area_Ultimate_Consignee__c,
            Apttus_Proposal__Opportunity__r.Sales_Area_Distributor__c,Apttus_Proposal__Primary_Contact__r.Email,Apttus_Proposal__Account__r.Name,Ultimate_Consignee__r.Name,Distributor__r.Name,
            Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Owner.Name,Apttus_Proposal__Opportunity__r.Owner.Name,Apttus_Proposal__Opportunity__r.Sales_Org_Override__c,Owner.Id,Apttus_Proposal__Account__r.Oncology_Lab_Manufacturer_Comparison__c,
            Apttus_Proposal__Account__r.Territory_Name__c,Apttus_Proposal__Opportunity__r.Product_Interest__c,Apttus_Proposal__Opportunity__r.Territory_Region__c,Apttus_Proposal__Primary_Contact__r.Name,Prepared_by__r.Email,
            Ultimate_Consignee__r.Oncology_Lab_Manufacturer_Comparison__c,Work_Order__r.Name,Work_Order__r.Owner.Name,Apttus_Proposal__Opportunity__r.Price_List_Type__c,Approval_Category__c,Quote_Total_Value_Prior_To_DiscountUSD__c,
            Id,Bill_To__c,Ship_To__c,Apttus_QPApprov__Approval_Status__c,Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Primary__c,Apttus_Proposal__Opportunity__c,Apttus_Proposal__Account__c,Cloned_From__c,Ship_To_ERP_Number__c,
            CurrencyIsoCode,Apttus_Proposal__Discount_Percent__c,Apttus_Proposal__ExpectedStartDate__c,Apttus_Proposal__Amount__c,Apttus_Proposal__ExpectedEndDate__c,Post_Pricing_Message__c,Discount_Reason__c,Discount_Reason_Definition__c,
            Discount_Justification__c,Quote_Total_Value_Prior_To_Discount__c,Total_Cart_Discount__c,Blended_Discount_Percentage__c,Quote_Total_Value_After_Discount__c,Apttus_Proposal__Primary_Contact__c,Invalid_Quote__c,MyIllumina_User_Email__c,
            Distributor__c,SAP_Quote__c,Is_Updated_By_System__c,Promo_Channel_1__c,Promo_Code_1__c,Promo_Channel_2__c,Promo_Code_2__c,Promo_Channel_3__c,Promo_Code_3__c,Ultimate_Consignee__c,Apttus_QPConfig__PriceListId__c,
            Apttus_QPConfig__PricingDate__c,Sold_To_ERP_Number__c,Ultimate_Consignee_ERP_Number__c,Bill_To_ERP_Number__c,Informatics_Quotation_c__c,Payer_ERP_Number__c,Informatics_Product_Line_Item_Numbers__c,Distributor_ERP_Number__c,
            Name,Web_Visible__c,Apttus_Proposal__Payment_Term__c,Quote_Type__c,Payer__c,Total_Net__c,Total_Discount__c,Estimated_Freight__c,Estimated_Tax__c,Post_Pricing_Message_List__c,Preferred_Language__c,Inco_Term_1__c,Prepared_by__c,
            Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Region_Ultimate_Consignee__c,Region_Distributor__c,Region_Sold_To__c,Indirect_Transregion_Flag__c,SAP_Errors__c,Direct_Sale_to_Ultimate_Consignee__c,
            Promotion_JSON__c,Opportunity_Record_Type__c,Sales_Discretionary_Approval_Error__c,Quote_Sub_Type__c,Subtotal__c,Sub_Total__c,Contract_Numbers__c,Fapiao_Type_Code__c,Fapiao_Type_Description__c,Last_Generate_Success__c,
            Last_Validation_Id__c,Generate_In_Progress__c,Async_Generation_Complete__c,View_Contract__c,BDR_Deal_Governing_Terms__c,Estimated_Presentation_Date__c,Informatics_Line_Item_Number__c,Open_Offer_Discount_Exception_Request__c,
            Open_Offer_Discount_Violation_Type__c,Quote_For_Open_Offer_Customer__c,Quote_Has_Open_Offer_Product__c,Sold_To_Account_Region__c,Work_Order__c,Number_of_MFN_Line_Items__c,Apttus_Proposal__Proposal_Name__c,
            Submit_For_Approval__c,Approval_Hierarchy_Record_Owner__c,Approval_Hierarchy_Transborder__c,Generate__c,Territory_Region__c,Async_Validation_Complete__c,OwnerId,Validation_In_Progress__c,Inventory_Location_ERP_Number__c,
            Open_Offer_Legal_Approver_Comments__c,Sub_Region_Sold_To__c,Business_Unit_Sold_To__c,Sub_Region_UC__c,Business_Unit_UC__c,Sub_Region_Distributor__c,Business_Unit_Distributor__c,Total_Discount_USD__c,
            Quote_Total_Value_After_Discount_USD__c, Apttus_Proposal__Account__r.Owner.Name, Apttus_Proposal__Account__r.Owner_Full_Name__c, Apttus_Proposal__Account__r.Subregion__c, Ultimate_Consignee__r.Owner_Full_Name__c,
            Ultimate_Consignee__r.Subregion__c, Ultimate_Consignee__r.Territory_Name__c, Term_Years__c
        FROM Apttus_Proposal__Proposal__c
        WHERE Id IN :setQuoteIds];
    }

    //CMCM-4516
    /*
    *  @author       : Rajbabu Boopalan
    *  @description  : To fetch Apttus_Approval__Approval_Process__c records
    *  @param        : Set<Id>
    *  @return       : List<Apttus_Approval__Approval_Process__c>
    */
    public static List<Apttus_Approval__Approval_Process__c> approvalProcessesSelectById(Set<Id> idProcesses) {
        return [SELECT 
            id,
            Name,
            Apttus_Approval__Reassignment_Email_Template__c,
            Apttus_Approval__Process_Name__c,
            Apttus_Approval__Object_Type__c,
            Apttus_Approval__Object_Name__c,
            Apttus_Approval__Object_Label__c,
            Apttus_Approval__NotifyOnly_Email_Template__c,
            Apttus_Approval__Escalation_Email_Template__c,
            Apttus_Approval__Cancellation_Email_Template__c,
            Apttus_Approval__Assignment_Email_Template__c
        FROM Apttus_Approval__Approval_Process__c
        WHERE id IN :idProcesses];
    }

    //CMCM-4516
    private static List<Apttus_Proposal__Proposal_Line_Item__c> proposalsSelectByQuoteId(Set<Id> setQuoteIds) {
        return [SELECT Id,Customer_Net_Price__c,Premium__c,Freight_Discount_Amount__c,Apttus_QPConfig__Uom__c,Apttus_Proposal__Quantity__c,Approval_Level_Promotion__c,Approval_Category__c,Apttus_Proposal__Proposal__c,Apttus_QPApprov__Approval_Status__c,
        Configuration_Status__c,Material_Number__c,Apttus_QPConfig__ListPrice__c,Applied_Discount_Amount__c,Applied_Discount_Details__c,Apttus_QPConfig__AdjustedPrice__c,Apttus_QPConfig__Quantity2__c,
        Apttus_QPConfig__NetPrice__c,Apttus_QPConfig__NetAdjustmentPercent__c,
        Apttus_QPConfig__AdjustmentAmount__c,Apttus_QPConfig__AdjustmentType__c ,Applied_Discount_Percentage__c,Freight_Discount_Percentage__c,Discounted_Price_Per_Unit__c,Distributor_Discount_Amount__c,Distributor_Discount_Percentage__c,
        Stacked_Discount_Amount__c,Stacked_Discount_Percentage__c,Name,Apttus_QPConfig__LineNumber__c,Apttus_QPConfig__ItemSequence__c,Apttus_QPConfig__LineType__c,Apttus_QPConfig__PrimaryLineNumber__c,Apttus_QPConfig__IsPrimaryLine__c,
        Apttus_QPConfig__LineStatus__c,Apttus_QPConfig__AssetLineItemId__c,Apttus_QPConfig__PriceType__c,Apttus_QPConfig__SellingFrequency__c,Apttus_QPConfig__ChargeType__c,Apttus_Proposal__Product__c,ERP_Line_Number__c,
        Serial_Number__c,Billing_Type__c,Apttus_QPConfig__SellingTerm__c,Apttus_QPConfig__ParentBundleNumber__c,Total_Discount_Percentage__c,Total_Discount_Amount__c,Distributor_Specific_Discount_Percentage__c,Distributor_Specific_Discount__c,
        Apttus_QPConfig__BillingFrequency__c,Derived_From_Name__c,Sales_Discretionary_Type__c,Sales_Discretionary_Discount__c,Customer_Price_Per_Unit__c,Distributor_Rebate__c,Apttus_QPConfig__OptionId__c,Price_Override__c,
        Beadchip_Part_Number__c,Project_Id__c,List_Price__c,Apttus_QPConfig__PriceAdjustmentAmount__c,Max_Samples_Allowed_Per_kit__c,Price_per_sample__c,Total_List_Price__c,Customer_Premium_Amount_Per_Unit__c,Distributor_Specific_Price__c,
        Program_Type__c,Equipment_Id__c,Apttus_QPConfig__StartDate__c,Apttus_QPConfig__EndDate__c,Suggested_Sales_Discount_Percentage__c,Suggested_Sales_Discount_Amount__c,Meets_Discount_Guidelines__c,Previous_ERP_Contract_Line_Number__c,
        Instance_Region__c,Domain_Name__c,Previous_ERP_Contract_Number__c,Registrant_Contact__c,Service_Connectivity__c,Custom_License_Flag__c,Custom_Licensing_Description__c,Product_Family__c,Product_Type__c,Product_Tier__c,
        Is_Informatics_Product__c,Is_iCredit__c,Is_Dragen__c,Apttus_QPConfig__DerivedFromId__c,Existing_Subscription__c,Renewal_Subscription__c,CurrencyIsoCode,Manual_Rebate__c,Signed_Open_Offer__c,Open_Offer_Comparison_Customer__c,
        Open_Offer_Product__c,Custom_Setup_Details__c,Manual_Rebate_Per_Unit__c,Select_Instance_Type__c,Primary_Email__c,Server_Connectivity__c,Sold_To_Sales_Organization__c,Apttus_Proposal__Product__r.Name,Apttus_Proposal__Product__r.ProductCode,
        Apttus_Proposal__Product__r.Bundle_Id__c,Apttus_Proposal__Product__r.Apttus_Config2__ConfigurationType__c,Apttus_Proposal__Product__r.Description,Apttus_Proposal__Product__r.Material_Type__c,Apttus_QPConfig__NetUnitPrice__c,
        Material_Class_Type__c,Shipping_In_Close_Quarter__c,Shipping_In_1Q_After_Close_Quarter__c,Shipping_In_2Q_After_Close_Quarter__c,Term_Months__c,Apttus_Proposal__Product__r.End_Of_Sale_Date__c,Control_Code_India_SAC__c,
        Commodity_Import_Code_India_HSN__c,Apttus_Proposal__Product__r.End_Of_Service_Date__c,Apttus_Proposal__Product__r.Material_Number__c,Apttus_QPConfig__OptionId__r.End_Of_Sale_Date__c,Apttus_QPConfig__OptionId__r.End_Of_Service_Date__c,
        Apttus_QPConfig__OptionId__r.Material_Number__c,Apttus_QPConfig__OptionId__r.Name,Product_Indicator__c,Apttus_Proposal__Proposal__r.Quote_Type__c,Apttus_Proposal__Proposal__r.Name,Apttus_Proposal__Product__r.Material_Class_Type__c,
        Registrant_Contact__r.PGUID__c,Registrant_Contact__r.Email,Custom_License_Setup_Required__c,Custom_Setup_Required__c,Open_Offer_Max__c,Trade_In_Type__c,Sales_Approval_Threshold__c,Median_Discount_Guidance__c,Max_Discount_Guidance__c,
        Submitter_Notes__c,Customer_Historical_Discount__c,Approval_Level_Product__c,Approval_Level_UC_Discount__c,Apttus_QPConfig__ExtendedPrice__c,Approval_Level_Record_Owner__c,Apttus_Proposal__Proposal__r.Transborder_Flag__c
        FROM Apttus_Proposal__Proposal_Line_Item__c
        WHERE Apttus_Proposal__Proposal__c IN :setQuoteIds
        ];
    }



    //CMCM-4516
    private static List<User> selectByUserId(Set<Id> setUserIds) {
        return [SELECT
            Id,
            Name,
            Email,
            Title,
            Department,
            EmployeeNumber,
            Username,
            Contact.AccountId,
            LastName,
            Profile.Name,
            Profile.UserLicense.Name,
            Contact.Name,
            Contact.Phone,
            Contact.Email,
            ProfileId,
            Manager_Email__c,
            AD_userName__c,
            AccountId,
            ManagerId,
            Manager.ProfileId,
            Manager.IsActive,
            Manager.ManagerId,
            Manager.DelegatedApproverId,
            Manager.Out_of_Office__c,
            UserType,
            Signature,
            DelegatedApproverId,
            Out_of_Office__c,
            IsPortalEnabled,
            User_Profile_Name__c, 
            IsActive,
            Contact.Account.Territory_Region__c,
            Contact.Account.SVMX_PS_Location__r.ERP_Customer_ID__c
        FROM User
        WHERE Id IN :setUserIds
        ];
        
    }

    /*
    *  @author       : Saurabh Brahmankar
    *  @description  : Public method createUrlWithParams created Fetch the mapping of Discount reason and discount definition from Custom metadata
    *  @param        : baseUrl, params
    *  @return       : url
    */    
    public static String createUrlWithParams(String baseUrl, Map<String, String> params) {
        String url = baseUrl;
        if (params != null && !params.isEmpty()) {
            // Append the initial '?' to start the query parameters
            url += '?';
            // Iterate over the map of parameters to append them to the URL
            for (String key : params.keySet()) {
                url += EncodingUtil.urlEncode(key, 'UTF-8') + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8') + '&';
            }
            // Remove the last '&' from the URL string
            url = url.substring(0, url.length() - 1);
        }
        return url;
    }
    
    /*
    *  @author       : Lovel Panchal
    *  @description  : Handle the cancel event in approval process. 
    *  @param        : Sobject, Id, Commnents
    *  @return       : Update the status in system
    */ 

    public PageReference handleCancel() {
        //Apttus_Approval.ApprovalsWebService.cancelApprovalsWithComments(APTTUS_PROPOSAL_PROPOSAL, strQuoteId ,strcomment);
        PageReference quotationPage = new PageReference('/' +strQuoteId);
        quotationPage.setRedirect(true);
        return quotationPage;   
        		//system.debug('Status of approval'+status); 
    }

    /*
    *  @author       : Lovel Panchal
    *  @description  : Handle the Comment event in approval process. 
    *  @param        : Request Id, Commnents
    *  @return       : Update the status in system
    */ 
    
    public void handleComment() {
        Boolean status=Apttus_Approval.ApprovalsWebService.addCommentsToRequest(objApprovalRequest.Id ,strcomment);
        //system.debug('Status of approval'+status); 
    }

    /*
    *  @author       : Lovel Panchal
    *  @description  : Handle the Attach File event in approval process. 
    *  @param        : Request Id, Commnents
    *  @return       : Update the status in system

    */ 

    public PageReference handleAttachFile() {
        String redirectUrl = '/apex/Apttus_Approval__approvalrequestattachment?id=' + objApprovalRequest.Id + '&pageMode=approveReject';
        PageReference pageRef = new PageReference(redirectUrl);
        pageRef.setRedirect(true);
        return pageRef;
        
    }


    /*
    *  @author       : Lovel Panchal
    *  @description  : Handle the Reject event in approval process. 
    *  @param        : Request Id, Commnents
    *  @return       : Update the status in system
    */ 

    public PageReference handleReject() {
        Boolean status=Apttus_Approval.ApprovalsWebService.rejectRequest(objApprovalRequest.Id ,strcomment);
        string redirectUrl = '/lightning/r/Apttus_Proposal__Proposal__c/'+strQuoteId+'/related/Apttus_QPApprov__ApprovalRequests__r/view';
        PageReference quotationApprovalPage = new PageReference(redirectUrl);
        quotationApprovalPage.setRedirect(true);
        return quotationApprovalPage;
        //system.debug('Status of approval'+status); 
    }

    /*
    *  @author       : Lovel Panchal
    *  @description  : Handle the Approve event in approval process. 
    *  @param        : Request Id, Commnents
    *  @return       : Update the status in system
    */ 

    public PageReference handleApprove() {
        Boolean status=Apttus_Approval.ApprovalsWebService.approveRequest(objApprovalRequest.Id ,strcomment); 
        string redirectUrl = '/lightning/r/Apttus_Proposal__Proposal__c/'+strQuoteId+'/related/Apttus_QPApprov__ApprovalRequests__r/view';
        PageReference quotationApprovalPage = new PageReference(redirectUrl);
        quotationApprovalPage.setRedirect(true);
        return quotationApprovalPage;
        //system.debug('Status of approval'+status); 
    }

    /*
    *  @author       : Akash Kumar
    *  @description  : Validate whether the user has access to read the message containing link to marginal analysis data
    *  @param        : Approval Request record in context
    *  @return       : Boolean - true when user has access to read the message containing link to marginal analysis data
    */ 
    public static Boolean showMarginalAnalysisMessage(Apttus_Approval__Approval_Request__c objApprovalRequest){
        
        Integer approvalLevel;
        Boolean boolShowMessage = false;
        Integer approvalThreshhold = Integer.valueOf(Code_Parameter__mdt.getInstance('Min_Approval_Level_To_View_Margin_Data').Values_Text__c);
        ilib_LogEvent.message('Approval Request Object :' +objApprovalRequest);
        if(String.isNotBlank(objApprovalRequest.Apttus_Approval__Step_Name__c) && objApprovalRequest.Apttus_Approval__Step_Name__c == Label.ApprovalStepNameCPQSalesApprovalRule){
            if(String.isNotBlank(objApprovalRequest.Apttus_Approval__StepLabel__c) && objApprovalRequest.Apttus_Approval__StepLabel__c.contains(Label.Finance_Level_Approver)){
                boolShowMessage = true;
            }
            else if(String.isNotBlank(objApprovalRequest.Apttus_Approval__StepLabel__c) && objApprovalRequest.Apttus_Approval__StepLabel__c.contains(Label.UI_Text_Level)){
                approvalLevel = Integer.valueOf(objApprovalRequest.Apttus_Approval__StepLabel__c.substringAfter(Label.UI_Text_Level ).trim());
                boolShowMessage = approvalLevel >= approvalThreshhold; 
            }
        }
        else if(String.isNotBlank(objApprovalRequest.Apttus_Approval__Step_Name__c) && objApprovalRequest.Apttus_Approval__Step_Name__c == Label.ApprovalStepNameCPQSalesTransborderRule){
            approvalLevel = Integer.valueOf(objApprovalRequest.Apttus_Approval__StepLabel__c);
            boolShowMessage = approvalLevel >= approvalThreshhold-1;
        }
        return boolShowMessage;
    }

}