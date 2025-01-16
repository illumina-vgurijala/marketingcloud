var DeliveryOptionNameToType = {
    Unknown: 0,
    Normal: 1,
    
    // The following four are fake delivery option for client app to handle UI consistantly  
    AddPersonalCollection: 50,
    RemovePersonalContent: 51,
    MovePersonalContent: 52,
    ChangePersonalContentName: 53,
    EditPersonalContent: 54,
    
    Download: 101,
    SendByEmail: 102,
    CreateSharedLink: 103,
    SaveToPersonal: 105,
    SendToLiveShare: 106,
    SendToCart: 107,
    SendToLiveSend: 108,
    SendToGmail: 109,
    
    SendToSalesforce: 111,
    SendToSharePoint: 112,
    
    SFSendByEmail: 131,
    SFPostToChatter: 132,
    SFSaveAttachment: 133,
    SFCreateContent: 134,
    SFCreateContentDelivery: 135,
    
    // 141 - 150 for iPad
    iPadSendByEmail: 141,
    iPadOpenWith: 142,
    iPadPrint: 143
    
    // Id 200 - 210 is reserved for iPad auto-support system delivery options
};

var DeliveryOptionIconNames = {
    0 : "DO_NORMAL",
    1 : "DO_NORMAL",
    50 : "DO_ADD",
    52 : "DO_MOVE",
    54 : "DO_EDIT",
    101 : "DO_DOWNLOAD",
    102 : "DO_EMAIL",
    105 : "DO_SAVE_PERSONAL",
    106 : "DO_SHARE",
    107 : "DO_CART",
    108 : "DO_LIVESEND",
    131 : "DO_EMAIL",
    999 : "DO_DELETE"
};

var DeliveryOptionIconNameMapping = {
    Unknown: "",
    Normal: "",
    Download: "glyphicon-download",
    SendByEmail: "glyphicon-envelope",
    CreateSharedLink: "",
    SaveToPersonal: "glyphicon-folder-close",
    SendToLiveShare: "glyphicon-share",
    SendToCart: "glyphicon-shopping-cart",
    SendToLiveSend: "glyphicon-send",
    SendToGmail: "glyphicon-envelope",
    
    // The "following" four are fake delivery option for client app to handle UI consistantly  
    AddPersonalCollection: "",
    RemovePersonalContent: "",
    MovePersonalContent: "",
    ChangePersonalContentName: "",
    EditPersonalContent: "",
    SendToSalesforce: "",
    SendToSharePoint: "",
    
    // Id "200" - 210 is reserved for iPad auto-support system delivery options

    SFSendByEmail: "glyphicon-envelope",
    SFPostToChatter: "",
    SFSaveAttachment: "",
    SFCreateContent: "",
    SFCreateContentDelivery: "",

    FullScreen: "glyphicon-fullscreen"
};

var DirectRequestFormType = {
    NoInput : 0,
    SFIndexFieldOnly : 1,
    Invalid : 99
};

var DeliveryOptionNameToTypeToName = {
    "0": "Unknown",
    "1": "Normal",
    "101": "Download",
    "102": "SendByEmail",
    "103": "CreateSharedLink",
    "105": "SaveToPersonal",
    "106": "SendToLiveShare",
    "107": "SendToCart",
    "108": "SendToLiveSend",
    "109": "SendToGmail",
    // The following four are fake delivery option for client app to handle UI consistantly 
    "50": "AddPersonalCollection",
    "51": "RemovePersonalContent",
    "52": "MovePersonalContent",
    "53": "ChangePersonalContentName",
    "54": "EditPersonalContent",
    "111": "SendToSalesforce",
    "112": "SendToSharePoint",
    // Id 200 - 210 is reserved for iPad auto-support system delivery options

    "131": "SFSendByEmail",
    "132": "SFPostToChatter",
    "133": "SFSaveAttachment",
    "134": "SFCreateContent",
    "135": "SFCreateContentDelivery",

    "FullScreen": "FullScreen"
};

var DELIVERY_OPTION_DEFAULT_ICON_NAME = "glyphicon-link";

var DocumentTypes = {
    UNKNOWN: 0,
    PRESENTATION: 1,
    MSWORD: 2,
    PDF: 3,
    IMAGE: 4,
    VIDEO: 5,
    EXCEL: 6,
    BUNDLE: 10,
    SLIDE : 11,
    MULTISLIDES : 12,
    TABLE : 13,
    CHART : 14,
    EXCELCHART : 15,
    SMARTART : 16,
    TEXT : 17,
    DATASOURCE : 18,
    SHAREABLETEXT : 19,
    LIVEIMAGE : 20,
    URL : 21,
    OTHER: 99
};

var DocumentFormats = {
    DEFAULT: 0,
    PPT: 1,
    PPTX: 2,
    DOC: 3,
    DOCX: 4,
    JPG: 5,
    JPEG: 6,
    PNG: 7,
    BMP: 8,
    AVI: 9,
    MPEG4: 10,
    MP4: 11,
    MP3: 12,
    WAV: 13,
    PDF: 14,
    BUNDLE: 15,
    IMAGE: 16,
    GIF: 17,
    TIF: 18,
    TIFF: 19,
    ZIP: 20,
    XLSX: 21,
    XLS: 22,
    M4V: 23,
    PPTXTABLE: 30,
    DOCXTABLE: 31,
    YOUTUBE: 32,
    VIMEO: 33,
    MPG: 34,
    MPA: 35,
    MPE: 36,
    RM: 37,
    RAM: 38,
    ASF: 39,
    MOV: 40,
    VOB: 41,
    WMV: 42,
    V3GP: 43,
    TXT: 44,
    URL: 45,
    UNKNOWN: 99
};

var FORMATS_TO_NAME = {
    0: "DEFAULT",
    1: "PPT",
    2: "PPTX",
    3: "DOC",
    4: "DOCX",
    5: "JPG",
    6: "JPEG",
    7: "PNG",
    8: "BMP",
    9: "AVI",
    10: "MPEG4",
    11: "MP4",
    12: "MP3",
    13: "WAV",
    14: "PDF",
    15: "BUNDLE",
    16: "IMAGE",
    17: "GIF",
    18: "TIF",
    19: "TIFF",
    20: "ZIP",
    21: "XLSX",
    22: "XLS",
    23: "M4V",
    30: "PPTXTABLE",
    31: "DOCXTABLE",
    32: "YOUTUBE",
    33: "VIMEO",
    34: "MPG",
    35: "MPA",
    36: "MPE",
    37: "RM",
    38: "RAM",
    39: "ASF",
    40: "MOV",
    41: "VOB",
    42: "WMV",
    43: "3GP", // "V3GP"
    44: "TXT",
    45: "URL",
    99: "UNKNOWN"
};

var LiveSendContentType = {
    LIBRARY: 0,
    GENERATED_DOC: 1,
    PERSONAL_CONTENT: 2,
    PERSONAL_FOLDER: 3
}