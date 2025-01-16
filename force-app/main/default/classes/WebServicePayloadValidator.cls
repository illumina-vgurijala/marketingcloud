/**
*    @author Gerardo Garcia
*    @description  : Interface that contains methods for validation of payload
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    Gerardo Garcia             10-29-2024             Initial Version
*    ------------------------------------------------------------------------------------ 
**/
public interface WebServicePayloadValidator {

   // validates json schema. Thorows exception 
   void validateSchema(String strJsonData);
}