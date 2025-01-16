/****************************************************************************************************************************************
* NAME         : WorkOrdersCustomerAbandonedService
* DESCRIPTION  : To prefix "Abandoned" to WorkOrder's subject when Abandoned Reason is selected from SFM
*                    
* @AUTHOR : Gladis
* @DATE   : 05/05/2021 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Gladis                05/05/2021              Initial Version.    
* Deepika              17-May-2021          DCP-38815 -Populating Verification Result     	
****************************************************************************************************************************************/

public with sharing class WorkOrdersCustomerAbandonedService {
    
    public static final String STRING_ABANDONED_CODE='BUS Customer abandoned or unresponsive'; // DCP-38815
   
    /**
     *  @author       : Gladis
     *  @description  : prefixing "Abandoned" to WorkOrder's subject
     *  @return       : void
     */
    public static void updateCustomerAbandonedWorkOrder(SVMXC__Service_Order__c record , SVMXC__Service_Order__c oldRecord){              
        
        if( record.Abandoned_Reason__c != oldRecord.Abandoned_Reason__c && !record.SVMX_PS_Subject__c.startsWithIgnoreCase(System.Label.Work_Order_Customer_Abandoned_Prefix)   ){
            record.SVMX_PS_Subject__c = System.Label.Work_Order_Customer_Abandoned_Prefix +' '+record.SVMX_PS_Subject__c;
            record.Additional_Detail__c = record.Additional_Detail__c != null ? record.Additional_Detail__c +'  '+System.Label.Work_Order_Verification_Result : System.Label.Work_Order_Verification_Result; // Added by Vishal for CMCM-10578
        }
    }
    /*
    *  @AUTHOR: KD
    *  @DESCRIPTION: CreAte Associated Code for Abandoned WO
    *  @PARAM : Set WO id
    *  @RETURN:  void
    */
    public static void createAssociatedCodeOnAbandonedWO(Set<Id> setAbandonedWOId){
        
        List<Associated_Codes__c> lstWOAssociationCodesToInsert = new List<Associated_Codes__c>();
        List<Code_Library__c> lstCodeLibrary = new CodeLibrarySelector().selectCodeLibraryByTitle(new set<string>{STRING_ABANDONED_CODE});
        if(lstCodeLibrary.isEmpty()){
            return;
        }
        Code_Library__c objCodeLibrary = lstCodeLibrary[0];
        Set<Id> setWOIdWithExistingCode = UtilsCollection.getSetOfIds(new AssociatedCodeSelector().selectParticularAssociatedCodesOnWorkOrders(setAbandonedWOId,STRING_ABANDONED_CODE),'Work_Order__c');
        for(Id idWO : setAbandonedWOId){
            if(setWOIdWithExistingCode.contains(idWO)){
                continue;
            }
            lstWOAssociationCodesToInsert.add(new Associated_Codes__c(
                Code_Title__c = objCodeLibrary.id,
                Work_Order__c = idWO,
                Code_Type__c = objCodeLibrary.Code_Type__c,
                Case_Type__c = objCodeLibrary.Case_Type__c,
                Code_Description__c = objCodeLibrary.Code_Description__c
            ));
        }
        if(!lstWOAssociationCodesToInsert.IsEmpty()){
            try{
                insert lstWOAssociationCodesToInsert;
            }catch(Exception e){
                ApexExceptions.emit('createAssociatedCodeOnAbandonedWO',e);
            }
        }
    }     
}