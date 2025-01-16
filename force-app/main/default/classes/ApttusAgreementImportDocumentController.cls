/**
 *    @author Satya Swain
 *    @date   11-March-2020
 *    @description    Controller class to update Agreement field values after offline import as part of DCP-35033
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                   Date                  Description
 *    Satya                   11-March-2020           Initial Version
 *	  Satya 				  24-March-2020			  Added new condition as part of DCP-36446
 *    Joshith K               20-November-2020        DCP-43693 updated condition for agreement update using metadata table
 *    Nesar Mohan             01-April-2022           CodeScan Fix - Code Comments
 *   ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApttusAgreementImportDocumentController
{
    public Apttus__APTS_Agreement__c objAgreement;
    public Id agreementId;
    Public Set<String> approvalStatus = New Set<String>{Label.UI_Label_Approval_Required,Label.UI_Label_Agreement_Approval_Status_Pending_Approval};
    
    /*
    * @author      : Satya Swain
    * @Description : Constructor of the class ApttusAgreementImportDocumentController to fetch the agreement
    */
    
    public ApttusAgreementImportDocumentController()
    {
        agreementId = ApexPages.CurrentPage().getParameters().get('id') == null ? null : ApexPages.CurrentPage().getParameters().get('id').escapeHtml4();
        List<Apttus__APTS_Agreement__c> lstAgreement = new ApttusAgreementSelectors().selectAgreements(new Set<Id>{agreementId});
        if(!lstAgreement.isEmpty())
        {
            objAgreement = lstAgreement.get(0);
        }
    }
    /*
    * @Joshith K
    * Method to update Agreement status and status category 
    */
    public PageReference updateAgreement()
    {
        if(objAgreement == NULL)
            return new PageReference('/'+agreementId);
        
        if(String.isNotBlank(objAgreement.Apttus__Subtype__c)
        &&!approvalStatus.contains(objAgreement.Apttus_Approval__Approval_Status__c)
        &&((String.isNotBlank(objAgreement.Validation_Status__c)&&!(objAgreement.Validation_Status__c.contains(Label.UI_Label_Agreement_Validation_Status_In_Progress)))
        ||String.isBlank(objAgreement.Validation_Status__c)))
        {   
            List<Agreement_Import_Offline_Condition_Table__mdt> lstImportOfflineConditions=new AgreementImportOfflineConditionSelector().getImportOfflineDocumentConditionMapping(objAgreement.RecordType.DeveloperName,objAgreement.Apttus__Subtype__c);
            if(!lstImportOfflineConditions.isEmpty()&&lstImportOfflineConditions[0].Update_Category_Status__c){
                    objAgreement.Apttus__Status_Category__c =  Label.AgreementStatusCategoryInAuthoring;
                    objAgreement.Apttus__Status__c = Label.AgreementStatusAuthorContract;
                    update objAgreement;
                
            }
        }
        Pagereference result = new Pagereference('/'+objAgreement.Id);
        return result;
    }
}