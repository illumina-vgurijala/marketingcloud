/**
*    @author Akshay Mohan
*    @date   2021-05-06
*    @description    DCP-38809: Auto generate quote
*    @Test Class for 75% Coverage : TestQuoteGenerationQueueable
*    @Test Class for 90% Coverage : TestQuoteGenerationQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          Initial Version
*         Akshay Mohan            2021-05-24          DCP-39386:Add logic for failure notification in case of template not found
*         Dushyant Srivastava     2021-09-15          DCP-49598: Add logic to send email in case of Generate Success scenario
*         Khushbu Vasani          2022-02-25          INC0361545 : When document name is greater than 80, split to 30 chars and add delimiter  
*         Anshaj Sinha            2022-09-16          CMSI-204 Instrumented class with latest changes in Logging Framework
*         Saddam                  08-Dec-2022         Codescan Fix , Varaible naming convention. 
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class QuoteGenerationQueueable implements IOpportunityQuoteAutomation {
    private static boolean runOnce = true;
    private Id idQuotation,idQuoteOutput;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVED;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'QuoteGenerationQueueable';
    private static final string LONGFILENAMEDELIMITER = '...'; 
    public Boolean catchException = false;

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return Id of quote
	**/
    public Id getRecordId(){
        return idQuoteOutput;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Id of Quote
	*	@return void
	**/
    public void setRecordId(String idQuotation){
        this.idQuotation = idQuotation;    
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return OpportunityQuoteAutomationQueueable.EmailWrapper
	**/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.getErrorDetails()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED) ? Label.OpportunityQuoteAutomation_QUOTE_GENERATION_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
        ValidateQuoteAutomation.handleErrorValidateApproval(idQuotation,wrapDetails);
        ilib_LogEvent.pop();
        return wrapDetails;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext context){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            Apttus_Proposal__Proposal__c objProposal=new ApttusProposalsSelector().selectById(new Set<Id>{idQuotation}).get(0);
            ilib_LogEvent.info('Generate SAP call successfull'); 
            Id idTemplate =getTemplateId(objProposal);
            ilib_LogEvent.info('idTemplate: '+idTemplate); 
            if(idTemplate==null){
                //DCP-39386
                status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED;
                ilib_LogEvent.pop(); 
                ilib_LogEvent.emit();
                return;
            }

            String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/'+UtilsRest.APEX_SOAP_WEBSERVICE_VERSION+ '/' + UserInfo.getOrganizationId();
            ilib_LogEvent.info('apiServerURL: '+apiServerURL); 
                
            String generatedDocId = Test.isRunningTest()? null : Apttus_Proposal.MergeWebService.generateDoc(idTemplate, objProposal.id, 'Read only', 'PDF', UserInfo.getSessionId(), apiServerURL);
            ilib_LogEvent.info('generatedDocId: '+generatedDocId); 
            if(String.isNotBlank(generatedDocId) || Test.isRunningTest()){
                Attachment objAttachment= Test.isRunningTest()? new Attachment(Name='Test') : new AttachmentsSelector().selectById(new Set<String>{generatedDocId}).get(0);
                Apttus_Proposal__DocumentCollateInfo__c objDocumentCollateInfo = new Apttus_Proposal__DocumentCollateInfo__c();
                //INC0361545 : When document name is greater than 80, split to 30 chars and add delimiter as document collate info name is max 80 chars
                ilib_LogEvent.info('objAttachment.Name : '+objAttachment.Name);
                if(objAttachment.Name.length() > 80)
                {
                    objDocumentCollateInfo.Name = objAttachment.Name.left(30) + LONGFILENAMEDELIMITER + objAttachment.Name.right(30);
                }
                else
                {
                	objDocumentCollateInfo.Name = objAttachment.Name;
                }
                objDocumentCollateInfo.Apttus_Proposal__ProposalId__c = idQuotation;
                insert objDocumentCollateInfo;
                objDocumentCollateInfo.Apttus_Proposal__RelatedAttachmentId__c = generatedDocId;
                update objDocumentCollateInfo;//update to sync files
                idQuoteOutput=idQuotation;
                status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATED;
                //DCP-49598
                if(String.isNotBlank(objProposal.Work_Order__c)){
                    sendQuoteGenerateSuccessEmail(objProposal.id , objAttachment);
                }
               // end of DCP-49598
            }else{
                status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED;
            }
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
            }
        }catch(Exception e){
            ilib_LogEvent.info('Exception Message : '+e.getMessage());
            ilib_LogEvent.pop(); 
            ilib_LogEvent.emit();
            ApexExceptions.emit(LOG_TITLE,idQuotation,e, ilib_LogEvent.SALES);
        }
        ilib_LogEvent.pop(); 
        ilib_LogEvent.emit();
    }
    

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Apttus_Proposal__Proposal__c
	*	@return Template Id
	**/
    public Id getTemplateId(Apttus_Proposal__Proposal__c objProposal){
        ilib_LogEvent.push(LOG_TITLE + '.getTemplateId()');
        ApttusQueryTemplateQualifierSelector qtqSelector = new ApttusQueryTemplateQualifierSelector();
        List<Apttus__QueryTemplateQualifier__c> lstRegionQTQ = qtqSelector.selectQuoteTemplatesByTerritory(objProposal.Territory_Region__c);
        ilib_LogEvent.info('lstRegionQTQ: '+lstRegionQTQ);
        ilib_LogEvent.info('lstRegionQTQ size: '+lstRegionQTQ.size()); 
        if(lstRegionQTQ.isEmpty()){
            ilib_LogEvent.info('No Template in region');
            ilib_LogEvent.pop();
            return null;
        }
        String strQuery = 'SELECT Id,Name';
        Set<String> setFields=new Set<String>{'Id','Name'};
        Map<Id,List<Apttus__QueryTemplateQualifier__c>> queryTemplateIdTolstQTQs=new Map<Id,List<Apttus__QueryTemplateQualifier__c>>();
        List<Id> lstOrderedQTQ = new List<Id>();
        
        for(Apttus__QueryTemplateQualifier__c objqtq:
                qtqSelector.selectByQueryTemplateIds(UtilsCollection.getSetOfIds(lstRegionQTQ,'Apttus__QueryTemplate__c'))
        ){
            if(!setFields.contains(objqtq.Apttus__Field__c)){
                strQuery+=','+objqtq.Apttus__Field__c;
                setFields.add(objqtq.Apttus__Field__c);
            }
            
            List<Apttus__QueryTemplateQualifier__c> lstQTQs;
            if(queryTemplateIdTolstQTQs.containsKey(objqtq.Apttus__QueryTemplate__c)){
                lstQTQs=queryTemplateIdTolstQTQs.get(objqtq.Apttus__QueryTemplate__c);
            }else{
                lstQTQs=new List<Apttus__QueryTemplateQualifier__c>();
                queryTemplateIdTolstQTQs.put(objqtq.Apttus__QueryTemplate__c,lstQTQs);
                lstOrderedQTQ.add(objqtq.Apttus__QueryTemplate__c);
            }
            lstQTQs.add(objqtq);
        }
        strQuery+=' FROM Apttus_Proposal__Proposal__c WHERE Id=:idQuotation';
        ilib_LogEvent.info('strQuery: '+strQuery); 
        Apttus_Proposal__Proposal__c objProposalWithQTQValues = (Apttus_Proposal__Proposal__c)Database.query(strQuery).get(0);
        ilib_LogEvent.info('objProposalWithQTQValues: '+objProposalWithQTQValues); 
        ilib_LogEvent.info('lstOrderedQTQ: '+lstOrderedQTQ); 
        ilib_LogEvent.info('queryTemplateIdTolstQTQs keySet: '+queryTemplateIdTolstQTQs.keySet()); 
        Id idMatchingQueryTemplate=getQueryTemplateId(lstOrderedQTQ,queryTemplateIdTolstQTQs,objProposalWithQTQValues);
        if(idMatchingQueryTemplate==null){
            ilib_LogEvent.info('No idQueryTemplate matching');
            ilib_LogEvent.pop(); 
            return null;
        }
        
        ilib_LogEvent.pop();
        return getTemplateId(idMatchingQueryTemplate);
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param List<Id> lstOrderedQTQ,Map<Id,List<Apttus__QueryTemplateQualifier__c>> queryTemplateIdTolstQTQs, Apttus_Proposal__Proposal__c objProposalWithQTQValues
	*	@return Id
	**/
    private Id getQueryTemplateId(List<Id> lstOrderedQTQ,Map<Id,List<Apttus__QueryTemplateQualifier__c>> queryTemplateIdTolstQTQs, Apttus_Proposal__Proposal__c objProposalWithQTQValues){
        ilib_LogEvent.push(LOG_TITLE + '.getQueryTemplateId()');
        Id idMatchingQueryTemplate=null;
        for(Id idQueryTemplate : lstOrderedQTQ){
            Boolean boolFailed=false;
            for(Apttus__QueryTemplateQualifier__c objQTQ : queryTemplateIdTolstQTQs.get(idQueryTemplate)){
                ilib_LogEvent.message('objQTQ: '+objQTQ); 
                if(!evaluateQualifier(UtilsObject.getDeepStringFromObject(objProposalWithQTQValues,objQTQ.Apttus__Field__c),objQTQ.Apttus__CompOper__c,objQTQ.Apttus__Value__c)){
                    boolFailed=true;
                    break;
                }
            }
            if(!boolFailed){
                idMatchingQueryTemplate=idQueryTemplate;
                ilib_LogEvent.info('idQueryTemplate matching: '+idQueryTemplate); 
                break;
            }
        }
        ilib_LogEvent.pop();
        return idMatchingQueryTemplate;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Id idQueryTemplate
	*	@return Id
	**/
    private Id getTemplateId(Id idQueryTemplate){
        ilib_LogEvent.push(LOG_TITLE + '.getTemplateId()');
        List<Apttus__QueryTemplateFilter__c> lstQTF= new ApttusQueryTemplateFilterSelector().selectByQueryTemplateIds(new Set<Id>{idQueryTemplate});
        if(lstQTF.isEmpty() || lstQTF.size()>1){
            ilib_LogEvent.info('Multiple or no filters found: '+lstQTF); 
            ilib_LogEvent.pop();
            return null;
        }
        Apttus__QueryTemplateFilter__c objQTF = lstQTF.get(0);
        String strQuery = 'SELECT Id FROM Apttus__APTS_Template__c WHERE ';

        switch on objQTF.Apttus__CompOper__c{
            
            when 'not equal to'{
                strQuery+=objQTF.Apttus__Field__c+'<> \''+objQTF.Apttus__Value__c+'\'';
            }
            when 'in'{
                strQuery+=objQTF.Apttus__Field__c+' IN ('+getCommaSeperatedValues(objQTF.Apttus__Value__c)+')';
            }
            when 'not in'{
                strQuery+=objQTF.Apttus__Field__c+' NOT IN ('+getCommaSeperatedValues(objQTF.Apttus__Value__c)+')';
            }
            when 'like','contains'{
                strQuery+=objQTF.Apttus__Field__c+' LIKE \'%'+objQTF.Apttus__Value__c+'%\'';
            }
            when 'not like','does not contain'{
                strQuery+='(NOT '+objQTF.Apttus__Field__c+' LIKE \'%'+objQTF.Apttus__Value__c+'%\')';
            }
            when 'includes'{
                strQuery+=objQTF.Apttus__Field__c+' INCLUDES ('+getCommaSeperatedValues(objQTF.Apttus__Value__c)+')';
            }
            when 'excludes'{
                strQuery+=objQTF.Apttus__Field__c+' EXCLUDES ('+getCommaSeperatedValues(objQTF.Apttus__Value__c)+')';
            }
            when 'starts with'{
                strQuery+=objQTF.Apttus__Field__c+' LIKE \''+objQTF.Apttus__Value__c+'%\'';
            }
            when 'equal to'{
                strQuery+=objQTF.Apttus__Field__c+'= \''+objQTF.Apttus__Value__c+'\'';
            }
        }
        ilib_LogEvent.info('strQuery: '+strQuery); 
        List<Apttus__APTS_Template__c> lstTemplate = (List<Apttus__APTS_Template__c>)Database.query(strQuery);
        ilib_LogEvent.info('lstTemplate: '+lstTemplate); 
        if(lstTemplate.isEmpty() || lstTemplate.size()>1){
            ilib_LogEvent.info('Multiple/no templates found: '+lstTemplate); 
            ilib_LogEvent.pop(); 
            return null;
        }

        ilib_LogEvent.pop();
        return lstTemplate.get(0).Id;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param String strRecordValue, String strComparator, String strQualifierValue
	*	@return Boolean
	**/
    private String getCommaSeperatedValues(String strMainString){
        String strConcatValue='';
        Boolean boolFirst=true;
        for(String strValue: strMainString.split(',')){
            if(boolFirst){
                boolFirst=false;
                strConcatValue+='\''+strValue+'\'';
            }else{
                strConcatValue+=',\''+strValue+'\'';
            }
        }
        return strConcatValue;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param String strRecordValue, String strComparator, String strQualifierValue
	*	@return Boolean
	**/
    private Boolean evaluateQualifier(String strRecordValue, String strComparator, String strQualifierValue){
        Boolean boolSatisfied=false;
        switch on strComparator{
            when 'equal to'{
                boolSatisfied=strRecordValue==strQualifierValue;
            }
            when 'not equal to'{
                boolSatisfied=strRecordValue!=strQualifierValue;
            }
            when 'in'{
                boolSatisfied = new Set<String>(strQualifierValue.split(',')).contains(strRecordValue);
            }
            when 'not in'{
                boolSatisfied=!(new Set<String>(strQualifierValue.split(',')).contains(strRecordValue));
            }
            when 'like','contains'{
                boolSatisfied = strRecordValue!=null && strRecordValue.contains(strQualifierValue);
            }
            when 'not like','does not contain'{
                boolSatisfied = !(strRecordValue!=null && strRecordValue.contains(strQualifierValue)) || strRecordValue==null;
            }
            when 'includes'{
                boolSatisfied=new Set<String>(strRecordValue.split(',')).contains(strQualifierValue);
            }
            when 'excludes'{
                boolSatisfied=!(new Set<String>(strRecordValue.split(',')).contains(strQualifierValue));
            }
            when 'starts with'{
                boolSatisfied=strRecordValue!=null && strRecordValue.startsWith(strQualifierValue);
            }
            
        }
        ilib_LogEvent.info('Returning Boolean Value From evaluateQualifier : '+boolSatisfied);
        return boolSatisfied;
    }
    

    /** DCP-49598
	*	@author Dushyant Srivastava
	*	@param Apttus_Proposal__Proposal__c objProposal
	*	@return void
	**/
    public void sendQuoteGenerateSuccessEmail(Id objProposalId , Attachment objAttachment) {

        ilib_LogEvent.push(LOG_TITLE + '.sendQuoteGenerateSuccessEmail()');

        if(status == OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATED && runOnce) {
            runOnce = false;
            Map<Id,Apttus_Proposal__Proposal__c> idToProposalMap = new Map<Id,Apttus_Proposal__Proposal__c>(new ApttusProposalsSelector().selectByQuoteId(new Set<Id>{objProposalId}));
            Attachment atch = objAttachment;
            Map<Id,Attachment> proposalIdToDocumentMap = new Map<Id,Attachment>();
            proposalIdToDocumentMap.put(objProposalId,atch);
            SendEmailToQuoteOwnersQueueable.sendEmailMessages(proposalIdToDocumentMap,idToProposalMap);
            ilib_LogEvent.pop();
        }
    }
}