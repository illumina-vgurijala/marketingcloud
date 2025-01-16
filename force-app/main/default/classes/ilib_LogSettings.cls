/**
*    @author Illumina   
*    @date          
*    @description   Log settings class to return the metadata settings
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Pranay                      06-May-2022       CMSI-2 : Feature flag driven architecture 
*/

public with sharing class ilib_LogSettings implements Metadata.DeployCallback {
	
    private static final String LOG_TITLE = 'ilib_LogSettings';

    // only used during unit testing
    public static PS_Log_Setting__mdt unitTestSettingsRecord;
    public static Code_Parameter__mdt unitTestRecordCodeParam;

    // record/table names for queries and updates
    // private static final String METADATA_TABLE_NAME = 'PS_Log_Setting__mdt';
    private static final String METADATA_TABLE_NAME = 'Code_Parameter__mdt';
    public static final String CONFIG_RECORD_NAME = 'PS_Log_Settings';
    public static final String CONFIG_RECORD_LABEL = 'PS Log Settings';
    // private static final String PAUSE_DATETIME_FIELD = 'Pause_Publishes_Until__c';
    private static final String PAUSE_DATETIME_FIELD = 'Values_Text__c';
    
   

    // abstract the setting values for readability in client classes
    public Boolean disableAllPersistence { get; private set; }
    public Boolean disableSlowQueryPersistence { get; private set; }
    public Boolean disableSlowTransactionPersistence { get; private set; }
    public Decimal slowQueryThreshold { get; private set; }
    public Decimal slowTransactionThreshold { get; private set; }
    public Decimal publishPercentThreshold { get; private set; }
    public Datetime pausePublishesUntil { get; private set; }
    public Integer lineCountCap { get; private set; }
    public Integer lineLengthCap { get; private set; }

    //CMSI-2
    public Decimal heapSizeThreshold { get; private set; }
    public Decimal cpuTimeThreshold { get; private set; }
    public Decimal defCheckInterval { get; private set; }    
    public String defPSlogSetting { get; private set; }
    public Boolean restInterface { get; private set; }
    public Boolean apex { get; private set; }
    public Boolean queueable { get; private set; }
    public Boolean batchable { get; private set; }
    public ilib_LogEvent.Level level { get; private set; }
    public String interfaceClass { get; private set; }
    private static Map<String,String> codeParamDefaultValues = new Map<String,String>();
    public static final String METADATA_CONFIG_RECORD_NAME = 'PSLogSetting';
    public static final String METADATA_CONFIG_RECORD_LABEL = 'PSLogSetting';

    /**
     * @author Illumina
     * @description Constructor for base class
     */
    public ilib_LogSettings()
    {
        // start with defaults
        // in case an unreasonable value was configured
        disableAllPersistence = false;
        disableSlowQueryPersistence = false;
        disableSlowTransactionPersistence = false;
        slowQueryThreshold = 3.0;
        slowTransactionThreshold = 8.0;
        publishPercentThreshold = 75;
        pausePublishesUntil = null;
        lineCountCap = 1000;
        lineLengthCap = 1000;

        //CMSI-2
        heapSizeThreshold = 50.00;
        cpuTimeThreshold = 50.00;
        defCheckInterval=500;
        apex = true;
        restInterface = false;
        queueable = false;
        batchable =false;
        //get code param default values and set default values
        ilib_LogEvent.loggingUserId = UserInfo.getUserId();
        queryCodeParam();
        if(!codeParamDefaultValues.isEmpty()){
            setDefaultValues();
        }
        setConfiguredValues();
        ilib_LogEvent.setLogLevel(level);
    }

    /**
     * @author Illumina
     * @description called by IlmnLogs when publish threshold is exceeded
     * @param Datetime newval
     */
    public static void updateMetadataPauseDate(Datetime newval)
    {
        ilib_LogEvent.push('updateMetadataPauseDate');
        
        //CMSI-2 Changes
        codeParamDefaultValues.put('SwtchOffLogngUntl',String.valueOf(newval));
        String updatedTextValue = '';
        for(String key: codeParamDefaultValues.keySet()){
            updatedTextValue += key + ':' + codeParamDefaultValues.get(key)+';';
        }
        updatedTextValue = updatedTextValue.removeEnd(';');
        try
        {
            // represent new date and add it to metadata row
            Metadata.CustomMetadataValue customField1 = new Metadata.CustomMetadataValue();
            customField1.field = PAUSE_DATETIME_FIELD;
            customField1.value = updatedTextValue;
            ilib_LogEvent.message('Metadata field ' + customField1);

            // represent metadata row with field
            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = METADATA_TABLE_NAME + '.' + METADATA_CONFIG_RECORD_NAME;
            customMetadata.label = METADATA_CONFIG_RECORD_LABEL;
            customMetadata.values.add(customField1);
            ilib_LogEvent.message('Metadata object ' + customMetadata);

            // prepare row for deployment
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadata);
            ilib_LogEvent.message('Metadata container ' + mdContainer);

            // schedule deployment
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, new ilib_LogSettings());
            ilib_LogEvent.message('Deploy job Id ' + jobId);
        }
        catch (Exception e)
        {
            ApexExceptions.emit(LOG_TITLE + '.updateMetadataPauseDate', e, ilib_LogEvent.getWorkstream());
        }

        ilib_LogEvent.pop();
    }

    /**
     * @author Illumina
     * @description Required by Metadata.DeployCallback handle results of metadata deployment
     * @param Metadata.DeployResult result, Metadata.DeployCallbackContext context
     */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context)
    {
        ilib_LogEvent.setTitle(LOG_TITLE);
        ilib_LogEvent.push('handleResult');

        if (result.status == Metadata.DeployStatus.SUCCEEDED)
        {
            ilib_LogEvent.message('all good: '+ result);
        }
        else
        {
            ilib_LogEvent.message('error: '+ result);
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }


    /**
     * @author Illumina
     * @description Method to set configured values of metadata
     */
    private void setConfiguredValues()
    {
        PS_Log_Setting__mdt config = query();
        if (config == null) return;

        disableAllPersistence = config.Disable_All_Log_Persistence__c;
        disableSlowQueryPersistence = config.Disable_Slow_Query_Publish__c;
        disableSlowTransactionPersistence = config.Disable_Slow_Transaction_Publish__c;
        slowQueryThreshold = config.Slow_Query_Threshold__c;
        slowTransactionThreshold = config.Slow_Transaction_Threshold__c;
        publishPercentThreshold = config.Publish_Percent_Threshold__c;
        lineCountCap = Integer.valueOf(config.Line_Count_Cap__c);
        lineLengthCap = Integer.valueOf(config.Line_Length_Cap__c);

        //CMSI-2
        heapSizeThreshold = config.Heap_Size_Threshold__c;
        cpuTimeThreshold =config.Cpu_Time_Threshold__c;

        restInterface = config.Interface__c;
        apex = config.Apex__c;
        queueable = config.Queueable__c;
        batchable = config.Batchable__c;
        if(config.Log_Level__c != null){
            level = ilib_LogEvent.Level.valueOf(config.Log_Level__c);
        }
        interfaceClass = config.Interface_Class__c;
        defCheckInterval = Decimal.valueOf(config.Limits_Check_Interval__c);
    }

    @TestVisible
    private PS_Log_Setting__mdt query()
    {
        // unit tests need to be able to control the config values
        if (Test.isRunningTest() && unitTestSettingsRecord != null && unitTestRecordCodeParam == null )
        {
            return unitTestSettingsRecord;
        }
        
        //CMSI-2
        Map<String,PS_Log_Setting__mdt> configs = new Map<String,PS_Log_Setting__mdt>();
        List<PS_Log_Setting__mdt> psLogSettingsData = [SELECT Id, MasterLabel, DeveloperName,
                        Disable_All_Log_Persistence__c, Disable_Slow_Query_Publish__c, Disable_Slow_Transaction_Publish__c,
                        Slow_Query_Threshold__c, Slow_Transaction_Threshold__c, Publish_Percent_Threshold__c,
                        Line_Count_Cap__c, Line_Length_Cap__c, Heap_Size_Threshold__c,
                        Cpu_Time_Threshold__c, Log_Level__c, Apex__c, Interface__c, Queueable__c, 
                        Batchable__c, Interface_Class__c, Limits_Check_Interval__c
                    FROM PS_Log_Setting__mdt limit 1000
                ];
        
        if(!psLogSettingsData.isEmpty()){
            for(PS_Log_Setting__mdt psLogObj:psLogSettingsData){
                configs.put(psLogObj.DeveloperName, psLogObj);
            }          

            if(ilib_LogEvent.apexSettings == null)
                ilib_LogEvent.getApexSetting();
            
            String psLogSettingName = ilib_LogEvent.apexSettings.PS_Log_Setting__c;

            if(configs.containsKey(psLogSettingName)){
                return configs.get(psLogSettingName);
            } else if(configs.containsKey(defPSlogSetting)){
                return configs.get(defPSlogSetting);
            }
        }
        
        return null;
    }

    //CMSI-2
    /**
     * @author Pranay
     * @description CMSI 2- Method to get default values set in the code params metadata
     */
    private void queryCodeParam(){

        List<String> codeParamDataValuesText = new List<String>();
		if (Test.isRunningTest() && unitTestRecordCodeParam != null){
            codeParamDataValuesText = unitTestRecordCodeParam.Values_Text__c.split(';');
        }else{
            List<Code_Parameter__mdt> codeParamData = [SELECT Id, MasterLabel, DeveloperName,
                Values_Text__c, Value__c, PickListValue__c
                FROM Code_Parameter__mdt
                Where DeveloperName = :METADATA_CONFIG_RECORD_NAME
            ];

            codeParamDataValuesText= codeParamData[0].Values_Text__c.split(';');
        }

        for(String ls : codeParamDataValuesText){
            List<String> temp = ls.split(':',2);
            codeParamDefaultValues.put(temp[0],temp[1]);
        }
    }

    //CMSI-2
     /**
     * @author Pranay
     * @description CMSI -2 Method to set default values from the code param metadata
     */
    private void setDefaultValues() {

        if (codeParamDefaultValues.get('SwtchOffLogngUntl') != null){
            Datetime defSwitchOffLoggingTime = Datetime.valueOf(codeParamDefaultValues.get('SwtchOffLogngUntl').trim());
            if (Datetime.now() < defSwitchOffLoggingTime){
                pausePublishesUntil = defSwitchOffLoggingTime;
            }
        }
        defPSlogSetting = codeParamDefaultValues.get('defPSSetng');
        // only accept config values if set withing reasonable thresholds
        slowQueryThreshold = Decimal.valueOf(codeParamDefaultValues.get('SlwQryTh').trim());
        slowTransactionThreshold = Decimal.valueOf(codeParamDefaultValues.get('SlwTranxTh').trim());
        publishPercentThreshold = Decimal.valueOf(codeParamDefaultValues.get('PubPerTh').trim());
        lineCountCap = Integer.valueOf(codeParamDefaultValues.get('LneCntCap').trim());
        lineLengthCap = Integer.valueOf(codeParamDefaultValues.get('LneLngthCap').trim());
        
        heapSizeThreshold = Decimal.valueOf(codeParamDefaultValues.get('heapTh').trim());
        cpuTimeThreshold = Decimal.valueOf(codeParamDefaultValues.get('cpuTh').trim());
        level = ilib_LogEvent.Level.DEBUG;
        interfaceClass = codeParamDefaultValues.get('IntrfcCls');
        defCheckInterval = Decimal.valueOf(codeParamDefaultValues.get('DefChkInt').trim());
    }
}