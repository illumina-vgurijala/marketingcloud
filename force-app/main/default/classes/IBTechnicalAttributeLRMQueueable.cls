/***************************************************************************************************************************************
* NAME         : IBTechnicalAttributeLRMQueueable
* DESCRIPTION  : DCP-54367 : This class will be called from Installed Product Trigger to set the default values for LRM Patch Applied Technical Attributes
*                    
* @AUTHOR : Sagar Madkaikar
* @DATE   : 08-07-2020 
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Sagar Madkaikar         20-07-2022           DCP-54367 Initial Version.  

****************************************************************************************************************************************/

public with sharing  class IBTechnicalAttributeLRMQueueable implements Queueable, Database.AllowsCallouts  {

    String strMethodtoExecute;
    Set<String> setPrdFamily = new Set<String>();
    Set<String> setPrdFamilyTemplate = new Set<String>();
    Set<Id> setInstalledProductIds = new Set<Id>();
    Map<String,Set<String>> mapOfTemplateNameWithAttributes = new Map<String,Set<String>>();
    List<SVMXC__SM_IB_Attributes_Template_Instance__c> lstTemplateInstanceToInsert;
    List<SVMXC__SM_IB_Attributes_History__c> lstAttributeHistoryToInsert = new List<SVMXC__SM_IB_Attributes_History__c>();
    Map<String,String> mapofTemplateNameWithLoadedJSON = new Map<String,String>();
    Map<String,Id> mapofTemplateNameWithTemplateId = new Map<String,Id>();

    public static final String LRM_CODE_PARAM_NAME = 'LRM_Patch_Product_Family_List';
    public static final String LOG_TITLE = 'IBTechnicalAttributeLRMQueueable';
    public static final String TEXT_TEMPLATE =' Template';
    public static final String TA_LRM_PATCH_APPLIED = '2022 LRM Patch Applied?';
    public static final String TA_LRM_PATCH_APPLIED_RUO = '2022 LRM Patch Applied (RUO)?';
    public static final String TA_LRM_PATCH_APPLIED_DX ='2022 LRM Patch Applied (Dx)?';
    public static final String TXT_TRUE ='true';
    public static final String TXT_FALSE ='false';
    public static final String TEXT_TECHNICAL ='TECHNICAL';
    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Constructor
     *  @DATE - 20-Jul-2022 
     *  @PARAM : String strMethodtoExecute, Set<SVMXC__Installed_Product__c> setInstalledProductIds
     *  @RETURN : NA
     **/
    public IBTechnicalAttributeLRMQueueable(String strMethodtoExecute, Set<Id> setInstalledProductIds) {

        this.strMethodtoExecute=strMethodtoExecute;
        this.setInstalledProductIds=setInstalledProductIds;

        //create Product Family set and Template Name set
        List<Code_Parameter__mdt> lstLRMCodeParam= new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{LRM_CODE_PARAM_NAME});
        List<String> lstPrdFamily = lstLRMCodeParam.get(0).Values_Text__c.split(',');
        setPrdFamily.addAll(lstPrdFamily);
        for(String prdFamily:setPrdFamily){
            setPrdFamilyTemplate.add(prdFamily+TEXT_TEMPLATE);
            //Populate mapOfTemplateNameWithAttributes
            populateMapOfTemplateNameWithAttributes(lstLRMCodeParam.get(0).Value__c);
        }

    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Execute Method of Queueable
     *  @DATE - 20-Jul-2022 
     *  @PARAM : QueueableContext qc
     *  @RETURN : NA
     **/
    public void execute(QueueableContext qc) 
    {
        List<SVMXC__Installed_Product__c> listIPRecordsWithFamily = new List<SVMXC__Installed_Product__c>();


        ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SERVICE);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');

        try {
            ilib_LogEvent.info(LOG_TITLE+':setInstalledProductIds='+setInstalledProductIds);

            //Get IP records and check if Product Family is present in the setPrdFamily.
            for(SVMXC__Installed_Product__c ipRec : new InstalledProductsSelector().getIPWithAttributeTemplateInstance(setInstalledProductIds)){
                if(ipRec.SVMXC__Product__r.Family!=null && setPrdFamily.contains(ipRec.SVMXC__Product__r.Family)){
                    listIPRecordsWithFamily.add(ipRec);
                }
            }
            
            ilib_LogEvent.info(LOG_TITLE+':listIPRecordsWithFamily='+listIPRecordsWithFamily);

            if(strMethodtoExecute=='insertTAInstanceOnIPCreation' && !listIPRecordsWithFamily.IsEmpty())
            {
                insertTAInstanceOnIPCreation(listIPRecordsWithFamily);
            }
            else if (strMethodtoExecute=='updateTAInstanceOnIPProductChange' && !listIPRecordsWithFamily.IsEmpty()) {
                updateTAInstanceOnIPProductChange(listIPRecordsWithFamily);
            }

            //Create History Records
            if(!lstAttributeHistoryToInsert.isEmpty()){
                insert lstAttributeHistoryToInsert;
            }

        } catch (Exception ex) {
            ilib_LogEvent.info(LOG_TITLE+':ex='+ex);
            ApexExceptions.emit(ex, LOG_TITLE, listIPRecordsWithFamily);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This method is called when new IP is getting created. It will create a new Attribute Instance record with default LRM value=true
     *  @DATE - 20-Jul-2022 
     *  @PARAM : List<SVMXC__Installed_Product__c> listIPRecordsWithFamily
     *  @RETURN : NA
     **/
    private void insertTAInstanceOnIPCreation(List<SVMXC__Installed_Product__c> listIPRecordsWithFamily) 
    {
        ilib_LogEvent.push(LOG_TITLE + '.insertTAInstanceOnIPCreation()');
        lstTemplateInstanceToInsert = new List<SVMXC__SM_IB_Attributes_Template_Instance__c>();
        //Get TA Template Records for Product Families
        for(SVMXC__SM_Attributes_Template__c objTemplate : new SMAttributesTemplateSelector().getAttributesTemplateByTitle(setPrdFamilyTemplate)){
            ilib_LogEvent.info(LOG_TITLE+':objTemplate.SVMXC__SM_Template_Json__c='+objTemplate.SVMXC__SM_Template_Json__c);
            String templateJSON = populateLRMFIelds(objTemplate.SVMXC__SM_Template_Json__c,objTemplate.SVMXC__SM_Title__c,false);
            //mapofTemplateNameWithLoadedJSON to store Template Title/Product Family with respective JSON body.
            mapofTemplateNameWithLoadedJSON.put(objTemplate.SVMXC__SM_Title__c,templateJSON);
            ilib_LogEvent.info(LOG_TITLE+':mapofTemplateNameWithLoadedJSON='+mapofTemplateNameWithLoadedJSON);

            mapofTemplateNameWithTemplateId.put(objTemplate.SVMXC__SM_Title__c,objTemplate.Id);
            ilib_LogEvent.info(LOG_TITLE+':mapofTemplateNameWithTemplateId='+mapofTemplateNameWithTemplateId);
        }

        //iterate IP records to create SVMXC__SM_IB_Attributes_Template_Instance__c 
        for (SVMXC__Installed_Product__c ipRec : listIPRecordsWithFamily) {
            if(!mapofTemplateNameWithLoadedJSON.isEmpty() && !mapofTemplateNameWithTemplateId.isEmpty()) {
                lstTemplateInstanceToInsert.add(new SVMXC__SM_IB_Attributes_Template_Instance__c(SVMXC__SM_Attr_Payload__c=mapofTemplateNameWithLoadedJSON.get(ipRec.SVMXC__Product__r.Family+TEXT_TEMPLATE),
                                                                                                SVMXC__SM_Installed_Product_Id__c = ipRec.Id,
                                                                                                SVMXC__SM_Instance_Template_Id__c=mapofTemplateNameWithTemplateId.get(ipRec.SVMXC__Product__r.Family+TEXT_TEMPLATE),
                                                                                                SVMXC__SM_Attr_Type__c=TEXT_TECHNICAL,
                                                                                                SVMXC__SM_Captured_On__c=System.now(),
                                                                                                Serial_Lot_Number__c = ipRec.SVMXC__Serial_Lot_Number__c
                                                                                                ));
                //Create Attribute History Record. Pass JSONPayload and IP record Id                                                                    
                lstAttributeHistoryToInsert.add(getAttributeHistoryRecord(mapofTemplateNameWithLoadedJSON.get(ipRec.SVMXC__Product__r.Family+TEXT_TEMPLATE),ipRec.Id,null));                                                                                
            }
        }
        ilib_LogEvent.info(LOG_TITLE+':lstTemplateInstanceToInsert='+lstTemplateInstanceToInsert);
        ilib_LogEvent.info(LOG_TITLE+':lstAttributeHistoryToInsert='+lstAttributeHistoryToInsert);
        
        //Insert SVMXC__SM_IB_Attributes_Template_Instance__c list
        if(!lstTemplateInstanceToInsert.isEmpty()){
            insert lstTemplateInstanceToInsert;
        }

        
        ilib_LogEvent.pop();
        
    }
     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This method is called when product field on IP is getting updated. It will create a new Attribute Instance record with default LRM value=true if there is no existing Instance Record. If there is existing Instance record, this method will update the LRM values to true.
     *  @DATE - 20-Jul-2022 
     *  @PARAM : List<SVMXC__Installed_Product__c> listIPRecordsWithFamily
     *  @RETURN : NA
     **/
    private void updateTAInstanceOnIPProductChange(List<SVMXC__Installed_Product__c> listIPRecordsWithFamily) 
    {
        ilib_LogEvent.push(LOG_TITLE + '.updateTAInstanceOnIPProductChange()');
        List<SVMXC__SM_IB_Attributes_Template_Instance__c> listAttributeInstance;
        List<SVMXC__SM_IB_Attributes_Template_Instance__c> listAttributeInstanceToUpdate = new List<SVMXC__SM_IB_Attributes_Template_Instance__c>();
        List<SVMXC__Installed_Product__c> listIPForNewInstanceCreation = new List<SVMXC__Installed_Product__c>();
         //Get TA Template Records for Product Families
         for(SVMXC__SM_Attributes_Template__c objTemplate : new SMAttributesTemplateSelector().getAttributesTemplateByTitle(setPrdFamilyTemplate)){
            ilib_LogEvent.info(LOG_TITLE+':objTemplate.SVMXC__SM_Template_Json__c='+objTemplate.SVMXC__SM_Template_Json__c);
            mapofTemplateNameWithLoadedJSON.put(objTemplate.SVMXC__SM_Title__c,objTemplate.SVMXC__SM_Template_Json__c);
            ilib_LogEvent.info(LOG_TITLE+' :mapofTemplateNameWithLoadedJSON= '+mapofTemplateNameWithLoadedJSON);

            mapofTemplateNameWithTemplateId.put(objTemplate.SVMXC__SM_Title__c,objTemplate.Id);
            ilib_LogEvent.info(LOG_TITLE+':mapofTemplateNameWithTemplateId='+mapofTemplateNameWithTemplateId);
        }
        //get TA Instance Records for IP IDs in Map
        for (SVMXC__Installed_Product__c ipRec : listIPRecordsWithFamily) {
            listAttributeInstance = new List<SVMXC__SM_IB_Attributes_Template_Instance__c>();
            if(ipRec.SVMXC__IB_Attributes_Template_Instance__r != NULL && ipRec.SVMXC__IB_Attributes_Template_Instance__r.size() > 0){
                listAttributeInstance = ipRec.SVMXC__IB_Attributes_Template_Instance__r;
            }
            ilib_LogEvent.info(LOG_TITLE+':listAttributeInstance='+listAttributeInstance);

            //If IP has TA Attribute Instance recordaAlready
            if(!listAttributeInstance.isEmpty()){
                for(SVMXC__SM_IB_Attributes_Template_Instance__c instanceRec : listAttributeInstance){
                    ilib_LogEvent.info(LOG_TITLE+':instanceRec.SVMXC__SM_Attr_Payload__c[Before LRM]='+instanceRec.SVMXC__SM_Attr_Payload__c);
                    String templateInstanceJSONPopulated = populateLRMFIelds(instanceRec.SVMXC__SM_Attr_Payload__c,ipRec.SVMXC__Product__r.Family+TEXT_TEMPLATE,true);
                    ilib_LogEvent.info(LOG_TITLE+':templateInstanceJSONPopulated[After LRM]='+templateInstanceJSONPopulated);
                    instanceRec.SVMXC__SM_Attr_Payload__c = templateInstanceJSONPopulated;
                    listAttributeInstanceToUpdate.add(instanceRec);

                    //create history record
                    lstAttributeHistoryToInsert.add(getAttributeHistoryRecord(templateInstanceJSONPopulated,ipRec.Id,instanceRec.Id));
                }
            }
            else {
                listIPForNewInstanceCreation.add(ipRec);
            }

        }
        ilib_LogEvent.info(LOG_TITLE+':listIPForNewInstanceCreation='+listIPForNewInstanceCreation);
        ilib_LogEvent.info(LOG_TITLE+':listAttributeInstanceToUpdate='+listAttributeInstanceToUpdate);
        //update Instance Records
        if (!listAttributeInstanceToUpdate.IsEmpty()) {
            update listAttributeInstanceToUpdate;
        }

        //send listIPForNewInstanceCreation for new Instance creation
        if (!listIPForNewInstanceCreation.isEmpty()) {
            insertTAInstanceOnIPCreation(listIPForNewInstanceCreation);
        }
        
        
        ilib_LogEvent.pop();
    }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This method will iterate over the jsonwrapper and populate the LRM fields to true
     *  @DATE - 20-Jul-2022 
     *  @PARAM : String templateJSON, String templateTitle
     *  @RETURN : String of JSON
     **/
    private String populateLRMFIelds(String templateJSON, String templateTitle,Boolean isUpdate) {
        ilib_LogEvent.push(LOG_TITLE + '.populateLRMFIelds()');
        Set<String> setTANamesForTemplate = new Set<String>();
        if(String.isNotBlank(templateJSON)) {  
            //replace "type" with "typeField" in JSON
            String replacedTemplateJSON = templateJSON.replace('"type"', '"typeField"');
            ilib_LogEvent.info(LOG_TITLE+':replacedTemplateJSON='+replacedTemplateJSON);
            //deserialize JSON Payload
            TechnicalAttributesTemplateWrapper templateWrapper = (TechnicalAttributesTemplateWrapper)JSON.deserialize( replacedTemplateJSON , TechnicalAttributesTemplateWrapper.class);
            ilib_LogEvent.info(LOG_TITLE+':templateWrapper='+templateWrapper);

            //deserialize JSON for adding picklist elements.
            Map<String,Object> templateWrapper2 = (Map<String,Object>)JSON.deserializeUntyped(templateJSON);
            ilib_LogEvent.info(LOG_TITLE+':templateWrapper2='+templateWrapper2);

            //get set of Technical Attributes Names for given Tenplate title
            setTANamesForTemplate = mapOfTemplateNameWithAttributes.get(templateTitle);
            ilib_LogEvent.info(LOG_TITLE+':setTANamesForTemplate='+setTANamesForTemplate);
           Map<String,String> mapFieldNameToValue = new Map<String,String>();
            for(TechnicalAttributesTemplateWrapper.TechnicalAttributeFields field : templateWrapper.fields) {
                for(TechnicalAttributesTemplateWrapper.TechnicalAttributes attribute: field.technicalAttributes) {
                    //If the Label is equal to the Technical Attributes mentioned in the set, populate the default value to true.
                    if (setTANamesForTemplate.contains(attribute.label.trim())) {
                        attribute.defaultValue = TXT_TRUE;
                    }
                    String defaultValue = attribute.defaultValue!=null? attribute.defaultValue.trim(): attribute.defaultValue;
                    mapFieldNameToValue.put(attribute.label,defaultValue);
                }
            }
            String finalJSON = JSON.serialize(templateWrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(templateWrapper2.get('picklist')) + '}';
            if(isUpdate && mapofTemplateNameWithLoadedJSON.containsKey(templateTitle)) {
                finalJSON = returnTemplateJsonWithDefaultValues(templateTitle,setTANamesForTemplate,mapofTemplateNameWithLoadedJSON,mapFieldNameToValue);
                ilib_LogEvent.info(LOG_TITLE+':finalJSON[with LRM Patch and picklist] on update = '+finalJSON);
            }
            ilib_LogEvent.info(LOG_TITLE+':templateWrapper[with LRM Patch]='+templateWrapper);
            ilib_LogEvent.info(LOG_TITLE+':finalJSON[with LRM Patch and picklist]='+finalJSON);
            String replacedFinalJSON = finalJSON.replace('"typeField"', '"type"');
            ilib_LogEvent.info(LOG_TITLE+':replacedFinalJSON[with LRM Patch and picklist]='+replacedFinalJSON);
            return replacedFinalJSON;
        }
        return null;
    }
     /**
     *  @AUTHOR Sheikh Shahnawaz
     *  @DESCRIPTION - This method takes template json body and fills default value for fields which are already present if any with the actual value and also make LRM patch checkbox true
     *  @DATE - 02-Aug-2022 
     *  @RETURN : String of JSON
     **/
    private String returnTemplateJsonWithDefaultValues(String templateTitle, Set<String> setTANamesForTemplate,Map<String,String> mapofTemplateNameWithLoadedJSON,Map<String,String> mapFieldNameToValue) {
        ilib_LogEvent.push(LOG_TITLE + '.returnTemplateJsonWithDefaultValues()');
        String templateJSON = mapofTemplateNameWithLoadedJSON.get(templateTitle);
        Map<String,Object> templateWrapper2 = (Map<String,Object>)JSON.deserializeUntyped(templateJSON);
        ilib_LogEvent.info(LOG_TITLE+':templateWrapper2='+templateWrapper2);
        TechnicalAttributesTemplateWrapper templateWrapper = (TechnicalAttributesTemplateWrapper)JSON.deserialize( templateJSON , TechnicalAttributesTemplateWrapper.class);
        ilib_LogEvent.info(LOG_TITLE+':templateWrapper='+templateWrapper);
        for(TechnicalAttributesTemplateWrapper.TechnicalAttributeFields field : templateWrapper.fields) {
            for(TechnicalAttributesTemplateWrapper.TechnicalAttributes attribute: field.technicalAttributes) {
                //If the Label is equal to the Technical Attributes mentioned in the set, populate the default value to true.
                if (setTANamesForTemplate.contains(attribute.label.trim())) {
                    attribute.defaultValue = TXT_TRUE;
                }else if(mapFieldNameToValue.containsKey(attribute.label)) {
                    attribute.defaultValue = mapFieldNameToValue.get(attribute.label);
                }
                mapFieldNameToValue.put(attribute.label,attribute.defaultValue);
            }
        }
        ilib_LogEvent.pop();
        return JSON.serialize(templateWrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(templateWrapper2.get('picklist')) + '}';
     }

    /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - This method creates a map of Template Titles with Set of Technical Attribute Names for that product family from Code Params using split() function
     *  @DATE - 20-Jul-2022 
     *  @PARAM : String codeParamValue
     *  @RETURN : NA
     **/
    private void populateMapOfTemplateNameWithAttributes(String codeParamValue) 
    {
        ilib_LogEvent.push(LOG_TITLE + '.populateMapOfTemplateNameWithAttributes()');
        ilib_LogEvent.info(LOG_TITLE+':codeParamValue='+codeParamValue);

        for(String prdFamilyWithTA : codeParamValue.split(';')){ //this split will give this result "NextSeq - NSQ - Dx:2022 LRM Patch Applied (RUO)?,2022 LRM Patch Applied (Dx)?"
            List<String> prdFamilyWithTAIndex = prdFamilyWithTA.split(':'); //this split will give Product Family Name (NextSeq - NSQ - Dx) at index 0 and Comma separated TA names (2022 LRM Patch Applied (RUO)?,2022 LRM Patch Applied (Dx)) at index 1.
            String prdFamilyTemplateTitle = prdFamilyWithTAIndex.get(0);
            List<String> lstPrdFamilyTA = prdFamilyWithTAIndex.get(1).split(',');// This will split the comma separated TA list(2022 LRM Patch Applied (RUO)?,2022 LRM Patch Applied (Dx)) and create a list
            Set<String> setPrdFamilyTA = new Set<String>();
            setPrdFamilyTA.addAll(lstPrdFamilyTA);
            //populate Key=TA Template Name and Value= Set of TA Names.
            mapOfTemplateNameWithAttributes.put(prdFamilyTemplateTitle+TEXT_TEMPLATE, setPrdFamilyTA);
        }
        ilib_LogEvent.info(LOG_TITLE+':mapOfTemplateNameWithAttributes='+mapOfTemplateNameWithAttributes);
    }

     /**
     *  @AUTHOR Sagar Madkaikar
     *  @DESCRIPTION - Creates SVMXC__SM_IB_Attributes_History__c instance
     *  @DATE - 20-Jul-2022 
     *  @PARAM : String jsonPayload,Id ipRecordId
     *  @RETURN : SVMXC__SM_IB_Attributes_History__c instance
     **/
    private SVMXC__SM_IB_Attributes_History__c getAttributeHistoryRecord(String jsonPayload,Id ipRecordId, Id instanceTemplateId) 
    {
        return new SVMXC__SM_IB_Attributes_History__c(SVMXC__SM_Attr_Payload__c=jsonPayload,
                                                      SVMXC__SM_Captured_On__c = system.now(),
                                                      SVMXC__SM_Installed_Product_Id__c = ipRecordId,
                                                      SVMXC__SM_Attr_Type__c=TEXT_TECHNICAL,
                                                      SVMXC__SM_Instance_Template_Id__c = instanceTemplateId
                                                    );
    }
    
}