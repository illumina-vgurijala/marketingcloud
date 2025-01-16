/***************************************************************************************************************************************
* NAME   : FANRecordListController
* DESCRIPTION  :FANRecordListController
*         
*    
* @AUTHOR : Digvijay
* @DATE   : 23-02-2021 
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay            23-02-2021           Initial Version
* Harsh Shukla        11/15/2021           DCP-47394
* Rohan Rathod        07/29/2022           Added Illib 
* Priya Mukherjee	   07/11/2023			CMCM-1021 Adding Locked Fan status logic
  ****************************************************************************************************************************************/ 
  public with sharing class FANRecordListController {
    private static final String LOG_TITLE = 'FANRecordListController';
    public static final set<string> SET_LOCKED_STATUS = new set<string>{'Locked Assessment','Locked Monitoring - no investigation', 'Locked Investigation ongoing', 'Locked Investigation complete - monitoring', 'Locked Open', 'Locked Closed'};//CMCM-1021

/**Method to get wrapper list for UI Table */
    @AuraEnabled
    public static List<DataWrapper> getwrapperList(String recordId){
        ilib_LogEvent.push(LOG_TITLE + '.getwrapperList()');
        ilib_LogEvent.info('recordId: ' + recordId);
        try{
            Map<String, String> mapProductDetails=new Map<String,String>();

            if( recordId.startsWith('500')){
                for(Case caseObj : new CasesSelector().selectCasesByCaseId(recordId)){
                    //PRB0048548- added a null check for product on Case
                    if (caseObj.SVMXC__Product__c != null) { 
                    mapProductDetails.put('productid',caseObj.SVMXC__Product__c);
                    }
                }   
            }else{
                for(SVMXC__Service_Order__c  woObj : new WorkOrdersSelector().selectWorkOrderLstFromStringIds(new Set<String>{recordId})){
                    //PRB0048548- added a null check for product on WorkOrder
                    if (woObj.SVMXC__Product__c != null) {
                    mapProductDetails.put('productid',woObj.SVMXC__Product__c);
                    }
                }    
            }
 
            return getDataWrapperList(mapProductDetails,recordId);
    }catch(Exception ex){
        //get exception message
        ApexExceptions.emit(LOG_TITLE,ex);
        throw new AuraHandledException(ex.getMessage()); 
    }
}
 
/**Method to get wrapper list for UI Table  */
    public static List<DataWrapper> getDataWrapperList(Map<String,String> mapProductDetails,String recordId){
        ilib_LogEvent.push(LOG_TITLE + '.getDataWrapperList()');
        List<DataWrapper> lstDataWrapper=new List<DataWrapper>();
        Set<Id> setFanIds=new Set<Id>(); 
        Set<Id> setWOorCaseIds =new Set<Id>(); 
        string subjectSubString=null;
        setWOorCaseIds.add(recordId);
        if(!String.IsBlank(recordId)){
           List<Field_Action_Item__c> fieldActionItemLst = new FieldActionItemsSelector().selectFieldActionItemsByCaseORWOId(setWOorCaseIds,setWOorCaseIds);            
            for(Field_Action_Item__c obj: fieldActionItemLst){
                setFanIds.add(obj.Field_Action_Notification__c);
            }
        }
        List<Impacted_Products_Serials_Lots__c> lstfieldActionNoti = new ImpactedProductSerialLotsSelector().selectImpactedProductByProductId(mapProductDetails.get('productid'));

                ilib_LogEvent.message('lstfieldActionNoti--' + lstfieldActionNoti);
        if(lstfieldActionNoti!=null && !lstfieldActionNoti.IsEmpty()){
            for(Impacted_Products_Serials_Lots__c obj:lstfieldActionNoti){
                //CMCM-1021 add locked status condition in if statement
                if(!setFanIds.contains(obj.Field_Action_Notification__c) && !SET_LOCKED_STATUS.contains(obj.Field_Action_Notification__r.Status__c)){
                    //Added "obj.Field_Action_Notification__r.Subject__c" as DCP-47394
                    subjectSubString = obj.Field_Action_Notification__r.Subject__c;
                    DataWrapper dataobj=new DataWrapper(obj.Field_Action_Notification__c,obj.Field_Action_Notification__r.Name,subjectSubString,obj.Field_Action_Notification__r.RecordType.Name,obj.Field_Action_Notification__r.Mitigations__c,obj.Product__r.ProductCode,obj.Serial_Number__c,obj.Lot_Number__c,obj.Id,obj.Field_Action_Notification__r.Status__c);
                    lstDataWrapper.add(dataobj);
                    setFanIds.add(obj.Field_Action_Notification__c);
                }
            }
        }

        ilib_LogEvent.message('lstDataWrapper--' + lstDataWrapper);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return lstDataWrapper;
    }
 
/**Wrapper class */
    public class DataWrapper{
        @AuraEnabled
        public  String fanId;
        @AuraEnabled
        public  String fanName;
        @AuraEnabled
        public  String fanSubjectSubString;//DCP-47394
        @AuraEnabled
        public String recordType;
        @AuraEnabled
        public String customermessaging;
        @AuraEnabled
        public String productCode;
        @AuraEnabled
        public String serialNumber;
        @AuraEnabled
        public String lotNumber;
        @AuraEnabled
        public String impactedProductRecId;
		 @AuraEnabled
        public String statusFan; //CMCM-1021

        /**Constructor */
        public DataWrapper(String fanId,String fanName,String fanSubjectSubString,String recordType,String customermessaging,String productCode,String serialNumber,String lotNumber, String impactedProductRecId, String statusFan){
            this.fanId=fanId;
            this.fanName=fanName;
            this.fanSubjectSubString=fanSubjectSubString;//DCP-47394
            this.recordType=recordType;
            this.customermessaging=customermessaging;
            this.productCode=productCode;
            this.serialNumber=serialNumber;
            this.lotNumber=lotNumber;
            this.impactedProductRecId=impactedProductRecId;
            this.statusFan=statusFan; //CMCM-1021
        }
 
    }
}