/***************************************************************************************************************************************
* NAME   : WorkOrderDetailForTemplate
* DESCRIPTION  : Controller class for WorkOrderNotifyCPOnSubmitEstimateTemp VF Component.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 09-April-2019  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay                09-April-2019          Initial Version. Added logic to Fetch Work Details Records for WorkOrderNotifyCPOnSubmitEstimateTemp VF Component.

****************************************************************************************************************************************/ 

public  class WorkOrderDetailForTemplate
{
    public Id workOrderId {get;set;}
    
    
    /**
     *  @author Digvijay Singh
     *  @description - Fetches the Work Detail records for the work Order. 
     *               
     **/
    public List<SVMXC__Service_Order_Line__c> getlistworkDetails()
    {
        return new WorkDetailsSelector().selectWorkDetailRecords(workOrderId); 
    }
}