/*@ author       : Vinay S Reddy
* @ date         : 24-07-2024
* @ Description  : Batch class to Data remediation - Discount Guidance for the Agreements created prior to DG Launch
 * 100% Code Coverage: 
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vinay S Reddy             24-07-2024             Initial version
 
*/
public class BatchToUpdateLargeAgmntLineItems implements Database.Batchable < sObject > {
    
    private static final String LOG_TITLE = 'BatchToUpdateLargeAgmntLineItems';
	  set<Id> agreementId = new set<Id>();
    
    
    public List<String> errors = new List<String>();
    public List < Database.SaveResult > saveResults = new List < Database.SaveResult > ();
    
    @TestVisible
    public static Boolean useOldFrameworkWhileTesting = true;
    
    /**
     * @author: Vinay S Reddy
     * @date: 24-07-2024
     * @description: 
     * @param: bc - batch context
     * @return: void
     */
    public BatchToUpdateLargeAgmntLineItems(){
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);
    }
    
    /**
     * @author: Vinay S Reddy
     * @date: 24-07-2024
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    public BatchToUpdateLargeAgmntLineItems(set<Id> agmntId){
        this.agreementId=agmntId;
    }
    
    /**
     * @author: Vinay S Reddy
     * @date: 24-07-2024
     * @description: Required start  method for batch
     * @param: bc - batch context
     * @return: void
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
         String strSoql ='Select Id,Agreement_Subtype__c,Apttus__ProductId__r.IsActive, Name,Agreement_Record_Type__c,Sales_Approval_Threshold__c,Approval_Matrix_Record_Owner__c,Line_Type__c,is_MFN_Line_Item__c,Is_MFN_TG_NextSeq_Consumable__c,Is_MFN_NovaSeq_Consumable__c,Is_MFN_NextSeq_RUO_Consumable__c,Discontinued__c,Discount__c,RecordTypeId,Apttus__ProductId__c,Line_Type_1__c,Distribution_Channel__c,Agreement_Distribution_Channel__c,Customer_ERP_Number__c,Ultimate_Consignee_ERP_Number__c,Sales_Org__c,CurrencyIsoCode,Material_Number__c,Material_Group_1__c,Apttus_CMConfig__StartDate__c,Discount_Grid_Group__c,Discount_Type__c,Agreement_Currency__c,Apttus_CMConfig__LineStatus__c,Do_Not_Run_Discount_Guidance__c, Max_Discount_Guidance__c,Customer_Historical_Discount__c, Median_Discount_Guidance__c,Apttus__AgreementId__c,Apttus__AgreementId__r.Apttus__Account__c from Apttus__AgreementLineItem__c Where  Apttus__AgreementId__c IN: agreementId and  Apttus__AgreementId__c !=null  AND Apttus_CMConfig__LineStatus__c!=\'Existing\' AND Apttus__ProductId__r.IsActive=TRUE';
		 return Database.getQueryLocator(strSoql);        
        
    }
    
    /**
     * @author: Vinay S Reddy
     * @date: 24-07-2024
     * @description: Required execute method for batch
     * @param: bc - batch context
     * @return: void
     */
     /*Execute method of Batch Class*/    
    public void execute(Database.BatchableContext bc, list < Apttus__AgreementLineItem__c > scope) {
    
       
        
        DiscountGuidancePopulatorForCLM populator = new DiscountGuidancePopulatorForCLM();
        populator.deriveFieldValuesForDiscountGuidance(scope, null);
        

            
        System.debug('Line items to be processed '+scope);
        
        //method for approval of agreements
        // approveAgreements(agreementId, scope);
       
        
        if (!scope.isEmpty()) {
            saveResults.addAll(Database.update(scope, false));
            handleSaveResults(saveResults, 'Agreement Line Items after Approval Selection', errors);
            ApexExceptions.emitSaveErrors(saveResults, LOG_TITLE );
    
}
    }
    
      /*  private void approveAgreements(set<Id> agmntIdToUpdateApprovalStatus, List < Apttus__AgreementLineItem__c > agreementLineItemList ) {
        
        //Approval setup
        List < Apttus__APTS_Agreement__c > listAgreementsFromIntialize = new List < Apttus__APTS_Agreement__c > ();
        listAgreementsFromIntialize = new ApttusAgreementSelectors().selectAgreements(agmntIdToUpdateApprovalStatus);   

            Boolean forceOldFramework = System.Test.isRunningTest() && useOldFrameworkWhileTesting;
        	if (Feature.isOn('SalesCLMApprovalsPipeline') && !forceOldFramework) {
            if (agreementLineItemList!=null && agreementLineItemList.size()>0) {
                Approvals.AgreementLineInputs approvalInputs = new Approvals.AgreementLineInputs(agreementLineItemList, new Map < Id, Apttus__APTS_Agreement__c > (listAgreementsFromIntialize));
                    IApprovalsAPI approvals = ApprovalsService.init(approvalInputs);
                	System.Debug('Test 1 '+approvals);
                	
                	
                    System.debug('Test 2 '+approvals.processAgreementLines());
                     approvals.processAgreementLines();
            	
                }
             } 

       }   */
    /**
     * @author: Vinay S Reddy
     * @date: 24-7-2024
     * @description: 
     * @param: bc - batch context
     * @return: void
     */
            // Method to handle save results and errors
    private void handleSaveResults(List < Database.SaveResult > saveResults, String objectType, List < String > errors) {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        for (Database.SaveResult saveResult: saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error e: saveResult.getErrors()) {
                    errors.add(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    System.debug(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    ilib_LogEvent.info(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    System.debug(objectType + ' fields that affected this error: ' + e.getFields());
                    ilib_LogEvent.info(objectType + ' fields that affected this error: ' + e.getFields());
                    System.debug(objectType + ' record that affected this id: ' + saveResult.getId());
                    ilib_LogEvent.info(objectType + ' record that affected this id: ' + saveResult.getId());
                }
             }
            if (saveResult.isSuccess()) {
                System.debug('Success Status for Agreements/Agreement Line Items   ' + saveResult);
                ilib_LogEvent.info('Success Status for Agreements/Agreement Line Items   ' + saveResult);
             }
         }
         ilib_LogEvent.pop();
         ilib_LogEvent.emit(); 

    }

    /**
     * @author: Vinay S Reddy
     * @date: 24-07-2024
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    public void finish(Database.BatchableContext bc) {
       // finish method logic
       // 
    }
}