/**
*    @author Rahul Sharma 
*    @date   2018-08-25
*    @description    DCP-10312: Transborder Price List 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rahul Sharma                25 Aug 2018            To populate price list on Account Sales Area
*             Rahul Sharma                18 Oct 2018            Added logic to populate price list only if blanked out
*             Roopal Verma                29-Nov 2018            Added logic for sales area extension, onAfterInsert(), getNewAccSalesArea
*             Aman Tyagi                  30-Mar-2022            CodeScan Fixes
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/

public with sharing class AccountSalesAreas extends ilib_SObjectDomain {

    //public Static Map<Id, String> asaToERPId = new Map<Id, String>();
    public Static List<Account_Sales_Area__c> lstNewASA = new List<Account_Sales_Area__c>(); 

    /*
    * @Author: Rahul Sharma
    * @Description : parameterized constructor of the class AccountSalesAreas
    * @param: List< Account_Sales_Area__c > sObjectList
    * @return: NA
    */
    public AccountSalesAreas(List< Account_Sales_Area__c > sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        * @Author: Rahul Sharma
        * @Description : constructor for base class
        * @param: List<SObject> sObjectList
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new AccountSalesAreas(sObjectList);
        }
    }

    /*
    * @Author: Rahul Sharma
    * @Description : this method is populating the records of the price list
    * @param: none
    * @return: void
    */    
    public override void onBeforeInsert(){
        List<Account_Sales_Area__c> lstTempAccSales = (List<Account_Sales_Area__c>) records;
        populatePriceList(lstTempAccSales);
    }

    /*
    * @Author: Rahul Sharma
    * @Description : this method is populating the records of the price list
    * @param: Map<Id, sObject> existingRecords
    * @return: void
    */ 
    public override void onBeforeUpdate(Map<Id, sObject> existingRecords){
        List<Account_Sales_Area__c> lstTempAccSales = (List<Account_Sales_Area__c>) records;
        populatePriceList(lstTempAccSales);
        
    } 
    /*
    * @author Roopal Verma
    * @date   2018-11-29
    * @description    DCP-16987:Sales Area Extension
    * Get the inserted Sales area records for sales area extension
    *
    */

    public override void onAfterInsert(){
        List<Account_Sales_Area__c> lstTempAccSales = (List<Account_Sales_Area__c>) records;
        lstNewASA = lstTempAccSales;
        //asaToERPId = getNewAccSalesArea(lstTempAccSales);
    }    
    /*
    * @author Rahul Sharma
    * @date   2018-08-25
    * @description    DCP-10312:Transborder Price list
    * Populate Price List on Account Sales Area records
    *
    */
    public static void populatePriceList(List<Account_Sales_Area__c> lstAccSalesArea) {
           
        //Map to store ID and Combination of price list type and currency of Account Sales Area
        Map<Id, String> idToTypeCurrency = new Map<Id, String>();
       
       //Store the Combination of price list type and currency of Account Sales Area in a Map
        for(Account_Sales_Area__c acc: lstAccSalesArea) {
           if(String.isNotBlank(acc.Price_List_Type__c) && String.isNotBlank(acc.CurrencyIsoCode)){
                idToTypeCurrency.put(acc.Id,acc.Price_List_Type__c + '_' + acc.CurrencyIsoCode);
             }
         }
        if(idToTypeCurrency.isEmpty())
            return;
       //Map to store String Combination of price list type and currency of Account Sales Area With the Price List Metadata
        Map<String, Price_List__mdt> mapStrToPriceList = new Map<String, Price_List__mdt>();  
       
       //List to store Price List related to Account Sales Area record
       for(Price_List__mdt plm: new PriceListSelector().selectPriceList(idToTypeCurrency.values())) {
        mapStrToPriceList.put(plm.MasterLabel,plm);
       }
        
        //Populate Price List
         for( Account_Sales_Area__c acc: lstAccSalesArea) {
             String strKey = acc.Price_List_Type__c + '_' + acc.CurrencyIsoCode;
           if(mapStrToPriceList.containsKey(strKey) &&
               String.isNotBlank(mapStrToPriceList.get(strKey).Price_List__c)){
                 acc.Price_List__c = mapStrToPriceList.get(strKey).Price_List__c;
             }
         }
    }
         /*
         * @author Roopal Verma
         * @date   2018-11-29
         * @description    DCP-16987:Sales Area Extension
         * Get the inserted Sales area records for sales area extension
         *
         *
        public static Map<Id,String> getNewAccSalesArea (List<Account_Sales_Area__c> lstAccSalesArea){

            Map<Id, String> idToERPId = new Map<Id, String>();
            for (Account_Sales_Area__c asa : lstAccSalesArea){
                idToERPId.put(asa.id, asa.ERP_Account_Sales_Area_Id__c);
            }

            return idToERPId;
        }*/
}