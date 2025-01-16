window.optimizerInfo = (function() {

    var data = {
        "OptimizerPlusParentHome":{
          HighImpact:{
            title: "High-Impact Feature Summary",
            icon: "Summary",
            paragraph: "Issues that require immediate attention.",
            empty: "Great work! You don’t have any high-impact features for review.",
          },
          Progress:{
            title: "Optimization Progress",
            icon: "Success",
            paragraph: "Since the last time Salesforce Optimizer ran, the following areas of your org are now ready.",
            empty: "Nothing yet. Check Results to see which features you can improve. Consider focusing on high-impact or low-effort features to get started.",
          },
          OptimizerPlusDetailResources:{
            title: "Help & Training",
            icon: "Help",
            is_Home: true,
            resources:  [
                    { icon: "Document", title: "Read the Salesforce Optimizer Help.", link: "https://help.salesforce.com/articleView?id=optimizer_introduction.htm"},
                    { icon: "Webinar", title: "Sign up for the Optimizer webinar.", link: "https://sfdc.co/OptimizerCircle"}
                ],
          },
        },

        "adapps__OptimizerPlus_File_Storage_Limit__c": {
            OptimizerPlusDetailDescription: {
                title: "File Storage Limits",
                observation: {
                    ready: "Great job! You’re using less than 70% of your file storage limit.",
                    medium_impact: "You’re using {0}% of your file storage limit.",
                    high_impact: "You’re using {0}% of your file storage limit, which is approaching your limit.",
                    error: "You need the Manage Users permission before Optimizer can analyze your file storage limits. Update your permissions, and then run Optimizer again."
                },
                orgLink: "/lightning/setup/CompanyResourceDisk/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "To get to less than 70% of your file storage limit:",
                recommendation_bottom: "If your users still need access to these files, contact your Salesforce account executive to purchase more storage space.",
                recommendation_list: [
                    "Determine whether you need old files that are lingering in your implementation.",
                    "Export the files that your users no longer need, and then delete them from Salesforce."
                ]
            },
            OptimizerPlusDetailImpact: {
                impact: "If you meet or exceed your file storage limit, users receive errors and can’t add new files to Salesforce.",
                show_graph: true,
                usage_label:"File Storage Currently in Use"
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Storage Limits Documentation", link: "https://help.salesforce.com/articleView?id=limits_storage_allocation.htm" },
                    { icon: "Trail", title: "Data Management Trailhead", link: "https://trailhead.salesforce.com/en/modules/lex_implementation_data_management" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Data Management Rockstar Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=data%20management"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Org Health Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailHistory:{
              usage_label:"File Storage Currently in Use",
            },
        },

        "adapps__OptimizerPlus_Data_Storage_Limit__c": {
            OptimizerPlusDetailDescription: {
                title: "Data Storage Limits",
                observation: {
                    ready: "Great job! You’re using less than 70% of your data storage limit.",
                    medium_impact: "You’re using {0}% of your data storage limit.",
                    high_impact: "You’re using {0}% of your data storage limit, which is approaching your limit.",
                    error: "You need the Manage Users permission before Optimizer can analyze your data storage limits. Update your permissions, and then run Optimizer again."
                },
                orgLink: "/lightning/setup/CompanyResourceDisk/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether you need old records that are lingering in your implementation. Export the data that your users no longer need, and then delete it from Salesforce. If your users still need access to this data, contact your Salesforce representative to purchase more storage space.",
            },
            OptimizerPlusDetailImpact: {
                impact: "If you meet or exceed your 1 GB per org data storage limit, users receive errors and can’t add new records or data to Salesforce.",
                show_graph: true,
                usage_label:"Data Storage Currently in Use"
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Data and File Storage Allocations Documentation", link: "https://help.salesforce.com/articleView?id=overview_storage.htm" },
                    { icon: "Document", title: "Best Practices for Deployments with Large Data Volumes", link: "http://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/salesforce_large_data_volumes_bp.pdf" },
                    { icon: "Document", title: "Data Loader Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.dataLoader.meta/dataLoader/data_loader.htm" },
                    { icon: "Trail", title: "Data Management Trailhead", link: "https://trailhead.salesforce.com/en/modules/lex_implementation_data_management" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How to: Platform: Backup and Manage Salesforce Data Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/accelerator-salesforce-data-backup.pdf"}],
                }

            },
            OptimizerPlusDetailHistory:{
              usage_label:"Data Storage Currently in Use",
            },
        },

        "adapps__OptimizerPlus_Static_Resource_Limit__c": {
            OptimizerPlusDetailDescription: {
                title: "Static Resource Limits",
                observation: {
                    ready: "Great job! You’re using less than 70% of your static resource limit.",
                    medium_impact: "You’re using {0}% of your static resource limit.",
                    high_impact: "You’re using {0}% of your static resource limit, which is approaching your limit."
                },
                orgLink: "/lightning/setup/StaticResources/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether you need old static resources that are lingering in your implementation. Export the static resources that your users no longer need, and then delete them from Salesforce."
            },
            OptimizerPlusDetailImpact: {
                impact: "If you meet or exceed your data storage limit, users receive errors and can’t add new records or data to Salesforce.",
                show_graph: true,
                usage_label: "Static Resource Storage Currently in Use",
                note2: "Static resources in managed packages count against your 250 MB per org static resource limit. We include static resources in managed packages in this analysis."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Monitor Data and Storage Resources Documentation", link: "https://help.salesforce.com/articleView?id=admin_monitorresources.htm"},
                    { icon: "Document", title: "Best Practices for Static Resources", link: "https://trailhead.salesforce.com/en/modules/lex_implementation_data_management"},
                    { icon: "Trail", title: "Use Static Resources Trailhead", link: "https://trailhead.salesforce.com/en/modules/visualforce_fundamentals/units/visualforce_static_resources"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform Org Health Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailHistory:{
              usage_label:"Static Resource Storage Currently in Use",
            },
        },
        "adapps__OptimizerPlus_Custom_Field_Limit__c": {
            OptimizerPlusDetailDescription: {
                title: "Custom Field Limits",
                observation: {
                    ready: "Great job! Your field usage looks good.",
                    medium_impact: "One object uses a high number of fields.",
                    multiple_medium_impact: "{0} objects use a high number of fields.",
                    high_impact: "One object uses a very high number of fields, which is approaching the field limits for your edition.",
                    multiple_high_impact: "{0} objects use a very high number of fields, which is approaching the field limits for your edition.",
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete custom fields that your users don’t use or need. Use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users. If your users need these fields, consider <a target='_blank' href='https://developer.salesforce.com/docs/atlas.en-us.204.0.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_features.htm?search_text=validation%20rules'>upgrading your Salesforce edition to increase your field limits</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "You can’t add new fields to an object when you reach the 500 fields per object field limit for your edition.",
                note: "We found {0} more objects with a high number of fields. You’ll need to resolve these issues to see the status of more objects.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Custom Fields Documentation", link: "https://help.salesforce.com/articleView?id=customize_customfields.htm&type=0&language=en_US&release=204.17"},
                    { icon: "Document", title: "Field Footprint App", link: "https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EShrRUAT"},
                    { icon: "Trail", title: "Data Modeling Trailhead", link: "https://trailhead.salesforce.com/en/module/data_modeling"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Platform: Clean Up Custom Fields Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/custom-field-cleanup.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Custom Field Limits",
                tableHead: ["Object", "Number of Fields"],
                note: "We found {0} more objects with a high number of fields. You’ll need to resolve these issues to see the status of more objects."
            }
        },
        "adapps__OptimizerPlus_Active_Sharing_Rules__c": {
            OptimizerPlusDetailDescription: {
                title: "Active Sharing Rule Limits",
                observation: {
                    ready: "Great job! Your implementation uses sharing rules according to our best practices.",
                    low_impact: "One object includes a high number of sharing rules.",
                    medium_impact: "One object includes a high number of sharing rules.",
                    multiple_low_impact: "{0} objects include a high number of sharing rules.",
                    multiple_medium_impact: "{0} objects include a high number of sharing rules.",
                    high_impact: "One object includes a very high number of sharing rules, which can cause you to hit limits.",
                    multiple_high_impact: "{0} objects include a very high number of sharing rules, which can cause you to hit limits."
                },
                orgLink: "/lightning/setup/SecuritySharing/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete unnecessary sharing rules, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Too many sharing rules on objects can increase the time it takes to save and load records. There’s a limit of 300 sharing rules per object.",
                note: "We found {0} more objects with a high number of sharing rules. You’ll need to resolve these issues to see the status of more objects."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Sharing Rules Documentation", link: "https://help.salesforce.com/articleView?id=security_about_sharing_rules.htm&type=0&language=en_US&release=204.17"},
                    { icon: "Document", title: "Sharing Rule Limits Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.204.0.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_features.htm?search_text=validation%20rules"},
                    { icon: "Trail", title: "Overview of Data Security Trailhead", link: "https://trailhead.salesforce.com/en/modules/data_security/units/data_security_overview"}
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Automate Key Business Processes with Lightning Process Builder", link: "http://pages.mail.salesforce.com/gettingstarted/lightning/process-builder/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Active Sharing Rule Limits",
                tableHead: ["Object", "Number of Sharing Rules"],
                note: "We found {number} more objects with a high number of sharing rules. You’ll need to resolve these issues to see the status of more objects."
            }
        },
        "adapps__OptimizerPlus_Active_WF_Rules__c": {
            OptimizerPlusDetailDescription: {
                title: "Active Workflow Rule Limits",
                observation: {
                    ready: "Great job! Your implementation uses workflow rules according to our best practices.",
                    medium_impact: "One object includes a high number of workflow rules.",
                    multiple_medium_impact: "{0} objects include a high number of workflow rules.",
                    high_impact: "One object includes a very high number of workflow rules, which can cause you to hit limits.",
                    multiple_high_impact: "{0} objects include a very high number of workflow rules, which can cause you to hit limits in your edition."
                },
                orgLink: "/lightning/setup/WorkflowRules/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_list: [
                    "Delete unnecessary workflow rules for each object, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users.",
                    "Consolidate the workflow rules on an object into a single process with the <a target='_blank' href='https://help.salesforce.com/articleView?id=process_overview.htm&type=0&language=en_US&release=204.17'>Lightning Process Builder</a>."
                ]
            },
            OptimizerPlusDetailImpact: {
                impact: "Too many workflow rules on objects can increase the time it takes to save and load records. There’s a 50 workflow rules per object limit.",
                note: "We found {0} more objects with a high number of workflow rules. You’ll need to resolve these issues to see the status of more objects."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Workflow Limits Documentation", link: "https://help.salesforce.com/articleView?id=workflow_limits.htm"},
                    { icon: "Document", title: "Process Limits Documentation", link: "https://help.salesforce.com/articleView?id=process_limits.htm"},
                    { icon: "Trail", title: "Automate Basic Business Processes with Process Builder Trailhead", link: "https://trailhead.salesforce.com/en/business_process_automation/process_builder"},
                    { icon: "Trail", title: "Workflow Rule Migration Trailhead", link: "https://trailhead.salesforce.com/modules/workflow_migration"}
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Automate Key Business Processes with Lightning Process Builder", link: "http://pages.mail.salesforce.com/gettingstarted/lightning/process-builder/"}],
                    premier: [{ icon: "Webinar", title: "Transform Your Business with Automation Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&search=automation"}, { icon: "Questions_and_Answers", title: "Review: Platform: Business Process Automation Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/review-platform-business-process-automation.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Active Workflow Rule Limits",
                tableHead: ["Object", "Number of Workflow Rules"],
                note: "We found {0} more objects with a high number of workflow rules. You’ll need to resolve these issues to see the status of more objects."
            }
        },
        "adapps__OptimizerPlus_Active_Val_Rules__c": {
            OptimizerPlusDetailDescription: {
                title: "Active Validation Rule Limits",
                observation: {
                    ready: "Great job! Your implementation uses validation rules according to our best practices.",
                    low_impact: "One object includes too many validation rules.",
                    multiple_low_impact: "{0} objects include too many validation rules.",
                    medium_impact: "One object includes a high number of validation rules.",
                    multiple_medium_impact: "{0} objects include a high number of validation rules.",
                    high_impact: "One object includes a very high number of validation rules, which can cause you to hit limits in your edition.",
                    multiple_high_impact: "{0} objects include a very high number of validation rules, which can cause you to hit limits in your edition."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_list: [
                    "Delete unnecessary validation rules for each object, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users.",
                    "If all the validation rules are necessary to your users, consider <a target='_blank' href='https://developer.salesforce.com/docs/atlas.en-us.204.0.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_features.htm?search_text=validation%20rules'>upgrading your Salesforce edition to increase your validation rule limits</a>."
                ]
            },
            OptimizerPlusDetailImpact: {
                impact: "It takes longer for users to save records that have a high number of validation rules. There’s a 100 validation rules per object limit.",
                note: "We found {0} more objects with a high number of validation rules. You’ll need to resolve these issues to see the status of more objects.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Validation Rules Documentation", link: "https://help.salesforce.com/articleView?id=fields_about_field_validation.htm&type=5"},
                    { icon: "Document", title: "Validation Rules Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.fundamentals.meta/fundamentals/adg_simple_app_adv_validation_rules.htm"},
                    { icon: "Document", title: "Examples of Validation Rules Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.204.0.usefulValidationRules.meta/usefulValidationRules/fields_useful_field_validation_formulas.htm"},
                    { icon: "Trail", title: "Creating Validation Rules Trailhead", link: "https://trailhead.salesforce.com/point_click_business_logic/validation_rules"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Transform Your Business with Automation Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&search=automation"}],
                    premier: [{ icon: "Webinar", title: "Transform Your Business with Automation Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&search=automation"}]
                }
            },
            OptimizerPlusDetailList: {
                title: "Active Validation Rule Limits",
                tableHead: ["Object", "Number of Validation Rules"],
                note: "We found {number} more objects with a high number of validation rules. You’ll need to resolve these issues to see the status of more objects."
            }
        },
        "adapps__OptimizerPlus_Field_Usage__c": {
            OptimizerPlusDetailDescription: {
                title: "Field Usage",
                observation: {
                    ready: "Great job! Your users regularly use the fields on your objects.",
                    low_impact: "One field was completed less than 10% of the time within the past three months.",
                    multiple_low_impact: "{0} fields were completed less than 10% of the time within the last three months.",
                    unable_timeout: "A timeout error occurred when evaluating your org for field usage. This section was removed from your report.",
                    unable_too_many: "Your implementation contains too many records to analyze. To identify fields that can be removed from your implementation, download the <a target='_blank' href='https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EShrRUAT'>Field Footprint</a> app."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete custom fields that your users don’t use or need. Use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unnecessary fields clutter your objects and make your implementation difficult to maintain.",
                note: "We found {0} more unused fields. You’ll need to resolve these issues to see the status of more fields."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Delete Fields Documentation", link: "https://help.salesforce.com/articleView?id=deleting_fields.htm&type=0&language=en_US&release=204.17" },
                    { icon: "Document", title: "Custom Fields Allowed Per Object Documentation", link: "https://help.salesforce.com/articleView?id=custom_field_allocations.htm" },
                    { icon: "Document", title: "Field Footprint App", link: "https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EShrRUAT" },
                    { icon: "Trail", title: "Data Modeling Trailhead", link: "https://trailhead.salesforce.com/en/module/data_modeling" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Platform: Clean Up Custom Fields Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/custom-field-cleanup.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Field Usage",
                tableHead: ["Unused Field", "Related Page Layout"],
                note: "We found {number} more unused fields. You’ll need to resolve these issues to see the status of more fields."
            }
        },
        "adapps__OptimizerPlus_Fields_Page_Layouts__c": {
            OptimizerPlusDetailDescription: {
                title: "Fields on Page Layouts",
                observation: {
                    ready: "Great job! Your page layouts meet our best practices.",
                    low_impact: "One page layout contains a high number of fields.",
                    multiple_low_impact: "{0} page layouts contain a high number of fields.",
                    medium_impact: "One page layout contains a very high number of fields.",
                    multiple_medium_impact: "{0} page layouts contain a very high number of fields."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete custom fields that your users don’t use or need. Use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Excessive fields clutter your page layouts, make your implementation difficult to maintain, and increase page load time.",
                note: "We found {0} more page layouts with a high number of fields. You’ll need to resolve these issues to see the status of more page layouts."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Delete Fields Documentation", link: "https://help.salesforce.com/articleView?id=deleting_fields.htm&type=0&language=en_US&release=204.17" },
                    { icon: "Document", title: "Field Footprint App", link: "https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EShrRUAT" },
                    { icon: "Trail", title: "Data Modeling Trailhead", link: "https://trailhead.salesforce.com/en/module/data_modeling" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Create the User Experience Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.webinar&search=user%20experience"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Org Health Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Fields on Page Layouts",
                tableHead: ["Page Layout", "Number of Fields"],
                note: "We found {number} more page layouts with a high number of fields. You’ll need to resolve these issues to see the status of more page layouts."
            }
        },
        "adapps__OptimizerPlus_Details_Tabs_Pages__c": {
            OptimizerPlusDetailDescription: {
                title: "Details Tab on Record Pages",
                observation: {
                    ready: "Great job! Your use of the Details tab meets our best practices.",
                    low_impact: "One page contains a Details tab with a high number of fields.",
                    multiple_low_impact: "{0} pages contain a Details tab with a high number of fields.",
                    medium_impact: "One page contains a Details tab with a very high number of fields.",
                    multiple_medium_impact: "{0} pages contain a Details tab with a very high number of fields.",
                    high_impact: "One page contains a Details tab with a very high number of fields.",
                    multiple_high_impact: "{0} pages contain a Details tab with a very high number of fields."
                },
                orgLink: "/lightning/setup/FlexiPageList/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "The Details tab displays fields and sections from the page layout associated with the object. When you have a high number of fields on this tab, you can increase performance by moving the Details tab so that it’s not shown by default on a Lightning record page."
            },
            OptimizerPlusDetailImpact: {
                impact: "Excessive fields clutter your page, make your implementation difficult to maintain, and increase page load time.",
                note: "We found {0} more Lightning pages to review. You’ll need to resolve these issues to see the status of more pages."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Customize Tabs on Lightning Experience Record Pages Using the Lightning App Builder Documentation", link: "https://help.salesforce.com/articleView?id=lightning_app_builder_customize_lex_pages_add_tabs.htm" },
                ],
                top_resources: {
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Lightning Platform: Configuration Fast Start Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/lightning-config-fast-start.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Details Tab on Record Pages",
                tableHead: ["Lightning Record Pages", "Number of Fields"],
                note: "We found {number} more Lightning pages to review. You’ll need to resolve these issues to see the status of more pages."
            }
        },
        "adapps__OptimizerPlus_Unused_Reports__c": {
            OptimizerPlusDetailDescription: {
                title: "Unused Reports",
                observation: {
                    ready: "Great job! You don’t have unused reports.",
                    low_impact: "You have 1 unused report.",
                    multiple_low_impact: "You have {0} unused reports.",
                    unable_timeout: "A timeout error occurred while evaluating your org for Unused Reports. This section was removed from your report.",
                    unable_too_many: "A timeout error occurred while evaluating your org for Unused Reports. This section was removed from your report."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete the reports that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unused reports make your implementation difficult to maintain.",
                note: "We found {0} more unused reports. You’ll need to resolve these issues to see the status of more reports."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Delete a Report Documentation", link: "https://help.salesforce.com/articleView?id=reports_delete.htm" },
                    { icon: "Document", title: "Salesforce Reports and Dashboards Limits Per Edition Documentation", link: "https://help.salesforce.com/articleView?id=limits_analytics_per_edition.htm&type=5" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Tech Lounge: Reporting Basics Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=reporting"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Insights: Sales Cloud: Design Reports and Dashboards Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/sc-reports-and-dashboards-qs.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unused Reports",
                tableHead: ["Report Name", "Last Viewed", "Last Run", "Last Modified"],
                note: "We found {number} more unused reports. You’ll need to resolve these issues to see the status of more reports."
            }
        },
        "adapps__OptimizerPlus_Unused_Dashboards__c": {
            OptimizerPlusDetailDescription: {
                title: "Unused Dashboards",
                observation: {
                    ready: "Great job! You don’t have unused dashboards.",
                    low_impact: "You have 1 unused dashboard.",
                    multiple_low_impact: "You have {0} unused dashboards.",
                    unable_timeout: "A timeout error occurred while evaluating your org for Unused Dashboards. This section was removed from your report.",
                    unable_too_many: "A timeout error occurred while evaluating your org for Unused Dashboards. This section was removed from your report."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete the dashboards that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unused dashboards make your implementation difficult to maintain.",
                note: "We found {0} more unused dashboards. You’ll need to resolve these issues to see the status of more dashboards."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Delete a Dashboard Documentation", link: "https://help.salesforce.com/articleView?id=dashboards_del.htm" },
                    { icon: "Document", title: "Salesforce Reports and Dashboards Limits Per Edition Documentation", link: "https://help.salesforce.com/articleView?id=limits_analytics_per_edition.htm&type=5" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Drive Metrics Using Reports and Dashboards Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=reports"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Insights: Sales Cloud: Design Reports and Dashboards Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/sc-reports-and-dashboards-qs.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unused Dashboards",
                tableHead: ["Dashboard Name", "Last Viewed", "Last Modified"],
                note: "We found {number} more unused dashboards. You’ll need to resolve these issues to see the status of more dashboards."
            }
        },

        "adapps__OptimizerPlus_Unassigned_Page_Layouts__c": {
            OptimizerPlusDetailDescription: {
                title: "Unassigned Page Layouts",
                observation: {
                    ready: "Great job! You don’t have unassigned page layouts.",
                    low_impact: "You have 1 page layout that isn’t assigned to a record type.",
                    multiple_low_impact: "You have {0} page layouts that aren’t assigned to a record type."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete unassigned page layouts in your implementation, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users. If you need to keep the page layout, <a target='_blank' href='https://help.salesforce.com/articleView?id=customize_layoutassign.htm'>assign it to a record type</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "Page layouts that aren’t assigned to record types take up unnecessary space and make your implementation harder to maintain.",
                note: "We found {0} more unassigned page layouts. You’ll need to resolve these issues to see the status of more page layouts.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Page Layouts Documentation", link: "https://help.salesforce.com/articleView?id=customize_layout.htm"},
                    { icon: "Trail", title: "Customize Record Details with Page Layouts Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_beginner/modules/lex_customization/units/lex_customization_page_layouts"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Org Health Assessment Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unassigned Page Layouts",
                tableHead: ["Unassigned Page Layouts"],
                note: "We found {number} more unassigned page layouts. You’ll need to resolve these issues to see the status of more page layouts."
            }
        },
        "adapps__OptimizerPlus_Unassigned_Rec_Types__c": {
            OptimizerPlusDetailDescription: {
                title: "Unassigned Record Types",
                observation: {
                    ready: "Great job! You don’t have unassigned record types.",
                    low_impact: "You have 1 record type that isn’t assigned to a profile.",
                    multiple_low_impact: "You have {0} record types that aren’t assigned to a profile."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete unassigned record types in your implementation, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users.",
            },
            OptimizerPlusDetailImpact: {
                impact: "Record types that aren’t assigned to profiles take up unnecessary space and make your implementation harder to maintain.",
                note: "We found {0} more unassigned record types.  You’ll need to resolve these issues to see the status of more record types.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Considerations for Creating and Updating Record Types and Picklists Documentation", link: "https://help.salesforce.com/articleView?id=customize_recordtype_considerations.htm&type=0&language=en_US"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Org Health Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unassigned Record Types",
                tableHead: ["Unassigned Record Types"],
                note: "We found {number} more unassigned record types.  You’ll need to resolve these issues to see the status of more record types."
            }
        },
        "adapps__OptimizerPlus_Page_Layouts_X_Object__c": {
            OptimizerPlusDetailDescription: {
                title: "Page Layouts per Object",
                observation: {
                    ready: "Great job! You use page layouts according to our best practices.",
                    low_impact: "You have 1 object with a high number of page layouts.",
                    multiple_low_impact: "You have {0} objects with a high number of page layouts.",
                    medium_impact: "You have 1 object with a very high number of page layouts.",
                    multiple_medium_impact: "You have {0} objects with a very high number of page layouts."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Implement a consistent page layout for as many objects as possible, and delete the page layouts that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unnecessary page layouts make your implementation difficult to maintain.",
                note: "We found {0} more objects with a high number of page layouts.  You’ll need to resolve these issues to see the status of more page layouts.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Page Layouts Documentation", link: "https://help.salesforce.com/articleView?id=customize_layout.htm&type=0&language=en_US" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Org Health Assessment Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Page Layouts per Object",
                tableHead: ["Object", "Number of Page Layouts"],
                note: "We found {number} more objects with a high number of page layouts.  You’ll need to resolve these issues to see the status of more page layouts."
            }
        },
        "adapps__OptimizerPlus_Rec_Types_X_Object__c": {
            OptimizerPlusDetailDescription: {
                title: "Record Types per Object",
                observation: {
                    ready: "Great job! You use record types according to our best practices.",
                    low_impact: "You have 1 object with a high number of record types.",
                    multiple_low_impact: "You have {0} objects with a high number of record types.",
                    medium_impact: "You have 1 object with a very high number of record types.",
                    multiple_medium_impact: "You have {0} objects with a very high number of record types."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Implement a consistent record type for as many objects as possible, and delete the record types that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unnecessary record types make your implementation difficult to maintain.",
                note: "We found {0} more objects with a high number of record types. You’ll need to resolve these issues to see the status of more record types.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Considerations for Creating and Updating Record Types and Picklists Documentation", link: "https://help.salesforce.com/articleView?id=customize_recordtype_considerations.htm&type=0&language=en_US"},
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Org Health Accelerator", link: "https://www.salesforce.com/assets/pdf/success-services/salesforce-org-health.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Record Types per Object",
                tableHead: ["Object", "Number of Record Types"],
                note: "We found {number} more objects with a high number of record types. You’ll need to resolve these issues to see the status of more record types."
            }
        },
        "adapps__OptimizerPlus_Rep_Related_Lists__c": {
            OptimizerPlusDetailDescription: {
                title: "Replacing Related Lists with the Related List Quick Links Component",
                observation: {
                    ready: "Great job! You use related lists according to our best practices.",
                    low_impact: "One Lightning page might not be taking advantage of the Related List Quick Links component.",
                    multiple_low_impact: "{0} Lightning pages might not be taking advantage of the Related List Quick Links component.",
                },
                orgLink: "/lightning/setup/FlexiPageList/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Replace all Related Lists components with the Related List Quick Links component. If there’s a related list that should be easily accessible to users, you can add a Related List - Single component. If a page layout includes many related lists, consider moving some to a second tab."
            },
            OptimizerPlusDetailImpact: {
                impact: "Scrolling through several related lists to find the right one is time consuming. With the Related List Quick Links component, users can hover over links to see all the related list columns without opening the View All page. Users see all options at a glance and can find the right one faster. Users can also customize the quick link order in their personal settings.",
                note: "We found {0} more Lightning pages that could possibly benefit from replacing single Related List components with the Related List Quick Links component. You’ll need to resolve these issues to see the status of more Lightning pages.",
                note2: "We analyze related lists only in layouts assigned to a profile."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Standard Lightning Page Components Documentation", link: "https://help.salesforce.com/articleView?id=lightning_page_components.htm&type=5" },
                    { icon: "Document", title: "Customize Related Lists Documentation", link: "https://help.salesforce.com/articleView?id=customizing_related_lists.htm" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Streamline Salesforce Experience Through Data Archival and Cleanup Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Replacing Related Lists with the Related List Quick Links Component",
                tableHead: ["Lightning Pages", "Number of Related Lists"],
                note: "We found {number} more Lightning pages that could possibly benefit from replacing single Related List components with the Related List Quick Links component. You’ll need to resolve these issues to see the status of more Lightning pages."
            }
        },
        "adapps__OptimizerPlus_News_And_Twitter__c": {
            OptimizerPlusDetailDescription: {
                title: "News and Twitter",
                observation: {
                    ready: "Great job! Your News and Twitter components are already behind a tab.",
                    medium_impact: "One Lightning page includes the News or Twitter component.",
                    multiple_medium_impact: "{0} Lightning pages include the News or Twitter component."
                },
                orgLink: "/lightning/setup/FlexiPageList/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Move the News and Twitter components from the page to a tab."
            },
            OptimizerPlusDetailImpact: {
                impact: "Having the News or Twitter component directly on a page can cause the page to load slowly.",
                note: "We found {0} more Lightning pages with the News or Twitter component. You’ll need to resolve these issues to see the status of more Lightning pages.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Customize Tabs on Lightning Experience Record Pages Using the Lightning App Builder Documentation", link: "https://help.salesforce.com/articleView?id=lightning_app_builder_customize_lex_pages_add_tabs.htm&type=5" },
                ],
                top_resources: {
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Lightning Platform: Configuration Fast Star Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/lightning-config-fast-start.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "News and Twitter",
                tableHead: ["Lightning Page with News or Twitter Component"],
                note: "We found {number} more Lightning pages with the News or Twitter component. You’ll need to resolve these issues to see the status of more Lightning pages."
            }
        },
        "adapps__OptimizerPlus_Lig_Comp_Record__c": {
            OptimizerPlusDetailDescription: {
                title: "Lightning Components on Record Lightning Pages",
                observation: {
                    ready: "Great job! You use Lightning components according to our best practices.",
                    low_impact: "One Lightning page might include too many components.",
                    multiple_low_impact: "{0} Lightning pages might include too many components.",
                    medium_impact: "One Lightning page has a high number of components.",
                    multiple_medium_impact: "{0} Lightning pages has a high number of components.",
                    high_impact: "One Lightning page has a very high number of components.",
                    multiple_high_impact: "{0} Lightning pages have a very high number of Lightning components.",
                    note: "",
                },
                orgLink: "/lightning/setup/FlexiPageList/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Move some Lightning components to the Tabs or Accordion Lightning component."
            },
            OptimizerPlusDetailImpact: {
                impact: "Too many components on a page can cause it to load slowly.",
                note: "We found {0} more Lightning pages with a high number of components. You’ll need to resolve these issues to see the status of more Lightning pages.",
                note2: "We only analyze Lightning pages for the record page type."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Customize Tabs on Lightning Experience Record Pages Using the Lightning App Builder Documentation", link: "https://help.salesforce.com/articleView?id=lightning_app_builder_customize_lex_pages_add_tabs.htm&type=5" },
                    { icon: "Document", title: "Standard Lightning Page Components Documentation", link: "https://help.salesforce.com/articleView?id=lightning_page_components.htm&type=5" },
                ],
                top_resources: {
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Lightning Platform: Configuration Fast Start Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/lightning-config-fast-start.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Lightning Components on Record Lightning Pages",
                tableHead: ["Lightning Page", "Number of Components"],
                note: "We found {number} more Lightning pages with a high number of components. You’ll need to resolve these issues to see the status of more Lightning pages."
            }
        },
        "adapps__OptimizerPlus_Inactive_Val_Rules__c": {
            OptimizerPlusDetailDescription: {
                title: "Inactive Validation Rules",
                observation: {
                    ready: "Great job! You don’t have any inactive validation rules.",
                    low_impact: "You have 1 inactive validation rule.",
                    multiple_low_impact: "You have {0} inactive validation rules."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete validation rules that you don’t need, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Inactive validation rules make your implementation difficult to maintain.",
                note: "We found {0} more inactive validation rules. You’ll need to resolve these issues to see the status of more validation rules.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Validation Rule Limits Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.204.0.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_features.htm?search_text=validation%20rules" },
                    { icon: "Trail", title: "Creating Validation Rules Trailhead", link: "https://trailhead.salesforce.com/point_click_business_logic/validation_rules" },
                    { icon: "Trail", title: "Process Automation Trailhead", link: "https://trailhead.salesforce.com/modules/business_process_automation" },
                ],
                top_resources: {
                    premier: [{ icon: "Questions_and_Answers", title: "Automate Key Business Processes with Lightning Process Builder", link: "http://pages.mail.salesforce.com/gettingstarted/lightning/process-builder/"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Inactive Validation Rules",
                tableHead: ["Object", "Inactive Validation Rule"],
                note: "We found {number} more inactive validation rules. You’ll need to resolve these issues to see the status of more validation rules."
            }
        },
        "adapps__OptimizerPlus_Inactive_WF_Rules__c": {
            OptimizerPlusDetailDescription: {
                title: "Inactive Workflow Rules",
                observation: {
                    ready: "Great job! You don’t have any inactive workflow rules.",
                    low_impact: "You have 1 inactive workflow rule.",
                    multiple_low_impact: "You have {0} inactive workflow rules.",
                },
                orgLink: "/lightning/setup/WorkflowRules/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete workflow rules that you don’t need, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Inactive workflow rules make your implementation difficult to maintain.",
                note: "For this report, we only analyzed Account, Opportunities, Cases, Lead, Campaign, Contact and custom objects. Objects from managed packages aren’t analyzed.",
                note2: "View all inactive workflow rules in Setup."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Lightning Process Builder Documentation", link: "https://help.salesforce.com/articleView?id=process_overview.htm&type=0&language=en_US&release=204.17"},
                    { icon: "Trail", title: "Process Automation Trailhead", link: "https://trailhead.salesforce.com/modules/business_process_automation"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Transform Your Business with Automation Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&search=automation"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Business Process Automation Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/review-platform-business-process-automation.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Inactive Workflow Rules",
                tableHead: ["Object", "Inactive Workflow Rule"],
                note: "View all inactive workflow rules in Setup."
            }
        },

        "adapps__OptimizerPlus_Migrating_Workflows__c": {
            OptimizerPlusDetailDescription: {
                title: "Migrating Workflow Rules to the Lightning Process Builder",
                observation: {
                    not_currently_enabled: "You have 1 workflow rule that you can replace with a process.",
                    multiple_not_currently_enabled: "You have {0} workflow rules that you can replace with a process.",
                    ready: "Great job! You don’t have any workflow rules to replace.",
                    medium_impact: "You have 1 workflow rule that you can replace with a process.",
                    multiple_medium_impact: "You have {0} workflow rules that you can replace with a process."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Replace workflow rules by <a target='_blank' href='https://help.salesforce.com/articleView?id=process_create.htm&type=0&language=en_US'>creating processes</a>, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Eventually, the Lightning Process Builder will replace workflow rules, so we recommend replacing workflow rules as soon as possible.",
                show_note: false
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Lightning Process Builder Documentation", link: "https://help.salesforce.com/articleView?id=process_overview.htm&type=0&language=en_US&release=204.17" },
                    { icon: "Trail", title: "Process Automation Trailhead", link: "https://trailhead.salesforce.com/modules/business_process_automation" },
                    { icon: "Trail", title: "Workflow Rule Migration Trailhead", link: "https://trailhead.salesforce.com/modules/workflow_migration" },
                ],
                top_resources: {
                    premier: [{ icon: "Questions_and_Answers", title: "Automate Key Business Processes with Lightning Process Builder", link: "http://pages.mail.salesforce.com/gettingstarted/lightning/process-builder/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Automate Key Business Processes with Lightning Process Builder", link: "http://pages.mail.salesforce.com/gettingstarted/lightning/process-builder/"}],
                }
            },
        },
        "adapps__OptimizerPlus_User_Logins__c": {
            OptimizerPlusDetailDescription: {
                title: "User Logins",
                observation: {
                    low_impact: "One user hasn’t logged in lately.",
                    multiple_low_impact: "{0} users haven’t logged in lately.",
                    multiple_medium_impact: "At least {0} users haven’t logged in lately.",
                },
                orgLink: "/lightning/setup/ManageUsers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether these users need access to Salesforce. Deactivate accounts of former employees or anyone who doesn’t need to access Salesforce."
            },
            OptimizerPlusDetailImpact: {
                impact: "If users aren’t managing their business in Salesforce, your teams might not be working efficiently, and your data might be at risk.",
                note: "We found {0} more users who haven’t logged in recently. You’ll need to resolve these issues to see the status of more users.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Deactivate (Delete) Users Documentation", link: "https://help.salesforce.com/articleView?id=deactivating_users.htm" },
                    { icon: "Trail", title: "User Management Trailhead", link: "https://trailhead.salesforce.com/modules/lex_implementation_user_setup_mgmt" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started Series: Create the User Experience Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.webinar&search=user%20experience"}],
                    premier: [{ icon: "Webinar", title: "Getting Started Series: Create the User Experience Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.webinar&search=user%20experience"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "User Logins",
                tableHead: ["User Name", "Login Frequency", "Days Since Last Login"],
                tableHead_2: ["User Login Frequency"],
                note: "We found {number} more users who haven’t logged in recently. You’ll need to resolve these issues to see the status of more users."
            }
        },
        "adapps__OptimizerPlus_Admin_Perm__c": {
            OptimizerPlusDetailDescription: {
                title: "Admin Permissions",
                observation: {
                    ready: "Great job! You have an appropriate number of admins for your implementation.",
                    multiple_low_impact: "You have a high number of admins.",
                    multiple_medium_impact: "Your have a very high number of admins."
                },
                orgLink: "/lightning/setup/EnhancedProfiles/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Reduce the number of users who have the Customize App and Modify All Data permissions. We define an admin by these settings. Assign users those permissions only if they are responsible for maintaining and updating users and settings in your implementation."
            },
            OptimizerPlusDetailImpact: {
                show_note: false,
                impact: "Having too many admins can make it more difficult to keep your settings and data secure."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Edit Users Documentation", link: "https://help.salesforce.com/articleView?id=editing_users.htm&type=0&language=en_US"},
                    { icon: "Document", title: "Profiles Documentation", link: "https://help.salesforce.com/articleView?id=admin_userprofiles.htm&type=0&language=en_US&release=204.18"},
                    { icon: "Trail", title: "User Management Trailhead", link: "https://trailhead.salesforce.com/modules/lex_implementation_user_setup_mgmt"},
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Admin Permissions",
                tableHead: ["Admin Name", "Admin Username"]
            }
        },
        "adapps__OptimizerPlus_Unassigned_Roles__c": {
            OptimizerPlusDetailDescription: {
                title: "Unassigned Roles",
                observation: {
                    ready: "Great job! You don’t have unassigned roles.",
                    low_impact: "You have 1 unassigned role.",
                    multiple_low_impact: "You have {0} unassigned roles."
                },
                orgLink: "/lightning/setup/Roles/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete roles that don’t have active users assigned to them, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unassigned roles make your implementation difficult to maintain.",
                note: "We found {0} more unassigned roles. You’ll need to resolve these issues to see the status of more roles.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "User Role Hierarchy Documentation", link: "https://help.salesforce.com/articleView?id=admin_roles.htm" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Streamline Salesforce Experience Through Data Archival and Cleanup", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&search=streamline"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unassigned Roles",
                tableHead: ["Unassigned Roles"],
                note: "We found {number} more unassigned roles. You’ll need to resolve these issues to see the status of more roles."
            }
        },
        "adapps__OptimizerPlus_Unassigned_Profiles__c": {
            OptimizerPlusDetailDescription: {
                title: "Unassigned Custom Profiles",
                observation: {
                    ready: "Great job! You don’t have unassigned custom profiles.",
                    low_impact: "You have 1 unassigned custom profile.",
                    multiple_low_impact: "You have {0} unassigned profiles."
                },
                orgLink: "/lightning/setup/EnhancedProfiles/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete custom profiles that don’t have active users assigned to them, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unassigned custom profiles make your implementation difficult to maintain.",
                note: "We found {0} more unassigned custom profiles. You’ll need to resolve these issues to see the status of more profiles.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Profiles Documentation", link: "https://help.salesforce.com/articleView?id=admin_userprofiles.htm&type=0&language=en_US&release=206.11" },
                    { icon: "Document", title: "Security for Profiles Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_userprofiles.htm" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unassigned Custom Profiles",
                tableHead: ["Unassigned Custom Profiles"],
                note: "We found {number} more unassigned custom profiles. You’ll need to resolve these issues to see the status of more profiles."
            }
        },
        "adapps__OptimizerPlus_Custom_Profiles__c": {
            OptimizerPlusDetailDescription: {
                title: "Custom Profiles with a Low Number of Users",
                observation: {
                    ready: "Great job! You don’t have profiles with a low number of users.",
                    low_impact: "You have 1 custom profile that has a low number of users.",
                    multiple_low_impact: "You have {0} custom profiles that have a low number of users."
                },
                orgLink: "/lightning/setup/EnhancedProfiles/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Consolidate profiles that have a low number of active users, and delete the profiles that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Excessive custom profiles make your implementation difficult to maintain.",
                note: "We found {0} more custom profiles with a low number of users. You’ll need to resolve these issues to see the status of more profiles.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Profiles Documentation", link: "https://help.salesforce.com/articleView?id=admin_userprofiles.htm&type=0&language=en_US&release=206.11" },
                    { icon: "Document", title: "Security for Profiles Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_userprofiles.htm" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Custom Profiles with a Low Number of Users",
                tableHead: ["Custom Profile", "Number of Users"],
                note: "We found {number} more custom profiles with a low number of users. You’ll need to resolve these issues to see the status of more profiles."
            }
        },
        "adapps__OptimizerPlus_Unassigned_Perm_Sets__c": {
            OptimizerPlusDetailDescription: {
                title: "Unassigned Permission Sets",
                observation: {
                    ready: "Great job! You don’t have unassigned permission sets.",
                    low_impact: "You have 1 unassigned permission set.",
                    multiple_low_impact: "You have {0} unassigned permission sets."
                },
                orgLink: "/lightning/setup/PermSets/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Delete permission sets that don’t have active users assigned to them, and use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unassigned permission sets make your implementation difficult to maintain.",
                note: "We found {0} more unassigned permission sets. You’ll need to resolve these issues to see the status of more permission sets.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Permission Sets Documentation", link: "https://help.salesforce.com/articleView?id=perm_sets_overview.htm&type=0&language=en_US&release=206.11" },
                    { icon: "Document", title: "Security for Permission Sets Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_userprofiles.htm" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Unassigned Permission Sets",
                tableHead: ["Unassigned Permission Sets"],
                note: "We found {number} more unassigned permission sets. You’ll need to resolve these issues to see the status of more permission sets."
            }
        },
        "adapps__OptimizerPlus_Custom_Perm_Sets__c": {
            OptimizerPlusDetailDescription: {
                title: "Permission Sets with a Low Number of Users",
                observation: {
                    ready: "Great job! You don’t have permission sets with a low number of users.",
                    low_impact: "You have 1 permission set with a low number of users.",
                    multiple_low_impact: "You have {0} permission sets with a low number of users."
                },
                orgLink: "/lightning/setup/PermSets/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Consolidate permission sets that have a low number of active users, and delete the permission sets that you no longer need."
            },
            OptimizerPlusDetailImpact: {
                impact: "Excessive permission sets make your implementation difficult to maintain.",
                note: "We found {0} more permission sets with a low number of users. You’ll need to resolve these issues to see the status of more permission sets.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Permission Sets Documentation", link: "https://help.salesforce.com/articleView?id=perm_sets_overview.htm&type=0&language=en_US&release=206.11" },
                    { icon: "Document", title: "Security for Permission Sets Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.securityImplGuide.meta/securityImplGuide/admin_userprofiles.htm" },
                    { icon: "Trail", title: "Data Security Trailhead", link: "https://trailhead.salesforce.com/trails/force_com_admin_intermediate/modules/data_security" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Platform: Access Controls Accelerator", link: "https://help.salesforce.com/articleView?id=Getting-Started-Platform-Access-Controls&language=en_US&type=1"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Permission Sets with a Low Number of Users",
                tableHead: ["Permission Set", "Number of Users"],
                note: "We found {number} more permission sets with a low number of users. You’ll need to resolve these issues to see the status of more permission sets."
            }
        },
        "adapps__OptimizerPlus_Formula_Fields__c": {
            OptimizerPlusDetailDescription: {
                title: "Formula Fields with JavaScript Code",
                observation: {
                    ready: "Great job! You don’t have formula fields that contain JavaScript code.",
                    medium_impact: "You have 1 formula field that contains JavaScript code.",
                    multiple_medium_impact: "You have {0} formula fields that contain JavaScript code.",
                    unable_timeout: "A timeout error occurred when evaluating your org for formula fields with JavaScript code. This section was removed from your report.",
                    unable_too_many: "A timeout error occurred when evaluating your org for formula fields with JavaScript code. This section was removed from your report."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Remove all JavaScript code from your formula fields. Use your <a target='_blank' href='https://help.salesforce.com/articleView?id=create_test_instance.htm&language=en&type=0'>sandbox</a> to test changes before you deploy them to your users."
            },
            OptimizerPlusDetailImpact: {
                impact: "JavaScript security issues can put your data at risk if you use JavaScript code in formula fields.",
                note: "We found {0} more formula fields that contain JavaScript code. You’ll need to resolve these issues to see the status of more fields.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Build a Formula Field Documentation", link: "https://help.salesforce.com/articleView?id=customize_formulas.htm" },
                    { icon: "Trail", title: "Use Formula Fields Trailhead", link: "https://trailhead.salesforce.com/en/modules/point_click_business_logic/units/formula_fields" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Ask Salesforce Anything Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=ask"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Formula Fields with JavaScript Code",
                tableHead: ["Formula Fields with JavaScript Code"],
                note: "We found {number} more formula fields that contain JavaScript code. You’ll need to resolve these issues to see the status of more fields."
            }
        },
        "adapps__OptimizerPlus_Triggers_Per_Object__c": {
            OptimizerPlusDetailDescription: {
                title: "Multiple Apex Triggers per Object",
                observation: {
                    ready: "Great job! You use triggers according to our best practices.",
                    medium_impact: "You have 1 object that contains multiple triggers.",
                    multiple_medium_impact: "You have {0} objects that contain multiple triggers."
                },
                orgLink: "/lightning/setup/ApexTriggers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "If an object contains multiple triggers, consolidate them into a single trigger. If coding isn’t your thing, use the <a target='_blank' href='http://pages.mail.salesforce.com/achievemore/automateprocesses'>Lightning Process Builder</a> to consolidate triggers. We filtered out triggers from apps that you downloaded from AppExchange and other managed packages."
            },
            OptimizerPlusDetailImpact: {
                impact: "Having more than one trigger on an object can cause you to reach Apex limits. Triggers can also execute in a random order."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Triggers Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.202.0.apexcode.meta/apexcode/apex_triggers.htm"},
                    { icon: "Trail", title: "Apex Triggers Trailhead", link: "https://trailhead.salesforce.com/module/apex_triggers"}
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Getting Started with Salesforce Live: Q&A Office Hours", link: "https://register.gotowebinar.com/register/8990512341795866113"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Review: Platform: Business Process Automation Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/review-platform-business-process-automation.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Multiple Apex Triggers per Object",
                tableHead: ["Object", "Number of Apex Triggers"]
            }
        },
        "adapps__OptimizerPlus_Old_Api_Version__c": {
            OptimizerPlusDetailDescription: {
                title: "API Versions",
                observation: {
                    ready: "Great job! Your code is up to date.",
                    low_impact: "You have 1 code element that uses out-of-date API versions.",
                    multiple_low_impact: "You have {0} code elements that use out-of-date API versions."
                },
                orgLink: "/lightning/setup/ApexTriggers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Ask your Salesforce developer to update these elements with the current API version. Give your developer the following resources for best practices on updating code."
            },
            OptimizerPlusDetailImpact: {
                impact: "API versions that are more than nine releases—or three years—old can hinder your code’s performance.",
                note: "We found {0} more out-of-date code elements. You’ll need to resolve these issues to see the status of more Apex classes."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Apex Release Notes", link: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_intro_whats_new.htm?search_text=what%27s%20new"},
                    { icon: "Document", title: "Apex Code Versions Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_version_settings_intro.htm"},
                    { icon: "Document", title: "Metadata API Developer Guide", link: "https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_intro.htm"},
                    { icon: "Trail", title: "API Basics Trailhead", link: "https://trailhead.salesforce.com/modules/api_basics"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Ask Salesforce Anything Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=ask"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "API Versions",
                tableHead: ["Name", "API Version", "Code Element", "Last Modified"],
                note: "We found {0} more out-of-date code elements. You’ll need to resolve these issues to see the status of more Apex classes."

            }
        },
        "adapps__OptimizerPlus_New_Api_Version__c": {
            OptimizerPlusDetailDescription: {
                title: "New Code Using Old API Versions",
                observation: {
                    ready: "Great job! Your code is up to date.",
                    low_impact: "You have 1 new code element that uses out-of-date API versions.",
                    multiple_low_impact: "You have {0} new code elements that use out-of-date API versions."
                },
                orgLink: "/lightning/setup/ApexTriggers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Ask your Salesforce developer to update these elements with the current API version. Give your developer the following resources for best practices on updating code."
            },
            OptimizerPlusDetailImpact: {
                impact: "Out-of-date API versions don’t provide the latest functionality and security features.",
                note: "We found {0} more out-of-date code elements. You’ll need to resolve these issues to see the status of more Apex classes."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Apex Release Notes", link: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_intro_whats_new.htm?search_text=what%27s%20new"},
                    { icon: "Document", title: "Apex Code Versions Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_version_settings_intro.htm"},
                    { icon: "Document", title: "Metadata API Developer Guide", link: "https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_intro.htm"},
                    { icon: "Trail", title: "API Basics Trailhead", link: "https://trailhead.salesforce.com/modules/api_basics"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Ask Salesforce Anything Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=ask"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "New Code Using Old API Versions",
                tableHead: ["Name", "API Version", "Code Element", "Last Modified"],
                note: "We found {0} more out-of-date code elements. You’ll need to resolve these issues to see the status of more Apex classes."

            }
        },
        "adapps__OptimizerPlus_Scontrols__c": {
            OptimizerPlusDetailDescription: {
                title: "S-Controls",
                observation: {
                  ready: "You don’t have any s-controls to replace.",
                  low_impact: "You have 1 s-control.",
                  multiple_low_impact: "You have {0} s-controls."
                },
                orgLink: "/lightning/setup/ApexTriggers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether your users still require the functionality that’s defined by the s-control. Replace the ones still in use with custom Lightning components or Visualforce pages."
            },
            OptimizerPlusDetailImpact: {
                impact: "S-controls can introduce security risks in your implementation and are no longer supported.",
                note: "View s-controls in Setup."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Using Components Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/components_using_intro.htm"},
                    { icon: "Document", title: "Check Your Lightning Experience Readiness Documentation", link: "https://help.salesforce.com/articleView?id=lex_readiness_check.htm"},
                    { icon: "Trail", title: "Lightning Components Basics Trailhead", link: "https://trailhead.salesforce.com/trails/lex_dev/modules/lex_dev_lc_basics"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Ask Salesforce Anything Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=ask"}],
                }
            },
            OptimizerPlusDetailList: {
                note: "View s-controls in Setup."
            }
        },
        "adapps__OptimizerPlus_Hardcoded_Urls__c": {
            OptimizerPlusDetailDescription: {
                title: "Hard-Coded URLs",
                observation: {
                  ready: "Great job! You don’t have any hard-coded URLs to replace.",
                    low_impact: "You have 1 hard-coded URL.",
                    multiple_low_impact: "You have {0} objects that contain multiple triggers.",
              },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Ask your Salesforce developer to change these URL references. After you change the URL references, consider enabling <a target='_blank' href='https://help.salesforce.com/articleView?id=domain_name_overview.htm&type=0&language=en_US&release=206.15'>My Domain</a> to personalize Salesforce for your company."
            },
            OptimizerPlusDetailImpact: {
                impact: "Hard-coded URLs can cause links to break.",
                note: "We found {0} more hard-coded URLs. You’ll need to resolve these issues to see the status of more URL types.",
                note2: "We don’t check for hard-coded URLs in package or feature integrations, workflows, Chatter posts, content URLs, Salesforce documents, or static content."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "My Domain URL Changes Documentation", link: "https://help.salesforce.com/HTViewHelpDoc?id=domain_name_app_url_changes.htm&language=en_US"},
                    { icon: "Document", title: "URL Class Developer Documentation", link: "https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_url.htm"},
                    { icon: "Trail", title: "User Authentication Trailhead", link: "https://trailhead.salesforce.com/modules/identity_login"}
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Salesforce Customizations Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=customization"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Advanced: Platform: Codebase Health Assessment Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/advanced-platform-codebase-health-assessment.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Hard-Coded URLs",
                tableHead: ["URL Type", "URL Reference", "Location in Salesforce"],
                note: "We found {0} more hard-coded URLs. You’ll need to resolve these issues to see the status of more URL types."

            }
        },
        "adapps__OptimizerPlus_Convert_Attach_To_Files__c": {
            OptimizerPlusDetailDescription: {
                title: "Convert Attachments to Files",
                observation: {
                    ready: "Great job! You don’t have any attachments.",
                    low_impact: "You have 1 attachment.",
                    multiple_low_impact: "You have {0} attachments.",
              },
                orgLink: "/lightning/setup/ApexTriggers/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Convert your existing notes and attachments to Salesforce Files with the <a target='_blank' href='https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EHAmyUAH'>Attachments to Files app</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "The Attachments object is no longer supported and will soon be replaced with Salesforce Files.",
                show_note: false
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Salesforce Files Documentation", link: "https://help.salesforce.com/articleView?id=collab_salesforce_files_parent.htm"},
                    { icon: "Document", title: "Moving Documents to Salesforce Files Documentation", link: "https://help.salesforce.com/articleView?id=docs_documents_to_files.htm&type=5"},
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "How to Successfully Transition to Lightning Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=lightning"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How to: Lightning Platform: Configuration and Customization Accelerator", link: "https://help.salesforce.com/articleView?id=How-to-Lightning-Platform-Configuration-and-Customization&language=en_US&type=1"}],
                }
            },
        },
        "adapps__OptimizerPlus_Notes_And_Attach__c": {
            OptimizerPlusDetailDescription: {
                title: "Notes and Attachments Related List",
                observation: {
                    ready: "Great job! You don’t have any page layouts that use the Notes and Attachments related list.",
                    low_impact: "You have 1 page layout that uses the Notes and Attachments related list.",
                    multiple_low_impact: "You have {0} page layouts that use the Notes and Attachments related list."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Convert your existing notes and attachments to Salesforce Files with the <a target='_blank' href='https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000EHAmyUAH'>Attachments to Files app</a>. Then, on all your page layouts, replace the Notes and Attachments related list with the Files related list."
            },
            OptimizerPlusDetailImpact: {
                impact: "In Lightning Experience, existing attachments in the Notes and Attachments related list are read only, and which actions users can take is limited. New attachments are uploaded as Files. The Files related list offers improved functionality, and it will eventually replace the Notes and Attachments related list.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Salesforce Files Documentation", link: "https://help.salesforce.com/articleView?id=collab_salesforce_files_parent.htm" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "How to Successfully Transition to Lightning Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=lightning"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Lightning Platform: Configuration Fast Start Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/accelerator-lightning-quickstart.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Notes and Attachments Related List",
                tableHead: ["Page Layout"],
            }
        },
        "adapps__OptimizerPlus_Disable_Debug_Mode__c": {
            OptimizerPlusDetailDescription: {
                title: "Disable Debug Mode",
                observation: {
                    ready: "You’ve already disabled debug mode.",
                    not_currently_enabled: "Increase productivity by disabling debug mode for users who aren’t actively debugging JavaScript.",
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine which users are actively debugging JavaScript. Disable debug mode for those who aren’t debugging."
            },
            OptimizerPlusDetailImpact: {
                impact: "Enabling debug mode makes it easier to debug JavaScript code from Lightning components. However, Salesforce is slower for users who have debug mode enabled, so enable only for users who need it.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Enable Debug Mode for Lightning Components", link: "https://developer.salesforce.com/docs/atlas.en-us.214.0.lightning.meta/lightning/aura_debug_mode.htm" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Ask Salesforce Anything Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=ask"}],
                }
            },
        },
        "adapps__OptimizerPlus_Unsupported_Browsers__c": {
            OptimizerPlusDetailDescription: {
                title: "Unsupported Browsers",
                observation: {
                    ready: "Great job! Your users access Salesforce with supported browsers.",
                    low_impact: "One user accessed Salesforce with an unsupported browser within the past 30 days.",
                    multiple_low_impact: "{0} users accessed Salesforce with an unsupported browser within the past 30 days."
                },
                orgLink: "/lightning/setup/OrgLoginHistory/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Ask users to upgrade their browser to one that supports Salesforce’s Lightning Experience."
            },
            OptimizerPlusDetailImpact: {
                impact: "Unsupported browsers don’t give users the most stability and security when they work in Salesforce.",
                note: "We found {0} more users who access Salesforce with unsupported browsers. You’ll need to resolve these issues to see the status of more users.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Supported Browsers Documentation", link: "https://help.salesforce.com/articleView?id=getstart_browser_overview.htm&type=5" },
                    { icon: "Document", title: "Recommendations and Requirements for All Browsers Documentation", link: "https://help.salesforce.com/articleView?id=getstart_browser_recommendations.htm&type=5" },
                ],
            },
            OptimizerPlusDetailList: {
                title: "Unsupported Browsers",
                tableHead: ["User", "Browser and Platform", "Last Used"],
                note: "We found {number} more users who access Salesforce with unsupported browsers. You’ll need to resolve these issues to see the status of more users."
            }
        },
        "adapps__OptimizerPlus_Out_Of_Date_Browsers__c": {
            OptimizerPlusDetailDescription: {
                title: "Out-of-Date Browsers",
                observation: {
                    ready: "Great job! Your users access Salesforce with up-to-date browsers.",
                    low_impact: "{0}% of users access Salesforce with out-of-date browsers.",
                    high_impact: "{0}% of users access Salesforce with out-of-date browsers.",
                    multiple_low_impact: "{0}% of users access Salesforce with out-of-date browsers.",
                    multiple_high_impact: "{0}% of users access Salesforce with out-of-date browsers."
                },
                orgLink: "/lightning/setup/OrgLoginHistory/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Ask users to upgrade to the latest version of a browser that supports Salesforce’s Lightning Experience."
            },
            OptimizerPlusDetailImpact: {
                impact: "Out-of-date browsers don’t give users the most stability and security when they work in Salesforce.",
                note: "We found {0} more users who access Salesforce with unsupported browsers. You’ll need to resolve these issues to see the status of more users.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Supported Browsers Documentation", link: "https://help.salesforce.com/articleView?id=getstart_browser_overview.htm&type=5" },
                    { icon: "Document", title: "Recommendations and Requirements for All Browsers Documentation", link: "https://help.salesforce.com/articleView?id=getstart_browser_recommendations.htm&type=5" },
                ],

            },
            OptimizerPlusDetailList: {
                title: "Out-of-Date Browsers",
                tableHead: ["User", "Browser and Platform", "Last Used"],
                note: "We found {number} more users who access Salesforce with unsupported browsers. You’ll need to resolve these issues to see the status of more users."
            }
        },
        "adapps__OptimizerPlus_Inactive_Chatter__c": {
            OptimizerPlusDetailDescription: {
                title: "Inactive Chatter Users",
                observation: {
                    ready: "Great job! All your users have contributed to Chatter within the past 30 days.",
                    low_impact: "{0}% of your users haven’t contributed to Chatter in the past 30 days.",
                    not_currently_enabled: "It looks like Chatter is disabled in your org. Enable Chatter, then run Optimizer again."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Remind users who haven’t logged in to Chatter recently to check their accounts regularly. Monitor your org’s Chatter engagement with <a target='_blank' href='https://appexchange.salesforce.com/listingDetail?listingId=a0N30000000pviyEAA'>Chatter dashboards</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "If users aren’t logging in and contributing regularly, your company might not be taking full advantage of Chatter’s benefits.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Chatter Overview Documentation", link: "https://help.salesforce.com/articleView?id=collab_overview.htm&type=5" },
                    { icon: "Trail", title: "Chatter Basics for Users Trailhead", link: "https://trailhead.salesforce.com/modules/chatter_basics_for_users/units/chatter_basics_for_users_basics" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Success with Chatter", link: "http://pages.mail.salesforce.com/gettingstarted/chatter/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Community Cloud: Plan Your Chatter Adoption Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/how-to-community-cloud-plan-your-chatter-adoption.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Incomplete_Chatter__c": {
            OptimizerPlusDetailDescription: {
                title: "Incomplete Chatter Profiles",
                observation: {
                    ready: "Great job! All your users have complete Chatter profiles.",
                    low_impact: "{0}% of your users haven’t completed their Chatter profiles.",
                    multiple_low_impact: "{0}% of your users haven’t completed their Chatter profiles.",
                    not_currently_enabled: "It looks like Chatter is disabled in your org. Enable Chatter, then run Optimizer again.",
                    profile_photo: "{0} of {1} users don’t have profile photos.",
                    about_me: "{0} of {1} users don’t have “About Me” sections."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Remind users who haven’t completed their profiles to update their information. Monitor your org’s Chatter engagement with <a target='_blank' href='https://appexchange.salesforce.com/listingDetail?listingId=a0N30000000pviyEAA'>Chatter dashboards</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "Users across your organization might have trouble finding who they need to talk to if users don’t have complete profiles.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                  { icon: "Document", title: "Chatter Overview Documentation", link: "https://help.salesforce.com/articleView?id=collab_overview.htm&type=5" },
                  { icon: "Trail", title: "Chatter Basics for Users Trailhead", link: "https://trailhead.salesforce.com/modules/chatter_basics_for_users/units/chatter_basics_for_users_basics" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Welcome to Getting Started with Chatter!", link: "http://pages.mail.salesforce.com/gettingstarted/chatter/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Community Cloud: Plan Your Chatter Adoption Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/how-to-community-cloud-plan-your-chatter-adoption.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Incomplete Chatter Profiles",
                tableHead: ["User", "No Profile Photo", "No “About Me”"],
            }
        },
        "adapps__OptimizerPlus_Files_Adoption__c": {
            OptimizerPlusDetailDescription: {
                title: "Files Adoption",
                observation: {
                    ready: "Great job! All your users have used Files in the past 30 days.",
                    low_impact: "{0}% of your users have used Files in the past 30 days."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Remind your users about the benefits of using Salesforce Files to manage and collaborate on documents and files in Salesforce. Let them know that Salesforce Files lets you share and collaborate on files, store files privately, manage version updates, associate files with other records, and connect to external file systems right from Salesforce. <br/>If your org currently uses Documents, make time to move most of your documents to Files. Your users will be more productive in Lightning Experience with all their files at their fingertips."
            },
            OptimizerPlusDetailImpact: {
                impact: "If your users aren’t using Files to manage their documents, your sensitive customer data might be at risk. Salesforce Files are the best way to save, organize, and share files in Salesforce. Salesforce Files will continue to see improvements."
            },
            OptimizerPlusDetailResources: {
                resources: [
                  { icon: "Document", title: "Salesforce Files Documentation", link: "https://help.salesforce.com/articleView?id=collab_salesforce_files_parent.htm" },
                  { icon: "Document", title: "Moving Documents to Salesforce Files Documentation", link: "https://help.salesforce.com/articleView?id=docs_documents_to_files.htm" },
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "How to Successfully Transition to Lightning Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=prepare%20for%20your%20lightning"}],
                    premier: [{ icon: "Webinar", title: "How to Successfully Transition to Lightning Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=prepare%20for%20your%20lightning"}],
                }
            },
        },
        "adapps__OptimizerPlus_Lightning_Sales_Con__c": {
            OptimizerPlusDetailDescription: {
                title: "Lightning Sales Console",
                observation: {
                    unable_timeout: "A timeout error occurred when evaluating your org for Lightning Sales Console. This section was removed from your report.",
                    unable_too_many: "A timeout error occurred when evaluating your org for Lightning Sales Console. This section was removed from your report.",
                    not_currently_enabled: "One profile can benefit from using the Lightning Sales Console.",
                    multiple_not_currently_enabled: "{0} profiles can benefit from using the Lightning Sales Console.",
                    ready: "Great job! You already enabled the Lightning Console app for users."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Give these profiles access to the <a target='_blank' href='https://help.salesforce.com/articleView?id=console_lex_sales_intro.htm&type=0&language=en_US&release=208.10'>Lightning Console app</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "The Lightning Sales Console is a Salesforce Lightning app that gives your sales reps easy access to sales tools."
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Lightning Sales Console Documentation", link: "https://help.salesforce.com/articleView?id=console_lex_sales_intro.htm&type=5" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Sales Cloud Success", link: "http://pages.mail.salesforce.com/gettingstarted/home/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "Getting Started: Sales Cloud: Console Design Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/getting-started-sales-cloud-console-design.pdf"}],
                }
            },
            OptimizerPlusDetailList: {
                title: "Lightning Sales Console",
                tableHead: ["Profile", "User", "Most-used Object", "Number of Updates"],
            }
        },
        "adapps__OptimizerPlus_Path_Assistant__c": {
            OptimizerPlusDetailDescription: {
                title: "Path",
                observation: {
                    unable_timeout: "A timeout error occurred while evaluating your org for Path. This section was removed from your report.",
                    unable_too_many: "A timeout error occurred while evaluating your org for Path. This section was removed from your report.",
                    not_currently_enabled: "Increase your users’ productivity by enabling Path on {0} of your top 5 objects.",
                    multiple_not_currently_enabled: "Increase your users’ productivity by enabling Path on {0} of your top 5 objects.",
                    ready: "Great job! You already enabled Path."

                },
                orgLink: "/lightning/setup/PathAssistantSetupHome/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether to <a target='_blank' href='https://help.salesforce.com/articleView?id=rss_sales_path.htm&language=en_US&type=0'>enable Path</a> on these objects."
            },
            OptimizerPlusDetailImpact: {
                impact: "Path guides your users along the steps in a process, such as working an opportunity from a fresh lead to a successfully closed deal.",
                show_graph: false
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Guide Users with Path Documentation", link: "https://help.salesforce.com/articleView?id=path_overview.htm&type=0&language=en_US&release=208.10" },
                    { icon: "Trail", title: "Path and Workspaces Trailhead", link: "https://trailhead.salesforce.com/modules/sales_admin_optimize_salesforce_for_selling" },
                    { icon: "Trail", title: "Customize a Sales Path for Your Team Trailhead", link: "https://trailhead.salesforce.com/projects/customize-a-sales-path-for-your-team" },
                ],
                top_resources: {
                    standard: [{ icon: "Video", title: "Get Going with Lightning, Now! Video", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.video&search=get%20going"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Sales Cloud: Design Lightning Desktop Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/accelerator-sales-cloud-lightning-desktop-design.pdf"}]
                }
            },
            OptimizerPlusDetailList: {
                title: "Path",
                tableHead: ["Objects That Aren’t Using Path"]
            }
        },
        "adapps__OptimizerPlus_Duplicate_Management__c": {
            OptimizerPlusDetailDescription: {
                title: "Duplicate Management",
                observation: {
                    not_currently_enabled: "Your sales team might benefit from duplicate management rules on objects.",
                    ready: "Great job! You already have duplicate and matching rules set up."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "<a target='_blank' href='https://help.salesforce.com/articleView?id=duplicate_prevention_map_of_tasks.htm&type=0'>Create duplicate rules and matching rules</a> to help your sales reps identify records that contain similar information."
            },
            OptimizerPlusDetailImpact: {
                impact: "Duplicate Management helps your sales teams keep your leads, accounts, and contacts clutter free.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Manage Duplicate Records Documentation", link: "https://help.salesforce.com/articleView?id=managing_duplicates_overview.htm&type=0" },
                    { icon: "Trail", title: "Duplicate Management Trailhead", link: "https://trailhead.salesforce.com/modules/sales_admin_duplicate_management" },
                    { icon: "Trail", title: "Data Quality Trailhead", link: "https://trailhead.salesforce.com/modules/data_quality" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Become a Data Management Rockstar Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/#&eventType=.virtual&search=data%20management"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Sales Cloud: Prevent Duplicate Records Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/how-to-sales-cloud-prevent-duplicate-records.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Service_Cloud_Console__c": {
            OptimizerPlusDetailDescription: {
                title: "Lightning Service Console",
                observation: {
                    not_currently_enabled: "Your support reps might benefit from the Lightning Service Console.",
                    ready: "Great job! You already enabled Lightning Service Console for users."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailImpact: {
                impact: "The Lightning Service Console is a Salesforce Lightning app that gives your support agents easy access to service tools.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Lightning Service Console Documentation", link: "https://help.salesforce.com/articleView?id=console_lex_service_intro.htm&type=5" },
                    { icon: "Document", title: "Set Up and Configure Features in the Lightning Service Console Documentation", link: "https://help.salesforce.com/articleView?id=console_lex_service_setup.htm&type=0&language=en_US&release=208.16" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Service Cloud Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&product=.ServiceCloud&search=Getting%20Started%20with%20Service%20Cloud"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How to: Service Cloud: Design Your Lightning Console Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/svc-lightning-console-design.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Case_Feed__c": {
            OptimizerPlusDetailDescription: {
                title: "Case Feed",
                observation: {
                    not_currently_enabled: "Your support reps might benefit from Case Feed.",
                    ready: "Great job! You already enabled Case Feed."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "<a target='_blank' href='https://help.salesforce.com/articleView?id=case_interaction_enabling.htm'>Enable Case Feed</a> for your support reps."
            },
            OptimizerPlusDetailImpact: {
                impact: "Case Feed gives support agents a more streamlined way of creating, managing, and viewing cases with actions and a Chatter feed.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Enable Case Feed Actions and Feed Items Documentation", link: "https://help.salesforce.com/articleView?id=case_interaction_enabling.htm" },
                    { icon: "Trail", title: "Case Feed Trailhead", link: "https://trailhead.salesforce.com/en/modules/service_casefeed_basics" },
                    { icon: "Trail", title: "Service Cloud Transition to Lightning Experience Trailhead", link: "https://trailhead.salesforce.com/modules/service_trans" }
                ],
                top_resources: {
                    standard: [{ icon: "Webinar", title: "Getting Started with Service Cloud Circles of Success Webinar", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&eventType=.virtual&product=.ServiceCloud&search=Getting%20Started%20with%20Service%20Cloud"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How to: Service Cloud: Design Your Lightning Console Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/svc-lightning-console-design.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Omni_Channel__c": {
            OptimizerPlusDetailDescription: {
                title: "Omni-Channel",
                observation: {
                    not_currently_enabled: "Your support reps might benefit from Omni-Channel.",
                    ready: "Great job! You already enabled Omni-Channel."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether to <a target='_blank' href='https://help.salesforce.com/articleView?id=service_presence_intro.htm'>enable Omni-Channel</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "Omni-Channel is a comprehensive customer service solution that lets your call center route incoming work items—including cases, chats, and leads—to the most qualified, available agents in your organization.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Omni-Channel for Administrators Documentation", link: "https://help.salesforce.com/articleView?id=service_presence_intro.htm" },
                    { icon: "Trail", title: "Deliver Omni-Channel Service Trailhead", link: "https://trailhead.salesforce.com/modules/service-cloud-platform-quick-look/units/deliver-omnichannel-service" },
                ],
                top_resources: {
                    standard: [{ icon: "Video", title: "Omni-Channel Routing Review Video", link: "http://pages.mail.salesforce.com/cloud-services/event-calendar/?region=ALL#&search=omni"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Service Cloud: Automate Work Distribution with Omni-Channel Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/how-to-service-cloud-automate-work-distribution-with-omni-channel.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Keyboard_Shortcuts__c": {
            OptimizerPlusDetailDescription: {
                title: "Keyboard Shortcuts",
                observation: {
                    not_currently_enabled: "Your support reps might benefit from keyboard shortcuts.",
                    ready:"Great job! You already created custom keyboard shortcuts."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether to <a target='_blank' href='https://help.salesforce.com/articleView?id=accessibility_keyboard_shortcuts.htm'>create custom keyboard shortcuts</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "Keyboard shortcuts help your agents work faster while they work in the Lightning Service Console.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Keyboard Shortcuts Documentation", link: "https://help.salesforce.com/articleView?id=accessibility_keyboard_shortcuts.htm&type=5" },
                    { icon: "Trail", title: "Customize Keyboard Shortcuts for Agents Trailhead", link: "https://trailhead.salesforce.com/en/modules/service_console_customize/units/service_console_customize_key" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Welcome to Getting Started with Service Cloud!", link: "http://pages.mail.salesforce.com/gettingstarted/service-cloud/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How to: Service Cloud: Design Your Lightning Console Accelerator", link: "https://www.salesforce.com/assets/pdf/cloud-services/svc-lightning-console-design.pdf"}],
                }
            },
        },
        "adapps__OptimizerPlus_Macros__c": {
            OptimizerPlusDetailDescription: {
                title: "Macros",
                observation: {
                    not_currently_enabled: "Your support reps might benefit from macros.",
                    ready: "Great job! You already enabled macros."
                },
                orgLink: "/lightning/setup/ObjectManager/home"
            },
            OptimizerPlusDetailRecommendation: {
                recommendation_top: "Determine whether to <a target='_blank' href='https://help.salesforce.com/articleView?id=macros_getting_started.htm'>enable macros</a>."
            },
            OptimizerPlusDetailImpact: {
                impact: "Support agents who use Case Feed can run macros to complete repetitive tasks, such as selecting an email template, sending an email to a customer, and updating the case status, all in a single click.",
            },
            OptimizerPlusDetailResources: {
                resources: [
                    { icon: "Document", title: "Set Up and Use Macros Documentation", link: "https://help.salesforce.com/articleView?id=macros_def.htm&type=5" },
                    { icon: "Document", title: "Create Macros in Lightning Experience Documentation", link: "https://help.salesforce.com/articleView?id=macros_create_lightning.htm&type=5" },
                    { icon: "Trail", title: "Get Started with Macros Trailhead", link: "https://trailhead.salesforce.com/en/modules/service_macros/units/service_macros_define" },
                    { icon: "Trail", title: "Automate Case Management Trailhead", link: "https://trailhead.salesforce.com/en/modules/service_basics/units/service_basics_automate_case_management" },
                ],
                top_resources: {
                    standard: [{ icon: "Questions_and_Answers", title: "Welcome to Getting Started with Service Cloud!", link: "http://pages.mail.salesforce.com/gettingstarted/service-cloud/"}],
                    premier: [{ icon: "Questions_and_Answers", title: "How To: Service Cloud: Case Macro Design Accelerator", link: "https://www.salesforce.com/content/dam/web/en_us/www/documents/accelerators/how-to-service-cloud-case-macro-design.pdf"}],
                }
            },
        },








};
    return {
        getData: function() {
            return data;
        }
    };

}());
