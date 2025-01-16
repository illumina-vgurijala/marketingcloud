/**
*    @author Adyasha Satapathy
*    @date   2021-06-04
*    @description  DCP-38810: Prompt for Requoting based on comparison between estimate and debrief lines
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-06-04           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class PromptReQuoteOnBillableWO 
{
    private static final String LOG_TITLE = 'PromptReQuoteOnBillableWO';
    private static final String MAP_KEY_SEPARATOR = '~';
    private static final Set<String> SET_LABOR_CODES = new Set<String>{Label.Labor_MA_Product_Code,Label.Labor_SQ_Product_Code};
    private static final Set<String> SET_LINE_TYPES_FOR_REQUOTE = new Set<String>{WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_PARTS,WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_MATERIALSCONSUMED};
    private static Id idWorkDetailUsageRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkDetails.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(); 
    private static Id idWorkDetailEstimatesRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkDetails.STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATES).getRecordTypeId();
    
    private static Map<String,SVMXC__Service_Order_Line__c> mapIdToWorkDetailForDebrief;
    private static Map<String,SVMXC__Service_Order_Line__c> mapIdToWorkDetailForEstimate;
    private static Map<Id, Decimal> mapWorkOrderIdToEstimatedQuantity;
    private static Map<Id, Decimal> mapWorkOrderIdToSumLaborHours;
    private static Map<Id,SVMXC__Service_Order__c> mapIdToWorkOrder;
    private static Set<SVMXC__Service_Order_Line__c> setWorkDetailForDebriefLaborLine;
    private static Map<Id, String> mapProductIdToProductCode;
    
    /**
    *   DCP-38810
    *   @description main method to check if re-quoting is required 
    **/
    public static void verifyIfRequotingIsRequiredForWO(List<SVMXC__Service_Order__c> lstWorkOrders)
    {
        ilib_LogEvent.push(LOG_TITLE + '.verifyIfRequotingIsRequiredForWO()');

        mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>(lstWorkOrders);
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new WorkDetailsSelector().selectNonCanceledWorkDetailsForWorkOrderId(mapIdToWorkOrder.keySet());
      
        mapIdToWorkDetailForDebrief = new Map<String, SVMXC__Service_Order_Line__c>();
        mapIdToWorkDetailForEstimate = new Map<String, SVMXC__Service_Order_Line__c>();
        mapWorkOrderIdToEstimatedQuantity = new Map<Id, Decimal>();
        mapWorkOrderIdToSumLaborHours = new Map<Id, Decimal>();
        setWorkDetailForDebriefLaborLine = new Set<SVMXC__Service_Order_Line__c>();
        mapProductIdToProductCode = new Map<Id, String>();
        
        if(lstWorkDetails.isEmpty()){
            ilib_LogEvent.message('No Work Details are present on the WorkOrder');
            ilib_LogEvent.pop();
            return;
        }
        Map<Id, List<SVMXC__Service_Order_Line__c>> mapWorkOrderIdToListWorkDetails = (Map<Id, List<SVMXC__Service_Order_Line__c>>) UtilsCollection.getMapOfIdToSObjects(lstWorkDetails,WorkOrders.STRING_WORK_ORDER_API_NAME);
        
        prepareMapsForEstimateAndDetailUsageWDs(mapWorkOrderIdToListWorkDetails);
        
        if(!mapIdToWorkDetailForEstimate.isEmpty() && mapIdToWorkDetailForDebrief.isEmpty() && setWorkDetailForDebriefLaborLine.isEmpty())
        {
            ilib_LogEvent.message('No Debrief Lines are pesent on the WorkOrder');
            ilib_LogEvent.pop();
            return;
        }
        checkForChangesInEstimatesAndDebriefLines(mapWorkOrderIdToListWorkDetails);
        ilib_LogEvent.pop();
        
    }

    /**
    *   DCP-38810
    *   @desc prepare maps for storing estimate and debrief work details based on certain conditions 
    **/
    private static void prepareMapsForEstimateAndDetailUsageWDs(Map<Id, List<SVMXC__Service_Order_Line__c>> mapWorkOrderIdToListWorkDetails)
    {
        ilib_LogEvent.push(LOG_TITLE + '.prepareMapsForEstimateAndDetailUsageWDs()');
        for(Id workOrderId : mapWorkOrderIdToListWorkDetails.keySet())
        {
            Decimal sumLaborHours = 0;
            Decimal decEstimatedQuantity = null;
            for(SVMXC__Service_Order_Line__c objWorkDetail : mapWorkOrderIdToListWorkDetails.get(workOrderId))
            {
                String strKey = workOrderId + MAP_KEY_SEPARATOR + objWorkDetail.SVMXC__Product__c;
                if(objWorkDetail.SVMXC__Line_Status__c == WorkDetails.STRING_WORK_DETAIL_LINE_STATUS_CANCELED) {continue;}
                if(objWorkDetail.RecordTypeId == idWorkDetailEstimatesRecordTypeId && String.isNotBlank(objWorkDetail.SVMXC__Product__c)){
                    
                    mapIdToWorkDetailForEstimate.put(strKey, objWorkDetail);
                    mapProductIdToProductCode.put(objWorkDetail.SVMXC__Product__c, objWorkDetail.SVMXC__Product__r.ProductCode);
                    
                    if(mapIdToWorkDetailForEstimate.containsKey(strKey) && mapProductIdToProductCode.containsKey(objWorkDetail.SVMXC__Product__c) && SET_LABOR_CODES.contains(mapProductIdToProductCode.get(objWorkDetail.SVMXC__Product__c))){
                        decEstimatedQuantity = mapIdToWorkDetailForEstimate.get(strKey).SVMXC__Estimated_Quantity2__c;
                    }
                } 
                
                else if(objWorkDetail.RecordTypeId == idWorkDetailUsageRecordTypeId && objWorkDetail.SVMXC__Is_Billable__c){
                    if(objWorkDetail.SVMXC__Line_Type__c != WorkDetails.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR && String.isNotBlank(objWorkDetail.SVMXC__Product__c)){
                        mapIdToWorkDetailForDebrief.put(strKey, objWorkDetail);
                    }
                    else{
                        Decimal decLaborHours = convertLaborHoursToNumber(objWorkDetail);
                        sumLaborHours += decLaborHours;
                        setWorkDetailForDebriefLaborLine.add(objWorkDetail);
                    }
                }             
            }
            ilib_LogEvent.message('sum of labor hours for work order: '+workOrderId+' : '+sumLaborHours);
            ilib_LogEvent.message('estimated quantity for work order: '+workOrderId+' : '+decEstimatedQuantity);
            mapWorkOrderIdToSumLaborHours.put(workOrderId, sumLaborHours);
            mapWorkOrderIdToEstimatedQuantity.put(workOrderId,decEstimatedQuantity);
        }

    }

    /**
    *   DCP-38810
    *   @desc throw error for work order/ work detail based on conditions 
    **/
    private static void checkForChangesInEstimatesAndDebriefLines(Map<Id, List<SVMXC__Service_Order_Line__c>> mapWorkOrderIdToListWorkDetails)
    {   
        ilib_LogEvent.push(LOG_TITLE + '.checkForChangesInEstimatesAndDebriefLines()');
        
        List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
        
        for(List<SVMXC__Service_Order_Line__c> lstWorkDetailsFromMap : mapWorkOrderIdToListWorkDetails.values())
        {
            lstWorkDetails.addAll(lstWorkDetailsFromMap);
        }
        
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstWorkDetails)
        {
            Boolean boolReQuotingCriteriaSatisfied = false;
            ilib_LogEvent.message('@@@@ objWorkDetail.SVMXC__Product__c: '+objWorkDetail.SVMXC__Product__c);
            String strKey = objWorkDetail.SVMXC__Service_Order__c + MAP_KEY_SEPARATOR + objWorkDetail.SVMXC__Product__c;
            if(checkWorkDetailSatifiesLineType(mapIdToWorkDetailForDebrief, objWorkDetail))
            {
                if(mapIdToWorkDetailForEstimate.containsKey(strKey))
                {
                    if(mapIdToWorkDetailForEstimate.get(strKey).SVMXC__Estimated_Quantity2__c < mapIdToWorkDetailForDebrief.get(strKey).SVMXC__Actual_Quantity2__c)
                    {
                        boolReQuotingCriteriaSatisfied = true;
                        ilib_LogEvent.message('Quantity of Debrief Lines Exceed Quantity of Estimate Lines');
                    }
                }
                else 
                {
                    boolReQuotingCriteriaSatisfied = true;
                    ilib_LogEvent.message('Debrief Lines Product do not match Estimate Lines');
                }
            }
            if(mapWorkOrderIdToEstimatedQuantity.get(objWorkDetail.SVMXC__Service_Order__c) != null && mapWorkOrderIdToSumLaborHours.get(objWorkDetail.SVMXC__Service_Order__c) != null && mapWorkOrderIdToEstimatedQuantity.get(objWorkDetail.SVMXC__Service_Order__c) < mapWorkOrderIdToSumLaborHours.get(objWorkDetail.SVMXC__Service_Order__c))
            {
                boolReQuotingCriteriaSatisfied = true;
                ilib_LogEvent.message('Sum of labor hours is greater than estimated quantity');
            }
            
            ilib_LogEvent.message('@@@ inside checkForChangesInEstimatesAndDebriefLines, boolReQuotingCriteriaSatisfied: '+boolReQuotingCriteriaSatisfied);
            
            if(boolReQuotingCriteriaSatisfied && mapIdToWorkOrder.containsKey(objWorkDetail.SVMXC__Service_Order__c))
            {
                mapIdToWorkOrder.get(objWorkDetail.SVMXC__Service_Order__c).addError(Label.PromptReQuotingErrorMessageOnWorkOrderWorkDetail);
            }
        }
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38810
    *   @description checks if work detail satisfies specific line type conditions 
    **/
    private static Boolean checkWorkDetailSatifiesLineType(Map<String,SVMXC__Service_Order_Line__c> mapIdToWorkDetailForDebrief, SVMXC__Service_Order_Line__c objWorkDetail)
    {
        ilib_LogEvent.push(LOG_TITLE + '.checkWorkDetailSatifiesLineType()');

        Boolean boolCriteriaSatisfied = false;
        String strKey = objWorkDetail.SVMXC__Service_Order__c + MAP_KEY_SEPARATOR + objWorkDetail.SVMXC__Product__c;
        if(String.isNotBlank(objWorkDetail.SVMXC__Product__c) && mapIdToWorkDetailForDebrief.containsKey(strKey) && SET_LINE_TYPES_FOR_REQUOTE.contains(mapIdToWorkDetailForDebrief.get(strKey).SVMXC__Line_Type__c))
        {
            boolCriteriaSatisfied = true;
        }
        ilib_LogEvent.message('@@@ boolCriteriaSatisfied: '+boolCriteriaSatisfied);
        ilib_LogEvent.pop();
        return boolCriteriaSatisfied;
    }

    /**
    *   DCP-38810
    *   @description returns a calculated decimal of labour hours for a specific work detail
    **/
    private static Decimal convertLaborHoursToNumber(SVMXC__Service_Order_Line__c objWorkDetail)
    {
        ilib_LogEvent.push(LOG_TITLE + '.convertLaborHoursToNumber()');

        String delimiter = ':';
        String input = objWorkDetail.Labor_Hours__c;
        if(String.isBlank(input)) 
        {
            ilib_LogEvent.pop();
            return 0;
        }
    
        if(!input.contains(delimiter))
        {
            ilib_LogEvent.pop();
            return Decimal.valueOf(input);
        }  

        Decimal decHours = Decimal.valueof(input.substringBefore(delimiter).trim());
        Decimal decMinutes = Decimal.valueof(input.substringAfter(delimiter).trim());

        Decimal laborTime = decHours + (decMinutes/60);
        ilib_LogEvent.message('laborTime' +laborTime);
        ilib_LogEvent.pop();
        return laborTime.setScale(2);
    }

}