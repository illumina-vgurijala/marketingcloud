/***************************************************************************************************************************************
* NAME   : public class RuleEngineLogic{

* DESCRIPTION  :DCP-40191, Apex Class to Run Business Rules for Rule Entry Custom metadata
*           
*    
* @AUTHOR : Digvijay
* @DATE   : 18-09-2020  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Digvijay             18-09-2020            Initial Version

****************************************************************************************************************************************/ 
public with sharing class RuleEngineLogic{

    public static final String STRING_OPERATOR_NOT_IN = 'Not IN';
    public static final String STRING_OPERATOR_IN = 'IN';
    public static final String STRING_OPERATOR_OR = 'OR';
    public static final String STRING_OPERATOR_AND = 'AND';
    public static final String STRING_RECORDTYPE = 'RecordTypeID';
    public static Map<String ,DescribeSObjectResult> mapSobjectoDescribeObject=new Map<String ,DescribeSObjectResult>();
    public static Boolean ruleSatisFied=false;
    public static Rule_Object__mdt parentruleobj;
    
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Static method that need to be called to start Rule execution
*  @PARAM : String , String ,List<Sobject> ,Map<String , Map<Id,Object>> ,List<String> lstSpecificRulestoRun
*  @RETURN : void
**/
    
    public static List<Sobject> runtheBussinessRules(String sobjectAPI,String functionality,List<Sobject> lstSobjects, Map<String , Map<Id,Object>> mapofNeededSobjects,List<String> lstSpecificRulestoRun){
        
        
        Map<String,Rule_Entry__mdt > ruleidtoRuleObjectMap=new  Map<String,Rule_Entry__mdt >();
        

        //get the object metadata which will be used to determing the Sobject Field Type
        SObjectType sobjectType = ((SObject)(Type.forName('Schema.'+sobjectAPI).newInstance())).getSObjectType();
        DescribeSObjectResult sObjectdesc = sobjectType.getDescribe(); 
        mapSobjectoDescribeObject.put(sobjectAPI,sObjectdesc);
        
        //Query the Parent Object and the Rule's related to that Parent Object      
        parentruleobj=[SELECT Rule_Object_Name__c, Rule_OutCome_Field__c, Rules_Business_Functionality__c FROM Rule_Object__mdt WHERE Rules_Business_Functionality__c =: functionality and  Rule_Object_Name__c=:sobjectAPI];
        
        
         for(Rule_Entry__mdt obj:[SELECT Rule_Priority__c,Rule_Id__c,Callable_Apex__c, Rule_Criteria_Object__c,Rule_Criteria_Field__c,Rule_Criteria_Field_Value__c,Rule_Criteria_Operator__c,Rule_InputData_Map__c, Key_InputData_Map__c,   Rule_OutCome__c,Next_Rule_Id__c,Next_Rule_Operator__c,  Is_TopMost_Rule__c , Exit_If_Satisfied__c FROM Rule_Entry__mdt WHERE    Rule_Object__c =:parentruleobj.Id and  Is_Active__c=true ORDER BY  Rule_Priority__c NULLS LAST,Rule_Id__c]){
            RuleidtoRuleObjectMap.put(obj.Rule_Id__c,obj);
         }
         System.debug('RuleidtoRuleObjectMap..'+RuleidtoRuleObjectMap.values()); 

        //Iterate through the list of records and call the method to execute Rules  
        for(Sobject obj:lstSobjects){
            ruleSatisFied=false;
            for(String str:RuleidtoRuleObjectMap.keyset()){
                //run all rules if no specfic rules mentioned in the List else Run specific rules mentioned in List
                if((lstSpecificRulestoRun==null && RuleidtoRuleObjectMap.get(str).Is_TopMost_Rule__c==TRUE  ) ||(lstSpecificRulestoRun!=null && !lstSpecificRulestoRun.IsEmpty() && RuleidtoRuleObjectMap.get(str).Is_TopMost_Rule__c==TRUE && lstSpecificRulestoRun.Contains(RuleidtoRuleObjectMap.get(str).Rule_Id__c))	){
                    System.debug('inside for..'+str);
                    
                    //execute the rule by calling executeRule method.
                    Object ruleOutcome= executeRule(sobjectAPI,obj,ruleidtoRuleObjectMap,str,mapofNeededSobjects,false,'');
                    //If the rule will evaluate to true the RuleOutcome wil be Not null. Type Cast the Rule outcome as per the output field Type
                    if(ruleOutcome!=null){
                        
                        //Set the Value on the Sobject Output Field based to Field Type of Output Field.
                        Schema.DisplayType fielddataType = mapSobjectoDescribeObject.get(sobjectAPI).fields.getMap().get(parentruleobj.Rule_OutCome_Field__c).getDescribe().getType();
                        if(fielddataType == Schema.DisplayType.BOOLEAN )
                        {
                            System.debug('RuleOutcome debug...'+BOOLEAN.ValueOf(RuleOutcome)+' Rule Id'+RuleidtoRuleObjectMap.get(str).Rule_Id__c);
                            obj.put(parentruleobj.Rule_OutCome_Field__c,BOOLEAN.ValueOf(RuleOutcome));
                        }
                        //need to add else if blocks for any other DataTypes.
                        
                        //if Rule is satisfied and there is no need to check for Next set of Rules.
                        if(ruleSatisFied && RuleidtoRuleObjectMap.get(str).Exit_If_Satisfied__c==TRUE)
                            break;
                        else
                            ruleSatisFied=false;                    
                        
                    }
                    
                }
            }
            
        }
        
        return lstSobjects;
    }
    
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Static method that need to execute a particular Rule 
*  @PARAM : String , String ,Map<String,Rule_Entry__mdt >,String , Map<String , Map<Id,Object>> ,List<String> ,Boolean,String
*  @RETURN : Object
**/
    
    public static Object executeRule(String sobjectName,Sobject sobjrecord, Map<String,Rule_Entry__mdt > ruleidtoRuleObjectMap,String str,Map<String , Map<Id,Object>> mapofNeededSobjects,Boolean prevOutcome,String nextRuleOperator){
        
        //to store outcome of each rule
        Boolean conditionOutcome=false;
        //to store the Rule output if the Rule evaluates to true
        Object ruleOutcome=null;
        Rule_Entry__mdt ruleobj=RuleidtoRuleObjectMap.get(str);
        
        System.debug('Executing Rule..'+ruleobj);
          //Rule Requires a Apex call
        if(!String.IsBlank(ruleobj.Callable_Apex__c)){
            try{
                Callable callobj = (Callable)Type.forName(ruleobj.Callable_Apex__c).newInstance();
                Object outcome=callobj.call(sobjectName+'_'+parentruleobj.Rules_Business_Functionality__c,new map<String,Object>{'RuleId' => ruleobj.Rule_Id__c,'Sobject'=>Sobjrecord});
                conditionOutcome=BOOLEAN.ValueOf(outcome);
            }Catch(Exception ex){
                ApexExceptions.emit('Exception on '+sobjectName+'for Rule: ' + ruleobj.Rule_Id__c, (Id)sobjrecord.get('Id'), ex);
            }

        //if the Rule Operator is 'IN'
        }else if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_IN || ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_NOT_IN){
              
              conditionOutcome=proccessINOperator(ruleobj,sobjectName,sobjrecord, mapofNeededSobjects);
        }else {
            //Run logic for Operators Other than 'IN'
            try{
                
                //if the Rule need field comparions on the object for   which the rules need to be run
                if(sobjectName==ruleobj.Rule_Criteria_Object__c){
                    conditionOutcome=compareValues(Sobjrecord,ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c,ruleobj.Rule_Criteria_Field_Value__c,ruleobj.Rule_Criteria_Operator__c);
                }else{
                    //if the Rule need field comparions on a related object  records.
                    System.debug('mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c)...'+mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c));
                    System.debug('ruleobj.Rule_Criteria_Field__c..'+ruleobj.Rule_Criteria_Field__c+'..'+(Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c));
                    System.debug('sobject rec...'+mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c)));
                    //System.debug('sobject rec...'+mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c)).get(ruleobj.Rule_Criteria_Field__c));
                    
                    
                    if(mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c)!=null && mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c))!=null ){
                        Object obj=mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c));
                        //the related data can be Sobject or a List of Sobjects
                        if(obj instanceof List<Sobject> ){
                            for(Sobject s:(List<Sobject>)obj){
                                conditionOutcome=compareValues(s,ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c,ruleobj.Rule_Criteria_Field_Value__c,ruleobj.Rule_Criteria_Operator__c);
                                if(conditionOutcome)  
                                    break;  
                            }    
                        }else if(obj instanceof Sobject) {
                            Sobject sobj=(Sobject)obj;
                            conditionOutcome=compareValues(sobj,ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c,ruleobj.Rule_Criteria_Field_Value__c,ruleobj.Rule_Criteria_Operator__c);                           
                        }
                    }else if(mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c)!=null && mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c))==null && ruleobj.Rule_Criteria_Operator__c=='Null'){
                            conditionOutcome=true;
                        }
                    //conditionOutcome=compareValues(mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c)),ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c,ruleobj.Rule_Criteria_Field_Value__c,ruleobj.Rule_Criteria_Operator__c);                 
                }
            }Catch(Exception ex){
                 ApexExceptions.emit('Exception on '+sobjectName+'for Rule: ' + ruleobj.Rule_Id__c, (Id)sobjrecord.get('Id'), ex);
            }
        }
        
        
        System.debug('condition '+conditionOutcome);
        
        //in case of multiple rules (examples rules in AND) , compare the outcome of previous rule with current rule 
        
        if( !String.IsEmpty(nextRuleOperator) ){
            System.debug('prevOutCome..'+prevOutcome);
            if(nextRuleOperator==STRING_OPERATOR_OR){
                if(conditionOutcome==TRUE|| prevOutcome==TRUE)
                    conditionOutcome=true;
            }else if(nextRuleOperator==STRING_OPERATOR_AND){
                if(conditionOutcome==TRUE && prevOutcome==TRUE)
                    conditionOutcome=true;
                else
                    conditionOutcome=FALSE;
                
            }
        }
        
        System.debug('cumulative condition Outcome '+conditionOutcome);
        if(!String.IsBlank(ruleobj.Next_Rule_Id__c) && ruleobj.Next_Rule_Operator__c!=''){
            
            // in case of multiple rules (examples rules with AND) , call the next rule recursively 
            ruleOutcome=executeRule(SobjectName,Sobjrecord, RuleidtoRuleObjectMap,ruleobj.Next_Rule_Id__c,mapofNeededSobjects,conditionOutcome,ruleobj.Next_Rule_Operator__c);
        }else{
            if(conditionOutcome==true){
                ruleOutcome=ruleobj.Rule_OutCome__c;
                ruleSatisFied=true;
            }
            
            System.debug('Final RuleOutcome..'+ruleOutcome);
        }
        
        return ruleOutcome;      
    }
    
        
    /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - Compare Field values for a Rule based on Field Type 
