/*@ author       : Vinay S Reddy
* @ date         : 26-06-2024
* @ Description  : Batch class to Data remediation - Discount Guidance for the Agreements created prior to DG Launch
 * 100% Code Coverage: 
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Vinay S Reddy             26-06-2024             Initial version
 * Pradeep L                 04-07-2024             Refactoring
*/

public class BatchToUpdateAgreementsCreatedPriorToDG implements Database.Batchable < sObject >, Database.Stateful {

    //private list < String > companyNameList = new list < String > {'a2gWH0000005i21YAA'};
    //private final static String APPREQ = 'Approval Required';
    private final static String PENDAPP = 'Pending Approval';
    Set<Id> agreementIds = new Set<Id>();
	
    List < Apttus__AgreementLineItem__c > agreementLineItemList = new List < Apttus__AgreementLineItem__c > ();
    Id idofAgreementsToRecallToRequest,idofAgreementsToCanelApprovals,idofAgreementsForApproval;

        private List<String> errors = new List<String>();
     public List < Database.SaveResult > saveResults = new List < Database.SaveResult > ();
    
    private static final String LOG_TITLE = 'BatchToUpdateAgreementsCreatedPriorToDG';
	set<Id> agmntIdtoprocessLargeLines = new set<Id>();
    /**
     *  @author Pradeep L
     *  @description Constructor
     **/
    public BatchToUpdateAgreementsCreatedPriorToDG(Set<Id> agreementIdSet) {
        this.agreementIds = agreementIdSet; 
    }

