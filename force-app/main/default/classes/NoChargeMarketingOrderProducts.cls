/**
*    @author: Deep Diwakar
*    @date:   March-08-2023
*    @description:  No Charge Marketing Order Product Trigger Handler class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*           Deep Diwakar                  March-08-2023       DCP-59580: Adding after insert and after delete logic
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class NoChargeMarketingOrderProducts extends ilib_SObjectDomain {

    /*Parameterised Constructor */
    public NoChargeMarketingOrderProducts (List<No_Charge_Marketing_Order_Product__c> sObjectList) {
        super(sObjectList);
    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*Method Param - List<sObject> */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new NoChargeMarketingOrderProducts(sObjectList);
        }
    }

    /**
     * @author     : Deep Diwakar
     * @param      : None
     * @return     : void
     * @Description: DCP-59580 - After insert method for NCMO Product
    **/
    public override void onAfterInsert() {
        List<No_Charge_Marketing_Order_Product__c> lstNcmoProducts = (List<No_Charge_Marketing_Order_Product__c>) records;
        List<No_Charge_Marketing_Order__c> lstNcmo = new List<No_Charge_Marketing_Order__c>();
        Set<Id> setNcmoProductId = UtilsCollection.getSetOfIds(lstNcmoProducts);
        Set<Id> setNcmo = new Set<Id>();
        
        // looping through new ncmo products to find out which ones are of type open offer and storing their NCMO ids
        for (No_Charge_Marketing_Order_Product__c ncmoProduct : new NoChargeMarketingOrderProductsSelector().selectNcmoProductsById(setNcmoProductId)) {
            if (ncmoProduct.Product__r.Open_Offer_Product__c || String.isNotBlank(ncmoProduct.Product__r.Open_Offer_Product_Category__c)) {
                setNcmo.add(ncmoProduct.NCMO__c);
            }
        }
       
        ilib_LogEvent.info('setNcmo.size(): ' + setNcmo.size());
        
        // return if new products are not of type open offer
        if (setNcmo.isEmpty()) {
            return;
        }
        
        // looping through NCMO objects for open offer products to update Open_Offer_Product__c field on NCMO object
        for (No_Charge_Marketing_Order__c ncmo : new NoChargeMarketingOrdersSelector().selectNcmoById(setNcmo)) {
             ncmo.Open_Offer_Product__c = true;
             lstNcmo.add(ncmo);                                         
            
        }
        
        // update NCMO records
        ilib_LogEvent.info('lstNcmo.size(): ' + lstNcmo.size());
        if (!lstNcmo.isEmpty()) {
            update lstNcmo;
        }

    }

    /**
     * @author     : Deep Diwakar
     * @param      : None
     * @return     : void
     * @Description: DCP-59580 - After delete method for NCMO Product
    **/
    public override void onAfterDelete() {

        List<No_Charge_Marketing_Order_Product__c> lstDeletedNcmoProducts = (List<No_Charge_Marketing_Order_Product__c>)Trigger.old;
        ilib_LogEvent.info('deleted products: ' + lstDeletedNcmoProducts.size());
        Set<Id> setNcmo = new Set<Id>();
        List<No_Charge_Marketing_Order__c> lstNoOpenOfferNcmo = new List<No_Charge_Marketing_Order__c>();

        // collecting NCMO object id for deleted products 
        for (No_Charge_Marketing_Order_Product__c ncmoProduct : lstDeletedNcmoProducts) {          
            setNcmo.add(ncmoProduct.NCMO__c);
        }
        
        ilib_LogEvent.info('setNcmo size: ' + setNcmo.size());

        // looping through all NCMO and its children to identify if there is still any open offer product left after deletion
        // if there is no open offer product in NCMO then only set Open_Offer_Product__c field value to false
        for (No_Charge_Marketing_Order__c ncmo : new NoChargeMarketingOrdersSelector().selectNcmoWithProductsById(setNcmo)) {     

            if (!ncmo.Open_Offer_Product__c) {
                continue;
            }

            Boolean reverseOpenOfferNcmo = true;
            ilib_LogEvent.message('looping ncmo: ' + ncmo);    
            ilib_LogEvent.message('ncmo products: ' + ncmo.No_Charge_Marketing_Order_Products__r);                               
            for (No_Charge_Marketing_Order_Product__c prd : ncmo.No_Charge_Marketing_Order_Products__r) {     
                if (prd.Product__r.Open_Offer_Product__c || String.isNotBlank(prd.Product__r.Open_Offer_Product_Category__c)) {
                    reverseOpenOfferNcmo = false;
                    break;        
                }
            }
            
            if (reverseOpenOfferNcmo) {
                ncmo.Open_Offer_Product__c = false;   
                lstNoOpenOfferNcmo.add(ncmo);
            }      
        }
        
        // update NCMO records
        ilib_LogEvent.info('lstNoOpenOfferNcmo size: ' + lstNoOpenOfferNcmo.size());
        if (!lstNoOpenOfferNcmo.isEmpty()) {
            update lstNoOpenOfferNcmo;            
        } 

    }

}