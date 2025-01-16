/**
 *    @author KD
 *    @date   
 *    @description : Class for creating Estimate WD/
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                  Description
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class BillableCreateEstimateWD implements ilib_AdminOperationLogicInterface{
    public static final String STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE ='Estimate';
    private static final String LOG_TITLE = 'BillableCreateEstimateWD';
    public static Id idEstimateRecordTypeId ;
    public static final String LINE_TYPE_TRAVEL = 'Travel';
    public static final String LINE_TYPE_LABOR = 'Labor';
    public static final String LINE_OF_BUSINESS_MICROARRAY = 'MicroArray';
    public static Map<String,Product2> mapProductCodeToProductObject = new Map<String,Product2>();

     /**
     *  @author       : KD
     *  @description  : Create OQ work details for PM work orders using platform event
     *  @return       : void
     */
    public static void doBusinessLogic(List<Id> lstWOIds){
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            List<SVMXC__Service_Order_Line__c> lstWorkDetails = new List<SVMXC__Service_Order_Line__c>();
            List<SVMXC__Service_Order__c> lstWO = new WorkOrdersSelector().selectWorkOrders(new Set<Id>(lstWOIds));
            if(!lstWO.isEmpty()){
                mapProductCodeToProductObject = (Map<String,Product2>) UtilsCollection.getMapOfStringToSObject(new ProductsSelector().selectProductFromProdCode(new Set<String>{Label.Travel_Product_Code,Label.Labor_SQ_Product_Code,Label.Labor_MA_Product_Code}),'ProductCode',Map<String,Product2>.class);
                idEstimateRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(STRING_WORK_DETAIL_RECORD_TYPE_ESTIMATE).getRecordTypeId();
                for(SVMXC__Service_Order__c objWO : lstWO){
                    if(objWO.Count_of_Estimated_Travel_Lines__c == 0){
                        lstWorkDetails.add(createWorkDetail(objWO,LINE_TYPE_TRAVEL));
                    }
                    if(objWO.Count_of_Estimated_Labor_Lines__c == 0){
                        lstWorkDetails.add(createWorkDetail(objWO,LINE_TYPE_LABOR));
                    }
                }
                if(!lstWorkDetails.isEmpty()){
                    insert lstWorkDetails;
                }
            }
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,e);
        }
        ilib_LogEvent.pop();
		ilib_LogEvent.emit();
    }
    /**
     *  @author       : KD
     *  @description  : Create WD .
     *  @return       : void
     */
    public static SVMXC__Service_Order_Line__c createWorkDetail(SVMXC__Service_Order__c objWO,String strType){
        String strProductCode;
        if(strType == LINE_TYPE_TRAVEL){
            strProductCode = Label.Travel_Product_Code;
        }
        else if(String.isNotBlank(objWO.SVMXC__Component__c) && objWO.SVMXC__Component__r.SVMXC__Product__r.Line_Of_Business__c == LINE_OF_BUSINESS_MICROARRAY){
            strProductCode = Label.Labor_MA_Product_Code;
        }
        else{
            strProductCode = Label.Labor_SQ_Product_Code;
        }
        return new SVMXC__Service_Order_Line__c(
            SVMXC__Service_Order__c = objWO.Id,
            RecordTypeId = idEstimateRecordTypeId,
            SVMXC__Line_Type__c = strType,
            SVMXC__Estimated_Quantity2__c = strType == LINE_TYPE_TRAVEL ? null : 2,
            SVMXC__Product__c = mapProductCodeToProductObject.get(strProductCode).Id);
    }
}