/**
*	@author Arnab
*	@date	 
*	@description Utility class that retun different collection based on the input provided.
*	Modification Log:
*	------------------------------------------------------------------------------------
*			Developer					Date				Description
*			Arnab                                           Inital Version
*           Himanshu                   31 Mar-2022          Code Scan Fixes           
*	------------------------------------------------------------------------------------
**/
public with sharing class UtilsCollection {
    private static final String LOG_TITLE = 'UtilsCollection';
    /**
     *  @description given a list of sobjects, return a set of IDs
     *  @return set of values
     **/
    public static Set<Id> getSetOfIds(List<Sobject> objs)
    {
        return getSetOfIds(objs, 'Id');
    }

    /**
     *  @description given a list of sobjects, return a set of values in the requested field
     *  @return set of values
     **/
    public static Set<Id> getSetOfIds(List<Sobject> objs, String fieldName)
    {
        Set<Id> valueSet = new Set<Id>();
        if(objs == Null){
            return valueSet;    
        }
        try{
            for (Sobject so : objs)
            {
                Id thisValue = UtilsObject.getDeepIdFromObject(so, fieldName);
                if (thisValue != null)
                    valueSet.add(thisValue);
            }

            return valueSet;
        }catch(Exception e){
            return valueSet;
        }
    }

    /**
     *  @description given a list of sobjects, return a set of values in the requested field
     *  @return set of values
     **/
    public static Set<String> getSetOfStrings(List<Sobject> objs, String fieldName)
    {
        Set<String> valueSet = new Set<String>();
        for (Sobject so : objs)
        {
            String thisValue = UtilsObject.getDeepStringFromObject(so, fieldName);
            if (!String.isBlank(thisValue))
                valueSet.add(thisValue);
        }

        return valueSet;
    }

    /**
     *  @description given a list of sobjects, return a map of two of the values
     *  @return mapped values
     **/
    public static Map<Id, Id> getMapOfIdToId(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        Map<Id, Id> m = new Map<Id, Id>();
        for (Sobject so : objs)
        {
            Id thisKey = UtilsObject.getDeepIdFromObject(so, keyFieldName);
            Id thisValue = UtilsObject.getDeepIdFromObject(so, valueFieldName);
            if (thisKey != null && thisValue != null)
                m.put(thisKey, thisValue);
        }

        return m;
    }

    /**
     *  @description given a list of sobjects, return a map of two of the values
     *  @return mapped values
     **/
    public static Map<Id, String> getMapOfIdToString(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        Map<Id, String> m = new Map<Id, String>();
        for (Sobject so : objs)
        {
            Id thisKey = UtilsObject.getDeepIdFromObject(so, keyFieldName);
            String thisValue = UtilsObject.getDeepStringFromObject(so, valueFieldName);
            if (thisKey != null && thisValue != null)
                m.put(thisKey, thisValue);
        }

        return m;
    }

    /**
     *  @description given a list of sobjects, return a map of one of the values to a list of other values which are correlated to the first values
     *  @return mapped values
     **/
    public static Map<Id, Set<Id>> getMapOfIdToIds(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        ilib_LogEvent.push(LOG_TITLE + '.getMapOfIdToIds');
        Map<Id, Set<Id>> m = new Map<Id, Set<Id>>();
        for (Sobject so : objs)
        {
            Id thisKey = UtilsObject.getDeepIdFromObject(so, keyFieldName);
            Id thisValue = UtilsObject.getDeepIdFromObject(so, valueFieldName);
            if (thisKey != null && thisValue != null)
            {
                if (!m.containsKey(thisKey))
                    m.put(thisKey, new Set<Id>());
                m.get(thisKey).add(thisValue);
            }
        }
        ilib_LogEvent.message('mapped values->m ' + m);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return m;
    }

    /**
     *  @description  Return map of field -value pair for particular record
     *  @return mapped values
     **/
    public static Map<String, String> getMapOfAPInameToValue(Sobject objs, List<String> keyAPIname)
    {
        Map<String, String> m = new Map<String, String>();
        for (String apiName : keyAPIname)
        {
            String val = objs.get(apiName) == null ? null : String.valueof(objs.get(apiName));
            m.put(apiName, val);
        }
        return m;
    }

    
    // NOTE: because of Apex type wierdness, the type needs to be passed in for this method
    // ex:
    // Map<String, Account> res = (Map<String, Account>)UtilsCollection.getMapOfStringToSObject(accounts, 'Name', Map<String, Account>.class);
    /**
     *  @description given a list of sobjects, return a map of one value to the row
     *  @params List<SObject> lstSObjs, String strKeyFieldName, Type mapType
     *  @return mapped values
     **/
    public static Map<String, SObject> getMapOfStringToSObject(List<SObject> lstSObjs, String strKeyFieldName, Type mapType)
    {
        Map<String, SObject> mapStringToSObject = (Map<String, SObject>) mapType.newInstance();
        for (SObject so : lstSObjs)
            mapStringToSObject.put((String)so.get(strKeyFieldName), so);

        return mapStringToSObject;
    }

    /**
     *  @description given a list of sobjects, return a map of one value to rows which contain that value
     *  @return mapped values
     **/
    public static Map<Id, List<SObject>> getMapOfIdToSObjects(List<Sobject> objs, String keyFieldName, String valueObjectName)
    {
        Map<Id, List<SObject>> m = new Map<Id, List<SObject>>();
        for (Sobject so : objs)
        {
            Id thisKey = UtilsObject.getDeepIdFromObject(so, keyFieldName);
            if (thisKey != null && so.getSObject(valueObjectName) != null)
            {
                if (!m.containsKey(thisKey))
                    m.put(thisKey, new List<SObject>());
                m.get(thisKey).add(so.getSObject(valueObjectName));
            }
        }
        return m;
    }

    /**
     *  @description given a list of sobjects, return a map of one value to rows which contain that value
     *  @return mapped values
     **/
    public static Map<Id, List<SObject>> getMapOfIdToSObjects(List<SObject> lstSObjs, String keyFieldName)
    {
        Map<Id, List<SObject>> mapIdToSObjects = new Map<Id, List<SObject>>();
        for (SObject so : lstSObjs)
        {
            Id thisKey = UtilsObject.getDeepIdFromObject(so, keyFieldName);
            if (thisKey != null)
            {
                if (!mapIdToSObjects.containsKey(thisKey))
                    mapIdToSObjects.put(thisKey, new List<SObject>());
                mapIdToSObjects.get(thisKey).add(so);
            }
        }
        return mapIdToSObjects;
    }

    /**
     *  @description given a list of sobjects, return a map of one value to rows which contain that value
     *  @return mapped values
     **/
    public static Map<String, List<SObject>> getMapOfStringToSObjects(List<SObject> lstSObjs, String keyFieldName)
    {
        Map<String, List<SObject>> mapStringToSObjects = new Map<String, List<SObject>>();
        for (SObject so : lstSObjs)
        {
            String thisKey = UtilsObject.getDeepStringFromObject(so, keyFieldName);
            if (!String.isBlank(thisKey))
            {
                if (!mapStringToSObjects.containsKey(thisKey))
                    mapStringToSObjects.put(thisKey, new List<SObject>());
                mapStringToSObjects.get(thisKey).add(so);
            }
        }

        return mapStringToSObjects;
    }

    /**
     *  @description given a list of sobjects, return a map of two of the values
     *  @return mapped values
     **/
    public static Map<String, String> getMapOfStringToString(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        Map<String, String> valueMap = new Map<String, String>();
        for (Sobject so : objs)
        {
            String thisKey = UtilsObject.getDeepStringFromObject(so, keyFieldName);
            String thisValue = UtilsObject.getDeepStringFromObject(so, valueFieldName);
            if (!String.isBlank(thisKey))
                valueMap.put(thisKey, thisValue);
        }

        return valueMap;
    }

    /**
     *  @description DCP-25384: given two maps, combine them
     *  @return merged map
     **/
    public static Map<Id, Set<Id>> getMergeMap(Map<Id, Set<Id>> map1, Map<Id, Set<Id>> map2)
    {
        Map<Id, Set<Id>> finalMap = new Map<Id, Set<Id>>();

        if (map1 != null)
        {
            finalMap.putAll(map1);
        }


        if (map2 != null)
        {
            for (Id i : map2.keySet())
            {
                if (finalMap.containsKey(i))
                    finalMap.get(i).addAll(map2.get(i));
                else
                    finalMap.put(i, new Set<Id>(map2.get(i)));
            }
        }

        return finalMap;
    }

    /**
     *  @description given a map of value to sets, combine the sets to one
     *  @return merged set
     **/
    public static Set<Id> flattenMapValueSets(Map<Id, Set<Id>> idToSet)
    {
        ilib_LogEvent.push(LOG_TITLE + '.flattenMapValueSets');
        Set<Id> flattened = new Set<Id>();
        for (Id i :idToSet.keySet())
            flattened.addall(idToSet.get(i));

        ilib_LogEvent.message('flattened ' + flattened);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return flattened;
    }

    /**
     *  @description given a set of IDs, return the "first" one, because sometimes any ID will do
     *  @return one of the IDs
     **/
    public static Id getFirstIdFromSet(Set<Id> ids)
    {
        if (ids != null)
            for (Id i : ids)
                return i;
        return null;
    }

    /**
     *  @description given a set of IDs and a threshold, split the set into multiple sets no larger than the threshold size
     *  @return list of sets
     **/
    public static List<Set<Id>> sliding(Set<Id> ids, Integer elementsInEach)
    {
        List<Set<Id>> res = new List<Set<Id>>();

        if (ids == null) return res;
        if (elementsInEach == null || elementsInEach < 1) return res;

        Integer counter = 0;
        Set<Id> chunk;

        for (Id id : ids)
        {
            if (counter == 0)
                chunk = new Set<Id>();

            chunk.add(id);
            counter = counter + 1;

            if (counter == elementsInEach)
            {
                res.add(chunk);
                counter = 0;
            }
        }

        if (Math.mod(ids.size(), elementsInEach) != 0)
            res.add(chunk);

        return res;
    }

    /**
     *  @description given a set of values and a size n, return the first n elements in the set
     *  @return set of a capped size
     **/
    public static Set<Id> take(Set<Id> records, Integer n)
    {
        if (records == null || records.isEmpty() || n >= records.size()) return records;

        Set<Id> res = new Set<Id>();
        List<Id> lstRecords = new List<Id>(records);
        for (Integer i = 0; i < n; i++)
            res.add(lstRecords.get(i));

        return res;
    }

    /**
     *  @description given a set of values and a size n, return the last n elements in the set
     *  @return set of a capped size
     **/
    public static Set<Id> takeRight(Set<Id> records, Integer n)
    {
        if (records == null || records.isEmpty() || n >= records.size()) return records;

        Set<Id> res = new Set<Id>();
        List<Id> lstRecords = new List<Id>(records);
        for (Integer i = lstRecords.size() - 1; i >= lstRecords.size() - n; i--)
            res.add(lstRecords.get(i));

        return res;
    }

    /**
     *  @description given a set of values and a size n, return the first n elements in the set
     *  @return set of a capped size
     **/
    public static List<String> take(List<String> records, Integer n)
    {
        if (records == null || records.isEmpty() || n >= records.size()) return records;

        List<String> res = new List<String>();
        for (Integer i = 0; i < n; i++)
            res.add(records.get(i));

        return res;
    }

    /**
     *  @description given a set of values and a size n, return the last n elements in the set
     *  @return set of a capped size
     **/
    public static List<String> takeRight(List<String> records, Integer n)
    {
        if (records == null || records.isEmpty() || n >= records.size()) return records;

        List<String> res = new List<String>();
        for (Integer i = records.size() - 1; i >= records.size() - n; i--)
            res.add(records.get(i));

        return res;
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for rows where any field values have changed
     *  @return matching rows
     **/
    public static List<SObject> filterOnModified(List<SObject> newValues, Map<Id, SObject> idToOldValues)
    {
        return filterOnModified(newValues, idToOldValues, new Set<String>());
    }

    // NOTE: is there a better home for this?
    private static final Set<String> SYSTEM_TRACKING_FIELDS = new Set<String> {'LastModifiedById', 'LastModifiedDate', 'LastReferencedDate', 'LastViewedDate', 'SystemModstamp', 'LastActivityDate'};

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for rows where any field values have changed (other than passed-in list)
     *  @return matching rows
     **/
    public static List<SObject> filterOnModified(List<SObject> newValues, Map<Id, SObject> idToOldValues, Set<String> fieldsToExclude)
    {
        List<SObject> changedRecords = new List<SObject>();

        if (newValues == null || idToOldValues == null || newValues.size() == 0)
            return changedRecords;

        if (fieldsToExclude == null) fieldsToExclude = new Set<String>();

        List<Schema.SObjectField> lstFieldAPINames = newValues.get(0).getSObjectType().getDescribe().fields.getMap().values();

        for (SObject obj : newValues)
        {
            Boolean isDirty = false;
            for (Schema.SObjectField fieldName : lstFieldAPINames)
            {
                // skip formula fields
                if (fieldName.getDescribe().isCalculated())
                    continue;

                String strFieldName = fieldName.getDescribe().getName();

                // skip system stamping fields
                if (SYSTEM_TRACKING_FIELDS.contains(strFieldName))
                    continue;

                // skip fields client wants to ignore
                if (fieldsToExclude.contains(strFieldName))
                    continue;

                SObject oldObj = idToOldValues.get(obj.Id);
                if (oldObj == null || obj.get(strFieldName) != oldObj.get(strFieldName))
                {
                    isDirty = true;
                    break;
                }
            }

            if (isDirty)
                changedRecords.add(obj);
        }

        return changedRecords;
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for rows where certain field values have changed
     *  @return matching rows
     **/
    public static List<SObject> filterOnFieldsModified(List<SObject> newValues, Map<Id, sObject> idToOldValues, List<String> fieldNames)
    {
        List<SObject> changedRecords = new List<SObject>();
        if (newValues == null || newValues.size() == 0)
            return changedRecords;

        for (SObject rec : newValues)
        {
            if (rec.Id == null)
                changedRecords.add(rec);
            else if (areAnyValuesModified(rec, idToOldValues.get(rec.Id), fieldNames))
                changedRecords.add(rec);
        }

        return changedRecords;
    }

    /**
     *  @description determine if any of the fields were changed given an old and a new version of a database row
     **/
    public static Boolean areAnyValuesModified(SObject newValues, SObject oldValues, List<String> fieldNames)
    {
        for (String fieldName: fieldNames)
        {
            Object newVal = newValues.get(fieldName);
            Object oldVal;
            if (oldValues != null)
                oldVal = oldValues.get(fieldName);

            if (oldValues == null)
            {
                // on insert any new value is a change
                if (newVal != null)
                    return true;
            }
            else
            {
                // on update
                if (newVal != oldVal)
                    return true;
            }
        }

        return false;
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for fields that have specific values (passed in a map)
     *  @return matching rows
     **/
    public static List<SObject> filterForValues(List<SObject> records, Map<Id, SObject> idToOldValues, Map<String, Set<Object>> fieldToSpecifiedValues)
    {
        // don't care if the values changed or not
        return filterForValues(records, idToOldValues, fieldToSpecifiedValues, false, false);
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for fields that were unchanged and have specific values (passed in a map)
     *  @return matching rows
     **/
    public static List<SObject> filterForUnchangedValues(List<SObject> records, Map<Id, SObject> idToOldValues, Map<String, Set<Object>> fieldToSpecifiedValues)
    {
        return filterForValues(records, idToOldValues, fieldToSpecifiedValues, false, true);
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for fields that have changed to specific values (passed in a map)
     *  @return matching rows
     **/
    public static List<SObject> filterForChangeToValue(List<SObject> records, Map<Id, SObject> idToOldValues, Map<String, Set<Object>> fieldToSpecifiedValues)
    {
        return filterForValues(records, idToOldValues, fieldToSpecifiedValues, true, false);
    }

    /**
     *  @description given a list of rows and prior values map (like Trigger.new and Trigger.oldMap)
     *               look for fields that have specific values (passed in a map)
     *               the flags control whether we only want changed or unchanged values
     *  @return matching rows
     **/
    private static List<SObject> filterForValues(List<SObject> records, Map<Id, SObject> idToOldValues, Map<String, Set<Object>> fieldToSpecifiedValues, Boolean checkChangeToValue, Boolean checkUnchangedValue)
    {
        List<SObject> matchingRecords = new List<SObject>();

        for (SObject obj : records)
        {
            Boolean thisRecordMatches = true;

            for (String field : fieldToSpecifiedValues.keySet())
            {
                Object newValue = obj.get(field);
                Object oldValue = null;
                if (idToOldValues != null && idToOldValues.containsKey(obj.Id)) oldValue = idToOldValues.get(obj.Id).get(field);
                Set<Object> specifiedValues = fieldToSpecifiedValues.get(field);

                // check that the value changed if we care about such things
                Boolean changeToValueOrDontCare = !checkChangeToValue || newValue != oldValue;
                // check that the value did not change if we care about such things
                Boolean unchangedValueOrDontCare = !checkUnchangedValue || newValue == oldValue;

                if (!(specifiedValues.contains(newValue) && changeToValueOrDontCare && unchangedValueOrDontCare))
                {
                    thisRecordMatches = false;
                    break;
                }
            }

            if (thisRecordMatches)
                matchingRecords.add(obj);
        }

        return matchingRecords;
    }

    /**
     *  @description PRB0042658: publish an apex exception for ny errors present in list of SaveResults
     **/
    public static void processSaveResults(List<Database.SaveResult> results, String source)
    {
        for (Database.SaveResult res : results)
        {
            if (!res.isSuccess())
            {
                for (Database.Error err : res.getErrors())
                {
                    String errorMessage = err.getStatusCode() + ',' + err.getMessage();
                    ApexExceptions.emit(source, errorMessage, ilib_LogEvent.getWorkstream());
                }
            }
        }
    }

    /**
     *  @description INC0225110: given a set of values, serialize to a string
     *  @return serialized values
     **/
    public static String serializeIds(Set<Id> setIds)
    {
        if (setIds == null) return '';

        // NOTE: switched next two methods from pipe | to tilde ~
        // because it looks better in debug logs - ttn
        String res = '';
        for (Id i : setIds)
            res += i + '~';
        return res;
    }

    /**
     *  @description INC0225110: given a set of values, serialize to a string
     *  @return serialized values
     **/
    public static String serializeIds(Set<String> setIds)
    {
        if (setIds == null) return '';

        String res = '';
        for (String i : setIds)
            res += i + '~';

        return res;
    }

    
    /**
     *  @description Moved from ApttusProposals and refactored by Arnab
     *  @params List<SObject> lstNewValues, Map<Id, SObject> idToOldValues, List<String> fieldsToCheck
     *  @return Set<Id>
    **/
    public static Set<Id> filterForFieldChanges(List<SObject> lstNewValues, Map<Id, SObject> idToOldValues, List<String> fieldsToCheck)
    {
        List<SObject> changedRecords = filterOnFieldsModified(lstNewValues, idToOldValues, fieldsToCheck);
        return getSetOfIds(changedRecords);
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To return set of errors that match known errors - DCP-52339
    **/
    public static Set<String> addKnownErrors(String errorMsg, Set<String> setKnownErrors) {
        Set<String> setErrors = new Set<String>();
        for (String knownError : setKnownErrors) {
            if (errorMsg.contains(knownError)) {
                setErrors.add(errorMsg);
            }
        }
        return setErrors;
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To return set of errors that does not match known errors - DCP-52339
    **/
    public static Set<String> addUnknownErrors(String errorMsg, Set<String> setKnownErrors) {
        Set<String> setErrors = new Set<String>();
        Boolean boolIsUnknownError = true;      //set true by default
        for (String knownError : setKnownErrors) {
            if (errorMsg.contains(knownError)) {
                boolIsUnknownError = false;     //set false when errorMsg matches with atleast one knownError
                break;
            }
        }
        if (boolIsUnknownError) { setErrors.add(errorMsg); }
        return setErrors;
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To return set of errors that does not match known errors - DCP-52339
    **/
    public static String concatenateToStringWithDelimiter(Set<Id> setIds, String delimiter) {
        if (setIds.isEmpty()) { return ''; }

        String concatenatedValues = '';
        for (String id : setIds) {
            concatenatedValues += id + delimiter;
        }
        return concatenatedValues;
    }

    /**
     *  @author Ashwin Kumar
     *  @description - To return set of errors that does not match known errors - DCP-52339
    **/
    public static String concatenateToStringWithDelimiter(List<Sobject> objs, String fieldName, String delimiter) {
        if (objs.isEmpty()) { return ''; }

        String concatenatedValues = '';
        for (Sobject so : objs) {
            String thisValue = UtilsObject.getDeepStringFromObject(so, fieldName);
            concatenatedValues = String.isBlank(thisValue) ? concatenatedValues : concatenatedValues + thisValue + delimiter;
            if (!String.isBlank(thisValue)) {
                concatenatedValues += thisValue + delimiter;
            }
        }
        return concatenatedValues;
    }

    /**
     *  @description given a set of values, serialize to a string
     *  @return serialized values
     **/
    public static String serializeIds(Set<Decimal> setIds)
    {
        if (setIds == null) return '';

        String res = '';
        for (Decimal i : setIds)
        {
            res += i + '~';
        }
        return res;
    }
}