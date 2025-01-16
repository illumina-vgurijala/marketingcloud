/**
*    @author Vaibhav Sirohi
*    @date   8-Aug-2019
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Joshith K                  25-Sep-2019            Added Last Modified date formatting
*    Himanshu                   29-March-2021          Code Scan Fixes 
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ViewActivePlansController  {
    
    private static final String TARGET = '_blank';
    private static final String TYPEURL = 'url';
    private static final String TYPEDATETYME='date';
    private static final String FIELDNAME_NAME = 'Name';
    private static final String FIELDNAME_PLANID = 'Id';
    private static final String FIELDNAME_ACCOUNTNAME = 'Account_Name__r.Name';
    private static final String FIELDNAME_ACCOUNTID = 'Account_Name__c';
    private static final String FIELDNAME_OWNERAPINAME = 'Owner.Name';
    private static final String FIELDNAME_OWNERNAME = 'Owner Name';
    private static final String FIELD_LASTMODIFIEDDATE = 'LastModifiedDate';
    /**
     * @author  Vaibhav Sirohi
     * @description  init method to fetch initial records
     * @param string ObjectName, String fieldNames, String recordId
     * @return DataTableWrapper
    **/
    @AuraEnabled(cacheable=true)
    public static DataTableWrapper initRecords(String ObjectName, String fieldNames, String recordId ) {
        List<LabelDescriptionWrapper> lstlabel = new List<LabelDescriptionWrapper>();
        DataTableWrapper objdatatableWrapper = new DataTableWrapper();
       
        Set<String> setOfField = new Set<String>();
        List<String> lstOfField = new List<String>();
        
        if(recordId.length() > 0){
            Account_Plan__c objAccountPlanInstance = new AccountPlanSelector().getAccountPlanByAccountPlanRecordId(recordId);
            if( objAccountPlanInstance != null){
               
                Set<String> setFieldName = new Set<String>(fieldNames.split(','));
                if(Schema.getGlobalDescribe().containsKey(ObjectName) ) {
                    sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
                    system.debug('sObj--->'+sObj);
                    
                    //get all the labels for  fields and put them in a map, keyed to the field api name
                    Map<String, Schema.SObjectField> mapOfStringObject = Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap();
                    for(String fieldName :  setFieldName){
                        if(fieldName == FIELDNAME_NAME){
                            setOfField.add(fieldName);
                            label l1 = new label(fieldName);
                            tooltip tp = new tooltip(fieldName);
                            TypeAttributes tAttribute1 = new TypeAttributes(l1 , TARGET, tp ); 
                            lstlabel.add(new LabelDescriptionWrapper(mapOfStringObject.get(FIELDNAME_NAME).getDescribe().getLabel(), 
                                                                     FIELDNAME_PLANID,
                                                                     TYPEURL, 
                                                                     tAttribute1));
                        }
                        else if(fieldName == FIELDNAME_ACCOUNTNAME) {
                            setOfField.add(fieldName);
                            setOfField.add(FIELDNAME_ACCOUNTID);
                            label l = new label(fieldName);
                            tooltip tp = new tooltip(fieldName);
                            TypeAttributes tAttribute = new TypeAttributes(l, TARGET, tp ); 
                            lstlabel.add(new LabelDescriptionWrapper(mapOfStringObject.get(FIELDNAME_ACCOUNTID).getDescribe().getLabel(), 
                                                                     FIELDNAME_ACCOUNTID, 
                                                                     TYPEURL, 
                                                                     tAttribute));
                        }
                        else if(fieldName == FIELDNAME_OWNERAPINAME) {
                            setOfField.add(fieldName);
                            lstlabel.add(new LabelDescriptionWrapper(FIELDNAME_OWNERNAME, fieldName, null, null));
                        }
                        else if(fieldName == FIELD_LASTMODIFIEDDATE) {
                            setOfField.add(fieldName);
                            TypeAttributes tAttribute1 = new TypeAttributes('numeric' ,'short' ,'2-digit'  ); 
                            lstlabel.add(new LabelDescriptionWrapper(mapOfStringObject.get(FIELD_LASTMODIFIEDDATE).getDescribe().getLabel(), 
                                                                     FIELD_LASTMODIFIEDDATE,
                                                                     TYPEDATETYME, 
                                                                     tAttribute1));
                        }else if(mapOfStringObject.containsKey(fieldName)) {
                            setOfField.add(fieldName);
                            lstlabel.add(new LabelDescriptionWrapper(mapOfStringObject.get(fieldName).getDescribe().getLabel(), 
                                                                     fieldName, 
                                                                     mapOfStringObject.get(fieldName).getDescribe().getType().name().toLowerCase(), null));
                        }
                    }
                    //call method to query
                    lstOfField.addAll(setOfField);
                    system.debug('lstOfField-->'+lstOfField);
                    if(objAccountPlanInstance.Account_Name__r.Ultimate_Parent_Id__c != null){
                    List<sObject> sObjectRecords = getsObjectRecords(ObjectName, lstOfField,objAccountPlanInstance.Account_Name__r.Ultimate_Parent_Id__c, objAccountPlanInstance.Account_Name__r.Ultimate_Parent__c);
                    
                        objdatatableWrapper.lstLabelDescription 	= lstlabel;
                        objdatatableWrapper.lstSob 	= sObjectRecords;
                        objdatatableWrapper.lstFields 	= lstOfField;
                  }
                }
            }
        }
        return objdatatableWrapper;
        
    }
    /**
     * @author  Vaibhav Sirohi
     * @description  method to return different sobject records
     * @param String ObjectName, List<String> fieldNameSet, String utlimateParentId, String ultimateParentName
     * @return List<sObject> 
    **/
    @AuraEnabled(cacheable=true)
    public static List<sObject> getsObjectRecords(String ObjectName, List<String> fieldNameSet, String utlimateParentId, String ultimateParentName) {
        
        String activeState = 'Active';
        String query = 'SELECT  '+String.join(fieldNameSet, ',')+'  FROM '+ObjectName;
        if(String.isNotBlank(utlimateParentId) && !fieldNameSet.isEmpty()) {
           // recId = String.valueOf(recId);
           query += ' WHERE Account_Name__r.Ultimate_Parent_Id__c =: utlimateParentId AND Account_Name__r.Ultimate_Parent__c =: ultimateParentName AND Plan_Status__c = :activeState';
           system.debug('query-->'+query);
            return Database.query(query);
        }
        return null;
    }
    
    
    /**
     * @author  Vaibhav Sirohi
     * @date 2022-03-29
     * @description  wrapper class for data table
    **/
    
    public class DataTableWrapper {
        @AuraEnabled
        public List<LabelDescriptionWrapper> lstLabelDescription;
        @AuraEnabled
        public List<sObject> lstSob;
        @AuraEnabled
        public List<String> lstFields;
        
    }
    /**
     * @author  Vaibhav Sirohi
     * @date 2022-03-29
     * @description  Wrapper class to store Field details
    **/   
        
    public class LabelDescriptionWrapper {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public TypeAttributes typeAttributes;
        
        /**
         * @author  Vaibhav Sirohi
         * @description  constructor for the above wrapper class
         * @param String labelTemp, String fieldNameTemp, String typeTemp,TypeAttributes typeAttributesTemp
         * @return void
        **/
        public LabelDescriptionWrapper(String labelTemp, String fieldNameTemp, String typeTemp,TypeAttributes typeAttributesTemp) {
            label 	  = labelTemp;
            fieldName = fieldNameTemp;
            type 	  = typeTemp;
            typeAttributes = typeAttributesTemp;
            
        }
    }
    /**
     * @author  Vaibhav Sirohi
     * @date 2022-03-29
     * @description  Wrapper class to store TypeAttributes
    **/   
    public class TypeAttributes  {
        
        @AuraEnabled
        public label label;
        @AuraEnabled
        public String target;
        @AuraEnabled
        public tooltip tooltip;
        @AuraEnabled
        public String year;
        @AuraEnabled
        public String month;
        @AuraEnabled
        public String day;
        
        /**
         * @author  Vaibhav Sirohi
         * @description  constructor for the above wrapper class
         * @param String labelTemp, String fieldNameTemp, String typeTemp,TypeAttributes typeAttributesTemp
         * @return void
        **/
        public TypeAttributes(label tempLabel, String tempTarget ,tooltip tempTooltip) {
            
            label = tempLabel;
            target = tempTarget;
            tooltip = tempTooltip;
        }
        /**
         * @author  Vaibhav Sirohi
         * @description  constructor for the above wrapper class
         * @param String tempYear, String tempMonth ,String tempDay
         * @return void
        **/
        public TypeAttributes(String tempYear, String tempMonth ,String tempDay) {
            
            year = tempYear;
            month = tempMonth;
            day = tempDay;
        }
    }
    /**
     * @author  Vaibhav Sirohi
     * @date 2022-03-29
     * @description  Wrapper class to store tooltip
    **/   
    public class tooltip{
        @AuraEnabled
        public String fieldName;

    /**
     * @author  Vaibhav Sirohi
     * @description  constructor for the above wrapper class
     * @param String tempfieldName
     * @return void
    **/
        public tooltip(String tempfieldName) {
            
            fieldName = tempfieldName;
            
        }
    }
    /**
     * @author  Vaibhav Sirohi
     * @date 2022-03-29
     * @description  Wrapper class to store label
    **/       
    public class label  {
        
        @AuraEnabled
        public String fieldName;
        
                
        /**
         * @author  Vaibhav Sirohi
         * @description  constructor for the above wrapper class
         * @param String tempLabel
         * @return void
        **/       
        public label(String tempLabel) {
            
            fieldName = tempLabel;
            
        }
    }
    
    
}