/*****************************************************************************************************************
* Class Name: BeforeUpdate_InstalledProductHelper
* Description: Helper class for before update of Installed Products.
* 
* Author: Raviteja Vakkalagadda
* 
* Date: 28-03-2022
* 
* Notification Log:
* -------------------------------------------------------------------------------------------------------------
* Developer                  Date                              Description
* -------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda      28-03-2022                      Helper class for before update of Installed Products.
* Chaitanya Kartik           30-08-2023                      Created a updateFieldsonInstalledProduct method  that checks if SVMXC__Status__c is changing to either 
*                                                            'Scrapped' or 'Decommissioned' or 'Returned' by iterating through the records
* Abhishek Yadav              27-Sept-2023                     Modified the updateFieldsonInstalledProduct for adding the service product type check
******************************************************************************************************************/
public with sharing class BeforeUpdate_InstalledProductHelper {
    
/*
* @description: Method to form a map of field label to its api name and use in creation of Technical Attributes
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    public static void prepareIPFieldLabelToApiName() {
        
        for (Schema.FieldSetMember fieldMember : SObjectType.SVMXC__Installed_Product__c.FieldSets.IQ_OQ_Technical_Attribute_FieldSet.getFields()) { 
            InstalledProducts.mapIBFieldLabelVsAPIName.put(fieldMember.getLabel(), fieldMember.getFieldPath());
        }
    }
/*
* @description: Method to identify if there is any field value changed and create the technical attributes for the same.
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    public static void checkFieldSetValuesChangedOnIP(Map<Id, SObject> oldRecords, List<sObject> records) {
        
        for (SVMXC__Installed_Product__c objInstalledProduct: (List<SVMXC__Installed_Product__c >)records) {
            SVMXC__Installed_Product__c objObjInstalledProduct = (SVMXC__Installed_Product__c)(oldRecords.get(objInstalledProduct.Id));
            for (String strIBFieldAPI : InstalledProducts.mapIBFieldLabelVsAPIName.values()) {
                if (objInstalledProduct.get(strIBFieldAPI) != objObjInstalledProduct.get(strIBFieldAPI)) {
                    InstalledProducts.idToRecordWithAttributesUpdated.put(objInstalledProduct.Id, objInstalledProduct);
                }
            }
        }
    }
/*
* @description: checks if SVMXC__Status__c is changing to either 'Scrapped' or 'Decommissioned' or 'Returned' by iterating through the records
* @author: Chaitanya Karthik
* @date: 08/30/2023
* @returns: void
*/
    
    public static void updateFieldsonInstalledProduct(Map<Id, SObject> oldRecords, List<sObject> records) {
        String statusReturned='Returned';
        String statusScrapped='Scrapped';
        String statusDecommissioned='Decommissioned';
        
        
        for (SVMXC__Installed_Product__c objInstalledProduct: (List<SVMXC__Installed_Product__c >)records) {
            SVMXC__Installed_Product__c objObjInstalledProduct = (SVMXC__Installed_Product__c)(oldRecords.get(objInstalledProduct.Id));
             
            if(objInstalledProduct.Service_Product_Type__c == Label.ProductClassInstrument && (objInstalledProduct.SVMXC__Status__c != objObjInstalledProduct.SVMXC__Status__c || objInstalledProduct.SVMXC__Product__c != objObjInstalledProduct.SVMXC__Product__c)){
               
                if(objInstalledProduct.SVMXC__Status__c == statusReturned) {
                    objInstalledProduct.Operation_Status__c = 'Off';
                    objInstalledProduct.SVMXC__Site__c = null;
                    objInstalledProduct.SVMXC__Date_Installed__c = null;
                    objInstalledProduct.Acceptance_Date__c = null ;
                    objInstalledProduct.SVMXC__Date_Shipped__c = null;
                    objInstalledProduct.SVMXC__Date_Ordered__c = null;
                }
                else if(objInstalledProduct.SVMXC__Status__c == statusScrapped || objInstalledProduct.SVMXC__Status__c == statusDecommissioned) {
                     objInstalledProduct.Operation_Status__c = 'Off';
                }
           }
        }
    }
}