/**
* @date 13-Sep-2021
* @group ContentDocument
* @author: Pooja Shalwadi
* @description: This Test class is used to validate the functionality of trigger handler.
*/
@isTest
public class TestContentVersionsSelector {
    
/**
* @author: Pooja Shalwadi
* @description: This method is used to create the initialTestData
*/ 
    @testSetup
    public static void initializeTestData() {
        List<ContentVersion> contversionLst= new List<ContentVersion>();
        ContentVersion objCV = TestDataFieldService.createDocVersion('TestDoc', 'Pic.txt', 'Test Content', true);
        objCV.Document_Type_fileupload__c='Manual Signed LOA';
        contversionLst.add(objCV);
        insert contversionLst;
        System.assert(contversionLst.size()>0);
    }
    
    /*******************************************************************************************************
    * @author:Pooja Shalwadi
    * @description: This method is used validate the selector class contentversion with mock data
    * @param void
    * @return void
*/
    @isTest
    public static void selectByContentVersionTest(){
        List<ContentVersion> lstContentVersion=[SELECT id,ContentDocumentId,Document_Type_fileupload__c From ContentVersion LIMIT 1];
        Set<Id> setContentVersionId= new Set<id>();
        Set<Id> setContentDocId= new Set<id>();
        List<Id> lstContentDocId= new List<Id>();
        setContentDocId.add(lstContentVersion[0].ContentDocumentId);
        setContentVersionId.add(lstContentVersion[0].Id);
        lstContentDocId.add(lstContentVersion[0].ContentDocumentId);
        
        Test.startTest();
        ContentVersionsSelector contentVersionsSel= new ContentVersionsSelector();
        
        List<ContentVersion>contversionLst1=contentVersionsSel.selectByContentDocumentId(setContentDocId);
        System.assert(contversionLst1.size()>0);
        List<ContentVersion>contversionLst2=contentVersionsSel.selectByContentVersionId(setContentVersionId);
        System.assert(contversionLst2.size()>0);
        List<ContentVersion>contversionLst3=contentVersionsSel.selectByContentDocument(lstContentDocId);
        System.assert(contversionLst3.size()>0);
        List<ContentVersion>contversionLst4=contentVersionsSel.getContentVersionIdsForDocUploadComp(lstContentDocId);
        System.assert(contversionLst4.size()>0);
        List<ContentVersion>contversionLst5=contentVersionsSel.selectByContentDocumentWithoutVersionData(lstContentDocId);
        System.assert(contversionLst5.size()>0);
        List<ContentVersion>contversionLst7=contentVersionsSel.selectByContentDocumentForManualLOA(setContentDocId,'Manual Signed LOA');
        System.assert(contversionLst7.size()>0);
        
        Test.stopTest();
    }
    
}