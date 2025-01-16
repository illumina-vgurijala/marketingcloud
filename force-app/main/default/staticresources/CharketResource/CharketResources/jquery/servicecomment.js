function refreshPage() {
    showLoading();
    refreshComments();
}

function showDelFileBtn(fileSelectId) {
    var thisfile = jQuery("." + fileSelectId)[0];
    if (thisfile.files[0].name != "") {
        jQuery("." + fileSelectId).parent().parent().find(".label").show();
    }
    else {
        jQuery("." + fileSelectId).parent().parent().find(".label").hide();
    }
}

function removeFileSelect(fileSelectId) {
    jQuery("." + fileSelectId).val("");
    jQuery("." + fileSelectId).parent().parent().find(".label").hide();
}

function showReplyBox() {
    jQuery(".wj-box").show();
    jQuery(".page-zj").css("margin-bottom", "145px");
    jQuery("#commentBody").focus();
    jQuery("#commentBody").css("color", "black");
}

function createCommentAndFile(newCommentBody, caseId, currentFollowerName) {
    showLoading();
    var replyCaseCommentId = jQuery("[id$='replyCaseCommentId']").val();
    try {
        CharketServiceRequestCommentController.saveTheComment(
            newCommentBody,
            caseId,
            currentFollowerName,
            replyCaseCommentId,
            function (result, event) {
                if (event.status) {
                    var saveResult = JSON.parse(result);
                    if (saveResult.status == 1) {
                        if (hasFiles()) {
                            uploadCaseImages(saveResult.message);
                        }
                        else {
                            refreshComments();
                        }
                    }
                    else {
                        hideLoging();
                        displayErrorMsg('添加回复失败，请稍后再试');
                    }
                } else {
                    alert(event.message);
                }
            },
            { escape: false, timeout: 120000 }
        )
    }
    catch (e) {
        alert(e);
    }
}

function uploadFile(caseId, followerName) {
    if (hasFiles()) {
        if (validaImageFormat()) {
            createCommentAndFile('添加了新文件', caseId, followerName);
        }
    }
    else {
        displayErrorMsg("请选择一个文件上传");
    }
}

function saveComment(caseId, followerName) {
    var commentBody = jQuery('#commentBody').val();
    if (commentBody == "" && !hasFiles()) {
        displayErrorMsg("请填写回复内容或者上传附件");
    }
    else {
        if (commentBody == "") {
            commentBody = '添加了新文件';
        }
        if ((hasFiles() && validaImageFormat()) || (!hasFiles())) {
            createCommentAndFile(commentBody, caseId, followerName);
        }
    }
}

function uploadCaseImages(newCaseCommentId) {
    var targetId = jQuery("[id$='caseCommentId']");
    targetId.val(newCaseCommentId);
    uploadImages();
}


function checkSupportFileType(fileName) {
    var isSupport = true;
    var validExtensions = ['jpg', 'jpeg', 'heic', 'mp4', 'png', 'avi', 'mov'];
    var fileNameExt = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
    if (jQuery.inArray(fileNameExt, validExtensions) == -1) {
        alert(fileName + '非支持文件类型，请确认后再上传');
        isSupport = false;
    }
    return isSupport
}

function validaImageFormat() {
    var isValid = true;
    var file1 = jQuery(".file1")[0];
    if (file1.files.length > 0) {
        if (file1.files[0].size > (10 * 1024 * 1024)) {
            alert(file1.files[0].name + ' 超出文件大小限制，请压缩后再上传');
            isValid = false;
        }
        else {
            var fileName = file1.files[0].name;
            isValid = checkSupportFileType(fileName);
        }
    }
    return isValid;
}

function hasFiles() {
    var hasFile = false;
    var file1 = jQuery(".file1")[0];
    if (file1.files.length > 0) {
        hasFile = true;
    }
    return hasFile;
}

function displayErrorMsg(content) {
    jQuery('#weuiWarn').show();
    jQuery('#weuiWarn').html(content);
    setTimeout(function () {
        jQuery('#weuiWarn').hide();
    }, 2000);
}

function showLoading() {
    jQuery('#formtast').show();
    jQuery('#formloading').show();
}

function hideLoging() {
    jQuery('#formtast').hide();
    jQuery('#formloading').hide();
}

function initPage(caseId) {
    if (caseId != "") {
        try {
            CharketServiceRequestCommentController.updateCommentCustomerReadDateTime(
                caseId,
                function (result, event) {
                    if (event.status) {
                        var saveResult = JSON.parse(result);
                        //saveResult.message;
                    } else {
                        alert(event.message);
                    }
                },
                { escape: false, timeout: 120000 }
            )
        }
        catch (e) {
            alert(e);
        }
    }
}