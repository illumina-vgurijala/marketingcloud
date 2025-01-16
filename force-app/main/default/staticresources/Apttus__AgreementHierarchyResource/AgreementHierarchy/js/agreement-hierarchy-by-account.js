/*  
Apttus Contract Management
agreement-hierarchy-by-account

@2019 Apttus Inc. All rights reserved.
*/

var apexCallController = {};
var apexMethodGetChildPrefix = "getchildren";

var slideAnimationMilliSeconds = 200;
var slideAnimationEasingOption = "swing";
var opacityDeltaAmend = 2;
var initialOpacityForPastAgr = 80;
var endOpacityForPastAgr = 50;

var popupChildStructure =
    "<ul>" +
    "<li><div id='popup-related-group'></div></li>" +
    "<li><div id='popup-child-group'></div></li>" +
    "</div></li>" +
    "</ul>";

var relatedDom = null;
var amendDom = null;
var childDom = null;

function onExpandComplete() {
    if (!this.childAgreements[0]) {
        return false;
    }
    if (!this.childAgreements[1] && this.childAgreements[1].length == 0) {
        return false;
    }

    var agreementId = this.childAgreements[0];
    var childAgreements = this.childAgreements[1];
    createRenderRootAgreements("#" + agreementId, childAgreements);

    if (apexCallController[apexMethodGetChildPrefix + agreementId]) {
        delete apexCallController[apexMethodGetChildPrefix + agreementId];
    }

    var $li = $("#" + agreementId);
    var $currentTarget = $li.find(".expand-collapse-icon:first");
    $currentTarget.addClass("flip");
}

$(window).resize(function () {
    initDocumentDisplay();
});

function initDocumentDisplay() {
    var height = $(window).height() - $('#container').position().top - 50;
    document.getElementById('container').style.height = height + 'px';


    var area = document.querySelector('.zoomable');
    var dims = area.getBoundingClientRect();
    const pzInstance = panzoom(area, {
        maxZoom: 1.2,
        minZoom: 0.7,
        zoomSpeed: 0.035, // 6.5% per mouse wheel event
        onDoubleClick: function (e) { return true; },
        zoomDoubleClickSpeed: 1,
        bounds: {
            top: height / 2,
            left: dims.width / 2,
            right: dims.width / 2,
            bottom: height / 2,
        }
    });
}

$(document).ready(function () {

    initDocumentDisplay();
    createAccount("#root-account", accountDetails);
    createRenderRootAgreements("#root-account", agreementDetails);

    //for elipsis
    $(document).on("mouseenter", "p", function () {
        var $this = $(this);
        if (this.offsetWidth < this.scrollWidth && !$this.attr("title")) {
            $this.attr("title", $this.text());
        }
    });

    function onExpandClick(event) {
        var $currentTarget = $(event.currentTarget);
        var $li = $currentTarget.closest("li");
        var $ulChildren = $li.children("ul");

        if ($currentTarget.hasClass("collapsed")) {
            $currentTarget.removeClass("collapsed").addClass("expanded");

            if ($ulChildren.length > 0) {
                $ulChildren.slideDown(slideAnimationMilliSeconds, slideAnimationEasingOption);
                $currentTarget.addClass("flip");
            } else {
                var agreementId = $li.attr("id");
                //If process is still running to get child agreement for same agreement.
                if (apexCallController[apexMethodGetChildPrefix + agreementId]) {
                    return false;
                }
                apexCallController[apexMethodGetChildPrefix + agreementId] = true;
                getChildAgreementsFromAgreement(agreementId);
            }
        }
        else {
            $ulChildren.slideUp(slideAnimationMilliSeconds, slideAnimationEasingOption);
            $currentTarget.removeClass("flip");
            $currentTarget.removeClass("expanded").addClass("collapsed");
        }
    }

    $("#container").on("click", ".expand-collapse-icon", onExpandClick);
    bindDropButtonClick();

    $("#container").on("click touchstart", ".show-record", function (event) {
        event.preventDefault();
        event.stopPropagation();
        window.open(salesforceUrl + $(event.currentTarget).data("agid"));
        removeExistingDropDowns();
    });

    $("#container").on("click touchstart", ".show-popup", function (event) {
        event.preventDefault();
        event.stopPropagation();
        viewRelatedRecord($(event.currentTarget).data("agid"));
        removeExistingDropDowns();
    });

});

