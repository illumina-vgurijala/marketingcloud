/*****************************************************************************************************************
 * Class Name: ProcessWDBeforeDelete_WorkdetailHelper
 * 
 * Description: Helper class for processing work detail on before delete.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for processing work detail on before delete.
 * 
 ******************************************************************************************************************/
public with sharing class ProcessWDBeforeDelete_WorkdetailHelper {
    public static final String STRING_INTEGRATION_SUCCESS = 'Success';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tool';
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED = 'Material Consumed';
    public static final String STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION = System.Label.Work_Detail_Record_Type_Usage_Consumption;
    public static Id idWorkDetailUsageRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId();
    /*
     *  @AUTHOR:  Shruti 
     *  @DESCRIPTION: Method to restrict user from deleting Work Details. Updated for DCP-37747
     *  @PARAM :  List<SVMXC__Service_Order_Line__c> records
     *  @RETURN:  void
     */
    public static void restrictWorkDetailsDeletion(List < SVMXC__Service_Order_Line__c > records) {

        //Added by Shruti Karn for RITM0356143
        User loggedInUser = [Select profile.Name from User where Id =: USerInfo.getUserId()];

        for (SVMXC__Service_Order_Line__c objWorkDetail: records) {

            //Added by Shruti Karn for RITM0356143. Allow only Admin to delete any Work detail
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS &&
                objWorkDetail.SVMX_PS_External_ID__c != null &&
                objWorkDetail.Integration_Status__c == STRING_INTEGRATION_SUCCESS &&
                (loggedInUser.profile.Name != Label.Integration_SAP_Service &&
                    loggedInUser.profile.Name != Label.ProfileSystemAdmin &&
                    loggedInUser.profile.Name != Label.Integration_Service_SNAP_Profile)
            ) {
                objWorkDetail.addError(Label.WorkDetailDeleteErrorMsg);
            }

        }

    }
    /*
     *  @AUTHOR:  Shruti 
     *  @DESCRIPTION: Method to restrict user from deleting Work Details. Updated for DCP-37747
     *  @PARAM :  List<SVMXC__Service_Order_Line__c> records
     *  @RETURN:  void
     */
    public static void updateWarningMessageOnWorkOrder(List < SVMXC__Service_Order_Line__c > records) {

        Set < Id > setWorkOrderIdsWarningMessageUpdated = new Set < Id > ();
        List < SVMXC__Service_Order_Line__c > lstWorkDetailsToolsPartsDeleted = new List < SVMXC__Service_Order_Line__c > ();
        Map < Id, SVMXC__Service_Order__c > workOrderIdToRecordToBeUpdated = new Map < Id, SVMXC__Service_Order__c > ();
        Set < Id > setProductsIdsSelected = new Set < Id > ();

        for (SVMXC__Service_Order_Line__c objWorkDetail: records) {
            
            checkIfToolsIsPresentInFRU(objWorkDetail, setWorkOrderIdsWarningMessageUpdated, lstWorkDetailsToolsPartsDeleted , setProductsIdsSelected);
        }

        //Fetch the associated parent records and create its map
        Map < Id, Product2 > productIdToRecordMap = new Map < Id, Product2 > (new ProductsSelector().selectProducts(setProductsIdsSelected));

        Map < Id, SVMXC__Service_Order__c > idToWorkOrderMap = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setWorkOrderIdsWarningMessageUpdated));

        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetailsToolsPartsDeleted) {
            //Bug fix - DCP - 38189 - Start
            string source = productIdToRecordMap.get(objWorkDetail.SVMXC__Product__c).Name;
           
            source = getProductName(source, '+');
            source = getProductName(source, '(');
            source = getProductName(source, ')');
            
            string productName = source;
            //Bug fix - DCP - 38189 - End
            String strWarningMessageRegex = '^.*Warning for part ' + productName + '.*on the Work Order.$';
            Pattern objPattern = Pattern.compile(strWarningMessageRegex);
            if (!workOrderIdToRecordToBeUpdated.containsKey(objWorkDetail.SVMXC__Service_Order__c)) {
                workOrderIdToRecordToBeUpdated.put(objWorkDetail.SVMXC__Service_Order__c, new SVMXC__Service_Order__c(Id = idToWorkOrderMap.get(objWorkDetail.SVMXC__Service_Order__c).Id, Warning_Message__c = idToWorkOrderMap.get(objWorkDetail.SVMXC__Service_Order__c).Warning_Message__c));
            }
            String strWorkOrderWarningMessage = workOrderIdToRecordToBeUpdated.get(objWorkDetail.SVMXC__Service_Order__c).Warning_Message__c;
            //Bug fix - DCP - 38189 - Start
            string sourceNew = strWorkOrderWarningMessage;
            
            source = getProductName(source, '+');
            strWorkOrderWarningMessage = sourceNew;
            //Bug fix - DCP - 38189 - End
            if (strWorkOrderWarningMessage != null && strWorkOrderWarningMessage.contains('\r\n')) {
                populateWorkorderMap(objWorkDetail, objPattern, strWorkOrderWarningMessage, workOrderIdToRecordToBeUpdated);
            } else {
                blankWarningMessage(objWorkDetail, objPattern, strWorkOrderWarningMessage, workOrderIdToRecordToBeUpdated);
            }
        }

        updateWorkdetails(workOrderIdToRecordToBeUpdated);

    }
    /*
     *  @AUTHOR:  Prashanth 
     *  @DESCRIPTION: Method to get the product name.
     *  @PARAM :  NA
     *  @RETURN:  void
     */
    public static string getProductName(String source, String target){
        if (String.isNotBlank(source)) {
            while (source.contains(target)) {
                Integer index = source.indexOf(target);
                source = source.left(index) + source.right(source.length() - index - 1);
            }
        }
        return source;
    }
    /*
     *  @AUTHOR:  Prashanth 
     *  @DESCRIPTION: Method to update the work details.
     *  @PARAM :  NA
     *  @RETURN:  void
     */
    public static void updateWorkdetails(Map < Id, SVMXC__Service_Order__c > workOrderIdToRecordToBeUpdated){
        Map<Id, SVMXC__Service_Order__c> mapFinalWOToBeUpdated = new Map<Id, SVMXC__Service_Order__c>();
        if (workOrderIdToRecordToBeUpdated != null && !workOrderIdToRecordToBeUpdated.isEmpty()) {

            for (Id workOrderId: workOrderIdToRecordToBeUpdated.keyset()) {
                if (workOrderIdToRecordToBeUpdated.get(workOrderId).Warning_Message__c != null) {
                    mapFinalWOToBeUpdated.put(workOrderId, workOrderIdToRecordToBeUpdated.get(workOrderId));
                }
            }
            if(System.isQueueable()){
                if(!mapFinalWOToBeUpdated.isEmpty()){
                    update mapFinalWOToBeUpdated.values();
                }
            }else{
                Workdetails.mapFinalWOToBeUpdated = mapFinalWOToBeUpdated;
            }
            // if (!lstFinalWOToBeUpdated.isEmpty()){
            //     update lstFinalWOToBeUpdated;
            // }
        }
    }
    /*
     *  @AUTHOR:  Prashanth 
     *  @DESCRIPTION: Method to populate the required sets.
     *  @PARAM :  NA
     *  @RETURN:  void
     */
    public static void checkIfToolsIsPresentInFRU(SVMXC__Service_Order_Line__c objWorkDetail, Set < Id > setWorkOrderIdsWarningMessageUpdated, List < SVMXC__Service_Order_Line__c > lstWorkDetailsToolsPartsDeleted ,Set < Id > setProductsIdsSelected){
        // Check if the tool selected is present in the FRU list
        if ((objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS ||
            objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS ||
            objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED) &&
            objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
            objWorkDetail.SVMXC__Product__c != null) {
            setWorkOrderIdsWarningMessageUpdated.add(objWorkDetail.SVMXC__Service_Order__c);
            lstWorkDetailsToolsPartsDeleted.add(objWorkDetail);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);
        }
    }
    /*
     *  @Method:  Prashanth 
     *  @DESCRIPTION: Method to populate the required sets.
     *  @PARAM :  NA
     *  @RETURN:  void
     */
    public static void populateWorkorderMap(SVMXC__Service_Order_Line__c objWorkDetail, Pattern objPattern, String strWorkOrderWarningMessage, Map < Id, SVMXC__Service_Order__c > workOrderIdToRecordToBeUpdated ){
        for (String strIndividualError: strWorkOrderWarningMessage.split('\r\n')) {
            Matcher objMatcher = objPattern.matcher(strIndividualError);
            Boolean boolPatternMatchResult = objMatcher.matches();
            if (boolPatternMatchResult) {
                //strWorkOrderWarningMessage = strWorkOrderWarningMessage.replaceFirst(strIndividualError, '');
                workOrderIdToRecordToBeUpdated.get(objWorkDetail.SVMXC__Service_Order__c).Warning_Message__c = strWorkOrderWarningMessage.replaceFirst(strIndividualError, '');
                break;
            }
        }
    }
    /*
     *  @Method:  Prashanth 
     *  @DESCRIPTION: Method to blank out the warning message.
     *  @PARAM :  NA
     *  @RETURN:  void
     */
    public static void blankWarningMessage(SVMXC__Service_Order_Line__c objWorkDetail, Pattern objPattern, String strWorkOrderWarningMessage, Map <Id,SVMXC__Service_Order__c> workOrderIdToRecordToBeUpdated){
        if (objPattern != null && strWorkOrderWarningMessage != null) { 
            Matcher objMatcher = objPattern.matcher(strWorkOrderWarningMessage);
            Boolean boolPatternMatchResult = objMatcher.matches();
            if (boolPatternMatchResult) {
                //strWorkOrderWarningMessage = '';
                workOrderIdToRecordToBeUpdated.get(objWorkDetail.SVMXC__Service_Order__c).Warning_Message__c = '';
            }
        }
    }
    /*
     *  @AUTHOR:  prashanth 
     *  @DESCRIPTION: Method to be called before delete of the work details
     *  @PARAM :  list<SVMXC__Service_Order_Line__c>
     *  @RETURN:  void
     */
    public static Set <Id> processWorkdetailsBeforeDelete(List < SVMXC__Service_Order_Line__c > records){
        Set < Id > setDeletedWDIds = new Set < Id > (); // DCP-33467
        for (SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records) {
            // DCP-33467: Delete Allocation Stock if a Parts Debrief line is deleted
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) {
                setDeletedWDIds.add(objWorkDetail.Id);
            }
        }
        return setDeletedWDIds;
        
    }
    
}
