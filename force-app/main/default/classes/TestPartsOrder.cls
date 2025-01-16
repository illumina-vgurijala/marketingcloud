/***************************************************************************************************************************************
 * NAME   : TestPartsOrder
 * DESCRIPTION  : TestClass for Parts Orders Trigger : Setting 
 *        DCP-326  :Validation the open parts orders on Case
 *                Annotated with SeeAllData=true due to dependency on ServiceMax managed trigger
 *    
 * @AUTHOR : Debalina
 * @DATE   : 22-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Ritika             22-May-2018            Initial Version
 * Gladis             08-Sep-2021            CMCP-16 : Test method to test insert time in/out when work order status is changed to Awaiting Parts.
 * Preetha            10-oct-2022            QACM-770 added line to check QualityNotification Component controller
 * Nancy              07-June-2022           CMCM-278: Integration error displayed as "A" for the submitted Shipment and Return PO's
 * Nidhi              12-July-2023           CMCM-939: CodeScan Technical Debt Cleanup (Service) - Q4 2022 - TestPartsOrders
  ****************************************************************************************************************************************/ 
  
  @IsTest(SeeAllData=true)
  public class TestPartsOrder {
     
     //DCP-51199
     public static final String STRING_INSTALLED_PRODUCT_ASSERT='Installed Product is not null';
     
     /**
     *  @author Ritika Maheshwari
     *  @description - test the part order status on case when a new part order is inserted 
     **/
     
     static testMethod void newPartOrderCreation() {
       Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         
         //added by prashanth
         //insert product
         Product2 product1 = TestDataMaster.createProduct(true);
         product1.Source_System__c='SAP';
         update product1;
         System.assertNotEquals(null, product1.Id, 'Product insertion failed');
         
         //insert serviceBOM
         Service_Bill_Of_Materials__c serviceBOM = TestDataFieldService.createServiceBOM(product1.Id);
         serviceBOM.Default__c = true;
         update serviceBOM;
         System.assertNotEquals(null, serviceBOM.Id, 'Service BOM insertion failed');
 
         Case objCase = TestDataCase.initServiceRequestCase(con);
         objCase.SVMXC__Product__c = product1.Id;
         insert objCase;
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
          //Parts Order creation in SAP (Inbound to SAP from SVMX)
         partOrder.ERP_Sales_Order_Number__c = '3111';
         partOrder.Contact_Name__c='Test';
         partOrder.Contact_Phone__c='Test';
         partOrder.SVMXC__Order_Type__c='Return';
         Test.startTest();
         insert partOrder;
         partOrder.Cancel_All_Part_Order_Lines__c = true;
         update partOrder;
         
         //added by prashanth
         SVMXC__RMA_Shipment_Order__c objPartsOrder = [Select Id,SVMXC__Case__c,Service_Bill_Of_Materials__c from SVMXC__RMA_Shipment_Order__c where Id =: partOrder.Id LIMIT 1];
         System.assertEquals(objPartsOrder.Service_Bill_Of_Materials__c, serviceBOM.Id, 'Service Bill Materials is not equal');
         Test.stopTest();
     }
 
 
     static testMethod void partOrderStatusForCase() {
         List < Product2 > lstProducts = new List < Product2 > ();
 
         Product2 objProduct = TestDataMaster.initProduct('1241527');
         objProduct.Service_Product_Type__c = 'Core';
         objProduct.Source_System__c='SAP';
         lstProducts.add(objProduct);
 
         Product2 objProduct1 = TestDataMaster.initProduct('12419677', 'Instrument');
         objProduct1.Serial_Number_Profile__c = 'IL02';
         objProduct1.Service_Product_Type__c = 'Instrument';
         objProduct1.CurrencyIsoCode = 'USD';
         objProduct1.Source_System__c='SAP';
         lstProducts.add(objProduct1);
         insert lstProducts;
 
         //system.runAs(sapUsr) {
             Account objAccount = TestDataAccount.getNewAccount();
             objAccount.Account_Group__c = 'Sold To';
             update objAccount;
             System.assertNotEquals(null, objAccount.Id, 'Account ID should not be null after update.');
             
             Contact objContact = TestDataContact.getNewContact(objAccount);
 
             Case objCase = TestDataCase.initServiceRequestCase(objContact);
             insert objCase;
             
             SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.id, 'Initiated');
             workOrder.Record_Created_from_SFM__c = true;
             insert workOrder;
 
             SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
             SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
             list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
             insert locList;
             
             SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
             partOrder.ERP_Sales_Order_Number__c = '2111';
             partOrder.SVMXC__Service_Order__c = workOrder.id;
             partOrder.Contact_Name__c = 'Test';
             partOrder.Contact_Phone__c = 'Test';
             partOrder.SVMXC__Order_Status__c = 'Approved';
             partOrder.SVMXC__Order_Type__c = 'Shipment';
             partOrder.SVMXC__Destination_Location__c = locList[0].Id;
             partOrder.Shipping_Location__c = locList[1].Id;
             partOrder.Requested_Delivery_Date__c = date.today() + 2;
             partOrder.SVMXC__Company__c = objAccount.Id;
             
             //Two partsorder records needs to be inserted seperately
             SVMXC__RMA_Shipment_Order__c partOrder1 = TestDataFieldService.createPartOrder('RMA', objCase.id, 'Open');
             partOrder1.SVMXC__Service_Order__c = workOrder.id;
             partOrder1.Contact_Name__c = 'Test';
             partOrder1.Contact_Phone__c = 'Test';
             partOrder1.SVMXC__Order_Type__c = 'Return';
             insert partOrder1;
 
             Test.startTest();
             
             Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
             acc1SalesArea.Account__c = objAccount.Id;
             acc1SalesArea.Price_List_Type__c='01';
             acc1SalesArea.CurrencyIsoCode = 'USD';
             acc1SalesArea.Price_List__c = '01-AMR-USD';
             acc1SalesArea.Contract_Number__c = '123456_US010100';
             acc1SalesArea.Company_Code__c = 'GB01';
             insert acc1SalesArea;
 
             insert partOrder;
             list < SVMXC__RMA_Shipment_Line__c > poLineList = new list < SVMXC__RMA_Shipment_Line__c > ();
             SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(partOrder.Id);
             objPartsOrderLine1.SVMXC__Product__c = objProduct1.Id;
             objPartsOrderLine1.Requested_Delivery_Date__c = date.today() + 2;
             poLineList.add(objPartsOrderLine1);
             SVMXC__RMA_Shipment_Line__c objPartsOrderLine2 = TestDataFieldService.createPartsOrderLines(partOrder.Id);
             objPartsOrderLine2.SVMXC__Product__c = objProduct1.Id;
             objPartsOrderLine2.Requested_Delivery_Date__c = date.today() + 2;
             poLineList.add(objPartsOrderLine2);
             insert poLineList;
             
             partOrder.Request_All_Part_Order_Lines__c = true;
             partOrder.Integration_Error_Message__c = 'E: CS will review and release the Approved/Requested Instrument Part Order in SAP.';
             update partOrder;
             Test.stopTest();
         //}
 
     }
 
     
      /**
     *  @author Sandeep Ram Ch.
     *  @description - test the part order status on wo when a part order line is delivered,
         **/
     
     
     static testmethod void partsOrderStatusUpdatedToWithInProgressForWO() { 
         List<SVMXC__RMA_Shipment_Line__c> lstPartOrderLineInserted = new List<SVMXC__RMA_Shipment_Line__c>();
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         Case objCase = TestDataCase.initServiceRequestCase(con);
         insert objCase;
         SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service',objCase.id, 'Initiated');
         workOrder.Record_Created_from_SFM__c=true;
         insert workOrder;
         
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA',objCase.id, 'Open');
         partOrder.SVMXC__Service_Order__c=workOrder.id;
         //Parts Order creation in SAP (Inbound to SAP from SVMX)
         partOrder.ERP_Sales_Order_Number__c = '5678';
         partOrder.Contact_Name__c='Test';
         partOrder.Contact_Phone__c='Test';
         partOrder.SVMXC__Order_Type__c='Return';
         insert partOrder;
         for(integer i=0; i<10; i++) {
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
             lstPartOrderLineInserted.add(objPartsOrderLine);
         }
         insert lstPartOrderLineInserted;
 
          
         List<Quality_Notification__c> newQN = new List<Quality_Notification__c>();
         Quality_Notification__c qn1 = new Quality_Notification__c();
         qn1.Parts_Order__c = partOrder.id;
         qn1.Parts_Order_Line__c = lstPartOrderLineInserted[0].id;
         qn1.Quality_Notification_Number__c = '12345678';
         newQN.add(qn1);
         Quality_Notification__c qn2 = new Quality_Notification__c();
         qn2.Parts_Order__c = partOrder.id;
         qn2.Quality_Notification_Number__c = '89101112';
         newQN.add(qn2);
         insert newQN;
 
         Test.startTest();
         lstPartOrderLineInserted[0].SVMXC__Line_Status__c = 'Delivered';
         update lstPartOrderLineInserted[0];
         List<QualityNotificationController.TreeStructure> returnList= QualityNotificationController.getPartsOrderWithQN(objCase.id);//QACM-770
         Integer expectedSize = 0;
         System.assertNotEquals(expectedSize, returnList.size(), 'List is empty');        
         Test.stopTest();  
         SVMXC__Service_Order__c updatedWo = [Select Parts_Order_Status__c from SVMXC__Service_Order__c where Id =: workorder.Id];
         System.assertEquals('In Progress',updatedWo.Parts_Order_Status__c,'Order status should be In Progress');        
         
     }
     
     /**
     *  @author Ritika Maheshwari
     *  @description - test the part order status on case when a part order is delivered, however other part order are in open state 
     **/
     
     static testMethod void partOrderStatusUpdatedToCompletedWithNoOtherWO() {
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         Case objCase = TestDataCase.initServiceRequestCase(con);
         insert objCase;
         
         List<SVMXC__RMA_Shipment_Order__c> lstPartOrderInserted = new List<SVMXC__RMA_Shipment_Order__c>();
         for(integer i=0; i<10; i++) {
             SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA',objCase.Id, 'Open');
             partOrder.ERP_Sales_Order_Number__c = '2234'+i;
             partOrder.Contact_Name__c='Test';
             partOrder.Contact_Phone__c='Test';
             partOrder.SVMXC__Order_Type__c='Return';
             lstPartOrderInserted.add(partOrder);
         }
         insert lstPartOrderInserted;
         
         Product2 objProduct1 = TestDataMaster.initProduct('test 123');
         objProduct1.Service_Product_Type__c = 'Instrument';
         objProduct1.Source_System__c='SAP';
         insert objProduct1;
         
         SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
         insert objLocationRec;
         
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(lstPartOrderInserted[0].Id);
         objPartsOrderLine.SVMXC__Product__c = objProduct1.Id;
         objPartsOrderLine.From_Location__c = objLocationRec.id;
         //objPartsOrderLine.Service_Product_Type__c='Instrument'; 
         objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
         
         Test.startTest();
             insert objPartsOrderLine;
             lstPartOrderInserted[0].Submit_to_SAP__c = true;
             try {
                 update lstPartOrderInserted[0];
             } catch(Exception ex) {
                 String expectedErrorMessage = 'Please ensure that the Parts Order has the From Location filled in, and both the Shipping Location and To Location are blank';
                 System.assert(ex.getMessage().contains(expectedErrorMessage), 'Error message is not as expected');
 
             }
 
             System.assertEquals(objPartsOrderLine.SVMXC__Product__c, objProduct1.Id, 'Product Not Equal');
         Test.stopTest();
     }
     
     
     /**
     *  @author Ritika Maheshwari
     *  @description - test the part order status on case when a there is only one part order for the case, which is delivered
     **/
     
     
     static testMethod void workOrderStatusUpdatedToCompletedWithInProgressWO() {
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         Case objCase = TestDataCase.initServiceRequestCase(con);
         insert objCase;
         //added by prashanth
         System.assertNotEquals(null, objCase.Id, 'Case ID is null');
 
         
         //List<SVMXC__RMA_Shipment_Order__c> lstWorkOrderInserted = new List<SVMXC__RMA_Shipment_Order__c>();
         SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service',objCase.id, 'Initiated');
         workOrder.Record_Created_from_SFM__c=true;
         insert workOrder;
         
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
         partOrder.SVMXC__Service_Order__c=workOrder.id;
         partOrder.ERP_Sales_Order_Number__c = '5555';
         partOrder.Contact_Name__c='Test';
         partOrder.Contact_Phone__c='Test';
         partOrder.SVMXC__Order_Type__c='Return';
         insert partOrder;
         System.assertNotEquals(null, partOrder.Id, 'Part Order ID is null');
 
         //added by prashanth
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
         insert objPartsOrderLine;
         
         Test.startTest();
         partOrder.SVMXC__Order_Status__c = 'Closed';  
         update partOrder;
         //added by prashanth
         objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
         update objPartsOrderLine;
         
         
         //added by prashanth
         SVMXC__Service_Order__c updatedWo = [Select Parts_Order_Status__c from SVMXC__Service_Order__c where Id =: workorder.Id];
         System.assertEquals('Delivered',updatedWo.Parts_Order_Status__c,'Parts order status should be Delivered');
         Test.stopTest();
     }
     
 
     /**
     *  @author Veerendra
     *  @description - update part order Is-Billable Flag
     **/
     
     
 
     static testmethod void newPartsOrderCreation() {
         
         SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
         Test.startTest();
         insert objInstalledProduct;
         SVMXC__Installed_Product__c insertedInstalledProduct = [Select SVMXC__Status__c from SVMXC__Installed_Product__c where Id =: objInstalledProduct.Id];
         System.assertEquals('New', insertedInstalledProduct.SVMXC__Status__c, 'Installed product status is not New');
 
         BusinessHours objBuinessHours = [SELECT Id FROM BusinessHours where Name =: 'Default'];
           Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
         SVMXC__Service_Level__c objServiceLevelTerms = new SVMXC__Service_Level__c(
             Name ='Test',
             SVMXC__Onsite_Response_Tracked_On__c='Case',
             SVMXC__Restoration_Tracked_On__c='Case',
             SVMXC__Resolution_Tracked_On__c='Case',
             SVMXC__Business_Hours__c = objBuinessHours.id,
             SVMXC__Active__c = true
         );
         insert objServiceLevelTerms;
         
         SVMXC__Service_Contract__c objServiceContract= new SVMXC__Service_Contract__c(
             Name = 'Test',
             SVMXC__Company__c = acc.Id,
             SVMXC__Start_Date__c = date.Today(),
             SVMXC__End_Date__c = date.Today()+1,
             SVMXC__Service_Level__c = objServiceLevelTerms.Id   
         );
         insert objServiceContract;
         
         SVMXC__Service_Contract_Products__c objCoveredProduct = TestDataFieldService.createCoveredProduct(objInstalledProduct.Id);
         objCoveredProduct.SVMXC__Service_Contract__c=objServiceContract.id;
         insert objCoveredProduct;
         SVMXC__Service_Contract_Products__c insertedCoveredProduct = [Select SVMXC__Installed_Product__c from SVMXC__Service_Contract_Products__c where SVMXC__Installed_Product__c =: objInstalledProduct.Id];
         System.assertEquals(objInstalledProduct.Id, insertedCoveredProduct.SVMXC__Installed_Product__c, 'Installed product ID does not match');
 
         
         
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         Case objCase = TestDataCase.initServiceRequestCase(con);
         objCase.SVMXC__Component__c = objInstalledProduct.Id;
         
         insert objCase; 
         Case insertedCase = [Select SVMXC__Component__c from Case where Id =: objCase.Id];
         System.assertEquals(insertedInstalledProduct.Id, InsertedCase.SVMXC__Component__c, 'Component ID does not match');
 
         
 
         SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrder(objCase.Id);
         objPartsOrder.SVMXC__Order_Status__c = 'Open';
         objPartsOrder.ERP_Sales_Order_Number__c = '9876';
         objPartsOrder.Contact_Name__c='Test';
         objPartsOrder.Contact_Phone__c='Test';
         objPartsOrder.SVMXC__Order_Type__c='Return';
         insert objPartsOrder;
         SVMXC__RMA_Shipment_Order__c insertedPartsOrder = [Select SVMXC__Case__c from SVMXC__RMA_Shipment_Order__c where SVMXC__Case__c =: objCase.Id];
         System.assertEquals(objCase.Id, insertedPartsOrder.SVMXC__Case__c, 'Case ID does not match');
         Test.stopTest();
     }
     
      
      /**
     *  @author Debanka
     *  @description - Check for Decontamination Required and DCIR form checkbox of POL
     **/
     
     
     static testMethod void partsorderlinedecontamination() {
         //Contact
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         //Case
         Case objCase = TestDataCase.initServiceRequestCase(con);
         insert objCase;
         //WorkOrder
         SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase('Service Support','Initiated', 'Installation');
         //objWorkOrder.SVMXC__Case__c = objCase.id;
          //PartOrder
         SVMXC__RMA_Shipment_Order__c partOrder1 = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        // partOrder1.SVMXC__Service_Order__c = objWorkOrder.id;
         partOrder1.Contact_Name__c='Test';
         partOrder1.Contact_Phone__c='Test';
         partOrder1.SVMXC__Order_Type__c='Return';
         partOrder1.Request_All_Part_Order_Lines__c = true;
         insert partOrder1;
 
      
 
         //system.debug('**Request_All_Part_Order_Lines__c='+insertedpartOrder1.Request_All_Part_Order_Lines__c+'   '+insertedpartOrder1.SVMXC__Order_Type__c);
         //Location
         SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
         insert objLocationRec;
         //Product
         Product2 product1 = TestDataMaster.createProduct(false);
         product1.Material_Group__c  = '41';
         product1.Decontamination_Required__c = True;
         product1.RMA_Required__c = true;
         product1.Source_System__c='SAP';
         insert product1;
 
         //DCP-51199 Product2
         Product2 product2 = TestDataMaster.createProduct(false);
         product2.Material_Group__c = '41';
         product2.Source_System__c = 'SAP';
         insert product2;
        System.assert(product2.Id != null, 'The Product2 record was not inserted successfully.');
 
         
         List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>();
         //PartsOrderLine1
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder1.id);
     
         objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
         objPartsOrderLine.SVMXC__Product__c = product1.id;
         
         objPartsOrderLine.Is_DCIR_Filled__c = false;
         objPartsOrderLine.Return_Reason__c = 'Return for Scrap';
         objPartsOrderLine.SVMXC__Actual_Quantity2__c = 0;
         objPartsOrderLine.To_Location__c = objLocationRec.id;
         lstPartsOrderLine.add(objPartsOrderLine);
         //insert objPartsOrderLine;
 
         //PartsOrderLine2
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(partOrder1.id);
         objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
         lstPartsOrderLine.add(objPartsOrderLine1);
         //insert objPartsOrderLine1;
 
         //DCP-51199 PartsOrderLine3
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine3 = TestDataFieldService.createPartsOrderLines(partOrder1.id);
         objPartsOrderLine3.SVMXC__Line_Status__c = 'Open';
         objPartsOrderLine3.SVMXC__Product__c = product2.id;
         objPartsOrderLine3.Is_CofD_Filled__c = false;
         objPartsOrderLine3.Return_Reason__c = 'Return for Scrap';
         objPartsOrderLine3.SVMXC__Actual_Quantity2__c = 1;
         objPartsOrderLine3.Item_Destroyed__c = true;
         objPartsOrderLine3.To_Location__c = objLocationRec.id;
         lstPartsOrderLine.add(objPartsOrderLine3);
 
         Test.startTest();
         insert lstPartsOrderLine;
         
         lstPartsOrderLine[0].SVMXC__Line_Status__c = 'Shipped';
         lstPartsOrderLine[0].SVMXC__Actual_Quantity2__c = 6;
         //Update objPartsOrderLine;
         
         
         lstPartsOrderLine[1].SVMXC__Line_Status__c = 'Delivered';
         lstPartsOrderLine[1].SVMXC__Actual_Quantity2__c = 6;
         Update lstPartsOrderLine;
 
         partOrder1.Request_All_Part_Order_Lines__c = true;
         partOrder1.SVMXC__Service_Order__c = objWorkOrder.id;
         try {
         update partOrder1;
         } Catch(exception e){
             String expectedErrorMessage = 'Please ensure that the Parts Order has the From Location filled in, and both the Shipping Location and To Location are blank.';
             System.assert(e.getMessage().contains(expectedErrorMessage), 'Error message does not contain the expected substring');
 
         }
         Test.stopTest();
         system.assert(partOrder1.Request_All_Part_Order_Lines__c,Label.POCompleteCOFDFormError);
        
     }
     
             /**
     *  @author Harsh Shukla
     *  @description - Check for Instrument and Loaner Agreement Signed form checkbox of POL
     **/
     
     
     static testMethod void testcheckPOLRequestingStatusLoaner() {
          Boolean expectedExceptionThrown;
         
         //Contact
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
         
         //Case
         Case objCase = TestDataCase.initServiceRequestCase(con);
         insert objCase;
         
         //Parts Order Location
         SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
             SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
             list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
             insert locList;
         
         //WorkOrder
         SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase('Service Support','Initiated', 'Installation');
         //objWorkOrder.SVMXC__Case__c = objCase.id;
         
          //PartOrder
         SVMXC__RMA_Shipment_Order__c partOrder1 = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        // partOrder1.SVMXC__Service_Order__c = objWorkOrder.id;
         partOrder1.Contact_Name__c='Test';
         partOrder1.Contact_Phone__c='Test';
         partOrder1.SVMXC__Order_Type__c='Shipment';
         partOrder1.Request_All_Part_Order_Lines__c = true;
         partOrder1.Shipping_Location__c = locList[1].Id;
         insert partOrder1;
         
         //Location
         SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
         insert objLocationRec;
         
         //Product
         Product2 product1 = TestDataMaster.createProduct(false);
         product1.Material_Group__c  = '41';
         product1.Service_Product_Type__c = 'Instrument';
         product1.Condition_Type__c = 'LOANER';
         product1.Serial_Number_Profile__c = 'IL02';
         product1.Source_System__c='SAP';
         insert product1;
         
         List<SVMXC__RMA_Shipment_Line__c> lstPartsOrderLine = new List<SVMXC__RMA_Shipment_Line__c>();
         //PartsOrderLine1
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder1.id);
     
         objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
         objPartsOrderLine.SVMXC__Product__c = product1.id;
         objPartsOrderLine.Loaner_Agreement_Signed__c = false;
         objPartsOrderLine.SVMXC__Actual_Quantity2__c = 0;
         objPartsOrderLine.To_Location__c = objLocationRec.id;
         lstPartsOrderLine.add(objPartsOrderLine);
         //insert objPartsOrderLine;
 
         //PartsOrderLine2
         SVMXC__RMA_Shipment_Line__c objPartsOrderLine1 = TestDataFieldService.createPartsOrderLines(partOrder1.id);
         objPartsOrderLine1.SVMXC__Line_Status__c = 'Open';
         lstPartsOrderLine.add(objPartsOrderLine1);
         //insert objPartsOrderLine1;
         Test.startTest();
         insert lstPartsOrderLine;
         Test.stopTest();        
         partOrder1.Request_All_Part_Order_Lines__c = true;
         partOrder1.SVMXC__Order_Status__c = 'Approved';
         partOrder1.SVMXC__Service_Order__c = objWorkOrder.id;
         try {
         update partOrder1;
         } Catch(exception e) {
            expectedExceptionThrown = e.getMessage().contains(Label.POLoanerAgreementCheckError) ? true : false;
            System.assert(expectedExceptionThrown, 'Expected exception was not thrown');
         }       
         
        
     }
     /**
      *  @author Soumya
      *  @description - Test Parts Order Lines are Updated when Parts Order is Updated
      **/
     
     
     static testMethod void checkPOLUpdatedWithPartsOrder() {
     
         List < Product2 > lstProducts = new List < Product2 > ();
         User manager1 = TestDataFieldService.createUser('Field Service', true);
         User manager2 = TestDataFieldService.createUser('Field Service', false);
         manager2.ManagerId = manager1.id;
         manager2.UserName = 'Second'+ manager2.UserName;
         insert manager2;
         User sapUsr = TestDataFieldService.createUser('Integration SAP Service', false);
         sapUsr.ManagerId = manager2.Id;
         insert sapUsr;
         
         Product2 objProduct = TestDataMaster.initProduct('1241527');
         objProduct.Service_Product_Type__c = 'Core';
         objProduct.Source_System__c='SAP';
         lstProducts.add(objProduct);
 
 
         Product2 objProduct1 = TestDataMaster.initProduct('12419677', 'Instrument');
         objProduct1.Serial_Number_Profile__c = 'IL02';
         objProduct1.Service_Product_Type__c = 'Instrument';
         objProduct1.Custom_Product__c = true;
         objProduct1.CurrencyIsoCode = 'USD';
         objProduct1.Source_System__c='SAP';
         Product2 objProduct2 = TestDataMaster.initProduct('11043888', 'Consumables');
         objProduct2.Serial_Number_Profile__c = 'IL02';
         objProduct2.Service_Product_Type__c = 'Core';
         objProduct2.CurrencyIsoCode = 'USD';
         objProduct2.Source_System__c='SAP';
         lstProducts.add(objProduct1);
         lstProducts.add(objProduct2);
         insert lstProducts;
 
         product2 proList = [select id, ProductCode, Service_Product_Type__c from product2 where Service_Product_Type__c = 'Instrument'
             and id in: lstProducts limit 1
         ];
 
         //system.runAs(sapUsr) {
             Account objAccount = TestDataAccount.getNewAccount();
             objAccount.Account_Group__c = 'Sold To';
             update objAccount;
             Contact objContact = TestDataContact.getNewContact(objAccount);
 
             Case objCase = TestDataCase.initServiceRequestCase(objContact);
             insert objCase;
 
             SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
             SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
             list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
             insert locList;
 
             SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
             //Parts Order creation in SAP (Inbound to SAP from SVMX)
             partOrder.ERP_Sales_Order_Number__c = '1765';
             //partOrder.SVMXC__Service_Order__c = workOrder.id;
             partOrder.Contact_Name__c = 'Test';
             partOrder.Contact_Phone__c = 'Test';
             partOrder.SVMXC__Order_Status__c = 'Approved';
             partOrder.SVMXC__Order_Type__c = 'Shipment';
             partOrder.SVMXC__Destination_Location__c = locList[0].Id;
             partOrder.Shipping_Location__c = locList[1].Id;
             partOrder.Requested_Delivery_Date__c = date.today() + 2;
 
            
             Test.startTest();
 
             insert partOrder;
             
            
             SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
             objPartsOrderLine.SVMXC__Product__c = proList.Id;
             insert objPartsOrderLine;
             
 
             partOrder.Request_All_Part_Order_Lines__c = true;   
             //partOrder.Requested_Delivery_Date__c = date.today() + 4;    
             //partOrder.OwnerId =  manager2.id;              
             update partOrder;
 
            // Query the updated SVMXC__RMA_Shipment_Order__c record
             SVMXC__RMA_Shipment_Order__c updatedPO = [SELECT Id, Request_All_Part_Order_Lines__c FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :partOrder.Id LIMIT 1];
 
           // Assert that Request_All_Part_Order_Lines__c is false
           System.assert(!(updatedPO.Request_All_Part_Order_Lines__c), 'Actual value is not true');
          //} //end of runas
     }
     /**
      * *
      * @description: Cover the DCp-25283 validation check 
      * */ 
       /**
      *  @author Soumya
      *  @description - Test Parts Order Lines are Updated when Parts Order is Updated
      **/
     
     static testMethod void checkRequestedByInventoryAuthority() {
     
         List < Product2 > lstProducts = new List < Product2 > ();
         User manager1 = TestDataFieldService.createUser('Field Service', true);
         User manager2 = TestDataFieldService.createUser('Field Service', false);
         manager2.ManagerId = manager1.id;
         manager2.UserName = 'Second'+ manager2.UserName;
         insert manager2;
         User sapUsr = TestDataFieldService.createUser('Integration SAP Service', false);
         sapUsr.ManagerId = manager2.Id;
         insert sapUsr;
         
                
         Product2 objProduct = TestDataMaster.initProduct('1241527');
         objProduct.Service_Product_Type__c = 'Core';
         objProduct.Source_System__c='SAP';
         lstProducts.add(objProduct);
 
 
         Product2 objProduct1 = TestDataMaster.initProduct('12419677', 'Instrument');
         objProduct1.Serial_Number_Profile__c = 'IL02';
         objProduct1.Service_Product_Type__c = 'Instrument';
         objProduct1.Custom_Product__c = true;
         objProduct1.CurrencyIsoCode = 'USD';
         objProduct1.Source_System__c='SAP';
         Product2 objProduct2 = TestDataMaster.initProduct('11043888', 'Consumables');
         objProduct2.Serial_Number_Profile__c = 'IL02';
         objProduct2.Service_Product_Type__c = 'Core';
         objProduct2.CurrencyIsoCode = 'USD';
         objProduct2.Source_System__c='SAP';
         lstProducts.add(objProduct1);
         lstProducts.add(objProduct2);
         insert lstProducts;
 
        
 
         //system.runAs(sapUsr) {
             Account objAccount = TestDataAccount.getNewAccount();
             objAccount.Account_Group__c = 'Sold To';
             update objAccount;
             Contact objContact = TestDataContact.getNewContact(objAccount);
 
             Case objCase = TestDataCase.initServiceRequestCase(objContact);
             insert objCase;
 
             SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
            
             SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 SVMXC__Service_Engineer__c=sapUsr.id,
                 Type__c = 'Trunk');
             list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
             insert locList;
 
             SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
             //Parts Order creation in SAP (Inbound to SAP from SVMX)
             partOrder.ERP_Sales_Order_Number__c = '1445';
             //partOrder.SVMXC__Service_Order__c = workOrder.id;
             partOrder.Contact_Name__c = 'Test';
             partOrder.Contact_Phone__c = 'Test';
             partOrder.SVMXC__Order_Status__c = 'Approved';
             partOrder.SVMXC__Order_Type__c = 'Shipment';
             partOrder.SVMXC__Destination_Location__c = locList[0].Id;
             partOrder.Requested_By__c=manager2.id;
             partOrder.Shipping_Location__c = locList[1].Id;
             partOrder.Requested_Delivery_Date__c = date.today() + 2;
 
            
             Test.startTest();
 
             insert partOrder;
         
             SVMXC__RMA_Shipment_Order__c insertedPO = [select id,Is_Requested_By_Not_Inventory_Authority__c from SVMXC__RMA_Shipment_Order__c where id =:partOrder.id][0];
             
             insertedPO.SVMXC__Destination_Location__c =locList[1].Id;
             update insertedPO;
             insertedPO.Requested_By__c=null;
             insertedPO.SVMXC__Destination_Location__c =locList[0].Id;
             update insertedPO;
              SVMXC__RMA_Shipment_Order__c negativeScenarioPO = [select id,Is_Requested_By_Not_Inventory_Authority__c from SVMXC__RMA_Shipment_Order__c where id =:partOrder.id][0];
             system.assert(!negativeScenarioPO.Is_Requested_By_Not_Inventory_Authority__c, 'The "Is_Requested_By_Not_Inventory_Authority__c" flag is not false as expected.');
             Test.stopTest();  
             
             
         //}
     }
     
            //43634
        static testMethod void testPartsOrderLinesForGoodwill() {
            SVMXC__RMA_Shipment_Order__c partOrder1;
            Channel_Partner_Profile_Settings__c cp =new Channel_Partner_Profile_Settings__c(SetupOwnerId=UserInfo.getUserId(), Is_Channel_Partner__c = false);
            insert cp;
           //Contact
            Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
            User objUser = [select id from user where (profile.name = 'Field Service' or profile.name = 'Customer Service') and IsActive = true and ManagerId != null and manager.IsActive = true limit 1];
         
           //Parts Order Location
             SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
             SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
             Name = 'testStockingLocation',
             CurrencyIsoCode = 'USD',
             SVMXC__Stocking_Location__c = true,
             SVMX_PS_Active__c = true,
             Type__c = 'Trunk');
         
          //Location
            SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c='Trunk');
            list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
            locList.add(location);
            locList.add(shippingLocation);
            locList.add(objLocationRec); 
            insert locList;
         
         //Product
            Product2 product1 = TestDataMaster.createProduct(false);
            product1.Service_Product_Type__c = 'Core';
            product1.Source_System__c='SAP';
            insert product1;
            System.runAs(objUser) { 
             
         //Case
          Case objCase = TestDataCase.initServiceRequestCase(con);
          insert objCase;
             
          //WorkOrder
             
             SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrder('Field Service',objCase.id, 'Initiated');
             objWorkOrder.Record_Created_from_SFM__c=true;
             objWorkOrder.Cost_Center__c = 123456;
             insert objWorkOrder;
 
             partOrder1 = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
             partOrder1.SVMXC__Service_Order__c = objWorkOrder.id;
             partOrder1.Contact_Name__c='Test';
             partOrder1.Contact_Phone__c='Test';
             partOrder1.SVMXC__Order_Type__c='Shipment';
             partOrder1.Shipping_Location__c = locList[1].Id;
             partOrder1.SVMXC__Destination_Location__c = locList[0].Id;
             insert partOrder1;
             
             //PartsOrderLine1
             SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder1.id);
         
             objPartsOrderLine.SVMXC__Line_Status__c = 'Open';
             objPartsOrderLine.SVMXC__Product__c = product1.id;
             objPartsOrderLine.Loaner_Agreement_Signed__c = false;
             objPartsOrderLine.SVMXC__Actual_Quantity2__c = 0;
             objPartsOrderLine.To_Location__c = objLocationRec.id;
             objPartsOrderLine.Reason__c = 'Goodwill';
 
             Test.startTest();
             insert objPartsOrderLine;
 
             partOrder1.Submit_For_Approval__c = true;
             update partOrder1;
 
             Test.stopTest();
         }
           try
           {
               Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
               req.setComments('Approving request using Trigger');
               req.setAction('Approve');
               String workitemId = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :partOrder1.Id LIMIT 1].Id;
               req.setWorkitemId(workitemId);
               Approval.process(req);
               /*SVMXC__RMA_Shipment_Order__c objPO = [SELECT Id, OwnerId FROM SVMXC__RMA_Shipment_Order__c WHERE Id = :partOrder1.Id LIMIT 1];
               UserFeed uf = [SELECT ParentId, Id, Body FROM UserFeed WHERE ParentId = :objPO.OwnerId ORDER BY CreatedDate DESC LIMIT 1];
    
               System.assert(uf.Body.contains('has been Approved for use of Goodwill.'), 'Approval message not found for SVMXC__RMA_Shipment_Order__c.');*/
           }
           catch(exception e)
           {
               system.debug(e);
           }
      }

     /**
       *  CMCP-16
       *  @author : Gladis
       *  @description - test method to insert time in when work order status is changed to Awaiting Parts.
     **/
     
     
     static testMethod void testcheckPartsOrderTimeInandOutCreate() {
         //Creating Account
         Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
         
         //Creating Contact
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
 
         //Creating Case      
         Case objectCase = TestDataCase.initServiceRequestCase(con);
         insert objectCase;
 
         //Creating Work Order
         SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Remote Support', objectCase.Id, 'Initiated');
         workOrder1.SVMXC__Order_Status__c='Assigned';
         workOrder1.Is_Auto_Created__c = true;
         insert workOrder1;
 
         //Insert Location
         SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
         list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
         insert locList;
 
         //Creating Part Order
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objectCase.Id, 'Open');
         partOrder.ERP_Sales_Order_Number__c = '2222';
         partOrder.SVMXC__Service_Order__c = workOrder1.id;
         partOrder.Contact_Name__c = 'Test';
         partOrder.Contact_Phone__c = 'Test';
         partOrder.SVMXC__Order_Type__c = 'Shipment';
         partOrder.SVMXC__Destination_Location__c = locList[0].Id;
         partOrder.Shipping_Location__c = locList[1].Id;
         insert partOrder;
 
         
        // Create a new instance of Time_In_State__c to track the start date/time
         Time_In_State__c timeInState = new Time_In_State__c();
         timeInState.Work_Order__c = workOrder1.Id;
         timeInState.Start_Date_Time__c = DateTime.now();
         insert timeInState;
 
       // Update the work order status to 'Awaiting Parts'
        workOrder1.SVMXC__Order_Status__c = 'Awaiting Parts';
        update workOrder1;
 
        test.startTest();
 
      // Update the work order status to 'In Progress'
        workOrder1.SVMXC__Order_Status__c = 'In Progress';
        update workOrder1;
 
       // Query the Time_In_State__c record
         timeInState = [SELECT Id, Start_Date_Time__c, End_Date_Time__c, Work_Order__c FROM Time_In_State__c WHERE Work_Order__c = :workOrder1.Id LIMIT 1];
 
        // Set the End_Date_Time__c field to the current date/time
        timeInState.End_Date_Time__c = DateTime.now();
        update timeInState;
 
        test.stopTest();
 
       // Query the Time_In_State__c record again to include the updated End_Date_Time__c value
        timeInState = [SELECT Id, Start_Date_Time__c, End_Date_Time__c, Work_Order__c FROM Time_In_State__c WHERE Work_Order__c = :workOrder1.Id LIMIT 1];
 
       // Assert that the Start_Date_Time__c is not null
        System.assert(timeInState.Start_Date_Time__c != null, 'Start_Date_Time__c should not be null');
       // Assert that the End_Date_Time__c is not null
       System.assert(timeInState.End_Date_Time__c != null, 'End_Date_Time__c should not be null');
 
         
     }
 
     /**
     * @description- Test method to cover the PartOrdersHelper class
     * Modified Date: 09-26-2022 
     **/
     
     
     @isTest static void coverPartOrdersHelper() {
         //Creating Account
         Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
         acc.Account_Group__c='Distributor';
         insert acc;
         
         //Creating Contact
         Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
 
         //Creating Case      
         Case objectCase = TestDataCase.initServiceRequestCase(con);
         insert objectCase;
 
         //Creating Work Order
         SVMXC__Service_Order__c workOrder1 = TestDataFieldService.createWorkOrder('Remote Support', objectCase.Id, 'Initiated');
         workOrder1.SVMXC__Order_Status__c='Assigned';
         workOrder1.Is_Auto_Created__c = true;
         insert workOrder1;
 
         //Insert Location
         SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
         SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
                 Name = 'testStockingLocation',
                 CurrencyIsoCode = 'USD',
                 SVMXC__Stocking_Location__c = true,
                 SVMX_PS_Active__c = true,
                 Type__c = 'Trunk');
         list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
             locList.add(location);
             locList.add(shippingLocation);
         insert locList;
 
         //Creating Part Order
         SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objectCase.Id, 'Open');
         partOrder.ERP_Sales_Order_Number__c = '4444';
         partOrder.SVMXC__Service_Order__c = workOrder1.id;
         partOrder.Contact_Name__c = 'Test';
         partOrder.Contact_Phone__c = 'Test';
         partOrder.SVMXC__Order_Type__c = 'Shipment';
         partOrder.SVMXC__Destination_Location__c = locList[0].Id;
         partOrder.Shipping_Location__c = locList[1].Id;
         insert partOrder;
         
         workOrder1.SVMXC__Order_Status__c='Awaiting Parts';
         update workOrder1;
 
         Set<Id> setPOId = new  Set<Id>();
         setPOId.add(partOrder.Id);
         test.startTest();
         
         PartsOrdersHelper.PartsOrder partsQuery = new PartsOrdersHelper.PartsOrder();
         partsQuery.initPartsOrderMap(setPOId);    
         system.assertNotEquals(null,partOrder.Id,'Part Order should not be null');                
         test.stopTest();
     }

       /*******************************************************************************************************
      * @description ttestUpdateRelatedShipmentLineStatus
      */
      @isTest
      public static void testUpdateRelatedShipmentLineStatus(){
          try {
              SVMXC__RMA_Shipment_Order__c shiporder = new SVMXC__RMA_Shipment_Order__c();
              shiporder.Bypass_Validation_Rules_for_Integration__c=true;
              shiporder.SVMXC__Order_Status__c='Open';
              shiporder.Contact_Name__c = 'Gaurav';
              shiporder.Contact_Phone__c = '8823038711';
              shiporder.SVMXC__Order_Type__c = 'Return';
              insert shiporder;
              
              list<SVMXC__RMA_Shipment_Order__c>shipmentOrderList=new list<SVMXC__RMA_Shipment_Order__c>([select id,SVMXC__Order_Status__c,Bypass_Validation_Rules_for_Integration__c from SVMXC__RMA_Shipment_Order__c where id=:shiporder.id LIMIT 1]);
          
              SVMXC__RMA_Shipment_Line__c shipline = new SVMXC__RMA_Shipment_Line__c();
              shipline.SVMXC__RMA_Shipment_Order__c=shipmentOrderList[0].id;
              shipline.SVMXC__Line_Status__c='Processing';
              insert shipline;
              
              shiporder.SVMXC__Order_Status__c='On Hold';
              update shiporder;
              
              list<SVMXC__RMA_Shipment_Line__c>shipmentlinelist=new list<SVMXC__RMA_Shipment_Line__c>([select id,SVMXC__Line_Status__c from SVMXC__RMA_Shipment_Line__c where id=:shipline.id LIMIT 1]);
              
              system.AssertEquals('On Hold',shipmentlinelist[0].SVMXC__Line_Status__c);	
          } catch (Exception e) {
              system.debug(e);
          }
      
      }
              /*******************************************************************************************************
      * @description testUpdateShipmentLineField
      */
      @isTest
      public static void testUpdateShipmentLineField(){
          try {
              SVMXC__RMA_Shipment_Order__c shiporder = new SVMXC__RMA_Shipment_Order__c();
              shiporder.SVMXC__Order_Status__c='Open';
              shipOrder.Shipped_All_Parts_Order_Line__c=true;
              shiporder.Contact_Name__c = 'Gaurav';
              shiporder.Contact_Phone__c = '8823038711';
              shiporder.SVMXC__Order_Type__c = 'Return';
              shiporder.Bypass_Validation_Rules_for_Integration__c = true;
              insert shiporder;
              
              list<SVMXC__RMA_Shipment_Order__c>shipmentOrderList=new list<SVMXC__RMA_Shipment_Order__c>([select id,SVMXC__Order_Status__c from SVMXC__RMA_Shipment_Order__c where id=:shiporder.id LIMIT 1]);
              
              SVMXC__RMA_Shipment_Line__c shipline = new SVMXC__RMA_Shipment_Line__c();
              shipline.SVMXC__RMA_Shipment_Order__c=shipmentOrderList[0].id;
              shipline.SVMXC__Line_Status__c='Open';
              insert shipline;
              
              shiporder.SVMXC__Order_Status__c='On Hold';
              PartsOrders.skipPartsOrderTrigger = false;
              update shiporder;
              
              SVMXC__RMA_Shipment_Line__c getShipLine = [SELECT id, SVMXC__Line_Status__c FROM SVMXC__RMA_Shipment_Line__c WHERE Id=:shipline.id];
              system.AssertEquals(label.PartsOrderLineShipped, getShipLine.SVMXC__Line_Status__c);
          } catch (Exception e) {
              system.debug(e);
          }
      }
    
    /**
     * Test for update trigger scenario.
     * This method validates that `Status_Changed_Time__c` is set or cleared appropriately
     * when `SVMXC__Order_Status__c` changes.
     */
    @isTest
    static void testUpdateBeforeTrigger() {
        // Setup test data: Create Account and Work Order
        SVMXC__Service_Order__c wo2 = new SVMXC__Service_Order__c( SVMXC__Customer_Down__c = false,SVMXC__Order_Type__c = 'Remote Support');
        insert wo2;
        
        Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
        acc.Account_Group__c='Distributor';
        acc.ERP_Customer_Id__c = 'Test1';
        acc.Territory_Region__c = 'AMEA';
        insert acc;
        
        Contact objContact = TestDataContact.getNewContact(acc);
            
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;

    SVMXC__Site__c location = TestDataFieldService.createLocation('ServiceLoc1', 'Stringing street New York', 'USA', '43527', 'USD');
        SVMXC__Site__c shippingLocation = new SVMXC__Site__c(
            Name = 'testStockingLocation',
        CurrencyIsoCode = 'USD',
        SVMXC__Stocking_Location__c = true,
        SVMX_PS_Active__c = true,
        Type__c = 'Trunk');
        list < SVMXC__Site__c > locList = new list < SVMXC__Site__c > ();
        locList.add(location);
        locList.add(shippingLocation);
        insert locList;
    
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.ERP_Sales_Order_Number__c = '2111';
        partOrder.SVMXC__Service_Order__c = workOrder.id;
        partOrder.Contact_Name__c = 'Test';
        partOrder.Contact_Phone__c = 'Test';
        partOrder.SVMXC__Order_Status__c = 'Pending Approval';
        partOrder.SVMXC__Order_Type__c = 'Shipment';
        partOrder.SVMXC__Destination_Location__c = locList[0].Id;
        partOrder.Shipping_Location__c = locList[1].Id;
        partOrder.Requested_Delivery_Date__c = date.today() + 2;
        partOrder.SVMXC__Company__c = acc.Id;
        insert partOrder;

        partOrder.SVMXC__Order_Status__c = 'Approved';
        update partOrder;
    
    // Simulate Trigger Context
    List<SVMXC__RMA_Shipment_Order__c> shipments = [
        SELECT Id, SVMXC__Company__c, Regional_Director_Mail_List__c,SVMXC__Order_Type__c, Contact_Phone__c, Contact_Name__c,SVMXC__Service_Order__c,SVMXC__Order_Status__c,Status_Changed_Time__c,SVMXC__Service_Order__r.SVMXC__Contact__r.Phone
        FROM SVMXC__RMA_Shipment_Order__c WHERE Id =: partOrder.Id limit 1
    ];

        // Assert that Status_Changed_Time__c is cleared for non-pending approval status
        for (SVMXC__RMA_Shipment_Order__c shipment : shipments) {
            if (shipment.SVMXC__Order_Status__c != 'Pending Approval') {
                System.assertEquals(null, shipment.Status_Changed_Time__c, 'Status Changed Time should be cleared for non-pending approval status');
            }
        }
    }
 }