function createAccount(domIdentifier, accountDetails) {
    accountDetails["account"] = true;
    $(domIdentifier).append(createAgreementNode(accountDetails));
}

function createAgreementNode(agreementDetail) {
    if (agreementDetail[0]) {
        var agrementDetailString = "";
        if (agreementDetail[0]) {
            for (var i = 2; i < agreementDetail.length; i++) {
                agrementDetailString +=
                    "<p class='agreement-detail bg-white'>" + agreementDetail[i] + "</p>";
            }
        }

        var showMoreClass = "";
        if (agreementDetail["show-more"] && agreementDetail["show-more"] == true) {
            showMoreClass = "parent-show-more";
        }

        var idString = ""
        if (agreementDetail["parent-id"]) {
            idString = " id='" + agreementDetail["parent-id"] + "' ";
        }
        var styleString = "";
        if (agreementDetail["skip"] && agreementDetail["skip"] == true) {
            styleString = " style='display:none;' ";
        }

        var agreementIcon = agreementIconFromResource;
        var agreementIconClass = "document-icon";
        if (agreementDetail["account"] && agreementDetail["account"] == true) {
            agreementIcon = accountIconFromResource;
            agreementIconClass = "account-icon";
        }

        var rect =
            "<div " + idString + styleString + " class='rectangle " + showMoreClass + "' data-id='" + agreementDetail[0] + "' data-title='" + agreementDetail[1] + "'>" +
            "<div class='icon'>" +
            "<img class='" + agreementIconClass + "'  src='" +
            agreementIcon +
            "'>" +
            "</div>" +
            "<div class='detail'>" +
            "<p class='agreement-name bg-white'>" +
            agreementDetail[1] +
            "</p>" +
            agrementDetailString +
            "</div>" + createMenu(agreementDetail[0], agreementDetail["account"]) +
            "</div>";
        return rect;
    }
}

function createMenu(agreementId, isAccount) {

    var showRelatedAgreement = (isAccount && isAccount == true) ? '' : "<a class='show-popup' data-agid='" + agreementId + "'>" + labelShowRelatedAgreements + "</a>";
    return "<div class='dropdown'>" +
        "<div class='dropbtn'><img class='down-icon' src='" + downArrowIconFromResource + "' </img> </div>" +
        "<div class='dropdown-content' style='background-color:white !important'>" +
        "<a class='show-record' data-agid='" + agreementId + "'>" + labelViewRecord + "</a>" +
        showRelatedAgreement +
        "</div>" +
        "</div>";
}

function createRenderRootAgreements(domId, agreementsDetails) {
    var agreementString = "";
    for (i = 0; i < agreementsDetails.length; i++) {
        var agreementsDetail = agreementsDetails[i];
        if (agreementsDetail) {
            agreementString += "<ul><li id= '" + agreementsDetail[0] + "-" + Math.round(Math.random() * 1000) + "'>" + createAgreementNodeForAccount(agreementsDetails[i]) + "</ul></li>";
        }
    }
    var $agreementNode = $(agreementString).hide();
    $(domId).append($agreementNode);
    $agreementNode.slideDown(slideAnimationMilliSeconds, slideAnimationEasingOption, function () {
        bindDropButtonClick();
    });
}

