/***************************************************************************************************************************************
 * NAME   : TestDataTableController
 * DESCRIPTION  : TestClass for DataTableController
 *           
 *    
 * @AUTHOR : Digvijay
 * @DATE   :14-May-2020  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay         14-05-2020           Initial Version
 
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public with sharing class TestDataTableController {

  public static final String STRING_ACCOUNT_NAME = 'Account.Name';
  
    static testMethod void testinitRecords(){
    
        String objectname='Case';
        //String fieldNamesStr='Id,Name,Account.Name,AccountId';
        Map<String, Object> fieldNamesStr=new Map<String, Object>{'Id.Name'=>'',STRING_ACCOUNT_NAME=>'','AccountId'=>''};
        String recordId;
        String orderby='Id';
        String orderDir='ASC';
        Map<String, Object> lookupmap=new Map<String, Object>{STRING_ACCOUNT_NAME=>'Account'};
        Map<String, Object> rowactionmap=new Map<String, Object>{'Edit'=>'edit'};
        String whereclause;
        Test.StartTest();
          Map<String, Object> columnactionmap=new Map<String, Object>{'Account.Name'=>'Account,200'};
          DataTableController.DataTableWrapper wrapobj=DataTableController.initRecords(objectname,fieldNamesStr,recordId,Orderby,OrderDir,true,true,lookupmap,rowactionmap,whereclause,columnactionmap,100,10);
          System.assert(wrapobj.sobList!=null);
         Test.StopTest();
       }
       
     static testMethod void testupdaterecords(){
          List<Sobject> lstcontacts= new List<Sobject>();
          
          Contact con1 = TestDataPerson.getNewContact(null);
          Contact con2 = TestDataPerson.getNewContact(null);
          List<Id> lstIds=new List<Id>{con1.Id, con2.Id};
          Test.startTest();
            lstcontacts=[Select Id , FirstName ,Birthdate from Contact where ID IN:lstIds];
            String updateString ='[{"FirstName":"Test","Birthdate":"2020-03-18","Contact_Me_Requested_Date__c":"2019-05-21T07:46:40.000+0000","id":"row-0"}]';
            
            DataTableController.updateRecords(lstcontacts,UpdateString,'Contact');
            List<Contact> lstcontact=[Select Id , FirstName ,Birthdate from Contact where ID IN:lstIds];
            System.assertEquals('Test',lstcontact[0].FirstName);     
          Test.stopTest();

     }
    
     }