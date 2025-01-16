/**
 * @File Name          : WorkOrderServiceMaxWebserviceTest.cls
 * @Description        : Test class for WorkOrderServiceMaxWebserviceController.
 * @Author             : Vaibhav Parashar
 * @Group              : 
 * @Last Modified By   : 
 * @Last Modified On   : 
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    6/26/2019,       1:56:23 PM   Vaibhav     Initial Version
 * 2.0    02/21/2023                    Rohan       DCP-59333 AutoPopulate To Location for Shipment PO SFM
 **/
@isTest 
public class WorkOrderServiceMaxWebserviceTest {

    /**
     * @description Testing by passing null request from SFM.
     * @author Vaibhav Parashar | 7/03/2019
     * @param none
     * @return void
     */
    static testMethod void testOnSFMClick() {
        
        Account acc = TestDataAccount.getCustomerAccount();
        insert acc;
        System.assert(acc.Id != null, 'Account id is null');

        //insert contact
        Contact con = TestDataPerson.getNewContact(acc.Id);
        System.assert(con.id != null, 'Contact Insertion failed');
        
        //insert case        
        Case cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
        System.assert(acc.Id != null, 'Case id is null');

        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Initiated');
        workOrder.Record_Created_from_SFM__c = true;
        insert workOrder;
        System.assert(workOrder.Id != null,'workorder id is null');

        User u = TestDataFieldService.createUser('Field Service',false);
        insert u;
        System.assert(u.Id != null, 'User id is null');

        Test.startTest();
        System.runAs(u) {
            //pass the SFM_TargetRecord request to the webservice method.
            SVMXC.SFM_WrapperDef.SFM_TargetRecord targetRecord = new SVMXC.SFM_WrapperDef.SFM_TargetRecord();
            System.assert(targetRecord!=null,'targetRecord is null'); 
            
            // SFM Header Record and associate to the SFM request
            SVMXC.SFM_WrapperDef.SFM_TargetRecordObject header = new SVMXC.SFM_WrapperDef.SFM_TargetRecordObject();
            header.objName = 'SVMXC__RMA_Shipment_Order__c';

            // SFM Records and associate to the SFM Header Record
            List<SVMXC.SFM_WrapperDef.SFM_StringMap> recordsAsKeyValue = new List<SVMXC.SFM_WrapperDef.SFM_StringMap>();
            SVMXC.SFM_WrapperDef.SFM_Record record = new SVMXC.SFM_WrapperDef.SFM_Record();

            //SFM Record for the SFM Records in Header
            recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('SVMXC__Order_Type__c', 'Shipment'));
            recordsAsKeyValue.add(new SVMXC.SFM_WrapperDef.SFM_StringMap('SVMXC__Service_Order__c', workOrder.Id));
            record.setTargetRecordAsKeyValue(recordsAsKeyValue);
            header.setRecords(new List<SVMXC.SFM_WrapperDef.SFM_Record> {record});
            targetRecord.headerRecord = header;
            
            //pass the null request to the apex method. 
            SVMXC.SFM_WrapperDef.SFM_PageData pageData = WorkOrderServiceMaxWebservice.updateWorkOrder(targetRecord);
            System.assertEquals(null,pageData,'pageData is null');
        }
        Test.stopTest();
        
    }
    

}