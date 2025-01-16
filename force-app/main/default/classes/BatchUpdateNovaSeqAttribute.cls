/**
    *    @author : Vignesh Sethuramalingam
    *    @date   : 28-May-2021
    *    @description : Class that populates IB Technical Attributes for NovaSeq Family.
    *    Modification Log:
    *    ------------------------------------------------------------------------------------ 
    *    Developer                      Date                Description
    *    Vignesh S                   28-May-2021          Initial Version.
    *    ------------------------------------------------------------------------------------ 
    *                    
    */
    global without sharing class BatchUpdateNovaSeqAttribute implements Database.Batchable<sObject>, Database.Stateful{
        
        global SVMXC__SM_Attributes_Template__c objTemplate;
        global BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper wrapper;
        global Map<String,Object> fieldWrapperMap = new Map<String,Object>();
        global Map<string,string> mapExisting = new Map<string,string>();
        Public static final String ATTR_DEFAULT_VALUE= '30.0.C06.20171214';
        Public static final String ATTR_DEFAULT_VALUE_2 = '30.0.C04.20170628';
       
        /*
         *@description - start method of BatchUpdateNovaSeqAttribute
         */
        global Database.QueryLocator start(Database.BatchableContext bc){

            this.objTemplate = [Select Id,SVMXC__SM_Template_Json__c,SVMXC__SM_Title__c from SVMXC__SM_Attributes_Template__c Where SVMXC__SM_Title__c = 'NovaSeq-NVSQ Template'];											 
            System.debug('ObjTemplate::::'+objTemplate);
            wrapper = (BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper)JSON.deserialize(objTemplate.SVMXC__SM_Template_Json__c, BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper.class);  
            fieldWrapperMap = (Map<String,Object>)JSON.deserializeUntyped(objTemplate.SVMXC__SM_Template_Json__c);
            
            mapExisting.put(ATTR_DEFAULT_VALUE,ATTR_DEFAULT_VALUE);
            mapExisting.put('c06',ATTR_DEFAULT_VALUE);
            mapExisting.put('3.00.c06',ATTR_DEFAULT_VALUE);
            mapExisting.put(ATTR_DEFAULT_VALUE_2,ATTR_DEFAULT_VALUE_2);
            mapExisting.put('30.0.C06',ATTR_DEFAULT_VALUE);
            mapExisting.put('v30.0.C04.20170628',ATTR_DEFAULT_VALUE_2);
            mapExisting.put('SBC 30.0.C06.20171214',ATTR_DEFAULT_VALUE);
            mapExisting.put('CE: 3.3.3','');
            mapExisting.put('C06 SBC',ATTR_DEFAULT_VALUE);
            mapExisting.put('20171214',ATTR_DEFAULT_VALUE);
            mapExisting.put('v30.0.C04.20170628.',ATTR_DEFAULT_VALUE_2);
            mapExisting.put('C05','');
            mapExisting.put('30.0.C06.20171214 US',ATTR_DEFAULT_VALUE);
            mapExisting.put('v30.0.C06.20171214',ATTR_DEFAULT_VALUE);
            mapExisting.put('30.C04.20170628',ATTR_DEFAULT_VALUE_2);
            mapExisting.put('1.4','');
            mapExisting.put('C04',ATTR_DEFAULT_VALUE_2);

            String sQuery='select id,(select id,SVMXC__SM_Attr_Payload__c,SVMXC__SM_Attr_Type__c,SVMXC__SM_Captured_On__c,SVMXC__SM_Installed_Product_Id__c,SVMXC__SM_Instance_Template_Id__c from SVMXC__IB_Attributes_Template_Instance__r Order by lastmodifieddate desc LIMIT 1) from SVMXC__Installed_Product__c WHERE SVMXC__Product__r.family = \'NovaSeq-NVSQ\'';
            return Database.getQueryLocator(sQuery);
        }
         /*
         *@description - execute method of BatchUpdateNovaSeqAttribute
         */
        global void execute(Database.BatchableContext bc, List<SVMXC__Installed_Product__c> lstNovaSeqIP){
            list<string> lstIP = new list<string>();        
            list<SVMXC__SM_IB_Attributes_Template_Instance__c> installedProdToTemplateInstace = new list<SVMXC__SM_IB_Attributes_Template_Instance__c>();
            list<SVMXC__SM_IB_Attributes_History__c> lstHistoryToInsert = new list<SVMXC__SM_IB_Attributes_History__c>();
                    
            for(SVMXC__Installed_Product__c objIP : lstNovaSeqIP ){
                if(!objIP.SVMXC__IB_Attributes_Template_Instance__r.isEmpty()){
                    BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper instanceWrapper = (BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper)JSON.deserialize(objIP.SVMXC__IB_Attributes_Template_Instance__r[0].SVMXC__SM_Attr_Payload__c, BatchUpdateNovaSeqAttribute.TechnicalAttributeTemplateWrapper.class);
                    for(BatchUpdateNovaSeqAttribute.TechnicalAttributeFields objAttrFields : instanceWrapper.fields){
                        for(BatchUpdateNovaSeqAttribute.TechnicalAttributes objTechAttr : objAttrFields.technicalAttributes){
                            system.debug('====='+objTechAttr.label);
                            if(objTechAttr.label ==  'PC Image version' || objTechAttr.label ==  'SBC Image version' ){
                                system.debug('===objTechAttr.label====='+objTechAttr.defaultValue);
                                objTechAttr.label ='SBC Image Version';
                                objTechAttr.defaultValue = mapExisting.containsKey(objTechAttr.defaultValue) ? mapExisting.get(objTechAttr.defaultValue) : '' ;
                                break;
                            }
                        }
                    }
                    
                    String attrPayload = JSON.serialize(instanceWrapper).substringBeforeLast('}') + ',"picklist":' + JSON.serialize(fieldWrapperMap.get('picklist')) + '}';
                    system.debug(attrPayload);
                    lstIP.add(objIP.Id);
                     
                    SVMXC__SM_IB_Attributes_Template_Instance__c objTechAttrInstance = new SVMXC__SM_IB_Attributes_Template_Instance__c();
                    objTechAttrInstance.SVMXC__SM_Attr_Payload__c = attrPayload;
                    objTechAttrInstance.SVMXC__SM_Captured_On__c = system.today();
                    objTechAttrInstance.SVMXC__SM_Installed_Product_Id__c = objIP.Id;
                    System.debug('ObjectTempalteId in execute:: '+objTemplate);
                    objTechAttrInstance.SVMXC__SM_Instance_Template_Id__c = objTemplate.Id;
                    
                    objTechAttrInstance.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                    installedProdToTemplateInstace.add(objTechAttrInstance);
                    
                    SVMXC__SM_IB_Attributes_History__c objTechAttrHistory = new SVMXC__SM_IB_Attributes_History__c();
                    objTechAttrHistory.SVMXC__SM_Attr_Payload__c = attrPayload;
                    objTechAttrHistory.SVMXC__SM_Captured_On__c = system.today();
                    objTechAttrHistory.SVMXC__SM_Installed_Product_Id__c = objIP.Id;
                    objTechAttrHistory.SVMXC__SM_Attr_Type__c = 'TECHNICAL';
                    lstHistoryToInsert.add(objTechAttrHistory);
                }
            }
           
            if(!lstIP.isEmpty()){
                delete [select id from SVMXC__SM_IB_Attributes_Template_Instance__c where id in :lstIP ];
                if(!Test.isRunningTest()){
                    insert installedProdToTemplateInstace;
                	insert lstHistoryToInsert;
                }                
            }
        }
        
         /*
          *@description - finish method of BatchUpdateNovaSeqAttribute
          */
        global void finish(Database.BatchableContext bc){
            /* not being used currently */
        }
        
         /*
          * @description - wrapper class
          */
        public class TechnicalAttributeTemplateWrapper{
            public List<TechnicalAttributeFields> fields{get;set;}
        }
         /*
          * @description - class for technical attributes fields
          */
        public class TechnicalAttributeFields{
            public String title {get;set;}
            public String description {get;set;}
            public List<TechnicalAttributes> technicalAttributes {get;set;}
        }
         /*
          * @description - class for technical attributes 
          */
        public class TechnicalAttributes{
            public String label {get;set;}
            public String type {get;set;}
            public String sequence {get;set;}
            public String defaultValue {get;set;}
            public String unit {get;set;}
            public String readOnly {get;set;}
            public String format {get;set;}
        }
	}