*  @PARAM : String 
*  @RETURN : Boolean
**/
    public static Boolean compareValues(Sobject sobj , String fieldAPi,String criteriaObject,String criteriaValue,String operator){
        
        Boolean conditionOutcome=false;
        if(!mapSobjectoDescribeObject.ContainsKey(criteriaObject)){
            SObjectType sobjectType = ((SObject)(Type.forName('Schema.'+criteriaObject).newInstance())).getSObjectType();
            mapSobjectoDescribeObject.put(criteriaObject,sobjectType.getDescribe());
        }
        
        if(operator=='Not Blank' && !String.IsBlank((String)getFieldValue(sobj,fieldAPi,criteriaObject))){
            conditionOutcome=true;
        }else if(operator=='Not Null' && getFieldValue(sobj,fieldAPi,criteriaObject)!=Null){
            conditionOutcome=true;    
        }else if(fieldAPi!=STRING_RECORDTYPE && mapSobjectoDescribeObject.get(criteriaObject).fields.getMap().get(fieldAPi).getDescribe().getType()==Schema.DisplayType.BOOLEAN ){
            if(operator=='Equals' && Boolean.valueOf(CriteriaValue)==Boolean.ValueOf(getFieldValue(sobj,fieldAPi,criteriaObject)))
                conditionOutcome=true;
            else if(operator=='Not Equals' && Boolean.valueOf(CriteriaValue)!=Boolean.ValueOf(getFieldValue(sobj,fieldAPi,criteriaObject)))
                conditionOutcome=true;
        }else{
            if(operator=='Equals' && CriteriaValue==(String)getFieldValue(sobj,fieldAPi,criteriaObject))
                conditionOutcome=true;
            else if(operator=='Not Equals' && CriteriaValue!=(String)getFieldValue(sobj,fieldAPi,criteriaObject))
                conditionOutcome=true;
            
        }
        return conditionOutcome;
 }
    
    
     /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - get Sobject Field Value 
