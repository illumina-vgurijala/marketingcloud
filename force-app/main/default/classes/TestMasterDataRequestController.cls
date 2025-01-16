/**
*    @author: Pankaj Singla
*    @date:   10-April-2019
*    @description:  TestClass for MasterDataRequestController
*    Modification Log:
*    -----------------------------------------------------------------------------------
*    Developer                 Date              Description
*    Pankaj Singla             10-Apr-2019       Initial Build
*    Akshay Mohan              26-Jun-2019       DCP-26543: Loading changes
*    Enrique Reyes             28-Jun-2024       Ensure sure there is a Contact to be used as target on Email Template
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
public class TestMasterDataRequestController {
    /**
    *  @author Pankaj Singla
    *  @description Test Method for MasterDataRequest File Upload and Email Send Functionality
    *  @param None
    *  @return None
    **/ 
    static testmethod void testFileAttachments(){
        Account objAcc=TestDataMarketing.getAccount('TestAccount');
        objAcc.Territory_Region__c='AMR';
        update objAcc;
        //Create dummy Contact to be used as target on Email Template
        TestDataContact.getNewContact(objAcc);
        Id recordTypeIdChangeRequest = Schema.SObjectType.Master_Data_Request__c.getRecordTypeInfosByName().get('Other Change Request').getRecordTypeId();
        Master_Data_Request__c objMDR=new Master_Data_Request__c();
        objMDR.RecordTypeId=recordTypeIdChangeRequest;
        objMDR.Account_Name__c=objAcc.id;
        objMDR.Comments__c='Test';
        insert objMDR;
        List<Id> lstMDRObjects=new List<Id>();
        lstMDRObjects.add(objMDR.id);
        MasterDataRequestController.sendEmailAlerts(lstMDRObjects);
        
        Blob beforeblob=Blob.valueOf('Unit Test Attachment Body');
        ContentVersion cv = new ContentVersion();
        cv.title = 'test content trigger';      
        cv.PathOnClient ='test';           
        cv.VersionData =beforeblob;          
        insert cv;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=objMDR.id;
        contentlink.ShareType= 'V';
        contentlink.LinkedEntityId = objMDR.Id; 
        contentlink.ContentDocumentId=documents[0].Id;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
        MasterDataRequestController.handlerFileUploadFinish(objMDR.id);
        objMDR.RecordTypeId=Schema.SObjectType.Master_Data_Request__c.getRecordTypeInfosByName().get('Upgrade to Sold To').getRecordTypeId();
        objMDR.Is_Updated_By_System__c=true;
        update objMDR;
         
        
        List<contentDocumentLink> lstContentDoc=MasterDataRequestController.updateContentDocument('',objMDR.id);
        system.assertEquals(1,lstContentDoc.size() );
        MasterDataRequestController.updateContentDocument(documents[0].id, objMDR.id); 
         lstContentDoc=MasterDataRequestController.updateContentDocument('',objMDR.id);
        system.assertEquals(0,lstContentDoc.size() );
         
    }
    /**
    *  @author Pankaj Singla
    *  @description Test Method for MasterDataRequest PageLayout Metadata get functionality
    *  @param None
    *  @return None
    **/ 
    static testmethod void testgetPageLayoutMetaData(){
        String pageLayoutName='Master_Data_Request__c-Upgrade To Distributor Layout';
        MasterDataRequestController.PageLayout objPageLayout=MasterDataRequestController.getPageLayoutMetadata(pageLayoutName);
        system.assert(objPageLayout!=null);
    }

    /**
    *  @author Pankaj Singla
    *  @description Test Method for HTTPCallout- to get assigned page layout name
    *  @param None
    *  @return None
    **/ 
    static testmethod void loadPage(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('StaticResourceMockForMDR');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json;charset=UTF-8');
        // Associate the callout with a mock response
        Test.setMock(HttpCalloutMock.class, mock);
        Id recordTypeIdChangeRequest = Schema.SObjectType.Master_Data_Request__c.getRecordTypeInfosByName().get('Upgrade to Sold To').getRecordTypeId();
        String strJSON=MasterDataRequestController.loadPage(recordTypeIdChangeRequest);
        system.debug('strJSON--'+strJSON);
        Map<String,String> mapLabels = (Map<String,String>)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ' "mapLabels": ', '}')
                                                                                , Map<String,String>.class);
                    
        System.assert(mapLabels.containsKey('UI_Label_MDG_Cancel_Button'),'Cancel button not found');
    }
    
}