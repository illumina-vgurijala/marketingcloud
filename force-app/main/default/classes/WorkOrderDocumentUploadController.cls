/**
*    @author: Pankaj Singla
*    @date:   10-Dec-2020
*    @description:  Controller Class for WorkOrderDocumentUpload Component
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer           Date                  Description
*         Pankaj Singla       10-Dec-2020           Initial build
*         Pooja Shalwadi      06-Dec-2021           DCP-49644: POC Story: Added logic for DCP-49644 to return work order activity rule where the Repair protocol contains a value.
*         Shivani Jain        20-12-2022            DCP-58614: Modified query to run properly for Repair Protocols
*/
public without sharing class WorkOrderDocumentUploadController {
    public static final String STRING_CHANNEL_PARTNER_SALES_AND_SERVICE = 'Channel Partner Sales and Service';
    public static final String STRING_CHANNEL_PARTNER_SERVICE = 'Channel Partner Service';
    public static final String STRING_FIELD_SERVICE = 'Field Service';
    public static final String STRING_REPAIR_TROUBLESHOTTING = 'Repair/Troubleshooting';
    public static final String STRING_FIELD_SERVICE_THIRD_PARTY = 'Field Service Third Party';
    public static final String STRING_RP_NOT_APPLICABLE= 'Not applicable for this instrument';
    public static final String STRING_FIELD_COMPLIANCE = 'Field Compliance';
    public static final String STRING_COMMERCIAL_REVENUE_OPS = 'Commercial and Revenue Operations';
    public static final String STRING_QUALITY_ASSURANCE = 'Quality Assurance';
    //TASK0926292
    public static final String STRING_CUSTOMER_SERVICE = 'Customer Service';
    public static final String STRING_TECHNICAL_SUPPORT = 'Technical Support';
    /*


          *  @AUTHOR:  
          *  @DESCRIPTION: getInstalledProductId
          */ //Dummy commit
    @AuraEnabled(cacheable=true)
    public static String getInstalledProductId(String recordId){
        try{
        system.debug('record is-'+recordId);
        String strProductId='';
        SVMXC__Service_Order__c objWorkOrder=[select id,SVMXC__Component__c,SVMXC__Product__c,Installed_Product_Group__c from SVMXC__Service_Order__c
                                              where id=:recordId];
        if(objWorkOrder!=null && objWorkOrder.SVMXC__Component__c!=null){
            strProductId=objWorkOrder.SVMXC__Component__c;
        }
        return strProductId;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
          *  @AUTHOR:  
          *  @DESCRIPTION: initRecord
          */
    @AuraEnabled
    public static DataWrapperList initRecord(String recordId){
        //recordId='';
        try{
        system.debug('record is-'+recordId);
        List<DataWrapper> lstWrapper=new List<DataWrapper>();
        List<DataWrapper> lstWrapperforuploadedfiles=new List<DataWrapper>();
        Set<String> setActivityTypes=new Set<String>();
        Set<Id> setContentDocumentLinkIds=new Set<Id>();
        Set<String> setDocumentNames=new Set<string>();
        Map<String,List<ContentVersion>> mapdocumentTypetoVersion=new Map<String,List<ContentVersion>>();
        List<SVMXC__Service_Order__c> lstWorkOrder= new WorkOrdersSelector().selectWorkOrders(new Set<Id>{recordId});
        List<SVMXC__Service_Order_Line__c> lstLineType= new WorkDetailsSelector().selectLaborWorkDetailRecords(new Set<Id>{recordId});
														
        
         for(SVMXC__Service_Order_Line__c objLineType:lstLineType){
            setActivityTypes.add(objLineType.SVMXC__Activity_Type__c);
         }

            //Start NEW: DCP:49644: Need to add  one cond(Activity Type= 'Repair Protocol')
            String productCode=lstWorkOrder[0].SVMXC__Product__c;
            String productGroup=lstWorkOrder[0].SVMXC__Product__r.Product_Group__c;
            List<Work_Order_Activity_Rules__c> lstActivityRules = new List<Work_Order_Activity_Rules__c>();
            String value = getRepairProtocolValue(lstWorkOrder[0]);
            //DCP-58614 [updated query to add Repair_protocol__c == NULL in first OR condition and Product_Group__c= productGroup in second OR condition]
            String queryString = 'SELECT id, Document_Name__c, Document_Number__c, Activity_Type__c FROM Work_Order_Activity_Rules__c ' 
                + 'WHERE Active__c=true AND RecordType.Name=\'Document Compliance\' ' 
                + 'AND ((Repair_protocol__c = NULL AND Activity_Type__c in: setActivityTypes AND (Product_Code__c=:productCode OR Product_Group__c=:productGroup)) ' ;
            queryString +=(String.isEmpty(value)? ')': 'OR (Product_Group__c=: productGroup AND Repair_protocol__c INCLUDES ' + value+'))');
            lstActivityRules= DataBase.query(queryString);
            
             system.debug('lstActivityRules ---> '+lstActivityRules);
            //END NEW

//pooja
       /*  List<Work_Order_Activity_Rules__c> lstActivityRules=[select id,Document_Name__c,Document_Number__c,Activity_Type__c from Work_Order_Activity_Rules__c
            where  RecordType.Name='Document Compliance' and Active__c=true
            and Activity_Type__c in: setActivityTypes and (Product_Code__c=:objWorkOrder.SVMXC__Product__c or Product_Group__c=:objWorkOrder.SVMXC__Product__r.Product_Group__c)];
        */


         /*Get Uploaded document Details */
         for(ContentDocumentLink obj:[select id,ContentDocumentId from ContentDocumentLink where LinkedEntityId =:recordId]){
            setContentDocumentLinkIds.add(obj.ContentDocumentId);
        }  
        for(ContentVersion objVersion:[select id,Document_Type_fileupload__c,ContentDocumentId,FileType   from ContentVersion 
            where ContentDocumentId IN  :setContentDocumentLinkIds]){
                setDocumentNames.add(objVersion.Document_Type_fileupload__c);

                ////////////////////
                if(!mapdocumentTypetoVersion.containsKey(objVersion.Document_Type_fileupload__c))
                    mapdocumentTypetoVersion.put(objVersion.Document_Type_fileupload__c,new List<ContentVersion>());
                mapdocumentTypetoVersion.get(objVersion.Document_Type_fileupload__c).add(objVersion);
        } 
         for(Work_Order_Activity_Rules__c objActivityRules:lstActivityRules){
            Boolean booldocumentUploaded=false;
            if(setDocumentNames.contains(objActivityRules.Document_Name__c)){
                booldocumentUploaded=true;  
                for(ContentVersion versionObj:mapdocumentTypetoVersion.get(objActivityRules.Document_Name__c)){
                    DataWrapper objdataWrapper=new DataWrapper(objActivityRules.Document_Name__c,objActivityRules.Document_Number__c,booldocumentUploaded,objActivityRules.Activity_Type__c,Versionobj.ContentDocumentId);
                    lstWrapperforuploadedfiles.add(objdataWrapper);
                    objdataWrapper.versionId=versionObj.ContentDocumentId;
                    objdataWrapper.fileType=versionObj.FileType;
                }
            }
            DataWrapper objWrapper=new DataWrapper(objActivityRules.Document_Name__c,objActivityRules.Document_Number__c,booldocumentUploaded,objActivityRules.Activity_Type__c,objActivityRules.Id);
            lstWrapper.add(objWrapper);
            
         }

         DataWrapperList lstdataWrapper=new DataWrapperList(lstWrapper,lstWrapperforuploadedfiles);
         system.debug('lstWrapper--'+lstWrapper);
         return lstdataWrapper;
         }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
/*
          *  @AUTHOR:  
          *  @DESCRIPTION: DataWrapper
          */
    public class DataWrapper{
        @AuraEnabled
        public String documentName;
        @AuraEnabled
        public String documentNumber;
        @AuraEnabled
        public Boolean documentUploaded;
        @AuraEnabled
        public String ActivityType;
        @AuraEnabled
        public String fileType;
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String versionId;
        /*
          *  @AUTHOR:  
          *  @DESCRIPTION: DataWrapper
          */

        public DataWrapper(String documentName, String documentNumber, Boolean documentUploaded,String ActivityType,String id){
            this.documentName=documentName;
            this.documentNumber=documentNumber;
            this.documentUploaded=documentUploaded;
            this.ActivityType=ActivityType;
            this.id=id;
        }
    }
        /*
          *  @AUTHOR:  
          *  @DESCRIPTION: DataWrapperList
          */
  public class DataWrapperList{
        @AuraEnabled
        public List<DataWrapper> lstDataWrapperforfileupload;
        @AuraEnabled
        public List<DataWrapper> lstDataWrapperforfiledisplay;
         /*
          *  @AUTHOR:  
          *  @DESCRIPTION: DataWrapperList
          */
        public DataWrapperList( List<DataWrapper> lstDataWrapperforfileupload,List<DataWrapper> lstDataWrapperforfiledisplay){
            this.lstDataWrapperforfileupload=lstDataWrapperforfileupload;
            this.lstDataWrapperforfiledisplay=lstDataWrapperforfiledisplay;
        }


  }
    /**
     * Method: getRepairProtocolValue
     * Description: Methid to return the Repair Protocal values with single quotes in the parathesis. DCP-49644
     * Params: objWorkorder
     * return: string
     */
    public static String getRepairProtocolValue(SVMXC__Service_Order__c objWorkOrder){
        // Pooja DCP:49644 Start
        String value=null; 
        List<String> repairProtocolsSelLst= new List<String>();
        String repairProtocols=null;
        List<User> lstUser = new List<User>();
        Set<Id> setUserProfileId= new Set<Id>();
        List<String> lstProfiles = new List<String>{STRING_CHANNEL_PARTNER_SALES_AND_SERVICE, STRING_CHANNEL_PARTNER_SERVICE, STRING_FIELD_SERVICE, STRING_FIELD_SERVICE_THIRD_PARTY, STRING_FIELD_COMPLIANCE,STRING_COMMERCIAL_REVENUE_OPS,STRING_QUALITY_ASSURANCE,STRING_CUSTOMER_SERVICE, STRING_TECHNICAL_SUPPORT};
        setUserProfileId.add(Userinfo.getUserId());
        lstUser = new UsersSelector().selectByUserId(setUserProfileId);
        if(!lstUser.isEmpty() && String.isNotBlank(lstUser[0].User_Profile_Name__c) && lstProfiles.contains(lstUser[0].User_Profile_Name__c) &&
            objWorkOrder.Repair_protocols__c!=null && objWorkOrder.Repair_protocols__c!=STRING_RP_NOT_APPLICABLE){
                repairProtocols=objWorkOrder.Repair_protocols__c;
                repairProtocolsSelLst=repairProtocols.split(';');
            }
        if(!repairProtocolsSelLst.isEmpty()) {
            value='(\'' + String.join(repairProtocolsSelLst, '\',\'') + '\')';
        }
        // DCP:49644 End
        return value;
    }

}

/* INIT METHOD:
OLD List query

 List<Work_Order_Activity_Rules__c> lstActivityRules=[select id,Document_Name__c,Document_Number__c,Activity_Type__c from Work_Order_Activity_Rules__c
            where  RecordType.Name='Document Compliance' and Active__c=true
            and Activity_Type__c in: setActivityTypes and (Product_Code__c=:objWorkOrder.SVMXC__Product__c or Product_Group__c=:objWorkOrder.SVMXC__Product__r.Product_Group__c)];
        
*/