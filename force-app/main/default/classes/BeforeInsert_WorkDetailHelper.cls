/*****************************************************************************************************************
 * Class Name: BeforeInsert_WorkDetailHelper
 * 
 * Description: Helper class for updating the fields on before insert.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for updating the fields on before insert.
 * 
 ******************************************************************************************************************/
public with sharing class BeforeInsert_WorkDetailHelper {
    public static final Integer INTEGER_ONE = 1;
    /*******************************************************************************************************
     * @description DCP-50097 method to make Batch Number NULL when Batch Lookup is null;
     * @param objWorkDetail New list of records
     * @return
     * @author Harsh Shukla
     */
    public static void makeBatchNumberNull(SVMXC__Service_Order_Line__c objWorkDetail) {
        if (
            objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS &&
            objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED &&
            !String.isBlank(objWorkDetail.SVMX_PS_VS_Consumed_Product_Stock__c) &&
            String.isBlank(objWorkDetail.Batch_Lookup__c) &&
            !String.isBlank(objWorkDetail.Batch_Number__c)
        ) {
            objWorkDetail.Batch_Number__c = null;
        }
    }
    /*
     * @author : Gagan Sindwani
     * @description : DCP-47396 - Method to calculate Duration = Labor Hours + Indirect Hours
     * @param : laborHours - field Labor_Hours__c in work details
     * @param : indirectHours - field Indirect_in_hours__c in work details
     * @return : duration - return value of "duration in Hours"
     * @example : laborHours + indirectHours => 10:45 + 5:30 = 16:15 Duration
     */
    public static string calculateDuration(String laborHours, String indirectHours, String travelHours) {
        if(laborHours != null || indirectHours != null || travelHours != null){
            Integer totalMinutes = ServiceUtilityCollection.convertHoursToMinutes(laborHours) + ServiceUtilityCollection.convertHoursToMinutes(indirectHours) + ServiceUtilityCollection.convertHoursToMinutes(travelHours);
            return ServiceUtilityCollection.convertMinutesToHours(totalMinutes); 
        }
        return null;
    }
    //47396
    /*******************************************************************************************************
     * Method: calculateEndDate
     * @description To calculate the end date.
     * @param Datetime startDate, String duration
     * @return: DateTime
     * @author Harsh Shukla
     */
    public static DateTime calculateEndDate(DateTime startDate, String duration) {
        List < String > lstHoursAndMinutes = new List<String>();
        DateTime endDate = null;
        if(startDate != null && String.isNotBlank(duration)){
            endDate = startDate;
            lstHoursAndMinutes = duration.split(':');
        }
        if (!lstHoursAndMinutes.isEmpty()) {
            try {
                endDate = startDate.addHours(Integer.valueOf(lstHoursAndMinutes[0]));
                if (lstHoursAndMinutes.size() > INTEGER_ONE) {
                    endDate = endDate.addMinutes(Integer.valueOf(lstHoursAndMinutes[1]));
                }
            } catch (TypeException e) {
                ApexExceptions.emit('WorkDetails.calculateEndDate', e);
            }
        }
        return endDate;
    }
    /**
     * Method: getCurrentUser
     * Description: Method to fetch the current user.
     * return: void
     */
    public static Map <Id,Id> getUsersManager(){
        Map < Id, Id > idUserToManager = new Map < Id, Id > ();
        if(Workdetails.idParentWOToWO != null){
            Workdetails.idWOtoWOOwnerId = UtilsCollection.getMapOfIdToId(Workdetails.idParentWOToWO.values(), 'ID', 'OwnerId');
            List < User > lstUsers = new UsersSelector().selectByUserId(new set < Id > (Workdetails.idWOtoWOOwnerId.values()));
            for (User objUser: lstUsers) {
                idUserToManager.put(objUser.Id, objUser.ManagerId);
                if (objUser.Id == UserInfo.getUserId()){
                    Workdetails.currentUser = objUser;
                }     
            }
        }
        return idUserToManager;
    }
    /**
     * Method: populateSerialNumber
     * Description: to populate the serial number & return serial number on the work detail
     */
    public static void populateSerialNumber(List<SVMXC__Service_Order_Line__c> lstWorkDetails){
        //DCP-33873(Refractor WF :- Work Detail : Return Installed Product Is Not Blank)
        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetails) {

            //DCP-44981
            if (Workdetails.consumedStockedSerialIdToConsumedStockedSerailMap != null && !Workdetails.consumedStockedSerialIdToConsumedStockedSerailMap.isEmpty() && Workdetails.consumedStockedSerialIdToConsumedStockedSerailMap.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c)){
                objWorkDetail.SVMXC__Serial_Number__c = Workdetails.consumedStockedSerialIdToConsumedStockedSerailMap.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c).SVMX_PS_VS_Linked_Installed_Product__c;
            }
            if (!String.IsBlank(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c) && !Workdetails.mapIdToIP.IsEmpty() && Workdetails.mapIdToIP.containsKey(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c)) {
                objWorkDetail.SVMX_PS_VS_Return_Serial_Number__c = Workdetails.mapIdToIP.get(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c).SVMXC__Serial_Lot_Number__c;
            }    
        }
    }
    /**
     * Method: getProductFromInstallProduct
     * Description: refactor: populate product realted to IP
     */

    public static Map < Id, Id > getProductFromInstallProduct(List < SVMXC__Service_Order_Line__c > lstWorkDetails) {

        Set < Id > setInstaledProductIds = new Set < Id > ();
        Map < Id, Id > installedProdcutIdToProductId = new Map < Id, Id > ();
        for (SVMXC__Service_Order_Line__c objWorkDetail: lstWorkDetails) {
            if (objWorkDetail.SVMXC__Serial_Number__c != null) {
                setInstaledProductIds.add(objWorkDetail.SVMXC__Serial_Number__c);
            }
        }

        if (setInstaledProductIds.size() > 0) {
            for (SVMXC__Installed_Product__c objInstalledProduct: new InstalledProductsSelector().selectInstalledProductsFromIds(setInstaledProductIds)) {
                InstalledProdcutIdToProductId.put(objInstalledProduct.Id, objInstalledProduct.SVMXC__Product__c);
                Workdetails.mapRelatedIP.put(objInstalledProduct.Id, objInstalledProduct);
            }
        }

        return InstalledProdcutIdToProductId;
    }
    /**
     * Method: updateFieldsOnBeforeInsert
     * Description: Method to populate the work detail fields on before insert
     * Params: List<SVMXC__Service_Order_Line__c> 
     * Return: void
     */
    public static void updateFieldsOnBeforeInsert(List<SVMXC__Service_Order_Line__c> lstWorkDetails){
        Map < Id, Id > iPtoProduct = Workdetails.IPtoProduct;
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetails){
            if(!iPtoProduct.isEmpty() && iPtoProduct.containsKey(objWorkDetail.SVMXC__Serial_Number__c)){
                objWorkDetail.SVMXC__Product__c = iPtoProduct.get(objWorkDetail.SVMXC__Serial_Number__c);
            }
            //DCP-49744 - Logic to populate serial Number for service report.
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED && objWorkDetail.SVMXC__Serial_Number__c != Null && Workdetails.mapRelatedIP.containsKey(objWorkDetail.SVMXC__Serial_Number__c)) {
                objWorkDetail.SVMXC__Serial_Number_List__c = Workdetails.mapRelatedIP.get(objWorkDetail.SVMXC__Serial_Number__c).SVMXC__Serial_Lot_Number__c;
            }
            //DCP-50097
            makeBatchNumberNull(objWorkDetail);
            //DCP-37399
            //If "Consumption Confirmed" is true, save the date/time and loggedin user
            if (objWorkDetail.Consumption_Confirmed__c) {
                objWorkDetail.Consumption_Confirmed_Date_Time__c = DateTime.now();
                objWorkDetail.Consumption_Confirmed_User__c = USerInfo.getUserId();
            }
            //DCP - 47396
            objWorkDetail.Duration_in_hours__c = calculateDuration(objWorkDetail.Labor_Hours__c, objWorkDetail.Indirect_in_hours__c,objWorkDetail.Travel_Time_in_hours__c);
            
            //DCP-33873  Refractor WF:- Work Detail : Activity End Date Time)
            objWorkDetail.SVMXC__End_Date_and_Time__c = calculateEndDate(objWorkDetail.SVMXC__Start_Date_and_Time__c, objWorkDetail.Duration_in_hours__c);
            
            //DCP-33873(Refractor WF :- Work Detail : Default To Closed Status)
            //DCP-37747 - Run only if the incoming status is "Open" and not otherwise.
            if (Workdetails.SET_WD_ACTIVITY_TYPES.contains(objWorkDetail.SVMXC__Activity_Type__c) && objWorkDetail.SVMXC__Line_Status__c == Workdetails.STRING_WORK_DETAIL_LINE_STATUS_OPEN) {
                objWorkDetail.SVMXC__Line_Status__c = Label.WorkDetailLineStatusClosed;
            }
            //DCP-33873(Refractor WF :- Work Detail :Default To Open Status)
            //DCP-37747 - Run only if the incoming status is "Open" and not otherwise.
            if (Workdetails.SET_ACTIVITY_TYPES_OPEN.contains(objWorkDetail.SVMXC__Activity_Type__c)) {
                objWorkDetail.SVMXC__Line_Status__c = Label.WorkDetailLineStatusOpen;
            }
            objWorkDetail.Owner_s_Manager__c = Workdetails.idUserToManager.get(Workdetails.idWOtoWOOwnerId.get(objWorkDetail.SVMXC__Service_Order__c));
        }
    }
}