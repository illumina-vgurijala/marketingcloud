/*****************************************************************************************************************
 * Class Name: ApprovalsBeforeUpdate_WorkdetailHelper
 * Description: Approvals in before update of work details.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Approvals in before update of work details.
 ******************************************************************************************************************/
public with sharing class ApprovalsBeforeUpdate_WorkdetailHelper {
    public static final String WD_APPROVALSTATUS_PENDINGAPPROVAL = 'Pending Approval';
    public static final String WD_APPROVALSTATUS_REJECTED = 'Rejected';
    public static final String WD_APPROVALSTATUS_NOTREQUIRED = 'Not Required';
    public static List < SVMXC__Service_Order_Line__c > lstRejectedWDs = new List < SVMXC__Service_Order_Line__c > ();
    public static List < SVMXC__Service_Order_Line__c > lstNormalWDs = new List < SVMXC__Service_Order_Line__c > ();
    public static Map < Id, set < Id >> idWoToSetAppContractId = new Map < Id, set < Id >> ();

    /*
     *  @author - Tapas
     *  @description - DCP-43634, as approval records are unlocked in WorkDetailsWithoutSharingInner class, here using a custom apex validation to prevent users from editing records which are pending approval 
     */
    public static void preventEditWhenPendingApproval(List < SVMXC__Service_Order_Line__c > records, Map < Id, SVMXC__Service_Order_Line__c > oldRecords) {
        Boolean isRecordChanged;
        Map < String, Schema.SObjectField > fieldMapWD = Schema.SObjectType.SVMXC__Service_Order_Line__c.fields.getMap();

        for (SVMXC__Service_Order_Line__c objWD: records) {
            SVMXC__Service_Order_Line__c objOldWD = oldRecords.get(objWD.Id);
            isRecordChanged = false;
            if (objWD.Approval_Status__c == WD_APPROVALSTATUS_PENDINGAPPROVAL && (GoodWillApprovals_WorkdetailHelper.idWDToWDGoodwillApproval == null || !GoodWillApprovals_WorkdetailHelper.idWDToWDGoodwillApproval.containsKey(objWD.Id)) && Workdetails.currentUser.profile.Name != Label.ProfileSystemAdmin) {
                isRecordChanged = updateBoolean(fieldMapWD, objWD, objOldWD);
                if (isRecordChanged) {
                    objWD.addError(System.Label.UI_Error_WD_PreventEditOnPendingGoodwillApproval);
                }
            }
        }
    }
    /*
     *  @author - Tapas
     *  @description - DCP-43634, as approval records are unlocked in WorkDetailsWithoutSharingInner class, here using a custom apex validation to prevent users from editing records which are pending approval 
     */
    public static Boolean updateBoolean(Map < String, Schema.SObjectField > fieldMapWD, SVMXC__Service_Order_Line__c objWD, SVMXC__Service_Order_Line__c objOldWD){
        Boolean isRecordChanged = false;
        for (String strWDField: fieldMapWD.keyset()) {
            if (fieldMapWD.get(strWDField).getDescribe().isUpdateable() && objWD.get(strWDField) != objOldWD.get(strWDField)) {
                isRecordChanged = true;
                break;
            }
        }
        return isRecordChanged;
    }

    /*
     *  @author - Tapas
     *  @description - DCP-43634, for Goodwill WDs approval if rejected, Non-Billable reason will revert to previous value. This method should be called before processBillableBypassesAndValidations so that on revert billable logic runs correctly
     * 
     */
    public static void revertNonBillableReasonOnRejection(List < SVMXC__Service_Order_Line__c > records, Map < Id, SVMXC__Service_Order_Line__c > oldRecords) {
        Set < String > setRejectedNotReqStatuses = new Set < String > {
            WD_APPROVALSTATUS_REJECTED,
            WD_APPROVALSTATUS_NOTREQUIRED
        };

        for (SVMXC__Service_Order_Line__c objWD: records) {
            SVMXC__Service_Order_Line__c objOldWD = oldRecords.get(objWD.Id);
            if (objWD.Approval_Status__c != objOldWD.Approval_Status__c && setRejectedNotReqStatuses.contains(objWD.Approval_Status__c)) {
                lstRejectedWDs.add(objWD);
            } else {
                lstNormalWDs.add(objWD);
            }
        }
        if (lstRejectedWDs.isEmpty()){
            return;
        }

        List < SVMXC__Service_Order_Line__History > lstWDHistories = [select parentid, Field, OldValue, NewValue from SVMXC__Service_Order_Line__History where Field = 'Non_Billable_Reason__c'
            and parentid in: lstRejectedWDs order by createddate
        ];

        if (lstWDHistories == null || lstWDHistories.isEmpty()) {
            for (SVMXC__Service_Order_Line__c objWD: lstRejectedWDs) {
                objWD.Non_Billable_Reason__c = null;
                objWD.SVMXC__Is_Billable__c = true;
            }
            return;
        }

        Map < id, List < SVMXC__Service_Order_Line__History >> idToLstWDHistories = (Map < id, List < SVMXC__Service_Order_Line__History >> ) UtilsCollection.getMapOfIdToSObjects(lstWDHistories, 'parentid');
        for (SVMXC__Service_Order_Line__c objWD: lstRejectedWDs) {
            List < SVMXC__Service_Order_Line__History > lstobjWDHistory = idToLstWDHistories.get(objWD.Id);
            if (lstobjWDHistory != null) {
                objWD.Non_Billable_Reason__c = String.valueOf(lstobjWDHistory.get(lstobjWDHistory.size() - 1).OldValue);
            } else {
                objWD.Non_Billable_Reason__c = null;
            }
            objWD.SVMXC__Is_Billable__c = true;
        }
    }
    /*
     *  @author - Tapas
     *  @description - DCP-43634, for Goodwill WDs approval if rejected, Non-Billable reason will revert to previous value. This method should be called before processBillableBypassesAndValidations so that on revert billable logic runs correctly
     * 
     */
    public static void updateNonBillableReason(List<SVMXC__Service_Order_Line__c> records){
        
        Map < Id, SVMXC__Service_Order__c > idToworkOrder = Workdetails.idParentWOToWO;
        //DCP-41937
        for (SVMXC__Service_Order_Line__c wd: BeforeUpdate_WorkdetailHelper.lstWorkOrderLinesWithBillableChange) {
            if (idToworkOrder.containsKey(wd.SVMXC__Service_Order__c) && idToworkOrder.get(wd.SVMXC__Service_Order__c).SVMXC__Order_Type__c == Workdetails.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION && idToworkOrder.get(wd.SVMXC__Service_Order__c).IP_Asset_Type__c == Workdetails.STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED && wd.Non_Billable_Reason__c != null) {
                wd.Non_Billable_Reason__c = '';
            }
        }
        for (Applied_Contract__c objAppContract: new AppliedContractsSelector().selectWorkOrderEntitlements(BeforeUpdate_WorkdetailHelper.setWorkOrderIds)) {
            if (!idWoToSetAppContractId.containskey(objAppContract.Work_Order__c)) {
                idWoToSetAppContractId.put(objAppContract.Work_Order__c, new Set < Id > ());
            }
            idWoToSetAppContractId.get(objAppContract.Work_Order__c).add(objAppContract.Id);
        }

        //execute Billable rules on update      
        processBillableBypassesAndValidations(idToWorkOrder, idWoToSetAppContractId, records);
    
        
    }
    /*
     *  @author - Tapas
     *  @description - Is_Billable__c Bypasses and validations
     * 
     */
    public static void processBillableBypassesAndValidations(Map < Id, SVMXC__Service_Order__c > idToWorkOrder, Map < Id, Set < Id >> idWoToSetAppContractIdm ,List < SVMXC__Service_Order_Line__c > records) {
        //DCP-40191
        Map < id, SVMXC__Service_Contract__c > workDetailtoServiceContractMap = new Map < id, SVMXC__Service_Contract__c > ();

        Map < Id, Sobject > userMap = new Map < Id, Sobject > ();
        for (Id wo: idToWorkOrder.keyset()) {
            UserMap.put(idToWorkOrder.get(wo).Id, new user(Username = UserInfo.getName()));
        }

        List < String > lstruleIds = new List < String > ();
        if (!String.IsEmpty(Label.WorkDetailBillableRulesonUpdate)){
            lstruleIds = new List < String > (Label.WorkDetailBillableRulesonUpdate.split(','));
        }
        for (Id key: idWoToSetAppContractId.keySet()) {
            WorkDetailtoServiceContractMap.put(key, new SVMXC__Service_Contract__c());
        }

        //DCP-40191
        if (!idToWorkOrder.IsEmpty()) {
            Map < String, Map < Id, Object >> mapofNeededSobjects = new Map < String, Map < Id, Object >> ();
            mapofNeededSobjects.put('WorkDetailtoServiceContractMap', WorkDetailtoServiceContractMap);
            mapofNeededSobjects.put('WorkDetailtoWorkOrderMap', idToWorkOrder);
            mapofNeededSobjects.put('UserMap', UserMap);


            System.debug('here..' + mapofNeededSobjects);
            //DCP-43634 start
            if (lstRejectedWDs == null || lstRejectedWDs.isEmpty()){
                RuleEngineLogic.runtheBussinessRules('SVMXC__Service_Order_Line__c', 'Billable', records, mapofNeededSobjects, lstruleIds);
            }
            else {
                //RuleEngineLogic.runtheBussinessRules('SVMXC__Service_Order_Line__c','Billable',lstRejectedWDs,mapofNeededSobjects,null);
                BillableRules_WorkdetailsHelper.executeIsBillableRules(lstRejectedWDs); //run the billable logic same as in insert
                RuleEngineLogic.runtheBussinessRules('SVMXC__Service_Order_Line__c', 'Billable', lstNormalWDs, mapofNeededSobjects, lstruleIds);
                lstNormalWDs.clear();
                lstRejectedWDs.clear();
            }
            //DCP-43634 end
        }
        
    }
    /*
     *  @author - Tapas
     *  @description - update serial number
     * 
     */
    public static void updateSerialNumber(Map < Id, Id > iPtoProduct,SVMXC__Service_Order_Line__c objWorkDetail,SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        if (IPtoProduct != Null && objWorkDetail.SVMXC__Serial_Number__c != Null && IPtoProduct.containsKey(objWorkDetail.SVMXC__Serial_Number__c)) {
            objWorkDetail.SVMXC__Product__c = IPtoProduct.get(objWorkDetail.SVMXC__Serial_Number__c);
        }

        if (objWorkDetail.SVMXC__Serial_Number__c != objOldWorkOrderLine.SVMXC__Serial_Number__c && objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED) {
            if (objWorkDetail.SVMXC__Serial_Number__c == Null) {
                objWorkDetail.SVMXC__Serial_Number_List__c = Null;
            } else if (Workdetails.mapRelatedIP.containsKey(objWorkDetail.SVMXC__Serial_Number__c)) {
                objWorkDetail.SVMXC__Serial_Number_List__c = Workdetails.mapRelatedIP.get(objWorkDetail.SVMXC__Serial_Number__c).SVMXC__Serial_Lot_Number__c;
            }
        }
    }
}
