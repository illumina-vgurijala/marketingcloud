/*
* @author Prabhsimran Singh
* @Date 7-Dec-2020
* @Description  Receiver class for Service query

Modification Log:
*/
@RestResource(urlMapping='/ServiceQueryReceiver/')
global with sharing class ServiceQueryInboundReceiver extends ilib_RestReceiver {
    public final static String ATTRIBUTE_KEYWORD = 'attributes';
    public final static String NO_RECORDS_KEYWORD = 'No records found';

    /* Method to return records*/
    @HttpPost
    global static void getSobjectRecords()
    {	
        
        List<map<string,object>> lstUpdateRecords = new List<map<string,object>>();
        ServiceQueryInboundReceiver instantiated = new ServiceQueryInboundReceiver();
        queryWrapper wrap = new queryWrapper();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;        
        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));        
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);
        try{
            wrap = (queryWrapper) System.JSON.deserialize(strJsonInput, queryWrapper.class);
            if(!wrap.query.containsIgnoreCase(' limit ')){
                wrap.query = wrap.query + ' limit 2000';
            }                
            List<sObject> lstsObjectRecords = database.query(wrap.query);
            List<Object> lstRecords = (List<Object>)JSON.deserializeUntyped(JSON.serialize(lstsObjectRecords));            
            for(object obj : lstRecords){                
                map<string,object> mapRecord = (map<string,object>) obj;                
                if(mapRecord.containsKey(ATTRIBUTE_KEYWORD)){
                    mapRecord.remove(ATTRIBUTE_KEYWORD);
                }                
                for(string keyname : mapRecord.keyset()){
                    if(mapRecord.get(keyname) instanceof map<string,object>){                        
                        map<string,object> mapRelationship = (map<string,object>) mapRecord.get(keyname);
                        if(mapRelationship.containsKey(ATTRIBUTE_KEYWORD)){
                            mapRelationship.remove(ATTRIBUTE_KEYWORD);
                        }                        
                        mapRecord.put(keyname,mapRelationship);
                    }
                    
                }                
                lstUpdateRecords.add(mapRecord);                
            }            
            if(!lstUpdateRecords.isEmpty()){                
                setResponse(JSON.serialize(lstUpdateRecords));
                
            }
            else{                
                setResponse(NO_RECORDS_KEYWORD);
                
            }                        
            ilib_LogInterface.finalizeLog(
                log,
                ilib_LogInterface.RESULT_SUCCESS,
                JSON.serialize(lstUpdateRecords),
                null
            );            
        }
        catch(Exception e){            
            setResponse('Exception:'+e.getMessage());
            ilib_LogInterface.finalizeLog(
                log,
                ilib_LogInterface.RESULT_FAIL,
                e.getMessage()+'-'+ e.getTypeName()+'-'+ e.getCause() +'-'+ e.getStackTraceString(),
                null
            );   
        }        
    }
    /*Method to set Response*/
    private static void setResponse(String responseMessage){
        RestResponse response = RestContext.response;
        response.statusCode = 200;
        response.responseBody = Blob.valueOf(responseMessage);
    }
    /*Wrapper class */
    public class queryWrapper{
        public string query;
    }
}