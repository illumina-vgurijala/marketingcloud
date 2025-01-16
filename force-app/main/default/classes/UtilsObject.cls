/*
 * Modification Log:
 * -------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *          Sagar Madkaikar                11 Aug 2021        CMCP-21 Added method convertStringToDate() to convert String Date "3-Mar-21" to Date format
 *          Maruthi                        09 Mar 2022        PM-54 added createHistoryTracking() to create History Tracking records.
 *          Gerardo Garcia                 16 Feb 2024        CMCM-5648 added getPicklistFromDescribe
 * -------------------------------------------------------------------------------------------------------------
*/
public with sharing class UtilsObject {

	private static final String LOG_TITLE = 'UtilsObject';
	/*******************************************************************************************************
    * @description fetch all fields fomr sobject
    * @param objectName String
    * @return Map<String, SObjectField>
    */	
    public static Map<String, SObjectField> getSObjectFields(String objectName) {
        return (Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap());
    }

    /** getPicklistValuesWrapper
    * Gets the picklist values of a picklist field
    * @params : mapField, a map of object fields
    * @params : sFieldName, name of the picklist field
    * @params : sSelectLabel, select label of the picklist field
    * @return : a list of the picklist values
    */
    public static List<PickListValueWrapper> getPicklistValuesWrapper(Map<String, Schema.SObjectField> mapField, String sFieldName,
                                                                            String sSelectLabel){
        List<PickListValueWrapper> lstPickvals = new List<PickListValueWrapper>();
        lstPickvals.add(new PickListValueWrapper(null, sSelectLabel));
        getPicklistValuesWrapper(mapField,sFieldName,lstPickvals);
        System.debug('lstPickvals: ' + lstPickvals);
        return lstPickvals;
    }

    /** getPicklistValuesWrapper
    * Gets the picklist values of a picklist field
    * @params : mapField, a map of object fields
    * @params : sFieldName, name of the picklist field
    * @params : lstPickvals, list of PickListValueWrapper
    * @return : a list of the picklist values
    */
    public static List<PickListValueWrapper> getPicklistValuesWrapper(Map<String, Schema.SObjectField> mapField,
                                                                            String sFieldName, List<PickListValueWrapper> lstPickvals){
        Schema.DescribeFieldResult field = mapField.get(sFieldName).getDescribe();
        if(field.getType() == Schema.DisplayType.Picklist || field.getType() == Schema.DisplayType.MULTIPICKLIST){
            list<Schema.PicklistEntry> lstPickListValues = mapField.get(sFieldName).getDescribe().getPickListValues();
            //for all values in the picklist list
            for (Schema.PicklistEntry a : lstPickListValues)
                //add the value  to our final list
                lstPickvals.add(new PickListValueWrapper(a.getValue(), a.getLabel()));

        }

        return lstPickvals;
    }

    /**
     * Gets activated picklist from Schema.DescribeFieldResul i.e. UtilsObject.getPicklistFromDescribe(Account.Type.getDescribe())
     * @params: Schema.DescribeFieldResult describe <Object>.<picklistField>.getDescribe()
     * @return: List<PickListValueWrapper> pickListValues
     */
    public static List<PickListValueWrapper> getPicklistFromDescribe(Schema.DescribeFieldResult describe) {
        List<PickListValueWrapper> lstPickvals = new List<PickListValueWrapper>();
        List<Schema.PicklistEntry> entries = describe.getPicklistValues();
        for(Schema.PicklistEntry ple : entries) {
            if(ple.active) {
                lstPickvals.add(new PickListValueWrapper(ple.getValue(), ple.getLabel()));
            }
        }
        return lstPickvals;
    }

    /** getJSONPart
    * Gets part of a JSON
    * @params : strJSON, JSON string
    * @params : strPrefix, prefixing part of JSON
    * @params : strSuffix, suffix part of JSON
    * @return : a substring of JSON
    */
    public static String getJSONPart(String strJSON,String strPrefix,String strSuffix){
        String strSub = strJSON.substring(strJSON.indexOf(strPrefix)+strPrefix.length(),strJSON.lastIndexOf(strSuffix));
        System.debug('strSub: ' + strSub);
        return strSub;
    }


    /** getDependentPicklistValues
    * Gets dependant picklist mapping
    * @params : Map<String,Schema.SObjectField>, Map of field name to field details
    * @params : strControllingField, name of the controlling field
    * @params : strDependentField, Dependant field name
    * @params : strSelectLabel, Select Label
    * @return : Map<String, List<PickListValueWrapper>>, Map of controlling picklist value to all dependent picklist values
    */
    public static Map<String, List<PickListValueWrapper>> getDependentPicklistValues(Map<String,Schema.SObjectField> fieldNameToField, String strControllingField, String strDependentField,String strSelectLabel){
        Map<String, List<PickListValueWrapper>> controllingInfo = new Map<String, List<PickListValueWrapper>>();

        Schema.DescribeFieldResult controllingFieldInfo = fieldNameToField.get(strControllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = fieldNameToField.get(strDependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for(Schema.PicklistEntry currControllingValue : controllingValues)
            controllingInfo.put(currControllingValue.getLabel(),
                                new List<PickListValueWrapper>{new PickListValueWrapper(null,strSelectLabel)});

        for(Schema.PicklistEntry currDependentValue : dependentValues){

            Map<String, Object>  info = (Map<String, Object> )JSON.deserializeUntyped(JSON.serialize(currDependentValue));
            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode((String)info.get('validFor'))).toUpperCase();

            Integer baseCount = 0;

            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;

                if(curr >= 65)
                {
                    val = curr - 65 + 10;
                }
                else
                {
                    val = curr - 48;
                }

                if((val & 8) == 8)
                {
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(new PickListValueWrapper(currDependentValue.getLabel()));
                }
                if((val & 4) == 4)
                {
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(new PickListValueWrapper(currDependentValue.getLabel()));
                }
                if((val & 2) == 2)
                {
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(new PickListValueWrapper(currDependentValue.getLabel()));
                }
                if((val & 1) == 1)
                {
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(new PickListValueWrapper(currDependentValue.getLabel()));
                }

                baseCount += 4;
            }
        }

        System.debug('ControllingInfo: ' + controllingInfo);

        return controllingInfo;
    }

    /** To generate map from list of object
    * Moved from Collection to object due to coverage issue.
    *
    */
    public static Map<String, String> getMapOfStringToString(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        Map<String, String> valueMap = new Map<String, String>();
        for (Sobject so : objs)
            if (!String.isBlank((String)so.get(keyFieldName)))
                valueMap.put((String)so.get(keyFieldName), (String)so.get(valueFieldName));

        return valueMap;
    }

    // not used?
//    public static Object getSObjectFieldValue(SObject so, Schema.sObjectField field)
//    {
//        if ((null == so) || (null == field))
//            return null;
//
//        // Note throws error if mismatch
//        // i.e.
//        // Account acct = new Account();
//        // acct.Name = 'Account 0';
//        // sObject so = acct;
//        // so.get(Account.Name) OK
//        // so.get(Opportunity.Id) throws System.SObjectException
//        return so.get(field);
//    }
//
//    public static Boolean isInteger(String s)
//    {
//        try
//        {
//            Integer.valueOf(s);
//            return true;
//        }
//        catch (Exception e)
//        {
//            return false;
//        }
//    }
//
//    public static Map<String, List<SObject>> getMapOfStringToSObjects(List<SObject> lstSObjs, String strKeyFieldName)
//    {
//        Map<String, List<SObject>> mapStringToSObjects = new Map<String, List<SObject>>();
//        for (SObject so : lstSObjs)
//            if (so.get(strKeyFieldName) != null)
//            {
//                String strKeyVal = (String)so.get(strKeyFieldName);
//                if (!mapStringToSObjects.containsKey(strKeyVal))
//                    mapStringToSObjects.put(strKeyVal, new List<SObject>());
//                mapStringToSObjects.get(strKeyVal).add(so);
//            }
//
//        return mapStringToSObjects;
//    }
//
//    public static Datetime parseSapDate(String raw, Boolean endOfDay)
//    {
//        if (raw.length() != 8) return Datetime.now();
//        if (!UtilsObject.isInteger(raw)) return Datetime.now();
//
//        Date dateComponent = Date.newInstance(
//                Integer.valueOf(raw.substring(0, 4)),
//                Integer.valueOf(raw.substring(4, 6)),
//                Integer.valueOf(raw.substring(6, 8)));
//        Time timeComponent = (endOfDay ? Time.newInstance(23, 59, 59, 500) : Time.newInstance(0, 0, 0, 0));
//        return Datetime.newInstance(dateComponent, timeComponent);
//    }

    // traverse arbitrary number relationships to get a value on an SObject
    // ex: on opportunity can pass 'Account.Owner.Name' as the deep field
    // result will be the Name value on the account owner
		
    /*******************************************************************************************************
    * @description fetch all deep fields from sobject
    * @param obj Sobject
    * @param deepField String
    * @return String
    */
    public static String getDeepStringFromObject(Sobject obj, String deepField)
    {
        // optimization
        if (!deepField.contains('.')) return String.valueOf(obj.get(deepField));

        List<String> deepFieldList = deepField.split('\\.');

        for (Integer i=0; i<deepFieldList.size(); i++)
        {
            if (i == deepFieldList.size()-1)
                return String.valueOf(obj.get(deepFieldList.get(i)));
            else
            {
                obj = obj.getSobject(deepFieldList.get(i));
                if (obj == null)
                    return null;
            }
        }
        return null;
    }

    // traverse arbitrary number relationships to get a value on an SObject
    // ex: on opportunity can pass 'Account.OwnerId' as the deep field
    // result will be the Owner ID value on the account
	
	/*******************************************************************************************************
    * @description fetch all Deep id type fields from sobject
    * @param obj Sobject
    * @param deepField String
    * @return String
    */		
    public static Id getDeepIdFromObject(Sobject obj, String deepField)
    {
        // optimization
            if (!deepField.contains('.')) return (Id)obj.get(deepField);

            List<String> deepFieldList = deepField.split('\\.');

            for (Integer i=0; i<deepFieldList.size(); i++)
            {
                if (i == deepFieldList.size()-1)
                    return (Id)obj.get(deepFieldList.get(i));
                else
                {
                    obj = obj.getSobject(deepFieldList.get(i));
                    if (obj == null)
                        return null;
                }
            }
            return null;
    }

	/*******************************************************************************************************
    * @description method to check if field value is changed
    * @param lstNewValues List<SObject>
    * @param idToOldValues Map<Id, SObject>
    * @param fieldsToCheck List<String>
    * @return List<SObject>
    */	
    public static List<SObject> filterForFieldChanges(List<SObject> lstNewValues, Map<Id, SObject> idToOldValues, List<String> fieldsToCheck)
    {
        List<SObject> changedObjects = new List<SObject>();

        for (SObject newObject : lstNewValues)
        {
            SObject oldObject = idToOldValues.get(newObject.Id);

            for (String f : fieldsToCheck)
            {
                String newValue = (String)newObject.get(f);
                String oldValue = (String)oldObject.get(f);

                if (newValue != oldValue)
                {
                    changedObjects.add(newObject);
                    break;
                }
            }
        }

        return changedObjects;
    }

    /*******************************************************************************************************
    * @description generate a random number
    * @return String
    */		
    public static String getRandom()
    {
        return getRandom(6);
    }

	/*******************************************************************************************************
    * @description generate a random number
    * @param len Integer
    * @return String
    */	
    public static String getRandom(Integer len)
    {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        return getRandom(len, chars);
    }

	/*******************************************************************************************************
    * @description generate a random number
    * @param len Integer
    * @param chars String
    * @return String
    */
    private static String getRandom(Integer len, String chars)
    {
        String randStr = '';
        while (randStr.length() < len)
        {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
	
	/** convertStringToDate
    * @author Sagar Madkaikar
    * @date   11-Aug-2021
    * @description: CMCP-21:Converts String Date "3-Mar-21" to Date format.
    * @params : stringDate, a string containing date in "3-Mar-21" format
    * @return : converted value in Date format.
    */
    public static Date convertStringToDate(String stringDate){
        Map<String, Integer> monthsMap = new Map<String, Integer>{'JAN' => 1,
                                                                  'FEB' => 2,
                                                                  'MAR' => 3,
                                                                  'APR' => 4,
                                                                  'MAY' => 5,
                                                                  'JUN' => 6,
                                                                  'JUL' => 7,
                                                                  'AUG' => 8,
                                                                  'SEP' => 9,
                                                                  'OCT' => 10,
                                                                  'NOV' => 11,
                                                                  'DEC' => 12
                                                                  };
        Date returnDate = null;
                                                                  
        if(String.isNotBlank(stringDate)){
            //split the String date "3-Mar-21" with "-"
            List<String> dateList = stringDate.split('-');
            //If Year is present in 2 digits. Convert into 4 digits.
            String yearValue=dateList[2].length()==2?'20'+dateList[2]:dateList[2];
            returnDate = Date.newInstance(Integer.valueOf(yearValue),monthsMap.get(dateList[1].toUpperCase()),Integer.valueOf(dateList[0]));
        }
        
        return returnDate;

    }
	
	/* @author     : Maruthi
     * @param      : Sobject NewMap, OldMap, Codepatameter value 
     * @return     : N/A
     * @Description: PM:54 To insert Object History records on change of fields added in custom metadata. 
     **/
    public static void createHistoryTracking(Map<Id, SObject> newRecordsMap, Map<Id, SObject> oldRecordMap, String codeParameterForHistoryTrackingFields) {
       
        ilib_LogEvent.push(LOG_TITLE + '.createHistoryTracking()');
        try {
            List<Object_History__c> lstHistory = new List<Object_History__c>(); 
            List<Code_Parameter__mdt> codeParameter =new CodeParametersSelector().selectCodeParameterByDeveloperName(new set<String>{codeParameterForHistoryTrackingFields});        
            List<String> fieldsToCheck = codeParameter[0].Value__c.split(';');
            List<String> fieldsToUpdate = codeParameter[0].Values_Text__c.split(':');
            Map<String,String> labelToAPI = new Map<String,String>();
            for(String str: fieldsToCheck) {
                List<String> strLst = str.split(':');
                labelToAPI.put(strLst[1],strLst[0]);  
            }                 
            for(Id recId : newRecordsMap.keySet()) {
                for(String fieldAPI : labelToAPI.keySet()) {                
                    if(newRecordsMap.get(recId).get(fieldAPI) != oldRecordMap.get(recId).get(fieldAPI)) {                    
                        Object_History__c newHistory = new Object_History__c();
                            if(String.valueOf(recId.getSobjectType()) == fieldsToUpdate[0]) {
                                newHistory.put(fieldsToUpdate[1],recId);
                            }                                
                            newHistory.put('Field__c',labelToAPI.get(fieldAPI));                            
                            newHistory.put('Original_Value__c',String.valueOf(oldRecordMap.get(recId).get(fieldAPI)));                                
                            newHistory.put('New_Value__c',String.valueOf(newRecordsMap.get(recId).get(fieldAPI)));                                               
                            newHistory.put('Source_Object__c',fieldsToUpdate[0]);
                            newHistory.put('Date__c',DateTime.now());
                            newHistory.put('User__c',UserInfo.getUserId());                                                     
                            lstHistory.add(newHistory);
                    }
                }                        
            }
            ilib_LogEvent.message('lstHistory-->'+lstHistory);            
            if(!lstHistory.isEmpty()) {
                insert lstHistory; 
            }
            ilib_LogEvent.pop();
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE+'.createHistoryTracking',e);
        }
    }

}