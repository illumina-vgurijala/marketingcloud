/**
* 
*
@description TestBundleCustomersValues (CodeScan Fix)
*-----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*-----------------------------------------------------------------------------------------------------------------------------------
*         Adyasha Satapathy                28-Nov-2022           POL-54: Update region references to AMEA and EUR
*         Jitesh Lakhwani                  21-Feb-2023           Codescan - Avoid unused Variable
*/

public with sharing class TestBundleCustomersValues {

    public static final String SALES_ORG_US01 = 'US01';
    public static final String SALES_ORG_BR01 = 'BR01';
    public static final String SALES_ORG_GB01 = 'GB01';
    public static final String SALES_ORG_FR01 = 'FR01';
    public static final String SALES_ORG_NL01 = 'NL01';
    public static final String SALES_ORG_JP01 = 'JP01';
    public static final String SALES_ORG_SG01 = 'SG01';
    public static final String SALES_ORG_USD = 'USD';
    /**
    @description Blank Constructor
    */
    public TestBundleCustomersValues() { }

    public static List<String> REGION_VALUES = new List<String> {Territories2.REGION_AMR, Territories2.REGION_EUR, Territories2.REGION_AMEA, Territories2.REGION_CHINA};//POL-54

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Setting parameters for new values
    //
    // for each customer (account and/or CMD) and ASA generated
    // we need to update our assumptions based on the definitions provided
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private final Map<String, String> SALES_ORG_TO_REGION = new Map<String, String> {
        SALES_ORG_US01 => Territories2.REGION_AMR,
        SALES_ORG_BR01 => Territories2.REGION_AMR,
        SALES_ORG_GB01 => Territories2.REGION_EUR, //POL-54
        SALES_ORG_FR01 => Territories2.REGION_EUR, //POL-54
        SALES_ORG_NL01 => Territories2.REGION_EUR, //POL-54
        SALES_ORG_JP01 => Territories2.REGION_AMEA, //POL-54
        SALES_ORG_SG01 => Territories2.REGION_CHINA
    };

    
/**
* 
*
* @desc specifyCustomerDef  (CodeScan Fix)
*/
    public void specifyCustomerDef(TestBundleCustomersStructure.CustomerDefinition customerDefinition, List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs)
    {
        // set the region which drives country/currency
        // NOTE: no support for trans-region account generation at present
        specifySalesAreaDef(salesAreaDefs.get(0));

        // generate these two if not provided
        if (String.isBlank(customerDefinition.countryCode))
        {
            customerDefinition.countryCode = getRandomCountry();
        }
        if (String.isBlank(customerDefinition.currencyCode))
        {
            customerDefinition.currencyCode = getRandomCurrency();
        }

        // set the provided/generated values
        randomCountry = customerDefinition.countryCode;
        randomCurrency = customerDefinition.currencyCode;

        // state to be generated based on new country value
        randomState = null;
    }

/**
* 
*
* @desc specifySalesAreaDef  (CodeScan Fix)
*/

    public void specifySalesAreaDef(TestBundleCustomersStructure.SalesAreaDefinition salesAreaDef)
    {
        // set the region associated with the provided sales org
        customerRegion = SALES_ORG_TO_REGION.get(salesAreaDef.salesOrg);

        // don't need to clear country/currency
        // specifyCustomerDef() will be called before those values are queried

        // clear price list type value if no longer valid
        if (!SALES_ORG_TO_PRICE_LIST_TYPES.get(salesAreaDef.salesOrg).contains(randomPriceListType))
        {
            randomPriceListType = null;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Sales Area values
    //
    // If sales areas are not provided, this is the logic to pick a region and sales area
    //
    // If sales area(s) were provided, this logic will not be used
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private final Map<String, List<String>> REGION_TO_SALES_ORGS = new Map<String, List<String>> {
        Territories2.REGION_AMR => new List<String> { SALES_ORG_US01, SALES_ORG_BR01 },
        Territories2.REGION_EUR => new List<String> { SALES_ORG_GB01, SALES_ORG_FR01, SALES_ORG_NL01 },//POL-54
        Territories2.REGION_AMEA => new List<String> { SALES_ORG_JP01 }, //POL-54
        Territories2.REGION_CHINA => new List<String> { SALES_ORG_SG01 }
    };

    private String randomSalesOrg;

/**
* 
*
* @desc getRandomSalesOrg  (CodeScan Fix)
*/
    public String getRandomSalesOrg()
    {
        if (randomSalesOrg == null)
        {
            randomSalesOrg = getRandomStringFromList(REGION_TO_SALES_ORGS.get(getRandomRegion()));
        }
        return randomSalesOrg;
    }

    private String customerRegion;

/**
* 
*
* @desc getRandomRegion  (CodeScan Fix)
*/
    public String getRandomRegion()
    {
        if (customerRegion == null)
            customerRegion = getRandomStringFromList(REGION_VALUES);
        return customerRegion;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Geography values
    //
    // The driver is Sales Areas, they will be provided by the client or generated randomly on construction
    // by now we have the sales area and region values
    //
    // controlled by sales org are the price list type value and price list name
    // controlled by region are country and currency values
    // controlled by country is state value
    // Customer Sub Type is dependent on Customer Type
    //
    // Incoterm and Payment Term are random for now
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private final Map<String, List<String>> SALES_ORG_TO_PRICE_LIST_TYPES = new Map<String, List<String>> {
        SALES_ORG_US01 => new List<String> { '01' },
        SALES_ORG_BR01 => new List<String> { '10' },
        SALES_ORG_GB01 => new List<String> { '01,', '04' },
        SALES_ORG_FR01 => new List<String> { '01', '04' },
        SALES_ORG_NL01 => new List<String> { '01', '02', '04' },
        SALES_ORG_JP01 => new List<String> { '01', '05' },
        SALES_ORG_SG01 => new List<String> { '01', '05' }
    };

    private final Map<String, String> PRICE_LIST_TYPE_TO_PRICE_LIST_PREFIX = new Map<String, String> {
        '01' => '01-AMR-',
        '02' => '02-ANZ-',
        '03' => '03-CN-',
        '04' => '04-EUR-',
        '05' => '05-JPY-',
        '06' => '06-SGD-',
        '07' => '07-CAD-',
        '08' => '08-KRW-',
        '09' => '09-HK-',
        '10' => '10-BRL-',
        '11' => '11-CNY-'
    };

    private final Map<String, List<String>> REGION_TO_CURRENCIES = new Map<String, List<String>> {
        Territories2.REGION_AMR => new List<String> { SALES_ORG_USD, 'BRL' },
        Territories2.REGION_EUR => new List<String> { SALES_ORG_USD, 'EUR', 'GBP' },//POL-54
        Territories2.REGION_AMEA => new List<String> { SALES_ORG_USD, 'JPY', 'SGD' },//POL-54
        Territories2.REGION_CHINA => new List<String> { SALES_ORG_USD, 'CNY', 'HKD' }
    };

    private final Map<String, List<String>> REGION_TO_COUNTRIES = new Map<String, List<String>> {
        Territories2.REGION_AMR => new List<String> { 'US', 'AR', 'BR', 'CO' },
        Territories2.REGION_EUR => new List<String> { 'GB', 'FR', 'CH', 'AT' }, //POL-54
        Territories2.REGION_AMEA => new List<String> { 'JP', 'KR' }, //POL-54
        Territories2.REGION_CHINA => new List<String> { 'CN' }
    };

    private final Map<String, String> COUNTRY_CODE_TO_DESCRIPTION = new Map<String, String> {
        'US' => 'USA',
        'AR' => 'Argentina',
        'BR' => 'Brazil',
        'CO' => 'Columbia',
        'GB' => 'United Kingdom',
        'FR' => 'France',
        'CH' => 'Switzerland',
        'AT' => 'Austria',
        'JP' => 'Japan',
        'KR' => 'Korea',
        'CN' => 'China'
    };

    private final Map<String, List<String>> COUNTRY_TO_STATES = new Map<String, List<String>> {
        'US' => new List<String> { 'OH', 'IN', 'AZ', 'AK' },
        'FR' => new List<String> { '69', '75', '86' },
        'JP' => new List<String> { '07', '13', '47' },
        'CN' => new List<String> { '150', '160', '230', '010' }
    };

    private final Map<String, String> STATE_CODE_TO_DESCRIPTION = new Map<String, String> {
        'OH' => 'Ohio',
        'IN' => 'Indiana',
        'AZ' => 'Arizona',
        'AK' => 'Arkansas',
        '69' => 'Rhone',
        '75' => 'Paris',
        '86' => 'Vienne',
        '07' => 'Fukushima',
        '13' => 'Tokyo',
        '47' => 'Okinawa',
        '150' => 'Fujian',
        '160' => 'Hunan',
        '230' => 'Sichuan',
        '010' => 'Beijing'
    };

    private String randomCountry;

/**
* 
*
* @desc getRandomCountry  (CodeScan Fix)
*/
    public String getRandomCountry()
    {
        if (randomCountry == null)
        {
            randomCountry = getRandomStringFromList(REGION_TO_COUNTRIES.get(getRandomRegion()));
        }
        return randomCountry;
    }

/**
* 
*
* @desc getRandomCountryDesc  (CodeScan Fix)
*/
    
    public String getRandomCountryDesc()
    {
        return COUNTRY_CODE_TO_DESCRIPTION.get(getRandomCountry());
    }

    private String randomState;

/**
* 
*
* @desc getRandomState  (CodeScan Fix)
*/
    public String getRandomState()
    {
        if (randomState == null)
        {
            if (COUNTRY_TO_STATES.containsKey(getRandomCountry()))
                randomState = getRandomStringFromList(COUNTRY_TO_STATES.get(getRandomCountry()));
            else
                randomState = '';
        }
        return randomState;
    }

/**
* 
*
* @desc getRandomStateDesc  (CodeScan Fix)
*/
    public String getRandomStateDesc()
    {
        return STATE_CODE_TO_DESCRIPTION.get(getRandomState());
    }

    private String randomCurrency;

/**
* 
*
* @desc getRandomCurrency  (CodeScan Fix)
*/
    public String getRandomCurrency()
    {
        if (randomCurrency == null)
        {
            randomCurrency = getRandomStringFromList(REGION_TO_CURRENCIES.get(getRandomRegion()));
        }
        return randomCurrency;
    }

    final List<String> INCOTERM_VALUES = new List<String> {'DAP: Delivered At Place', 'DAT: Delivery At Terminal', 'DES: Delivered Ex Ship'};
    final List<String> PAYMENT_TERM_VALUES = new List<String> {'NT30', 'NT45'};

    private String randomPriceListType;

/**
* 
*
* @desc getRandomPriceListType  (CodeScan Fix)
*/

    public String getRandomPriceListType(String salesOrg)
    {
        if (randomPriceListType == null)
        {
            randomPriceListType = getRandomStringFromList(SALES_ORG_TO_PRICE_LIST_TYPES.get(salesOrg));
        }
        return randomPriceListType;
    }

/**
* 
*
* @desc getPriceListPrefix  (CodeScan Fix)
*/

    public String getPriceListPrefix(String plType)
    {
        return PRICE_LIST_TYPE_TO_PRICE_LIST_PREFIX.get(plType);
    }

    private String randomIncoterm;

/**
* 
*
* @desc getRandomIncoterm  (CodeScan Fix)
*/

    public String getRandomIncoterm()
    {
        if (randomIncoterm == null)
            randomIncoterm = getRandomStringFromList(INCOTERM_VALUES);
        return randomIncoterm;
    }

    private String randomPaymentTerm;

/**
* 
*
* @desc getRandomPaymentTerm  (CodeScan Fix)
*/

    public String getRandomPaymentTerm()
    {
        if (randomPaymentTerm == null)
            randomPaymentTerm = getRandomStringFromList(PAYMENT_TERM_VALUES);
        return randomPaymentTerm;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Customer Type values
    //
    // Market Segment, Clinical Type, Customer Type and Tier have no dependencies
    // Customer Sub Type is dependent on Customer Type
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private final List<String> CLINICAL_TYPE_VALUES = new List<String> { 'Clinical', 'Non Clinical' };
    // NOTE: can't insert the value 'Multiple' unless we bypass the validation
    private final List<String> MARKET_SEGMENT_VALUES = new List<String> { 'Agrigenomics', 'Cancer Research', 'Genetic Disease Research', 'Reproductive Health' };
    private final List<String> CUSTOMER_TYPE_VALUES = new List<String> { 'Academic', 'Commercial', 'Government', 'Healthcare' };
    private final List<String> TIER_VALUES = new List<String> { 'Tier 1', 'Tier 2', 'Tier 3' };

    private final Map<String, List<String>> TYPE_TO_SUBTYPES = new Map<String, List<String>> {
        'Academic' => new List<String> { 'Genome Center', 'Research Institute' },
        'Commercial' => new List<String> { 'Applied Technology Company', 'Biopharma' },
        'Government' => new List<String> { 'Department Lab', 'Genome Center' },
        'Healthcare' => new List<String> { 'Health System', 'Hospital' }
    };

    private String randomClinicalType;

/**
* 
*
* @desc getRandomClinicalType  (CodeScan Fix)
*/
    public String getRandomClinicalType()
    {
        if (randomClinicalType == null)
            randomClinicalType = getRandomStringFromList(CLINICAL_TYPE_VALUES);
        return randomClinicalType;
    }

    private String randomMarketSegment;

/**
* 
*
* @desc getRandomMarketSegment  (CodeScan Fix)
*/
    public String getRandomMarketSegment()
    {
        if (randomMarketSegment == null)
            randomMarketSegment = getRandomStringFromList(MARKET_SEGMENT_VALUES);
        return randomMarketSegment;
    }

    private String randomCustomerType;

/**
* 
*
* @desc getRandomCustomerType  (CodeScan Fix)
*/
    public String getRandomCustomerType()
    {
        if (randomCustomerType == null)
            randomCustomerType = getRandomStringFromList(CUSTOMER_TYPE_VALUES);
        return randomCustomerType;
    }

    private String randomTier;

/**
* 
*
* @desc getRandomTier  (CodeScan Fix)
*/
    public String getRandomTier()
    {
        if (randomTier == null)
            randomTier = getRandomStringFromList(TIER_VALUES);
        return randomTier;
    }

    private String randomCustomerSubType;

/**
* 
*
* @desc getRandomCustomerSubtype  (CodeScan Fix)
*/

    public String getRandomCustomerSubType()
    {
        if (randomCustomerSubType == null)
        {
            randomCustomerSubType = getRandomStringFromList(TYPE_TO_SUBTYPES.get(getRandomCustomerType()));
        }
        return randomCustomerSubType;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utility methods
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
* 
*
* @desc getRandomStringfromList  (CodeScan Fix)
*/
    
    public String getRandomStringFromList(List<String> values)
    {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), values.size());
        return values.get(idx);
    }

}