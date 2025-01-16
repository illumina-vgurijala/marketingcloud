/***************************************************************************************************************************************
* NAME   : WorkOrderResources 
* DESCRIPTION  : Domain class for WorkOrderResourceTrigger.
*                    
* @AUTHOR : Digvijay Singh
* @DATE   : 20-May-2018  
* Test class for 75%: TestDataBillableFlowQueueable, TestPopulateLastPMDateOnIP, TestPreventativeMaintenance_WOHelper, TestServiceReportEmailController, 
                      TestWorkOrderBulkUpdateController, TestWorkOrderDataSender, TestWorkOrderResourceSelector,TestWorkOrderResources
* Test class for 90%: TestDataBillableFlowQueueable, TestPopulateLastPMDateOnIP, TestPreventativeMaintenance_WOHelper, TestServiceReportEmailController, 
                      TestWorkOrderBulkUpdateController, TestWorkOrderDataSender, TestWorkOrderResourceSelector,TestWorkOrderResources
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                   DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 Digvijay Singh               30-May-2019          Initial Version. Added logic for DCP-25271 to prevent WOR record deletion/Re-parenting on Completed/Closed Work Orders. 
 Akshay Mohan                 14-June-2021         DCP-38968: Add sharing logic for sharing opportunities
 Nitin                        31-Aug-2022          CMSI-222 Instrumentation 
******************************************************************************************************/

