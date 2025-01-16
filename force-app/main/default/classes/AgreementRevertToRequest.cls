/*
    * @author      : Umesh Mor
    * @date        : 6-03-2020.
    * @description : To revert the agreement to request.(DCP-32419)
    * Parameter    : AgreementId
    * @return      : String 
     Test class for 75%+ Coverage : TestAgreementRevertToRequest
*    Test class for 90%+ Coverage : TestAgreementRevertToRequest
*    ------------------------------------------
*    Developer Name                    Date                    Modified by 
*       Vignesh                      27/4/2020            Made "Is_Agreement_under_Approvals_submission__c" field to false on reverting request.
*    Nishan Shetty                  22-April-2022         CodeScan Fix-Avoid Literals in If condition           
*       Aman Tyagi                   8/4/2022             CodeScan Fixes
*    Nishan Shetty                   18-February-2023     CodeScan Fix - NPath Complexity       
*    ---------------------------------------------------------------------------------                    
**/
public with sharing class AgreementRevertToRequest {

    //START CodeScan Fix [Avoid Literals in If condition]
    private static final String STRING_ERROR = 'Error';
    //END CodeScan Fix
    private static String recordValidationStatus;//CodeScan Fix for Npath Complexity.
    private static String recordValidationLabel;//CodeScan Fix for Npath Complexity.


    /*
    * @author      : Umesh Mor
    * @date        : 6/03/2020.
    * @description : This method revert the agreement to request based on related agreement status.(DCP-32419)
    * Parameter    : AgreementId
    * @return      : String 
    */
    @AuraEnabled
    public static string agreementRevertToRequest(Id agreementId) {
        String revertAgreementApprovalStatus = Label.AgreementApprovalStatusNotSubmitted;
        List<Apttus__APTS_Agreement__c> lstAgreement;
        List<Apttus__APTS_Agreement__c> lstAgreementList =new ApttusAgreementSelectors().selectAgreements(new Set<Id>{agreementId});
        
        if(!lstAgreementList.isEmpty()) {
            set<string> setCategoryStatus = new set<string>();
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_In_Effect); 
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_Category_Amended); 
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_Category_Renewed); 
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_Category_Terminated);  
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_Category_Cancelled); 
            setCategoryStatus.add(Label.UI_Label_Agreement_Status_Category_Expired); 

            Apttus__APTS_Agreement__c objAgreement = lstAgreementList.get(0);//CodeScan Npath Complexity Fix.
			//Below line of code sets approval status 
            if(objAgreement!=null && !string.isBlank(objAgreement.Apttus_Approval__Approval_Status__c) && objAgreement.Apttus_Approval__Approval_Status__c != Label.AgreementApprovalStatusNotSubmitted) {
                revertAgreementApprovalStatus = Label.AgreementApprovalStatusApprovalRequired;
            }
            
			setErrorValidationStatus(objAgreement,setCategoryStatus);//CodeScan Npath Complexity Fix.

            if(recordValidationStatus != STRING_ERROR) {
                Apttus__APTS_Agreement__c recNew;
                List<Apttus__APTS_Related_Agreement__c> relatedAgreement = new List<Apttus__APTS_Related_Agreement__c>();
                relatedAgreement=new ApttusRelatedAgreementSelectors().getRelatedAgreementToAndFrom(agreementId);
                if(relatedAgreement.size() == 0) {
                    lstAgreement = new List<Apttus__APTS_Agreement__c>();
                    recNew = new Apttus__APTS_Agreement__c(id=agreementId);
                    recNew.Apttus__Status__c = Label.Agreement_Status;
                    recNew.Apttus__Status_Category__c = Label.Agreement_Status_Category;
                    recNew.Apttus_Approval__Approval_Status__c = revertAgreementApprovalStatus;
                    recNew.Validation_Status__c = '';
                    recordValidationStatus = Label.Success;
                    recordValidationLabel  = Label.RecordUpdatedSuccessfully;
                    lstAgreement.add(recNew);
                } else { 
                    lstAgreement = new List<Apttus__APTS_Agreement__c>();
                    for(Apttus__APTS_Related_Agreement__c rec : relatedAgreement) {
                        if(rec.Apttus__APTS_Contract_From__c !=NULL &&  rec.Apttus__APTS_Contract_From__c == AgreementId  &&  rec.Apttus__APTS_Contract_To__c != NULL && rec.Apttus__APTS_Contract_To__r.Apttus__Status__c == 'Being Amended') {
                            recNew = new Apttus__APTS_Agreement__c(id=agreementId);
                            recNew.Apttus__Status_Category__c = Label.Agreement_Status_Category;
                            recNew.Apttus__Status__c = Label.Apttus_Status_In_Amendment;
                            recNew.Apttus_Approval__Approval_Status__c =revertAgreementApprovalStatus; 
                            recNew.Validation_Status__c = '';
                            recordValidationStatus = Label.Success;
                            recordValidationLabel  = Label.RecordUpdatedSuccessfully;
                            lstAgreement.add(recNew);
                            break;
                        } else if(rec.Apttus__APTS_Contract_From__c != NULL &&  rec.Apttus__APTS_Contract_From__c == AgreementId  &&  rec.Apttus__APTS_Contract_To__c != NULL && rec.Apttus__APTS_Contract_To__r.Apttus__Status__c == 'Being Renewed') {
                            recNew = new Apttus__APTS_Agreement__c(id=agreementId);
                            recNew.Apttus__Status__c = Label.Apttus_Status_In_Renewal;
                            recNew.Apttus__Status_Category__c = Label.Agreement_Status_Category;
                            recNew.Apttus_Approval__Approval_Status__c = revertAgreementApprovalStatus; 
                            recNew.Validation_Status__c = '';
                            recordValidationStatus = Label.Success;
                            recordValidationLabel  = Label.RecordUpdatedSuccessfully;
                            lstAgreement.add(recNew);
                            break;
                        } else if(rec.Apttus__APTS_Contract_To__c != NULL  && rec.Apttus__APTS_Contract_To__c == AgreementId && rec.Apttus__APTS_Contract_From__c != NULL &&  rec.Apttus__APTS_Contract_From__r.Apttus__Status__c == 'Being Amended') {
                            recNew = new Apttus__APTS_Agreement__c(id=agreementId);
                            recNew.Apttus__Status__c = Label.Apttus_Status_In_Amendment;
                            recNew.Apttus__Status_Category__c = Label.Agreement_Status_Category;
                            recNew.Apttus_Approval__Approval_Status__c = revertAgreementApprovalStatus ;
                            recNew.Validation_Status__c = '';
                            recordValidationStatus = Label.Success;
                            recordValidationLabel  = Label.RecordUpdatedSuccessfully;
                            lstAgreement.add(recNew);
                        } else if(rec.Apttus__APTS_Contract_To__c != NULL  && rec.Apttus__APTS_Contract_To__c == AgreementId  && rec.Apttus__APTS_Contract_From__c != NULL &&  rec.Apttus__APTS_Contract_From__r.Apttus__Status__c == 'Being Renewed') {
                            recNew = new Apttus__APTS_Agreement__c(id=agreementId);
                            recNew.Apttus__Status__c = Label.Apttus_Status_In_Renewal;
                            recNew.Apttus__Status_Category__c = Label.Agreement_Status_Category;
                            recNew.Apttus_Approval__Approval_Status__c = revertAgreementApprovalStatus;
                            recNew.Validation_Status__c = '';
                            recordValidationStatus = Label.Success;
                            recordValidationLabel  = Label.RecordUpdatedSuccessfully;
                            lstAgreement.add(recNew);
                        } else {
                            recordValidationStatus = STRING_ERROR;
                            recordValidationLabel  = Label.UI_Error_Message_Revert_to_Request;  
                        }
                    }
                }
            }
            
            updateAgreement(lstAgreement);//CodeScan Fix for Npath Complexity.
            
        }
        return '{'+' "recordValidationStatus": '+JSON.serialize(recordValidationStatus)+','+' "recordValidationLabel": '+JSON.serialize(recordValidationLabel)+'}';
    }


    /*
    * @author      : Nishan Shetty
    * @date        : 18/02/2023.
    * @description : This method is created to reduce the npath complexity of agreementRevertToRequest method.
                     It contain logic to update the agreement
    * Parameter    :lstAgreement - List of Agreements.
                    recordValidationStatus - String Validation Status.
                    recordValidationLabel - String Validation Label.
    */
    public static void updateAgreement(List<Apttus__APTS_Agreement__c> lstAgreement) {
        if(lstAgreement != null && !lstAgreement.isEmpty() && recordValidationStatus != null && recordValidationStatus != STRING_ERROR) {
            try {
                //DCP-37225. Updating "Is_Agreement_under_Approvals_submission__c" to false on reverting Approvals. 
                lstAgreement[0].Is_Agreement_under_Approvals_submission__c = false;
                update lstAgreement;
                recordValidationStatus = Label.Success;
                recordValidationLabel  = Label.RecordUpdatedSuccessfully;
            } catch(Exception e) {
                System.debug('System Got Updated----'+e);
            }
        }
    }

    /*
    * @author      : Nishan Shetty
    * @date        : 18/02/2023.
    * @description : This method is created to reduce the npath complexity of agreementRevertToRequest method.
                     It contain logic to set validation error status.
    * Parameter    :objAgreement - Instance of Agreement Record.
                    setCategoryStatus - Set of Category Status.
    */
    public static void setErrorValidationStatus(Apttus__APTS_Agreement__c objAgreement,Set<String> setCategoryStatus) {
        //Validating record to revert
			if(objAgreement!=null && (objAgreement.Apttus_Approval__Approval_Status__c == Label.UI_Label_Agreement_Approval_Status_Pending_Approval
            ||(objAgreement.Validation_Status__c != null  && objAgreement.Validation_Status__c.toLowerCase().contains(Label.UI_Label_Agreement_Validation_Status_In_Progress))
            ||setCategoryStatus.contains(objAgreement.Apttus__Status_Category__c))) {
                recordValidationStatus = STRING_ERROR;
                recordValidationLabel  =  Label.UI_Error_Message_Revert_to_Request; 
			}
    }
}