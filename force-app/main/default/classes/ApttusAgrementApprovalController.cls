/* @author : Umesh Mor
* @date   : 2020-01-13
* @description : DCP-31142  :Email notification for All Agreement approval process(Except for Channel Partner & Negotiated T&C's)
* Modification Log:
* ------------------------------------------------------------------------------
* Developer                      Date                Description
* Umesh Mor                   2020-1-24           Modified previewAgreements() methods as part of DCP-31177 - Channel Partner Approval Notification
* Prabhsimran Singh           2020-3-4            Modified previewAgreements() method as part of DCP-35369.
* Prabhsimran Singh           2020-17-06          Modified previewAgreements() method as part of DCP-38285.
* Joshith k                  10-July-2020         TASK0493822-- show warning message if line items count is more than 50.
* Prem Ranjan                15-July-2022          DCP-52704-Ability to Access New Tableau Dashboard from Approval Request Emails.
*/
public with sharing class ApttusAgrementApprovalController {
    public List<Apttus_Approval__Approval_Request__c> lstApprovalRequest{get;set;}
    public List<ApprovalRequestWrapper> lstApprovalRequestWrapper {get;set;}
    public Map<String,ApprovalRequestWrapper> stringToApprovalRequestWrap;
    public Map<Id,String> idToUserTitle;
    public String strAgreementUrl{get;set;}
    public String strTableauLink{get;set;}//DCP-52704
    public String strBaseURL{get;set;}
    public String strApproveRejectURL{get;set;}
    public String strCommentURL{get;set;}
    public Apttus_Approval__Approval_Request__c objApprovalRequest{set;get;}
    public List<Apttus_Approval__Approval_Request__c> lstPreviousApprover{get;set;}
    public List<Apttus_Approval__Approval_Request__c> lstNextApprover{get;set;}
    public String strPreviousApproverName='';
    public String strNextApproverName='';
    public String strRegion;
    public string strEmailType{get;set;}
    public String strAgreementId{get;set;}
    public List<Apttus__APTS_Agreement__c> lstAgreement{get;set;}
    public List<Apttus__APTS_Agreement__c> lstNonNogotiatedAgreements{get;set;}
    public List<Apttus__APTS_Agreement__c> lstInitialAgreements{get;set;}
    public List<Agreement_Account_Relationship__c> lstAgreementAccountRelationships{get;set;}
    public List<Apttus__AgreementLineItem__c> lstChanlPrtnNonQuotaAgrmentLinItem {get;set;}
    public List<Apttus__AgreementLineItem__c> lstChanlPrtnQuotaAgrmentLinItem {get;set;}
    public Apttus__APTS_Agreement__c objAgreement{get;set;}
    public List<Apttus__AgreementLineItem__c> lstAgreementLineItem{get;set;}
    public boolean channelPartnerLineItemData {get;set;}
    public boolean nonNegotiatedTnCRecordType =false;
	public List<Apttus__AgreementLineItem__c> lstStandardNonQuotaAgrmentLinItem{get;set;}
    public List<Apttus__Agreement_Clause__c> lstAgrmtClause{get;set;}
    public List<Apttus__Agreement_Clause__c> lstAgreementClause{get;set;}
    public final string HTTPHEADER = 'https://';
    public boolean showWarning{get;set;}
    public boolean boolOpenOffer{get;set;}
    public boolean boolAffiliatesAvailable{get;set;}
    public boolean boolAgreementIsOpenOffer{get;set;}
    public final Integer MAXLINESTOSHOW = 50;
    public string componentUrl{get;set;}
     /*
    *  @author       : Umesh Mor
    *  @description  : Below is tehe constructor 
    *  @param        : NA
    *  @return       : 
    */
    public ApttusAgrementApprovalController(){
        lstChanlPrtnNonQuotaAgrmentLinItem = new   List<Apttus__AgreementLineItem__c>(); 
        lstChanlPrtnQuotaAgrmentLinItem = new   List<Apttus__AgreementLineItem__c>(); 
        lstNonNogotiatedAgreements = new List<Apttus__APTS_Agreement__c>();
        lstInitialAgreements = new List<Apttus__APTS_Agreement__c>();
        channelPartnerLineItemData =false;
		lstAgreementClause = new List<Apttus__Agreement_Clause__c>();
        lstAgreementAccountRelationships = new List<Agreement_Account_Relationship__c>();	
        lstStandardNonQuotaAgrmentLinItem = new List<Apttus__AgreementLineItem__c>();
        boolOpenOffer = false;
        boolAffiliatesAvailable = false;
        boolAgreementIsOpenOffer = false;
    }
    /*
    *  @author       : Umesh Mor
    *  @description  : To create Agreement records and display on the page
    *  @param        : NA
    *  @return       : 
    */
    public string getLoadAgreementData(){
        previewAgreements();
        return '';
    }

    /*
    *  @author       : Aman Tyagi
    *  @description  : get agreement record based on record Id
    *  @param        : NA
    *  @return       : String
    */
    public string getLoadAgreementRecord() {
        strAgreementId = strAgreementId != null ? strAgreementId : (Id)ApexPages.currentPage().getParameters().get('sObjectId').escapeHtml4();
        lstInitialAgreements = new ApttusAgreementSelectors().selectAgreements(new Set<Id>{strAgreementId});
        
        if(lstInitialAgreements != null && !lstInitialAgreements.isEmpty()) {
            boolAgreementIsOpenOffer = lstInitialAgreements[0].RecordType.DeveloperName == Label.AgreementRecordTypeDevNameOpenOffer ? true : false;
        }
        return '';
    } 
    /*
    *  @author       : Aman Tyagi
    *  @description  : generate hyperlinks to be used in HTML
    *  @param        : NA
    *  @return       : void
    */
    public void generateHyperLinks() {
        strBaseURL = System.URL.getSalesforceBaseUrl().getHost();
        strAgreementUrl = HTTPHEADER +strBaseURL+'/'+strAgreementId; 
        strTableauLink = HTTPHEADER +'tableau.illumina.com/#/site/Commercial/views/StandingQuoteApproval/AgreementReview?TargetAgreement='+strAgreementId; //DCP-52704
        strApproveRejectURL = HTTPHEADER+strBaseURL+'/apex/Apttus_Approval__ApprovalSummaryLaunch?id='+objApprovalRequest.Id+'&pageMode=approveReject';
        strCommentURL = HTTPHEADER+strBaseURL+'/apex/Apttus_Approval__ApprovalSummaryLaunch?id='+objApprovalRequest.Id+'&pageMode=addComment';
        componentUrl=HTTPHEADER +strBaseURL+'/lightning/cmp/c__ApttusAgreementLinesNav?c__agreementId='+strAgreementId;
    }

    /*
    *  @author       : Aman Tyagi
    *  @description  : get open offer agreement record based on record Id
    *  @param        : NA
    *  @return       : String
    */
    public string getLoadAgreementOpenOfferRecord() {
        if(!lstAgreement.isEmpty()) {
            lstAgreementAccountRelationships = new AgreementAccountRelationshipSelectors().selectByAgreementIdAndOpenOffer(new Set<Id>{strAgreementId});
            boolAffiliatesAvailable = lstAgreementAccountRelationships == null || lstAgreementAccountRelationships.isEmpty() ? false : true;
        }
        generateHyperLinks();
        return '';
    }

    /*
    *  @author       : Umesh Mor
    *  @description  : To create Agreement records and display on the page
    *  @param        : NA
    *  @return       : 
    */
    public void previewAgreements(){
        Set<Id> nonNegoatedAgreementIds = new Set<Id>();
        showWarning=false;
        if(Test.isRunningTest()) {
            lstAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<Id>{strAgreementId});
        }
        if(!lstAgreement.isEmpty()){
            objAgreement = lstAgreement.get(0);
            for(Apttus__APTS_Agreement__c agrm : lstAgreement){ //Modified for DCP - 31177 
               
                if(agrm.RecordType.DeveloperName== Label.UI_Label_Channel_Partner_Agreement){
                     channelPartnerLineItemData =true;   
                }
                if(agrm.RecordType.DeveloperName != Label.UI_Label_Negotiated_Terms_and_Conditions){
                      lstNonNogotiatedAgreements.add(agrm);
                      nonNegoatedAgreementIds.add(agrm.Id);
                }
                if(agrm.Number_Of_Agreement_Line_Items__c>MAXLINESTOSHOW)
                    showWarning=true;
            }
        }
        generateHyperLinks();
        if(!showWarning){
            lstAgreementLineItem = new ApttusAgreementLineItemSelectors().selectAgreementLineItemSorted(nonNegoatedAgreementIds,NULL,NULL);
        }else{
            lstAgreementLineItem = new ApttusAgreementLineItemSelectors().selectAgreementLineItemSorted(nonNegoatedAgreementIds,MAXLINESTOSHOW,NULL);
            
        }
        
			//Modified for DCP - 31177 , 35369
        if(!lstAgreementLineItem.isEmpty()){
                for(Apttus__AgreementLineItem__c agglItems : lstAgreementLineItem ){
                   if(agglItems.Apttus__AgreementId__r.RecordType.DeveloperName== Label.UI_Label_Channel_Partner_Agreement && agglItems.Line_Type__c !=Label.UI_Label_Quota 
				   && agglItems.Discontinued__c != Label.UI_Label_Yes)
                        lstChanlPrtnNonQuotaAgrmentLinItem.add(agglItems);
                   else if(agglItems.Apttus__AgreementId__r.RecordType.DeveloperName == Label.UI_Label_Channel_Partner_Agreement && agglItems.Line_Type__c ==Label.UI_Label_Quota)
                        lstChanlPrtnQuotaAgrmentLinItem.add(agglItems); 
				   else if(agglItems.Apttus__AgreementId__r.RecordType.DeveloperName != Label.UI_Label_Channel_Partner_Agreement && agglItems.Line_Type__c !=Label.UI_Label_Quota	
                           && agglItems.Discontinued__c != Label.UI_Label_Yes)	
                        lstStandardNonQuotaAgrmentLinItem.add(agglItems);	
               }	
        }
        //End of DCP - 31177 modification
		  //Added for DCP - 35369 	
		  
        lstAgrmtClause = new ApttusAgreementClauseSelectors().selectByAgreementId(new Set<Id>{strAgreementId});        	
        if(!lstAgrmtClause.isEmpty()){	
            for(Apttus__Agreement_Clause__c aggClause : lstAgrmtClause ){ 	
               if(aggClause.Approval_Status__c == Label.UI_Label_Approval_Required ||
                   aggClause.Approval_Status__c == Label.UI_Label_Pending_Approval)
                {	
                    lstAgreementClause.add(aggClause);	
               }                	
           }	
        }        	
        //End of DCP - 35369
        lstApprovalRequest = new ApttusApprovalRequestsSelector().selectByAgreementId(nonNegoatedAgreementIds);
        Set<Id> setUserId = new Set<Id>();
        lstPreviousApprover = new List<Apttus_Approval__Approval_Request__c>();
        lstNextApprover = new List<Apttus_Approval__Approval_Request__c>();
        for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest){
           if(!String.isEmpty(objAppReq.Apttus_Approval__Assigned_To_Id__c)){
                setUserId.add(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                if(objApprovalRequest!=null){
                    if(objApprovalRequest.Id != objAppReq.Id && !strNextApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && (objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusAssigned || objAppReq.Apttus_Approval__Approval_Status__c == Label.ApprovalRequestApprovalStatusNotSubmitted)){ 
                        lstNextApprover.add(objAppReq);
                        strNextApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                    }else if(!strPreviousApproverName.contains(objAppReq.Apttus_Approval__Assigned_To_Name__c) && objAppReq.Apttus_Approval__Approval_Status__c == Label.AgreementApprovalStatusApproved){
                        lstPreviousApprover.add(objAppReq);
                        strPreviousApproverName += objAppReq.Apttus_Approval__Assigned_To_Name__c +',';
                    }
                }
            }
        }
        idToUserTitle = new Map<Id,String>();
        for(User objUser: new UsersSelector().selectByUserId(setUserId)){
            idToUserTitle.put(objUser.Id, objUser.Title);
        }
        stringToApprovalRequestWrap = new Map<String,ApprovalRequestWrapper>();
        lstApprovalRequestWrapper = new List<ApprovalRequestWrapper>();
        
        map<string,integer> stepApproverNameToIntMap = new map<string,integer>();
        if(!lstApprovalRequest.isEmpty()){
            for(Apttus_Approval__Approval_Request__c objAppReq : lstApprovalRequest){
                strRegion = objAppReq.Apttus_Approval__Related_Agreement__r.Region__c!=null?objAppReq.Apttus_Approval__Related_Agreement__r.Region__c:null;
                String strApproverDetail = objAppReq.Apttus_Approval__Assigned_To_Name__c;
                String strApprovalLabel = objAppReq.Apttus_Approval__StepLabel__c;
                String strApprovalStepName = objAppReq.Apttus_Approval__Step_Name__c;
                if(idToUserTitle.containsKey(objAppReq.Apttus_Approval__Assigned_To_Id__c) && idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c) != null)
                strApproverDetail = strApproverDetail + ', ' + idToUserTitle.get(objAppReq.Apttus_Approval__Assigned_To_Id__c);
                //Update Logic DCP-38285
                if(!stepApproverNameToIntMap.isEmpty() && stepApproverNameToIntMap.containsKey(strApproverDetail + objAppReq.Apttus_Approval__Sequence__c)){
                    stepApproverNameToIntMap.put(strApproverDetail + objAppReq.Apttus_Approval__Sequence__c,stepApproverNameToIntMap.get(strApproverDetail + objAppReq.Apttus_Approval__Sequence__c)+1);
                }
                else{
                    stepApproverNameToIntMap.put(strApproverDetail + objAppReq.Apttus_Approval__Sequence__c,1);
                }
                
                String strStepName;
                strStepName = objAppReq.Apttus_Approval__Step_Name__c;                
                if(!stringToApprovalRequestWrap.containsKey(strStepName+strRegion)){
                    stringToApprovalRequestWrap.put(strStepName+strRegion,new ApprovalRequestWrapper(Integer.valueOf(objAppReq.Apttus_Approval__StepSequenceString__c.substringBefore('.')),strStepName,objAppReq,strApproverDetail,strRegion,false,false,false));
                    lstApprovalRequestWrapper.add(stringToApprovalRequestWrap.get(strStepName+strRegion));
                }else{
                    ApprovalRequestWrapper objApprovalRequestWrapper = new ApprovalRequestWrapper();
                    objApprovalRequestWrapper = stringToApprovalRequestWrap.get(strStepName+strRegion);
                    
                    if(objApprovalRequestWrapper != null && !stepApproverNameToIntMap.isEmpty() 
                       && stepApproverNameToIntMap.containsKey(strApproverDetail+objAppReq.Apttus_Approval__Sequence__c) && 
                       stepApproverNameToIntMap.get(strApproverDetail+objAppReq.Apttus_Approval__Sequence__c) == 1)
                     {
                        if(UtilsSettings.CPQCLM_RO_Approver_Steps.contains(strStepName)){
							objApprovalRequestWrapper.lstApprovalSequence.add(String.valueOf(integer.valueof(objAppReq.Apttus_Approval__Sequence__c) + 1));
                            //objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                        }
                        else if (objAppReq.Apttus_Approval__Step_Name__c.contains(Label.ApprovalStepNameCPQSalesApprovalRule)) { //CMCM-4444
                            //objApprovalRequestWrapper.lstApproverName.add(strApproverDetail);
                            objApprovalRequestWrapper.lstApprovalLabel.add(strApprovalLabel);
                            objApprovalRequestWrapper.lstApprovalStepName.add(strApprovalStepName);
                        } 
                        else{
                            objApprovalRequestWrapper.lstApprovalSequence.add(objAppReq.Apttus_Approval__Sequence__c);
                        }
                        objApprovalRequestWrapper.lstApproverName.add(strApproverDetail); //Added by saswati : regression issue
                     }
                }
            }
        }
    }
}