/***************************************************************************************************************************************
 * NAME   : SmIbAttributesTemplateInstances 
 * DESCRIPTION  : Trigger Handler for SmIbAttributesTemplateInstances
 *    @Test Class for above 90% coverage.
 *    -TestBatchUpdateMandatoryInfoOnIB
 *    -TestIBTechinalAttributeCreationQueuable
 *    -TestValidateInstallWOOnComplete
 *    @Test Class for atleast 75% coverage.
      -TestBatchUpdateMandatoryInfoOnIB
 *    -TestIBTechinalAttributeCreationQueuable
 *    -TestValidateInstallWOOnComplete
 *           
 * @AUTHOR : Vignesh
 * @DATE   : 13-Oct-2021   
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Vignesh               13-Oct-2021            Adding logic to populate Json based on Proactive attributes. 
 * Raviteja              18-Apr-2022            Added a condition to check the upgrade type to mandate the Date Fields
 * Nishan Shetty         25-Aug-2022            DCP-44091 - Indirect Instantiation of Orchestrator Class for Performance Improvement.
 * Shivani Jain          16-Sep-2022            DCP-52682 - Report on Proactive and Salesforce Discrepancies for IB TA
 * Gladis                27-Jan-2023            DCP-52696 To validate IPs Edit access and throw error when Technical Attribute don't have access on the IP
 *************************************************************************************************************/
