/**
*    @author 
*    @date   
*    @description test bundles
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Aman Tyagi                      6th Oct 2022       codescan fixes
*/
public with sharing class TestBundles {
    /**
     *  @author   
     *  @description TestBundleException extending Exception class
     **/
    public class TestBundleException extends Exception { }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // utility methods used across test bundle classes
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     *  @author   
     *  @description static method to insert the single object rows
     *  @param Map<String, List<SObject>> bundle, String objType
     *  @return List<SObject> 
     **/
    public static List<SObject> insertSingleObjectRows(Map<String, List<SObject>> bundle, String objType)
    {
        List<SObject> insertedRecs;

        if (bundle.containsKey(objType))
        {
            insertedRecs = bundle.get(objType);
            insert insertedRecs;

            ilib_LogEvent.message(objType + ' records inserted: ' + insertedRecs.size());
            for (Sobject rec : insertedRecs)
                ilib_LogEvent.message('Inserted record ' + rec);
        }

        return insertedRecs;
    }
    /**
     *  @author   
     *  @description method to add record to the list of SObject
     *  @param List<SObject> existingList, SObject rec
     *  @return List<SObject> 
     **/
    public static List<SObject> addRecordToList(List<SObject> existingList, SObject rec)
    {
        if (existingList == null)
            existingList = new List<SObject>();

        if (rec != null) existingList.add(rec);
        return existingList;
    }
    /**
     *  @author   
     *  @description method to add records to the list of SObject
     *  @param List<SObject> existingList, List<SObject> newRecs
     *  @return List<SObject> 
     **/
    public static List<SObject> addRecordsToList(List<SObject> existingList, List<SObject> newRecs)
    {
        if (existingList == null)
            existingList = new List<SObject>();

        existingList.addAll(newRecs);
        return existingList;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // value-picking utility methods used across test bundle classes
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     *  @author   
     *  @description  to return the string
     *  @param NA
     *  @return String
     **/
    public static String getRandom()
    {
        return getRandom(6);
    }
    /**
     *  @author   
     *  @description method to return the string
     *  @param Integer len
     *  @return String
     **/
    public static String getRandom(Integer len)
    {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        return getRandom(len, chars);
    }

    /**
     *  @author   
     *  @description method to return the numeric value
     *  @param NA
     *  @return String
     **/
    public static String getRandomNumeric()
    {
        return getRandomNumeric(6);
    }

    /**
     *  @author   
     *  @description method to return the random numeric value
     *  @param Integer len
     *  @return String
     **/
    public static String getRandomNumeric(Integer len)
    {
        String chars = '123456789'; // NOTE: removed 0 so numbers never start with 0
        return getRandom(len, chars);
    }

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

    /**
     *  @author   
     *  @description method to return the random string value from list
     *  @param List<String> values
     *  @return String
     **/
    public static String getRandomStringFromList(List<String> values)
    {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), values.size());
        return values.get(idx);
    }

}