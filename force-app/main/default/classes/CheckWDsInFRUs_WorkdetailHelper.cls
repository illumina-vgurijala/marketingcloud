/*****************************************************************************************************************
 * Class Name: CheckWDsInFRUs_WorkdetailHelper
 * Description: Helper class for checking if the work details are selected in FRUs.
 * 
 * Author: Prashanth
 * 
 * Date: 07-Dec-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  07-12-2021                       Helper class for checking if the work details are selected in FRUs
 ******************************************************************************************************************/
public with sharing class CheckWDsInFRUs_WorkdetailHelper {
    public static set < String > setTypeCheck = new set < String > ();
    public static Set < Id > setCombinedWorkOrderIds = new Set < Id > ();
    public static List < SVMXC__Service_Order_Line__c > lstCombineWOLForFRUCheck = new List < SVMXC__Service_Order_Line__c > ();
    public static Set < Id > setCombinedProductsIdsSelected = new Set < Id > ();
    public static set < Id > setToolsWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for tools
    public static Set < Id > setProductsIdsSelected = new Set < Id > (); //Set of product ids which have been selected in the work detail record.
    public static set < Id > setMaterialsConsumedWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for materials consumed
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatibleToolCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for tools
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatiblePartCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for tools
    public static List < SVMXC__Service_Order_Line__c > lstWOLForCompatibleMaterialsConsumedCheck = new List < SVMXC__Service_Order_Line__c > (); //List of work details created for materials consumed
    public static set < Id > setPartsWorkOrderIds = new set < id > (); //Set of work orders associated with work details created for parts
    public static final String STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS = 'Tool';
    /*
    *  method: checkIfSelectedInFRU
    *  @author - Prashanth
    *  @Description : check the work details if they are selected in FRU.
    * 
    */
    public static void checkIfSelectedInFRU(Map<Id, SObject> oldRecords, List<sObject> records){
        for(SVMXC__Service_Order_Line__c objWorkDetail: (List < SVMXC__Service_Order_Line__c > ) records){
            SVMXC__Service_Order_Line__c objOldWorkOrderLine = (SVMXC__Service_Order_Line__c)(oldRecords.get(objWorkDetail.Id));
            getTools(objWorkDetail, objOldWorkOrderLine);
            getMaterialsConsumed(objWorkDetail, objOldWorkOrderLine);

            // Check if the Parts selected is in FRU list
            if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS &&
                objWorkDetail.RecordTypeId == BeforeUpdate_WorkdetailHelper.idWorkDetailUsageRecordTypeId &&
                objWorkDetail.SVMXC__Service_Order__c != null && objWorkDetail.SVMXC__Product__c != null &&
                objWorkDetail.SVMXC__Product__c != objOldWorkOrderLine.SVMXC__Product__c &&
                objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
                setPartsWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
                setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);
                setProductsIdsSelected.add(objOldWorkOrderLine.SVMXC__Product__c);

                //DCP-37747 - Bypass canceled WD's
                if (objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                    lstWOLForCompatiblePartCheck.add(objWorkDetail);
                }

            }
            if (!String.IsBlank(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c) && !Workdetails.mapIdToIP.IsEmpty() && Workdetails.mapIdToIP.containsKey(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c)) {
                objWorkDetail.SVMX_PS_VS_Return_Serial_Number__c = Workdetails.mapIdToIP.get(objWorkDetail.SVMX_PS_VS_Return_Installed_Product__c).SVMXC__Serial_Lot_Number__c;
    
            }
        }  
        //To check the Product is listed in the FRU list of Product of Work Order
        if (!setToolsWorkOrderIds.isEmpty() && !lstWOLForCompatibleToolCheck.isEmpty() && !setProductsIdsSelected.isEmpty()) {
            //DCP-33873(populate lst/Set for FRU Check)
            setCombinedWorkOrderIds.addAll(setToolsWorkOrderIds);
            lstCombineWOLForFRUCheck.addAll(lstWOLForCompatibleToolCheck);
            setCombinedProductsIdsSelected.addAll(setProductsIdsSelected);
            setTypeCheck.add('Tool');
        }
        processMaterialsConsumed();
        checkProductinRFU(oldRecords);
        
    }
    /*
    *  method: getTools
    *  @author - Prashanth
    *  @Description : check the work details if they are selected in FRU.
    * 
    */
    public static void getTools(SVMXC__Service_Order_Line__c objWorkDetail,SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        // Check if the Tools selected is in FRU list
        if (objWorkDetail.SVMXC__Line_Type__c == STRING_WORK_DETAIL_LINE_TYPE_IS_TOOLS &&
            objWorkDetail.RecordTypeId == BeforeUpdate_WorkdetailHelper.idWorkDetailUsageRecordTypeId &&
            objWorkDetail.SVMXC__Service_Order__c != null && objWorkDetail.SVMXC__Product__c != null &&
            objWorkDetail.SVMXC__Product__c != objOldWorkOrderLine.SVMXC__Product__c &&
            objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setToolsWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);
            setProductsIdsSelected.add(objOldWorkOrderLine.SVMXC__Product__c);

            //DCP-37747 - Bypass canceled WD's
            if (objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                lstWOLForCompatibleToolCheck.add(objWorkDetail);
            }

        }
    }
    /*
    *  method: getMaterialsConsumed
    *  @author - Prashanth
    *  @Description : check the work details if they are selected in FRU.
    * 
    */
    public static void getMaterialsConsumed(SVMXC__Service_Order_Line__c objWorkDetail,SVMXC__Service_Order_Line__c objOldWorkOrderLine){
        // Check if the Materials Consumed selected is in FRU list
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED &&
            objWorkDetail.RecordTypeId == BeforeUpdate_WorkdetailHelper.idWorkDetailUsageRecordTypeId &&
            objWorkDetail.SVMXC__Service_Order__c != null && objWorkDetail.SVMXC__Product__c != null &&
            objWorkDetail.SVMXC__Product__c != objOldWorkOrderLine.SVMXC__Product__c &&
            objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {
            setMaterialsConsumedWorkOrderIds.add(objWorkDetail.SVMXC__Service_Order__c);
            setProductsIdsSelected.add(objWorkDetail.SVMXC__Product__c);
            setProductsIdsSelected.add(objOldWorkOrderLine.SVMXC__Product__c);

            //DCP-37747 - Bypass canceled WD's
            if (objWorkDetail.SVMXC__Line_Status__c != Workdetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED){
                lstWOLForCompatibleMaterialsConsumedCheck.add(objWorkDetail);
            }

        }
    }
    /*
    *  method: processMaterialsConsumed
    *  @author - Prashanth
    *  @Description : process materials consumed
    * 
    */
    public static void processMaterialsConsumed(){
        
        //To check the Product is listed in the FRU list of Product of Work Order
        if (!setMaterialsConsumedWorkOrderIds.isEmpty()) {
            set < id > setSpareProductIds = new set < id > ();
            List < Product2 > lstProduct = new List<Product2>();
            if (setProductsIdsSelected.size() > 0) {
                lstProduct = new ProductsSelector().selectProductsWithServiceProductType(setProductsIdsSelected, 'spare');
            }
            If(lstProduct != null && !lstProduct.isEmpty()) {
                For(Product2 objProduct: lstProduct) {
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

        //To check the Product is listed in the FRU list of Product of Work Order
        if (!setPartsWorkOrderIds.isEmpty() && !lstWOLForCompatiblePartCheck.isEmpty() && !setProductsIdsSelected.isEmpty()) {
            //DCP-33873(populate lst/Set for FRU Check)
            setCombinedWorkOrderIds.addAll(setPartsWorkOrderIds);
            lstCombineWOLForFRUCheck.addAll(lstWOLForCompatiblePartCheck);
            setCombinedProductsIdsSelected.addAll(setProductsIdsSelected);
            setTypeCheck.add('Part');
        }
    }
     /*
    *  method: checkProductinRFU
    *  @author - Prashanth
    *  @Description : process materials consumed
    * 
    */
    public static void checkProductinRFU(Map<Id, sObject> oldRecords){
        //DCP-33873(call method for FRU Check)
        if (!setCombinedWorkOrderIds.isEmpty() && !lstCombineWOLForFRUCheck.isEmpty() && !setCombinedProductsIdsSelected.isEmpty()) {
            ProcessWDBeforeInsert_WorkDetailHelper.checkProductinFRUList(setCombinedWorkOrderIds, lstCombineWOLForFRUCheck, oldRecords, setCombinedProductsIdsSelected, 'Part', setTypeCheck);

        }
    }
}
