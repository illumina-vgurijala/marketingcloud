/**
 *    @author Gerardo Garcia
 *    @description  : Interface that contains methods for validation of payload
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                  Date                   Description
 *    Vinay S Reddy            14-Oct-2024             CMCM-2890 Initial Version
 *    Gerardo Garcia           29-Oct-2024             CMCM-2890 Move it into own class.
 *    ------------------------------------------------------------------------------------
 **/
public without sharing class RestOpportunityQuoteCreationValidator implements WebServicePayloadValidator {
    private static final String METADATA_SEPARATOR = '\\|';
    public static List<MetadataWrapper> fields2Validate = new List<MetadataWrapper>();
    public static final String SOURCE_FIELD_DEFAULT = 'SourceSystem';
    public static final String SOURCE_FIELD_WRAPPER = 'sourceSystem';


    /**
     * @author: Gerardo Garcia
     * @description: Validates Schema, relaying on getting the fields on custom metadata Quote_Creation_API_Payload_Validation__mdt
     * Throw Exception InvalidSchemaException
     */
    public void validateSchema(String strJsonData) {
        Map<String,Object> payload = (Map<String,Object>)JSON.deserializeUntyped(strJsonData);
        String source = '';

        if(payload.containsKey(SOURCE_FIELD_DEFAULT)){
            source = (String) payload.get(SOURCE_FIELD_DEFAULT);
        }else if(payload.containsKey(SOURCE_FIELD_WRAPPER)){
            source = (String) payload.get(SOURCE_FIELD_WRAPPER);
        }
        List<String> returnViolatingFieldList = new List<String>();
        
        if(fields2Validate == null){
            throw new InvalidSchemaException('Invalid source system: ' + source);
        }

        if(fields2Validate.isEmpty()){
            fields2Validate = getValidationFields(source);
        }
        if(fields2Validate == null){
            throw new InvalidSchemaException('Invalid source system: ' + source);
        }

        for(MetadataWrapper wrapper : fields2Validate) {
            String crossValidatingFields = wrapper.fields.toUpperCase();
            if(wrapper.isRoot) {
                ilib_LogEvent.message('Level ONE key set '+ payload.keySet());
                
                for(String strField: payload.keySet()){
                    if(!crossValidatingFields.contains(strField.toUpperCase())) {//flag=true;
                        returnViolatingFieldList.add(strField);
                    }//flag contract violation
                }
            } else if(payload.containsKey(wrapper.key)){
                List<Object> quoteRelatedItems = (List<Object>)payload.get(wrapper.key);

                Set<String> keysetOfIndividualfields = new Set<String>();
                for (Integer i=0; i < quoteRelatedItems.size(); i++){
                    Map<String,Object> individualFields = (Map<String,Object>)quoteRelatedItems[i];
                    keysetOfIndividualfields.addAll(individualFields.keySet());
                }
                ilib_LogEvent.message('Level TWO key set '+keysetOfIndividualfields);
                for(String strField: keysetOfIndividualfields){
                    if(!crossValidatingFields.contains(strField.toUpperCase())) {//flag=true;
                        returnViolatingFieldList.add(strField);
                    }//flag contract violation
                }
            }
        }

        ilib_LogEvent.message('Returning violated fields '+ returnViolatingFieldList);
        if(returnViolatingFieldList.size() > 0) {
            throw new InvalidSchemaException('JSON Violates the Contract with following extra fields:' + returnViolatingFieldList);
        }
    }

    /**
     * @author: Arquimidez Mora
     * @description: Gets map of custom metadata that are representation of json schema fields.
     */
    public static Map<String, List<MetadataWrapper>> getMetadataConfiguration(){
        Map<String, List<MetadataWrapper>> getMetadataConfigResult = new Map<String, List<MetadataWrapper>>();
        Map<String, Quote_Creation_API_Payload_Validation__mdt> mapMetadataConfig =  Quote_Creation_API_Payload_Validation__mdt.getAll();

        for(Quote_Creation_API_Payload_Validation__mdt objMetadataConfig : mapMetadataConfig.values()){
            fillMapWithSchemaMetadata(getMetadataConfigResult, objMetadataConfig);
        }
        ilib_LogEvent.message(JSON.serializePretty(getMetadataConfigResult));
        return getMetadataConfigResult;
    }

    private static void fillMapWithSchemaMetadata(Map<String, List<MetadataWrapper>> getMetadataConfigResult, Quote_Creation_API_Payload_Validation__mdt objMetadataConfig) {
        if(!getMetadataConfigResult.containsKey(objMetadataConfig.Source_System__c)){

            String strLevel1Fields = getLevel1Fields(objMetadataConfig);
            
            String strLevel2Fields = getLevel2Fields(objMetadataConfig);

            List<MetadataWrapper> wrappers = new List<MetadataWrapper>();
            wrappers.add(getWrapper(null, strLevel1Fields));
            ilib_LogEvent.message('strLevel2Fields:' + strLevel2Fields);

            List<String> level2 = strLevel2Fields.split(METADATA_SEPARATOR);
            String key = null;
            for(String eval : level2) {
                if(key == null) {
                    key = eval;
                } else {
                    wrappers.add(getWrapper(key, eval));
                    key = null;
                }
            }

            getMetadataConfigResult.put(objMetadataConfig.Source_System__c, wrappers);
        }
    }

    private static String getLevel1Fields(Quote_Creation_API_Payload_Validation__mdt objMetadataConfig) {
        String strLevel1Fields = String.isNotBlank(objMetadataConfig.Level1FieldsPart1__c) ? objMetadataConfig.Level1FieldsPart1__c : '';
        if(objMetadataConfig.Level1FieldsPart2__c != null){
            strLevel1Fields += objMetadataConfig.Level1FieldsPart2__c;
        }
        if(objMetadataConfig.Level1FieldsPart3__c != null){
            strLevel1Fields += objMetadataConfig.Level1FieldsPart3__c;
        }
        if(objMetadataConfig.Level1FieldsPart4__c != null){
            strLevel1Fields += objMetadataConfig.Level1FieldsPart4__c;
        }
        return strLevel1Fields;
    }

    private static String getLevel2Fields(Quote_Creation_API_Payload_Validation__mdt objMetadataConfig) {
        String strLevel2Fields = String.isNotBlank(objMetadataConfig.Level2FieldsPart1__c) ? objMetadataConfig.Level2FieldsPart1__c : '';
        if(objMetadataConfig.Level2FieldsPart2__c != null){
            strLevel2Fields += objMetadataConfig.Level2FieldsPart2__c;
        }
        if(objMetadataConfig.Level2FieldsPart3__c != null){
            strLevel2Fields += objMetadataConfig.Level2FieldsPart3__c;
        }
        if(objMetadataConfig.Level2FieldsPart4__c != null){
            strLevel2Fields += objMetadataConfig.Level2FieldsPart4__c;
        }

        return strLevel2Fields;
    }

    private static MetadataWrapper getWrapper(String key, String fields) {
        MetadataWrapper objMetadataWrapper = new MetadataWrapper();
        if(key != null) {
            objMetadataWrapper.isRoot = false;
            objMetadataWrapper.key = key;
        } else {
            objMetadataWrapper.isRoot = true;
        }
        objMetadataWrapper.fields = fields;
        return objMetadataWrapper;
    }

    /**
     * @author: Gerardo Garcia
     * @description: Gets list of MetadataWrapper from given source.
     */
    public static List<MetadataWrapper> getValidationFields(String source) {
        return getMetadataConfiguration().get(source);
    }

    /**
     * @description: MetadataWrapper representation
     */
    public class MetadataWrapper{
        public String key;
        public String fields;
        public Boolean isRoot;
    }

    /**
     * Exception to handle invalid schema
     */
    public class InvalidSchemaException extends Exception {}

}