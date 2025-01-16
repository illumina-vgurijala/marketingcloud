/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Canceled & rejected WO 
*/ 
public with sharing class CanceledRejectedStatus_WOHelper {

    // CMCM-10597
    public static List<SVMXC__Service_Order__c> listOfStandAloneWO = new List<SVMXC__Service_Order__c>();

    /**
    *  @author Shashank Singhal
    *  @description - create Related product for WO when Additional product is there on Case
    *  @parameters : List<SVMXC__Service_Order__c> lstInstallWO
    *  @return : void
    **/
    public static void processCancelledAutorejectedWorkOrders(Map<Id, SObject> mapOld) {
        Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles = new Map<Id,Map<String,Account_to_Field_Support__c>>();
        //Set of canceled work orders
        set<Id> setCanceledWorkOrderIds = new Set<Id>();
        //List of customer down work orders
        List<SVMXC__Service_Order__c> lstCustomerDownWorkOrder = new List<SVMXC__Service_Order__c>();
        //List of scheduled work orders
        List<SVMXC__Service_Order__c> lstScheduledWorkOrder = new List<SVMXC__Service_Order__c>();
        //List of work orders that are auto rejected
        //List of work orders that are auto rejected
        Set<Id> setRejectedWorkOrderPrimaryFSE = new Set<Id>();   
        //List of work orders that are auto rejected
        Set<Id> setRejectedWorkOrderSecondaryFSE = new Set<Id>();  
        //List of work orders that are auto rejected
        Set<Id> setRejectedWorkOrderFSM = new Set<Id>();


        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            //DCP-1053 : if work Order is auto rejected
            if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objOldWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED && objNewWorkorder.Reason__c != null && objNewWorkorder.Reason__c != '' && objNewWorkorder.SVMXC__Company__c != null){
                WorkOrders.mapWorkOrderIdRejectionStatus.put(objNewWorkorder.Id, objNewWorkorder.SVMXC__Order_Status__c);
            } 


            if(objNewWorkorder.SVMXC__Company__c != null) {
                // Rule 1 Check if Work Order is canceled
                //[Debalina 21-June-2018 Bug DCP-5010]
                //INC0436387 - Added a condition to check if prev work order status was not Cancelled
                if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED && objOldWorkorder.SVMXC__Order_Status__c!= WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED
                   // && objOldWorkorder.Reason__c != objNewWorkorder.Reason__c
                   )
                {
                   // setAccountIdTeFetchFSERoles.add(objNewWorkorder.SVMXC__Company__c);
                    setCanceledWorkOrderIds.add(objNewWorkorder.Id);
                }  
                //Rule 2 Check if Work Order is customer down
                else if(objNewWorkorder.SVMXC__Customer_Down__c!= objOldWorkorder.SVMXC__Customer_Down__c && objNewWorkorder.SVMXC__Customer_Down__c && !(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE))//INC0218050
                {
                   // setAccountIdTeFetchFSERoles.add(objNewWorkorder.SVMXC__Company__c);
                    lstCustomerDownWorkOrder.add(objNewWorkorder);
                }  

                addScheduledAndAutoRejectedWO(objNewWorkorder,objOldWorkorder,lstScheduledWorkOrder,setRejectedWorkOrderPrimaryFSE,setRejectedWorkOrderSecondaryFSE,setRejectedWorkOrderFSM);           
            }
        }

        //Fetch the account roles corresponding to the account
        accountIdToFSERoles = WorkOrders.mapaccountIdToPFSERoles;
        
        sendEmailForVariousWOStatus(accountIdToFSERoles,setCanceledWorkOrderIds,lstCustomerDownWorkOrder,lstScheduledWorkOrder);

        sendEmailForWOAutorejection(accountIdToFSERoles,setRejectedWorkOrderPrimaryFSE,setRejectedWorkOrderSecondaryFSE,setRejectedWorkOrderFSM);
    }
    /**
    * @description : prepare a collect of scheduled WO and auto rejected WO for sending email notification
    * @param objNewWorkorder 
    * @param objOldWorkorder 
    * @param lstScheduledWorkOrder 
    * @param setRejectedWorkOrderPrimaryFSE 
    * @param setRejectedWorkOrderSecondaryFSE 
    * @param setRejectedWorkOrderFSM 
    **/
    public static void addScheduledAndAutoRejectedWO(SVMXC__Service_Order__c objNewWorkorder,SVMXC__Service_Order__c objOldWorkorder,List<SVMXC__Service_Order__c> lstScheduledWorkOrder,
    Set<Id> setRejectedWorkOrderPrimaryFSE,Set<Id> setRejectedWorkOrderSecondaryFSE,Set<Id> setRejectedWorkOrderFSM)
    {
         //Rule 3 check if work order status changes to scheduled
         if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_SCHEDULED && 
         objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c && objNewWorkorder.Send_Notification_To_Customer__c)
         {
             
             lstScheduledWorkOrder.add(objNewWorkorder);
         } 

         //Rule 4 DCP-1053 : if work Order is auto rejected
         if(WorkOrders.mapWorkOrderIdRejectionStatus.containsKey(objNewWorkorder.Id) && WorkOrders.mapWorkOrderIdRejectionStatus.get(objNewWorkorder.Id) == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objOldWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED && objNewWorkorder.Reason__c != null && objNewWorkorder.Reason__c != '' && objNewWorkorder.SVMXC__Company__c != null){
             if(objOldWorkorder.Field_Support_User_Role__c == WorkOrders.STRING_LABEL_PRIMARY_FSE ) {
                 setRejectedWorkOrderPrimaryFSE.add(objNewWorkorder.Id);
             }else if(objOldWorkorder.Field_Support_User_Role__c == WorkOrders.STRING_LABEL_SECONDARY_FSE ) {
                 setRejectedWorkOrderSecondaryFSE.add(objNewWorkorder.id);              
             }else if(objOldWorkorder.Field_Support_User_Role__c == WorkOrders.STRING_LABEL_FSM ) {
                 setRejectedWorkOrderFSM.add(objNewWorkorder.id);              
             }
             
         } 
    }


    /**
    * @description :send email notifiction for canceled and scheduled status ,also for customer down WO
    * @param accountIdToFSERoles 
    * @param setCanceledWorkOrderIds 
    * @param lstCustomerDownWorkOrder 
    * @param lstScheduledWorkOrder 
    **/
    public static void sendEmailForVariousWOStatus(Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles,set<Id> setCanceledWorkOrderIds,List<SVMXC__Service_Order__c> lstCustomerDownWorkOrder,
    List<SVMXC__Service_Order__c> lstScheduledWorkOrder)
    {
        String strUserType=UserInfo.getUserType();

        if(!setCanceledWorkOrderIds.isEmpty()  && !accountIdToFSERoles.isEmpty()) {
            //INC0417839
            if(WorkOrders.setStandAloneWOId!=null && !WorkOrders.setStandAloneWOId.isEmpty() && listOfStandAloneWO.isEmpty()) {
                listOfStandAloneWO = new WorkOrdersSelector().selectWorkOrdersWithoutCasesFromIds(WorkOrders.setStandAloneWOId);
            }
            List<SVMXC__Service_Order__c> lstcancelledWorkOrders=new List<SVMXC__Service_Order__c>();
            for(SVMXC__Service_Order__c obj : listOfStandAloneWO) {
                if(setCanceledWorkOrderIds.contains(obj.id))
                    lstcancelledWorkOrders.add(obj);
            }

            if(!lstcancelledWorkOrders.isEmpty()){
                SendEmailNotification.getSendEmailParamaters('Canceled_Work_Order', lstcancelledWorkOrders, 
                                                         accountIdToFSERoles,WorkOrders.STRING_COMPANY);
            }
        }

        if(!lstCustomerDownWorkOrder.isEmpty() && !accountIdToFSERoles.isEmpty() && WorkOrders.notificationSent==false) {
            SendEmailNotification.getSendEmailParamaters('Instrument_Down_Work_Order', lstCustomerDownWorkOrder, accountIdToFSERoles,WorkOrders.STRING_COMPANY);
            WorkOrders.notificationSent=true;
        }
        //DCP-1047 : Send email once the appoitment has been rescheuled 
        if(!lstScheduledWorkOrder.isEmpty() && strUserType != WorkOrders.STRING_USER_TYPE  && !accountIdToFSERoles.isEmpty()) {
            SendEmailNotification.getSendEmailParamaters('Scheduled_Work_Order', lstScheduledWorkOrder, accountIdToFSERoles,WorkOrders.STRING_COMPANY);
        }
    }

    /**
    * @description :Send email notification for auto rejected WO
    * @param accountIdToFSERoles 
    * @param setRejectedWorkOrderPrimaryFSE 
    * @param setRejectedWorkOrderSecondaryFSE 
    * @param setRejectedWorkOrderFSM 
    **/
    public static void sendEmailForWOAutorejection(Map<Id,Map<String,Account_to_Field_Support__c>> accountIdToFSERoles,Set<Id> setRejectedWorkOrderPrimaryFSE, 
    Set<Id> setRejectedWorkOrderSecondaryFSE,Set<Id> setRejectedWorkOrderFSM)
    {
        //DCP-1053 : if work Order is auto rejected        
        if(!setRejectedWorkOrderPrimaryFSE.isEmpty()  && !accountIdToFSERoles.isEmpty()) {
            List<SVMXC__Service_Order__c> lstRejectedWorkOrderPrimaryFSE=new List<SVMXC__Service_Order__c>();
            for(SVMXC__Service_Order__c obj:WorkOrders.lstWorkOrders){
                if(setRejectedWorkOrderPrimaryFSE.contains(obj.id))
                    lstRejectedWorkOrderPrimaryFSE.add(obj);
            }
            SendEmailNotification.getSendEmailParamaters('Primary_SFE_Rejection', lstRejectedWorkOrderPrimaryFSE, accountIdToFSERoles,WorkOrders.STRING_COMPANY);
        }        
        if(!setRejectedWorkOrderSecondaryFSE.isEmpty()  && !accountIdToFSERoles.isEmpty()) {
            List<SVMXC__Service_Order__c> lstRejectedWorkOrderSecondaryFSE=new List<SVMXC__Service_Order__c>();
            for(SVMXC__Service_Order__c obj:WorkOrders.lstWorkOrders){
                if(setRejectedWorkOrderSecondaryFSE.contains(obj.id))
                    lstRejectedWorkOrderSecondaryFSE.add(obj);
            }
            SendEmailNotification.getSendEmailParamaters('Secondary_SFE_Rejection', lstRejectedWorkOrderSecondaryFSE, accountIdToFSERoles,WorkOrders.STRING_COMPANY);
        }
        if(!setRejectedWorkOrderFSM.isEmpty()) {
            List<SVMXC__Service_Order__c> lstRejectedWorkOrderFSM=new List<SVMXC__Service_Order__c>();
            for(SVMXC__Service_Order__c obj:WorkOrders.lstWorkOrders){
                if(setRejectedWorkOrderFSM.contains(obj.id))
                    lstRejectedWorkOrderFSM.add(obj);
            }
            SendEmailNotification.getSendEmailParamaters('FSM_Rejection', lstRejectedWorkOrderFSM, accountIdToFSERoles,WorkOrders.STRING_COMPANY);
        }
    }

    
}
