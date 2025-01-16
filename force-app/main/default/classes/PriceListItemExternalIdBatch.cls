/*
 * @Author: Rishab Wali
 * @Date: 03-APR-2020
 * @Description : Batch Class to Update External Id Field on PriceListItem Records
*Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                        Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Rishab Wali            03-APR-2020                   Batch Class For External Id Updates(DCP 33826)
* Prem Ranjan            25-April-2022                 CodeScan Fix:Avoid Literals in If condition
* Aman Tyagi             12-dec-2022                   CodeScan Fixes
 */
global class PriceListItemExternalIdBatch implements Database.Batchable<sObject>{
    public static final Integer TEN = 10;
    /**
    * @author Rishab
    * @description  start method of batch whixh return Apttus_Config2__PriceListItem__c records that needs to be updated
    * @params Database.BatchableContext BC
    * @return Database.getQueryLocator(query)
    */
    global Database.QueryLocator start(Database.BatchableContext bc){
        DateTime dt = System.now();
        String query = 'SELECT Id,Apttus_Config2__ProductId__r.ProductCode,Apttus_Config2__PriceListId__c,Apttus_Config2__PriceListId__r.External_Id__c,'
                       + 'External_Id__c,Apttus_Config2__EffectiveDate__c FROM Apttus_Config2__PriceListItem__c WHERE Apttus_Config2__Active__c = true'
                       + ' AND Apttus_Config2__ExpirationDate__c > :dt';
        return Database.getQueryLocator(query);
    }
    /**
    * @author Rishab
    * @description  execute method of batch for updating Apttus_Config2__PriceListItem__c records
    * @params DDatabase.BatchableContext BC, List<Apttus_Config2__PriceListItem__c> scope
    * @return void
    */
    global void execute(Database.BatchableContext bc, List<Apttus_Config2__PriceListItem__c> scope){
        List<Apttus_Config2__PriceListItem__c> updatedPriceListItems = new List<Apttus_Config2__PriceListItem__c>();
        for(Apttus_Config2__PriceListItem__c pi : scope)
        {
            if(pi.Apttus_Config2__ProductId__c != null && pi.Apttus_Config2__PriceListId__r.External_Id__c != null && pi.Apttus_Config2__EffectiveDate__c != null)
            {
                DateTime effectiveDateValue = pi.Apttus_Config2__EffectiveDate__c;
                String strMonth = String.valueOf(effectiveDateValue.month());
                String strDate = String.valueOf(effectiveDateValue.day());
                if(effectiveDateValue.month() < TEN)
                    strMonth = '0'+ strMonth;
                if(effectiveDateValue.day() < TEN)
                    strDate = '0' + strDate;
                
                String strExternalId = pi.Apttus_Config2__ProductId__r.ProductCode +'_'+ pi.Apttus_Config2__PriceListId__r.External_Id__c+
                    '_'+String.valueOf(effectiveDateValue.year())+strMonth+strDate;
                
                pi.External_Id__c = strExternalId;
                updatedPriceListItems.add(pi);
            }
        }
        Database.update(updatedPriceListItems,false);
    }
    /**
    * @author Rishab
    * @description  finish method for batch
    * @params Database.BatchableContext BC
    * @return null
    */
    global void finish(Database.BatchableContext bc){
    }
}