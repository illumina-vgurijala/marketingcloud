/**
 *  @author Navy Jain
 *  @date  25-June-2024
 *  @description  [DCP-522] | [CPQ]: Data remediation - For In Progress Quotes > Quote Lines
 *  Modification Log:
 *  ------------------------------------------------------------------------------------
 *       Developer           Date            Description  
 *       Navy Jain          25-June-2024    Initial Version
 *  ------------------------------------------------------------------------------------
 **/
public class BatchUpdateToRecalculate implements Database.Batchable<sObject> {
    Set<Id> quoteId = new Set<Id>();
    private static final String LOG_TITLE = 'BatchUpdateToRecalculate';

    /**
     *  @author Navy Jain
     *  @description Constructor
     **/
    public BatchUpdateToRecalculate(Set<Id> quoteIdSet) {
       this.quoteId = quoteIdSet; 
   }

    /**
     *  @author Navy Jain
     *  @description Batch start method
     **/
    public Database.QueryLocator start(Database.BatchableContext bc) {
   
      return Database.getQueryLocator([SELECT ID,(Select Id,Customer_Historical_Discount__c,Approval_Matrix_Custom__c,Min_Discount__c,Approval_Matrix_Record_Owner__c,Material_Group_1__c,Open_Offer_Product_Category__c,Max_Discount_Guidance__c,Median_Discount_Guidance__c,Discount_Guidance__c,Product_Code__c,Discount_Grid_Group__c,Apttus_Config2__ConfigurationId__c,Apttus_Config2__ConfigurationId__r.Apttus_QPConfig__Proposald__c From Apttus_Config2__LineItems__r) FROM Apttus_Config2__ProductConfiguration__c where Apttus_QPConfig__Proposald__c IN : quoteId]);
      
   }

    /**
     *  @author Navy Jain
     *  @description Execute method - Update Quote lines
     **/
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        ilib_LogEvent.info('Apttus_Config2__ProductConfiguration__c list > '+scope);
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c>();
        for (Apttus_Config2__ProductConfiguration__c objProductConfig: (List < Apttus_Config2__ProductConfiguration__c > ) scope) {
            if(objProductConfig!=null && objProductConfig.Apttus_Config2__LineItems__r!=null && !objProductConfig.Apttus_Config2__LineItems__r.isEmpty()){
            DiscountGuidancePopulatorForCPQ disGuidanceObj = new DiscountGuidancePopulatorForCPQ();
                disGuidanceObj.deriveFieldValuesForDiscountGuidance(objProductConfig.Apttus_Config2__LineItems__r);
                ilib_LogEvent.info('Apttus_Config2__LineItems__r Calc list > '+objProductConfig.Apttus_Config2__LineItems__r);
                lineItemList.addAll(objProductConfig.Apttus_Config2__LineItems__r);
            }
        }
        database.update(lineItemList,false);  
        ilib_LogEvent.pop();
   }
   
   
    /**
     *  @author Navy Jain
     *  @description Batch Finish method
     **/
    public void finish(Database.BatchableContext bc) {

   }

}