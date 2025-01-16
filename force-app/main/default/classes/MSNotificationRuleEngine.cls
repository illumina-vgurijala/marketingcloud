/**
 *    @author KD
 *    @date   30-March-2021
 *    @description  Rule engine class for Case Change Event
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
 *     Developer                      Date                Description
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class MSNotificationRuleEngine {
    public static final string CASE_OWNED_BY_QUEUE = 'Owned By Queue';
    public static final string AND_OPERATOR = ' && ';
    public static final string OR_OPERATOR = ' || ';
    public static final string CONTAINS_CONDITION = ' Contains ';
    public static final string EQUALS_CONDITION = ' Equals ';
    public static final string NOTEQUALS_CONDITION = ' NotEquals ';
    public static final string IN_CONDITION = ' IN ';
    public static List<String> lstAddConditions = new List<String>();
    public static Set<String> setImpactedField = new Set<String>();
    public static Map<String,String> mapRelationshipNameToApiName = new Map<String,String>{
        'Owner' => 'OwnerId',
        'Account' => 'AccountId'
    };
    /**
     *  @author       : KD
     *  @description  : method to check if case stisfy notification condition
     *  @return       : Boolean
     */
    public static Boolean checkCondition(Case objCase,String strRuleSyntax,Boolean boolSatisfy){
        // Example syntax 'Owned By Queue && Subject Contains {KD} || Description Contains {Updayted}'
        // Parent level And operation check
        system.debug('strRuleSyntax -->'+strRuleSyntax);
        system.debug('boolSatisfy -->'+boolSatisfy);
        if(strRuleSyntax.contains(AND_OPERATOR)){
            if(boolSatisfy == null)
                boolSatisfy = true;
            if(!boolSatisfy)
                return false;
            system.debug('Inside -->'+AND_OPERATOR);
            List<String> strSplitedAndConditions = strRuleSyntax.split(AND_OPERATOR);
            system.debug('AND ops -->'+strSplitedAndConditions);
            for(String strAndConditions : strSplitedAndConditions){
                system.debug('strAndConditions -->'+strAndConditions);
                
                Boolean result = checkCondition(objCase,strAndConditions,null);
                if(result != null && !result)
                    boolSatisfy = false;
            }
            return boolSatisfy;
        }
        // Parent level OR operation check
        if(strRuleSyntax.contains(OR_OPERATOR)){
            if(boolSatisfy == null)
                boolSatisfy = false;
            system.debug('Inside -->'+OR_OPERATOR);
            List<String> strSplitedOrConditions = strRuleSyntax.split(' \\|\\| ');
            system.debug('OR ops -->'+strSplitedOrConditions);
            for(String strOrConditions : strSplitedOrConditions){
                system.debug('strOrConditions -->'+strOrConditions);
                boolSatisfy = boolSatisfy || checkCondition(objCase,strOrConditions,boolSatisfy);
            }
            return boolSatisfy;
        }
        // Leaf Node level condition check
        if(strRuleSyntax == CASE_OWNED_BY_QUEUE)
            return checkOwnedByQueue(objCase);
        if(strRuleSyntax.contains(CONTAINS_CONDITION))
            return processContainsOperation(objCase,strRuleSyntax);
        if(strRuleSyntax.contains(IN_CONDITION))
            return processInOperation(objCase,strRuleSyntax);
        if(strRuleSyntax.contains(EQUALS_CONDITION))
            return processEqualsOperation(objCase,strRuleSyntax);
        if(strRuleSyntax.contains(NOTEQUALS_CONDITION))
            return processNotEqualsOperation(objCase,strRuleSyntax);
        return boolSatisfy;
    }
    /**
     *  @author       : KD
     *  @description  : method to check if case owned by Queue
     *  @return       : Boolean
     */
    public static Boolean checkOwnedByQueue(Case objCase){
        system.debug('Inside -->'+CASE_OWNED_BY_QUEUE);
        return objCase.owner.type == 'Queue';
    }
    /**
     *  @author       : KD
     *  @description  : method to process Contains operation
     *  @return       : Boolean
     */
    public static Boolean processContainsOperation(Case objCase,String strLeafCondition){
        // Example Condition "Subject contains {high,priority}"
        system.debug('Inside -->'+CONTAINS_CONDITION);
        List<String> lstSplitedCondition = strLeafCondition.split(CONTAINS_CONDITION);
        String strFieldValue = (String)objCase.get(lstSplitedCondition[0]);
        List<String> lstKeyWordsToCheck = ( lstSplitedCondition != null && !lstSplitedCondition.isEmpty() ) ? lstSplitedCondition[1].substringBetween('{','}').split(',') : null ;
        Boolean boolFlag = false;
        for(String strKeyWord : lstKeyWordsToCheck){
            if(strFieldValue != null && strFieldValue.containsIgnoreCase(strKeyWord)){
                boolFlag = true;
                break;
            }
        }
        return boolFlag;
    }
    /**
     *  @author       : KD
     *  @description  : method to process Equals operation
     *  @return       : Boolean
     */
    public static Boolean processEqualsOperation(Case objCase,String strLeafCondition){
        // Example Condition "Region Equals AMR"
        system.debug('Inside -->'+EQUALS_CONDITION);
        List<String> lstSplitedCondition = strLeafCondition.split(EQUALS_CONDITION);
        return String.valueOf(objCase.get(lstSplitedCondition[0])) == lstSplitedCondition[1];
    }/**
     *  @author       : KD
     *  @description  : method to process Not Equals operation
     *  @return       : Boolean
     */
    public static Boolean processNotEqualsOperation(Case objCase,String strLeafCondition){
        // Example Condition "Region NotEquals AMR"
        system.debug('Inside -->'+NOTEQUALS_CONDITION);
        List<String> lstSplitedCondition = strLeafCondition.split(NOTEQUALS_CONDITION);
        return String.valueOf(objCase.get(lstSplitedCondition[0])) != lstSplitedCondition[1];
    }
    /**
     *  @author       : KD
     *  @description  : method to process IN operation
     *  @return       : Boolean
     */
    public static Boolean processInOperation(Case objCase,String strLeafCondition){
        // Example Condition "Account.ERP_Customer_Id__c IN {12353,654678,2347853}"
        system.debug('Inside -->'+IN_CONDITION);
        List<String> lstSplitedCondition = strLeafCondition.split(IN_CONDITION);
        String strFieldValue = getRelationshipField(objCase,lstSplitedCondition[0]);
        List<String> lstKeyWordsToCheck = lstSplitedCondition[1].substringBetween('{','}').split(',');
        return lstKeyWordsToCheck.contains(strFieldValue);
    }
    /**
     *  @author       : KD
     *  @description  : method to fetch parent field from Sobject
     *  @return       : String
     */
    public static String getRelationshipField(Sobject objSobject,String strFieldRelation){
        System.debug('strFieldRelation --> '+strFieldRelation);
        if(strFieldRelation.contains('.')){
            System.debug('IF');
            List<String> strFieldRelationSplit = strFieldRelation.split('\\.',2);
            
            //added for INC0324365
            if(objSobject.getSobject(strFieldRelationSplit[0]) == null)
            return '';
            
            return getRelationshipField(objSobject.getSobject(strFieldRelationSplit[0]),strFieldRelationSplit[1]);
        }
        else{
            System.debug('ELSE');
            return (String)objSobject.get(strFieldRelation);
        }
    }
    /**
     *  @author       : KD
     *  @description  : method to fetch parent field from Sobject
     *  @return       : String
     */
    public static void getImpactedFields(String strRuleSyntax){
        System.debug('setImpactedField  -->'+setImpactedField);
        if(strRuleSyntax.contains(AND_OPERATOR)){
            List<String> strSplitedAndConditions = strRuleSyntax.split(AND_OPERATOR);
            system.debug('AND ops -->'+strSplitedAndConditions);
            for(String strAndConditions : strSplitedAndConditions){
                getImpactedFields(strAndConditions);
            }
        }
        else if(strRuleSyntax.contains(OR_OPERATOR)){
            List<String> strSplitedOrConditions = strRuleSyntax.split(' \\|\\| ');
            system.debug('OR ops -->'+strSplitedOrConditions);
            for(String strOrConditions : strSplitedOrConditions){
                getImpactedFields(strOrConditions);
            }
        }
        else if(strRuleSyntax == CASE_OWNED_BY_QUEUE){
            setImpactedField.add('OwnerId');
            System.debug('setImpactedField  Owner-->'+setImpactedField);
        }
        else if(strRuleSyntax.contains(CONTAINS_CONDITION)){
            setImpactedField.add(strRuleSyntax.split(CONTAINS_CONDITION)[0]);
            System.debug('setImpactedField  Contains-->'+setImpactedField);
        }
        else if(strRuleSyntax.contains(NOTEQUALS_CONDITION)){
            setImpactedField.add(strRuleSyntax.split(NOTEQUALS_CONDITION)[0]);
            System.debug('setImpactedField  NE-->'+setImpactedField);
        }
        else if(strRuleSyntax.contains(EQUALS_CONDITION)){
            setImpactedField.add(strRuleSyntax.split(EQUALS_CONDITION)[0]);
            System.debug('setImpactedField  Equal-->'+setImpactedField);
        }
        
        else if(strRuleSyntax.contains(IN_CONDITION)){
            String strRelation = strRuleSyntax.split(IN_CONDITION)[0];
            if(strRelation.contains('.')){
                String strFieldRelationSplit = strRelation.split('\\.',2)[0];
                if(strFieldRelationSplit.endsWith('__r'))
                    setImpactedField.add(strFieldRelationSplit.replace('__r','__c'));
                else{
                    setImpactedField.add(mapRelationshipNameToApiName.get(strFieldRelationSplit));
                }
            }
            System.debug('setImpactedField  IN-->'+setImpactedField);
        }
    }
}