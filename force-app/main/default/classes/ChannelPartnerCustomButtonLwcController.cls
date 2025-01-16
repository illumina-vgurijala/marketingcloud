/*
*    @author Nishan Shetty
*    @date   2021-08-24
*    @description  Controller class for channelPartnerCustomButtonLWC component.
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                24 Aug 2021           Allow CP User to Request for Ownership Change.        		
*    --------------------------------------------------------------------------------------------------------
*                    
*/
public without sharing class ChannelPartnerCustomButtonLwcController {
    private static final String LOG_TITLE = 'ChannelPartnerCustomButtonLwcController';
    private static final String STRING_CASE='Case';
    private static final String STRING_WORK_ORDER='WorkOrder';
    private static final String STRING_PARTNER='Partner';
    private static final String STRING_REQUESTED='Requested';
    private static final String STRING_SUCCESS='SUCCESS';
    private static final String STRING_DENIED='DENIED';
    private static final String STRING_REQUEST_RAISED='RAISED';

   /*
    *  @author Nishan Shetty
    *  @description Pass Map Labels to Component.
    *  @return String 
    */
    @AuraEnabled
    public static String initializeMap() {
        try {
            return '{"mapLabels": '+JSON.serialize(getMapLabels())+'}';
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,'initializeMap',e);
            throw  new AuraHandledException('initializeMap'+ e.getMessage()) ;
        }
    }    

    /*
     *  @author Nishan Shetty
     *  @description Update Request Ownership Status and Ownership Requested By Field on Case/WorkOrder
     *  @param recordId Id of Case or Work Order.
     *  @param objectName - Case or Work Order Object Name.
     *  @return String 
     */
    @AuraEnabled
    public static String updateRequestOwnershipFields(String recordId,String objectName) {
        ilib_LogEvent.push(LOG_TITLE + '.updateRequestOwnershipFields');
        Boolean allowRequest=false;
        try {
            ilib_LogEvent.message('recordId'+recordId);
            ilib_LogEvent.message('objectName'+objectName);
            if(objectName.equals(STRING_CASE)) {
                List<Case> lstCase=(List<Case>)getRecords(recordId,objectName);
                allowRequest=allowRequestCheck((List<SObject>)lstCase,objectName);
                if(allowRequest && lstCase[0].Request_Ownership_Status__c!=STRING_REQUESTED) {
                    lstCase[0].Request_Ownership_Status__c=STRING_REQUESTED;
                    lstCase[0].Ownership_Requested_By__c=UserInfo.getUserId();
                    update lstCase;
                    ilib_LogEvent.pop();
                    return STRING_SUCCESS;
                } else if(allowRequest && lstCase[0].Request_Ownership_Status__c==STRING_REQUESTED){
                    ilib_LogEvent.pop();
                    return STRING_REQUEST_RAISED;
                }            
            } else if(objectName.equals(STRING_WORK_ORDER)) {
                List<SVMXC__Service_Order__c> lstWorkOrder= (List<SVMXC__Service_Order__c>)getRecords(recordId,objectName);
                allowRequest=allowRequestCheck((List<SObject>)lstWorkOrder,objectName);
                if(allowRequest && lstWorkOrder[0].Request_Ownership_Status__c!=STRING_REQUESTED) {
                    lstWorkOrder[0].Request_Ownership_Status__c=STRING_REQUESTED;
                    lstWorkOrder[0].Ownership_Requested_By__c=UserInfo.getUserId();
                    update lstWorkOrder;
                    ilib_LogEvent.pop();
                    return STRING_SUCCESS;
                } else if (allowRequest && lstWorkOrder[0].Request_Ownership_Status__c==STRING_REQUESTED) {
                    ilib_LogEvent.pop();
                    return STRING_REQUEST_RAISED;
                }
            }

            ilib_LogEvent.pop();
            return STRING_DENIED;

        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,recordId,e);
            throw  new AuraHandledException('updateRequestOwnershipFields'+ e.getMessage()) ;
        }
    }
    
   /*
    *  @author Nishan Shetty
    *  @description Get MapLabels.
    *  @return Map<String,String> - Map of Labels.
    */
    public static Map<String,String> getMapLabels() {
        return new Map<String,String>{
            'Channel_Partner_Request_Ownership' => Label.Channel_Partner_Request_Ownership,
            'Channel_Partner_Request_Ownership_Success_Msg' => Label.Channel_Partner_Request_Ownership_Success_Msg,
            'Channel_Partner_Request_Ownership_Denied' => Label.Channel_Partner_Request_Ownership_Denied,
            'Channel_Partner_Request_Ownership_Already_Raised' => Label.Channel_Partner_Request_Ownership_Already_Raised
        };
    }

    /*
    *  @author Nishan Shetty
    *  @description  fetch records for Case or WorkOrder.
    *  @param recordId Id of Case or Work Order.
    *  @param objectName - Case or Work Order Object Name.
    *  @return List<SObject> Case or Work Order record.
    */
    public static List<SObject> getRecords(String recordId,String objectName) {
        ilib_LogEvent.push(LOG_TITLE + '.getRecords');
        List<SObject> records=new List<SObject>();
        if(objectName.equals(STRING_CASE)) {
            records=new CasesSelector().selectCases(new Set<Id>{Id.valueOf(recordId)});
            ilib_LogEvent.message('CaseRecords'+records[0].Id);
        
        } else if(objectName.equals(STRING_WORK_ORDER)) {
            records=new WorkOrdersSelector().selectWorkOrders(new Set<Id>{Id.valueOf(recordId)});
            ilib_LogEvent.message('WorkOrderRecords'+records[0].Id);
        }
        ilib_LogEvent.pop(); 
        return records;  
    }  
    
    /*
    *  @author Nishan Shetty
    *  @description  check request permission.
    *  @param records  List of Case or Work Order.
    *  @param objectName - Case or Work Order Object Name.
    *  @return boolean.
    */
    public static Boolean allowRequestCheck(List<SObject> records,String objectName) {
        if(objectName.equals(STRING_CASE) && !records.isEmpty()) {
            Case objCase=(Case)records.get(0);
            String strCaseOwnerRole=objCase.Case_Owner_Role__c;
            if(strCaseOwnerRole!=null && strCaseOwnerRole.containsIgnoreCase(STRING_PARTNER)) {
                return false;
            }
        } else if(objectName.equals(STRING_WORK_ORDER) && !records.isEmpty()) {
            SVMXC__Service_Order__c objWorkOrder=(SVMXC__Service_Order__c)records.get(0);
            List<User> lstUser=new List<User>();
            if(objWorkOrder.OwnerId!=null && string.valueOf(objWorkOrder.OwnerId).startsWith('005')) {
                lstUser=new UsersSelector().selectByUserId(new Set<Id>{Id.valueOf(objWorkOrder.OwnerId)});
            }
            if(!lstUser.isEmpty() && lstUser[0].IsPortalEnabled) {
                return false;
            }
        }
        return true;
    }
    
      
}