    /**
     *  @author Pradeep L
     *  @description Constructor default
     **/
    public BatchToUpdateAgreementsCreatedPriorToDG() {
     // setting workstream
     ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);  
    }
    
    @TestVisible
    private static Boolean useOldFrameworkWhileTesting = true;
    /**
     * @author:Vinay S Reddy
     * @date: 26-08-2024
     * @description: Required start method for batch
     * @param: bc - batch context 
     * @return: query
     */
  
        
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String strSoql = 'Select Id, Name,Number_Of_Agreement_Line_Items__c,Apttus__Account__c,Apttus__Status_Category__c,Apttus__Status__c,Apttus_Approval__Approval_Status__c,Created_Date__c,Agreement_End_Date__c,Apttus__Activated_Date__c,Related_Agreement__c,Record_Type__c,Apttus__Subtype__c From Apttus__APTS_Agreement__c Where ' +
            ' Apttus__Status_Category__c  IN (\'Request\', \'In Authoring\', \'In Signatures\', \'In Filing\') and Apttus_Approval__Approval_Status__c IN (\'Approval Required\', \'Pending Approval\', \'Rejected\', \'Cancelled\') And Number_Of_Agreement_Line_Items__c > 0 AND ( Record_Type__c !=\'Open Offer Agreement\' AND (Record_Type__c !=\'Special Programs\' AND Apttus__Subtype__c != \'Reagent Rentals\')) dynamicAgreementIds';
            if(agreementIds?.size()>0){
                strSoql = strSoql.replace('dynamicAgreementIds', ' AND Id IN : agreementIds');
            }else{
                strSoql = strSoql.replace('dynamicAgreementIds', '');
            }
            return Database.getQueryLocator(strSoql);   
        }

    /**
     * @author: Vinay S Reddy
     * @date: 26-08-2024
     * @description: Required execute method for batch
     * @param: bc - batch context
     * @return: void
     */    

    /*Execute method of Batch Class*/    
    public void execute(Database.BatchableContext bc, list < Apttus__APTS_Agreement__c > scope) {
        agreementLineItemList = new List < Apttus__AgreementLineItem__c > ();
        List < Database.SaveResult > saveResults = new List < Database.SaveResult > ();
	
        Set < string > statusCatSet = new Set < string > {
            'Request',
            'In Authoring',
            'In Signatures',
            'In Filing'
        };
        Set < Id > agreementSet = new Set < Id > {scope[0].Id};
            System.Debug('Current Agreement Record to be processed 1'+scope);
        
        for(Apttus__AgreementLineItem__c  ali : new ApttusAgreementLineItemSelectors().selectAgreementLineItemNew(agreementSet)){
            agreementLineItemList.addAll(new List<Apttus__AgreementLineItem__c>{ali});
        }

        if (statusCatSet.contains(scope[0].Apttus__Status_Category__c)) {
            idofAgreementsForApproval = scope[0].Id;
            if (scope[0].Apttus_Approval__Approval_Status__c == PENDAPP) {
                idofAgreementsToRecallToRequest = scope[0].Id;
                idofAgreementsToCanelApprovals = scope[0].Id;
            } else if (scope[0].Apttus_Approval__Approval_Status__c == 'Rejected' || scope[0].Apttus_Approval__Approval_Status__c == 'Cancelled') {
                idofAgreementsToRecallToRequest = scope[0].Id;
            }
        }
        /*if (scope[0].Apttus__Status_Category__c == 'Request' || scope[0].Apttus__Status_Category__c == 'In Authoring' || scope[0].Apttus__Status_Category__c == 'In Signatures' || scope[0].Apttus__Status_Category__c == 'In Filing') {
            if (scope[0].Apttus_Approval__Approval_Status__c == PENDAPP) {
                        agreementLineItemList1.addAll(scope[0].Apttus__AgreementLineItems__r);
                idofAgreementsToRecallToRequest = scope[0].Id;
                        idofAgreementsToCanelApprovals = scope[0].Id;
                        idofAgreementsForApproval = scope[0].Id;
                    } 
                    if (scope[0].Apttus_Approval__Approval_Status__c == 'Rejected' || scope[0].Apttus_Approval__Approval_Status__c == 'Cancelled') {
                        agreementLineItemList1.addAll(scopE[0].Apttus__AgreementLineItems__r);
                idofAgreementsToRecallToRequest = scope[0].Id;
                        idofAgreementsForApproval = scope[0].Id;
                    }                     
            if (scope[0].Apttus_Approval__Approval_Status__c == APPREQ) {
                        agreementLineItemList1.addAll(scope[0].Apttus__AgreementLineItems__r);
                        idofAgreementsForApproval = scope[0].Id;
                    }
        }*/
            

            // Cancelling Approvals

        if (idofAgreementsToCanelApprovals != null) {
            Boolean status = Apttus_Approval.ApprovalsWebService.cancelApprovals('Apttus__APTS_Agreement__c', idofAgreementsToCanelApprovals);
            System.debug('Status  ' + status);
            }
		
            
            // Status Category of Agreements to 'Request' and Status to 'Request'               
        if (idofAgreementsToRecallToRequest != null)
                AgreementRevertToRequest.agreementRevertToRequest(idofAgreementsToRecallToRequest);
                             
                //DG Fields Update
                
        if(agreementLineItemList != null && !agreementLineItemList.isEmpty() && agreementLineItemList.size() < 200){
                    DiscountGuidancePopulatorForCLM populator = new DiscountGuidancePopulatorForCLM();
        populator.deriveFieldValuesForDiscountGuidance(agreementLineItemList, null);
        //approveAgreements(scope, agreementLineItemList);
        if (!agreementLineItemList.isEmpty()) {
            saveResults.addAll(Database.update(agreementLineItemList, false));
            handleSaveResults(saveResults, 'Agreement Line Items after Approval Selection', errors);
            ApexExceptions.emitSaveErrors(saveResults, LOG_TITLE );
        }  
        } else if(agreementLineItemList != null && !agreementLineItemList.isEmpty()) {
           // agmntIdtoprocessLargeLines.clear();
            agmntIdtoprocessLargeLines.add(scope[0].Id);
        }
        

        
        }

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

    /*   // Method for agreement approvals
    private void approveAgreements(List < Apttus__APTS_Agreement__c > agreeementList, List < Apttus__AgreementLineItem__c > agreementLineItemList ) {
        
        //Approval setup
        List < Apttus__APTS_Agreement__c > listAgreementsFromIntialize = new List < Apttus__APTS_Agreement__c > ();
        Set < Id > agreementSet = new Set < Id > ();
        //agreementSet.add(idofAgreementsForApproval);
        agreementSet.add(agreeementList[0].Id);
        listAgreementsFromIntialize = new ApttusAgreementSelectors().selectAgreements(agreementSet);
        //// DCP-50961 : NEW APPROVALS start
        

            Boolean forceOldFramework = System.Test.isRunningTest() && useOldFrameworkWhileTesting;
        if (Feature.isOn('SalesCLMApprovalsPipeline') && !forceOldFramework) {
            if (!agreementLineItemList.isEmpty()) {
                Approvals.AgreementLineInputs approvalInputs = new Approvals.AgreementLineInputs(agreementLineItemList, new Map < Id, Apttus__APTS_Agreement__c > (listAgreementsFromIntialize));
                    IApprovalsAPI approvals = ApprovalsService.init(approvalInputs);
                     approvals.processAgreementLines();
                }
             } 

       } */
    /**
     * @author: Vinay S Reddy
     * @date: 27-06-2024
     * @description: Required final method for batch
     * @param: bc - batch context
     * @return: void
     */
    public void finish(Database.BatchableContext bc) {
       // finish method logic
       // 
       // 
       if(agmntIdtoprocessLargeLines !=null && agmntIdtoprocessLargeLines.size() > 0)
        Database.executeBatch(new BatchToUpdateLargeAgmntLineItems(agmntIdtoprocessLargeLines),200);
    }    

}