/**
*    @author Adyasha Satapathy
*    @date   2022-05-25
*    @description    DCP-53375: Created Market Segment Domain Class
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Adyasha                      25 May 2022           DCP-53375: Domain class created for Market Segment related validations
*             Adyasha                      27 Jun 2022           Adding logic to update Market Segment value on Account 
*             Deep Diwakar                 Jan-04-2024           CMCM-4697: Update contact AOW when Market Segment change
*    -------------------------------------------------------------------------------------------------------------------------------------                     
*/
public with sharing class MarketSegments extends ilib_SObjectDomain {
    
    private static final String LOG_TITLE = 'MarketSegments';
    public static final String STRING_ACCOUNT_FIELD_API_NAME = 'Account__c';
    public static final Integer INTEGER_PERCENT_ALLOCATION = 100;
    private static cs_Apex_Settings__c objApexSetting;
    private static Boolean boolEvaluateAllocationValidation = true;
    private static final Integer INTEGER_ONE = 1;

    /*Constructor method */
    public MarketSegments(List<Market_Segment__c> sObjectList) {
        super(sObjectList);
    }

    /**
     * Boilerplate which is required for base class instantiation logic
     **/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new MarketSegments(sObjectList);
        }
    }

    /*
    * @desc : Trigger Before Insert method - runs before record is saved in database (in insert scenario) 
    */
    public override void onBeforeInsert() {           
        validateMarketSegmentDetails((List<Market_Segment__c>)records, null);        
    }
    
    /*
    * @desc : Trigger Before Update method - runs before record is saved in database (in update scenario) 
    */
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords) {
        validateMarketSegmentDetails((List<Market_Segment__c>)records, (Map<Id, Market_Segment__c>) existingRecords);        
    }

    /*
    * @desc : Trigger Before Delete method - runs before record is deleted from database (in delete scenario) 
    */
    public override void onBeforeDelete() {
        Map<Id, Market_Segment__c> mapIdToDeletedMarketSegments = new Map<Id, Market_Segment__c>((List<Market_Segment__c>) records);
        validateMarketSegmentDetailsForDelete(mapIdToDeletedMarketSegments);        
    }

    /*
    * @desc : Trigger After Insert method - runs after record is saved in database (in insert scenario) 
    */
    public override void onAfterInsert() {           
        updateMarketSegmentOnAccount((List<Market_Segment__c>)records); 

        // CMCM-4697: Publish PE to calculate AOW for related contacts
        publishMarketSegmentChange((List<Market_Segment__c>)records);
      
    }

    /**
     * @author: Deep Diwakar
     * @date: Jan-03-2024
     * @description: this method publishes PE when market segment change
     * @param: List of changed market segments
     * @return: void
     */
    private void publishMarketSegmentChange(List<Market_Segment__c> lstMarketSegment) {

        List<MarketSegmentChangeEvent__e> lstEvent = new List<MarketSegmentChangeEvent__e>();

        for (Market_Segment__c segment : lstMarketSegment) {
            MarketSegmentChangeEvent__e marketSegment = new MarketSegmentChangeEvent__e();
            marketSegment.Object_Type__c = 'Account';
            marketSegment.Object_Id__c = segment.Account__c;
            lstEvent.add(marketSegment);
        }

        ilib_LogEvent.info('publishing MarketSegmentChangeEvent__e event');

        if (!lstMarketSegment.isEmpty()) {
            EventBus.publish(lstEvent);
        }

    }

    /*
    * @desc : Trigger After Update method - runs after record is saved in database (in update scenario) 
    */
    public override void onAfterUpdate(Map<Id, sObject> existingRecords) {
        updateMarketSegmentOnAccount((List<Market_Segment__c>)records);  

        // CMCM-4697: Publish PE to calculate AOW for related contacts
        publishMarketSegmentChange((List<Market_Segment__c>)records);      
    }

    /*
    * @desc : Trigger After Delete method - runs after record is deleted from database (in delete scenario) 
    */
    public override void onAfterDelete() {        
        updateMarketSegmentOnAccount((List<Market_Segment__c>)records);  

        // CMCM-4697: Publish PE to calculate AOW for related contacts
        publishMarketSegmentChange((List<Market_Segment__c>)records);      
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : validate market segment data
    *  @param        : List<Market_Segment__c> lstMarketSegments, Map<Id, Market_Segment__c> mapIdToOldMarketSegment
    *  @return       : none
    */
    public void validateMarketSegmentDetails(List<Market_Segment__c> lstMarketSegments, Map<Id, Market_Segment__c> mapIdToOldMarketSegment) {

        ilib_LogEvent.push(LOG_TITLE+'.validateMarketSegmentDetails()'); 
        
        if (getApexSetting().Bypass_All_Validations__c || (System.Test.isRunningTest() && !TestMarketSegments.boolRunValidations)) {            
            ilib_LogEvent.pop();
            return; 
        }
                           
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstMarketSegments,STRING_ACCOUNT_FIELD_API_NAME);
        Set<Id> setMarketSegmentIdsToExclude = new Set<Id>();   
        Map<Id, List<Market_Segment__c>> mapAccountIdToListMarketSegments = new Map<Id, List<Market_Segment__c>>();             
                
        if(mapIdToOldMarketSegment == null || mapIdToOldMarketSegment.isEmpty()) {     
            setMarketSegmentIdsToExclude.clear();            
        } else {
            setMarketSegmentIdsToExclude.addAll(mapIdToOldMarketSegment.keySet());
        }
        
        if(setAccountIds == null || setAccountIds.isEmpty()) { 
            ilib_LogEvent.pop();
            return; 
        }
                
        Map<Id, Decimal> mapAccountIdToTotalMSAllocation = new Map<Id, Decimal>();
        prepareMapOfAccountIdToTotalAllocation(mapAccountIdToTotalMSAllocation,setAccountIds,setMarketSegmentIdsToExclude);
        mapAccountIdToListMarketSegments = (Map<Id, List<Market_Segment__c>>) UtilsCollection.getMapOfIdToSObjects(lstMarketSegments,STRING_ACCOUNT_FIELD_API_NAME);              
        checkForInvalidData(mapAccountIdToListMarketSegments,mapAccountIdToTotalMSAllocation);
        ilib_LogEvent.pop();              
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : validate market segment data for delete scenario
    *  @param        : Map<Id, Market_Segment__c> mapIdToMarketSegment
    *  @return       : none
    */
    public void validateMarketSegmentDetailsForDelete(Map<Id, Market_Segment__c> mapIdToMarketSegment) {
        ilib_LogEvent.push(LOG_TITLE+'.validateMarketSegmentDetailsForDelete()'); 
        if (getApexSetting().Bypass_All_Validations__c || (System.Test.isRunningTest() && !TestMarketSegments.boolRunValidations) || !isFlagTrueForAllocationEvaluation()) {            
            ilib_LogEvent.pop();
            return; 
        }
        
        Map<Id, Decimal> mapAccountIdToTotalMSAllocation = new Map<Id, Decimal>();        
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(mapIdToMarketSegment.values(),STRING_ACCOUNT_FIELD_API_NAME);
        prepareMapOfAccountIdToTotalAllocation(mapAccountIdToTotalMSAllocation,setAccountIds,mapIdToMarketSegment.keySet());
                                                
        for(Market_Segment__c objMarketSegment : mapIdToMarketSegment.values()) {
            Decimal decTotalAllocation = mapAccountIdToTotalMSAllocation.containsKey(objMarketSegment.Account__c)  ? mapAccountIdToTotalMSAllocation.get(objMarketSegment.Account__c) : 0;
            if(decTotalAllocation == 0) { continue; }
            if(Math.round(decTotalAllocation) != INTEGER_PERCENT_ALLOCATION) {
                showErrorForInvalidData(objMarketSegment, Label.UI_Error_Message_Segmentation_Selection_Allocation_Total);
            }
        }
        ilib_LogEvent.pop();
    }
    
    /*
    *  @author       : Adyasha Satapathy
    *  @description  : update Market Segment field on Account
    *  @param        : List<Market_Segment__c> lstMarketSegments
    *  @return       : none
    */
    public void updateMarketSegmentOnAccount(List<Market_Segment__c> lstMarketSegments) {    
        if(!isFlagTrueForAllocationEvaluation()) { return; }    
        
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(lstMarketSegments,STRING_ACCOUNT_FIELD_API_NAME);             
        List<Account> lstAccountsToUpdate = new List<Account>();
        List<Account> lstAccountsForMarketSegments = new AccountsSelector().selectAccountsWithMarketSegments(setAccountIds);

        for(Account objAccount : lstAccountsForMarketSegments) {            
            List<Market_Segment__c> lstMarketSegmentForAccount = objAccount.Market_Segments__r;            
            if(lstMarketSegmentForAccount == null || lstMarketSegmentForAccount.isEmpty()) {
                objAccount.Market_Segment__c = null;
            } else if(lstMarketSegmentForAccount.size() == INTEGER_ONE) {
                objAccount.Market_Segment__c = lstMarketSegmentForAccount[0].Market_Segment__c;
            } else {
                objAccount.Market_Segment__c = 'Multiple';
            }
            objAccount.Is_Updated_By_System__c = true;
            lstAccountsToUpdate.add(objAccount);
        }
        
        if(!lstAccountsToUpdate.isEmpty()) {
            update lstAccountsToUpdate;
        }
    }
    
    /*
    *  @author       : Adyasha Satapathy
    *  @description  : prepare map for calcuating sum of all market segments Allocation for an account
    *  @param        : Map<Id, Decimal> mapAccountIdToTotalMSAllocation, Set<Id> setAccountIds, Set<Id> setMarketSegmentIdsToExclude
    *  @return       : none
    */
    private void prepareMapOfAccountIdToTotalAllocation(Map<Id, Decimal> mapAccountIdToTotalMSAllocation, Set<Id> setAccountIds, Set<Id> setMarketSegmentIdsToExclude) {
        List<AggregateResult> lstTotalSumResult = new MarketSegmentSelector().selectByAccountIdExcludingGivenRecords(setAccountIds, setMarketSegmentIdsToExclude);
        
        for(AggregateResult objResult : lstTotalSumResult) {
            Decimal decTotalAllocation = (Decimal) objResult.get('TotalAllocation');
            Id accountId  = (Id) objResult.get('Account__c');
            mapAccountIdToTotalMSAllocation.put(accountId, decTotalAllocation);
        }        
    }
    
    /*
    *  @author       : Adyasha Satapathy
    *  @description  : check for errors in Market Segment Data
    *  @param        : Map<Id, List<Market_Segment__c>> mapAccountIdToListMarketSegments
    *  @return       : none
    */
    private void checkForInvalidData(Map<Id, List<Market_Segment__c>> mapAccountIdToListMarketSegments,Map<Id, Decimal> mapAccountIdToTotalMSAllocation) {
        ilib_LogEvent.push(LOG_TITLE+'.checkForInvalidData()'); 
        for(Id accountId : mapAccountIdToListMarketSegments.keySet()) {
            Decimal decTotalAllocation = mapAccountIdToTotalMSAllocation.get(accountId) == null ? 0 : mapAccountIdToTotalMSAllocation.get(accountId);
            Integer totalMarketSegmentsSize = mapAccountIdToListMarketSegments.get(accountId).size();
            Integer counter = 0;
            for(Market_Segment__c objMarketSegment : mapAccountIdToListMarketSegments.get(accountId)) {
                counter++;
                                
                if(String.isBlank(objMarketSegment.Market_Segment__c) || objMarketSegment.Percent_Allocation__c == null) {
                    showErrorForInvalidData(objMarketSegment, Label.UI_Error_Message_Segmentation_Selection_Complete_Required_fields);
                    ilib_LogEvent.pop();
                    return;                    
                }
                if(!isFlagTrueForAllocationEvaluation()) { 
                    ilib_LogEvent.pop();
                    return; 
                }     
                decTotalAllocation += objMarketSegment?.Percent_Allocation__c;
                if(Math.round(decTotalAllocation) > INTEGER_PERCENT_ALLOCATION || (counter == totalMarketSegmentsSize && Math.round(decTotalAllocation) < INTEGER_PERCENT_ALLOCATION)) {                               
                    showErrorForInvalidData(objMarketSegment, Label.UI_Error_Message_Segmentation_Selection_Allocation_Total);
                }                
            }            
        }
        ilib_LogEvent.pop();
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : throw error for invalid market segment data
    *  @param        : Market_Segment__c objMarketSegment, String errormessage
    *  @return       : none
    */
    private void showErrorForInvalidData(Market_Segment__c objMarketSegment, String strErrorMessage) {
        ilib_LogEvent.push(LOG_TITLE + '.showErrorForInvalidData()');                
        objMarketSegment.addError(strErrorMessage);
        ilib_LogEvent.pop();    
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : Fetch Apex Setting for the user/profile
    *  @param        : none
    *  @return       : cs_Apex_Settings__c objApexSetting
    */
    private static cs_Apex_Settings__c getApexSetting() {
        ilib_LogEvent.push(LOG_TITLE+'.getApexSetting()'); 
        if(objApexSetting == null) {
            objApexSetting = cs_Apex_Settings__c.getInstance();
        }
        ilib_LogEvent.pop();
        return objApexSetting;
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : Fetch boolEvaluateAllocationValidation value
    *  @param        : none
    *  @return       : Boolean boolEvaluateAllocationValidation
    */
    public static Boolean isFlagTrueForAllocationEvaluation() {
        return boolEvaluateAllocationValidation;
    }

    /*
    *  @author       : Adyasha Satapathy
    *  @description  : Set value of boolEvaluateAllocationValidation
    *  @param        : Boolean boolValue
    *  @return       : void
    */
    public static void setFlagForAllocationEvaluation(Boolean boolValue) {
        boolEvaluateAllocationValidation = boolValue;
    }   
}