$(document).ready(function () {
  // const scrSize = window.matchMedia("(min-width: 900px)");
  // if (scrSize.matches) {
  //   // Top menu setup

  // }
  $("#top-menu").after('<div id="topmenu-nav"></div>');
  $("#topmenu-nav").append($("#top-menu").html());
  $("#top-menu").empty();

  $("#topmenu-nav").prepend($("#header h1"));

  $("#quick-search").appendTo("#topmenu-nav");
  $("#quick-search #project-jump").appendTo($("#topmenu-nav h1"));

  const ele = $("#quick-search label a");
  $("#quick-search label").empty();
  $(ele).appendTo("#quick-search label");
  const srch = "<div class = expandSearch ></div>";
  $("#quick-search #q").before(srch).prependTo(".expandSearch");
  $("#project-jump .drdn-trigger").prop("title", "Jump to project");
  $("#userprofile").prop("title", "User profile");
  $("#loggedas").prependTo("#account");
  $("#account").appendTo("#topmenu-nav");

  //Add header after topmenu nav

  // Get current user avatar if available (BEFORE removing #loggedas)
  var userAvatar = "";
  if ($("#loggedas").length > 0) {
    // Try to get avatar from the page if it exists
    var avatarImg = $("img.gravatar").first();
    console.log("=== Gravatar Debug Info ===");
    console.log("Found gravatar images:", $("img.gravatar").length);
    console.log("Gravatar src:", avatarImg.attr("src"));

    if (avatarImg.length > 0) {
      console.log("Gravatar found - processing...");
      // Clone the avatar image and adjust size for profile icon
      var clonedAvatar = avatarImg.clone();
      clonedAvatar.css({
        width: "32px",
        height: "32px",
        "border-radius": "50%",
        "object-fit": "cover",
      });
      userAvatar = clonedAvatar.prop("outerHTML");
      console.log("Processed userAvatar:", userAvatar);
    } else {
      console.log("No gravatar image found on page");
    }
  }

  // For user profile Setup (AFTER getting avatar)
  if ($("#loggedas").length > 0) {
    var loggedasEle = $.parseHTML($("#loggedas").html());
    $("#loggedas").remove();
    $("#account ul").prepend("<li></li>");
    $("#account ul li").first().html(loggedasEle[1]);
  }

  var account = '<div id="userprofile">';
  if (userAvatar) {
    account += '<div class="profileicon account" id="myprofile"></div>';
    console.log("Profile icon created with avatar");
  } else {
    account += '<div class="profileicon account" id="myprofile"></div>';
    console.log("Profile icon created without avatar");
  }
  account += '<div id="profilemenu" style="display: none;"></div></div>';
  $("#quick-search").append(account);
  $("#account ul").prop("id", "profilelist").appendTo("#profilemenu");
  $("#account").remove();
  $("#topmenu-nav > ul").appendTo($("#quick-search"));
  $("#userprofile").appendTo("#quick-search");

  // GNB 영역의 projects 링크 URL 변경
  $("#quick-search a.projects").attr("href", "/projects?set_filter=1&sort=");

  // For user profile popup setup
  $(".account").click(function () {
    var X = this.id;
    if (X == 1) {
      $("#profilemenu").hide();
      $(".profileicon").removeClass("show");
      $(this).prop("id", "0");
    } else {
      $("#profilemenu").show();
      $(".profileicon").addClass("show");
      $(this).prop("id", "1");
    }
  });
  $("#profilemenu, .account").mouseup(function () {
    return false;
  });
  $(document).mouseup(function () {
    $("#profilemenu").hide();
    $(".profileicon").removeClass("show");
    $(".account").prop("id", "");
  });

  if ($('label[for="settings_app_title"]').length) {
    $('label[for="settings_app_title"]').parent().hide();
  }
  if ($('label[for="settings_ui_theme"]').length) {
    $('label[for="settings_ui_theme"]').parent().hide();
  }

  if ($("body.controller-my").length) {
    $("#user_firstname, #user_lastname, #user_mail").prop("disabled", true);
    $('select#block-select option[value="issuequery"]').prop("hidden", true); // 숨기기
    $("#password_fields").closest(".box.tabular, .box").hide();
    $("#notified-projects").closest(".box").hide();
    $("#user_mail_notification").closest(".box").hide();
    $("#tab-content-memberships .icon-add").hide();
    $("#sidebar-wrapper p").has(".icon-del").hide();
  }

  if ($("body.controller-users").length) {
    $("#user_mail").prop("disabled", true);
    $("#user_login").prop("disabled", true);
    $("#user_firstname").prop("disabled", true);
    $("#user_lastname").prop("disabled", true);

    // Fallback for CSS :has() — hide parent boxes via jQuery on users controller pages
    $("#password_fields").closest(".box.tabular, .box").hide();
    $("#notified-projects").closest(".box").hide();
    $("#user_mail_notification").closest(".box").hide();
    $("#tab-content-memberships .icon-add").hide();
    $("#sidebar-wrapper p").has(".icon-del").hide();

    if ($(".splitcontentright").children().length === 0) {
      $(".splitcontentright").addClass("empty");
    }
  }

  if ($("body.controller-groups").length) {
  }

  // Swap positions of <p> blocks wrapping #user_firstname and #user_lastname
  (function () {
    var firstBlock = $("#user_firstname").closest("p");
    var lastBlock = $("#user_lastname").closest("p");
    if (
      firstBlock.length &&
      lastBlock.length &&
      firstBlock[0] !== lastBlock[0]
    ) {
      var placeholder = $('<span style="display:none;"></span>');
      firstBlock.before(placeholder);
      lastBlock.before(firstBlock);
      placeholder.replaceWith(lastBlock);
    }
  })();

  if ($("body.controller-groups").length) {
    $('label[for="group_twofa_required"]').parent().hide();
  }

  if ($("body.controller-settings").length) {
    $('label[for="settings_gravatar_enabled"]').parent().hide();
    $('label[for="settings_gravatar_default"]').parent().hide();
    $('label[for="settings_user_format"]').parent().hide();
    $("#tab-api").parent().hide();
    $("#tab-users").parent().hide();
    $("#tab-repositories").parent().hide();
  }

  // 공통으로 숨겨야할 항목
  $('label[for="user_lastname"]').parent().hide();

  (function () {
    var currentYear = new Date().getFullYear();
    var $footer = $("#footer");

    // 기존에 삽입된 커스텀 표기 제거 (중복 방지)
    $footer.find(".jandi-copyright").remove();

    // 기존 푸터 텍스트 내의 연도 범위를 현재 연도로 갱신 (예: "© 2006-2025" → "© 2006-2026")
    var html = $footer.html();
    if (typeof html === "string") {
      var replaced = html.replace(
        /©\s*(\d{4})(?:\s*[-]\s*(\d{4}))?/i,
        function (full, start, end) {
          var startYearNum = parseInt(start, 10);
          if (!isFinite(startYearNum) || startYearNum > currentYear)
            return full;
          var yearText =
            startYearNum === currentYear
              ? String(currentYear)
              : startYearNum + "-" + currentYear;
          return "© " + yearText;
        }
      );
      if (replaced !== html) {
        $footer.html(replaced);
        return;
      }
    }

    // 대체: 연도 범위를 찾지 못한 경우 회사 표기를 현재 연도로 추가
    var companyHtml =
      "© 2025 - " +
      currentYear +
      ' <a href="https://www.jandi.com/landing/" target="_blank" rel="noopener noreferrer">Toss Lab, Inc.</a>';
    $footer.append('<span class="jandi-copyright">' + companyHtml + "</span>");
  })();
  // Fallback for CSS :has() — hide paragraphs containing .icon-del in the sidebar

  // 1) 미디어쿼리 객체
  const mq = window.matchMedia("(max-width: 899px)");

  // ===== URL 경로 감지: /blocked =====
  (function detectBlockedRoute() {
    try {
      var path =
        window.location && window.location.pathname
          ? window.location.pathname
          : "";
      // '/blocked' 또는 '/blocked/' 형태 모두 허용
      var isBlocked = /^\/blocked\/?$/.test(path);
      if (isBlocked) {
        $("#quick-search").css("visibility", "hidden");
      } else {
        $("#quick-search").css("visibility", "visible");
      }
    } catch (e) {
      // no-op (안전하게 무시)
    }
  })();

  // 2) 핸들러
  function onViewportChange(e) {
    if (e.matches) {
      // 899px 이하
      // ... 모바일 전용 로직
      $("#header").prepend($("#topmenu-nav"));
    } else {
      // 900px 이상
      // ... 데스크톱 전용 로직
    }
  }

  // 3) 초기 1회 실행
  onViewportChange(mq);

  // 4) 상태 변화 구독
  if (mq.addEventListener) {
    mq.addEventListener("change", onViewportChange);
  } else {
    // 구형 브라우저 호환
    mq.addListener(onViewportChange);
  }
});