public with sharing class WorkOrderResources extends ilib_SObjectDomain{

 public static final String STRING_WORK_ORDER_STATUS_COMPLETED = 'Completed';
 public static final String STRING_WORK_ORDER_STATUS_CLOSED = 'Closed';
 public static final String STRING_WORK_ORDER_STATUS_CANCELLED = 'Canceled';
 public static final String STRING_WORK_ORDER_STATUS_REOPENREQUESTED = 'Reopen Requested';
 private static ilib_Queueablethread triggerThread;//DCP-38968-trigger thread    
 private static final String LOG_TITLE = 'WorkOrderResources';
 public static final String NULLSTR = 'Null';
 
		/*
         * Constructor
         */
 public WorkOrderResources (List<SVMXC__Work_Order_Resource__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new WorkOrderResources(sObjectList);
        }
  }
  
  
   /**
    *  @author Digvijay Singh
    *  @description - To be executed, when the Work Order Resource is deleted. 
    **/
    public override void onBeforeDelete(){
       set<id> setWOId=new set<id>();
       Map<id, String> mapWorkOrdertoStatus= new Map<id,String>(); 
	   Map<id,SVMXC__Service_Order__c> mapWOIdtoWO = new Map<Id,SVMXC__Service_Order__c>();
        for(SVMXC__Work_Order_Resource__c objWO:(List<SVMXC__Work_Order_Resource__c>)records){
          setWOId.add(objWO.SVMXC__Work_Order__c);
        }
        ilib_LogEvent.info('setWOId : '+setWOId);
         for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().selectWorkOrders(setWOId)){           
                 mapWorkOrdertoStatus.put(wo.Id, wo.SVMXC__Order_Status__c);
				 mapWOIdtoWO.put(wo.Id,wo);
          } 
          ilib_LogEvent.info('mapWorkOrdertoStatus : '+mapWorkOrdertoStatus);
          ilib_LogEvent.info('mapWOIdtoWO : '+(mapWOIdtoWO != Null ? String.valueof(mapWOIdtoWO.keySet()):NULLSTR));   
       
         
       for(SVMXC__Work_Order_Resource__c objWO:(List<SVMXC__Work_Order_Resource__c>)records){
         System.debug('here '+objWO.SVMXC__Work_Order__r.SVMXC__Order_Status__c);
            if(objWO.SVMXC__Work_Order__c != null && !mapWorkOrdertoStatus.isEmpty() && (mapWorkOrdertoStatus.get(objWO.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_COMPLETED || mapWorkOrdertoStatus.get(objWO.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_CLOSED ||
             mapWorkOrdertoStatus.get(objWO.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_REOPENREQUESTED||
			 (mapWorkOrdertoStatus.get(objWO.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_CANCELLED && mapWOIdtoWO.get(objWO.SVMXC__Work_Order__c).SVMXC__Is_PM_Work_Order__c == false && mapWOIdtoWO.get(objWO.SVMXC__Work_Order__c).SVMXC__Order_Type__c != 'Preventative Maintenance'))){
                objWO.addError(Label.WOResourceErrorMessage);
            } 
        }
    }
    
    
    /**
    *  @author Digvijay Singh
    *  @description - To be executed, when the Work Order Resource is updated. 
    **/
     public override void onBeforeUpdate(Map<Id, SObject> oldRecords){
    
     set<id> setWOId=new set<id>();
     Map<id, String> mapWorkOrdertoStatus= new Map<id,String>(); 
     for(SVMXC__Work_Order_Resource__c objWO:(List<SVMXC__Work_Order_Resource__c>)records){
          SVMXC__Work_Order_Resource__c objOldWO = (SVMXC__Work_Order_Resource__c)(oldRecords.get(objWO.Id));
          setWOId.add(objOldWO.SVMXC__Work_Order__c);
        }
        
              ilib_LogEvent.info('setWOId : '+setWOId);
      for(SVMXC__Service_Order__c wo: new WorkOrdersSelector().selectWorkOrders(setWOId)){           
                 mapWorkOrdertoStatus.put(wo.Id, wo.SVMXC__Order_Status__c);
          } 
          ilib_LogEvent.info('mapWorkOrdertoStatus : '+mapWorkOrdertoStatus);
          System.debug('mapWorkOrdertoStatus..'+mapWorkOrdertoStatus);
        
       for(SVMXC__Work_Order_Resource__c objWOR : (List<SVMXC__Work_Order_Resource__c>)records){
            SVMXC__Work_Order_Resource__c objOldWOR = (SVMXC__Work_Order_Resource__c)(oldRecords.get(objWOR.Id));
             System.debug('objWOR.SVMXC__Work_Order__c..'+objWOR.SVMXC__Work_Order__c);
              System.debug('objoldWOR.SVMXC__Work_Order__c..'+objOldWOR.SVMXC__Work_Order__c);
            
            if((objWOR.SVMXC__Work_Order__c!=objOldWOR.SVMXC__Work_Order__c) && !mapWorkOrdertoStatus.isEmpty() && (mapWorkOrdertoStatus.get(objoldWOR.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_COMPLETED || mapWorkOrdertoStatus.get(objoldWOR.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_CLOSED
               ||mapWorkOrdertoStatus.get(objoldWOR.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_CANCELLED || mapWorkOrdertoStatus.get(objoldWOR.SVMXC__Work_Order__c)==STRING_WORK_ORDER_STATUS_REOPENREQUESTED))
            {
               objWOR.addError(Label.WOResourceErrorMessage);
                
            }
    }
    
    }

     /**
     *  @AUTHOR:  Joshith K
     *  @DESCRIPTION: after Insert logic to update the Field_Support_IDs in work order if the technecian is not null
     *  
     */ 
    public override void onAfterInsert(){
        //DCP-38968: Start- Initialize the trigger thread queueable
        triggerThread = new ilib_Queueablethread('WorkOrderResourcesAfterInsert');
        //DCP-38968: End- Initialize the trigger thread queueable

		Map<Id,Id> mapWORtoWOtoshare=new  Map<Id,Id>();											 
        Set<Id> setWorkOrderIdsforUpdate  = new Set<Id>();
        Set<Id> setPMWorkOrderIdsforUpdate  = new Set<Id>();
        //DCP-38968: Start- Process all resources for a work order for opporunity sharing
        Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResources = UtilsCollection.getMapOfIdToSObjects(records,'SVMXC__Work_Order__c');
        processOppShareQueueable(mapWOIdToWOResources,false);
        //DCP-38968: End- Process all resources for a work order for opporunity sharing
        Map<id ,SVMXC__Service_Order__c> mapWOIDToWorkOrder=new Map<id,SVMXC__Service_Order__c>();
        
        //DCP-38968: Start- Use map key set instead
        for(SVMXC__Service_Order__c obj:new WorkOrdersSelector().selectWorkOrders(mapWOIdToWOResources.keySet())){
        //DCP-38968: End- Use map key set instead
            if(obj.SVMXC__Order_Type__c==Label.WorkOrderTypePreventativeMaintenance){
                mapWOIDToWorkOrder.put(obj.Id, obj);
            }
        }
        ilib_LogEvent.info('mapWOIDToWorkOrder : '+(mapWOIDToWorkOrder != Null ? String.valueof(mapWOIDToWorkOrder.keySet()):NULLSTR));   

        for(SVMXC__Work_Order_Resource__c objWORes:(List<SVMXC__Work_Order_Resource__c>)records){
            if(objWORes.SVMXC__Work_Order__c!=null&&objWORes.SVMXC__Group_Member__c!=null && !mapWOIDToWorkOrder.ContainsKey(objWORes.SVMXC__Work_Order__c)){
                setWorkOrderIdsforUpdate.add(objWORes.SVMXC__Work_Order__c);
            }else if(objWORes.SVMXC__Work_Order__c!=null&&objWORes.SVMXC__Group_Member__c!=null && mapWOIDToWorkOrder.ContainsKey(objWORes.SVMXC__Work_Order__c)){
                setPMWorkOrderIdsforUpdate.add(objWORes.SVMXC__Work_Order__c);
            }
			  
		//DCP-31721
         if(mapWOIDToWorkOrder!=null && !mapWOIDToWorkOrder.ContainsKey(objWORes.SVMXC__Work_Order__c)){
				mapWORtoWOtoshare.put(objWORes.SVMXC__Group_Member__c,objWORes.SVMXC__Work_Order__c); 
				}
        }
        // ilib_LogEvent.info('setWorkOrderIdsforUpdate : '+setWorkOrderIdsforUpdate);
        //  if(!setWorkOrderIdsforUpdate.isEmpty()) {
        //     updateFieldSupportIdsOnWorkOrderAsync(setWorkOrderIdsforUpdate);
        //   }
        //   ilib_LogEvent.info('setPMWorkOrderIdsforUpdate : '+setPMWorkOrderIdsforUpdate);
        //    if(!setPMWorkOrderIdsforUpdate.isEmpty()) {
        //     updateFieldSupportIdsOnWorkOrder(setPMWorkOrderIdsforUpdate);
        //   }
          ilib_LogEvent.info('mapWORtoWOtoshare : '+mapWORtoWOtoshare);
		  //DCP-31721	
		 if(!mapWORtoWOtoshare.IsEMpty() ){
              shareWOwithWOR(mapWORtoWOtoshare,new  Map<Id,Id>());
          }									
        //DCP-38968: Start- Queue Async jobs of trigger
        triggerAsyncOperations();
        //DCP-38968: End- Queue Async jobs of trigger
    }

     /**
     *  @AUTHOR:  Joshith K
     *  @DESCRIPTION: after update logic to update the Field_Support_IDs in work order if the technecian changed
     *  
     */
     public override void onAfterUpdate(Map<Id, SObject> mapOld){
        //DCP-38968: Start- Initialize the trigger thread queueable
        triggerThread = new ilib_Queueablethread('WorkOrderResourcesAfterUpdate');
        //DCP-38968: End- Initialize the trigger thread queueable
      Set<Id> setWorkOrderId = new Set<Id>();
		Map<Id,Id> mapWORtoWOtoshare=new  Map<Id,Id>();
      Map<Id,Id> mapWORtoWOtoUnshare=new  Map<Id,Id>();					
        //DCP-38968: Start- Maps for insert and delete shares for a wo to work order resources
        Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResourcesInsert= new Map<Id,List<SVMXC__Work_Order_Resource__c>>();
        Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResourcesDelete= new Map<Id,List<SVMXC__Work_Order_Resource__c>>();
        //DCP-38968: End- Maps for insert and delete shares for a wo to work order resources
        for(SVMXC__Work_Order_Resource__c objWORes:(List<SVMXC__Work_Order_Resource__c>)records){
            SVMXC__Work_Order_Resource__c oldWORes=(SVMXC__Work_Order_Resource__c)mapOld.get(objWORes.id);
            if(objWORes.SVMXC__Work_Order__c!=null&&objWORes.SVMXC__Group_Member__c!=null&&objWORes.SVMXC__Group_Member__c!=oldWORes.SVMXC__Group_Member__c){
                setWorkOrderId.add(objWORes.SVMXC__Work_Order__c);
				//DCP-31721	
			    mapWORtoWOtoshare.put(objWORes.SVMXC__Group_Member__c,objWORes.SVMXC__Work_Order__c);
				mapWORtoWOtoUnshare.put(oldWORes.SVMXC__Group_Member__c,oldWORes.SVMXC__Work_Order__c);
                //DCP-38968: Start- Add logic to populate maps
                addResourceToMap(objWORes,mapWOIdToWOResourcesInsert);
                addResourceToMap(oldWORes,mapWOIdToWOResourcesDelete);
                //DCP-38968: End- Add logic to populate maps
            }
        }
        ilib_LogEvent.info('setWorkOrderId : '+setWorkOrderId);
        ilib_LogEvent.info('mapWORtoWOtoshare : '+mapWORtoWOtoshare);
        ilib_LogEvent.info('mapWORtoWOtoUnshare : '+mapWORtoWOtoUnshare);
        ilib_LogEvent.info('mapWOIdToWOResourcesInsert  : '+(mapWOIdToWOResourcesInsert != Null ? String.valueof(mapWOIdToWOResourcesInsert.keySet()):NULLSTR));
        //DCP-38968: Start- Queue jobs if maps have values
        if(!mapWOIdToWOResourcesInsert.isEmpty()){
            processOppShareQueueable(mapWOIdToWOResourcesInsert,false);
        }
        ilib_LogEvent.info('mapWOIdToWOResourcesDelete  : '+(mapWOIdToWOResourcesDelete != Null ? String.valueof(mapWOIdToWOResourcesDelete.keySet()):NULLSTR));
        if(!mapWOIdToWOResourcesDelete.isEmpty()){
            processOppShareQueueable(mapWOIdToWOResourcesDelete,true);
        }
        //DCP-38968: End- Queue jobs if maps have values
         if(!setWorkOrderId.isEmpty()) {
           
            updateFieldSupportIdsOnWorkOrder(setWorkOrderId);
          }
		//DCP-31721	
		if(!mapWORtoWOtoshare.IsEmpty() || !mapWORtoWOtoUnshare.isEmpty()){
              shareWOwithWOR(mapWORtoWOtoshare,mapWORtoWOtoUnshare);
          }	
        //DCP-38968: Start- Queue Async jobs of trigger
        triggerAsyncOperations();
        //DCP-38968: End- Queue Async jobs of trigger																 
     }
     /**
     *  @AUTHOR:  Joshith K
     *  @DESCRIPTION: after delete logic to update the Field_Support_IDs in work order if the work order is deleted
     *  
     */
     public override void onAfterDelete(){
        //DCP-38968: Start- Initialize the trigger thread queueable
        triggerThread = new ilib_Queueablethread('WorkOrderResourcesAfterDelete');
        //DCP-38968: End- Initialize the trigger thread queueable
        Set<Id> setWorkOrderId = new Set<Id>();
	    Map<Id,Id> mapWORtoWOtoUnshare=new  Map<Id,Id>();			
        //DCP-38968: Start- Maps for delete shares for a wo to work order resources
        Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResourcesDelete= new Map<Id,List<SVMXC__Work_Order_Resource__c>>();
        //DCP-38968: End- Maps for delete shares for a wo to work order resources							   
        for(SVMXC__Work_Order_Resource__c objWORes:(List<SVMXC__Work_Order_Resource__c>)records){
              if(objWORes.SVMXC__Work_Order__c!=null&&objWORes.SVMXC__Group_Member__c!=null){
                setWorkOrderId.add(objWORes.SVMXC__Work_Order__c);
				//DCP-31721	
			mapWORtoWOtoUnshare.put(objWORes.SVMXC__Group_Member__c,objWORes.SVMXC__Work_Order__c);	
                //DCP-38968: Start- Add to delete map
                addResourceToMap(objWORes,mapWOIdToWOResourcesDelete);
                //DCP-38968: End- Add to delete map
              }
        }
        ilib_LogEvent.info('setWorkOrderId : '+setWorkOrderId);
        ilib_LogEvent.info('mapWORtoWOtoUnshare : '+mapWORtoWOtoUnshare);
        ilib_LogEvent.info('mapWOIdToWOResourcesDelete  : '+(mapWOIdToWOResourcesDelete != Null ? String.valueof(mapWOIdToWOResourcesDelete.keySet()):NULLSTR));
        //DCP-38968: Start- Add to process queue if not empty
        if(!mapWOIdToWOResourcesDelete.isEmpty()){
            processOppShareQueueable(mapWOIdToWOResourcesDelete,true);
        }
        //DCP-38968: End- Add to process queue if not empty
        if(!setWorkOrderId.isEmpty()) {
            updateFieldSupportIdsOnWorkOrder(setWorkOrderId);
        }
		  
		  //DCP-31721	
		if( !mapWORtoWOtoUnshare.isEmpty()){
            shareWOwithWOR(new  Map<Id,Id>(),mapWORtoWOtoUnshare);
        }  
        //DCP-38968: Start- Queue Async jobs of trigger
        triggerAsyncOperations();
        //DCP-38968: End- Queue Async jobs of trigger
     }
    
    /**
     *  @AUTHOR:  Joshith K
     *  @DESCRIPTION: This method updates field support ids on Work Order
     *  @PARAM :  set<Id> setFieldSupportWorkOrderIds
     */
    private static void updateFieldSupportIdsOnWorkOrder(set<Id> setFieldSupportWorkOrderIds) {
        ilib_LogEvent.push(LOG_TITLE+'.updateFieldSupportIdsOnWorkOrder()');
        map<Id, String> fieldSupportIdMap = new map<Id, String>();
        list<SVMXC__Service_Order__c  > workOrderToUpdateLst = new list<SVMXC__Service_Order__c >();
        map<Id, list<SVMXC__Work_Order_Resource__c  >> mapWorkOrderResToFieldSupport = new map<Id, list<SVMXC__Work_Order_Resource__c>>();
        
        for(SVMXC__Work_Order_Resource__c objWorkOrderResource : new WorkOrderResourceSelector().selectWorkOrderResources(setFieldSupportWorkOrderIds)) {
                                                                
            String uniqueUserIdentifier = objWorkOrderResource.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.FederationIdentifier != null ? 
                                          objWorkOrderResource.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.FederationIdentifier : '';
            
            uniqueUserIdentifier = objWorkOrderResource.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Alias != null ? 
                                   uniqueUserIdentifier + objWorkOrderResource.SVMXC__Group_Member__r.SVMXC__Salesforce_User__r.Alias : uniqueUserIdentifier;
            ilib_LogEvent.message('uniqueUserIdentifier : '+uniqueUserIdentifier);
            if(!mapWorkOrderResToFieldSupport.containsKey(objWorkOrderResource.SVMXC__Work_Order__c)) {
                mapWorkOrderResToFieldSupport.put(objWorkOrderResource.SVMXC__Work_Order__c, new list<SVMXC__Work_Order_Resource__c>());
            } 
            mapWorkOrderResToFieldSupport.get(objWorkOrderResource.SVMXC__Work_Order__c).add(objWorkOrderResource);
            fieldSupportIdMap.put(objWorkOrderResource.Id,uniqueUserIdentifier);
        }
        ilib_LogEvent.info('fieldSupportIdMap : '+fieldSupportIdMap);
        ilib_LogEvent.info('mapWorkOrderResToFieldSupport : '+(mapWorkOrderResToFieldSupport != Null ? String.valueof(mapWorkOrderResToFieldSupport.keySet()):NULLSTR));
        for(Id workOrderId : mapWorkOrderResToFieldSupport.keySet()) {
            String fieldSupportIds = '';
            
            SVMXC__Service_Order__c objWorkOrder = new SVMXC__Service_Order__c(Id = workOrderId);
            for(SVMXC__Work_Order_Resource__c objWorkOrderResource : mapWorkOrderResToFieldSupport.get(workOrderId)) {
               
                if(fieldSupportIdMap.containsKey(objWorkOrderResource.Id)){
                    if(!(String.ISBLANK(fieldSupportIdMap.get(objWorkOrderResource.Id)))){
                        if(!fieldSupportIds.contains(fieldSupportIdMap.get(objWorkOrderResource.Id))){
                            fieldSupportIds = (fieldSupportIds != ''  ? fieldSupportIds+','+fieldSupportIdMap.get(objWorkOrderResource.Id) : fieldSupportIdMap.get(objWorkOrderResource.Id));
                        }
                    }
                }
            }
            ilib_LogEvent.message('fieldSupportIds : '+fieldSupportIds); 
            if(fieldSupportIds !='' ){ 
                objWorkOrder.Field_Support_IDs__c = fieldSupportIds;
                workOrderToUpdateLst.add(objWorkOrder);
            }
        }
        
        if(workOrderToUpdateLst.size() > 0){
            update workOrderToUpdateLst;
        }
        ilib_LogEvent.pop();
    }    
     
	 
	    /*
     ** @AUTHOR:  Joshith K
     ** @DESCRIPTION: This method updates field support ids on Work Order
     **  @PARAM :  set<Id> setFieldSupportWorkOrderIds
    */
     @future
    private static void  updateFieldSupportIdsOnWorkOrderAsync(set<Id> setFieldSupportWorkOrderIds) {
        ilib_LogEvent.push(LOG_TITLE+'.updateFieldSupportIdsOnWorkOrderAsync()');
        updateFieldSupportIdsOnWorkOrder(setFieldSupportWorkOrderIds);
        ilib_LogEvent.pop();
     } 
	 
	 /**
    *  @author Digvijay Singh
    *  @description:- DCP-31721 , Shares/Unshare's  wo with  WOR. 
    **/
  
     @future
     private static void shareWOwithWOR(Map<Id,Id> mapWORtoWOtoshare,Map<Id,Id> mapWORtoWOtoUnshare){
        ilib_LogEvent.push(LOG_TITLE+'.shareWOwithWOR()');
         
         Map<Id , Id> mapFieldSupporttoUser=new Map<Id , Id>();
        
         List<SVMXC__Service_Order__share> lsttobeShared=new  List<SVMXC__Service_Order__share>();
         List<SVMXC__Service_Order__share> lsttobeUnShared=new  List<SVMXC__Service_Order__share>();
         Map<String ,  SVMXC__Service_Order__share> mapUsersWithAccess=new Map<String ,  SVMXC__Service_Order__share>();
         set<Id> setFieldSupport=new set<Id>();
         if(mapWORtoWOtoshare!=null && !mapWORtoWOtoshare.isEmpty())
             setFieldSupport.addAll(mapWORtoWOtoshare.keyset());
         
         if(mapWORtoWOtoUnshare!=null && !mapWORtoWOtoUnshare.isEmpty())
             setFieldSupport.addAll(mapWORtoWOtoUnshare.keyset());
         ilib_LogEvent.info('setFieldSupport : '+setFieldSupport);
         for(SVMXC__Service_Group_Members__c obj : new TechniciansSelector().selectTechnicians(setFieldSupport)){
            
            if(obj.SVMXC__Salesforce_User__r.IsPortalEnabled){
             mapFieldSupporttoUser.put(obj.id ,obj.SVMXC__Salesforce_User__c );
             }
         }
         ilib_LogEvent.info('mapFieldSupporttoUser : '+mapFieldSupporttoUser);
         for(SVMXC__Service_Order__share objshare:[Select Id, ParentId, AccessLevel ,UserOrGroupId, RowCause  from SVMXC__Service_Order__share where UserOrGroupId IN:mapFieldSupporttoUser.values() and (ParentId IN : mapWORtoWOtoshare.values() OR ParentId IN : mapWORtoWOtoUnshare.values())]){
             mapUsersWithAccess.put(objshare.UserOrGroupId+''+objshare.ParentId ,objshare );
             
         }
         ilib_LogEvent.info('mapUsersWithAccess : '+(mapUsersWithAccess != Null ? String.valueof(mapUsersWithAccess.keySet()):NULLSTR));
         
         for(Id objId: mapWORtoWOtoshare.keyset()){
             if(!mapFieldSupporttoUser.IsEMpty() && mapFieldSupporttoUser.containsKey(objId) && !mapUsersWithAccess.ContainsKey(mapFieldSupporttoUser.get(objId)+''+mapWORtoWOtoshare.get(objId))){
             
                    SVMXC__Service_Order__share obj=new SVMXC__Service_Order__share( ParentId=mapWORtoWOtoshare.get(objId) ,AccessLevel='edit', UserOrGroupId=mapFieldSupporttoUser.get(objId));
                  lsttobeShared.add(obj);                   
                 }
             
         }
         
         for(Id objId: mapWORtoWOtoUnshare.keyset()){
             if(!mapFieldSupporttoUser.IsEMpty() && mapFieldSupporttoUser.containsKey(objId) && mapUsersWithAccess.ContainsKey(mapFieldSupporttoUser.get(objId)+''+mapWORtoWOtoUnshare.get(objId)) ){
                    
                  lsttobeUnShared.add(mapUsersWithAccess.get(mapFieldSupporttoUser.get(objId)+''+mapWORtoWOtoUnshare.get(objId)));                   
                 }
             
         }
         
         if(lsttobeShared!=null && !lsttobeShared.IsEMpty())
             insert lsttobeShared;
         
         if(lsttobeUnShared!=null && !lsttobeUnShared.IsEMpty())
             delete lsttobeUnShared;
        ilib_LogEvent.pop();
     } 

    /**DCP-38968
    *  @author Akshay Mohan
    *  @description:Trigger async job for all after events
    **/
    private void triggerAsyncOperations(){
        ilib_LogEvent.push(LOG_TITLE+'.triggerAsyncOperations()');
        if(!triggerThread.lstQueueableJobs.isEmpty()){
            ilib_QueueableManager.enqueueJob(triggerThread,ilib_LogEvent.SERVICE);
        }
        ilib_LogEvent.pop();
    }

    /**DCP-38968
    *  @author Akshay Mohan
    *  @description:Trigger async job for all after events
    **/
    private void addResourceToMap(SVMXC__Work_Order_Resource__c objWORes, Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResources){
        if(!mapWOIdToWOResources.containsKey(objWORes.SVMXC__Work_Order__c)){
            mapWOIdToWOResources.put(objWORes.SVMXC__Work_Order__c,new List<SVMXC__Work_Order_Resource__c>());
        }
        mapWOIdToWOResources.get(objWORes.SVMXC__Work_Order__c).add(objWORes);
    }

    /**DCP-38968
    *  @author Akshay Mohan
    *  @description:Trigger async job for all after events
    **/
    private void processOppShareQueueable(Map<Id,List<SVMXC__Work_Order_Resource__c>> mapWOIdToWOResources,Boolean boolIsDelete){
        ilib_LogEvent.push(LOG_TITLE+'.processOppShareQueueable()');
        ilib_LogEvent.info('boolIsDelete'+boolIsDelete);
        for(Id idWO : mapWOIdToWOResources.keySet()){
            triggerThread.logandQueue(new OpportunitySharingToWOResource(idWO, boolIsDelete,mapWOIdToWOResources.get(idWO)),OpportunitySharingToWOResource.LOG_TITLE, boolIsDelete? 'deleteSharing' : 'insertSharing');
        }
        ilib_LogEvent.info('Work Orders added for sharing: '+mapWOIdToWOResources.keySet().size());
        ilib_LogEvent.pop();
    }
     /**
    *  @author Nitin
    *  @description  CMSI-222,method will return the workstream
    *  @return string
    **/
    public override string getWorkstream(){
        return ilib_LogEvent.SERVICE;
    }

}