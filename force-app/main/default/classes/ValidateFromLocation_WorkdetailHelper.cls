/*****************************************************************************************************************
 * Class Name: ValidateFromLocation_WorkdetailHelper
 * 
 * Description: Helper class for validating from location of work detail on before insert.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for validating from location of work detail on before insert.
 * 
 ******************************************************************************************************************/
public with sharing class ValidateFromLocation_WorkdetailHelper {
    public static Channel_Partner_Profile_Settings__c cpProfileSettings = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
    public static Map < Id, Id > workOrderIdToFieldSupportId = new Map < Id, Id > ();
    public static Map < Id, set < Id >> fieldSupportIdTosetLocationId = new Map < Id, set < Id >> ();
    public static final String STRING_SAP_INTEGRATION_USER = 'SAP Service Integration';
    public static final String STRING_SNAP_INTEGRATION_USER = 'SNAP Service Integration';
    public static final Set<String> SET_BYPASS_INTERGRATION_USER= new Set<String>{STRING_SAP_INTEGRATION_USER, STRING_SNAP_INTEGRATION_USER};
    //DCP-37747
    public static final Set < String > SET_BYPASS_LINE_STATUS_FROM_ADDERROR = new Set < String > {
        'Canceled'
    };
    public static String strLoggedInProfile;
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tool';
    /*
     *  @AUTHOR:Sandeep Ram Ch.
     *  @DESCRIPTION:To Validate Location is of user's trunk/locker for Tools
     *  @PARAM :set of work details and set of work order id's
     *  @RETURN:void
     */

    public static void validateFromLocation(set < SVMXC__Service_Order_Line__c > setWorkDetail, set < Id > setWorkOrderId) {

        Id idLoggedInUserProfile = UserInfo.getProfileId(); // DCP-45568
        strLoggedInProfile = UserInfo.getName() != 'Automated Process' ? [Select Name from Profile where Id =: idLoggedInUserProfile limit 1][0].Name : ''; // DCP-45568
        Set < Id > setFieldSupportId = new Set < Id > ();
        //Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        //25282 start
        List < Id > lstFieldSupportIds = new List < Id > ();
        Id idLoggedInUserFieldSupport = null;
        List < SVMXC__Service_Group_Members__c > lstLoggedInUserFS = new TechniciansSelector().selectTechniciansMatchingUsers(new Set < Id > {UserInfo.getUserId()});
        if (!lstLoggedInUserFS.isEmpty()){
            idLoggedInUserFieldSupport = lstLoggedInUserFS[0].Id;
        }
            
        //25282 end
        if (!setWorkOrderId.isEmpty()) {
            //creating work order associated field support map
            for (SVMXC__Service_Order__c objWorkOrder: new WorkOrdersSelector().selectRelatedWorkOrderWithFieldSupport(setWorkOrderId)) {
                workOrderIdToFieldSupportId.put(objWorkOrder.id, objWorkOrder.SVMXC__Group_Member__c);
            }
        }

        //25282 start 
        lstFieldSupportIds = workOrderIdToFieldSupportId.values();
        if (idLoggedInUserFieldSupport != null && !lstFieldSupportIds.contains(idLoggedInUserFieldSupport)){
            lstFieldSupportIds.add(idLoggedInUserFieldSupport);
        }   
        //25282 end

        createrFieldSupportMap(lstFieldSupportIds);


        setFieldSupportId.addAll(lstFieldSupportIds); // 25282 replaced workOrderIdToFieldSupportId.values() with lstFieldSupportIds

        if (!setFieldSupportId.isEmpty()) {
            // adding technican invetory location value to the map fieldSupportIdTosetLocationId
            for (SVMXC__Service_Group_Members__c objFieldSupport: new TechniciansSelector().selectTechnicians(setFieldSupportId)) {
                if (fieldSupportIdTosetLocationId.containskey(objFieldSupport.Id)) {
                    fieldSupportIdTosetLocationId.get(objFieldSupport.Id).add(objFieldSupport.SVMXC__Inventory_Location__c);
                } else {
                    fieldSupportIdTosetLocationId.put(objFieldSupport.Id, new set < Id > {
                        objFieldSupport.SVMXC__Inventory_Location__c
                    });
                }

            }
        }
        throwValidations(setWorkDetail, idLoggedInUserFieldSupport);
        
    }
    /*
     *  @AUTHOR:Sandeep Ram Ch.
     *  @DESCRIPTION:To Validate Location is of user's trunk/locker for Tools
     *  @PARAM :set of work details and set of work order id's
     *  @RETURN:void
     */
    public static void throwValidations(Set<SVMXC__Service_Order_Line__c> setWorkDetail, Id idLoggedInUserFieldSupport ){
        // logic for checking the location selected is either in truck or locker.
        for (SVMXC__Service_Order_Line__c objWorkDetail: setWorkDetail) {
            if (fieldSupportIdTosetLocationId != null && fieldSupportIdTosetLocationId.containskey(idLoggedInUserFieldSupport)) {
                set < Id > setLoggedInUserLocationId = fieldSupportIdTosetLocationId.get(idLoggedInUserFieldSupport);
                if (setLoggedInUserLocationId != null && !setLoggedInUserLocationId.contains(objWorkDetail.SVMXC__From_Location__c) && objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS
                    && !SET_BYPASS_INTERGRATION_USER.contains(UserInfo.getName()) &&
                    !cpProfileSettings.Is_Channel_Partner__c == true && Userinfo.getUserId() != NULL && !SET_BYPASS_LINE_STATUS_FROM_ADDERROR.contains(objWorkDetail.SVMXC__Line_Status__c) &&
                    strLoggedInProfile != null && !strLoggedInProfile.EqualsIgnoreCase(Workdetails.STRING_CRO_USER)) {
                        objWorkDetail.addError(System.Label.Tool_WD_Trigger_From_Location_Error_Message);    
                }
    
                //25282 start 
                if (setLoggedInUserLocationId != null && !setLoggedInUserLocationId.contains(objWorkDetail.SVMXC__Consumed_From_Location__c) && objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.Record_Create_From_SFM__c
                && !SET_BYPASS_INTERGRATION_USER.contains(UserInfo.getName()) && !SET_BYPASS_LINE_STATUS_FROM_ADDERROR.contains(objWorkDetail.SVMXC__Line_Status__c)) {    
                    objWorkDetail.addError(System.Label.Parts_WD_Trigger_From_Location_Error_Message);   
                        
                }
                
            }

        }
    }
    /*
     *  @AUTHOR:Sandeep Ram Ch.
     *  @DESCRIPTION:To Validate Location is of user's trunk/locker for Tools
     *  @PARAM :set of work details and set of work order id's
     *  @RETURN:void
     */
    public static void createrFieldSupportMap(List < Id > lstFieldSupportIds){
        if (!workOrderIdToFieldSupportId.isEmpty() || !lstFieldSupportIds.isEmpty()) { //25282 added  || !lstFieldSupportIds.isEmpty()
            // creating field support lockers map 
            for (SVMXC__Service_Group_Site__c objLocationCovered: new LocationsCoveredSelector().selectRelatedLocationFieldSupport(lstFieldSupportIds)) { // 25282 replaced workOrderIdToFieldSupportId.values() with lstFieldSupportIds LocationsCoveredSelector().selectRelatedLocationFieldSupport(workOrderIdToFieldSupportId.values())){

                if (fieldSupportIdTosetLocationId.containskey(objLocationCovered.SVMXC__Technician_Equipment__c)) {
                    fieldSupportIdTosetLocationId.get(objLocationCovered.SVMXC__Technician_Equipment__c).add(objLocationCovered.SVMXC__Site__c);
                } else {
                    fieldSupportIdTosetLocationId.put(objLocationCovered.SVMXC__Technician_Equipment__c, new set < Id > {
                        objLocationCovered.SVMXC__Site__c
                    });
                }
            }
        }
    }
    
}
