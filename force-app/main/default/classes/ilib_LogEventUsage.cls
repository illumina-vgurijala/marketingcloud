/**
*    @author Illumina   
*    @date          
*    @description   Ilmn Log Event usage class to determine the publish usage
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*              Pranay                      06-May-2022       CMSI-2 : Feature flag driven architecture
*/

public with sharing class ilib_LogEventUsage {

    // ilib_LogEventUsage.Data res = new ilib_LogEventUsage().query();

    /**
     * @author Illumina
     * @description Data class wrapper to return the publish percent usage
     */
    public class Data {
        public final Integer max;
        public final Integer remaining;

        private final Integer PCT_DECIMAL_PLACES = 2;

        /**
         * @author Illumina
         * @description Constructor for base class
         * @param Integer max, Integer remaining
         */
        public Data(Integer max, Integer remaining)
        {
            this.max = max;
            this.remaining = remaining;
        }

        /**
         * @author Illumina
         * @description Method to return the publish count
         */
        public Integer getPublishCount()
        {
            if (max == null || remaining == null) return -1;

            return max - remaining;
        }

        /**
         * @author Illumina
         * @description Method to return the publish percent used
         */
        public Decimal getPercentUsed()
        {
            // multiply by 100 so that 0.50 results in 50 as in 50%
            return (Decimal.valueOf(getPublishCount()) * 100 / Decimal.valueOf(max)).setScale(PCT_DECIMAL_PLACES);
        }
    }

    /**
     * @author Illumina
     * @description Method to return Data class instance with max and rem publish limit value
     */
    public Data query()
    {
        //CMSI-2 getting platform event usages from org limit
        Integer maxLimit = OrgLimits.getMap().get('HourlyPublishedPlatformEvents').getLimit();
        Integer usedLimit = OrgLimits.getMap().get('HourlyPublishedPlatformEvents').getValue();
        Integer remLimit = maxLimit - usedLimit;
        return new Data(
            maxLimit,
            remLimit
        );
    }

}