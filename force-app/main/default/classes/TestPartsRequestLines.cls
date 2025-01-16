/***************************************************************************************************************************************
 * NAME   : TestPartsRequestLines
 * DESCRIPTION  : TestClass for  PartsRequestLines.cls -> notifyInventoryAuthority
 *    
 * @AUTHOR : Nitin
 * @DATE   : 12th Sept 2024 
 *
 * MODIFICATION LOG:   
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Nitin             12th Sept 2024           Initial Version
***************************************************************************************************************************************
*/ 
@IsTest
public class TestPartsRequestLines {

  @IsTest
  private static void testnotifyInventoryAuthority() { 
      List < SVMXC__Site__c > locationList = new List < SVMXC__Site__c > ();
      Account testAccount = TestDataAccount.getAccount('Test ACC', 'USD');
      testAccount.Account_Group__c='Distributor';
      testAccount.ERP_Customer_Id__c = 'Test1';
      INSERT testAccount;

      User serviceEngineer = TestDataFieldService.createUser('Field Service Logistics',false);
      INSERT serviceEngineer;

      SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
      sourceLocation.Name = 'source location';
      sourceLocation.SVMXC__Account__c = testAccount.Id;
      sourceLocation.SVMXC__Stocking_Location__c = true;
      sourceLocation.SVMXC__Service_Engineer__c = serviceEngineer.Id;
      INSERT sourceLocation;

      system.assertNotEquals(null,sourceLocation.Id); 

      //Create Destination Location
      SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
      destinationLocation.Name = 'destination Location';
      destinationLocation.SVMXC__Account__c = testAccount.Id;
      destinationLocation.SVMXC__Stocking_Location__c = true;
      locationList.add(destinationLocation);
      INSERT destinationLocation;
      system.assertNotEquals(null,destinationLocation.Id); 

      //Create Parts Request
      SVMXC__Parts_Request__c partsRequest = new SVMXC__Parts_Request__c();
      partsRequest.SVMXC__Requested_From__c = sourceLocation.Id;
      partsRequest.SVMXC__Required_At_Location__c = destinationLocation.Id;
      INSERT partsRequest;

      system.assertNotEquals(null,partsRequest.SVMXC__Requested_From__c); 

      SVMXC__Parts_Request_Line__c partsRequestLine = new SVMXC__Parts_Request_Line__c();
      partsRequestLine.SVMXC__Parts_Request__c = partsRequest.Id;
      INSERT partsRequestLine;

      //Updates Parts Request Line
      SVMXC__Parts_Request_Line__c toUpdatepartsRequestLine = [SELECT Id, SVMXC__Posted_To_Inventory__c FROM SVMXC__Parts_Request_Line__c WHERE Id =: partsRequestLine.Id];
      toUpdatepartsRequestLine.SVMXC__Posted_To_Inventory__c = TRUE;
      UPDATE toUpdatepartsRequestLine;

      SVMXC__Parts_Request_Line__c ip= [select id,Inventory_Authority_Source__c from SVMXC__Parts_Request_Line__c where id=:partsRequestLine.id];
      System.assertEquals(ip.Inventory_Authority_Source__c, serviceEngineer.Id);
  }


  @IsTest
  private static void testnotifyInventoryAuthorityPreferredLocation() { 
      List < SVMXC__Site__c > locationList = new List < SVMXC__Site__c > ();
      Account testAccount = TestDataAccount.getAccount('Test ACC', 'USD');
      testAccount.Account_Group__c='Distributor';
      testAccount.ERP_Customer_Id__c = 'Test1';
      INSERT testAccount;

      User serviceEngineer = TestDataFieldService.createUser('Field Service Logistics',false);
      INSERT serviceEngineer;

      SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam('TestTeam','US');
      INSERT serviceTeam;

      SVMXC__Service_Group_Members__c fieldSupport = TestDataFieldService.getNewFieldSupport(serviceEngineer.Id,'PreferedTechnician',serviceTeam.Id);
      SVMXC__Site__c sourceLocation = new SVMXC__Site__c();
      sourceLocation.Name = 'source location';
      sourceLocation.SVMXC__Account__c = testAccount.Id;
      sourceLocation.SVMXC__Stocking_Location__c = true;
      sourceLocation.SVMX_PS_Preferred_Technician__c = fieldSupport.Id;
      INSERT sourceLocation;

      system.assertNotEquals(null,sourceLocation.Id); 

      //Create Destination Location
      SVMXC__Site__c destinationLocation = new SVMXC__Site__c();
      destinationLocation.Name = 'destination Location';
      destinationLocation.SVMXC__Account__c = testAccount.Id;
      destinationLocation.SVMXC__Stocking_Location__c = true;
      locationList.add(destinationLocation);
      INSERT destinationLocation;
      system.assertNotEquals(null,destinationLocation.Id); 

      //Create Parts Request
      SVMXC__Parts_Request__c partsRequest = new SVMXC__Parts_Request__c();
      partsRequest.SVMXC__Requested_From__c = sourceLocation.Id;
      partsRequest.SVMXC__Required_At_Location__c = destinationLocation.Id;
      INSERT partsRequest;

      system.assertNotEquals(null,partsRequest.SVMXC__Requested_From__c); 

      SVMXC__Parts_Request_Line__c partsRequestLine = new SVMXC__Parts_Request_Line__c();
      partsRequestLine.SVMXC__Parts_Request__c = partsRequest.Id;
      INSERT partsRequestLine;

      //Updates Parts Request Line
      SVMXC__Parts_Request_Line__c toUpdatepartsRequestLine = [SELECT Id, SVMXC__Posted_To_Inventory__c FROM SVMXC__Parts_Request_Line__c WHERE Id =: partsRequestLine.Id];
      toUpdatepartsRequestLine.SVMXC__Posted_To_Inventory__c = TRUE;
      UPDATE toUpdatepartsRequestLine;

      SVMXC__Parts_Request_Line__c ip= [select id,Inventory_Authority_Source__c from SVMXC__Parts_Request_Line__c where id=:partsRequestLine.id];
      SVMXC__Site__c fromLoc= [select id,SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c from SVMXC__Site__c where id=:sourceLocation.id];

      System.assertEquals(ip.Inventory_Authority_Source__c , fromLoc.SVMX_PS_Preferred_Technician__r.SVMXC__Salesforce_User__c);     
  }

}