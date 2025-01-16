/*****************************************************************************************************************
 * Class Name: VerifySerializedParts_WorkDetailHelper
 * 
 * Description: Helper class for Parts Reservation functionality.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for parts Reservation functionality.
 * 
 ******************************************************************************************************************/
public with sharing class VerifySerializedParts_WorkDetailHelper {
    // DCP-33467
    public static final String PRODUCT_CODE = 'Product Code:';
    public static final String SERIAL = ', Serial:';
    public static final String BATCH = ', Batch:';
    /*
     *  @AUTHOR:  Sravan
     *  @DESCRIPTION: 33467 - Verify serialized parts whether it has error
     */
    public static set < SVMXC__Service_Order_Line__c > verifySerializedParts(set < SVMXC__Service_Order_Line__c > setWorkDetailsParts, Set < Id > setStockSerialId, Map < Id, String > mapStockSerialNumbers) {
        Set < SVMXC__Service_Order_Line__c > setWDs = new Set < SVMXC__Service_Order_Line__c > ();
        Map < Id, set < string >> mapAlsWorkOrderNumber = new Map < Id, set < string >> ();
        String batchNumberDisplay = '';
        String serialNumberDisplay = '';
        
        // Find if the given serial was already used then through error
        if (!setWorkDetailsParts.isEmpty()) {
            mapAlsWorkOrderNumber = prepareAllocatedStockMap(setStockSerialId);
            for (SVMXC__Service_Order_Line__c objWorkDetail: setWorkDetailsParts) {
                if (mapAlsWorkOrderNumber.containsKey(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c)) {
                    Workdetails.setWorkOrderNumber.addAll(mapAlsWorkOrderNumber.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c));
                    setWDs.add(objWorkDetail);
                    batchNumberDisplay = objWorkDetail.Batch_Number__c != null ? objWorkDetail.Batch_Number__c : '';
                    serialNumberDisplay = mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) != null ? mapStockSerialNumbers.get(objWorkDetail.SVMX_PS_VS_Consumed_Stocked_Serial__c) : '';
                    workdetails.setWDErrors.add(PRODUCT_CODE + objWorkDetail.Product_Code__c + SERIAL + serialNumberDisplay + BATCH + batchNumberDisplay + '\n');
                }
            }
        }
        return setWDs;
    } // DCP-33467
    /**
     * Method:prepareAllocatedStockMap
     */
    public static Map < Id, set < string >> prepareAllocatedStockMap(Set < Id > setStockSerialId){
        Map < Id, set < string >> mapAlsWorkOrderNumber = new Map < Id, set < string >> ();
        // Prepare Allocated Stock Map for each Serial and get WOs list it was used
        if (!setStockSerialId.isEmpty()) {
            for (SVMXC__Allocated_Stock__c als: new AllocatedStocksSelector().selectAllocatedStocksByStockSerialIds(setStockSerialId)) {
                if (mapAlsWorkOrderNumber.containsKey(als.SVMX_PS_VS_Stocked_Serial__c)) {
                    mapAlsWorkOrderNumber.get(als.SVMX_PS_VS_Stocked_Serial__c).add(als.Work_Order__r.Name);
                } else {
                    mapAlsWorkOrderNumber.put(als.SVMX_PS_VS_Stocked_Serial__c, new set < string > {
                        als.Work_Order__r.Name
                    });
                }
            }
        }
        return mapAlsWorkOrderNumber;
    }
}