function createAgreementNodeForAccount(agreementDetail) {
    if (agreementDetail[0]) {
        var agrementDetailString = "";

        for (var i = 3; i < agreementDetail.length; i++) {
            agrementDetailString +=
                "<p class='agreement-detail bg-white'>" + agreementDetail[i] + "</p>";
        }

        var idString = "";
        if (agreementDetail[0]) {
            idString = " id='" + agreementDetail[0] + "' ";
        }

        var agreementIcon = agreementIconFromResource;
        if (agreementDetail["account"] && agreementDetail["account"] == true) {
            agreementIcon = accountIconFromResource;

        }

        var expandDom = "<div class='space20'></div>";
        if (agreementDetail[1] && agreementDetail[1] != "0") {
            expandDom = '<svg class="expand-collapse-icon collapsed" viewBox="0 0 52 52"><path d="m17.9 4.4l20.7 20.5c0.6 0.6 0.6 1.6 0 2.2l-20.7 20.5c-0.6 0.6-1.6 0.6-2.2 0l-2.2-2.2c-0.6-0.6-0.6-1.6 0-2.2l16.3-16.1c0.6-0.6 0.6-1.6 0-2.2l-16.2-16.1c-0.6-0.6-0.6-1.6 0-2.2l2.2-2.2c0.6-0.5 1.5-0.5 2.1 0z"></path></svg>'
        }

        var rect =
            "<div " + idString + " class='rectangle' data-id='" + agreementDetail[0] + "' data-title='" + agreementDetail[1] + "'>" +
            "<div class='icon'>" +
            "<img class='document-icon'  src='" +
            agreementIcon +
            "'>" +
            "</div>" +
            "<div class='detail'>" +
            "<p class='agreement-name bg-white'>" +
            agreementDetail[2] +
            "</p>" +
            agrementDetailString +
            "</div>" + createMenu(agreementDetail[0], agreementDetail["account"]) +
            "</div>";
        rect = "<div class='rect-main'><div class='line'><div class='line1'></div><div class='line2'></div></div>" + expandDom + rect + "</div>"

        return rect;
    }
}

function openDialogWrapper() {
    $("#dialog").dialog({
        autoOpen: true,
        modal: true,
        open: openDialog,
        height: 'auto',
        width: 'auto',
        title: popupName
    });
}

function openDialog() {
    var win = $(window);

    var area = document.querySelector('#popup-tree');
    var popupHeight = (win.height() - 100);
    panzoom(area, {
        maxZoom: 1.1,
        minZoom: 0.8,
        zoomSpeed: 0.065, // 6.5% per mouse wheel event
        onDoubleClick: function (e) { e.preventDefault(); e.stopPropagation(); return false; },
        bounds: {
            top: popupHeight / 3,
            left: 100,
            right: 100,
            bottom: popupHeight / 3,
        }
    });

    $(this).parent().css({
        position: 'fixed',
        left: (win.width() - 800) / 2,
        top: 20,

    });

    $(this).css({
        height: win.height() - 100,
        overflow: 'hidden'
    })

    $('.ui-widget-overlay').on('click', function () {
        $('#dialog').dialog('close');
    });

    $('.ui-widget-overlay').addClass('custom-overlay');

    $("#popup-tree").empty();

    createParentAgreements("#popup-tree", "popup-", parentDetailsForRelatedRecord, popupChildStructure);

    $("#popup-related-group")
        .addClass("treeNode")
        .html(createHeader(labelRelatedAgreements, "child-header"));
    renderRelatedItems("#popup-related-group", 0, 2, relatedDetailsForRelatedRecord);

    $("#popup-child-group")
        .addClass("treeNode")
        .html(createHeader(labelChildAgreements, "child-group-header"));
    renderChildAgreements("#popup-child-group", 0, 2, childDetailsForRelatedRecord);

    $("#popup-child-group").on("click", ".show-more", { "nodeSelector": "#popup-child-group", "details": childDetailsForRelatedRecord }, showMoreChildDetailsForRelatedRecord);
    $("#popup-related-group").on("click", ".show-more", { "nodeSelector": "#popup-related-group", "details": relatedDetailsForRelatedRecord }, showMoreRelatedDetailsForRelatedRecord);
}

