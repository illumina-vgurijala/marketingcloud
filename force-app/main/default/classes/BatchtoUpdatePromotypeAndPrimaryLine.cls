/**
*    @author Vinay S Reddy
*    @date   2025-09-05
*    @description   CMCM-10038 : Batch To Update Promo Type and Primary Product Line
*    Test classes for 75%: TestBatchtoUpdatePromotypeAndPrimaryLine
* 
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Vinay S Reddy                2024-09-05            Initial Version
*    -----------------------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class BatchtoUpdatePromotypeAndPrimaryLine implements Database.Batchable < sObject >, Database.Stateful{
    public List <Database.SaveResult> saveResults = new List <Database.SaveResult>();
    AsyncApexJob job;
    Set<Id> promotionIds = new Set<Id>();
    public static final string LOG_TITLE = 'BatchtoUpdatePromotypeAndPrimaryLine';
    
/**
* @author Vinay
* @description constructor
**/
    public BatchtoUpdatePromotypeAndPrimaryLine() {
        // setting workstream
     ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES);  
    }
/**
* @author Vinay
* @description constructor
**/
public BatchtoUpdatePromotypeAndPrimaryLine(Set<Id> promotionIdsSet) {
     this.promotionIds = promotionIdsSet;
}

/**
     * @author:Vinay S Reddy
     * @date: 05-09-2024
     * @description: Required start method for batch
     * @param: bc - batch context 
     * @return: query
     */
public Database.QueryLocator start(Database.BatchableContext bc){

    String strSoql ='Select Id ,Name,Primary_Product_Line__c,Promo_Type__c,Active__c From Promotions__c Where Active__c=true dynamicPromotionIds';
    if(promotionIds?.size()>0){
        strSoql = strSoql.replace('dynamicPromotionIds', ' AND Id IN : promotionIds');
    }else{
        strSoql = strSoql.replace('dynamicPromotionIds', '');
    }
    return Database.getQueryLocator(strSoql);   
}

/**
     * @author: Vinay S Reddy
     * @date: 05-09-2024
     * @description: Required execute method for batch
     * @param: bc - batch context
     * @return: void
     */   


     /*Execute method of Batch Class*/    
    public void execute(Database.BatchableContext bc, list <Promotions__c> scope) {

        list <Promotions__c> promotionsToUpdate = new list <Promotions__c>();

        for(Promotions__c tempPromotion : scope){
            Promotions__c singlePromotionsUpdate = new Promotions__c();

            if(tempPromotion.Primary_Product_Line__c!=null && tempPromotion.Primary_Product_Line__c.substringBetween('(',')')!=null){
                singlePromotionsUpdate.Id = tempPromotion.Id;
                singlePromotionsUpdate.Promo_Type__c=tempPromotion.Primary_Product_Line__c.substringBetween('(',')');
                singlePromotionsUpdate.Primary_Product_Line__c = tempPromotion.Primary_Product_Line__c.substringBefore('(');
                promotionsToUpdate.add(singlePromotionsUpdate);
            }
        }

        try {
            if (promotionsToUpdate != null && !promotionsToUpdate.isEmpty()) {
                
                saveResults.addAll(Database.update(promotionsToUpdate, false));
                handleSaveResults(saveResults, 'Updating Promotions');
            }
        } 
        catch (DmlException e) {
            // Log any exceptions that occurred during the update operation
            //System.debug('Error in updatePlans: ' + e.getMessage());
            ApexExceptions.emit(LOG_TITLE,e,ilib_LogEvent.SALES);
            throw e;
        }
    }

            /**
* @author Vinay
* @description method to handle save results
**/  
public void handleSaveResults(List < Database.SaveResult > saveResults, String objectType) {
    ilib_LogEvent.push(LOG_TITLE + '.execute()');
    for (Database.SaveResult saveResult: saveResults) {
        if (!saveResult.isSuccess()) {
            for (Database.Error e: saveResult.getErrors()) {
               // System.debug(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                ilib_LogEvent.info(objectType + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                //System.debug(objectType + ' fields that affected this error: ' + e.getFields());
                ilib_LogEvent.info(objectType + ' fields that affected this error: ' + e.getFields());
                //System.debug(objectType + ' record that affected this id: ' + saveResult.getId());
                ilib_LogEvent.info(objectType + ' record that affected this id: ' + saveResult.getId());
            }
        }
        if (saveResult.isSuccess()) {
            System.debug('Success Status for plan records   ' + saveResult);
            ilib_LogEvent.info('Success Status for plan records  ' + saveResult);
        }
    }
    ilib_LogEvent.pop();
    ilib_LogEvent.emit(); 
}

/**
* @author Vinay
* @description finish method of Batch
**/
public void finish(Database.BatchableContext bc)
{
}

    }

