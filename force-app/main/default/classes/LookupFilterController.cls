/**
*    @author : Akshay 
*    @date   18-Jan-20 
*    @description    Controller class for LWC lookUpFilter
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Akshay                         18-Jan-20           Initial build
*             Anand Palla                    26-Apr-22           CodeScan Fix-Avoid Literals in If condition
*             Aman Tyagi                     31-Mar-2022         Codescan Fixes
*             Adyasha Satapathy              24-May-2022         Incident - INC0399200: Update the string literal 
*             Iram Malik                     14-Jul-2022         Codescan fix
*             Jitesh Lakhwani                21-Feb-2023         Codescan - Avoid unused Variable
* ------------------------------------------------------------------------------------
*
*/
public with sharing class LookupFilterController {

    //constants
    private static final String OPERATOR_REGEX = '[=]|[>=]|[!=]|[<=]|[<>]|[>]|[<]';
    private static final Set<String> FORMULA_CONDITIONS = new Set<String>{'TODAY','true','false'};
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_TWO = 2;
    //End CodeScan Fix
    public static final String API_SUFFIX = '__c'; //INC0399200
    public static final String NAME_FIELD = 'Name';
    public static final String NOT_FOUND_IN =' not found in ';

    /*
    * @Author: Akshay
    * @Description : class for storing the input details
    */ 
    public class InputDetails{
        public String strLookupApiName;
        public String strObjectApiName;
        public String strFieldFilters;
        public String strSearchFields;
        public String strDisplayFields;
        public String strOrderBy;
        public String strSearch;
    }

    /*
    * @Author: Akshay
    * @Description : class for storing the output details
    */
    public class OutputFields{
        public List<String> lstErrors;
        public Map<Integer,String> mapFieldToPositions;
        public List<DataTableWrapper> lstColumns;
        public String strLookupLabel,strSourceObject,strLookupId;

        /*
        * @Author: Akshay
        * @Description : parameterized constructor of class OutputFields
        * @param:null
        */
        public OutputFields(){
            mapFieldToPositions = new Map<Integer,String>();
            lstErrors = new List<String>();
            lstColumns = new List<DataTableWrapper>();
        }
    }

    
    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method runs on Page Load
    *  @PARAM :  String idRecord,strInputJSON
    *  @RETURN:  String JSON of page load details
    */ 
    
    @AuraEnabled(cacheable = true)
    public static  String loadPage(id idRecord,String strInputJSON){ 
        System.debug('idRecord: ' + idRecord);
        System.debug('strInputJSON: ' + strInputJSON);
        InputDetails wrapInput = (InputDetails)JSON.deserialize(strInputJSON, InputDetails.class);
        System.debug('wrapInput: ' + wrapInput);
        Schema.DescribeSObjectResult objDR = idRecord.getSObjectType().getDescribe();
        System.debug('objDR: ' + objDR);
        Schema.DescribeSObjectResult objTargetDR = Schema.getGlobalDescribe().get(wrapInput.strObjectApiName).getDescribe();
        System.debug('objTargetDR: ' + objTargetDR);
        OutputFields wrapFields = processFields(wrapInput, objDR, objTargetDR);
        wrapFields.strSourceObject = objDR.getName();
        String strValue;
        if(wrapFields.lstErrors.isEmpty()){
            String strRelationshipField;
            Map<String,Schema.SObjectField> sourceFields = objDR.fields.getMap();
            if(sourceFields.get(wrapInput.strLookupApiName).getDescribe().isCustom())
                strRelationshipField = wrapInput.strLookupApiName.replace(API_SUFFIX, '__r');
            else
                strRelationshipField = wrapInput.strLookupApiName.replace('Id', '');
            String strRecordId = String.valueOf(idRecord);
            String strQuery = 'SELECT '+strRelationshipField+'.Name,'+wrapInput.strLookupApiName
                                +' FROM '+objDR.getName()+' WHERE ID =:strRecordId';
            System.debug('strQuery: ' + strQuery);
            
            SObject objValue = Database.query(strQuery)[0];
            System.debug('objValue: ' + objValue);
            if(objValue.get(wrapInput.strLookupApiName)!=null){
                strValue = String.valueOf(objValue.getSObject(strRelationshipField).get(NAME_FIELD));
                wrapFields.strLookupId= String.valueOf(objValue.get(wrapInput.strLookupApiName));
            }else
                strValue = '';
            wrapFields.strLookupLabel = sourceFields.get(wrapInput.strLookupApiName).getDescribe().getLabel();
        }
        System.debug('strValue: ' + strValue);
        return '{"wrapFields" : '+JSON.serialize(wrapFields)
                +',"strValue" : "'+strValue+'"}';
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to process field configurations 
    *  @PARAM :  InputDetails wrapInput,Schema.DescribeSObjectResult objDR,Schema.DescribeSObjectResult objTargetDR
    *  @RETURN:  OutputFields of fields processed
    */ 
    @AuraEnabled(cacheable = true)
    public static String doSearch(id idRecord,String strInputJSON,String strFieldsWrapper){
        System.debug('idRecord: ' + idRecord);
        
        System.debug('strInputJSON: ' + strInputJSON);
        InputDetails wrapInput = (InputDetails)JSON.deserialize(strInputJSON, InputDetails.class);
        System.debug('wrapInput: ' + wrapInput);
        
        System.debug('strFieldsWrapper: ' + strFieldsWrapper);
        OutputFields wrapFields = (OutputFields)JSON.deserialize(strFieldsWrapper, OutputFields.class);
        System.debug('wrapFields: ' + wrapFields);

        String strQuery = 'SELECT '+wrapInput.strDisplayFields;
        Set<String> setDisplayFields = new Set<String>(wrapInput.strDisplayFields.split(','));
        if(!setDisplayFields.contains(NAME_FIELD))
            strQuery+=',NAME';
        setDisplayFields.add(NAME_FIELD);
        if(!setDisplayFields.contains('Id'))
            strQuery+=',Id';
        setDisplayFields.add('Id');

        strQuery+=' FROM '+wrapInput.strObjectApiName+' WHERE (';
        Boolean booFirst=true;
        for(String strSearchField : wrapInput.strSearchFields.split(','))
            if(booFirst){
                booFirst = false;
                strQuery+=strSearchField+' LIKE \'%'+wrapInput.strSearch+'%\'';
            }else {
                strQuery+=' OR '+strSearchField+' LIKE \'%'+wrapInput.strSearch+'%\'';
            }
        strQuery+=') ';
        
        Map<String,String> mapValues = processFields(new Set<String>(wrapFields.mapFieldToPositions.values()), idRecord, idRecord.getSObjectType().getDescribe().getName());
        
        String strFilterPart = setFieldValues(wrapInput.strFieldFilters,wrapFields.mapFieldToPositions,mapValues);
        System.debug('strFilterPart: ' + strFilterPart);

        strQuery+=' AND ('+strFilterPart+')';

        if(String.isNotBlank(wrapInput.strOrderBy))
            strQuery+=' ORDER BY '+wrapInput.strOrderBy;

        System.debug('strQuery: ' + strQuery);
        List<SObject> lstValues = Database.query(strQuery);
        System.debug('lstValues: ' + lstValues);        

        return searchResults(lstValues, setDisplayFields, idRecord);
    } 

    /*
    *  @AUTHOR:  Rishi Sharma
    *  @DESCRIPTION: method to return search results 
    *  @PARAM :  InputDetails lstExpOrExisting, lstResults, strExistingSubscription, idRecord
    *  @RETURN:  List of Search results
    */ 
    private static String searchResults(List<SObject> lstValues, Set<String> setDisplayFields, id idRecord){
        String strEndDateField = 'Apttus_Config2__EndDate__c';
        String strExistingSubscription = 'Existing';
        String strExpiredSubscription = 'Expired';
        String strQueryProd = '';
        String strExpiredMsg = '';
        List<Map<String,Object>> lstResults = new List<Map<String,Object>>();
        List<String> lstExpOrExisting = new List<String>();
        
        strQueryProd = 'SELECT Apttus_Proposal__Product__r.Name, Product_Family__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE id =: idRecord';
        List<Apttus_Proposal__Proposal_Line_Item__c> lstProdValues = Database.query(strQueryProd);
        Apttus_Proposal__Proposal_Line_Item__c qli = lstProdValues.size()>0?lstProdValues[0]:new Apttus_Proposal__Proposal_Line_Item__c();

        for(SObject objRecord: lstValues){
            if(setDisplayFields.contains(strEndDateField) && Date.valueOf(objRecord.get(strEndDateField))<System.Today()){
                lstExpOrExisting.add(strExpiredSubscription);
            }else if(setDisplayFields.contains(strEndDateField) && Date.valueOf(objRecord.get(strEndDateField))>=System.Today()){
                lstExpOrExisting.add(strExistingSubscription);
            }
            Map<String,Object> record = new Map<String,Object>();
            if(qli.Product_Family__c == Label.InformaticsFamilyPartek){
                for(String strField : setDisplayFields)
                record.putAll(dotWalkField(strField, objRecord,true));
                lstResults.add(record);
            }
            else if(setDisplayFields.contains(strEndDateField) && Date.valueOf(objRecord.get(strEndDateField))>=System.Today()){
            for(String strField : setDisplayFields)
                record.putAll(dotWalkField(strField, objRecord,true));
            lstResults.add(record);
            }
        }
        System.debug('lstResults: ' + lstResults);
        //strQueryProd = 'SELECT Apttus_Proposal__Product__r.Name, Product_Family__c FROM Apttus_Proposal__Proposal_Line_Item__c WHERE id =: idRecord';
        //List<Apttus_Proposal__Proposal_Line_Item__c> lstProdValues = Database.query(strQueryProd);
        //Apttus_Proposal__Proposal_Line_Item__c qli = lstProdValues.size()>0?lstProdValues[0]:new Apttus_Proposal__Proposal_Line_Item__c();
        if(!lstExpOrExisting.isEmpty() && !lstExpOrExisting.contains(strExistingSubscription) && qli.Product_Family__c!='PARTEK')
        {
            //for(Apttus_Proposal__Proposal_Line_Item__c qli : (List<Apttus_Proposal__Proposal_Line_Item__c>)lstProdValues){
                strExpiredMsg = System.Label.UI_Label_Exp_ICA + ' ' +qli.Apttus_Proposal__Product__r.Name + ' ' + System.Label.UI_Label_Exp_ICA_1;
            //}
            return strExpiredMsg;
        }
        else{
        return JSON.serialize(lstResults);
        }
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to process field configurations 
    *  @PARAM :  InputDetails wrapInput,Schema.DescribeSObjectResult objDR,Schema.DescribeSObjectResult objTargetDR
    *  @RETURN:  OutputFields of fields processed
    */ 
    @AuraEnabled
    public static String doSave(id idRecord,String strInputJSON,String strFieldsWrapper){
        System.debug('idRecord: ' + idRecord);
        
        System.debug('strInputJSON: ' + strInputJSON);
        InputDetails wrapInput = (InputDetails)JSON.deserialize(strInputJSON, InputDetails.class);
        System.debug('wrapInput: ' + wrapInput);
        
        System.debug('strFieldsWrapper: ' + strFieldsWrapper);
        OutputFields wrapFields = (OutputFields)JSON.deserialize(strFieldsWrapper, OutputFields.class);
        System.debug('wrapFields: ' + wrapFields);

        Sobject objRec = idRecord.getSObjectType().newSObject(idRecord);
        objRec.put('Id',idRecord);
        objRec.put(wrapInput.strLookupApiName,wrapFields.strLookupId);
        System.debug('objRec: ' + objRec);
        update objRec;
        return 'Success';
    }
    

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to process field configurations 
    *  @PARAM :  InputDetails wrapInput,Schema.DescribeSObjectResult objDR,Schema.DescribeSObjectResult objTargetDR
    *  @RETURN:  OutputFields of fields processed
    */ 
    private static OutputFields processFields(InputDetails wrapInput,Schema.DescribeSObjectResult objDR,Schema.DescribeSObjectResult objTargetDR){
        OutputFields wrapFields = new OutputFields();
        Map<String,Schema.SObjectField> sourceFields =  objDR.fields.getMap();
        Map<String,Schema.SObjectField> lookupFields =  objTargetDR.fields.getMap();
        //make sure lookup field is proper
        if(!sourceFields.containsKey(wrapInput.strLookupApiName))
            wrapFields.lstErrors.add(wrapInput.strLookupApiName+NOT_FOUND_IN+objDR.getName()+'. Check lookup field.');
        
        //process search fields
        for(String strField : wrapInput.strSearchFields.split(','))
            dotWalkField(strField,objTargetDR,wrapFields,'. Check search fields.');
            
        //process display fields
        for(String strField : wrapInput.strDisplayFields.split(',')){
            Schema.DescribeFieldResult field = dotWalkField(strField,objTargetDR,wrapFields,'. Check display fields.');
            if(field!=null)
                wrapFields.lstColumns.add(new DataTableWrapper(field));
        }
        
        //process filter expression
        wrapFields.mapFieldToPositions = evaluateExpression(wrapInput.strFieldFilters,objDR,objTargetDR,wrapFields,'. Check filter conditions.');
        
        //process order by clause
        for(String strExpression : wrapInput.strOrderBy.split(',')){
            if(String.isBlank(strExpression.trim()))continue;
            if(strExpression.contains('DESC')){
                List<String> lstFields = strExpression.split('DESC');
                String strField = lstFields[0].trim();
                if(!lookupFields.containsKey(strField))
                    wrapFields.lstErrors.add(strField+NOT_FOUND_IN+objTargetDR.getName()+'. Check Order by clause.');
            }else if(strExpression.contains('ASC')){
                List<String> lstFields = strExpression.split('ASC');
                String strField = lstFields[0].trim();
                if(!lookupFields.containsKey(strField))
                    wrapFields.lstErrors.add(strField+NOT_FOUND_IN+objTargetDR.getName()+'. Check Order by clause.');
            }else {
                String strField = strExpression.trim();
                if(!lookupFields.containsKey(strField))
                    wrapFields.lstErrors.add(strField+NOT_FOUND_IN+objTargetDR.getName()+'. Check Order by clause.');
            }
        }
            
        System.debug('wrapFields: ' + wrapFields);
        return wrapFields;
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to process field configurations 
    *  @PARAM :  Set<String> setFields,String strRecordId, String strObjectApiName
    *  @RETURN:  Map<String,String>
    */ 
    private static Map<String,String> processFields(Set<String> setFields,String strRecordId, String strObjectApiName){
        String strQuery ='SELECT Id';
        for(String strField : setFields)
            strQuery+=','+strField;
        strQuery+=' FROM '+strObjectApiName+' WHERE Id=:strRecordId';
        System.debug('strQuery: ' + strQuery);
        SObject objRecord = Database.query(strQuery)[0];
        System.debug('objRecord: ' + objRecord);
        Map<String,String> mapValues = new Map<String,String>();
        for(String strField : setFields){
            Map<String,Object> mapValue= dotWalkField(strField,objRecord,false);
            for(String strKey: mapValue.keySet())
                mapValues.put(strField,String.valueOf(mapValue.get(strKey)));
        }
            
        System.debug('mapValues: ' + mapValues);

        return mapValues;
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to check validity of field & return field details if valid
    *  @PARAM :  String strComplexField,Schema.DescribeSObjectResult objDR,OutputFields wrapFields,String strErrorSuffix
    *  @RETURN: void
    */ 
    private static Schema.DescribeFieldResult dotWalkField(String strComplexField,Schema.DescribeSObjectResult objDR,OutputFields wrapFields,String strErrorSuffix){
        Schema.DescribeFieldResult finalField;
        Map<String,Schema.SObjectField> mapFields =  objDR.fields.getMap();
        System.debug('strComplexField: ' + strComplexField);
        System.debug('mapFields: ' + mapFields);
        for(String strField : strComplexField.split('\\.')){
            if(!strComplexField.endsWith(strField)){
                strField=convertRelationshipField(strField);
                if(!mapFields.containsKey(strField))
                    wrapFields.lstErrors.add(strField+NOT_FOUND_IN+objDR.getName()+strErrorSuffix);
                else{
                    finalField=mapFields.get(strField).getDescribe();
                    objDR = mapFields.get(strField).getDescribe().getReferenceTo()[0].getDescribe();
                    mapFields = objDR.fields.getMap();
                    
                }
            }else if(!mapFields.containsKey(strField)) 
                wrapFields.lstErrors.add(strField+NOT_FOUND_IN+objDR.getName()+strErrorSuffix);    
            else if(!NAME_FIELD.equalsIgnoreCase(strField) ||finalField==null)//ignore name so last lookup field's label will be taken as name
                finalField = mapFields.get(strField).getDescribe();
            
        }
        System.debug('finalField: ' + finalField);
        return finalField;   
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to get value of field with . operator
    *  @PARAM :  String strComplexField,SObject record
    *  @RETURN: Object value
    */ 
    private static Map<String,Object> dotWalkField(String strComplexField,SObject record,Boolean booResultKey){
        Schema.DescribeFieldResult field;
        Map<String,Object> mapValue = new Map<String,Object>();
        System.debug('strComplexField: ' + strComplexField);
        List<String> lstSplitFields = strComplexField.split('\\.');
        //initialize value as null if any lookup field is not populated
        if(booResultKey)
            mapValue.put(lstSplitFields[lstSplitFields.size()-1].removeEnd(API_SUFFIX),null);
        else
            mapValue.put(strComplexField,null);
        
        //now parse the relationship from the record
        for(String strField : lstSplitFields){
            if(record==null) break;
            System.debug('strField: ' + strField);
            if(!strComplexField.endsWith(strField)){
                field = record.getSObjectType().getDescribe().fields.getMap().get(convertRelationshipField(strField)).getDescribe();
                record = record.getSObject(strField);
            }else{
                System.debug('record: ' + record);
                System.debug('strField: ' + strField);
                if(!NAME_FIELD.equalsIgnoreCase(strField)||field==null)//ignore name so last lookup field's label will be taken as name
                    field = record.getSObjectType().getDescribe().fields.getMap().get(strField).getDescribe();
                if(booResultKey)
                    mapValue.put(field.getName().removeEnd(API_SUFFIX),record==null? null : record.get(strField));
                else
                    mapValue.put(strComplexField,record.get(strField));
            }
                
        }
        return mapValue;
    } 

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to convert relationship field into field on the object for describing
    *  @PARAM :  String strComplexField,SObject record
    *  @RETURN: Object value
    */ 
    private static String convertRelationshipField(String strField){
        if(strField.endsWith('__r'))
            strField=strField.replace('__r', API_SUFFIX);
        else if(!strField.endsWith(API_SUFFIX))
            strField+='Id';
        return strField;
    }

    @TestVisible
    private static final String LHS = 'LHS';
    @TestVisible
    private static final String RHS = 'RHS';
    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to parse where condition to make sure fields are proper
    *  @PARAM :  String strComplexExpression,Schema.DescribeSObjectResult objSource,Schema.DescribeSObjectResult objTarget,OutputFields wrapFields,String strErrorSuffix
    *  @RETURN: void
    */ 
    private static Map<Integer,String> evaluateExpression(String strComplexExpression,Schema.DescribeSObjectResult objSource,Schema.DescribeSObjectResult objTarget,OutputFields wrapFields,String strErrorSuffix){
        Map<String,Set<Integer>> mapFields = new Map<String,Set<Integer>>();
        Map<String,Set<String>> mapAllFields = new Map<String,Set<String>>();
        mapAllFields.put(LHS, new Set<String>());
        mapAllFields.put(RHS, new Set<String>());
        Pattern bracketPattern = Pattern.compile('\\((.*?)\\)');
        
        evaluateExpression(strComplexExpression,mapAllFields,mapFields,bracketPattern,wrapFields,0);
        System.debug('mapFields: ' + mapFields);

        for(String strField : mapAllFields.get(LHS))
            dotWalkField(strField,objTarget,wrapFields,strErrorSuffix);
        
        for(String strField : mapAllFields.get(RHS))
            dotWalkField(strField,objSource,wrapFields,strErrorSuffix);

        Map<Integer,String> cleanMap = cleanFieldPositions(strComplexExpression,mapFields);
        System.debug('cleanMap: ' + cleanMap);

        return cleanMap;
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to parse where condition
    *  @PARAM :  String strComplexField, Map<String,Set<String>> mapAllFields,Map<String,List<String>> mapFields,Pattern bracketPattern,OutputFields wrapFields
    *  @RETURN: void
    */ 
    @TestVisible
    private static void evaluateExpression(String strComplexField, Map<String,Set<String>> mapAllFields,Map<String,Set<Integer>> mapFields,
                                            Pattern bracketPattern,OutputFields wrapFields,Integer startIndex){
        if(String.isBlank(strComplexField)) return;
        strComplexField = removeUnRequiredBrackets(strComplexField);
        Matcher bracketMatcher = bracketPattern.matcher(strComplexField);
        Boolean booFoundMatch=false;
        while(bracketMatcher.find()){
            booFoundMatch=true;
            String strMatch = bracketMatcher.group();
            evaluateExpression(strMatch,mapAllFields,mapFields,bracketPattern,wrapFields,startIndex+bracketMatcher.start());
            
            for(String strRemainingExpression : strComplexField.split(strMatch.replaceAll('\\(', '\\\\(').replaceAll('\\)', '\\\\)')))
                evaluateExpression(strRemainingExpression,mapAllFields,mapFields,bracketPattern,wrapFields,startIndex+strComplexField.indexOf(strRemainingExpression));
        }
        if(!booFoundMatch) {//successfully drilled down to an expression without ()
            System.debug('strComplexField: '+strComplexField);
            String strFinalDrill = strComplexField.remove('(').remove(')').trim();// needs to be done for stry ( or )
            for(String strANDSplit : strFinalDrill.split('AND'))
                for(String strORSplit : strANDSplit.trim().split('OR')){
                    String strExpression = strORSplit.trim();
                    if(String.isBlank(strExpression)) continue;
                    System.debug('strExpression: ' + strExpression);
                    List<String> lstFields = strExpression.split(OPERATOR_REGEX);//split all posible operations to get LHS and RHS of expression
                    System.debug('lstFields: ' + lstFields);
                    if(lstFields.size()<INTEGER_TWO)
                        wrapFields.lstErrors.add('Cannot understand expression in filter : '+strExpression);
                    else{
                        mapAllFields.get(LHS).add(lstFields[0].trim());
                        String strRightHandValue = lstFields[lstFields.size()-1].trim();
                        if(strRightHandValue.contains('\'') //do not add literal values 
                           || FORMULA_CONDITIONS.contains(strRightHandValue))//ignore formula constants
                           continue;
                        mapAllFields.get(RHS).add(strRightHandValue);
                        
                        Integer finalPosition = strComplexField.lastIndexOf(strRightHandValue)+startIndex+1;
                        System.debug('strRightHandValue: ' + strRightHandValue);
                        System.debug('finalPosition: ' + finalPosition);
                        if(!mapFields.containsKey(strRightHandValue))
                            mapFields.put(strRightHandValue, new Set<Integer>());
                        mapFields.get(strRightHandValue).add(finalPosition);
                    }
                }
        }
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to parse where condition
    *  @PARAM :  String strComplexField,Map<String,List<String>> mapFields,Pattern bracketPattern
    *  @RETURN: void
    */ 
    private static String removeUnRequiredBrackets(String strExpression){
        String strSimplifiedExpression=strExpression;
        if(strSimplifiedExpression.startsWith('(') && strSimplifiedExpression.endsWith(')') 
            && strSimplifiedExpression.countMatches('(') == strSimplifiedExpression.countMatches(')')) 
            strSimplifiedExpression=strSimplifiedExpression.removeStart('(').removeEnd(')');
        if(strSimplifiedExpression.countMatches('(') > strSimplifiedExpression.countMatches(')'))
            strSimplifiedExpression=strSimplifiedExpression.removeStart('(');
        else if(strSimplifiedExpression.countMatches('(') < strSimplifiedExpression.countMatches(')'))
            strSimplifiedExpression=strSimplifiedExpression.removeEnd(')');
        return strSimplifiedExpression.trim();
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to remove garbage positions which came from regex matching
    *  @PARAM :  String strComplexField,Map<String,Set<Integer>> mapFields
    *  @RETURN: Map<String,Integer> map of field and actual position
    */ 
    @TestVisible
    private static Map<Integer,String> cleanFieldPositions(String strComplexField,Map<String,Set<Integer>> mapFields){
        Map<Integer,String> mapFieldToPositions = new Map<Integer,String>();
        for(String strField: mapFields.keySet()){
            String strSecondPart;
            Boolean booFound=false;
            Integer index ;
            for(Integer i : mapFields.get(strField)){
                index =i;
                strSecondPart=strComplexField.substring(index);
                if(strSecondPart.startsWith(strField)){
                    booFound=true;
                    break;
                }
                index=i+1;
                strSecondPart=strComplexField.substring(index);
                if(strSecondPart.startsWith(strField)){
                    booFound=true;
                    break;
                }
                index=i-1;
                if(index<0) continue;
                strSecondPart=strComplexField.substring(index);
                if(strSecondPart.startsWith(strField)){
                    booFound=true;
                    break;
                }
            }
            if(booFound)
                mapFieldToPositions.put(index,strField);
            
        }

        return mapFieldToPositions;
    }

    /*
    *  @AUTHOR:  Akshay Mohan
    *  @DESCRIPTION: method to remove garbage positions which came from regex matching
    *  @PARAM :  String strComplexField,Map<String,Set<Integer>> mapFields
    *  @RETURN: Map<String,Integer> map of field and actual position
    */ 
    @TestVisible
    private static String setFieldValues(String strComplexExpression,Map<Integer,String> mapFieldToPositions,
                                            Map<String,String> mapFieldToValues){
        String strFirstPart; //Codescan Fix - Use one line for each declaration
        String strSecondPart;
        String strFinalExpression=strComplexExpression;
        
        List<Integer> lstIndexes = new List<Integer>(mapFieldToPositions.keySet());
        lstIndexes.sort();
        for(Integer index = lstIndexes.size()-1;index>=0;index--){
            String strField = mapFieldToPositions.get(lstIndexes[index]);
            strFirstPart= strFinalExpression.substring(0, lstIndexes[index]);
            strSecondPart= strFinalExpression.substring(lstIndexes[index]);
            strFinalExpression = strFirstPart+strSecondPart.replaceFirst(strField, '\''+mapFieldToValues.get(strField)+'\'');
        }
        System.debug('strFinalExpression: '+strFinalExpression);
        return strFinalExpression;
    }
    
}