// DOM 준비 후 실행
$(function () {
  const htmlEl = document.documentElement; // <html>
  let wasActive = htmlEl.classList.contains("flyout-is-active");

  const observer = new MutationObserver((mutations) => {
    for (const m of mutations) {
      if (m.type === "attributes" && m.attributeName === "class") {
        const isActive = htmlEl.classList.contains("flyout-is-active");
        if (isActive !== wasActive) {
          wasActive = isActive;
          if (isActive) {
            // 활성화됨
            $(document).trigger("flyout:open");
          } else {
            // 비활성화됨
            $(document).trigger("flyout:close");
          }
        }
      }
    }
  });

  observer.observe(htmlEl, { attributes: true, attributeFilter: ["class"] });
});

$(document).on("flyout:open", function () {
  // 열림 처리
  const mobileNavTarget = $(".js-project-menu");
  const mobileNavTarget2 = $(".js-general-menu");
  // mobile gnb 프로젝트
  const linkClassesProject = [
    ".activity",
    ".issues",
    ".time-entries",
    ".gantt",
    ".calendar",
    ".news",
    ".display-menu-link",
    ".documents",
    ".wiki",
    ".files",
    ".settings",
    ".boards",
    ".roadmap",
  ];
  // mobile gnb 일반
  const linkClassesGeneral = [
    ".my-page",
    ".administration",
    ".help",
    ".projects",
  ];
  const selector = linkClassesProject.map((cls) => `a${cls}`).join(", ");
  const selector2 = linkClassesGeneral.map((cls) => `a${cls}`).join(", ");
  mobileNavTarget.find(selector).closest("li").hide();

  mobileNavTarget2.find(selector2).closest("li").hide();
  $(".js-profile-menu").prev("h3").hide();
});
$(document).on("flyout:close", function () {
  // 닫힘 처리
});
