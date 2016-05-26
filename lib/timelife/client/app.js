// Define Ruby Application Holder in JS.
var app;
var scene_manager;

// refresh main-clock # Native
function refresh_MainClock(status) {
  if (status == 'ready') {
    d = new Date();
    $('#main-clock').text(sprintf("%02d:%02d:%02d", d.getHours(), d.getMinutes(), d.getSeconds()));
  }
}

// Get Application Status
function appStatus() {
  return app.scene.status;
}

// Refresh APP
function refreshAPP() {
  status = appStatus();
  refresh_MainClock(status);
}

// Application Ready
window.appReady = function() {
  setInterval(refreshAPP, 1000);
  $(document).keydown(function(event) {
    scene_manager.$keydown(event.keyCode);
  });
  $$('.scene-main').swipeLeft(function() {
    scene_manager.$slide_right();
  });
  $$('.scene-main').swipeUp(function() {
    scene_manager.$slide_down();
  });
  $$('.scene-main').swipeRight(function() {
    scene_manager.$slide_left();
  });
  $$('.scene-main').swipeDown(function() {
    scene_manager.$slide_up();
  });
};

