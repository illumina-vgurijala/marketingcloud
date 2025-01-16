/*****************************************************************************************************************
 * Class Name: AutoRMA_WorkdetailHelper
 * 
 * Description: Helper class for processing work detail after update.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  03-12-2021                       Helper class for processing work detail after update.
 * 
 ******************************************************************************************************************/
public with sharing class AutoRMA_WorkdetailHelper {
    //DCP-37747
    // public static final Set < String > SET_BYPASS_LINE_STATUS_FROM_ADDERROR = new Set < String > {
    //     'Canceled'
    // };
    public static Boolean hasupdaterun = false;
    public static final String STRING_WORK_DETAIL_NON_BILLABLE_REASON_CONSUMABLE_WARRANTY = 'Consumable Warranty';
    public static final String STRING_REVERSAL_REQUESTED = 'Reversal Requested';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS = 'Parts';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED = 'Material Consumed';
    public static List<String> lstAdminIntegrationProfiles = new List<String> {Label.Integration_SAP_Service, Label.ProfileSystemAdmin, Label.Integration_Service_SNAP_Profile} ;
    
     /**
     * Method:throwAutoRMAValidation
     * Description: Method to throw the validation error.
     * Params: old record & new record.
     * return: void
     */
    public static Set<Id> throwAutoRMAValidation(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail, Set < Id > setInsertedPartWorkDetailsIds){
        //check if Work Detail consumption confirmed is checked
        if ((objNewWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || (objNewWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objNewWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != NULL)) && objOldWorkDetail.Consumption_Confirmed__c == true && objNewWorkDetail.Consumption_Confirmed__c == false) {

            //DCP-37747 - Bypass canceled line status - uncomment after post commit
            //if (!SET_BYPASS_LINE_STATUS_FROM_ADDERROR.contains(objNewWorkDetail.SVMXC__Line_Status__c)){objNewWorkDetail.addError(Label.AutoRMACheckedError);} - commented for INC0363183 and added bypass for admin/SAP
            if(!lstAdminIntegrationProfiles.contains(Workdetails.currentUser.profile.Name)){objNewWorkDetail.addError(Label.AutoRMACheckedError);}
        } else if ((objNewWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || (objNewWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objNewWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c != NULL)) && objOldWorkDetail.Consumption_Confirmed__c == false && objNewWorkDetail.Consumption_Confirmed__c == true) {
            setInsertedPartWorkDetailsIds.add(objNewWorkDetail.Id);
        }
        return setInsertedPartWorkDetailsIds;
    }
    /**
     * Method:getReversalRequestedWorkorders
     * Description: Method to populate the reversal requested work orders set.
     * Params: old record & new record.
     * return: void
     */
    public static Set<Id> getReversalRequestedWorkorders(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail, set<Id> setWorkOrderIds){
        //DCP-44981 - Trigger integration if WD is moved to Reversal Requested except when WD is CP
        if (objOldWorkDetail.SVMXC__Line_Status__c != objNewWorkDetail.SVMXC__Line_Status__c && objNewWorkDetail.SVMXC__Line_Status__c == STRING_REVERSAL_REQUESTED && Workdetails.consumedFromLocationIdToLocationMap != null && !Workdetails.consumedFromLocationIdToLocationMap.isEmpty() && Workdetails.consumedFromLocationIdToLocationMap.get(objNewWorkDetail.SVMXC__Consumed_From_Location__c).Type__c != 'Partner Stock'&& objNewWorkDetail.SVMXC__Service_Order__c != null) {setWorkOrderIds.add(objNewWorkDetail.SVMXC__Service_Order__c);}
        return setWorkOrderIds;
    }
    /**
     * Method:populateBillableServiceOrders
     * Description: Method to populate the set of billable work orders.
     * Params: old record & new record.
     * return: void
     */
    public static Set<Id> populateBillableServiceOrders(SVMXC__Service_Order_Line__c objOldWorkDetail, SVMXC__Service_Order_Line__c objNewWorkDetail,Map<Id, SVMXC__Service_Order__c> partnerWorkOrderIdsToPartnerWorkOrder, Set < Id > setBillableServiceOrderIds){
        //DCP-38817
        //conditions - Billable by the system to Non Billable and any Non Billable Reason excluding Consumable Warranty.
        if (objOldWorkDetail.SVMXC__Is_Billable__c && !objNewWorkDetail.SVMXC__Is_Billable__c && objNewWorkDetail.Non_Billable_Reason__c != STRING_WORK_DETAIL_NON_BILLABLE_REASON_CONSUMABLE_WARRANTY && partnerWorkOrderIdsToPartnerWorkOrder != null && partnerWorkOrderIdsToPartnerWorkOrder.containsKey(objNewWorkDetail.SVMXC__Service_Order__c) && (!partnerWorkOrderIdsToPartnerWorkOrder.get(objNewWorkDetail.SVMXC__Service_Order__c).Partner_Work_Order__c) && !hasupdaterun) {
            setBillableServiceOrderIds.add(objNewWorkDetail.Id);
            hasupdaterun = true;
        }
        return setBillableServiceOrderIds;
    }
    /**
     * Method:workdetailsComplexBillableRules
     * Description: Method to calculate  billable logic of work details. //DCP-40191
     * Params: map
     * return: Boolean
     */
    public Static Boolean workdetailsComplexBillableRules(Map < String, Object > args) {

        Boolean conditionOutcome = false;
        String ruleId = null;
        if (args != null && !args.IsEmpty()) {
            RuleId = (String) args.get('RuleId');
        }

        if (!String.IsBlank(RuleId) && RuleId == 'Rule-041') {
            SVMXC__Service_Order_Line__c objWorkDetail = (SVMXC__Service_Order_Line__c) args.get('Sobject');
            System.debug('RuleEngineCallable..' + RuleId);
            conditionOutcome = calculateOutcome(objWorkDetail);
        } else if (!String.IsBlank(RuleId) && RuleId == 'Rule-042') {
            SVMXC__Service_Order_Line__c objWorkDetail = (SVMXC__Service_Order_Line__c) args.get('Sobject');
            conditionOutcome = calculateOutcomeForRule(objWorkDetail);
        }
        return conditionOutcome;
    }
    /**
     * Method:calculateOutcomeForRule
     * Description: Method to calculate  the outcome. //DCP-40191
     * Params: workdetail object
     * return: Boolean
     */
    public static Boolean calculateOutcome(SVMXC__Service_Order_Line__c objWorkDetail){
        Boolean conditionOutcome = false;
        if (String.IsBlank(objWorkDetail.Non_Billable_Reason__c) && objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED && objWorkDetail.SVMXC__Line_Type__c != Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS && String.IsBlank(objWorkDetail.Indirect_in_hours__c) && objWorkDetail.SVMXC__Is_Billable__c == false &&
            !(objWorkDetail.SVMXC__Activity_Type__c == Workdetails.STRING_WOD_ACTIVITY_TYPE_IQ_OQ ||
                objWorkDetail.SVMXC__Activity_Type__c ==Workdetails.STRING_WOD_ACTIVITY_TYPE_PQ ||
                objWorkDetail.SVMXC__Activity_Type__c == Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW ||
                objWorkDetail.SVMXC__Activity_Type__c == Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW ||
                objWorkDetail.SVMXC__Activity_Type__c == Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW)) {
            if (!(objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Line_Status__c == Label.WorkDetailLineStatusClosed)) {
                conditionOutcome = true;
            }
        }
        return conditionOutcome;
    }
    /**
     * Method:calculateOutcomeForRule
     * Description: Method to calculate  the outcome. //DCP-40191
     * Params: workdetail object
     * return: Boolean
     */
    public static Boolean calculateOutcomeForRule(SVMXC__Service_Order_Line__c objWorkDetail){
        Boolean conditionOutcome = false;
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && (!String.isBlank(objWorkDetail.Indirect_in_hours__c) && objWorkDetail.Indirect_in_hours__c != null && ((objWorkDetail.Indirect_in_hours__c).remove(':')).IsNumeric() && (Integer.ValueOf((objWorkDetail.Indirect_in_hours__c).remove(':')) != 0))) {
            if (String.isBlank(objWorkDetail.Labor_Hours__c) || (objWorkDetail.Labor_Hours__c != null && ((objWorkDetail.Labor_Hours__c).remove(':')).IsNumeric() && Integer.ValueOf((objWorkDetail.Labor_Hours__c).remove(':')) == 0)) {
                if (String.isBlank(objWorkDetail.Travel_Time_in_hours__c) || (objWorkDetail.Travel_Time_in_hours__c != null && ((objWorkDetail.Travel_Time_in_hours__c).remove(':')).IsNumeric() && Integer.ValueOf((objWorkDetail.Travel_Time_in_hours__c).remove(':')) == 0)) {
                    conditionOutcome = true;
                }
            }
        }
        return conditionOutcome;
    }
}