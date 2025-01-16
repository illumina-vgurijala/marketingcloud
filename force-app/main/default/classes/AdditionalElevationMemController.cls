/***************************************************************************************************************************************
    * NAME   : AdditionalElevationMemController
    * DESCRIPTION  : Controller Class to fetch contact/User details on Create technical/Account Elevation screen.
    *                    
    * @AUTHOR : Rohan Rathod
    * @DATE   : 02-Dec-2021  
    * 
    * MODIFICATION LOG: 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * DEVELOPER                DATE                DESCRIPTION 
    * --------------------------------------------------------------------------------------------------------------------------------------
    * Rohan                  02-Dec-2021         Initial Version.
    *****************************************************************************************************************************************/


public with sharing class AdditionalElevationMemController {
   
   /**
   * @description To fetch User or Contact records based on search key word
   * @author Rohan Rathod 
   * @param searchKey,objectName   
   * @return List<sobject> 
   **/
   @AuraEnabled  
   public static List<sobject> findRecords(String searchKey, String objectName) {       
     try{
      string strRepresentative = objectName=='User'? 'CompanyName': 'Account.Name' ;     
      string searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';    
      string filter = objectName=='User'? ' AND IsActive = true ' : ' ';
      string query = 'SELECT Id, Name, Title, Email, '+strRepresentative+' FROM ' +objectName+ ' WHERE Name LIKE ' +searchText+ filter +' LIMIT 5';        
      return Database.query(query);  
     }
     catch(Exception e){
      throw new AuraHandledException(e.getMessage()); 
     }
     
   }     

   /**
   * @description To fetch exisiting elevation member records related to WO on screen
   * @author  
   * @param recId 
   * @return List<DataWrap> 
   **/
   @AuraEnabled(cacheable=true)
   public static List<DataWrap> fetchElevationMember(String recId){
     try {
       List<DataWrap> lstDataWrap= new List<DataWrap>();
      Set<Id> setWOId = new Set<Id>();
      setWOId.add(recId);
      
      for(Related_Contacts__c obj:new RelatedContactsSelector().selectRelatedContactByWOId(setWOId))                
      {
          DataWrap objDataWrap= new DataWrap();
          objDataWrap.memberId=obj.id;
          objDataWrap.typePiclst=obj.Type__c;
          objDataWrap.title =obj.Title__c;
          objDataWrap.memberEmail =obj.Email__c;
          objDataWrap.representative = obj.Representative__c;
          objDataWrap.woRecId =obj.Elevated_Work_Order__c;
          if(obj.User__c!= null){
            objDataWrap.tempAllIds =obj.User__c;
            objDataWrap.name =obj.User_Name__c;
         }
          if(obj.Contact__c!=null){
            objDataWrap.tempAllIds =obj.Contact__c;
            objDataWrap.name =obj.Contact_Name__c;
          }
          lstDataWrap.add(objDataWrap);
      }
      
      return lstDataWrap;
       
     } catch (Exception e) {
      throw new AuraHandledException(e.getMessage()); 
     }
   }

   /**
   * @description To delete elevation member record 
   * @author Rohan Rathod 
   * @param delId 
   **/
   @AuraEnabled
   public static void deleteElevationMember(Id delId){
    if(delId!=null){            
      try{
        Related_Contacts__c rcRecord = new Related_Contacts__c();
        rcRecord.id = delId;      
        Delete rcRecord;
      }
      catch(Exception e){
        throw new AuraHandledException(e.getMessage());       
      } 
         
    }
     
   }

  /**
   * @description Wrapper class for additional Elevation mem
   * @author Rohan Rathod    
   **/
   public class DataWrap{

    @AuraEnabled
    public String typePiclst {get;set;}
    @AuraEnabled
    public String title {get;set;}
    @AuraEnabled
    public String memberEmail {get;set;}
    @AuraEnabled
    public String name {get;set;}
    @AuraEnabled
    public String woRecId {get;set;}
    @AuraEnabled
    public String tempAllIds {get;set;}
    @AuraEnabled
    public Id memberId{get;set;}
    @AuraEnabled
    public String representative {get;set;}
    
   }
   
}