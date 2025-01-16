/*@ author       : KD
* @ date         : 16-Feb-2021
* @ Description  : Create Knowledge Article
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                  Date                       Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* 
*/
public with sharing class TestDataKnowledgeArticle {
    public static Id idReferenceMaterial = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('Reference_Material').getRecordTypeId();
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates KA
    *  @PARAM :  
    *  @RETURN:  String Knowledge Article id
    */
    public static Knowledge__kav getKnowledgeArticle(String strTitle,String strPrimaryWorkFlow,String strSecondaryWorkflow){
        return new Knowledge__kav(Title=strTitle,
                                summary=strTitle+String.valueof(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS')),
                                urlname=  getRandomString(),
                                Primary_Workflow__c = strPrimaryWorkFlow,
                                Secondary_Workflow__c=strSecondaryWorkflow,
                                Article_Body__c='testKD',
                                Article_Version_Author__c = userinfo.getuserid(),
                                recordTypeId =idReferenceMaterial);
    }
     /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates KA URL
    *  @PARAM :  
    *  @RETURN:  String URL
    */
    static String getRandomString() {
        String strHashString = '1000' + String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob bbHash = Crypto.generateDigest('MD5', Blob.valueOf(strHashString));
        String strHexDigest = EncodingUtil.convertToHex(bbHash);
        return strHexDigest;
    }
}