public with sharing class SmIbAttributesTemplateInstances extends ilib_SObjectDomain {


    public static final String STRING_LAST_UPGRADE_DAY = 'Last Upgrade Day';
    public static final String STRING_LAST_UPGRADE_MONTH = 'Last Upgrade Month';
    public static final String STRING_LAST_UPGRADE_YEAR = 'Last Upgrade Year';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
   
    public static Map<String,SVMXC__SM_Attributes_Template__c> mapAttributeTemplate = new Map<String,SVMXC__SM_Attributes_Template__c>();//DCP-47035
    public static Map<Id,String> mapAttributeInstance = new Map<Id,String>();//DCP-47035
    public static final set<string> UPGRADE_TYPE = new set<string>{'Tecan with IAC','IAPS with IAC','IAPS with ILASS'}; //DCP-51837
    //START - DCP-52682
    public static Map<String, Technical_Attribute_Discrepancy__c> discrepancyRecs;  
    public static Map<Id,SVMXC__Installed_Product__c> mapInstalledProduct = new Map<Id,SVMXC__Installed_Product__c >();  
    private static final String LOG_TITLE = 'SmIbAttributesTemplateInstances';
    private static final String STRING_TEMPLATE = ' Template';                 
    private static final String STRING_PICKLIST = 'picklist';                  
    private static final String STRING_VALUES = 'values';                     
    private static final String DELIMETER = '~';     
    //END - DCP-52682                       

		/*
         * Constructor
         */
    public SmIbAttributesTemplateInstances(List<SVMXC__SM_IB_Attributes_Template_Instance__c> sObjectList)
    {
        super(sObjectList);
    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new SmIbAttributesTemplateInstances(sObjectList);
        }
    }

    /*******************************************************************************************************
    * @description  Method to use for initializing Collections that will be used in all events
    * @param records List of Parts Order Lines
    */
    public void queryRecordsforExecution(List<Sobject> records) {
        Set<Id> setIPsProactive = new Set<Id>();
        
		for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>) records) {
            if(String.isNotBlank(obj.Proactive_Attributes__c) && obj.SVMXC__SM_Installed_Product_Id__c != NULL) {
                setIPsProactive.add(obj.SVMXC__SM_Installed_Product_Id__c);
            }
        }

        if(!setIPsProactive.isEmpty()) {
            mapInstalledProduct = new Map<Id,SVMXC__Installed_Product__c >( new InstalledProductsSelector().selectIPsWithAttributeHistory(setIPsProactive));
        }
    }
    
		/*
         * description - onBeforeInsert method
		 * return - void
         */ 	
     public override void onBeforeInsert()
    {
        queryRecordsforExecution(records);
        populateInstalledProduct(records);
        populateJson(records, null);
        validateIPAccess(records);//DCP-52696
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(Userinfo.getUserId());
        if(!apexSetting.Bypass_All_Validations__c){
            validateattributeFields(null,records);

        }
        
        
    }

		/*
         * description - onAfterInsert method
		 * return - void
         */ 
    public override void onAfterInsert()
    {
        queryRecordsforExecution(records);  //DCP-52682
        createInstanceHistory(records,null);
        createProactiveDiscrepancyRecs();  //DCP-52682
    }

		/*
         * description - onAfterUpdate method
		 * return - void
         */ 
    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        queryRecordsforExecution(records);
        createInstanceHistory(records,existingRecords);
        createProactiveDiscrepancyRecs();  //DCP-52682
    }
    
 		/*
         * description - onBeforeUpdate method
		 * return - void
         */ 
 
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords) {
        queryRecordsforExecution(records);
        validateIPAccess(records);//DCP-52696
        populateJson(records, oldRecords);
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(Userinfo.getUserId());
        if(!apexSetting.Bypass_All_Validations__c){
            validateattributeFields(oldRecords,records);
        }
    }
    
    
		/*
         * description - validateattributeFields method
		 * return - void
         */ 	
    public void validateattributeFields(Map<Id, SObject> oldRecords, List<SObject> records){
        Map<String, String> mapoldattributeToValue=new Map<String , String>();
        Map<String, String> mapnewattributeToValue=new Map<String , String>();
        Map<String , IVD_Product_Criteria__mdt> mapAttrToObj=new Map<String , IVD_Product_Criteria__mdt>();
        //Initialize Map with Values from CustomMetaData
        for(IVD_Product_Criteria__mdt obj:[Select    Attribute_Type__c,  Attribute_Name__c , Attribute_Value__c , IVD_Product_Identifier__c from IVD_Product_Criteria__mdt]){
            mapAttrToObj.put(obj.Attribute_Name__c , obj);
        }
    
        for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
        //Added condition to check for records not processed by proactive - DCP-47035
        if(!mapAttributeInstance.containsKey(obj.Id) && obj.SVMXC__SM_Attr_Payload__c != Null ) {
        System.debug('here..1');
        IBTechnicalAttributeWrapper objoldAttrPayload;
        if(oldRecords!=null && !oldRecords.isEmpty()){
        SVMXC__SM_IB_Attributes_Template_Instance__c objOltemplateInstance = (SVMXC__SM_IB_Attributes_Template_Instance__c)(oldRecords.get(obj.Id));
        objoldAttrPayload=(IBTechnicalAttributeWrapper)JSON.deserialize(objOltemplateInstance .SVMXC__SM_Attr_Payload__c, IBTechnicalAttributeWrapper.class);
        }
        IBTechnicalAttributeWrapper objAttrPayload=(IBTechnicalAttributeWrapper)JSON.deserialize(obj.SVMXC__SM_Attr_Payload__c, IBTechnicalAttributeWrapper.class);
        
        mapoldattributeToValue=new Map<String,String>();
        if(objoldAttrPayload!=null){
            for(IBTechnicalAttributeWrapper.fields objField: objoldAttrPayload.fields){
                for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr:  objField.technicalAttributes ){
                    mapoldattributeToValue.put(objTechAttr.label,objTechAttr.defaultValue);
                    }    
            }
        }


        mapnewattributeToValue=new Map<String,String>();
        if(objAttrPayload!=null){
            for(IBTechnicalAttributeWrapper.fields objField: objAttrPayload.fields){
                for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr:  objField.technicalAttributes ){
                    mapnewattributeToValue.put(objTechAttr.label,objTechAttr.defaultValue);
                    }    
            }
        }


        if(mapoldattributeToValue!=null && !mapoldattributeToValue.isEmpty() && mapnewattributeToValue!=null && !mapnewattributeToValue.isEmpty()){
            
            String oldupgradeType;
            String newUpgradeType;
            for(String attrname:mapAttrToObj.keyset()){
                /* if(mapoldattributeToValue.containsKey(attrname))
                oldupgradeType=mapoldattributeToValue.get(attrname);*/
                
                if(mapnewattributeToValue.containsKey(attrname))
                newUpgradeType=mapnewattributeToValue.get(attrname);
            }
            
                Date lastUpgradeDate=new SmIbTechnicalAttributes(new List<SVMXC__SM_IB_Technical_Attributes__c>()).getConvertDate(mapnewattributeToValue);
            ilib_LogEvent.message('newUpgradeType***'+newUpgradeType);
            ilib_LogEvent.message('lastUpgradeDate***'+lastUpgradeDate);
            //DCP-51837 - Added a condition to check the Upgrade Type
                if(newUpgradeType!=null && newUpgradeType!='' && lastUpgradeDate==null && !UPGRADE_TYPE.contains(newUpgradeType))
                obj.addError('Last Upgrade Date Fields are Required');

        }else if((mapoldattributeToValue==null || mapoldattributeToValue.isEmpty()) && mapnewattributeToValue!=null && !mapnewattributeToValue.isEmpty() ){
            String newUpgradeType;
            for(String attrname:mapAttrToObj.keyset()){
                if(mapnewattributeToValue.containsKey(attrname))
                newUpgradeType=mapnewattributeToValue.get(attrname);
            }
            Date lastUpgradeDate=new SmIbTechnicalAttributes(new List<SVMXC__SM_IB_Technical_Attributes__c>()).getConvertDate(mapnewattributeToValue);
            
            ilib_LogEvent.message('newUpgradeType***'+newUpgradeType);
            ilib_LogEvent.message('lastUpgradeDate***'+lastUpgradeDate);
            //DCP-51837 - Added a condition to check the Upgrade Type
            if( newUpgradeType!=null && newUpgradeType!='' && lastUpgradeDate==null && !UPGRADE_TYPE.contains(newUpgradeType))
                obj.addError('Last Upgrade Date Fields are Required ');
            
        }
 
        }
       }
    }
    
    /*******************************************************************************************************
    * @description Method to calculate Attrbute Json based on proactive attributes 
    * @param List<SObject> records Work Order Record
    * @param Map<Id,SObject> mapOldRecords Value from Qualification Requirements field
    * @return void
    * @example
    *******************************************************************************************************/
    public void populateJson(List<SObject> records, Map<Id,SObject> mapOldRecords) {
        discrepancyRecs = new Map<String, Technical_Attribute_Discrepancy__c>();  //DCP-52682
        
        mapAttributeInstance = checkForProactiveUpdates ((List<SVMXC__SM_IB_Attributes_Template_Instance__c>) records , (Map<Id,SVMXC__SM_IB_Attributes_Template_Instance__c>) mapOldRecords );
       
        if(!mapAttributeInstance.isEmpty()){
            for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
                if(mapAttributeInstance.containsKey(obj.Id)) {
                    SVMXC__Installed_Product__c objRelatedIP = mapInstalledProduct.containsKey(obj.SVMXC__SM_Installed_Product_Id__c) 
                            ? mapInstalledProduct.get(obj.SVMXC__SM_Installed_Product_Id__c) : NULL;                   //DCP-52682
                    //Parse Json data.                    
                    String strPayload = mapAttributeInstance.get(obj.Id);
                    Map<String, Object> mapProactiveData = (Map<String, Object>)JSON.deserializeUntyped(obj.Proactive_Attributes__c);
                    
                    //START - DCP-52682  
                    Map<String, Object> mapOldProactiveData = NULL;
                    if(mapOldRecords != NULL && mapOldRecords.containsKey(obj.Id) 
                            && String.isNotEmpty(((SVMXC__SM_IB_Attributes_Template_Instance__c) mapOldRecords.get(obj.Id)).Proactive_Attributes__c)) {
                        mapOldProactiveData = (Map<String, Object>)JSON.deserializeUntyped(((SVMXC__SM_IB_Attributes_Template_Instance__c)mapOldRecords.get(obj.Id)).Proactive_Attributes__c); 
                    }             
                    //END - DCP-52682

                    Map<String,Object> fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(strPayload);
                    IBTechnicalAttributeWrapper objAttrPayload = (IBTechnicalAttributeWrapper)JSON.deserialize( strPayload , IBTechnicalAttributeWrapper.class);
                    //START - DCP-52682
                    IBTechnicalAttributeWrapper objAttrPayloadTemplate = mapAttributeTemplate.containsKey(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE) ? 
                            (IBTechnicalAttributeWrapper)JSON.deserialize(mapAttributeTemplate.get(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE).SVMXC__SM_Template_Json__c , IBTechnicalAttributeWrapper.class) : NULL;

                    Map<String, String> picklistLabelToId = createAttrTemplateMap(mapProactiveData, mapOldProactiveData, objAttrPayloadTemplate);
                    //END - DCP-52682

                    //Iterate over fields to check. 
                    for(IBTechnicalAttributeWrapper.fields objField: objAttrPayload.fields){
                        for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr:  objField.technicalAttributes ){
                            if( mapProactiveData.containskey(objTechAttr.label.trim()) && (string)mapProactiveData.get(objTechAttr.label.trim()) != '<Not available>'){
                                objTechAttr.defaultValue = (string)mapProactiveData.get(objTechAttr.label.trim()); 
                                //START - DCP-52682
                                String newProactiveVal = (String)mapProactiveData.get(objTechAttr.label.trim());
                                String oldProactiveVal = mapOldProactiveData != NULL && mapOldProactiveData.containskey(objTechAttr.label.trim()) ? (String)mapOldProactiveData.get(objTechAttr.label.trim()) : '';
                                
                                checkForPicklistDiscrepancy(objTechAttr, objRelatedIP, obj, newProactiveVal, oldProactiveVal, picklistLabelToId);  
                                //END - DCP-52682
                            }
                            
                        }    
                    }
                    //Construct Payload
                    String attrPayload = JSON.serialize(objAttrPayload).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get(STRING_PICKLIST)) + '}';
                    obj.SVMXC__SM_Attr_Payload__c = attrPayload;
                    obj.SVMXC__SM_Captured_On__c = Datetime.now();
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Method to create instance history record
    * @param List<SObject> records Work Order Record
    * @param Map<Id,SObject> mapOldRecords Value from Qualification Requirements field
    * @return
    * @example
    *******************************************************************************************************/
    public void createInstanceHistory (List<SObject> records, Map<Id,SObject> mapOldRecords){
        mapAttributeInstance = checkForProactiveUpdates ((List<SVMXC__SM_IB_Attributes_Template_Instance__c>) records , (Map<Id,SVMXC__SM_IB_Attributes_Template_Instance__c>) mapOldRecords );
        if(!mapAttributeInstance.isEmpty()){
            list<SVMXC__SM_IB_Attributes_History__c> lstHistoryToInsert = new list<SVMXC__SM_IB_Attributes_History__c>();
            for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
                if(mapAttributeInstance.containsKey(obj.Id)) {
                    SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
                    objTechAttrHistory.SVMXC__SM_Attr_Payload__c = obj.SVMXC__SM_Attr_Payload__c ;
                    objTechAttrHistory.SVMXC__SM_Captured_On__c = Datetime.now();
                    objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = obj.SVMXC__SM_Installed_Product_Id__c;
                    objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                    objTechAttrHistory.SVMXC__SM_Source__c = 'Web';
                    objTechAttrHistory.SVMXC__SM_Instance_Template_Id__c = obj.Id ;
                    lstHistoryToInsert.add(objTechAttrHistory);
                }
            }
            try{
                insert lstHistoryToInsert;
            } catch (Exception e){
                ApexExceptions.emit('SmIbAttributesTemplateInstances', e);
            }
        }
    }

    /*******************************************************************************************************
    * @description Method to populate Installed Product
    * @param List<SObject> records Work Order Record
    * @return void
    * @example
    *******************************************************************************************************/
    public void populateInstalledProduct (List<SObject> records){
        Map<String,String> mapIP = new Map<String,String>();
        mapIP = getRelatedInstalledProduct(records);

        for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
            if(!String.isBlank(obj.Serial_Lot_Number__c) && obj.SVMXC__SM_Installed_Product_Id__c == Null){
                if(mapIP.containsKey(obj.Serial_Lot_Number__c) ){
                    obj.SVMXC__SM_Installed_Product_Id__c = mapIP.get(obj.Serial_Lot_Number__c);
                }else{
                    obj.addError(Label.IP_MATCH_NOT_FOUND);
                }
            }

            if(String.isBlank(obj.Serial_Lot_Number__c) && obj.SVMXC__SM_Installed_Product_Id__c  != Null && mapIP.containsKey(obj.SVMXC__SM_Installed_Product_Id__c)  ){
                obj.Serial_Lot_Number__c = mapIP.get(obj.SVMXC__SM_Installed_Product_Id__c);
            }
        }

    }

    /*******************************************************************************************************
    * @description Method to populate Installed Product
    * @param List<SObject> records Work Order Record
    * @return Map<String,String> -  Map of SerialNumber and Id combination.
    * @example
    *******************************************************************************************************/
    public Map<String,String> getRelatedInstalledProduct (List<SObject> records){
        List<String> lstIPToCheck = new List<String>();
        List<String> lstSerialLotNumber = new List<String>();
        Map<String,String> mapIP = new Map<String,String>();

        for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
            if(!String.isBlank(obj.Serial_Lot_Number__c) && obj.SVMXC__SM_Installed_Product_Id__c  == Null ){
                lstSerialLotNumber.add(obj.Serial_Lot_Number__c);
            }else if(String.isBlank(obj.Serial_Lot_Number__c) && obj.SVMXC__SM_Installed_Product_Id__c  != Null){
                lstIPToCheck.add(obj.SVMXC__SM_Installed_Product_Id__c);
            }
        }

        for(SVMXC__Installed_Product__c objIP : new InstalledProductsSelector().selectIPForSerialLotNumberOrID(lstSerialLotNumber, lstIPToCheck)){
            mapIP.put(objIP.Id,objIP.SVMXC__Serial_Lot_Number__c);
            mapIP.put(objIP.SVMXC__Serial_Lot_Number__c,objIP.Id);
        }
        return mapIP;
    }

    /*******************************************************************************************************
    * @description Method to populate Attribute Template records.
    * @param void
    * @return void
    * @example
    *******************************************************************************************************/
    public void populateAttributeTemplate(){
		//Get All IB Technical Attribute Template records  
		if(mapAttributeTemplate.isEmpty()){
			for(SVMXC__SM_Attributes_Template__c objTemplate : new SMAttributesTemplateSelector().getActiveRecords()){
				mapAttributeTemplate.put(objTemplate.SVMXC__SM_Title__c , objTemplate );
			}
		}
	}

    /*******************************************************************************************************
    * @description Method to check for Updates Triggered from Proactive records.
    * @param List of Template Instance Records
    * @param Map of old instances of Template Instance Records
    * @return Map<Id,String> 
    * @example
    *******************************************************************************************************/
    public Map<Id,String> checkForProactiveUpdates(List<SVMXC__SM_IB_Attributes_Template_Instance__c> records , Map<Id,SVMXC__SM_IB_Attributes_Template_Instance__c> mapOldRecords){
		
		Map<Id,String> mapAttributeInstance = new Map<Id,String>();
		
        if(!mapInstalledProduct.isEmpty()){
            populateAttributeTemplate();

            for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>)records){
                SVMXC__Installed_Product__c objRelatedIP = Null;
                SVMXC__SM_IB_Attributes_Template_Instance__c oldInstance = Null;

                if(mapOldRecords != Null){
                    oldInstance = (SVMXC__SM_IB_Attributes_Template_Instance__c)mapOldRecords.get(obj.Id);
                }

                if(mapInstalledProduct.containsKey(obj.SVMXC__SM_Installed_Product_Id__c)){
                    objRelatedIP = mapInstalledProduct.get(obj.SVMXC__SM_Installed_Product_Id__c);
                }
                if( String.isNotBlank(obj.Proactive_Attributes__c) && objRelatedIP != Null &&
                (oldInstance == Null || objRelatedIP.SVMXC__IB_Attributes_Historys__r.size() == 0 || 
                (objRelatedIP.Proactive_Last_Connected_Date__c != Null && objRelatedIP.Proactive_Last_Connected_Date__c > objRelatedIP.SVMXC__IB_Attributes_Historys__r[0].createddate )))
                {
                    //get Payload to be modified. Either from instance record or default template from Instane Template record. 
                    String strPayload;
                    if(String.isNotBlank(obj.SVMXC__SM_Attr_Payload__c)){
                        strPayload = obj.SVMXC__SM_Attr_Payload__c;
                        mapAttributeInstance.put(obj.Id , strPayload);
                    } else if(objRelatedIP.SVMXC__Product__r.family != Null && mapAttributeTemplate.containsKey(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE) ) {
                        strPayload = mapAttributeTemplate.get(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE).SVMXC__SM_Template_Json__c;
                        mapAttributeInstance.put(obj.Id , strPayload);
                    }	
				}
			}
		}
		return mapAttributeInstance;
	}

    /*******************************************************************************************************
    * @description Method to create instance history record
    * @param List<SObject> records Work Order Record
    * @param Map<Id,SObject> mapOldRecords Value from Qualification Requirements field
    * @return
    * @example
    *******************************************************************************************************/
    public void createProactiveDiscrepancyRecs() {
        ilib_LogEvent.push(LOG_TITLE + '.createProactiveDiscrepancyRecs()');
        ilib_LogEvent.message('discrepancyRecs'+ discrepancyRecs);

        if(!discrepancyRecs.isEmpty()) {
            try {
                insert discrepancyRecs.values();
            } catch (Exception e){
                ApexExceptions.emit('SmIbAttributesTemplateInstances', e);
            }
        }
        ilib_LogEvent.pop();
    }

    /*******************************************************************************************************
    * @description DCP-52682 Method to check for Proactive Discrepancy fro picklist value
    * @param objTechAttr IBTechnicalAttributeWrapper.technicalAttributes
    * @param objRelatedIP SVMXC__Installed_Product__c
    * @param obj SVMXC__SM_IB_Attributes_Template_Instance__c
    * @return void
    *******************************************************************************************************/
    public void checkForPicklistDiscrepancy(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr, SVMXC__Installed_Product__c objRelatedIP, 
                                        SVMXC__SM_IB_Attributes_Template_Instance__c obj, String newProactiveVal, String oldProactiveVal,
                                        Map<String, String> picklistLabelToId) {
        
        ilib_LogEvent.push(LOG_TITLE + '.checkForPicklistDiscrepancy()');
        ilib_LogEvent.message('objTechAttr - objRelatedIP - obj'+ objTechAttr + objRelatedIP + obj);

        if(newProactiveVal != oldProactiveVal && objTechAttr.format == STRING_PICKLIST.capitalize() && objTechAttr.defaultValue != '' 
                    && picklistLabelToId.containsKey(objTechAttr.label.trim()) && mapAttributeTemplate.containsKey(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE)) {
                String templateJSON = mapAttributeTemplate.get(objRelatedIP.SVMXC__Product__r.family+STRING_TEMPLATE).SVMXC__SM_Template_Json__c;
                Map<String, Object> templateJSONWrapper = (Map<String,Object>) JSON.deserializeUntyped(templateJSON);
                Map<String, Object> picklistValuesMap = (Map<String,Object>) ((Map<String,Object>) templateJSONWrapper.get(STRING_PICKLIST))?.get(picklistLabelToId.get(objTechAttr.label.trim()));
                List<Object> picklistValuesObj = (List<Object>) picklistValuesMap.get(STRING_VALUES);
                List<String> picklistValuesList = String.join(picklistValuesObj, ';').split(';');
                String key = objRelatedIP.SVMXC__Product__r.family + DELIMETER + objTechAttr.label.trim() + DELIMETER + objTechAttr.defaultValue;
                if(!picklistValuesList.contains(objTechAttr.defaultValue) && !discrepancyRecs.containsKey(key)) {
                    discrepancyRecs.put(key, new Technical_Attribute_Discrepancy__c(Value_from_Proactive__c = objTechAttr.defaultValue,
                    Attribute_Name__c = objTechAttr.label.trim(), 
                    Product_Family__c = objRelatedIP.SVMXC__Product__r.family, 
                    Installed_Product__c = obj.SVMXC__SM_Installed_Product_Id__c));
                }
            }

        ilib_LogEvent.pop();

    }

    /*******************************************************************************************************
    * @description DCP-52682 Method to fetch picklist id from attribute template
    * @param mapProactiveData Map<String, Object>
    * @param mapOldProactiveData Map<String, Object>
    * @param objAttrPayloadTemplate IBTechnicalAttributeWrapper
    * @return Map<String, String>
    *******************************************************************************************************/
    private Map<String, String> createAttrTemplateMap(Map<String, Object> mapProactiveData,  Map<String, Object> mapOldProactiveData, IBTechnicalAttributeWrapper objAttrPayloadTemplate) {
        ilib_LogEvent.push(LOG_TITLE + '.createAttrTemplateMap()');
        ilib_LogEvent.message('mapProactiveData - mapOldProactiveData - objAttrPayloadTemplate'+ mapProactiveData + mapOldProactiveData + objAttrPayloadTemplate);

        Map<String, String>  picklistLabelToIdMap = new Map<String, String>();

        if(objAttrPayloadTemplate != NULL) {
            //Iterate over fields to check. 
            for(IBTechnicalAttributeWrapper.fields objField: objAttrPayloadTemplate.fields) {
                for(IBTechnicalAttributeWrapper.technicalAttributes objTechAttr:  objField.technicalAttributes ) {
                    if(mapProactiveData.containskey(objTechAttr.label.trim()) && (string)mapProactiveData.get(objTechAttr.label.trim()) != '<Not available>') {
                        String newProactiveVal = (String)mapProactiveData.get(objTechAttr.label.trim());
                        String oldProactiveVal =  mapOldProactiveData != NULL && mapOldProactiveData.containskey(objTechAttr.label.trim()) ? (String)mapOldProactiveData.get(objTechAttr.label.trim()) : '';
                        if(newProactiveVal != oldProactiveVal) {
                            picklistLabelToIdMap.put(objTechAttr.label.trim(), objTechAttr.picklistId);
                        }

                    }
                }
            }
        }

        ilib_LogEvent.pop();
        return picklistLabelToIdMap;
    }

    /**
    *  @Author Gladis 
    *  @Description - DCP-52696 To validate and throw error when Technical Attribute don't have access on the IP
    *  @Param      : trigger.new
    *  @Return     : void             
    **/
    public void validateIPAccess(List<SObject> records){

        ilib_LogEvent.push(LOG_TITLE + '.validateIPAccess()');
        Set<Id> setIPs= new Set<Id>();
        Map<Id, SVMXC__SM_IB_Attributes_Template_Instance__c> mapRec = new Map<Id, SVMXC__SM_IB_Attributes_Template_Instance__c>();
        try {
            for(SVMXC__SM_IB_Attributes_Template_Instance__c obj : (List<SVMXC__SM_IB_Attributes_Template_Instance__c>) records) {
                mapRec.put(obj.SVMXC__SM_Installed_Product_Id__c, obj);
                if(obj.SVMXC__SM_Installed_Product_Id__c != NULL) {
                    setIPs.add(obj.SVMXC__SM_Installed_Product_Id__c);
                }
            }
            for(UserRecordAccess usrAccessObj: new UserRecordAccessSelector().selectUserRecordAccessByUserAndSetRecordId(UserInfo.getUserId(),setIPs)) {
                if(usrAccessObj.HasEditAccess !=true) {
                    SVMXC__SM_IB_Attributes_Template_Instance__c actualRecord = mapRec.get(usrAccessObj.RecordId);
                    actualRecord.addError(System.Label.Check_Access_to_Update_Technical_Attributes_Error_Message);
                }
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit(); 
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            ilib_LogEvent.message(LOG_TITLE+'.Exception: ' + e.getMessage()); 
        }
    }
}