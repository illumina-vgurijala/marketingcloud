/*
Settings manager/wrapper for ilib_BatchManager
*/
public with sharing class ilib_BatchSettings {

    private static final String CODE_PARAMETER_NAME = 'Batch_Manager_Settings';

    // only used during unit testing
    public static Map<String, String> unitTestSettingsRecord;

    // threshold mins and maxes
    private static final Integer HOLDING_THRESHOLD_MIN = 100;
    private static final Integer HOLDING_THRESHOLD_MAX = 200; // will the holding maximum ever grow?  We will allow up to 200 before a code change is needed
    private static final Integer BUFFER_THRESHOLD_MIN = 0;
    private static final Integer BUFFER_THRESHOLD_MAX = 25;
    private static final Integer SCHEDULER_THRESHOLD_MIN = 1;
    private static final Integer SCHEDULER_THRESHOLD_MAX = 10;

    // ********************************************
    // Configurable values
    // ********************************************
    private static Integer flexQueueHoldingMax {
        private get
        {
            if (flexQueueHoldingMax == null)
            {
                // default
                flexQueueHoldingMax = 100;
                // lazy-load config value
                setConfiguredValues();
            }
            return flexQueueHoldingMax;
        }
        private set;
    }

    private static Integer flexQueueHoldingBuffer {
        private get
        {
            if (flexQueueHoldingBuffer == null)
            {
                // default
                flexQueueHoldingBuffer = 10;
                // lazy-load config value
                setConfiguredValues();
            }
            return flexQueueHoldingBuffer;
        }
        private set;
    }

    private static Integer schedulerDelayInMinutes {
        private get
        {
            if (schedulerDelayInMinutes == null)
            {
                // default
                schedulerDelayInMinutes = 5;
                // lazy-load config value
                setConfiguredValues();
            }
            return schedulerDelayInMinutes;
        }
        private set;
    }

    // ********************************************
    // Public API
    // ********************************************
    /* self-explanitory */
    public static Integer getSchedulerDelayInMinutes()
    {
        return schedulerDelayInMinutes;
    }

    /* self-explanitory */
    public static Integer getFlexQueueCapacity(Boolean buffered)
    {
        Integer res = flexQueueHoldingMax - getFlexQueueHoldingCount();
        if (buffered) res = res - flexQueueHoldingBuffer;

        if (res < 0) return 0;
        return res;
    }

    // ********************************************
    // Everything else is private
    // ********************************************

    // this class never instantiated
    private ilib_BatchSettings() { }

    private static void setConfiguredValues()
    {
        Map<String, String> settingsMap = query();

        // minimum thresholds are zero for unit testing
        Integer minHoldingThreshold = Test.isRunningTest() ? 0 : HOLDING_THRESHOLD_MIN;
        Integer minBufferThreshold = Test.isRunningTest() ? 0 : BUFFER_THRESHOLD_MIN;

        // only accept config values if set withing reasonable thresholds
        flexQueueHoldingMax = valueIfInBounds(settingsMap.get('flexQueueMax'), minHoldingThreshold, HOLDING_THRESHOLD_MAX, flexQueueHoldingMax);
        flexQueueHoldingBuffer = valueIfInBounds(settingsMap.get('flexQueueBuffer'), minBufferThreshold, BUFFER_THRESHOLD_MAX, flexQueueHoldingBuffer);
        schedulerDelayInMinutes = valueIfInBounds(settingsMap.get('schedulerDelayInMinutes'), SCHEDULER_THRESHOLD_MIN, SCHEDULER_THRESHOLD_MAX, schedulerDelayInMinutes);
    }

    @TestVisible
    private static Map<String, String> query()
    {
        // unit tests need to be able to control the config values
        if (Test.isRunningTest() && unitTestSettingsRecord != null)
        {
            return unitTestSettingsRecord;
        }

        Map<String, String> settingsMap = UtilsSettings.getCustomMetadataMap(CODE_PARAMETER_NAME);
        return settingsMap;
    }

    private static Integer valueIfInBounds(String configuredValue, Integer lowerBound, Integer upperBound, Integer otherwiseValue)
    {
        if (configuredValue == null) return otherwiseValue;

        try
        {
            Integer parsedValue = Integer.valueOf(configuredValue);
            if (parsedValue >= lowerBound && parsedValue <= upperBound)
                return parsedValue;
            else
                return otherwiseValue;
        }
        catch (Exception e)
        {
            return otherwiseValue;
        }
    }

    private static Integer getFlexQueueHoldingCount()
    {
        Integer flexHoldingCount = [SELECT count() FROM AsyncApexJob WHERE Status = 'Holding'];
        ilib_LogEvent.message('flexHoldingCount ' + flexHoldingCount);
        return flexHoldingCount;
    }

}