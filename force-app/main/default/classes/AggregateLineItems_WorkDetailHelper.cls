/*****************************************************************************************************************
 * Class Name: AggregateLineItems_WorkDetailHelper
 * 
 * Description: Helper class for AggregateLinetems functionality.
 * 
 * Author: Prashanth
 * 
 * Date: 29-Nov-2021
 * 
 * Notification Log:
 * -------------------------------------------------------------------------------------------------------------
 * Developer                  Date                              Description
 * -------------------------------------------------------------------------------------------------------------
 * Prashanth                  29-11-2021                       Helper class for Aggregating lineitems functionality.
 * 
 ******************************************************************************************************************/
public with sharing class AggregateLineItems_WorkDetailHelper {
    /**
     * Description: Wrapper class for storing the quantity information. 
     */
    public class WorkDetailLineQuantityWrapper {
        public Id idWorkOrder;
        public Map < Id, Decimal > estimateProductIdToQuantity;
        public Map < String, Decimal > estimateActivityTypeToQuantity;
        public Map < Id, Decimal > debriefProductIdToQuantity;
        public Map < String, Decimal > debriefActivityTypeToQuantity;
        /**
         * Desricption: Constructor for the wrapper class
         */
        public WorkDetailLineQuantityWrapper(Id idWorkOrder) {
            this.idWorkOrder = idWorkOrder;
            estimateProductIdToQuantity = new Map < Id, Decimal > ();
            estimateActivityTypeToQuantity = new Map < String, Decimal > ();
            debriefProductIdToQuantity = new Map < Id, Decimal > ();
            debriefActivityTypeToQuantity = new Map < String, Decimal > ();
        }
    }
    /**
     * Method: aggregateLineItems
     * Description: Method to aggregate the quantity of work order lines for a work order.
     */
    public static void aggregateLineItems(List<SVMXC__Service_Order_Line__c> lstWorkDetails, Map<Id, WorkDetailLineQuantityWrapper> workOrderIdToQuantityWrapper){
        Map < Id, SVMXC__Service_Order_Line__c > mapProductIdToWorkDetails = new Map < Id, SVMXC__Service_Order_Line__c > ();
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetails){
            //If Estimates Work Detail Line is created :
            // Check for corresponsing Debrief lines for any mismatch
            //This scenario would come when the Estimates are performed post Debrief.
            if (objWorkDetail.RecordTypeId == Workdetails.idWorkDetailEstimatesRecordTypeId) {
                //DCP-45873
                if (String.isNotBlank(objWorkDetail.SVMXC__Product__c)) {
                    mapProductIdToWorkDetails.put(objWorkDetail.SVMXC__Product__c, objWorkDetail);
                }
                aggregateEstimateLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
            }
            //If Usage/Consumption Work Detail Line is created :
            // Check for corresponsing Estimate lines for any mismatch
            if (objWorkDetail.RecordTypeId == Workdetails.idWorkDetailUsageRecordTypeId && (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS || (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && (objWorkDetail.SVMXC__Activity_Type__c != Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_FIELD_COMPLIANCE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_CUSTOMER_SERVICE_REVIEW && objWorkDetail.SVMXC__Activity_Type__c != Workdetails.STRING_WORK_DETAIL_ACTIVITY_TYPE_QS_REVIEW)))) {
                //DCP-25289 condition updated
                aggregateDebriefLineItems(workOrderIdToQuantityWrapper, objWorkDetail);
            }
            
        }
        //DCP-45873
        if (!mapProductIdToWorkDetails.isEmpty()) {
            //Update Estimate Line
            updateEstimateLineType(mapProductIdToWorkDetails);
        }
    }
    /*
     *  @AUTHOR:  Ritika Maheshwari
     *  @DESCRIPTION: Method to be aggregate the Quantity of all the estimate line items asscoaited with a work order
     *  @PARAM :  Map<Id,WorkDetailLineQuantityWrapper> - Map of Work Order versus a wrapper which would store quantity details
     *  @RETURN:  void
     */
    public static void aggregateEstimateLineItems(Map < Id, WorkDetailLineQuantityWrapper > workOrderIdToEstimateQuantityWrapper, SVMXC__Service_Order_Line__c objWorkDetail) {
        if (!workOrderIdToEstimateQuantityWrapper.containsKey(objWorkDetail.SVMXC__Service_Order__c)) {
            workOrderIdToEstimateQuantityWrapper.put(objWorkDetail.SVMXC__Service_Order__c, new WorkDetailLineQuantityWrapper(objWorkDetail.SVMXC__Service_Order__c));
        }

        WorkDetailLineQuantityWrapper objEstimateLineWrapper = workOrderIdToEstimateQuantityWrapper.get(objWorkDetail.SVMXC__Service_Order__c);
        //If product is not null, update the quantity and set it in an agregated map
        if (objWorkDetail.SVMXC__Product__c != null) {
            if (objEstimateLineWrapper.estimateProductIdToQuantity.containskey(objWorkDetail.SVMXC__Product__c)) {
                Decimal estimateQuantity = objEstimateLineWrapper.estimateProductIdToQuantity.get(objWorkDetail.SVMXC__Product__c);
                objEstimateLineWrapper.estimateProductIdToQuantity.put(objWorkDetail.SVMXC__Product__c, estimateQuantity + objWorkDetail.SVMXC__Estimated_Quantity2__c);
            } else {
                objEstimateLineWrapper.estimateProductIdToQuantity.put(objWorkDetail.SVMXC__Product__c, objWorkDetail.SVMXC__Estimated_Quantity2__c);
            }
        }
        //If activity is not null, update the quantity and set it in an agregated map
        if (objWorkDetail.SVMXC__Activity_Type__c != null && objWorkDetail.SVMXC__Estimated_Quantity2__c  != null ) {
            Decimal enteredQuantity = objWorkDetail.SVMXC__Estimated_Quantity2__c * 60;
            if (objEstimateLineWrapper.estimateActivityTypeToQuantity.containskey(objWorkDetail.SVMXC__Activity_Type__c)) {
                Decimal estimateQuantity = objEstimateLineWrapper.estimateActivityTypeToQuantity.get(objWorkDetail.SVMXC__Activity_Type__c);
                objEstimateLineWrapper.estimateActivityTypeToQuantity.put(objWorkDetail.SVMXC__Activity_Type__c, estimateQuantity + enteredQuantity);
            } else {
                objEstimateLineWrapper.estimateActivityTypeToQuantity.put(objWorkDetail.SVMXC__Activity_Type__c, enteredQuantity);
            }
        }
    }
    /*
     *  @AUTHOR:  Ritika Maheshwari
     *  @DESCRIPTION: Method to be aggregate the Quantity of all the debrief line items asscoaited with a work order
     *  @PARAM :  Map<Id,WorkDetailLineQuantityWrapper>  - Map of Work Order versus a wrapper which would store quantity details
     *  @RETURN:  void
     */
    public static void aggregateDebriefLineItems(Map < Id, WorkDetailLineQuantityWrapper > workOrderIdToDebriefQuantityWrapper, SVMXC__Service_Order_Line__c objWorkDetail) {
        if (!workOrderIdToDebriefQuantityWrapper.containsKey(objWorkDetail.SVMXC__Service_Order__c)) {
            workOrderIdToDebriefQuantityWrapper.put(objWorkDetail.SVMXC__Service_Order__c, new WorkDetailLineQuantityWrapper(objWorkDetail.SVMXC__Service_Order__c));
        }
        WorkDetailLineQuantityWrapper objDebriefQuantityWrapper = workOrderIdToDebriefQuantityWrapper.get(objWorkDetail.SVMXC__Service_Order__c);
        aggregateLineItemsForPartsSwap(objDebriefQuantityWrapper, objWorkDetail);
        //If activity is not null, update the quantity and set it in an agregated map
        if (objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && objWorkDetail.SVMXC__Activity_Type__c != null &&
            objWorkDetail.Duration_in_hours__c != null && objWorkDetail.SVMXC__Is_Billable__c) {
            Decimal enteredQuantity = 0;
            if (objWorkDetail.Duration_in_hours__c.contains(':')) {
                enteredQuantity = (Integer.valueOf(objWorkDetail.Duration_in_hours__c.split(':')[0]) * 60) + (Integer.valueOf(objWorkDetail.Duration_in_hours__c.split(':')[1]));
            } else {
                enteredQuantity = (Integer.valueOf(objWorkDetail.Duration_in_hours__c) * 60);
            }
            if (objDebriefQuantityWrapper.debriefActivityTypeToQuantity.containskey(objWorkDetail.SVMXC__Activity_Type__c)) {
                Decimal debriefQuantity = objDebriefQuantityWrapper.debriefActivityTypeToQuantity.get(objWorkDetail.SVMXC__Activity_Type__c);
                objDebriefQuantityWrapper.debriefActivityTypeToQuantity.put(objWorkDetail.SVMXC__Activity_Type__c, debriefQuantity + enteredQuantity);
            } else {
                objDebriefQuantityWrapper.debriefActivityTypeToQuantity.put(objWorkDetail.SVMXC__Activity_Type__c, enteredQuantity);
            }
        }
    }
    /**
     * Method: aggregateLineItemsForPartsSwap
     * Description: To aggregate the parts lines
     * return: void
     */
    public static void aggregateLineItemsForPartsSwap(WorkDetailLineQuantityWrapper objDebriefQuantityWrapper, SVMXC__Service_Order_Line__c objWorkDetail){
        //If product is not null, update the quantity and set it in an agregated map
        if ((objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED || objWorkDetail.SVMXC__Line_Type__c == Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS) &&
            objWorkDetail.SVMXC__Product__c != null && objWorkDetail.SVMXC__Is_Billable__c) {
            if (objDebriefQuantityWrapper.debriefProductIdToQuantity.containskey(objWorkDetail.SVMXC__Product__c)) {
                Decimal debriefQuantity = objDebriefQuantityWrapper.debriefProductIdToQuantity.get(objWorkDetail.SVMXC__Product__c);
                if (objWorkDetail.SVMXC__Actual_Quantity2__c != null) {
                    objDebriefQuantityWrapper.debriefProductIdToQuantity.put(objWorkDetail.SVMXC__Product__c, debriefQuantity + objWorkDetail.SVMXC__Actual_Quantity2__c);
                }
            } else {
                objDebriefQuantityWrapper.debriefProductIdToQuantity.put(objWorkDetail.SVMXC__Product__c, objWorkDetail.SVMXC__Actual_Quantity2__c);
            }
        }
    }
    /**
     *  @author KD
     *  @description - Update Line type on estimate Lines
     **/
    public static void updateEstimateLineType(Map < Id, SVMXC__Service_Order_Line__c > mapProductIdToWorkDetails) {
        List < Code_Parameter__mdt > lstCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set < String > {
            Workdetails.CODE_PARAMETER_LABOUR_CODE,
            Workdetails.CODE_PARAMETER_TRAVEL_CODE
        });
        Map < String, Code_Parameter__mdt > mapNameToCodeParameter = (Map < String, Code_Parameter__mdt > ) UtilsCollection.getMapOfStringToSObject(lstCodeParam, 'DeveloperName', Map < String, Code_Parameter__mdt > .class);
        Map < Id, Product2 > mapIdToProduct = new Map < Id, Product2 > (new ProductsSelector().selectProducts(mapProductIdToWorkDetails.keySet()));
        for (Id objProductId: mapProductIdToWorkDetails.keySet()) {
            if (mapNameToCodeParameter.get(Workdetails.CODE_PARAMETER_LABOUR_CODE).Value__c.contains(mapIdToProduct.get(objProductId).ProductCode)) {
                //DCP-45928
                if (mapProductIdToWorkDetails.get(objProductId).SVMXC__Estimated_Quantity2__c < Integer.valueOf(Label.BillableLabourQtyCount) || mapProductIdToWorkDetails.get(objProductId).SVMXC__Estimated_Quantity2__c == null){
                    mapProductIdToWorkDetails.get(objProductId).addError(System.Label.ERROR_LABOR_QNTY_2_NEEDED);
                }    
                mapProductIdToWorkDetails.get(objProductId).SVMXC__Line_Type__c = Workdetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR;
            } else if (mapNameToCodeParameter.get(Workdetails.CODE_PARAMETER_TRAVEL_CODE).Value__c.contains(mapIdToProduct.get(objProductId).ProductCode)) {
                mapProductIdToWorkDetails.get(objProductId).SVMXC__Line_Type__c = 'Travel';
            } else {
                mapProductIdToWorkDetails.get(objProductId).SVMXC__Line_Type__c = '';
            }
        }
    }
}
