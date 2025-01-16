/***************************************************************************************************************************************
* NAME   : IBTechinalAttributeCreationQueuable 
* --------------------------------------------------------------------------------------------------------------------------------------
*/
/*@ author       : illumina
* @ date         :
* @ Description  : 
*  Modification Log:
*    ------------------------------------------------------------------------------------
*    Developer                      Date                Description
*    Nitin                          7 june 2022         CMSI-36 try catch in execute method 
*    ------------------------------------------------------------------------------------  
*
*
*/
public class IBTechinalAttributeCreationQueuable implements Queueable{
    Map<Id,SVMXC__Installed_Product__c> installedProductIdToRecordWithAttributesUpdated; 
    public static Boolean catchException = false;
      
		/*
         * Constructor
         */   
    public IBTechinalAttributeCreationQueuable(Map<Id,SVMXC__Installed_Product__c> installedProductIdToRecordWithAttributesUpdated){
        this.installedProductIdToRecordWithAttributesUpdated = installedProductIdToRecordWithAttributesUpdated;
    }

		/*
         * description - execute method
		 * return - void
         */    
    public void execute(QueueableContext context) {
        try{
        Map<String,String> mapIBFieldLabelVsAPIName = new Map<String,String>();
        if(system.test.isRunningTest()){
            Schema.FieldSetMember fieldMember = SObjectType.SVMXC__Installed_Product__c.FieldSets.IQ_OQ_Technical_Attribute_FieldSet.getFields()[0];
            mapIBFieldLabelVsAPIName.put(fieldMember.getLabel(), fieldMember.getFieldPath());
        }else{
            for(Schema.FieldSetMember fieldMember : SObjectType.SVMXC__Installed_Product__c.FieldSets.IQ_OQ_Technical_Attribute_FieldSet.getFields()){
                mapIBFieldLabelVsAPIName.put(fieldMember.getLabel(), fieldMember.getFieldPath());
            }
        }
         
        //With the technical attributes updated, its history and attribute instance also needs to be updated in ServiceMax.
        //List of technical attributes to be created/updated
        List<SVMXC__SM_IB_Technical_Attributes__c> lstTechnicalAttrToBeCreated = new List<SVMXC__SM_IB_Technical_Attributes__c>();
                
        //Map of existing technical attribute values for an IB
        Map<Id,Map<String,SVMXC__SM_IB_Technical_Attributes__c>> installedProdToexistingTechAttrValueMap = new Map<Id,Map<String,SVMXC__SM_IB_Technical_Attributes__c>>();
        //Attribute Instance record for that day for an IB
        Map<Id,SVMXC__SM_IB_Attributes_Template_Instance__c> installedProdToTemplateInstace = new Map<Id,SVMXC__SM_IB_Attributes_Template_Instance__c>();
        //Attribute History record for that day for an IB
        Map<Id,SVMXC__SM_IB_Attributes_History__c> installedProdToAttrHistory = new Map<Id,SVMXC__SM_IB_Attributes_History__c>();
        //Fetch the template for MiSeq - MSQ 
        List<SVMXC__SM_Attributes_Template__c> lstAttrTemplate = [Select Id,SVMXC__SM_Template_Json__c,SVMXC__SM_Title__c
                                                                 from SVMXC__SM_Attributes_Template__c 
                                                                  Where SVMXC__SM_Title__c = 'MiSeq - MSQ - DX Template' OR SVMXC__SM_Title__c = 'MiSeq - MSQ - RUO Template' ];
        if(!lstAttrTemplate.isEmpty()){
            Map<string,IBTechinalAttributeCreationQueuable.TechnicalAttributeTemplateWrapper> mapWrapper = new Map<string,IBTechinalAttributeCreationQueuable.TechnicalAttributeTemplateWrapper>();
            Map<string,Map<String,Object>> mapFieldWrapperMap = new Map<string,Map<String,Object>>();
            
           
            for(SVMXC__SM_Attributes_Template__c objTemplate : lstAttrTemplate){
                //Deserialize the JSON for the template
                IBTechinalAttributeCreationQueuable.TechnicalAttributeTemplateWrapper wrapper = (TechnicalAttributeTemplateWrapper)JSON.deserialize(objTemplate.SVMXC__SM_Template_Json__c, TechnicalAttributeTemplateWrapper.class);
                mapWrapper.put(objTemplate.SVMXC__SM_Title__c , wrapper);

                Map<String,Object> fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(objTemplate.SVMXC__SM_Template_Json__c);
                mapFieldWrapperMap.put(objTemplate.SVMXC__SM_Title__c , fieldWrapperMap );
            }

            //Fetch existing Technical Attributes
            for(SVMXC__SM_IB_Technical_Attributes__c objTechAttr : [Select SVMXC__SM_Installed_Product_id__c,SVMXC__SM_Attr_Name__c
                                                                    from SVMXC__SM_IB_Technical_Attributes__c
                                                                    where SVMXC__SM_Installed_Product_id__c IN : installedProductIdToRecordWithAttributesUpdated.keySet()
                                                                   AND CreatedDate = TODAY])
            {
                if(!installedProdToexistingTechAttrValueMap.containsKey(objTechAttr.SVMXC__SM_Installed_Product_id__c)){
                    installedProdToexistingTechAttrValueMap.put(objTechAttr.SVMXC__SM_Installed_Product_id__c, new Map<String,SVMXC__SM_IB_Technical_Attributes__c>());
                }
                Map<String,SVMXC__SM_IB_Technical_Attributes__c> extingAttrNameToValue = installedProdToexistingTechAttrValueMap.get(objTechAttr.SVMXC__SM_Installed_Product_id__c);
                extingAttrNameToValue.put(objTechAttr.SVMXC__SM_Attr_Name__c, objTechAttr);
                installedProdToexistingTechAttrValueMap.put(objTechAttr.SVMXC__SM_Installed_Product_id__c,extingAttrNameToValue);
            }
            
            //Fetch IB's Template instance for current day
            for(SVMXC__Installed_Product__c objIP : [select id,(select id,SVMXC__SM_Attr_Payload__c,SVMXC__SM_Attr_Type__c,SVMXC__SM_Captured_On__c,SVMXC__SM_Installed_Product_Id__c,SVMXC__SM_Instance_Template_Id__c from SVMXC__IB_Attributes_Template_Instance__r Order by lastmodifieddate desc LIMIT 1) from SVMXC__Installed_Product__c WHERE ID IN:installedProductIdToRecordWithAttributesUpdated.Values() ]){
                if(!objIP.SVMXC__IB_Attributes_Template_Instance__r.isEmpty()){
                    installedProdToTemplateInstace.put(objIP.Id, objIP.SVMXC__IB_Attributes_Template_Instance__r );
                }
            }
            
            //Fetch IB's History instance for current day
            for(SVMXC__SM_IB_Attributes_History__c objTechAttrHistory : [Select Id,SVMXC__SM_Installed_Product_Id__c
                                                                         from SVMXC__SM_IB_Attributes_History__c 
                                                                         Where SVMXC__SM_Installed_Product_Id__c IN : installedProductIdToRecordWithAttributesUpdated.keySet()
                                                                         AND createddate = TODAY])
            {
                installedProdToAttrHistory.put(objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c ,objTechAttrHistory);            
            }
            
            Map<Id,SVMXC__Installed_Product__c> mapInstalledPdt = new Map<Id,SVMXC__Installed_Product__c>([select Id,SVMXC__Product__r.family FROM SVMXC__Installed_Product__c WHERE ID IN:installedProductIdToRecordWithAttributesUpdated.keyset() ]);

            for(SVMXC__Installed_Product__c objInstalledProduct : installedProductIdToRecordWithAttributesUpdated.values())
            {  
                //Deserialize the JSON created from IQ/OQ form
                //String strIQOQIBAttrJson = '{' + objInstalledProduct.IQ_OQ_For_IB_Attributes_JSON__c + '}';
                //Map<String, Object> jsonDeserialized = (Map<String, Object>)JSON.deserializeUntyped(strIQOQIBAttrJson);
                
                //Get existing values

                String templateName = mapInstalledPdt.get(objInstalledProduct.Id).SVMXC__Product__r.family+' Template';
 
                IBTechinalAttributeCreationQueuable.TechnicalAttributeTemplateWrapper wrapper = mapWrapper.get(templateName);
                Map<String,Object> fieldWrapperMap = mapfieldWrapperMap.get(templateName);
                
                //Get the template instance if any
                SVMXC__SM_IB_Attributes_Template_Instance__c objTechAttrInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
                IBTechinalAttributeCreationQueuable.TechnicalAttributeTemplateWrapper objInstancewrapper = wrapper;
                if(installedProdToTemplateInstace.containsKey(objInstalledProduct.Id)){
                    SVMXC__SM_IB_Attributes_Template_Instance__c objExistingTechAttrInstance = installedProdToTemplateInstace.get(objInstalledProduct.Id);
                    objInstancewrapper = (TechnicalAttributeTemplateWrapper)JSON.deserialize(objExistingTechAttrInstance.SVMXC__SM_Attr_Payload__c, TechnicalAttributeTemplateWrapper.class);
                    
                }
                
                //Get Attribute history if any
                SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
                if(installedProdToAttrHistory.containsKey(objInstalledProduct.Id)){
                    objTechAttrHistory = installedProdToAttrHistory.get(objInstalledProduct.Id);
                }
                //for(String strAttrName : jsonDeserialized.keySet()){
                for(String strAttrName : mapIBFieldLabelVsAPIName.keySet()){
                    SVMXC__SM_IB_Technical_Attributes__c objIBAttr = new SVMXC__SM_IB_Technical_Attributes__c();
                    /*if(extingAttrNameToValue != null && extingAttrNameToValue.containsKey(strAttrName)){
                        objIBAttr = extingAttrNameToValue.get(strAttrName);
                    }*/
                    objIBAttr.SVMXC__SM_Attr_Name__c = strAttrName;
                    objIBAttr.SVMXC__SM_Attr_Value__c = (String)objInstalledProduct.get(mapIBFieldLabelVsAPIName.get(strAttrName));
                    objIBAttr.SVMXC__SM_Created_Date__c = System.now();
                    objIBAttr.SVMXC__SM_Installed_Product_id__c = objInstalledProduct.Id;
                    objIBAttr.SVMXC__SM_IsActive__c = true;
                    objIBAttr.SVMXC__SM_IBAttr_ExtId__c = (objInstalledProduct.Id + strAttrName).replace(' ','~') ;
                    lstTechnicalAttrToBeCreated.add(objIBAttr);
                    for(TechnicalAttributeFields objAttrFields : objInstancewrapper.fields){
                        for(TechnicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                            if(objTechAttr.label != null && strAttrName != null && objTechAttr.label.trim() == strAttrName.trim()){
                                String attrValue = (String)objInstalledProduct.get(mapIBFieldLabelVsAPIName.get(strAttrName));
                                if(attrValue == 'checked'){
                                    attrValue = 'true';
                                }else if(attrValue == 'unchecked'){
                                    attrValue = 'false';
                                }
                                objTechAttr.defaultValue = attrValue;
                                break;
                            }
                        }
                    }
                }
                String attrPayload = JSON.serialize(objInstancewrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
                objTechAttrInstance.SVMXC__SM_Attr_Payload__c = attrPayload;
                objTechAttrInstance.SVMXC__SM_Captured_On__c = system.today();
                objTechAttrInstance.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
                objTechAttrInstance.SVMXC__SM_Instance_Template_Id__c = lstAttrTemplate[0].Id;
                objTechAttrInstance.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                installedProdToTemplateInstace.put(objTechAttrInstance.SVMXC__SM_Installed_Product_Id__c,objTechAttrInstance);
                
                objTechAttrHistory.SVMXC__SM_Attr_Payload__c = attrPayload;
                objTechAttrHistory.SVMXC__SM_Captured_On__c = system.today();
                objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = objInstalledProduct.Id;
                objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                installedProdToAttrHistory.put(objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c ,objTechAttrHistory); 
                
                objInstalledProduct.IQ_OQ_For_IB_Attributes_JSON__c = null;
                objInstalledProduct.Is_IB_Attribute_Updated_from_IQ_OQ_Form__c = false;
            }
        }   
        
        if(!installedProdToTemplateInstace.isEmpty()){
            delete [Select Id from SVMXC__SM_IB_Attributes_Template_Instance__c 
                   Where SVMXC__SM_Installed_Product_Id__c IN : installedProductIdToRecordWithAttributesUpdated.keySet()];
            insert installedProdToTemplateInstace.values();
        }
        
         if(!installedProdToAttrHistory.isEmpty()){
            upsert installedProdToAttrHistory.values();
        }
        
        if(!lstTechnicalAttrToBeCreated.isEmpty()){
            upsert lstTechnicalAttrToBeCreated SVMXC__SM_IBAttr_ExtId__c ;
        }
        if(catchException == true){
            throw new AuraHandledException('throwing custom exceptions');
        }  
    }
    catch(Exception e){
        ApexExceptions.emit('IBTechinalAttributeCreationQueuable',e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
    }
    }
   /*
    * @Description- Wrapper Object
    */    
    private class TechnicalAttributeTemplateWrapper{
        List<TechnicalAttributeFields> fields {get;set;}
        //sObject picklist {get;set;}
    }
 
   /*
    * @Description- Wrapper Object
    */  
    private class TechnicalAttributeFields{
        String title {get;set;}
        String description {get;set;}
        List<TechnicalAttributes> technicalAttributes {get;set;}
    }
    
   /*
    * @Description- Wrapper Object
    */ 	
    private class TechnicalAttributePicklist{
        
    }
	
    @TestVisible
   /*
    * @Description- Wrapper Object
    */ 	
    private class TechnicalAttributes{
        @TestVisible String label {get;set;}
        @TestVisible String type {get;set;}
        @TestVisible String sequence {get;set;}
        @TestVisible String defaultValue {get;set;}
        @TestVisible String unit {get;set;}
        @TestVisible String readOnly {get;set;}
        @TestVisible String format {get;set;}
    }

}