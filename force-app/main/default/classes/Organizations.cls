/**
*    @author Satya Swain
*    @date   2020-01-28
*    @description  Class to describe Organization's attributes
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Todd Newman                    2020-01-29         Initial Version as part of PRB0043346
*            Nesar Mohan                    2022-04-01         Codescan Fix
*/
public with sharing class Organizations extends ilib_SObjectDomain {

    public static final Id PRODUCTION_ID = '00D1N000002Dojm';
    /*
    *  @Author      : Satya Swain
    *  @Description : Constructor to pass the parameter value to parent constructor
    *  @Param       : List<Organization>
    */
    public Organizations(List<Organization> sObjectList)
    {
        super(sObjectList);
    }
    /*
    *  @Author      : Satya Swain
    *  @Description : Constructor class to implement the method body for construct method
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /*
        *  @Author      : Satya Swain
        *  @Description : construct method to return a new instantiation of type Organizations
        *  @Param       : List<SObject>
        *  @Return      : ilib_SObjectDomain
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Organizations(sObjectList);
        }
    }

    /*
    *  @Author      : Satya Swain
    *  @Description : Method to check if environment is Production ORG or not
    *  @Param       : None
    *  @Return      : Boolean
    */
    public static Boolean isProduction()
    {
        return isProductionUsingQuery();
    }

    /*
    *  @Author      : Satya Swain
    *  @Description : Method to check if the environment is a production using defined environment id as a 
    *  constant PRODUCTION_ID
    *  @Param       : None
    *  @Return      : Boolean
    */
    public static Boolean isProductionUsingConstant()
    {
        return (UserInfo.getOrganizationId() == PRODUCTION_ID);
    }

    /*
    *  @Author      : Satya Swain
    *  @Description : Method to check of environement is Production ORG or not
    *  @Param       : None
    *  @Return      : Boolean
    */
    public static Boolean isProductionUsingQuery()
    {
        // Method to check of environement is Production ORG or not
        Organization org = [SELECT IsSandbox FROM Organization WHERE Id = :UserInfo.getOrganizationId()];
        return (org.IsSandbox == false);
    }

}