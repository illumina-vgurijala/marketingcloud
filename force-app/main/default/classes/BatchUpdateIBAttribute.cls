/**
    *    @author : Vignesh Sethuramalingam
    *    @date   : 17-Dec-2019
    *    @description : Class that populates IB Technical Attributes with Internal objects.
    *    Modification Log:
    *    ------------------------------------------------------------------------------------ 
    *    Developer                      Date                Description
    *    Vignesh S                   17-Dec-2019          Initial Version.
    *    ------------------------------------------------------------------------------------ 
    *                    
    */
    global without sharing class BatchUpdateIBAttribute implements Database.Batchable<sObject>{
        
        global Map<string,string> mapProductFamilyName = new Map<String,string>();
        global Map<string,Map<String,Object>> mapIBTemplatePicklist = new Map<string,Map<String,Object>>();
        global Map<string,Id> mapIBTemplateWrapper = new Map<string,Id>(); 
        //global Map<String,BatchUpdateIBAttribute.TechnicalAttributeTemplateWrapper> mapIBTemplate = new Map<String,BatchUpdateIBAttribute.TechnicalAttributeTemplateWrapper>();
        global Map<String,String> mapIBTemplate = new Map<String,String>();
         
        //global Map<Id,String> mapIPIdToWFMValue = new Map<Id,String>();       
        public String productFamily;
         
		
         /*
          * Constructor
          */
        global BatchUpdateIBAttribute(String productFamily){
            for(SVMXC__SM_Product_Attributes__c objProdAtt : [select ID,SVMXC__SM_Product_Family__c,
                                                              SVMXC__SM_Attribute_Template_Id__r.Id,
                                                              SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Template_Json__c,
                                                              SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c
                                                              from SVMXC__SM_Product_Attributes__c WHERE SVMXC__SM_Product_Family__c =: productFamily  AND SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c != Null]){
                                                                  
                                                                  Map<String,Object> fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Template_Json__c);
                                                                  
                                                                  mapIBTemplate.put(objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c, objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Template_Json__c);
                                                                  mapIBTemplatePicklist.put(objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c,fieldWrapperMap);
                                                                  mapIBTemplateWrapper.put(objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c, objProdAtt.SVMXC__SM_Attribute_Template_Id__r.Id);
                                                                  mapProductFamilyName.put(objProdAtt.SVMXC__SM_Product_Family__c, objProdAtt.SVMXC__SM_Attribute_Template_Id__r.SVMXC__SM_Title__c);
                                                              }
            
            this.productFamily=productFamily;
            //37550 start
            /*for(SVMXC__SM_IB_Technical_Attributes__c objIBTechAttr : [select id,SVMXC__SM_Installed_Product_id__c,SVMXC__SM_Attr_Value__c,SVMXC__SM_Installed_Product_id__r.SVMXC__Product__r.family from SVMXC__SM_IB_Technical_Attributes__c where SVMXC__SM_Installed_Product_id__r.SVMXC__Product__r.family ='Workflow Manager' and SVMXC__SM_Attr_Value__c != null]){
                mapIPIdToWFMValue.put(objIBTechAttr.SVMXC__SM_Installed_Product_id__c, objIBTechAttr.SVMXC__SM_Attr_Value__c);
            }*///37550 end
        }
        
   /*
    * method: start method
    * Params: Database.BatchableContext
    */
        global Database.QueryLocator start(Database.BatchableContext bc){

            //37550 starts
            //Set<Id> setInstalledProductIDs = mapIPIdToWFMValue.keySet();//37550 end
            String sQuery='select id,SVMXC__Product__r.family,(select id,SVMXC__SM_Attr_Name__c,SVMXC__SM_Attr_Value__c,SVMXC__SM_Installed_Product_id__c from SVMXC__Technical_Attributes__r) from SVMXC__Installed_Product__c';
            if(!String.isBlank(productFamily)){
                sQuery=sQuery+' where SVMXC__Product__r.family Like \'%'+String.escapeSingleQuotes(productFamily)+'%\' ';
            //37550 start             
                //sQuery = sQuery + ':setInstalledProductIDs';//37550 end
            }else{
                sQuery=sQuery+' where SVMXC__Product__r.family != Null';
            }       
            
            System.debug('sQuery..'+sQuery);
            return Database.getQueryLocator(sQuery);
        }
   /*
    * method: execute method
    * Params: Database.BatchableContext , List<sObject> lstRecords
    * return: void
    */
        global void execute(Database.BatchableContext bc, List<SVMXC__Installed_Product__c> lstIP){
            list<SVMXC__SM_IB_Attributes_History__c> attrHistoryToInsert = new list<SVMXC__SM_IB_Attributes_History__c>();
            Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c> mapTemplateInstancetoInsert = new Map<String,SVMXC__SM_IB_Attributes_Template_Instance__c>();
            for(SVMXC__Installed_Product__c objIP : lstIP){
                 
                list<SVMXC__SM_IB_Technical_Attributes__c> lstTA = new list<SVMXC__SM_IB_Technical_Attributes__c>();
                lstTA = objIP.SVMXC__Technical_Attributes__r;
                
                if( objIP.SVMXC__Product__c != Null && objIP.SVMXC__Product__r.family != Null && mapProductFamilyName.containsKey(objIP.SVMXC__Product__r.family)){
                    string templateName = mapProductFamilyName.get(objIP.SVMXC__Product__r.family);
                    
                    string strWrapper = mapIBTemplate.get(templateName);
                    BatchUpdateIBAttribute.TechnicalAttributeTemplateWrapper wrapper = (TechnicalAttributeTemplateWrapper)JSON.deserialize( strWrapper , TechnicalAttributeTemplateWrapper.class);
                    Map<String,Object> fieldWrapperMap = mapIBTemplatePicklist.get(templateName);
                                        
                    TechnicalAttributeTemplateWrapper clonedWrapper = new TechnicalAttributeTemplateWrapper();
                    list<TechnicalAttributeFields> clonedlist = new list<TechnicalAttributeFields>();
                    clonedlist.addall(wrapper.fields);
                    clonedWrapper.fields = clonedlist;

                    for(SVMXC__SM_IB_Technical_Attributes__c objIBTA : lstTA  ){
                        for(TechnicalAttributeFields objAttrFields : clonedWrapper.fields){
                            
                            for(TechnicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                            //37550 start
                                if(objTechAttr.label != null && objIBTA.SVMXC__SM_Attr_Name__c != null && objTechAttr.label.trim() == objIBTA.SVMXC__SM_Attr_Name__c.trim()){
                                    String attrValue = objIBTA.SVMXC__SM_Attr_Value__c;
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
                    
                    String attrPayload = JSON.serialize(clonedWrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
                    SVMXC__SM_IB_Attributes_Template_Instance__c objTechAttrInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
                    objTechAttrInstance.SVMXC__SM_Attr_Payload__c = attrPayload;
                    objTechAttrInstance.SVMXC__SM_Captured_On__c = system.today();
                    objTechAttrInstance.SVMXC__SM_Installed_Product_Id__c = objIP.Id;
                    objTechAttrInstance.SVMXC__SM_Instance_Template_Id__c =  mapIBTemplateWrapper.get(templateName);
                    objTechAttrInstance.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                    mapTemplateInstancetoInsert.put(objIP.Id,objTechAttrInstance);
                    
                    SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
                    objTechAttrHistory.SVMXC__SM_Attr_Payload__c = attrPayload;
                    objTechAttrHistory.SVMXC__SM_Captured_On__c = system.today();
                    objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = objIP.Id;
                    objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                    attrHistoryToInsert.add(objTechAttrHistory); 
                }
            }
            
            if(!attrHistoryToInsert.isEmpty() || !mapTemplateInstancetoInsert.isEmpty()){
                QueueableUpdateIBAttribute esync = new QueueableUpdateIBAttribute(attrHistoryToInsert, mapTemplateInstancetoInsert);
                System.enqueueJob(esync);
            }
        }
        
   /*
    * Method: finish
    * Params: Database.BatchableContext
    * return: void
    */
        global void finish(Database.BatchableContext bc){
         /* not being used currently */
        }
        
		/*
		 * Description - Wrapper Class TechnicalAttributeTemplateWrapper
		 */
        public class TechnicalAttributeTemplateWrapper{
            public List<TechnicalAttributeFields> fields{get;set;}
			 /*
              * Constructor of TechnicalAttributeTemplateWrapper
			  */
            public TechnicalAttributeTemplateWrapper(){}
        }
        /*
		 * Description - Wrapper Class TechnicalAttributeFields
		 */
        public class TechnicalAttributeFields{
            public String title {get;set;}
            public String description {get;set;}
            public List<TechnicalAttributes> technicalAttributes {get;set;}
			 /*
              * Constructor of TechnicalAttributeFields
			  */
            public TechnicalAttributeFields() {}
        }
        
		/*
		 * Description - Wrapper Class TechnicalAttributes
		 */
        public class TechnicalAttributes{
            public String label {get;set;}
            public String type {get;set;}
            public String sequence {get;set;}
            public String defaultValue {get;set;}
            public String unit {get;set;}
            public String readOnly {get;set;}
            public String format {get;set;}
			/* called TechnicalAttributes */
            public TechnicalAttributes(){}
        }
	}