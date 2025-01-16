/**
*    @author Nikil
*    @date   15/03/2020
*    @description    Class to performs action after inserting ImportFullySignedDocument.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------
*      Developer                      Date                Description
*       Nikhil                      15/03/2020            Initial Version
*       Aman Tyagi                  31 March 2022         Codescan fixes
*    --------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class APTS_ImportFullySignedDocumentController {

  private Apttus__APTS_Agreement__c agreement;

  /*
  * @Author: Nikhil
  * @Description : parameterized constructor of class APTS_ImportFullySignedDocumentController
  * @param :ApexPages.StandardController stdController
  */
  public APTS_ImportFullySignedDocumentController(ApexPages.StandardController stdController) { 
    
    this.agreement = (Apttus__APTS_Agreement__c)stdController.getRecord();
    
  }

  /*
  author: Nikhil:
  returntype: Pagereference
  description: To Update Agreement after Impoting fully signed document. 
   */
  public PageReference finalize(){
    
    agreement.Apttus__Status_Category__c = Label.InSignatures;
    agreement.Apttus__Status__c = Label.AgreementStatusFullySigned;
    
    update agreement;
    
    PageReference result = new ApexPages.StandardController(agreement).view();
    
    return result;
    
  }


}