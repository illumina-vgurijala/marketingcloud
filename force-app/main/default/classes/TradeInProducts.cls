/*
*  @Author: Gerardo Garcia
*  @Date: 2023-11-02
*  @Description: Class for TradeInProductTrigger handler
*  @Test Class
   -TestTradeInProducts
*  Modification Log:
*  ---------------------------------------------------------------------------------------------------------------------------
*       Developer                       Date(YY-MM-DD)                  Description
*       Gerardo Garcia                  2023-11-02                      Initial Version CMCM-817
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class TradeInProducts extends ilib_SObjectDomain {
    private static String salesProfileId;
    private static String commOpsProfileId;

    /*Parameterised Constructor */
    public TradeInProducts(List<Trade_In_Product__c> sObjectList) {
        super(sObjectList);
    }

    /*
    *  @Author: Gerardo Garcia
    *  @Description: Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        *  @Author: Gerardo Garcia
        *  @Description: contruct method to create a TradeInProducts object
        *  @Param: List<SObject>
        *  @Return: ilib_SObjectDomain
        */

        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new TradeInProducts(sObjectList);
        }
    }

    /**
     * Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method
     **/
    public override void onBeforeInsert(){ 
        List<Trade_In_Product__c> tradeInRecords = (List<Trade_In_Product__c>) records;
        validateProfile(tradeInRecords);
        ilib_LogEvent.emit();
    }

    /**
     * Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method
     **/
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
        // List<Trade_In_Product__c> oldRecords = (List<Trade_In_Product__c>) existingRecords.values();
        validateProfile((List<Trade_In_Product__c>) records);
        ilib_LogEvent.emit();
    }
    /**
     * Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method
     **/
    public override void onBeforeDelete() {
        List<Trade_In_Product__c> tradeInRecords = (List<Trade_In_Product__c>) records;
        validateProfile(tradeInRecords);
        ilib_LogEvent.emit();
    }

    /**
     * @author Gerardo Garcia
     * @description Profile of "Sales" and "Commercial Ops Quoting" Users are able to do inser/update/delete operation on certain quote stages.
     */
    private static void validateProfile(List<Trade_In_Product__c> tradeInRecords) {

        ilib_LogEvent.message('tradeInRecords:' + JSON.serializePretty(tradeInRecords));

        if(hasSalesProfile() || hasCommOpsProfile()) {

            // get list from custom metadata depending on profile.
            String codeParam = hasSalesProfile() ? 'Quotation_Stages_Edit_Sales' : 'Quotation_Stages_Edit_Commercial_Ops';
            List<String> stagesToValidate = Code_Parameter__mdt.getInstance(codeParam)?.Value__c?.split(',');

            ilib_LogEvent.info('stagesToValidate:' + stagesToValidate != null? JSON.serializePretty(stagesToValidate) : 'does not have stages!' );

            // if doesn't have stages to valid, cancel validation.
            if(stagesToValidate == null || stagesToValidate.isEmpty()) 
                return;

            // Pull quototion stages from query.
            Set<Id> quotationIds = UtilsCollection.getSetOfIds(tradeInRecords, 'Quote_Proposal__c');
            ilib_LogEvent.message('quotationIds:' + quotationIds);
            Map<Id, Apttus_Proposal__Proposal__c> quotationMap = new Map<Id, Apttus_Proposal__Proposal__c>([SELECT Id, Apttus_Proposal__Approval_Stage__c FROM Apttus_Proposal__Proposal__c WHERE Id IN :quotationIds]);
            ilib_LogEvent.message('quotationMap:' + JSON.serializePretty(quotationMap));

            for(Trade_In_Product__c tradeEntry : tradeInRecords) {
                Apttus_Proposal__Proposal__c quotation = quotationMap.get(tradeEntry.Quote_Proposal__c);
                ilib_LogEvent.message('Quotation.stage:' + quotation?.Apttus_Proposal__Approval_Stage__c);
                if(!isValidQuotationStage(quotation, stagesToValidate))
                    tradeEntry.addError(hasSalesProfile() ? Label.TradeIn_Product_Sales_Profile_Validation_Error : Label.TradeIn_Product_CommOps_Profile_Validation_Error);
            }
        }
    }

    /**
     * @description Verifies validates stage of quotation
     * @return Boolean true if quotation stage has a valid stage.
     */
    private static Boolean isValidQuotationStage(Apttus_Proposal__Proposal__c quotation, List<String> stages) {
        if(quotation?.Apttus_Proposal__Approval_Stage__c == null)
            return false;
        
        return stages?.contains(quotation.Apttus_Proposal__Approval_Stage__c);
    }

    @TestVisible
    private static Boolean hasSalesProfile() {
        if(salesProfileId == null) {
            salesProfileId = new ProfilesSelector().getProfileByName(new Set<String> {ProfilesSelector.PROFILE_SALES})?.get(0)?.id;
        }
        return UserInfo.getProfileId()?.equals(salesProfileId);
    }

    @TestVisible
    private static Boolean hasCommOpsProfile() {
        if(commOpsProfileId == null) {
            commOpsProfileId = new ProfilesSelector().getProfileByName(new Set<String> {ProfilesSelector.PROFILE_COMM_OPS})?.get(0)?.id;
        }
        return UserInfo.getProfileId()?.equals(commOpsProfileId);
    }

    /**
     * return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }
}