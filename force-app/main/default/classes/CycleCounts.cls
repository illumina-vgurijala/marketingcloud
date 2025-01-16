/**
*    @author Soumya Sahu
*    @date   2019-04-01
*    @description   : DCP-24618 - Cycle Count Program functionality
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Soumya Ranjan Sahu          01 Apr 2019            Added after insert and after update method
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class CycleCounts extends ilib_SObjectDomain
{
	public static final String STRING_STATUS_INITIATED = 'Initiated';
	public static final String STRING_STATUS_INPROGRESS = 'In Progress';
	public static final String STRING_STATUS_COMPLETED = 'Completed';

	/*
	 * Constructor
	 */
	public CycleCounts(List<Cycle_Count__c> sObjectList) {
		super(sObjectList);
	}

	 /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable{
	    
        /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList){
            return new CycleCounts(sObjectList);
        }
    }

    /**
    *  @author Soumya
    *  @description - To be executed, when the cycle count is inserted.
    **/ 
    
    public override void onBeforeInsert(){
    	set<id> setWOIds = new set<id>();
    	for(Cycle_Count__c objCycleCount : (List<Cycle_Count__c>)records){
    		if(objCycleCount.Work_Order__c!= NULL){
    			setWOIds.add(objCycleCount.Work_Order__c);
    		}
    	}
    	if(setWOIds.size()>0)
		updateFSAndOwnerFromWorkOrder(setWOIds);
    }
    /**
    *  @author Soumya
    *  @description - To be executed, when the cycle count is inserted. 
    *               1. Checks if Cycle Count is created, update the Work Order status.
    **/
    public override void onAfterInsert(){
    	//To store WO vs Cycle Count List in a Map
    	set<Id> setCycleCountWOs = new set<id>();
    	for(Cycle_Count__c objCycleCount : (List<Cycle_Count__c>)records){
    		if(objCycleCount.Work_Order__c!= NULL){
    			setCycleCountWOs.add(objCycleCount.Work_Order__c);
    		}
    	}
    	if(setCycleCountWOs.size()>0){
    		updateOrderStatusOnWorkOrder(setCycleCountWOs);
    	}

    }

	/**
    *  @author Soumya
    *  @description - To be executed, when the Cycle Count is updated. 
    **/
    public override void onAfterUpdate(Map<Id, sObject> oldRecords){
    	//To store WO vs Cycle Count List in a Map
    	set<Id> setCycleCountWOs = new set<id>();
    	for(Cycle_Count__c objCycleCount : (List<Cycle_Count__c>)records){
    		Cycle_Count__c objOldCycleCount = (Cycle_Count__c)(oldRecords.get(objCycleCount.Id));
    		//Only to trigger when status or Work Order fields are updated
    		if(objCycleCount.Work_Order__c!= NULL && (objCycleCount.Status__c != objOldCycleCount.Status__c)){
    			setCycleCountWOs.add(objCycleCount.Work_Order__c);
    		}
    	}
    	if(setCycleCountWOs.size()>0){
    		updateOrderStatusOnWorkOrder(setCycleCountWOs);
    	}
    }
    /**
    *  @author Soumya
    *  @description - To be executed, when the Cycle Count is deleted. 
    **/
    public override void onAfterDelete(){
    	//To store WO vs Cycle Count List in a Map
    	set<Id> setCycleCountWOs = new set<id>();
    	for(Cycle_Count__c objCycleCount : (List<Cycle_Count__c>)records){
    		if(objCycleCount.Work_Order__c!= NULL){
    			setCycleCountWOs.add(objCycleCount.Work_Order__c);
    		}
    	}
    	if(setCycleCountWOs.size()>0){
    		updateOrderStatusOnWorkOrder(setCycleCountWOs);
    	}
    }
    /**
    *  @author Soumya
    *  @description - To update the work order status as per DCP-24618 based on all cycle counts of associated WO. 
    **/
    public void updateOrderStatusOnWorkOrder(set<id> setCycleCountWOs){
    	List<Cycle_Count__c> lstCycleCounts = new CycleCountsSelector().selectCycleCountWithWO(setCycleCountWOs);
    	Map<id,List<Cycle_Count__c>> idWOToCycleCounts = new Map<id,List<Cycle_Count__c>>();
    	List<SVMXC__Service_Order__c> lstWorkOrdersToUpdate = new List<SVMXC__Service_Order__c>();
    	//To build a map of WO and its Cycle Counts
    	if(lstCycleCounts.size()>0){
    		For(Cycle_Count__c objCycleCount :lstCycleCounts ){
    			if(!idWOToCycleCounts.containsKey(objCycleCount.Work_Order__c)){
    				idWOToCycleCounts.put(objCycleCount.Work_Order__c, new List<Cycle_Count__c>());
    				idWOToCycleCounts.get(objCycleCount.Work_Order__c).add(objCycleCount);
    			}
    			else{
    				idWOToCycleCounts.get(objCycleCount.Work_Order__c).add(objCycleCount);
    			}
    		}
    	}
    	//To update work order status
    	For(id idWO : idWOToCycleCounts.keySet()){
    		if(idWOToCycleCounts.get(idWO).size()>0){
    			integer intCountInitiated = 0;
    			integer intCountInProgress = 0;
    			integer intCountCompleted = 0;
    			string strWONewStatus='';
    			for(Cycle_Count__c objCycleCount :idWOToCycleCounts.get(idWO)){
    				if(objCycleCount.Status__c==STRING_STATUS_INITIATED)
    					intCountInitiated++;
    				else if(objCycleCount.Status__c==STRING_STATUS_COMPLETED)
    					intCountCompleted++;
    				else
    					intCountInProgress++;
    				
				}
				strWONewStatus=(idWOToCycleCounts.get(idWO).size()==intCountInitiated)?STRING_STATUS_INITIATED:
								((idWOToCycleCounts.get(idWO).size()==intCountCompleted)?STRING_STATUS_COMPLETED:STRING_STATUS_INPROGRESS);
    		
    			if(idWOToCycleCounts.get(idWO)[0].Work_Order__r.SVMXC__Order_Status__c !=strWONewStatus){
    				SVMXC__Service_Order__c objWO = new SVMXC__Service_Order__c(id =idWO, SVMXC__Order_Status__c = strWONewStatus);
    				lstWorkOrdersToUpdate.add(objWO);
    			}
    		}
    	}

    	if(lstWorkOrdersToUpdate.size()>0)
    		update lstWorkOrdersToUpdate;
    }

    /**
    *  @author Soumya
    *  @description - To update the Cycle count's Field Support and Owner from associated work order while creation as per DCP-24618
    **/
    public void updateFSAndOwnerFromWorkOrder(set<id> setCycleCountWOs){
    	List<SVMXC__Service_Order__c> lstWorkOrders = new WorkOrdersSelector().selectWorkOrders(setCycleCountWOs);
    	if(lstWorkOrders.size()>0){
    		Map<id,SVMXC__Service_Order__c> idToWorkOrder = new Map<id,SVMXC__Service_Order__c> (lstWorkOrders);

    		//For copying the value from Work Order
    		for(Cycle_Count__c objCycleCount : (List<Cycle_Count__c>)records){
    			if(objCycleCount.Work_Order__c!= NULL && idToWorkOrder.containsKey(objCycleCount.Work_Order__c)){
    				objCycleCount.Field_Support__c = idToWorkOrder.get(objCycleCount.Work_Order__c).SVMXC__Group_Member__c;
    				objCycleCount.OwnerId = idToWorkOrder.get(objCycleCount.Work_Order__c).OwnerId;    				
    			}
    		}
    	}

    }
}