*  @PARAM : Sobject , String , String 
*  @RETURN : Object
**/
    public static Object getFieldValue(Sobject sobj , String fieldAPi,String criteriaObject){
        
        Object val;
        if(fieldAPi.Contains('.')){
            List<String> fieldApis=fieldAPi.split('.');
            val= sobj.getSObject(fieldApis[0]).get(fieldApis[1]);
        }else if(fieldAPi==STRING_RECORDTYPE){
            val=mapSobjectoDescribeObject.get(criteriaObject).getRecordTypeInfosById().get((String)sobj.get(fieldAPi)).getName();
            
        } else{
            val= sobj.get(fieldAPi);
        }
        
        return val;
        
    }


    
     /**
*  @AUTHOR Digvijay
*  @DESCRIPTION - get Sobject Field Value 
*  @PARAM : Sobject , String , String 
*  @RETURN : Boolean
**/
    public Static Boolean  proccessINOperator(Rule_Entry__mdt ruleobj, String sobjectName , Sobject sobjrecord,Map<String , Map<Id,Object>> mapofNeededSobjects){
   //to store outcome of each rule
      Boolean conditionOutcome=false;
	      try{
                List<String> lstvalues=ruleobj.Rule_Criteria_Field_Value__c .split(',');
                if(SobjectName==ruleobj.Rule_Criteria_Object__c){
                    if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_IN  && lstvalues.contains((String)getFieldValue(Sobjrecord,ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c))  )
                        conditionOutcome=true;
                    else if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_NOT_IN && !lstvalues.contains((String)getFieldValue(Sobjrecord,ruleobj.Rule_Criteria_Field__c,ruleobj.Rule_Criteria_Object__c))  )
                        conditionOutcome=true;


                }else{
                     //if the data required for Rule evaluation is a related object data , then Use the MAP of MAPs which store related data needed for Rule.
                    Object obj=mapofNeededSobjects.get(ruleobj.Rule_InputData_Map__c).get((Id)Sobjrecord.get(ruleobj.Key_InputData_Map__c));
                    //the related data can be Sobject or a List of Sobjects
                    if(obj instanceof List<Sobject>){
                        for(Sobject s:(List<Sobject>)obj){
                            if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_IN && lstvalues.contains((String)s.get(ruleobj.Rule_Criteria_Field__c))  ){
                                conditionOutcome=true;
                                break;
                            }else if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_NOT_IN && !lstvalues.contains((String)s.get(ruleobj.Rule_Criteria_Field__c)) ){
                                conditionOutcome=true;
                                break;
                            }
                        }
                    }else if(obj  instanceof Sobject) {
                        Sobject sobj=(Sobject)obj;
                        if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_IN && lstvalues.contains((String)sobj.get(ruleobj.Rule_Criteria_Field__c))   )
                            conditionOutcome=true;      
                        else if(ruleobj.Rule_Criteria_Operator__c==STRING_OPERATOR_NOT_IN && !lstvalues.contains((String)sobj.get(ruleobj.Rule_Criteria_Field__c))   )
                            conditionOutcome=true;             
                    }
                    
                }
            }Catch(Exception ex){
                ApexExceptions.emit('Exception on '+sobjectName+'for Rule: ' + ruleobj.Rule_Id__c, (Id)sobjrecord.get('Id'), ex);
            }

 return conditionOutcome;
}
    
    
}