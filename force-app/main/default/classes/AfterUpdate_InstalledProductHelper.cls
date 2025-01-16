/*****************************************************************************************************************
* Class Name: BeforeUpdate_InstalledProductHelper
* Description: Helper class for after update of Installed Products.
* 
* Author: Raviteja Vakkalagadda
* 
* Date: 28-03-2022
* 
* Notification Log:
* -------------------------------------------------------------------------------------------------------------
* Developer                  Date                              Description
* -------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda      28-03-2022                      Helper class for after update of Installed Products.
******************************************************************************************************************/
public with sharing class AfterUpdate_InstalledProductHelper {
    
    public static final String  ASSET_TYPE_FIELD_API = 'Asset_Type__c';
    public static Set<String> setCompanyOwnedAssetType = new set<String>{'Customer Owned','Customer 3rd Party Owned'};
        
/*
* @description: Method to prepare the required sets to perform the asynchronous operation 
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
        
    public static void prepareRequiredSets(List<sObject> records,Map<Id, sObject> existingRecords) {
            
            Map<String, String> mapFieldToFieldAPI = UtilsSettings.getCustomMetadataMap('Check_Fields_Updated_On_InstProduct');
            
            for (Sobject obj : records) {
                for (String field : mapFieldToFieldAPI.get('Fields').split('\\|')) {
                    Object objUpdatedValue = obj.get(field);
                    Object objOldValue = existingRecords.get(obj.Id).get(field);
                    if (objUpdatedValue != objOldValue) {
                        //DCP-43163 : Logic to check update on Asset type for running billable rule engine
                        if(updateBilling(objUpdatedValue,objOldValue,field)){
                            InstalledProducts.setAssetUpdatedInstalledProductIds.add(obj.Id);
                        }
                        InstalledProducts.setInstalledProductIds.add(obj.Id);
                        break;
                    }
                }
            }
    }

/*
* @description: Method to identify Update billable 
* @author: KD
* @returns: void
* DCP-43163
*/
    
    public static Boolean updateBilling(Object objUpdatedValue,Object objOldValue,String strAPIName) {
        return strAPIName == ASSET_TYPE_FIELD_API && (setCompanyOwnedAssetType.Contains((String)objUpdatedValue) || setCompanyOwnedAssetType.Contains((String)objOldValue) && !(setCompanyOwnedAssetType.Contains((String)objUpdatedValue) && setCompanyOwnedAssetType.Contains((String)objOldValue)));
    }
    
/*
* @description: Method to prepare the required sets to perform the asynchronous operation 
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    
    public static void iterateToUpdateIVDAndRemoveCoveredProduct(Map<Id, sObject> existingRecords,List<Sobject> records) {
        
        Map<Id,SVMXC__Installed_Product__c> mapInstallProductToIds = new Map<Id,SVMXC__Installed_Product__c>();
        Set<Id> setReturnedInstalledProductIds= new Set<Id>();
        
        for (SVMXC__Installed_Product__c objInstalledProduct: (List<SVMXC__Installed_Product__c >)records) {
            SVMXC__Installed_Product__c objOldInstalledProduct= (SVMXC__Installed_Product__c)(existingRecords.get(objInstalledProduct.Id));
            
            if (objInstalledProduct.Installed_Product_Upgrade_Type__c  != objOldInstalledProduct.Installed_Product_Upgrade_Type__c ) {
                mapInstallProductToIds.put(objInstalledProduct.Id,objInstalledProduct);
            }
            //DCP-43163 : Remove association with contract when IP is returned
            if(objInstalledProduct.SVMXC__Status__c != objOldInstalledProduct.SVMXC__Status__c && objInstalledProduct.SVMXC__Status__c == 'Returned') {
                setReturnedInstalledProductIds.add(objInstalledProduct.id);
            }
        }
        
        //DCP-43163 : Remove association with contract when IP is returned
        if(!setReturnedInstalledProductIds.isEmpty()) {
            removeCoveredProduct(setReturnedInstalledProductIds);
        }
        
        if(mapInstallProductToIds!=null && !mapInstallProductToIds.isEmpty()) {
            updateIVDOnRelatedCases(mapInstallProductToIds);
        }
    }

/*
* @description: Remove association for covered product
* @author: Kushagra Desai
* @date: 03/28/2022
* @returns: void
*/
    public static void removeCoveredProduct(Set<Id> setInstalledProductIds) {
        List<SVMXC__Service_Contract_Products__c> lstCoveredProduct = new List<SVMXC__Service_Contract_Products__c>();
        List<SVMXC__Installed_Product__c> lstLoanerInstalledProduct = new InstalledProductsSelector().selectLoanerInstalledProductById(new List<Id>(setInstalledProductIds));
        if(lstLoanerInstalledProduct.isEmpty()){
            return;}
        Set<Id> setLoanerInstalledProductIds = UtilsCollection.getSetOfIds(lstLoanerInstalledProduct);
        List<SVMXC__Service_Contract_Products__c> lstCoveredProductAssociated = new CoveredProductSelector().selectOrderedCoveredProductsForInstalledProduct(setInstalledProductIds);
        for(SVMXC__Service_Contract_Products__c objCoveredProduct : lstCoveredProductAssociated) {
            if(setLoanerInstalledProductIds.contains(objCoveredProduct.SVMXC__Installed_Product__c)) {
                lstCoveredProduct.add(objCoveredProduct);
            }
        }
        if(!lstCoveredProduct.isEmpty()) {
            delete lstCoveredProduct;
        }
    }

/*
* @description: Method to hold the logic for IP record sharing with Distribution Users
* @author: Raviteja Vakkalagadda
* @date: 03/28/2022
* @returns: void
*/
    
    public static void ipSharingWithDistributionUsers(Boolean hasRunPartnerSharing,List<SObject> records,Map<Id, sObject> existingRecords) {
        // NOTE: hasRunPartnerSharing serves no purpose with this being commented out. All references to it can be deleted
        
        if (!hasRunPartnerSharing) {
            List<SVMXC__Installed_Product__c> changedRecords = UtilsObject.filterForFieldChanges(records, existingRecords, new List<String> {'Regulatory_Type__c', 'SVMXC__Product__c','SVMXC__Company__c'}); //CMCP-14: Added SVMXC__Company__c to run on Company Field Change.
            InstalledProductsService.shareWithDistributorUsers(changedRecords);
            InstalledProducts.hasRunPartnerSharing = true;
        }
    }

/*
* @description: DCP- 31083 Update IVD Upgrade Field on related Cases based on Installed Product IVD Indicator
* @author: Digvijay Singh
* @date: 03/28/2022
* @returns: void
*/
    
    public static void updateIVDOnRelatedCases(Map<Id,SVMXC__Installed_Product__c> mapInstallProductIds) {
        
        List<Case> lstCaseTobeUpdated=new List<Case>();
        List<Associated_Product__c> lstAssociatedProductTobeUpdated = new List<Associated_Product__c>();
        // list with Closed/Completed Case Statuses
        list<string> lstClosedStatuses = new list<string>();
        prepareListOfCloseStatuses(lstClosedStatuses);
        
        //Update the Open when Cases When the related IP has IVD Upgrade
        if(!mapInstallProductIds.IsEmpty()) {
            for(Case obj : new CasesSelector().selectCasesRelatedtoIP(mapInstallProductIds.keySet())) {
                if(mapInstallProductIds.ContainsKey(obj.SVMXC__Component__c) && mapInstallProductIds.get(obj.SVMXC__Component__c)!=null &&  !lstClosedStatuses.Contains(obj.status)) {
                    obj.Installed_Product_Upgrade_Type__c=mapInstallProductIds.get(obj.SVMXC__Component__c).Installed_Product_Upgrade_Type__c;
                    lstCaseTobeUpdated.add(obj);
                }
            }
            
            //Update the  AssociatedProduct When the related IP has IVD Upgrade
            for(Associated_Product__c objAP : new AssociatedProductSelector().selectAPwithInstallProduct(mapInstallProductIds.keySet())) {
                if(mapInstallProductIds.ContainsKey(objAP.Installed_Product__c) && mapInstallProductIds.get(objAP.Installed_Product__c)!=null && !lstClosedStatuses.Contains(objAP.Case__r.status) ) {
                    objAP.Installed_Product_Upgrade_Type__c = mapInstallProductIds.get(objAP.Installed_Product__c).Installed_Product_Upgrade_Type__c;
                    lstAssociatedProductTobeUpdated.add(objAP);
                }
            }
            
        }
        
        updateCaseAndAssociatedProduct(lstCaseTobeUpdated,lstAssociatedProductTobeUpdated);
    }
    
/**
* @author Digvijay Singh
* @description  - Method to prepare a list of closed statuses
*/
    
    public static void prepareListOfCloseStatuses(list<string> lstClosedStatuses) {

        lstClosedStatuses.add(Label.CaseStatusCompleted);
        lstClosedStatuses.add(Label.CaseStatusPendingQAReview); 
        lstClosedStatuses.add(Label.CaseStatusPendingLogisticsReview);
        lstClosedStatuses.add(Label.CaseStatusClosed);
        lstClosedStatuses.add(Label.CaseStatusReopenRequested);
        lstClosedStatuses.add(Label.CaseStatusReopened);
        lstClosedStatuses.add(Label.CaseStatusClosedDuplicate);
    }
    
/**
* @author Digvijay Singh
* @description  - Method to prepare a list of closed statuses
*/
    
    public static void updateCaseAndAssociatedProduct(List<Case> lstCaseTobeUpdated,List<Associated_Product__c> lstAssociatedProductTobeUpdated) {
        if(lstCaseTobeUpdated!=null && !lstCaseTobeUpdated.IsEmpty()) {
            update lstCaseTobeUpdated;
        }
        
        if(lstAssociatedProductTobeUpdated !=null && !lstAssociatedProductTobeUpdated.IsEmpty()) {
            update lstAssociatedProductTobeUpdated;
        }
    }
}