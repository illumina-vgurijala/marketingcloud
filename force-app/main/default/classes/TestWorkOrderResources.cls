/***************************************************************************************************************************************
 * NAME   : TestWorkOrderResources 
 * DESCRIPTION  : TestClass for Work Orders Resources Trigger
 *           
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 30-May-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                   DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Digvijay                 30-May-2019            Initial Version
 * Akshay Mohan             15-June-2021           DCP-38968: Add coverage for Opportunity sharing
  ****************************************************************************************************************************************/ 
@isTest(SeeAllData = false)
public with sharing class TestWorkOrderResources {
  
    private static final String SHARE_ACCESS_LEVEL='Read';//DCP-38968
    /**
     *  @AUTHOR:  Digvijay
     *  @DESCRIPTION: This method sets up data
     *  @PARAM :  set<Id> setFieldSupportWorkOrderIds
     */
    @testSetup
    public static void initializeTestData()
    {
        //DCP-38968: Start- Move setup data logic to where it is supposed to be
        User objFSUser = TestDataUser.findUserInProfile(System.label.Field_Service);
        User objFSUser2 = TestDataUser.findUserInProfile(System.label.Field_Service,new Set<Id>{objFSUser.Id});
         
        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test','country');
        insert serviceTeam;
            
        List<SVMXC__Service_Group_Members__c> lstTechnicians =new List<SVMXC__Service_Group_Members__c>();
        SVMXC__Service_Group_Members__c technician =TestDataFieldService.createTechnician(objFSUser.id,Label.Primary_Field_Application_Scientists,serviceTeam.id);
        technician.SVMXC__Email__c='a@b.com';
        lstTechnicians.add(technician);
        
        technician =TestDataFieldService.createTechnician(objFSUser2.id,Label.Field_Support_User_Role_Primary_FSE,serviceTeam.id);
        technician.SVMXC__Email__c='ax@b.com';
        lstTechnicians.add(technician);
        
        insert lstTechnicians;
        
        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        insert acc;
 
        
        Account_to_Field_Support__c accTechRole = new Account_to_Field_Support__c(
            Account__c = acc.Id,
            User__c = technician.Id,
            User_Role__c = 'Primary Field Application Scientist'
        );
        insert accTechRole;
        
        
		SVMXC__Installed_Product__c objIP=TestDataFieldService.createInstalledProduct('Test Installed product','USD','Installed');
        insert objIP;
        
        Contact con = TestDataPerson.getNewContact(null);
        Case cs = TestDataCase.initServiceRequestCase(con);
        Opportunity opp=TestDataOpportunity.initOpportunity(acc,Opportunities.RECORD_TYPE_MAP.get(Label.FieldServices).getRecordTypeId(),Label.OpportunityStageDevelop,Label.OpportunityTypeBillableService,Label.OpportunityProductInterestBreakFix);
        insert opp;
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, cs.Id, Label.WorkOrderStatusInitiated);
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Group_Member__c=technician.id;
        workOrder.SVMXC__Contact__c=con.id;
        workOrder.Opportunity__c=opp.id;
        insert workOrder;
        //DCP-38968: End- Move setup data logic to where it is supposed to be
    }
    
    
    /**
    *  @author Ritika Maheshwari
    *  @description - test the work order status on case when a new work order is inserted 
    **/
    static testMethod void workOrderResourceUpdate(){
        //DCP-38968: Start- Get records from setup
        Contact con = [SELECT Id,Name,AccountId FROM Contact LIMIT 1];
        System.debug('con: '+con);
        Case cs = TestDataCase.initServiceRequestCase(con);
        Case cs2 = TestDataCase.initServiceRequestCase(con);
        Case cs3 = TestDataCase.initServiceRequestCase(con);
        insert new List<Case>{cs,cs2,cs3};
        
        SVMXC__Service_Group_Members__c technician=null;
        SVMXC__Service_Group_Members__c technicianFSE=null;
        Set<String> setNames=new Set<String>{Label.Primary_Field_Application_Scientists,Label.Field_Support_User_Role_Primary_FSE};
        for(SVMXC__Service_Group_Members__c objMember : [SELECT  ID,Name 
                                                        FROM SVMXC__Service_Group_Members__c 
                                                        WHERE Name IN :setNames]){
            if(objMember.Name ==Label.Primary_Field_Application_Scientists){
                technician=objMember;
            }
            if(objMember.Name ==Label.Field_Support_User_Role_Primary_FSE){
                technicianFSE=objMember;
            }
        }
        System.debug('technician: '+technician);
        System.debug('technicianFSE: '+technicianFSE);
        Account acc =[SELECT Id,Name FROM Account LIMIT 1];
        System.debug('acc: '+acc);
        SVMXC__Installed_Product__c objIP=[SELECT Id,Name FROM SVMXC__Installed_Product__c LIMIT 1];
        System.debug('objIP: '+objIP);
        //DCP-38968: End- Get records from setup
        Test.startTest();
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, cs.Id, Label.WorkOrderStatusInitiated);
        workOrder.Record_Created_from_SFM__c=true;
        workOrder.SVMXC__Group_Member__c=technician.id;
        //DCP-38968: Start- Consolidate WO inserts
        SVMXC__Service_Order__c objWOFirstPM = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, cs2.Id, Label.WorkOrderStatusInitiated);
        objWOFirstPM.SVMXC__Order_Type__c='Preventative Maintenance';
        objWOFirstPM.SVMXC__Group_Member__c=technician.id;
        objWOFirstPM.SVMXC__Component__c=objIP.id;
        objWOFirstPM.createddate=System.now();
        objWOFirstPM.SVMXC__Billing_Type__c='Contract';
        objWOFirstPM.Is_Auto_Created__c = true;
        objWOFirstPM.SVMXC__Case__c = null;
        SVMXC__Service_Order__c instworkOrder = TestDataFieldService.createWorkOrder(Label.WorkOrderRecordTypeFieldService, cs3.Id, Label.WorkOrderStatusInitiated);
        instworkOrder.SVMXC__Order_Type__c='Installation';
        instworkOrder.SVMXC__Company__c=acc.id;
        instworkOrder.Is_Auto_Created__c = true;
        
        insert new List<SVMXC__Service_Order__c>{workOrder,objWOFirstPM,instworkOrder};
        //DCP-38968: End- Consolidate WO inserts
        
        SVMXC__Work_Order_Resource__c objWOR=new SVMXC__Work_Order_Resource__c();
        objWOR.SVMXC__Work_Order__c=workOrder.id;
        objWOR.SVMXC__Group_Member__c=technicianFSE.id;
        insert objWOR;
		
		List<SVMXC__Work_Order_Resource__c> lstWORforWO=[Select id from SVMXC__Work_Order_Resource__c where SVMXC__Work_Order__c=:workOrder.id ];
        System.assertEquals(1,lstWORforWO.size(),'lstWORforWO size incorrect');
        
        
        List<SVMXC__Work_Order_Resource__c> lstWOR=new WorkOrderResourceSelector().selectWorkOrderResources(new set<id>{workOrder.id});
        //DCP-38968: Start- Update and delete only required resources
        List<SVMXC__Work_Order_Resource__c> lstWORForUpdate=new List<SVMXC__Work_Order_Resource__c> ();
        for(SVMXC__Work_Order_Resource__c obj:lstWOR){
            if(obj.SVMXC__Group_Member__c!=technician.id){
                obj.SVMXC__Work_Order__c=instworkOrder.id;
                lstWORForUpdate.add(obj);
            }
        }
        
        update lstWORForUpdate;
        //DCP-38968: End- Update and delete only required resources
        lstWORforWO=[Select id from SVMXC__Work_Order_Resource__c where SVMXC__Work_Order__c=:instworkOrder.id ];
        System.assertEquals(1,lstWORforWO.size(),'lstWORforWO size is incorrect');
        delete lstWOR;
        
        Test.stopTest();
    }
    
    /**DCP-38968
    *  @author Akshay Mohan
    *  @description - test WO Resource insert & delete with Opportunity
    **/
    @isTest
    static void resourceMemberWithOpp(){
        SVMXC__Service_Order__c workOrder =[SELECT ID,Name,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1];
        System.debug('workOrder: '+workOrder);
        List<SVMXC__Work_Order_Resource__c> lstWOR=new WorkOrderResourceSelector().selectWorkOrderResources(new set<id>{workOrder.id});
        System.assertEquals(1,lstWOR.size(),'Resource not inserted as expected.');
        SVMXC__Work_Order_Resource__c objTechResource=lstWOR[0];
        System.debug('objTechResource: '+objTechResource);
        SVMXC__Service_Group_Members__c technician=null;
        SVMXC__Service_Group_Members__c technicianFSE=null;
        Set<ID> setUserIds = new Set<Id>();
        for(SVMXC__Service_Group_Members__c objTech : [SELECT ID,Name,SVMXC__Salesforce_User__c 
                                                        FROM SVMXC__Service_Group_Members__c LIMIT 2]){
            if(objTech.Name ==Label.Primary_Field_Application_Scientists){
                technician=objTech;
            }
            if(objTech.Name ==Label.Field_Support_User_Role_Primary_FSE){
                technicianFSE=objTech;
            }
            setUserIds.add(objTech.SVMXC__Salesforce_User__c);
        }
        System.debug('technician: '+technician);
        System.debug('technicianFSE: '+technicianFSE);
        System.debug('setUserIds: '+setUserIds);
        System.assertEquals(technicianFSE.id,objTechResource.SVMXC__Group_Member__c,'Wrong Work Order Resource Created');
        List<OpportunityShare> lstShares=[SELECT OpportunityAccessLevel,UserOrGroupId,OpportunityId 
                                            FROM OpportunityShare WHERE UserOrGroupId IN :setUserIds];
        
        User objWOTech=new User(Id=technicianFSE.SVMXC__Salesforce_User__c);
        System.runAs(objWOTech){
            Test.startTest();
            objTechResource.SVMXC__Group_Member__c=technician.id;
            update objTechResource;
            Test.stopTest();
        }
        lstShares=[SELECT OpportunityId,OpportunityAccessLevel,UserOrGroupId FROM OpportunityShare WHERE UserOrGroupId IN :setUserIds];
        System.assertEquals(1,lstShares.size(),'Shares not correct post update');
        System.assertEquals(technician.SVMXC__Salesforce_User__c,lstShares[0].UserOrGroupId,'Shares not correct post user update');
        System.assertEquals(workOrder.Opportunity__c,lstShares[0].OpportunityId,'Wrong opportunity shared');
        System.assertEquals(SHARE_ACCESS_LEVEL,lstShares[0].OpportunityAccessLevel,'Wrong access shared');
    }

    /**DCP-38968
    *  @author Akshay Mohan
    *  @description - test WO Resource insert & delete with Opportunity
    **/
    @isTest
    static void resourceMemberWithOppNoShareDiff(){
        SVMXC__Service_Order__c workOrder =[SELECT ID,Name,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1];
        System.debug('workOrder: '+workOrder);
        List<SVMXC__Work_Order_Resource__c> lstWOR=new WorkOrderResourceSelector().selectWorkOrderResources(new set<id>{workOrder.id});
        SVMXC__Work_Order_Resource__c objTechResource=lstWOR[0];
        System.debug('objTechResource: '+objTechResource);
        SVMXC__Service_Group_Members__c technician=null;
        SVMXC__Service_Group_Members__c technicianFSE=null;
        Set<ID> setUserIds = new Set<Id>();
        for(SVMXC__Service_Group_Members__c objTech : [SELECT ID,Name,SVMXC__Salesforce_User__c 
                                                        FROM SVMXC__Service_Group_Members__c LIMIT 2]){
            if(objTech.Name ==Label.Primary_Field_Application_Scientists){
                technician=objTech;
            }
            if(objTech.Name ==Label.Field_Support_User_Role_Primary_FSE){
                technicianFSE=objTech;
            }
            setUserIds.add(objTech.SVMXC__Salesforce_User__c);
        }
        System.debug('technician: '+technician);
        System.debug('technicianFSE: '+technicianFSE);
        System.debug('setUserIds: '+setUserIds);
        User objWOTech=new User(Id=technicianFSE.SVMXC__Salesforce_User__c);
        //give read to WO technician
        OpportunityShare oppShare = new OpportunityShare(
                                            UserOrGroupId = technician.SVMXC__Salesforce_User__c,
                                            OpportunityAccessLevel = SHARE_ACCESS_LEVEL,
                                            RowCause = Schema.OpportunityShare.RowCause.Manual,
                                            OpportunityId=workOrder.Opportunity__c);
        insert oppShare;
        System.debug('Opp shared with '+technician);
        System.runAs(objWOTech){
            Test.startTest();
            objTechResource.SVMXC__Group_Member__c=technician.id;
            update objTechResource;
            Test.stopTest();
        }
        List<OpportunityShare> lstShares=[SELECT OpportunityId,OpportunityAccessLevel,UserOrGroupId FROM OpportunityShare WHERE UserOrGroupId IN :setUserIds];
        System.assertEquals(1,lstShares.size(),'Shares not correct post update');
        System.assertEquals(technician.SVMXC__Salesforce_User__c,lstShares[0].UserOrGroupId,'Shares not done for technician');
        System.assertEquals(workOrder.Opportunity__c,lstShares[0].OpportunityId,'Wrong opportunity shared');
        System.assertEquals(SHARE_ACCESS_LEVEL,lstShares[0].OpportunityAccessLevel,'Wrong access shared');
    }
     /**
      *  @author Prashanth
      *  @description - test WO Resource insert with queueable framework
      **/
      @isTest
      static void testInsertWorkOrderResource(){
          
          Test.startTest();
          SVMXC__Service_Order__c workOrder =[SELECT ID,Name,Opportunity__c FROM SVMXC__Service_Order__c LIMIT 1];
          System.debug('workOrder: '+workOrder);
          List<SVMXC__Work_Order_Resource__c> lstWOR=new WorkOrderResourceSelector().selectWorkOrderResources(new set<id>{workOrder.id});
          System.assertEquals(1,lstWOR.size(),'Resource not inserted as expected.');
          SVMXC__Work_Order_Resource__c objTechResource=lstWOR[0];
          System.debug('objTechResource: '+objTechResource);
          SVMXC__Service_Group_Members__c technician=null;
          SVMXC__Service_Group_Members__c technicianFSE=null;
          Set<ID> setUserIds = new Set<Id>();
          for(SVMXC__Service_Group_Members__c objTech : [SELECT ID,Name,SVMXC__Salesforce_User__c 
                                                          FROM SVMXC__Service_Group_Members__c LIMIT 2]){
              if(objTech.Name ==Label.Primary_Field_Application_Scientists){
                  technician=objTech;
              }
              if(objTech.Name ==Label.Field_Support_User_Role_Primary_FSE){
                  technicianFSE=objTech;
              }
              setUserIds.add(objTech.SVMXC__Salesforce_User__c);
          }
          System.debug('technician: '+technician);
          System.debug('technicianFSE: '+technicianFSE);
          System.debug('setUserIds: '+setUserIds);
          System.assertEquals(technicianFSE.id,objTechResource.SVMXC__Group_Member__c,'Wrong Work Order Resource Created');
          Test.stopTest();
      }
  }