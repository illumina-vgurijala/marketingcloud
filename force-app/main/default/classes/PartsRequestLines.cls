/***************************************************************************************************************************************
* NAME   : PartsRequestLine
* DESCRIPTION  : Domain class for PartsRequestLineTrigger.
*                    
* @AUTHOR : Vaibhav
* @DATE   : 19-Dec-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class PartsRequestLines extends ilib_SObjectDomain {


		/*
         * Constructor
         */
    public static List<SVMXC__Parts_Request__c> listPartsRequest = new List<SVMXC__Parts_Request__c>();

    public PartsRequestLines(List < SVMXC__Parts_Request_Line__c > sObjectList) {
        super(sObjectList);
    }

    /*
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
	
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List < SObject > sObjectList) {
            return new PartsRequestLines(sObjectList);
        }
    }

    /**
     *  @author Vaibhav
     *  @description - To be executed, when the Parts Request Line is inserted. 
     **/
    public override void onAfterInsert() {
        set < Id > setPartsRequestId = new set < Id > ();
        for (SVMXC__Parts_Request_Line__c objPartsRequestLine: (List < SVMXC__Parts_Request_Line__c > ) records) {
            if (objPartsRequestLine.SVMXC__Posted_To_Inventory__c == true) {
                setPartsRequestId.add(objPartsRequestLine.SVMXC__Parts_Request__c);
            }
        }

        if (!system.isBatch() && !system.isFuture() && setPartsRequestId != null && !setPartsRequestId.isEmpty())
            sendStockTransferToSAP(setPartsRequestId);


    }

    /**Overrided method from Super class. Handles before Insert Trigger  event  */
    public override void onBeforeInsert() {
        notifyInventoryAuthority(records);
    }

    /**
     *  @author Vaibhav Parashar
     *  @description - To be executed, when the stock transfer is updated. 
     *               
     **/
    public override void onAfterUpdate(Map < Id, SObject > oldRecords) {
        //Stock Transfer SVMX To SAP
        //set of stock transfer ids.
        set < Id > setPartsRequestId = new set < Id > ();

        for (Id idPartsRequest: oldRecords.keySet()) {

            //new instance   
            SVMXC__Parts_Request_Line__c objNewPartsRequestLine = (SVMXC__Parts_Request_Line__c) Trigger.newMap.get(idPartsRequest);
            //old instance
            SVMXC__Parts_Request_Line__c objOldPartsRequestLine = (SVMXC__Parts_Request_Line__c) oldRecords.get(idPartsRequest);

            //conditions to check on stock transfer fields.
            if (objNewPartsRequestLine.SVMXC__Posted_To_Inventory__c != objOldPartsRequestLine.SVMXC__Posted_To_Inventory__c && objNewPartsRequestLine.SVMXC__Posted_To_Inventory__c == true) {
                setPartsRequestId.add(objNewPartsRequestLine.SVMXC__Parts_Request__c);
            }

        }

        if (!system.isBatch() && !system.isFuture() && setPartsRequestId != null && !setPartsRequestId.isEmpty())
            sendStockTransferToSAP(setPartsRequestId);

    }


    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Adhoc Inventory Sync using Parts Order Creation Interface.
     *              
     *  @PARAM :       set<Id> setPartsRequestId
     *  @RETURN : void
     **/
    @future(callout = true)
    public static void sendStockTransferToSAP(set < Id > setPartsRequestId) {

        //this interface creates a JSON.
        system.debug('setPartsRequestId ' + setPartsRequestId);

        //hold the list of platform events.
        List < Interface_Call__e > lstInterfaceCalls = New List < Interface_Call__e > ();

        //Iterate over the list of work orders.
        //create instance of platform events by iterating over the list of work orders recieved.
        for (Id partsRequestRec: setPartsRequestId) {

            //create platform event instance.
            Interface_Call__e interCall = new Interface_Call__e(Name__c = 'PartsOrderDataSender',
                Related_Record__c = partsRequestRec);

            //add all the events in single list.                        
            lstInterfaceCalls.add(interCall);

        }

        if (lstInterfaceCalls.size() > 0) {
            //publish the events in one single call.
            EventBus.publish(lstInterfaceCalls);
        }



    }

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Email Alert for Reopen Request)
    *  @RETURN:  void
    */ 
    public static void notifyInventoryAuthority(List<SVMXC__Parts_Request_Line__c> records) {
        set<ID> partRequest= new set<Id>();
        Map<ID,SVMXC__Parts_Request__c> serviceEnd = new Map<ID,SVMXC__Parts_Request__c>();

        for(SVMXC__Parts_Request_Line__c objPartsReq : (List<SVMXC__Parts_Request_Line__c>) records){ 
            if(objPartsReq.SVMXC__Parts_Request__c != null){
                partRequest.add(objPartsReq.SVMXC__Parts_Request__c);
            }
        }        

        if(partRequest!=null && !partRequest.isEmpty() && listPartsRequest.isEmpty()){
            listPartsRequest = new PartsRequestSelector().selectPartsRequestById(partRequest);
        }

        if(listPartsRequest!=null && !listPartsRequest.isEmpty()){
            for(SVMXC__Parts_Request__c variable : listPartsRequest){
                serviceEnd.put(variable.id,variable);
            }
        }

        if(serviceEnd!=null){
            inventorySerouceUpdateSFEnginner(records, serviceEnd);
            inventorySerouceUpdateSFUser(records, serviceEnd);
        }
    }

     /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Email Alert for Reopen Request)
    *  @RETURN:  void
    */ 
    public static void inventorySerouceUpdateSFEnginner(List<SVMXC__Parts_Request_Line__c> records, Map<ID,SVMXC__Parts_Request__c> serviceEnd) {
        for(SVMXC__Parts_Request_Line__c objPartsReq : (List<SVMXC__Parts_Request_Line__c>) records){ 
            SVMXC__Parts_Request__c dd= serviceEnd.get(objPartsReq.SVMXC__Parts_Request__c);
            if(dd!= null && dd.SVMXC__Requested_From__c != null && dd.SVMXC__Requested_From__r.SVMXC__Service_Engineer__c != null && dd.SVMXC__Requested_From__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c == null){
                objPartsReq.Inventory_Authority_Source__c = dd.SVMXC__Requested_From__r.SVMXC__Service_Engineer__c;
            }
        }
    }

     /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Email Alert for Reopen Request)
    *  @RETURN:  void
    */ 
    public static void inventorySerouceUpdateSFUser(List<SVMXC__Parts_Request_Line__c> records, Map<ID,SVMXC__Parts_Request__c> serviceEnd) {
        for(SVMXC__Parts_Request_Line__c objPartsReq : (List<SVMXC__Parts_Request_Line__c>) records){ 
            SVMXC__Parts_Request__c dd= serviceEnd.get(objPartsReq.SVMXC__Parts_Request__c);
            if(dd!= null &&dd.SVMXC__Requested_From__c!=null && dd.SVMXC__Requested_From__r.SVMX_PS_Preferred_Technician__c != null && dd.SVMXC__Requested_From__r.SVMXC__Service_Engineer__c == null){
                objPartsReq.Inventory_Authority_Source__c = dd.SVMXC__Requested_From__r.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c;
            }
        }
    }
}