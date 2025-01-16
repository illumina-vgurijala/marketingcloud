/**
*    @author  Illumina      
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      4/07/2022         CMSI-8 : Added Support for Transaction Id & Org Id
               Nitin                       5/06/2022         CMSI-5- Setting log category to interface
*/
global with sharing class ilib_LogInterface {

    private static final String TID = ilib_LogEvent.getTransactionId();
    private static final String ORGID = UserInfo.getOrganizationId();
    private static String inbound= 'Inbound';
    public static final String RESULT_SUCCESS = 'Success';
    public static final String RESULT_FAIL = 'Fail';
    public static final String RESULT_REJECTED = 'Rejected';
    public static final String KONG_CORRELATION_HEADER = 'API-Correlation-ID';
   

    private final static Schema.DescribeFieldResult LOG_JSON_MESSAGE_DFR = Schema.SObjectType.Interface_Log__c.fields.Json_Message__c;
    private final static Schema.DescribeFieldResult LOG_RESULT_DETAILS_DFR = Schema.SObjectType.Interface_Log__c.fields.Result_Details__c;

    /*
     * Lightweight wrapper that encapsulates Interface_Log__c
     */
    global class LogDetails
    {
        public String interfaceName { get; private set; }
        public String objectType { get; private set; }
        public String direction { get; private set; }
        public Id logRecordId { get; private set; }
        public Id relatedRecordId { get; private set; }
        public String jsonMessage { get; private set; }
        public String runningDetails { get; set; }
        public DateTime startTime { get; private set; }
        public String kongCorrelationId { get; private set; }
        
/**
*    @author  Illumina      
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
        public LogDetails(ilib_RestInterface.InterfaceDetails interfaceDetails)
        {
            this.startTime = DateTime.now();
            this.interfaceName = interfaceDetails.name;
            this.objectType = interfaceDetails.objectType;
            this.direction = interfaceDetails.direction;
        }
/**
*    @author  Illumina      
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
        public LogDetails(ilib_RestInterface.InterfaceDetails interfaceDetails, String jsonMessage)
        {
            this.startTime = DateTime.now();
            this.interfaceName = interfaceDetails.name;
            this.objectType = interfaceDetails.objectType;
            this.direction = interfaceDetails.direction;
            this.jsonMessage = jsonMessage;
        }
/**
*    @author  Illumina      
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
        public LogDetails(ilib_RestInterface.InterfaceDetails interfaceDetails, String jsonMessage, String kongCorrelationId)
        {
            this.startTime = DateTime.now();
            this.interfaceName = interfaceDetails.name;
            this.objectType = interfaceDetails.objectType;
            this.direction = interfaceDetails.direction;
            this.jsonMessage = jsonMessage;
            this.kongCorrelationId = kongCorrelationId;
        }
/**
*    @author  Illumina      
*    @date          
*    @description   
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
        public Boolean isPersisted()
        {
            return (logRecordId != null);
        }
    }

    /*
     * Start logging with an initial message
     * Probably json being sent to an external system
     *
     * This overload accepts the header. It prettifies the JSON and gets the KONG id
     */
     /**
*    @author  Illumina      
*    @date       
*    @description  
     @Param- interfaceDetails,req
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
              Nitin                          5/6/2022            CMSI-5- Setting log category to interface
*/
    public static LogDetails initiateLog(ilib_RestInterface.InterfaceDetails interfaceDetails, RestRequest req)
    {
        //CMSI-5
        ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
        String kongCorrelationId = (req != null && req.headers != null && req.headers.containsKey(KONG_CORRELATION_HEADER) ? req.headers.get(KONG_CORRELATION_HEADER) : '');

        String strJson = (req != null && req.requestBody != null ? req.requestBody.toString() : null);

        String strPrettyJson = '';
        if (!String.isBlank(strJson))
            strPrettyJson = JSON.serializePretty(JSON.deserializeUntyped(strJson));

        return new LogDetails(
            interfaceDetails,
            truncateToMaxLength(strPrettyJson, LOG_JSON_MESSAGE_DFR.getLength()),
            kongCorrelationId
        );
    }

    /*
     * Start logging with an initial message
     * Probably json being sent to an external system
     *
     * This overload accepts the JSON which is logged as-is and a header to get the KONG id
     */
     /**
*    @author    Illumina    
*    @date       
*    @description  
     @Param- interfaceDetails,req,strJson
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
              Nitin                          5/6/2022            CMSI-5- Setting log category to interface
*/
    public static LogDetails initiateLog(ilib_RestInterface.InterfaceDetails interfaceDetails, String strJson, RestRequest req)
    {
        //CMSI-5
        ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
        String kongCorrelationId = (req != null && req.headers != null && req.headers.containsKey(KONG_CORRELATION_HEADER)
                ? req.headers.get(KONG_CORRELATION_HEADER)
                : '');

        return new LogDetails(
                interfaceDetails,
                truncateToMaxLength(strJson, LOG_JSON_MESSAGE_DFR.getLength()),
                kongCorrelationId
        );
    }

    /*
     * Start logging with an initial message
     * Probably json being sent to an external system
     *
     * This overload accepts the JSON which is logged as-is
     */
    /**
*    @author Illumina       
*    @date       
*    @description  
     @Param- interfaceDetails,strJson
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
              Nitin                          5/6/2022            CMSI-5- Setting log category to interface
*/
    public static LogDetails initiateLog(ilib_RestInterface.InterfaceDetails interfaceDetails, String strJson)
    {
        //CMSI-5
        ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
        return new LogDetails(
            interfaceDetails,
            truncateToMaxLength(strJson, LOG_JSON_MESSAGE_DFR.getLength())
        );
    }

 /**
*    @author Illumina      
*    @date       
*    @description  
     @Param- interfaceDetails
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
              Nitin                           5/6/2022             CMSI-5- Setting log category to interface
*/
    public static LogDetails initiateLog(ilib_RestInterface.InterfaceDetails interfaceDetails)
    {
        //CMSI-5
        ilib_LogEvent.setLogCategory(ilib_LogEvent.Category.restInterface);
        return new LogDetails(interfaceDetails);
    }

/**
*    @author  Illumina      
*    @date          
*    @description 
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static void addJsonToLog(LogDetails wrapper, String json)
    {
        wrapper.jsonMessage = json;
    }
/**
*    @author  Illumina      
*    @date          
*    @description Add a mid-operation status (probably an error)
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static void addMessageToLog(LogDetails wrapper, String message)
    {
        if (wrapper.runningDetails == null)
            wrapper.runningDetails = message + '\n';
        else
            wrapper.runningDetails = wrapper.runningDetails + message + '\n';
    }
/**
*    @author  Illumina      
*    @date          
*    @description Add the final results to the log record and save it
     @Param- wrapper,result,resultDetails
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static String finalizeLog(LogDetails wrapper, String result, String resultDetails)
    {
        return finalizeLog(wrapper, result, resultDetails, wrapper.relatedRecordId, null);
    }
    /**
*    @author  Illumina      
*    @date          
*    @description Add the final results to the log record and save it
     @Param- wrapper,result,resultDetails,primaryRecordId
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static String finalizeLog(LogDetails wrapper, String result, String resultDetails, Id primaryRecordId)
    {
        return finalizeLog(wrapper, result, resultDetails, primaryRecordId, null);
    }
/**
*    @author  Illumina      
*    @date          
*    @description 
*    param - wrapper, result, resultDetails, primaryRecordId, response
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    public static String finalizeLog(LogDetails wrapper, String result, String resultDetails, Id primaryRecordId, HttpResponse response)
    {
        // combine result details and running log
        // NOTE: should these go to separate fields instead?
        Interface_Log__c objInterfaceLog = returnLogRecord(wrapper,result,resultDetails,primaryRecordId,response);
        upsert objInterfaceLog;
        wrapper.logRecordId = objInterfaceLog.Id;
        return objInterfaceLog.id;
    }
/**
*    @author  Illumina      
*    @date          
*    @description 
*    param - s, length
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*/
    private static String truncateToMaxLength(String s, Integer length)
    {
        return (String.isBlank(s) ? s : s.abbreviate(length));
    }

    /** 
* @author Illumina     
*    @date          
*    @description InterfaceException [CodeScan Fix]   
*
*/
    public class InterfaceException extends Exception { }
/** 
* @author Illumina     
*    @date          
*    @description   
*    param - wrapper, result, resultDetails, primaryRecordId, response
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Anshaj                      21/04/2022         CMSI-8 : Added Support for Transaction Id & Org Id
*/
    public static Interface_Log__c returnLogRecord(LogDetails wrapper, String result, String resultDetails, Id primaryRecordId, HttpResponse response)
    {
        // combine result details and running log
        // NOTE: should these go to separate fields instead?
         String fullResults;
        fullResults = resultDetails;
        if (!String.isBlank(wrapper.runningDetails))
            fullResults += '\n\nRUN LOG\n=======\n\n' + wrapper.runningDetails;

        Integer httpResponseCode;
        if (wrapper.direction == inbound)
        {
            httpResponseCode = (response == null ? null : response.getStatusCode());
        }
        else
        {
            if (result == RESULT_SUCCESS)
                httpResponseCode = UtilsRest.REST_SUCCESS;
            else
                httpResponseCode = UtilsRest.REST_ERROR;
        }

        Long runDuration = DateTime.now().getTime() - wrapper.startTime.getTime();

        Interface_Log__c logRecord = new Interface_Log__c(
            Interface_Name__c = wrapper.interfaceName,
            Related_Record_Type__c = wrapper.objectType,
            Direction__c = wrapper.direction,
            HTTP_Result_Code__c = httpResponseCode,
            Kong_Correlation_Header__c = wrapper.kongCorrelationId,
            Related_Record__c = primaryRecordId,
            Run_Duration__c = runDuration,
            //CMSI-8 : Added Support for Transaction Id & Org Id
            Transaction_Id__c = TID,
            Org_Id__c = ORGID,
            Json_Message__c = truncateToMaxLength(wrapper.jsonMessage, LOG_JSON_MESSAGE_DFR.getLength()),
            Result__c = result,
            Result_Details__c = truncateToMaxLength(fullResults, LOG_RESULT_DETAILS_DFR.getLength())
        );

        if (wrapper.isPersisted())
        {
            logRecord.Id = wrapper.logRecordId;
            return logRecord;
        }
        else
        {
            return logRecord;
        }
    }
}