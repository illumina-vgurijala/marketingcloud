/**
*    @author 
*    @date   
*    @description TestBundleCustomersStructure
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*            Aman Tyagi                     6th Oct 2022        Codescan fixes
*/
public with sharing class TestBundleCustomersStructure {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // custom data structures
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /**
     *  @author   
     *  @description customer definition class 
     **/
    public class CustomerDefinition {
        public String accountGroup;
        public String currencyCode;
        public String countryCode;
    /**
     *  @author   
     *  @description parameterized constructor of class CustomerDefinition
     *  @param String accountGroup
     *  @return NA 
     **/
        public CustomerDefinition(String accountGroup)
        {
            this.accountGroup = accountGroup;
        }
    /**
     *  @author   
     *  @description parameterized constructor of class CustomerDefinition
     *  @param String accountGroup, String currencyCode, String countryCode
     *  @return NA 
     **/
        public CustomerDefinition(String accountGroup, String currencyCode, String countryCode)
        {
            this.accountGroup = accountGroup;
            this.currencyCode = currencyCode;
            this.countryCode = countryCode;
        }
    }
    /**
     *  @author   
     *  @description SalesAreaDefinition class
     **/
    public class SalesAreaDefinition {
        public String salesOrg;
        public String distChannel;
        public String division;
    /**
     *  @author   
     *  @description parameterized constructor of class SalesAreaDefinition
     *  @param String salesOrg, String distChannel, String division
     *  @return NA 
     **/
        public SalesAreaDefinition(String salesOrg, String distChannel, String division)
        {
            this.salesOrg = salesOrg;
            this.distChannel = distChannel;
            this.division = division;
        }
    }
    /**
     *  @author   
     *  @description ExtraRelationshipDefinition class 
     **/
    public class ExtraRelationshipDefinition {
        public Integer parentCustomer;
        public Integer childCustomer;
        public Set<String> parentSalesAreas;
        public String relationshipType;
        public Boolean isDefault;
    /**
     *  @author   
     *  @description parameterized constructor of class ExtraRelationshipDefinition
     *  @param Integer childCustomer, Integer parentCustomer, Set<String> parentSalesAreas, String relationshipType, Boolean isDefault
     *  @return NA 
     **/
        public ExtraRelationshipDefinition(Integer childCustomer, Integer parentCustomer, Set<String> parentSalesAreas, String relationshipType, Boolean isDefault)
        {
            this.parentCustomer = parentCustomer;
            this.childCustomer = childCustomer;
            this.parentSalesAreas = parentSalesAreas;
            this.relationshipType = relationshipType;
            this.isDefault = isDefault;
        }
    }

}