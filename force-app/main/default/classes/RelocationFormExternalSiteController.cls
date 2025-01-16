/***************************************************************************************************************************************
* @Author:  KD
* @Date:   04-June-2021 
* @Description: DCP-38876 To capture Relocation specific information(Relocation Requirements Form LWC).
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                           DESCRIPTION 
* ------------------------------------------------------------------------------------
* KD                       04-June-2021                   Initial Version
* Akshay Mohan             04-June-2021                   Save method
******************************************************************************************************************************************************************/
public without sharing class RelocationFormExternalSiteController {
    
    private static final String LOG_TITLE = 'RelocationFormExternalSiteController';
    public final static String RELOCATION_REQUIREMENTS_FORM_OBJECT_NAME = 'Relocation_Requirements_Form__c';
    public String strPicklistDetails {get;set;}
    /**
    *  @author KD
    *  @description Entry method for verify passkey
    *  @param String strUserPassKey,String strRecordId
    *  @return String
    **/
    @AuraEnabled(cacheable=true)
    public static String checkUserAuthenticity(String strUserPassKey,String strRecordId){
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.checkUserAuthenticity('+strUserPassKey+','+strRecordId+')');
        try{
            Relocation_Requirements_Form__c objRelocationForm = new RelocationRequirementsFormsSelector().getPassbyId(strRecordId);
            ilib_LogEvent.message('objRelocationForm: '+objRelocationForm);
            if(!strUserPassKey.equals(objRelocationForm.Pass_Key__c)){
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return 'User Not Authorized';
            }
        }catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,strRecordId,e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return 'Success';
    }
    
    /**
    *  @author KD
    *  @description Entry method for fetch page layout [Re-used MDG controller as funtionality remains same]
    *  @param record id
    *  @return JSON
    **/
    @AuraEnabled(cacheable=true)
    public static String loadPage(String strRecordId){
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.loadPage('+strRecordId+')');
        try{
            Relocation_Requirements_Form__c objRelocationForm = new RelocationRequirementsFormsSelector().getRecordbyId(strRecordId);
            ilib_LogEvent.message('objRelocationForm: '+objRelocationForm);
            Map<String, Object> mapRecordFieldToValue = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(objRelocationForm));
            String strPageLayoutName = 'Relocation_Requirements_Form__c-Relocation Requirements Form Layout';
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return '{"LayoutStructure": '+JSON.serialize(getPageLayoutMetadata(strPageLayoutName))+','
            +'"mapRecordFieldToValue": '+JSON.serialize(mapRecordFieldToValue)+'}';
        }
        catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,strRecordId,e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    /**
    *  @author Akshay Mohan
    *  @description Save method
    *  @param record id
    *  @return String
    **/
    @AuraEnabled
    public static String doSave(String strRecordId,String strJSON){
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.doSave('+strRecordId+')');
        ilib_LogEvent.message('strJSON: '+strJSON);
        try{
            Relocation_Requirements_Form__c objForm = new Relocation_Requirements_Form__c(Id=strRecordId);
            ilib_LogEvent.message('mapFields '+objForm.getSObjectType().getDescribe().fields.getMap());
            Map<String, Schema.SObjectField> mapFields= (Map<String, Schema.SObjectField>)objForm.getSObjectType().getDescribe().fields.getMap();
            for(Object objValue: (List<Object>)JSON.deserializeUntyped(strJSON)){
                Map<String,Object> mapValue=(Map<String,Object>)objValue;
                ilib_LogEvent.message('mapValue: '+mapValue);
                String strField=String.valueOf(mapValue.get('fieldApiName'));
                Object value=mapValue.get('value');
                switch on mapFields.get(strField).getDescribe().getType(){
                    when Date{objForm.put(strField,Date.valueOf(String.valueOf(value)));}
                    when DateTime{objForm.put(strField,(DateTime)JSON.deserialize('"' + String.valueOf(value) + '"', DateTime.class));}
                    when Double{objForm.put(strField,Double.valueOf(String.valueOf(value)));}
                    when Integer{objForm.put(strField,Integer.valueOf(String.valueOf(value)));}
                    when else{objForm.put(strField,value);}
                }
                
            }
            ilib_LogEvent.message('objForm: '+objForm);
            update objForm;
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,strRecordId,e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return 'Success';
    }

    /**
    *  @author KD
    *  @description get Site URL
    *  @param 
    *  @return Site URL
    **/
    @InvocableMethod(label='Get Site URL')
    public static List<String> getSiteURL(){
        Site objSite = [Select id from Site where Name = 'Relocation_Form' LIMIT 1];
        SiteDetail objSiteDetail = [Select id,SecureUrl from SiteDetail where DurableId =:objSite.Id];
        return new List<String>{objSiteDetail.SecureUrl};
    }

    /**
    *  @author KD
    *  @description To get the metadata for the pagelayout
    *  @param pageLayoutName
    *  @return PageLayout
    **/
    @AuraEnabled
    public static MasterDataRequestController.PageLayout getPageLayoutMetadata(String pageLayoutName) {
        List<String> lstComponentNameList = new List<String>{pageLayoutName};       
        /*User Standard MetaData class for fetching layout details*/
        List<Metadata.Metadata> layouts =  
            Metadata.Operations.retrieve(Metadata.MetadataType.Layout, lstComponentNameList);
        try{    
        Integer layoutSize = 1;
        if (layouts.size() == layoutSize) {
            system.debug('  layouts[0]: ' + layouts[0]);
            
            return new MasterDataRequestController.PageLayout((Metadata.Layout) layouts[0]);
        }
        
        return new MasterDataRequestController.PageLayout();
        }catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,pageLayoutName,e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    *  @author KD
    *  @description method to fetch picklist translation
    **/
    public void getPicklistValueTranslation(){
        Map<String,Object> mapAPINameToPicklistTranslatedValue = new Map<String,Object>();
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.getFieldType()');
        Map<String, Schema.SObjectField> mapFields= Schema.SObjectType.Relocation_Requirements_Form__c.fields.getMap();
        for(String strFieldAPIName : mapFields.keySet()){
            Schema.DisplayType strFieldType = mapFields.get(strFieldAPIName).getDescribe().getType();
            if(strFieldAPIName != 'CurrencyIsoCode' 
                && (strFieldType == Schema.DisplayType.PICKLIST || strFieldType == Schema.DisplayType.MULTIPICKLIST)){
                    mapAPINameToPicklistTranslatedValue.put(strFieldAPIName,DynamicInputFieldController.getPicklistOptions(strFieldAPIName,mapFields));
            }
        }
        ilib_LogEvent.message('mapAPINameToPicklistTranslatedValue-->'+JSON.serialize(mapAPINameToPicklistTranslatedValue));
        strPicklistDetails = String.escapeSingleQuotes(JSON.serialize(mapAPINameToPicklistTranslatedValue));
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}