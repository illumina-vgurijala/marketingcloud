/***************************************************************************************************************************************
* NAME         : APQueueable
* DESCRIPTION  :  APQueueable.
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 7-Feb-2024
* @testclasses : TestAssociatedProduct
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav            7-Feb-2024           Initial Version.   
* Abhishek Yadav            27-Feb-2024          CMCM-273
* Abhishek Yadav            12-Jun-2024          CMCM-8298 - Removed the insert and update logic of applied contract and resolve the issue deletion of Applied contract
****************************************************************************************************************************************/
public class APQueueable implements Queueable {
    String strMethodtoExecute;
    Set<Id> setAssociatedProductIds = new set<Id>();
    Set<Id> setCaseIds = new set<Id>();
    Set<Id> setWorkOrderIds = new set<Id>();
    Set<Id> setAppliedContractIds = new set<Id>();
    /*
    * Constructor
    */
    public APQueueable(String strMethodtoExecute , Set<Id> setAssociatedProductIds , Set<Id> setCaseIds , Set<Id> setWorkOrderIds , Set<Id> setAppliedContractIds) {
        this.strMethodtoExecute = strMethodtoExecute;
        this.setAssociatedProductIds = setAssociatedProductIds;
        this.setCaseIds = setCaseIds;
        this.setWorkOrderIds = setWorkOrderIds;
        this.setAppliedContractIds = setAppliedContractIds;
    }
     /**
    *  @author Abhishek
    *  @description - Holds methods that need to be Run in Queuable context from Associatedproduct Class
    *                 
    **/
    public void execute(QueueableContext qc) {
        try {
            if(strMethodtoExecute == 'deleteConsumableWarrantyContract' && (!setAssociatedProductIds.IsEmpty() || !setCaseIds.IsEmpty() || !setWorkOrderIds.isEmpty())) {
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteConsumableWarrantyContract(setAssociatedProductIds , setCaseIds , setWorkOrderIds);
            }
            // Call Applied Contract Reated method
            if(strMethodtoExecute == 'deleteAppliedContractEntitlement' && !setAppliedContractIds.isEmpty()) {
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().deleteAppliedContractEntitlement(setAppliedContractIds); 
            }
        } catch(Exception e) {
            ApexExceptions.emit('APQueueable', e, ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw e;
        } 
    }
}