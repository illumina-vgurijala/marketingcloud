/***************************************************************************************************************************************
 * NAME         : FieldSupports
 * DESCRIPTION  : Domain class for Field Support
 *                    
 * @AUTHOR : Ritika
 * @DATE   : 18-Jan-2023  
 * 
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika               18-Jan-2023          Initial Version. 
  ****************************************************************************************************************************************/ 
public with sharing class FieldSupports extends ilib_SObjectDomain{

    /**
    * @description Constructor with List of SVMXC__Service_Group_Members__c
    * @author 
    * @param sObjectList 
    **/
    public FieldSupports (List<SVMXC__Service_Group_Members__c> sObjectList)
    {
        super(sObjectList);
    }

    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description Returns new FieldSupports Obj
        * @author 
        * @param sObjectList 
        * @return ilib_SObjectDomain 
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new FieldSupports (sObjectList);
        }
    }

    /**
    * @description onBeforeInsert method
    * @author 
    **/
    public override void onBeforeInsert()
    {
        List<SVMXC__Service_Group_Members__c> listCheckDuplicates = new List<SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c objFieldSupport : (List<SVMXC__Service_Group_Members__c>)records)
        {
            if(objFieldSupport.SVMXC__Active__c && objFieldSupport.SVMXC__Email__c != null){
                listCheckDuplicates.add(objFieldSupport);
            }
        }
        checkForClosedDuplicateFieldSupport(listCheckDuplicates);
    }

    /**
    * @description onBeforeupdate method
    * @author 
    **/
    public override void onBeforeUpdate(Map<Id, SObject> oldRecords)
    {
        List<SVMXC__Service_Group_Members__c> listCheckDuplicates = new List<SVMXC__Service_Group_Members__c>();
        for (SVMXC__Service_Group_Members__c objFieldSupport : (List<SVMXC__Service_Group_Members__c>)records)
        {
            SVMXC__Service_Group_Members__c oldFieldSupport = (SVMXC__Service_Group_Members__c)oldRecords.get(objFieldSupport.Id);
            if(objFieldSupport.SVMXC__Active__c && objFieldSupport.SVMXC__Email__c != null && oldFieldSupport.SVMXC__Email__c != objFieldSupport.SVMXC__Email__c){
                listCheckDuplicates.add(objFieldSupport);
            }
        }
        checkForClosedDuplicateFieldSupport(listCheckDuplicates);
    }

    /**
     * @author          Ritika M
     * @date            18-Jan-2023
     * @description     Find the duplicate fieldSupport if it exists based on the email address
     */
    
    private void checkForClosedDuplicateFieldSupport(List<SVMXC__Service_Group_Members__c> listCheckDuplicates){
        Map<String,SVMXC__Service_Group_Members__c> mapEmailToFieldSupport = new Map<String,SVMXC__Service_Group_Members__c>();
        //Iterate on the list of field support records getting inserted/updated and check if there is a duplicate in the list based on email address
        for(SVMXC__Service_Group_Members__c fieldSupport : listCheckDuplicates){
            if(!mapEmailToFieldSupport.containskey(fieldSupport.SVMXC__Email__c)){
                mapEmailToFieldSupport.put(fieldSupport.SVMXC__Email__c,fieldSupport);
            }else{
                fieldSupport.addError(System.label.Duplicate_Field_Support_Error);
            }
        }
        //If the list does not contain any duplicate, check for duplicates in the DB based on email address
        for(SVMXC__Service_Group_Members__c existingFieldSupport : [Select Id,SVMXC__Email__c from SVMXC__Service_Group_Members__c where SVMXC__Email__c IN :mapEmailToFieldSupport.keyset()])
        {
            if(existingFieldSupport.SVMXC__Email__c != null && mapEmailToFieldSupport.containskey(existingFieldSupport.SVMXC__Email__c)){
                SVMXC__Service_Group_Members__c fieldSupport = mapEmailToFieldSupport.get(existingFieldSupport.SVMXC__Email__c);
                fieldSupport.addError(System.label.Duplicate_Field_Support_Error + existingFieldSupport.Id);
            }
        }
    }
}