function createParentAgreements(nodeSelector, classPrefix, parentDetails, childStructure, skipFrom, skipTo) {
    var pointToDeepestLi = null;
    var isSkip = false;
    for (var i = 0; i < parentDetails.length; i++) {
        isSkip = false;
        if (skipFrom && skipTo && i >= skipFrom && i <= skipTo && skipFrom <= skipTo) {
            isSkip = true;
        }

        var parentDetail = parentDetails[i];
        if (skipTo && i == (skipTo + 1) && parentDetail.length > 3) {
            parentDetail["show-more"] = true;
        }

        var $ul = $("<ul>").attr("id", "parent-ul-" + i.toString());

        if (isSkip) {
            $ul.attr("style", "padding:0");
        }

        var $li = $("<li>");

        parentDetail["parent-id"] = "parent-rect-" + i.toString();
        parentDetail["skip"] = isSkip;

        $li.html(createAgreementNode(parentDetail));
        if (i == 0) {
            $li.attr("id", classPrefix + "account");
        }
        if (i == parentDetails.length - 1) {
            $li.attr("id", classPrefix + "root");
            $li.append(childStructure);
        }
        $ul.append($li);
        if (pointToDeepestLi == null) {
            $(nodeSelector).append($ul);
        } else {
            pointToDeepestLi.append($ul);
        }
        pointToDeepestLi = $li;
    }
}

function createHeader(headerName, className) {
    return (
        "<div class='" +
        className +
        "'><p>" +
        headerName +
        "&nbsp&nbsp</p>" +
        "</div>"
    );
}

function showMoreChildDetailsForRelatedRecord(event) {
    showMoreDetail("#popup-child-group", childDetailsForRelatedRecord);
}

function showMoreRelatedDetailsForRelatedRecord(event) {
    showMoreDetail("#popup-related-group", relatedDetailsForRelatedRecord);
}

function showMoreDetail(nodeSelector, details) {
    var nodeCount = $(nodeSelector + " .rectangle").length;
    if (nodeCount < details.length) {
        renderChildAgreements(nodeSelector, nodeCount, details.length - 1, details);
        bindDropButtonClick();
    }
}

function bindDropButtonClick() {
    $(".dropbtn").on("click touchstart", function (event) {
        event.preventDefault();
        event.stopPropagation();
        event.stopImmediatePropagation();
        removeExistingDropDowns();
        $(event.currentTarget).toggleClass("show");
        $(event.currentTarget).siblings(".dropdown-content").toggleClass("show");
        return false;
    });
}

window.onclick = function (event) {
    if (!event.target.matches('.dropbtn')) {
        removeExistingDropDowns();
    }
}

function removeExistingDropDowns() {
    var dropdowns = document.getElementsByClassName("dropdown-content");
    var i;
    for (i = 0; i < dropdowns.length; i++) {
        var openDropdown = dropdowns[i];
        if (openDropdown.classList.contains('show')) {
            openDropdown.classList.remove('show');
        }
    }
    var buttons = document.getElementsByClassName("dropbtn");
    var i;
    for (i = 0; i < buttons.length; i++) {
        var openButton = buttons[i];
        if (openButton.classList.contains('show')) {
            openButton.classList.remove('show');
        }
    }
}

function renderChildAgreements(nodeSelector, from, to, childDetails) {
    $(nodeSelector)
        .find(".show-more")
        .removeClass("show-more");
    if (childDetails && childDetails.length == 0) {
        $(nodeSelector).append("<div class='not-found'>" + labelNoChildAgreements + "</div>");
    }
    if (to > childDetails.length - 1) {
        to = childDetails.length - 1;
    }
    for (var i = from; i <= to; i++) {
        $(nodeSelector).append(createAgreementNode(childDetails[i]));
    }
    if (to < childDetails.length - 1) {
        $(nodeSelector + " .rectangle")
            .last()
            .addClass("show-more");
    }
}

function renderRelatedItems(nodeSelector, from, to, relatedDetails) {
    $(nodeSelector)
        .find(".show-more")
        .removeClass("show-more");

    if (relatedDetails && relatedDetails.length == 0) {
        $(nodeSelector).append("<div class='not-found'>" + labelNoRelatedAgreements + "</div>");
    }
    if (to > relatedDetails.length - 1) {
        to = relatedDetails.length - 1;
    }
    for (var i = from; i <= to; i++) {
        $(nodeSelector).append(createAgreementNode(relatedDetails[i]));
    }
    if (to < relatedDetails.length - 1) {
        $(nodeSelector + " .rectangle")
            .last()
            .addClass("show-more");
    }
}