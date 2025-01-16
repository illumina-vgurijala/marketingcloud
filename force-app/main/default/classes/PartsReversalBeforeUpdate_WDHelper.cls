/*****************************************************************************************************************
 * Class Name: PartsReversalBeforeUpdate_WDHelper
 * Description: Helper class for before update of work details.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Helper class for before update of work details.
 * Rucha Dalvi                16-Mar-2023                      TASK0855489 - Changed the Date assignment to DateTime.now in populateConsumptionConfirmed
 * Vineeta Verma			  13-Feb-2024						Null Check in validateErrorsForCP
 ******************************************************************************************************************/
public with sharing class PartsReversalBeforeUpdate_WDHelper {
    public static final string CLOSED = 'closed';
    public static final string FAIL_STATUS = 'Fail';
    public static final string PARTNER_STOCK = 'partner stock';
    /*
    *  method: populateProductMap
    *  @author - Prashanth
    *  @Description : populate Product Map
    * 
    */ 
    public static void partsReversalProcess(SVMXC__Service_Order_Line__c objOldWorkOrderLine, SVMXC__Service_Order_Line__c objWorkDetail, Set<Id> setConsumedFromLocationForPartReversal){
        populateConsumptionConfirmed(objOldWorkOrderLine,objWorkDetail);
        //DCP-44981
        if (objWorkDetail.Consumption_Confirmed__c &&
            String.isNotBlank(objWorkDetail.SVMXC__Consumed_From_Location__c) &&
            String.isNotBlank(objWorkDetail.SVMX_PS_External_ID__c) &&
            String.isNotBlank(objWorkDetail.SVMXC__Line_Type__c) &&
            objWorkDetail.SVMXC__Line_Type__c.equalsIgnoreCase(Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) &&
            objOldWorkOrderLine.SVMXC__Line_Status__c != objWorkDetail.SVMXC__Line_Status__c &&
            objWorkDetail.SVMXC__Line_Status__c != null &&
            objOldWorkOrderLine.SVMXC__Line_Status__c != null &&
            objOldWorkOrderLine.SVMXC__Line_Status__c.equalsIgnoreCase(CLOSED) && objWorkDetail.SVMXC__Line_Status__c.equalsIgnoreCase('Canceled') &&
            String.isBlank(objWorkDetail.Part_Consumption_Reversal_External_ID__c)
        ) {
            validateErrors(objOldWorkOrderLine,objWorkDetail);
            setConsumedFromLocationForPartReversal.add(objWorkDetail.SVMXC__Consumed_From_Location__c);
        } /* For CP */
        else if (
            objWorkDetail.Consumption_Confirmed__c &&
            String.isNotBlank(objWorkDetail.SVMXC__Consumed_From_Location__c) &&
            String.isNotBlank(objWorkDetail.SVMXC__Line_Type__c) &&
            objWorkDetail.SVMXC__Line_Type__c.equalsIgnoreCase(Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) &&
            objOldWorkOrderLine.SVMXC__Line_Status__c != objWorkDetail.SVMXC__Line_Status__c &&
            objWorkDetail.SVMXC__Line_Status__c != null &&
            objOldWorkOrderLine.SVMXC__Line_Status__c != null &&
            objOldWorkOrderLine.SVMXC__Line_Status__c.equalsIgnoreCase(CLOSED) && objWorkDetail.SVMXC__Line_Status__c.equalsIgnoreCase('Canceled') &&
            String.isBlank(objWorkDetail.Part_Consumption_Reversal_External_ID__c)
        ) {
            setConsumedFromLocationForPartReversal.add(objWorkDetail.SVMXC__Consumed_From_Location__c);
        }
    }
    /*
    *  method: populateConsumptionConfirmed
    *  @author - Prashanth
    *  @Description : populate Consumption Confirmed fields.
    * 
    */ 
    public static void populateConsumptionConfirmed(SVMXC__Service_Order_Line__c objOldWorkOrderLine, SVMXC__Service_Order_Line__c objWorkDetail){
        //DCP-37399
        //If "Consumption Confirmed" is true, save the date/time and loggedin user
        if (objOldWorkOrderLine.Consumption_Confirmed__c != objWorkDetail.Consumption_Confirmed__c && objWorkDetail.Consumption_Confirmed__c) {
            //Changed the Date assignment to DateTime.now for TASK0855489
            //objWorkDetail.Consumption_Confirmed_Date_Time__c = DateTime.parse(DateTime.now().format());
            objWorkDetail.Consumption_Confirmed_Date_Time__c = DateTime.now();
            objWorkDetail.Consumption_Confirmed_User__c = USerInfo.getUserId();
        }
    }
    /*
    *  method: validateErrors
    *  @author - Prashanth
    *  @Description : validate Errors
    * 
    */ 
    public static void validateErrors(SVMXC__Service_Order_Line__c objOldWorkOrderLine, SVMXC__Service_Order_Line__c objWorkDetail){
        /* Error, Product stock is missing */
        if (String.isBlank(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c)) {
            objWorkDetail.Integration_Message_Details__c = 'SFDC Error: No inventory /stock added on the line.';
            objWorkDetail.Integration_Status__c = FAIL_STATUS;
            objWorkDetail.SVMXC__Line_Status__c = objOldWorkOrderLine.SVMXC__Line_Status__c;
        } /* Error, Stock Serial is missing */
        else if (String.isNotBlank(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && String.isBlank(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) && objWorkDetail.Product_Tracking__c == Workdetails.PRODUCT_TRACKING_SERIALIZED) {
            objWorkDetail.Integration_Message_Details__c = 'SFDC Error: Consumed stock serial not linked on line.';
            objWorkDetail.Integration_Status__c = FAIL_STATUS;
            objWorkDetail.SVMXC__Line_Status__c = objOldWorkOrderLine.SVMXC__Line_Status__c;
        } /* Error, Batch Lookup is missing */
        else if (String.isNotBlank(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) && String.isBlank(objWorkDetail.Batch_Lookup__c) && objWorkDetail.Product_Tracking__c == 'Lot/Batch Tracked') {
            objWorkDetail.Integration_Message_Details__c = 'SFDC Error: Batch number is missing.';
            objWorkDetail.Integration_Status__c = FAIL_STATUS;
            objWorkDetail.SVMXC__Line_Status__c = objOldWorkOrderLine.SVMXC__Line_Status__c;
        } /* Error, FSE Missing for location */
        else if (String.isNotBlank(objWorkDetail.SVMXC__Consumed_From_Location__c) && String.isNotBlank(UserInfo.getUserId()) && objWorkDetail.Consumed_From_Location_Service_Engineer__c != UserInfo.getUserId().substring(0, 15)) {
            objWorkDetail.addError(System.Label.REVERSAL_CONSUMPTION_ERROR_MSG_1);
        }
        /* Error, Was consumed before 22 Feb 2021 */
        else if ((String.isNotBlank(objWorkDetail.SVMX_PS_VS_Consumed_Status__c) && Date.valueOf(objWorkDetail.SVMX_PS_VS_Consumed_Status__c.substring(0, 10)) < Date.valueOf('2021-02-22')) || String.isBlank(objWorkDetail.SVMX_PS_VS_Consumed_Status__c)) {
            objWorkDetail.addError(System.Label.REVERSAL_CONSUMPTION_ERROR_MSG_2);
        } else /* Update the status as Reversal Requested */ {
            if (String.isBlank(objWorkDetail.Part_Consumption_Reversal_External_ID__c)) {
                objWorkDetail.Integration_Message_Details__c = '';
                objWorkDetail.Integration_Status__c = '';
                objWorkDetail.SVMXC__Line_Status__c = Workdetails.STRING_REVERSAL_REQUESTED;
            }
        }
    }
    /*
    *  method: validateErrorsForCP
    *  @author - Prashanth
    *  @Description : validate Errors for Cp.
    * 
    */ 
    public static void validateErrorsForCP( Set<Id> setConsumedFromLocationForPartReversal,List<sObject> records, Map<Id, sObject> oldRecords){
        //DCP-44981
        if (!setConsumedFromLocationForPartReversal.IsEmpty()) {
            Workdetails.consumedFromLocationIdToLocationMap = new Map < Id, SVMXC__Site__c > (new LocationsSelector().selectToLocations(setConsumedFromLocationForPartReversal));
            for (SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records) {
                SVMXC__Service_Order_Line__c objOldWorkOrderLine = (SVMXC__Service_Order_Line__c)(oldRecords.get(objWorkDetail.Id));
                //INC0519186:adding null check
                if(objWorkDetail.SVMXC__Consumed_From_Location__c!= null && Workdetails.consumedFromLocationIdToLocationMap.size() > 0){
                    if (Workdetails.consumedFromLocationIdToLocationMap.get(objWorkDetail.SVMXC__Consumed_From_Location__c).Type__c == PARTNER_STOCK) {

                        if (String.isBlank(objWorkDetail.Part_Consumption_Reversal_External_ID__c)) {
                            validateErrors(objOldWorkOrderLine, objWorkDetail);
                        }

                    }
                }

            }
        }
    }
    /*
    *  method: assignFieldValues
    *  @author - Prashanth
    *  @Description : assign Field Values
    * 
    */
    public static void assignFieldValues(SVMXC__Service_Order_Line__c objWorkDetail,SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        //DCP-44981 - if status was reversal requested and sap failed, revert the status back to "closed".
        if (objOldWorkOrderLine.SVMXC__Line_Status__c != null && objOldWorkOrderLine.SVMXC__Line_Status__c.equalsIgnoreCase('Reversal Requested') && objWorkDetail.Integration_Status__c == FAIL_STATUS) {
            objWorkDetail.SVMXC__Line_Status__c = CLOSED;
        }
        //DCP - 47396
        if (objWorkDetail.Labor_Hours__c != null || objWorkDetail.Indirect_in_hours__c != null || objWorkDetail.Travel_Time_in_hours__c != null) {
            objWorkDetail.Duration_in_hours__c = BeforeInsert_WorkDetailHelper.calculateDuration(objWorkDetail.Labor_Hours__c, objWorkDetail.Indirect_in_hours__c, objWorkDetail.Travel_Time_in_hours__c);
        }

        //INC0275626: Populate End Date time 
        if (objWorkDetail.SVMXC__Start_Date_and_Time__c != null && objWorkDetail.Duration_in_hours__c != null) {
            objWorkDetail.SVMXC__End_Date_and_Time__c = BeforeInsert_WorkDetailHelper.calculateEndDate(objWorkDetail.SVMXC__Start_Date_and_Time__c, objWorkDetail.Duration_in_hours__c);
        }
        //DCP-38806
        if (objWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            objWorkDetail.SVMXC__Actual_Price2__c = 0;
        }
    }
    
    /*
    *  method: svmxcRecUpdate
    *  @author - Prashanth
    *  @Description : update isSvmxcRecUpdate boolean
    * 
    */
    public static void svmxcRecUpdate(SVMXC__Service_Order_Line__c objWorkDetail,SVMXC__Service_Order_Line__c objOldWorkOrderLine, Map < String, Schema.SObjectField > objWorkDetailFields, User loggedInUser){
        //Added by Shruti Karn for RITM0356143
        Boolean isSVMXRecUpdate = false;
        isSVMXRecUpdate = populateSVMXCBoolean(objWorkDetailFields, objWorkDetail,objOldWorkOrderLine);
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS &&
            objWorkDetail.SVMX_PS_External_ID__c != null &&
            objWorkDetail.Integration_Status__c == Workdetails.STRING_INTEGRATION_SUCCESS &&
            loggedInUser.profile.Name != Label.Integration_SAP_Service &&
                loggedInUser.profile.Name != Label.ProfileSystemAdmin &&
                loggedInUser.profile.Name != Label.Integration_Service_SNAP_Profile &&
                !(FeatureManagement.checkPermission('SS_Edit_Del_WorkDetails')) &&

                isSVMXRecUpdate == false
            ) {
            //DCP-44981 - This should not fire when reversal is requested, status changed from closed to canceled.
            if (objOldWorkOrderLine.SVMXC__Line_Status__c != null && !objOldWorkOrderLine.SVMXC__Line_Status__c.equalsIgnoreCase(CLOSED) && objWorkDetail.SVMXC__Line_Status__c != null && !objWorkDetail.SVMXC__Line_Status__c.equalsIgnoreCase('Canceled')){
                objWorkDetail.addError(Label.WorkDetailDeleteErrorMsg);
            }
        } // End of changes for RITM0356143
        // DCP- 37747check to stop edit on canceled wd.
        if (objOldWorkOrderLine.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED && isSVMXRecUpdate == false &&
            loggedInUser.profile.Name != Label.Integration_SAP_Service &&
                loggedInUser.profile.Name != Label.ProfileSystemAdmin &&
                loggedInUser.profile.Name != Label.Integration_Service_SNAP_Profile &&
                !(FeatureManagement.checkPermission('SS_Edit_Del_WorkDetails'))
        ) {
            objWorkDetail.addError(Label.WorkDetailLineCanceledEditError); //added in custom label.
        }

    }
    /*
    *  method: svmxcRecUpdate
    *  @author - Prashanth
    *  @Description : update isSvmxcRecUpdate boolean
    * 
    */
    public static Boolean populateSVMXCBoolean(Map < String, Schema.SObjectField > objWorkDetailFields, SVMXC__Service_Order_Line__c objWorkDetail, SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        Boolean isSVMXRecUpdate = false;
        for (String fieldName: objWorkDetailFields.keyset()) {

            if (objWorkDetail.get(fieldName) != objOldWorkOrderLine.get(fieldName)) {
                isSVMXRecUpdate = false;
                break;
            } else{
                isSVMXRecUpdate = true;
            }
        }
        return isSVMXRecUpdate;
    }
    
}
