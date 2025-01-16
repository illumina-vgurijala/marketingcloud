/*****************************************************************************************************************
 * Class Name: ProcessWDBeforeInsert_WorkDetailHelper
 * 
 * Description: Helper class for processing work detail on before insert.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for processing work detail on before insert.
 * 
 ******************************************************************************************************************/
public with sharing class ProcessWDBeforeInsert_WorkDetailHelper {
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tools';
    public static final String STRING_WORK_DETAIL_LINE_STATUS_CANCELED = 'Canceled'; //DCP-37747
    public static Set < Id > setLabourWorkDetailsReview = new Set < Id > ();
    public static set < id > setPartsSwapWorkDetails = new set < id > ();
    public static Set < Id > setToolsWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for tools
    public static Set < Id > setProductsIdsSelected = new Set < Id > (); //Set of product ids which have been selected in the work detail record.
    public static Set < Id > setPartsWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for parts
    public static Set < Id > setMaterialsConsumedWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for materials consumed
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatibleToolCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for tools
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatibleMaterialsConsumedCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for materials consumed
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatiblePartCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for tools
    public static Set < Id > setRelatedProducts = new Set < Id > ();
    public static set < Id > setInstalledProdId = new set < Id > ();
    //37734 list to hold canceld wds.
    public static List < SVMXC__service_order_Line__c > lstCanceledWd = new list < SVMXC__service_order_Line__c > ();
    public static Set < Id > setCombinedWorkOrderIds = new Set < Id > ();
    public static List < SVMXC__Service_Order_Line__c > lstCombineWOLForFRUCheck = new List < SVMXC__Service_Order_Line__c > ();
    public static Set < Id > setCombinedProductsIdsSelected = new Set < Id > ();
    //DCP-33873
    public static set < String > setTypeCheck = new set < String > ();

    public static Id idWorkDetailUsageRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Workdetails.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId();
    /*
     *  @AUTHOR:  Prashanth
     *  @DESCRIPTION: populate the sets and process the records
     *  @PARAM : List<SVMXC__Service_Order_Line__c>
     *  @RETURN:  void
     */
    public static void processWorkDetailsBeforeInsert(List<SVMXC__Service_Order_Line__c> lstWorkDetails){
        //DCP-44981
        Set < Id > setConsumedStockSerials = new set < Id > ();
        Set < SVMXC__Service_Order_Line__c > setWorkDetail = new Set < SVMXC__Service_Order_Line__c > ();
        Set < Id > setWorkOrderId = new Set < Id > ();
        //Variables to check products compatible with tools /parts selected

        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetails){
            getTools(objWorkDetail, setConsumedStockSerials, setWorkDetail, setWorkOrderId);
            getMaterialConsumedWds(objWorkDetail);
            getParts(objWorkDetail); 
        }
        //DCP-44981
        if (!setConsumedStockSerials.isEmpty()) {
            Workdetails.consumedStockedSerialIdToConsumedStockedSerailMap = new Map <Id, SVMXC__Product_Serial__c> (new StockedSerialSelector().selectStockedSerialById(setConsumedStockSerials));
        }
        if (!setWorkDetail.isEmpty() && !setWorkOrderId.isEmpty()) {
            ValidateFromLocation_WorkdetailHelper.validateFromLocation(setWorkDetail, setWorkOrderId);
        }
        processToolsAndParts();
        
        //DCP-33873(Refractor WF :- Work Detail : Return Installed Product Is Not Blank)
        Workdetails.mapIdToIP = populateIPMap(setInstalledProdId);

        
        //DCP-33873(method call for FRU Check)
        if (!setCombinedWorkOrderIds.isEmpty() && !lstCombineWOLForFRUCheck.isEmpty() && !setCombinedProductsIdsSelected.isEmpty()) {
            checkProductinFRUList(setCombinedWorkOrderIds, lstCombineWOLForFRUCheck, null, setCombinedProductsIdsSelected, 'Part', setTypeCheck);
        }
        //DCP-37747
        if (!lstCanceledWd.isEmpty()) {
            unCheckIncludeInSRforcanceledWd(lstCanceledWd);
        }
        

    }
    /**
     * Method: getToolWds
     * Description: Method to populate the sets related to Tools
     * return: void
     */
    public static void getTools(SVMXC__Service_Order_Line__c objWorkDetail, Set<Id> setConsumedStockSerials, Set < SVMXC__Service_Order_Line__c > setWorkDetail,Set<Id> setWorkOrderId){
        // Check if the tool selected is present in the FRU list
        if (objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS &&
        objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
        objWorkDetail.SVMXC__Service_Order__c != null &&
        objWorkDetail.SVMXC__Product__c != null &&
        objWorkDetail.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setToolsWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);

            //DCP-37747 - Bypass canceled WD's
            if (objWorkDetail.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                lstWOLForCompatibleToolCheck.add(objWorkDetail);
            }      

        }
        //DCP-44981
        if (String.isNotBlank(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c)) {
            setConsumedStockSerials.add(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c);
        }
        if ((objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS && objWorkDetail.SVMXC__From_Location__c != null && objWorkDetail.SVMXC__Service_Order__c != null) || (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS && objWorkDetail.SVMXC__Consumed_From_Location__c != null && objWorkDetail.SVMXC__Service_Order__c != null)) {
            setWorkDetail.add(objWorkDetail);
            setWorkOrderId.add(objWorkDetail.SVMXC__Service_Order__c);
        }
        
    }
    /**
     * Method: getToolWds
     * Description: Method to populate the sets related to materials consumed.
     * return: void
     */
    public static void getMaterialConsumedWds(SVMXC__Service_Order_Line__c objWorkDetail){
        // Check if the Materials Consumed selected is present in the FRU list
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED &&
            objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
            objWorkDetail.SVMXC__Service_Order__c != null &&
            objWorkDetail.SVMXC__Product__c != null &&
            objWorkDetail.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setMaterialsConsumedWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);

            //DCP-37747 - Bypass canceled WD's
            if (objWorkDetail.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                lstWOLForCompatibleMaterialsConsumedCheck.add(objWorkDetail);
            }

        }
        if (objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId && objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && objWorkDetail.SVMXC__Activity_Type__c != WOrkdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != WOrkdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW) { //DCP-25289 condition updated
            setLabourWorkDetailsReview.add(objWorkDetail.id);
        }
        //To find the Part Swap work details
        if (objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId && objWorkDetail.SVMXC__Line_Type__c == workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) {
            setPartsSwapWorkDetails.add(objWorkDetail.id);
        }
    }
    /**
     * Method: getParts
     * Description: Method to populate the sets related to partswap
     * return: void
     */
    public static void getParts(SVMXC__Service_Order_Line__c objWorkDetail){
        // Check if the part selected is present in the FRU list
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS &&
            objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId &&
            objWorkDetail.SVMXC__Service_Order__c != null &&
            objWorkDetail.SVMXC__Product__c != null &&
            objWorkDetail.SVMXC__Line_Status__c != STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setPartsWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);
            //DCP-37747 - Bypass canceled WD's
            lstWOLForCompatiblePartCheck.add(objWorkDetail);

        }
        //To Find Related Products
        if (objWorkDetail.RecordTypeId == Workdetails.idWorkDetailRelProdRecordTypeId) {
            setRelatedProducts.add(objWorkDetail.id);
        }

        //DCP-33873(Refractor WF :- Work Detail : Return Installed Product Is Not Blank)
        if (!String.IsBlank(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c)) {
            setInstalledProdId.add(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c);
        }
        //DCP-37747
        //creating list of wd which are canceled.
        if (!String.IsBlank(objWorkDetail.SVMXC__Line_Status__c) && objWorkDetail.SVMXC__Line_Status__c == STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            lstCanceledWd.add(objWorkDetail);
        }
    }
    /**
     * Method:processToolsAndParts
     * Description: Method to process tools & parts
     * return : void
     */
    public static void processToolsAndParts(){
        //To check the Product is listed in the FRU list of Product of Work Order
        if(!setToolsWorkOrderIds.isEmpty() && !lstWOLForCompatibleToolCheck.isEmpty() && !setProductsIdsSelected.isEmpty()) {
            //DCP-33873(populate lst/Set for FRU Check)
            setCombinedWorkOrderIds.addAll(setToolsWorkOrderIds);
            lstCombineWOLForFRUCheck.addAll(lstWOLForCompatibleToolCheck);
            setCombinedProductsIdsSelected.addAll(setProductsIdsSelected);
            setTypeCheck.add('Tool');
        }
        //To check the Product is listed in the FRU list of Product of Work Order
        if(!setPartsWorkOrderIds.isEmpty() && !lstWOLForCompatiblePartCheck.isEmpty() && !setProductsIdsSelected.isEmpty()) {
            //DCP-33873(populate lst/Set for FRU Check)
            setCombinedWorkOrderIds.addAll(setPartsWorkOrderIds);
            lstCombineWOLForFRUCheck.addAll(lstWOLForCompatiblePartCheck);
            setCombinedProductsIdsSelected.addAll(setProductsIdsSelected);
            setTypeCheck.add('Part');
        }
        //To check the Product is Spare that is listed in the FRU list of Product of Work Order
        if (!setMaterialsConsumedWorkOrderIds.isEmpty()) {
            Set < id > setSpareProductIds = new set < id > ();
            if(!setProductsIdsSelected.isEmpty()){
                for(Product2 objProduct: new ProductsSelector().selectProductsWithServiceProductType(setProductsIdsSelected, 'Spare')) {
                    setSpareProductIds.add(objProduct.id);
                }
            }
            if (!setSpareProductIds.isEmpty() && !lstWOLForCompatibleMaterialsConsumedCheck.isEmpty()) {
                //DCP-33873(populate lst/Set for FRU Check)
                setCombinedWorkOrderIds.addAll(setMaterialsConsumedWorkOrderIds);
                lstCombineWOLForFRUCheck.addAll(lstWOLForCompatibleMaterialsConsumedCheck);
                setCombinedProductsIdsSelected.addAll(setSpareProductIds);
                setTypeCheck.add('Part');
            }
        }
    }
    /**
     * Method:populateIPMap
     * Description: Method to populate IP map
     * return : void
     */
    public static Map<Id,SVMXC__Installed_Product__c> populateIPMap(Set<Id> setInstalledProdId){
        Map<Id,SVMXC__Installed_Product__c> mapIdToIP = new Map<Id,SVMXC__Installed_Product__c>();
        if (!setInstalledProdId.IsEmpty()) {
            for (SVMXC__Installed_Product__c obj: new InstalledProductsSelector().selectRelatedInstalledProducts(setInstalledProdId)) {
                mapIdToIP.put(obj.Id, obj);
            }
        }
        return mapIdToIP;
    }
    /*
     *  @AUTHOR:Ritika M
     *  @DESCRIPTION:To Check whether the product of tool / spare part is in FRU List
     *  @PARAM : set of work order id's
     *  @RETURN:void
     */
    public static void checkProductinFRUList(Set < Id > workOrderIds, List < SVMXC__Service_Order_Line__c > lstWOLForCompatibleProductCheck, Map < Id, sObject > oldRecords, Set < Id > setProductsIdsSelected, String strTypeCheck, set < String > setTypeCheck) {
        //if (!workOrderIds.isEmpty()) {
            Map < Id, SVMXC__Service_Order__c > idToWorkOrderMap = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(workOrderIds));
            if (!idToWorkOrderMap.isEmpty()) {
                ServiceUtilityCollection.checkCompatibleProductsInFRUList(lstWOLForCompatibleProductCheck, idToWorkOrderMap, oldRecords, 'SVMXC__Service_Order__c', setProductsIdsSelected, setTypeCheck);
            }
        //}
    }
    /*
     *  @AUTHOR:  Sandeep
     *  @DESCRIPTION:DCP-37747  Cancellation logic for Work Order Debrief Lines
     *  @PARAM :  list<SVMXC__service_order_Line__c> lstCanceledWd - list of WDs which are canceled. 
     *  @RETURN:  void
     */
    public static void unCheckIncludeInSRforcanceledWd(list < SVMXC__service_order_Line__c > lstCanceledWd) {
        for (SVMXC__Service_Order_Line__c objWd: lstCanceledWd) {
            if (objWd.Include_in_Service_Report__c) {
                objWd.Include_in_Service_Report__c = false;
            }
        }
        
    }
}
