/***************************************************************************************************************************************
* NAME   : QuoteCreationAPIPlatformEvents 
* DESCRIPTION  :
*                    
* @AUTHOR : Arquimidez Mora
* @DATE   : 29-10-2024  
* Modification Log:
*  ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*          Arquimidez Mora               29 Oct 2024           Initial version
*  ------------------------------------------------------------------------------------     
*/
public with sharing class QuoteCreationAPIPlatformEvents extends ilib_SObjectDomain {
    /**
    * @description Parameterized Constructor called
    * @params List<QuoteCreationAPIPlatformEvents> sObjectList
    * @return void
    **/
    public QuoteCreationAPIPlatformEvents(List<Quote_Creation_API__e> sObjectList){
        super(sObjectList);
    }
    /**
     * Boilerplate which is required for base class instantiation logic
     */
    public class Constructor implements ilib_SObjectDomain.IConstructable {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList){
            return new QuoteCreationAPIPlatformEvents(sObjectList);
        }
    }

    /**
    * @description Overriding the onAfterInsert base class method
    * @params NA
    * @return void
    **/ 
    public override void onAfterInsert(){
        QuoteCreationAPIPESubscriberService.requestHandler( (List<Quote_Creation_API__e>) records );
    }
}