/**
*    @author Satya Swain
*    @date   2018-12-11
*    @description    DCP-1351: Batch class to populate region fields on account's associated opportunity and quotation
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Satya Swain                   2018-12-11           Initial Version
*            Koustubh M                    09-Dec-2021          TASK0679416 Added code for error logging
*            Nishan Shetty                 03-Jun-2022         Implementing Batch Manager Framework DCP-50962
*            Nishan Shetty                 22-Aug-2022         [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
*            Adyasha Satapathy             13-Dec-2022         POL-188 : Update the batch to exclude OPPORTUNITIES with closed status for region update
*            Adyasha Satapathy             04-Jan-2023         POL-188 : Update the batch to exclude INVALID Quotes for region updates.
*    ------------------------------------------------------------------------------------
**/

public with sharing class BatchOpportunityAndQuotePopulateRegion extends ilib_BatchDeferrable {

    private final static String SOURCE = 'BatchOpportunityAndQuotePopulateRegion'; //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
   
    public String strQuery;
    private Set<Id> setAccountIds;
    private Inputs inputs;
    public Set<String> setOppClosedStage = new Set<String>{Label.OpportunityStageClosedWon,Label.OpportunityStageClosedLost,Label.OpportunityStageClosedAbandoned};   // POL-188


    /*
    *  @Author      : Nishan Shetty
    *  @Description : Parameter wrapper for easy serialization[DCP-50962]
    */
    public class Inputs {
        public Set<Id> setAccountId;

        /*Constructor*/
        public Inputs(Set<Id> setAccountId) {
            this.setAccountId = setAccountId;
        }
    }

   /*
    * @Author : Nishan Shetty[TASK0802266]
    * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
    */
    public BatchOpportunityAndQuotePopulateRegion() {
     super();
    }

    /*Constructor*/
    public BatchOpportunityAndQuotePopulateRegion(Set<Id> setAccountIds) {
        super();
        this.inputs = new Inputs(setAccountIds);
        this.setAccountIds = inputs.setAccountId;
        ilib_LogEvent.setTitle(SOURCE);
    }

    /*
    * @author Satya Swain
    * @date  2018-12-11
    * @description    DCP-1351: Batch method override
    * query all objects (opportunities) tied to the updated accounts
    */
    public override Database.QueryLocator start(Database.BatchableContext bc){
        this.strQuery = 'SELECT Id, Name, Sold_To_Account_Region__c, Ultimate_Consignee_Region__c,AccountId,Current_Ultimate_Consignee__c,'
                        +'Ultimate_Consignee__c, StageName, (SELECT Id,Apttus_Proposal__Proposal_Name__c,Sold_To_Account_Region__c,'
                        +'Ultimate_Consignee_Region__c,Invalid_Quote__c,Apttus_Proposal__Approval_Stage__c FROM R00N70000001yUfDEAU WHERE Invalid_Quote__c = false) '
                        +'FROM Opportunity WHERE (StageName NOT IN : setOppClosedStage AND (AccountId IN :setAccountIds OR Ultimate_Consignee__c IN :setAccountIds OR Current_Ultimate_Consignee__c IN :setAccountIds))';
        return Database.getQueryLocator(strQuery);
    }
    /*
    * @author Satya Swain
    * @date   2018-12-11
    * @description    DCP-1351 Batch method override
    * Excute Logic to populate Territory Information on Opportunity and Quotation Records
    *
    */
    public override void execute(Database.BatchableContext bc, List<sObject> scope){
        ilib_LogEvent.setBatchTitle(SOURCE, transactionId); 
        ilib_LogEvent.push('BatchOpportunityAndQuotePopulateRegion.execute');
        Set<Id> accounIds = new Set<Id>();
        List<Opportunity> lstOpportunity = (List<Opportunity>)scope;
        //Map<Id,String> accIdToAccMap = new Map<Id,String>();

        List<Opportunity> lstOpportunityToUpdate = new List<Opportunity>();
        Map<Id,Apttus_Proposal__Proposal__c> idToUpdatedQuotation = new Map<Id,Apttus_Proposal__Proposal__c>();
        
        //List<Opportunity> lstUCOpportunity = new List<Opportunity>();
         if(!lstOpportunity.isEmpty()){
            for(Opportunity opp: lstOpportunity){
                accounIds.add(opp.Ultimate_Consignee__c);
                accounIds.add(opp.AccountId);
                accounIds.add(opp.Current_Ultimate_Consignee__c);
            }
        }
        
        ilib_LogEvent.info('accounIds ::: '+accounIds);
        ilib_LogEvent.info('lstOpportunity ::: '+lstOpportunity);

        Map<Id,Account> accIdToAccMap = new Map<Id,Account>(new AccountsSelector().selectAccounts(accounIds));
        for(Opportunity objOpportunity : lstOpportunity){
            Boolean boolIsRegionChanged = false;
            if(objOpportunity.Sold_To_Account_Region__c != accIdToAccMap.get(objOpportunity.AccountId)?.Territory_Region__c){//POL-188
                objOpportunity.Sold_To_Account_Region__c = accIdToAccMap.get(objOpportunity.AccountId)?.Territory_Region__c;//POL-188
            } 
            if(objOpportunity.Ultimate_Consignee_Region__c != accIdToAccMap.get(objOpportunity.Ultimate_Consignee__c)?.Territory_Region__c){//POL-188
                objOpportunity.Ultimate_Consignee_Region__c = accIdToAccMap.get(objOpportunity.Ultimate_Consignee__c)?.Territory_Region__c;//POL-188
                boolIsRegionChanged = true;      
            }
            if(setAccountIds.contains(objOpportunity.Current_Ultimate_Consignee__c) || boolIsRegionChanged){
                objOpportunity.Relocation_Type__c = OpportunitiesService.updateRelocationType(objOpportunity,accIdToAccMap);
            }
            objOpportunity.Is_Updated_By_System__c = true;
            lstOpportunityToUpdate.add(objOpportunity);
            ilib_LogEvent.message('@@@ Child Relationship values:' + objOpportunity.R00N70000001yUfDEAU);
            if(objOpportunity.R00N70000001yUfDEAU!=null) {
                for ( Apttus_Proposal__Proposal__c objProposal : objOpportunity.R00N70000001yUfDEAU ){
                    if(objProposal.Sold_To_Account_Region__c != accIdToAccMap.get(objOpportunity.AccountId)?.Territory_Region__c){//POL-188
                        objProposal.Sold_To_Account_Region__c = accIdToAccMap.get(objOpportunity.AccountId)?.Territory_Region__c;//POL-188
                    }
                    if(objProposal.Ultimate_Consignee_Region__c != accIdToAccMap.get(objOpportunity.Ultimate_Consignee__c)?.Territory_Region__c){//POL-188
                        objProposal.Ultimate_Consignee_Region__c = accIdToAccMap.get(objOpportunity.Ultimate_Consignee__c)?.Territory_Region__c;//POL-188
                    }
                    objProposal.Is_Updated_By_System__c = true;
                    idToUpdatedQuotation.put(objProposal.Id, objProposal);
                }
            }
        }
        
        if(!lstOpportunityToUpdate.isEmpty()){
            //update lstOpportunityToUpdate;
            List<Database.SaveResult> lstSaveErrorsOpp = Database.update(lstOpportunityToUpdate, false); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            if(!lstSaveErrorsOpp.isEmpty()){ //Koustubh - TASK0679416, 9th Dec 2021 - Added error logging
                ApexExceptions.emitSaveErrors(lstSaveErrorsOpp, SOURCE+' Opportunity '); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            }
        }
        ilib_LogEvent.message('@@@ Quotation list:' + idToUpdatedQuotation.values());
        if(!idToUpdatedQuotation.isEmpty()){
            List<Database.SaveResult> lstSaveErrorsQuo = Database.update(idToUpdatedQuotation.values(), false); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            if(!lstSaveErrorsQuo.isEmpty()){ //Koustubh - TASK0679416, 9th Dec 2021 - Added error logging
                ApexExceptions.emitSaveErrors(lstSaveErrorsQuo, SOURCE+' Quotation '); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /*FINISH Method*/
    public override void finish(Database.BatchableContext bc) {
        ilib_LogEvent.setBatchTitle(SOURCE,transactionId);
        ilib_LogEvent.push(SOURCE + '.finish()');
        ilib_LogEvent.message('setAccountIds@@@@@' + setAccountIds);
        Map<String, String> params = UtilsSettings.getCustomMetadataMap('Contract_Territory_Updates');
        Integer defaultBatchSize = 100;
        Integer batchSize = UtilsSettings.parseIntegerFromSettingsMap(params, 'ContractBatchSize', defaultBatchSize);
        if (batchSize < 1 || batchSize > 200) batchSize = defaultBatchSize;

        if(setAccountIds != null && setAccountIds.size() > 0){
            ilib_BatchManager.executeBatch(new BatchContractOrderPopulateRegion(setAccountIds),batchSize);//DCP-50962
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }


    // ************************************************************************************************
    // Deferrable implementation DCP-50962
    // ************************************************************************************************
    
    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs() {
        return JSON.serialize(inputs);
    }

    /*
    *  @Author      : Nishan Shetty
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (BatchOpportunityAndQuotePopulateRegion.Inputs)JSON.deserialize(serializedInputs, BatchOpportunityAndQuotePopulateRegion.Inputs.class);
    }

}