/***************************************************************************************************************************************
* @Author:  Gladis
* @Date:   02-July-2021 
* @Description: DCP-38876 To capture Relocation specific information(Relocation Requirements Form LWC).
* Modification Log:
* ------------------------------------------------------------------------------------
* DEVELOPER                DATE                           DESCRIPTION 
* ------------------------------------------------------------------------------------
* Gladis                  02-July-2021                   Initial Version
******************************************************************************************************************************************************************/
public without sharing class DynamicInputFieldController {

    private static final String LOG_TITLE = 'DynamicInputFieldController';
    
    /**
    *  @author Gladis
    *  @description Fetching Picklist/Multi-Select Options
    *  @param String sFieldName
    *  @return String
    **/
    public static List<PickListValueWrapper> getPicklistOptions(String strFieldAPIName,Map<String, Schema.SObjectField> mapFields){
        system.debug('strFieldAPIName--'+strFieldAPIName);
        system.debug('mapFields--'+mapFields);
        ilib_LogEvent.push(LOG_TITLE + '.getPicklistOptions('+strFieldAPIName+')');
        
        List<PickListValueWrapper> lstPickvals = new List<PickListValueWrapper>();
        lstPickvals = UtilsObject.getPicklistValuesWrapper(mapFields,strFieldAPIName,lstPickvals);
        ilib_LogEvent.message('strJSON: '+JSON.serialize(lstPickvals));
        return lstPickvals;
 
    }
    /**
    *  @author Gladis
    *  @description Fetching Picklist/Multi-Select Options
    *  @param String sFieldName
    *  @return String
    **/

    @AuraEnabled
    public static String getFieldType(String strFieldAPIName){   
        ilib_LogEvent.rootTitle = LOG_TITLE;
        ilib_LogEvent.push(LOG_TITLE + '.getFieldType('+strFieldAPIName+')');
        List<PickListValueWrapper> lstPickvals = new List<PickListValueWrapper>();
        Map<String, Schema.SObjectField> mapFields= Schema.SObjectType.Relocation_Requirements_Form__c.fields.getMap();
        Schema.DisplayType strFieldType = mapFields.get(strFieldAPIName).getDescribe().getType();
        ilib_LogEvent.message('strFieldType: '+strFieldType);
        try{

            if(strFieldType == Schema.DisplayType.PICKLIST || strFieldType == Schema.DisplayType.MULTIPICKLIST){
                lstPickvals = getPicklistOptions(strFieldAPIName,mapFields);
            }
            ilib_LogEvent.message('{"fieldType": "'+strFieldType.name()+'",'
                +' "lstPickvals": '+JSON.serialize(lstPickvals)+'}');
            return '{"fieldType": "'+strFieldType.name()+'",'
                +' "lstPickvals": '+JSON.serialize(lstPickvals)+'}';
        }
        catch(Exception e){
            ApexExceptions.emit(LOG_TITLE,strFieldAPIName,e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            throw new AuraHandledException(e.getMessage()); 
        }
           
    }


}