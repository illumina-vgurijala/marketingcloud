/***************************************************************************************************************************************
* NAME         : ProactiveComponentController
* DESCRIPTION  : sending the Installed product and date information to fetch the runs and run metrics from proactive
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav         27 Oct                Modified saveMetrics method and added new fetchFeatureFlag method (CMCM-303)
****************************************************************************************************************************************/
public with sharing class ProactiveComponentController {
    
    public final static String SUCCESS_STRING = 'Success';
    public final static String FAILURE_STRING = 'Fail';
    public final static String STRING_CONTENT_TYPE = 'application/json';
    public final static String STRING_XCRF_TOKEN = 'x-csrf-token';
    public final static String GET_METHOD ='GET';
    public final static INTEGER MAX_TIMEOUT = 120000;
    public final static String INTERFACE_NAME = 'ProactiveRunMetrics';
    public  static String proactiveEndpointUrl;
    public  static String proactiveAPIKey;
    public final static String JSSTRING = 'jsonString';
    public final static String REQTYPE = 'Outbound';
    public final static String HISEQ = 'HiSeq';
    public final static String ISEQ = 'iSeq';
    public final static String MISEQ = 'MiSeq';
    public final static String MINISEQ = 'MiniSeq';
    public final static String NEXTSEQ500 = 'NextSeq 500/550';
    public final static String NOVASEQ = 'NovaSeq';
    public final static String NEXTSEQ1000 = 'NextSeq 1000/2000';
    public final static String GENOTYPING = 'MA Scanners';
    public final static String VALUE = 'value';
    public final static String INTERFACE_LOG_NAME = 'Proactive Run Metrics';
    
    
    
    
    public static List<ProactiveRunsReturnedWrapper> proactiveRunRetunrs = new List<ProactiveRunsReturnedWrapper>();
    
    /** @DESCRIPTION - Get Interface Parameter custom metadata information. **/
    public static void getProactiveMetadataInformation() {
        Map < String, String > mapInterfaceDetails = getBaseEnpointUrlFromCustomMetadata();
        proactiveEndpointUrl = mapInterfaceDetails.get('Endpoint');
        proactiveAPIKey = mapInterfaceDetails.get('ApiKey');
        
    }
    
    /** @DESCRIPTION - Get APIKey and Endpoint from Interface Parameters metadata **/
    public static Map < String, String > getBaseEnpointUrlFromCustomMetadata() {
        return UtilsRest.getIntegrationEndpoint(INTERFACE_NAME);
    }
    
    /**
*  @author Raviteja
*  @description To fetch the WorkOrder record information by passing Id
*  @param record Id
*  @return List of work order records
**/
    
    
    @AuraEnabled
    public static List<SVMXC__Service_Order__c> getWODetails(string strWoId) {
        try {
            
            return new WorkOrdersSelector().selectWorkOrders(new set<Id>{strWoId});
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
*  @author Raviteja
*  @description To fetch the case record information by passing Id
*  @param record Id
*  @return List of caes records
**/
    
    @AuraEnabled
    public static List<case> getCaseDetails(string strCaseId) {
        try {
            return new CasesSelector().selectCases(new set<Id>{strCaseId});
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
*  @AUTHOR Raviteja 
*  @DESCRIPTION - Initiate log object record.
*  @PARAM : InterfaceParaWrapper 
*  @RETURN : ilib_LogInterface.LogDetails
**/
    private static ilib_LogInterface.LogDetails getInterfaceLog(InterfaceParaWrapper intParaWrap) {
        
        //Interface Log
        ilib_RestInterface.InterfaceDetails intDetails = new ilib_RestInterface.InterfaceDetails(intParaWrap.interfaceName, intParaWrap.direction, intParaWrap.objectName);
        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(intDetails, intParaWrap.jsonString);
        ilib_LogInterface.addJsonToLog(log, intParaWrap.jsonString);
        return log;
        
    }
    
    /**
*  @author Raviteja
*  @description To fetch the runs based on the startdate ,endDate and Installed Product serial number
*  @params Startdate,EndDate & Installed Product Serial number
*  @return Serialized JSON string
**/
    
    @AuraEnabled
    public static String fetchRuns(String runsData) {
        system.debug('***runsData*'+runsData);
        HTTPResponse res = new HTTPResponse();
        FetchRunsWrapper runsWrap = new FetchRunsWrapper();
        
        runsWrap = (FetchRunsWrapper) System.JSON.deserialize(runsData,FetchRunsWrapper.class);
        try { 
            
            String startDate = runsWrap.sDate+'T00:00:00';
            String endDate = runsWrap.eDate+'T23:59:59';
            
            getProactiveMetadataInformation();
            system.debug('sDate->'+runsWrap.sDate+'eDate->'+runsWrap.eDate+'serialNumbers->'+runsWrap.serialNumbers);
            if(runsWrap.serialNumbers != '' && !String.isBlank(runsWrap.serialNumbers)) {
                
                HttpRequest request = createHttpRequest();
                request.setEndpoint(proactiveEndpointUrl+'run?toDate='+endDate+'&fromDate='+startDate+'&serialNumbers='+runsWrap.serialNumbers);
                system.debug('End point***'+request.getEndpoint());
                
                Http httpObj = new Http();
                res = httpObj.send(request);//Sending the request to fetch the runs with the request formed above
                system.debug('Response After API Change'+res);
            }
            if(res != NULL && res.getStatuscode() != NULL && !String.isBlank(res.getbody())) {
                system.debug('response status'+ res.getStatuscode()+'***'+res+res.getBody());
                InterfaceParaWrapper intParaWrap = new InterfaceParaWrapper();
                intParaWrap.jsonString = JSSTRING;
                intParaWrap.interfaceName = INTERFACE_LOG_NAME;
                intParaWrap.direction = REQTYPE;
                intParaWrap.objectName = runsWrap.objectName;
                
                if (res.getStatuscode() == 200 && res.getBody()!= NULL) {
                    system.debug('response successfully fetched'+res.getbody());
                    //log finalize method called (successful case)
                    ilib_LogInterface.finalizeLog(getInterfaceLog(intParaWrap), SUCCESS_STRING, res.getBody(), null, res);
                } else {
                    system.debug('response obtained'+res.getStatuscode());
                    //log finalize method called (failed case)
                    ilib_LogInterface.finalizeLog(getInterfaceLog(intParaWrap), FAILURE_STRING, res.getBody(), null, res); 
                }
                
                proactiveRunRetunrs = ProactiveRunsReturnedWrapper.parseRunsResponse(res.getBody());
                system.debug('*****'+proactiveRunRetunrs);
            }
            return JSON.serialize(proactiveRunRetunrs);
        } catch(Exception e) { 
            system.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
*  @author: Raviteja
*  @description: To fetch metrics of each run which is selected by the user on the UI
*  @params: Category,runId,Installed Product,Env,Id of the run
*  @return: metricWrapper
**/
    
    @AuraEnabled
    public static metricWrapper getRunMetrics(String runMetrics) {
        system.debug('***runMetrics*'+runMetrics);
        
        RunMetricsWrapper runMetricWrap = new RunMetricsWrapper();
        
        runMetricWrap = (RunMetricsWrapper) System.JSON.deserialize(runMetrics,RunMetricsWrapper.class);
        //string prCategory = '';
        
        
        try {
            HTTPResponse res = new HTTPResponse();
            map<string,string> lablesToMap = new map<string,string>();
            
            getProactiveMetadataInformation();
            
            system.debug('category**'+runMetricWrap.category+'runId'+runMetricWrap.runId+'*****'+runMetricWrap.isProactiveUpdate);
            //prCategory = handleCategory(runMetricWrap.category);
            
            
            HttpRequest request = createHttpRequest();
            
            request.setEndpoint(proactiveEndpointUrl+'run/'+runMetricWrap.Id+'/metrics?bsRunId='+runMetricWrap.runId+'&environment='+runMetricWrap.env+'&serialNumber='+runMetricWrap.serialNumber);
            
            system.debug('End point***'+request.getEndpoint());
            
            Http httpObj = new Http();
            res = httpObj.send(request);//Sending the request to fetch the metric information with the request formed above
            system.debug('response status'+ res.getStatuscode());
            InterfaceParaWrapper intParaWrap = new InterfaceParaWrapper();
            intParaWrap.jsonString = JSSTRING;
            intParaWrap.interfaceName = INTERFACE_LOG_NAME;
            intParaWrap.direction = REQTYPE;
            intParaWrap.objectName = runMetricWrap.objectName;
            
            if (res.getStatuscode() == 200 && res.getBody()!= NULL) {
                system.debug('response successfully fetched'+res.getbody());
                //log finalize method called (successful case)
                ilib_LogInterface.finalizeLog(getInterfaceLog(intParaWrap), SUCCESS_STRING, res.getBody(), null, res);
            } else {
                system.debug('response obtained'+res.getStatuscode());
                //log finalize method called (failed case)
                ilib_LogInterface.finalizeLog(getInterfaceLog(intParaWrap), FAILURE_STRING, res.getBody(), null, res); 
            }
            
            Map<String,Object> dataList =  (Map<String,Object>)System.Json.deserializeUntyped(res.getBody());
            system.debug('===dataList===='+dataList);
            //Fetching the metadata records based on the category of Installed Product to form a map 
            //which is used to display the run metrics on the UI dynamically
            if(!runMetricWrap.isProactiveUpdate) {    
                List<String> lstLabels = new List<String>();
                List<Proactive_Setting__mdt> jtmData = [Select id,Summary_Fields__c from Proactive_Setting__mdt where MasterLabel=: runMetricWrap.category limit 1];
                system.debug('jtmData***'+jtmData);
                if( jtmData!= null && !jtmData.isEmpty()) {
                    lstLabels = jtmData[0].Summary_Fields__c.split(',');
                }
                if(lstLabels!= NULL && !lstLabels.isEmpty()) {
                    for(String jtm : lstLabels ) { 
                        string str = '';
                        system.debug('***MetaData**'+jtm.split('-').get(0)+'***'+dataList.get(jtm.split('-').get(1)));            
                        if(string.valueof(dataList.get(jtm.split('-').get(1))) == null || 
                           string.valueof(dataList.get(jtm.split('-').get(1))) == NULL) {
                               system.debug('NULL Value check'+dataList.get(jtm.split('-').get(1)));
                               str = ' ';  
                           } else {
                               str = string.valueof(dataList.get(jtm.split('-').get(1)));
                           }
                        lablesToMap.put(jtm.split('-').get(0),str);
                    }
                }
            }
            //Forming the wrapper to be used on the UI 
            metricWrapper mWrap = new metricWrapper();
            mWrap.jsonRes = res.getBody();
            mWrap.lablesToMap = lablesToMap;
            mWrap.category = runMetricWrap.category;
            mWrap.proactiveLink = dataList.containsKey('proactiveLink')?String.valueOf(dataList.get('proactiveLink')):'';
            mWrap.statusCode = res.getStatuscode();
            return mWrap;
        } catch(Exception e) { 
            system.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    
    
    
    /**
*  @author: Raviteja
*  @description: To fetch the category of the selected installed product.
*                This fires when user selects a record in lookup drill down
*  @params: Installed Product Serial Number 
*  @return: String(Installed Product category)
**/
    
    @AuraEnabled
    public static SVMXC__Installed_Product__c getCategory(String serialNumbers) {
        SVMXC__Installed_Product__c iprec = new SVMXC__Installed_Product__c();
        try {
            
            if(!string.isBlank(serialNumbers)) { 
                List<SVMXC__Installed_Product__c> ipList = new List<SVMXC__Installed_Product__c>();
                ipList = new InstalledProductsSelector().selectIPForSerialNumber(serialNumbers);
                system.debug('Product category'+ipList[0].SVMXC__Product__r.Product_Category__c);
                if(ipList[0].SVMXC__Product__r!= NULL && !ipList.isEmpty() && ipList[0].SVMXC__Product__r.Product_Category__c != '' && ipList[0].Proactive_Connectivity_Status__c != '') {
                    return ipList[0];
                }
            }
            return iprec;
        } catch(Exception e) { 
            system.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    /**
*  @author: Raviteja
*  @description: Method to save the metrics information into Proactive and case line objects
*  @params: Json response of the selected run, Installed Product Category,Current Record Id
*  @return: String(Success or Fail)
*  @Modified: SaveMetrics to remove feature flag condition cmcm-7774 
**/  
    @AuraEnabled
    public static String saveMetrics(String saveRunMetrics) {
        system.debug('saveRunMetrics***'+saveRunMetrics);
        String status = '';
        SaveMetricRunWrapper saveRunWrapper = new SaveMetricRunWrapper();
        saveRunWrapper = (SaveMetricRunWrapper) System.JSON.deserialize(saveRunMetrics, SaveMetricRunWrapper.class);
        try {
            system.debug('Entered Save');
            
            ProactiveRunMetricsWrapper sWrap = new ProactiveRunMetricsWrapper();
            sWrap = (ProactiveRunMetricsWrapper) System.JSON.deserialize(saveRunWrapper.jsonRes, ProactiveRunMetricsWrapper.class);
            system.debug('====sWrap===' + sWrap);
            
            if(saveRunWrapper.category == GENOTYPING) { 
                status = ProactiveMetricHandlingController.handleGenotyping(sWrap,saveRunWrapper);
            } else {
                    status = ProactiveMetricHandlingController.handleProactiveAssociatedProductDML(sWrap,saveRunWrapper);
                    status = ProactiveMetricHandlingController.handleProactiveCaseLineDML(sWrap,saveRunWrapper);
            }
            
            return status;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
*  @author: Raviteja
*  @description: Method to form the list of additional product records
**/
    
    
    @AuraEnabled
    public static List < additionalProdWrapper > fetchAdditionalProducts(String jsonRes, String category) {
        system.debug('jsonRes:::'+jsonRes+'@@@@'+category);
        List < String > lstStr = new List < String > ();
        List < additionalProdWrapper > aprWrapList = new List < additionalProdWrapper > ();
        String prCategory = '';
        
        prCategory = handleCategory(category);
        Map < String, Object > dataList = (Map < String, Object > ) System.Json.deserializeUntyped(jsonRes);
        system.debug('dataList:::'+dataList+'@@@prCategory'+prCategory);
        Set<String> setCodeParamName = new Set<String>{prCategory};
            List<Code_Parameter__mdt> adPrData=new CodeParametersSelector().selectCodeParameterByDeveloperName(setCodeParamName);
        if(!adPrData.isEmpty()) {
            lstStr = adPrData[0].Value__c.split('-');
            
        }
        system.debug('lstStr:::'+lstStr+'@@@adPrData'+adPrData+'####');
        try {
            for (String str: lstStr) {
                additionalProdWrapper aprUIWrap = new additionalProdWrapper();
                aprUIWrap.selected =  TRUE;
                List < String > items = str.split(',');
                
                system.debug('^^^' + str);
                system.debug('####' + items);
                for (String apr: items) {
                    
                    system.debug('%%%%%' + apr);
                    if(category == HISEQ) {
                        if (apr.contains('Serial') && dataList.containsKey(apr)) {
                            ilib_LogEvent.message('debugging'+dataList.get(apr));
                            if(dataList.get(apr)!= null) {
                                ilib_LogEvent.message('Times products getting formed');
                                aprUIWrap.serialNumber = String.valueOf(dataList.get(apr));
                                //aprWrapList.add(aprUIWrap);
                            }
                        }
                    } else {
                        
                        if (apr.contains('Serial') && dataList.containsKey(apr)) {
                            system.debug('$$$$$$' + apr);
                            system.debug('dataList.get(apr):::'+dataList.get(apr));
                            if(dataList != null && dataList.get(apr) != null) {
                                Object obj = dataList.get(apr);
                                if(obj instanceof String) {
                                    aprUIWrap.serialNumber = String.valueOf(dataList.get(apr));
                                } else {
                                    map<String,Object> mapObj = (map<String,Object>)dataList.get(apr);
                                    aprUIWrap.serialNumber = string.valueof(mapObj.get(VALUE));
                                }
                            }
                            system.debug('aprUIWrap.serialNumber::::'+aprUIWrap.serialNumber);
                        } else if(apr.contains('Part') && dataList.containsKey(apr)) {
                            if(dataList != null && dataList.get(apr) != null) {
                                Object obj = dataList.get(apr);
                                if(obj instanceof String) {
                                    aprUIWrap.partNumber = String.valueOf(dataList.get(apr));
                                } else {
                                    map<String,object> mapObj = (map<String,object>)dataList.get(apr);
                                    aprUIWrap.partNumber = string.valueof(mapObj.get(VALUE));
                                }
                            }
                            system.debug('*****PartNum**-' + aprUIWrap.partNumber);
                            
                        } else if(apr.contains('Lot') && dataList.containsKey(apr)) {
                            if(dataList != null && dataList.get(apr) != null) {
                                Object obj = dataList.get(apr);
                                if(obj instanceof String) {
                                    aprUIWrap.lotNumber = String.valueOf(dataList.get(apr));
                                } else {
                                    map<String,object> mapObj = (map<String,object>)dataList.get(apr);
                                    aprUIWrap.lotNumber = string.valueof(mapObj.get(VALUE));
                                }
                                
                                system.debug('*****lotNum**-' + aprUIWrap.lotNumber);
                            }
                        } else if(apr.contains('Expiration') && dataList.containsKey(apr)) {
                            map<String,object> mapObj = (map<String,object>)dataList.get(apr);
                            aprUIWrap.expirationDate = string.valueOf(mapObj.get(VALUE)).split('T')[0];
                            aprUIWrap.expired = boolean.valueOf(mapObj.get('expired'));
                            system.debug('*****expDate**-' + aprUIWrap.expirationDate);
                            
                        }
                        
                    }
                    
                }
                if(aprUIWrap.serialNumber != NULL) {// Added this condition to avoid products with null values
                    aprWrapList.add(aprUIWrap);
                }
            }
            system.debug('aprWrapList*****' + aprWrapList);
            system.debug('***size*****' + aprWrapList.size());
            return aprWrapList;
        } catch(Exception e) {
            ilib_LogEvent.message(e.getStackTraceString());
            //return new List < additionalProdWrapper >();
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    
    
    /**
*  @author: Raviteja
*  @description:Wrapper to hold the metric response, Map to display metrics of each run,
*                category of IP,Proactive Link obtained in the metrics response,response status code
**/
    
    
    public class additionalProdWrapper {
        
        @AuraEnabled public boolean selected;
        @AuraEnabled public string serialNumber;
        @AuraEnabled public string partNumber;
        @AuraEnabled public string lotNumber;
        @AuraEnabled public string expirationDate;
        @AuraEnabled public boolean expired;        
    }
    
    /**
*  @author: Raviteja
*  @description: Method to change the category value as needed to fetch the metadata records 
**/
    
    public static string handleCategory(String category) {
        
        String proCategory = '';
        if(category != '' && category != NULL) {
            if(category.contains('NextSeq 500')) {
                proCategory = 'NextSeq_500_550';
            } else if(category.contains('NextSeq 1000')) {
                proCategory = 'NextSeq_1000_2000';   
            } else if(category.contains('HiSeq')) {
                proCategory = 'HiSeq'; 
            } else if(category.contains('NovaSeq X')) {
                proCategory = 'NovaSeq_X_Series'; 
            } else {
                proCategory = category;
            }
        }
        return proCategory;
    }
    
    /**
*  @author: Raviteja
*  @description: Method to fetch the Proactive Run Detail record
**/
    
    @AuraEnabled(cacheable=true)
    public static List<Proactive_Run_Detail__c> fetchProactiveRunDetailRec(id prdId) {
        
        try {
            system.debug('prdId'+prdId);
            
            return new ProactiveRunDetailSelector().selectPRDRec(prdId);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
*  @author: Raviteja
*  @description: Method to fetch the Proactive Run Detail record
**/
    
    public static HttpRequest createHttpRequest() {
        HttpRequest request = new HttpRequest();
        request.setHeader('apikey',proactiveAPIKey);
        request.setHeader('accept',STRING_CONTENT_TYPE);
        request.setHeader('content-type',STRING_CONTENT_TYPE);
        request.setTimeout(MAX_TIMEOUT);
        request.setMethod(GET_METHOD);
        return request;
    }

    /**
*  @author: Raviteja
*  @description: Wrapper to hold interface parameters to fetch the End point and API Key 
**/
    
    public class InterfaceParaWrapper {
        
        @AuraEnabled public string jsonString;
        @AuraEnabled public string interfaceName;
        @AuraEnabled public string direction;
        @AuraEnabled public string objectName;
        
    }
    
    /**
*  @author: Raviteja
*  @description:Wrapper to hold the metric response, Map to display metrics of each run,
*                category of IP,Proactive Link obtained in the metrics response,response status code
**/
    
    public class metricWrapper {
        @AuraEnabled public string jsonRes;
        @AuraEnabled public Map<string,string> lablesToMap;
        @AuraEnabled public string category;
        @AuraEnabled public string proactiveLink;
        @AuraEnabled public Integer statusCode;
        
    }
    
    /**
*  @author: Raviteja
*  @description:Wrapper to hold the parameters from UI to fetch the runs from proactive system.
**/
    
    public class FetchRunsWrapper {
        @AuraEnabled public string sDate;
        @AuraEnabled public string eDate;
        @AuraEnabled public string serialNumbers;
        @AuraEnabled public string objectName;
        
    }
    
    /**
*  @author: Raviteja
*  @description: Wrapper to hold the parameters from UI to fetch the Metrics of the each run selected from the RUNS on UI.
**/
    public class RunMetricsWrapper {
        @AuraEnabled public string category;
        @AuraEnabled public string runId;
        @AuraEnabled public string serialNumber;
        @AuraEnabled public string env;
        @AuraEnabled public string id;
        @AuraEnabled public string objectName;
        @AuraEnabled public boolean isProactiveUpdate;
        
        
    }
    
    /**
*  @author: Raviteja
*  @description: Wrapper to hold the parameters from UI to fetch the Metrics of the each run selected from the RUNS on UI.
**/
    public class SaveMetricRunWrapper {
        
        @AuraEnabled public string jsonRes;
        @AuraEnabled public string category;
        @AuraEnabled public string recordId;
        @AuraEnabled public string runNotes;
        @AuraEnabled public string ipId;
        @AuraEnabled public string selectedRecords;
        @AuraEnabled public string id;
        @AuraEnabled public string env;
        @AuraEnabled public string serialNumber;
        @AuraEnabled public string readLength;
        @AuraEnabled public Date runStartDate;
        @AuraEnabled public Date runEndDate;
        @AuraEnabled public string runStatus;
        @AuraEnabled public boolean isProactiveUpdate;
        @AuraEnabled public string runName;
        
        
    }
    
}