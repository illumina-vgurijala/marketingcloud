/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  HTTP Request handler class for knowledge sync
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class KnowledgeArticleICESyncConnector{
    public static final String CONTENT_TYPE = 'application/x-www-form-urlencoded';
    public static final String APPLICATION_TYPE = 'application/json';
    public static final String ICE_SCOPE = 'seismic.reporting seismic.library.view';
    public static final Integer HTTP_POST_SUCCESS_CODE = 201;
    public static final Integer HTTP_SUCCESS_CODE = 200;
    public static final String ERROR = 'ERROR';
    public static ilib_LogInterface.LogDetails log;
    public static final String CODEPARAMETERNAME_ICE_URL = 'Knowledge_ICE_URL_Content_Profile_Id'; 
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   method to get access token from ICE
     */
    public static string getAccessToken(String strInterfaceDetailMessage,Boolean isLogging){
        KnowledgeArticleICESyncEmailHandler instantiated = new KnowledgeArticleICESyncEmailHandler();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        log = ilib_LogInterface.initiateLog(interfaceDetails, strInterfaceDetailMessage);
        Interface_Parameters__mdt connectionParameters = UtilsRest.getConnectionParameters('ICE_Integration');
        List<String> lstIntegrationDetails = connectionParameters.ApiKey__c.split('\\|');
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'Content-Type' => CONTENT_TYPE
        };
        HttpRequest objReq = UtilsRest.createHttpRequest('ICE_Authorization','POST',headerKeyToValue);
        String payload = 'Client_Id='+EncodingUtil.urlEncode(lstIntegrationDetails[0],'UTF-8')+'&Client_Secret='+EncodingUtil.urlEncode(lstIntegrationDetails[1],'UTF-8')+'&Grant_Type=password&Scope='+EncodingUtil.urlEncode(ICE_SCOPE,'UTF-8')+'&Username={!HTMLENCODE($Credential.Username)}&Password={!HTMLENCODE($Credential.Password)}';
        objReq.setBody(payload);
        system.debug('Request--->'+objReq);
        System.debug('Payload -->'+payload);
        HttpResponse response = Test.isRunningTest() ? MockHTTPCalloutKnowledgeSyncService.respondMock('Auth') : new Http().send(objReq);  
        if(response.getStatusCode() != HTTP_SUCCESS_CODE){
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() +response.getStatusCode());
            ApexExceptions.emit('KnowledgeArticleICESyncEmailHandler',log.logRecordId,response.getBody());
            return ERROR;
        }
        else{
            System.debug(response.getBody());
            Map<String, Object> mapResponseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            System.debug('Token-->'+(String)mapResponseBody.get('access_token'));
            if(isLogging)
                ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, response.getBody() +response.getStatusCode());
            return (String)mapResponseBody.get('access_token');
        }
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   method to fetch file content from ICE
     */
    public static KnowledgeSyncWrapper.FileContent fetchFileContent(String strAccessToken,String strTeamSiteId,String strContentId){
        BatchKnowledgeArticleICESync instantiated = new BatchKnowledgeArticleICESync();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'Accept' => APPLICATION_TYPE,
            'Authorization' => 'Bearer '+strAccessToken
        };
        String strResourceURL = '/teamsites/'+strTeamSiteId+'/items/'+strContentId;
        HttpRequest objReq = UtilsRest.createHttpRequest('ICE_Integration_API',strResourceURL,'GET',headerKeyToValue);
        log = ilib_LogInterface.initiateLog(interfaceDetails,'ICE Integration Fetch Content Details : '+strResourceURL);
        HttpResponse response = Test.isRunningTest() ? MockHTTPCalloutKnowledgeSyncService.respondMock('FetchFile'):new Http().send(objReq);
        System.debug('File content-->'+response.getBody());
        if(response.getStatusCode() != HTTP_SUCCESS_CODE){
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() +response.getStatusCode());
            ApexExceptions.emit('BatchKnowledgeArticleICESync',log.logRecordId,response.getBody());
            return null;
        }
        else{
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, response.getBody() +response.getStatusCode());
            return (KnowledgeSyncWrapper.FileContent)JSON.deserialize(response.getBody(),KnowledgeSyncWrapper.FileContent.class);
        }
    }
    /**
     * @author Adyasha
     * @date    4-Jan-2021
     * @description   method to fetch content Profile ID,Content Library ID from ICE
     */
    public static List<KnowledgeSyncWrapper.ContentDetails> fetchContentDetails(String strAccessToken){
        BatchKnowledgeArticleICESync instantiated = new BatchKnowledgeArticleICESync();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        Map<String, String> headerKeyToValue = new Map<String, String>{
            'Accept' => APPLICATION_TYPE,
            'Authorization' => 'Bearer '+strAccessToken
        };
        List<Code_Parameter__mdt> lstCodeParameterURL = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODEPARAMETERNAME_ICE_URL});
        String strContentProfileId = Test.isRunningTest() ? '2c5e01d0-eb04-4cb2-8d92-258ae8a44865' : lstCodeParameterURL[0].Value__c;
        String strResourceURL = '/contentProfileAssignments?contentProfileId='+strContentProfileId;
        HttpRequest objReq = UtilsRest.createHttpRequest('ICE_Reporting_API',strResourceURL,'GET',headerKeyToValue);
        log = ilib_LogInterface.initiateLog(interfaceDetails,strResourceURL);
        HttpResponse response = Test.isRunningTest() ? MockHTTPCalloutKnowledgeSyncService.respondMock('FetchContentDetail'):new Http().send(objReq);
        System.debug('---@ADResponse->' +response.getBody());
        if(response.getStatusCode() != HTTP_SUCCESS_CODE){
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_FAIL, response.getBody() +response.getStatusCode());
            ApexExceptions.emit('ScheduledBatchKnowledgeArchiveICERecords',log.logRecordId,response.getBody());
            return new List<KnowledgeSyncWrapper.ContentDetails>();
        }
        else{
            ilib_LogInterface.finalizeLog(log,ilib_LogInterface.RESULT_SUCCESS, response.getBody());
            return (List<KnowledgeSyncWrapper.ContentDetails>)JSON.deserialize(response.getBody(),List<KnowledgeSyncWrapper.ContentDetails>.class);
        } 
    }
}