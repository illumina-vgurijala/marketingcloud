/***************************************************************************************************************************************
* NAME         : ProactiveRunDetails
* DESCRIPTION  : Proactive Run Detail records creation from Proactive system and other operations performed on PRD records are handled as 
*                 part of this class
*                    
* @AUTHOR      : 
* @DATE        : 08-Nov-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Raviteja Vakkalagadda    08-11-2021  
* Abhishek Yadav           27 oct 2023       Added Code for deleting Associated Product on deleting Proactive Run Detials on onBeforeDelete method  
* Dhairya Shah             17 April 2024     CMCM-6760 - Removed the method -onBeforeDelete()     
* Abhishek Yadav           27 oct 2023       Added Code for deleting Associated Product on deleting Proactive Run Detials on onBeforeDelete method  
* Dhairya Shah             14 May 2024       Added the method -onBeforeDelete()  
****************************************************************************************************************************************/
public with sharing class ProactiveRunDetails extends ilib_SObjectDomain {
    
    private static final String LOG_TITLE = 'ProactiveRunDetails';
    public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
    public static final String STRING_WORK_ORDER_STATUS_CLOSED = 'Closed';
    public static final String ASSOCIATED_PRODUCT_FEATURE_FLAG = 'ServiceAssociatedProducts';
    
    /*constructor. call to super class constructor
*/
    public ProactiveRunDetails(List<Proactive_Run_Detail__c> sObjectList) {
        super(sObjectList);
        ilib_LogEvent.rootTitle = LOG_TITLE;
    }
    
    /*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /**Constructor */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ProactiveRunDetails(sObjectList);
        }
    }
    
    /**
*  @author Raviteja Vakkalagadda 
*  @description - Logic to validate the user to edit the Proactive run detail record only when the corresponding WO is not closed or completed 
*               
**/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        set<Id> prdWOIds = new set<id>();
        List<SVMXC__Service_Order__c> woList = new List<SVMXC__Service_Order__c>();
        
        for(Proactive_Run_Detail__c prd:(List<Proactive_Run_Detail__c>)records) {
            Proactive_Run_Detail__c objOldPrdRec = (Proactive_Run_Detail__c)(oldRecords.get(prd.Id));
            if(prd.Notes__c != objOldPrdRec.Notes__c) {
                prdWOIds.add(prd.Work_Order__c);
            }
        }
        if(!prdWOIds.isEmpty()) {
            woList.addAll(new WorkOrdersSelector().selectWorkOrderByIDAndStatus(prdWOIds));
        }
        system.debug('***woList**'+woList);
        
        if(!woList.isEmpty()) {
            for(Proactive_Run_Detail__c prd:(List<Proactive_Run_Detail__c>)records) {
                prd.addError(System.Label.ProactiveRunDetailEdit);
            }
        }
    }

/***************************************************************************************
* Author: Dhairya Shah
* Description: added onBeforeDelete() methode to delete associate product list
* Params :None
*****************************************************************************************/
    public override void onBeforeDelete() {
        
        set<Id> prdIds = new set<id>();
        List<Associated_Product__c> associatedProdList = new List<Associated_Product__c>();
        for(Proactive_Run_Detail__c prd:(List<Proactive_Run_Detail__c>)records) {
            prdIds.add(prd.Id);
        }
            associatedProdList.addall(new AssociatedProductSelector().associatedProductRecords(prdIds));
            if(!associatedProdList.isEmpty()) {
                DELETE associatedProdList;
            }
    }
}