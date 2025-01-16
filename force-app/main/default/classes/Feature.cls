/**
 * @author https://github.com/wilkins88/Apex-Feature-Flagging
 * @description Feature class for managing feature flagging within Apex
 * Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date(YY-MM-DD)                  Description
 *    Gerardo Garcia                2023-10-10                      Add TAPS_CCT static final String for easy use of Feature.isOn(Feature.TAPS_CCT)
 *   ---------------------------------------------------------------------------------------------------------------------------
 */
public class Feature {

    public static final String TAPS_CCT = 'TAPS_CompetitiveComplementaryTech';

    @TestVisible
    private static final String ERROR_CANNOT_MOCK_OUTSIDE_TEST = 'Feature flags cannot be mocked outside of a test context.';

    @TestVisible
    private static Map<String, Boolean> features {
        get
        {
            if (features == null)
                features = new Map<String, Boolean>();

            return features;
        }
        private set;
    }

    /**
     * Returns whether or not the feature is activated
     * @param  featureName The name of the feature to check for
     * @return             True if the features is on, false if the feature is off or isn't configured
     */ 
    public static Boolean isOn(String featureName)
    {
        if (!features.containsKey(featureName))
            loadFeatureSetting(featureName);

        return features.get(featureName);
    }

    /**
     * Allows mocking a feature only in a test context. This is useful for decoupling your code from configuration,
     * which can be problematic when ci/cd is introduced
     * @param  featureName The name of the feature to set
     * @param  isOn        Marking the feature as on or off
     */ 
    public static void setMockFeatureFlag(String featureName, Boolean isOn)
    {
        if (!System.Test.isRunningTest()) throw new FeatureFlagException(ERROR_CANNOT_MOCK_OUTSIDE_TEST);
        features.put(featureName, isOn);
    }

    /**
     * Helper for loading the feature flag setting from custom metadata
     * @param  featureName the name of the feature to load
     */
    @TestVisible
    private static void loadFeatureSetting(String featureName)
    {
        Feature_Flag__mdt featureFlag = Feature_Flag__mdt.getInstance(featureName);
        if (featureFlag == null)
            features.put(featureName, false);
        else
            features.put(featureName, featureFlag.IsOn__c);
    }

    /**
     * @author Himanshu
     * @description Exception representing a developer coding error, not intended for end user eyes
    **/
    public class FeatureFlagException extends Exception {}

}