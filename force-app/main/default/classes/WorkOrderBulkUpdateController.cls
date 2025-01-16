/**
    *  @author Siddartha Reddy Kalam 
    *  @description  
    *  @return List of open Work Orders related to Account to field support or Field Support in LWC and updates selected work orders
    **/
public with sharing class WorkOrderBulkUpdateController {
     /**
    *  @author Siddartha Reddy Kalam 
    *  @description returns list of open work orders related to Account to field support or Field Support id
    *  @param account to field support id or field support id
    *  @return List
    **/
    @AuraEnabled
    public static List<WorkOrderWrapper> getRelatedWorkOrders(String recordID){
        try{
        List<WorkOrderWrapper> lstWO = new List<WorkOrderWrapper>();
        system.debug('recordID::'+recordID);
        if((recordID).startsWith('a22')){
        for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().getFieldSupportWorkOrders(recordID))
        {
            
            	lstWO.add(new WorkOrderWrapper(wo.SVMXC__Group_Member__r.Name, wo.SVMXC__Company__r.Name,wo.id,wo.Name,wo.SVMXC__Order_Type__c, wo.SVMX_PS_Subject__c,wo.SVMXC__Order_Status__c, wo.owner.Name));
            
        }
    }
    else if((recordID).startsWith('a93')){
        for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().getAccountToFieldSupportWorkOrders(recordID))
        {
            
            	lstWO.add(new WorkOrderWrapper(wo.SVMXC__Group_Member__r.Name, wo.SVMXC__Company__r.Name,wo.id,wo.Name,wo.SVMXC__Order_Type__c, wo.SVMX_PS_Subject__c,wo.SVMXC__Order_Status__c, wo.owner.Name));
            
        }
    }
   	return lstWO;
        }
      catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }  
    }

    /*
	* Work Order Wrapper Class
	*/
     public class WorkOrderWrapper{
     @AuraEnabled public id woId ;
     @AuraEnabled public string woName = '';
     @AuraEnabled public string fieldSupportName = '';
     @AuraEnabled public string accountName = '';
     @AuraEnabled public string orderType = '';
     @AuraEnabled public string subject = '';
     @AuraEnabled public string orderStatus = '';
     @AuraEnabled public string ownerName = '';
	 /*
	 * Work Order Wrapper Constructor
	 */
     public WorkOrderWrapper(string fsuppName, string acctName, id woId,string woName, string orderType, string subject,string orderStatus, string ownerName)
        {
            this.fieldSupportName = fsuppName;
            this.accountName = acctName;
            this.woId = woId;
            this.woName = woName;
            this.orderType = orderType;
            this.subject = subject;
            this.orderStatus = orderStatus;
            this.ownerName = ownerName;
          
        }
    }
    /**
    *  @author Siddartha Reddy Kalam 
    *  @description  
    *  @update method: Will update field support value from above returned and selected Work orders for transfer
    **/
    @AuraEnabled
    public static String updateRelatedWO(List<SVMXC__Service_Order__c> workOrderRecs){
        String status = null;
        system.debug('service_order_list::'+workOrderRecs);
        Database.SaveResult[] updateWoList = database.update(workOrderRecs, false);
        Map<Id, String> errorsMapping = new Map<Id, String>();
        for(Integer i=0;i<updateWoList.size();i++){
            if (updateWoList.get(i).isSuccess()){
                updateWoList.get(i).getId();
                
            }else if (!updateWoList.get(i).isSuccess()){
                // DML operation failed
                Database.Error error = updateWoList.get(i).getErrors().get(0);
                String failedDML = error.getMessage();
                workOrderRecs.get(i);//failed record from the list
                system.debug('Failed ID'+workOrderRecs.get(i).Id);
                errorsMapping.put(workOrderRecs.get(i).Id, failedDML);
            }
            
        }   
        
        for(SVMXC__Service_Order__c wo : workOrderRecs){
            if(errorsMapping.get(wo.Id)!=null){
                String errorMessage = errorsMapping.get(wo.Id);
                errorsMapping.remove(wo.Id);
                system.debug('wo: '+wo.Name);
                errorsMapping.put(wo.Id, wo.Name +' - '+ errorMessage);
            }
        }
        
        if(!errorsMapping.values().isEmpty()){
            status = JSON.serialize(errorsMapping.values());
        }
        return status;
    }
}