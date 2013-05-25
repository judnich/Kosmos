// Copyright (C) 2013 John Judnich
// Released under The MIT License - see "LICENSE" file for details.

// NOTE: Needs major cleanup, decouple events from html, change to coffeescript
// This file is meant to cover all UI stuff and abstract that away from the main 
// simulation/game code found in Main.coffee. This file isn't that "important" right
// now in the sense that most of Kosmos is in the 3D rendering stuff, not the management
// of slider bars.


_speed = 0.0;
_reverseMode = false;
_sliderMouseDown = false;
_ignoreWarning = false;
_autopilotMode = true;

function detectMobile() { 
	if( navigator.userAgent.match(/Android/i)
		|| navigator.userAgent.match(/webOS/i)
		|| navigator.userAgent.match(/iPhone/i)
		|| navigator.userAgent.match(/iPad/i)
		|| navigator.userAgent.match(/iPod/i)
		|| navigator.userAgent.match(/BlackBerry/i)
		|| navigator.userAgent.match(/Windows Phone/i) ){
		return true;
	}
	else {
		return false;
	}
}

function jsMain() {
	updateMessagePositions();
	showIntro();

	var is_chrome = navigator.userAgent.indexOf('Chrome') > -1;
	var is_explorer = navigator.userAgent.indexOf('MSIE') > -1;
	var is_firefox = navigator.userAgent.indexOf('Firefox') > -1;
	var is_safari = navigator.userAgent.indexOf("Safari") > -1;
	var is_opera = navigator.userAgent.indexOf("Presto") > -1;
	if ((is_chrome)&&(is_safari)) {is_safari=false;}
	var is_mobile = detectMobile();

	var OSName="Unknown OS";
	if (navigator.appVersion.indexOf("Win")!=-1) OSName="Windows";
	if (navigator.appVersion.indexOf("Mac")!=-1) OSName="MacOS";
	if (navigator.appVersion.indexOf("X11")!=-1) OSName="UNIX";
	if (navigator.appVersion.indexOf("Linux")!=-1) OSName="Linux";

	if (is_mobile) {
		document.location = "http://judnich.github.io/KosmosMobile";
	}

	if ( OSName=="Windows" || !is_firefox ) {
		if (_ignoreWarning != true) {
			document.getElementById("browserErrorMessage").style.display = "block";
			return;
		}
	}

	function resizeCanvas() {
		// correct canvas dimensions due to sidebar
		document.getElementById("rightbar").style.width = 
			(window.innerWidth - document.getElementById("sidebar").clientWidth) + "px";
	}

	resizeCanvas();

	// set up slider events
	var slider = document.getElementById("slider");

	function sliderEvent(x, y) {
		_speed = 1.0 - ((y-3) / (slider.clientHeight+3));
		if (_speed > 1) _speed = 1;
		updateSpeed();
	}

	function mouseWheelEvent(event) {
		if (event.wheelDelta)
			d = event.wheelDelta;
		else
			d = event.detail * -30.0; // stupid firefox incompatibility
		_speed -= d / 4000.0	
		if (_speed > 1) _speed = 1;
		updateSpeed();
		event.preventDefault();
		return false;
	}

	var mousewheelevt=(/Firefox/i.test(navigator.userAgent))? "DOMMouseScroll" : "mousewheel" //FF doesn't recognize mousewheel as of FF3.x
	if (document.attachEvent) //if IE (and Opera depending on user setting)
	    document.attachEvent("on"+mousewheelevt, mouseWheelEvent)
	else if (document.addEventListener) //WC3 browsers
	    document.addEventListener(mousewheelevt, mouseWheelEvent, false)

	document.body.style.overflow = 'hidden';

	$(slider).mousedown(function(e) {
		_sliderMouseDown = true;
		var offX  = (e.offsetX || e.clientX - $(e.target).offset().left);
		var offY  = (e.offsetY || e.clientY - $(e.target).offset().top);
		sliderEvent(offX, offY);
	});

	$(slider).mouseup(function(event) {
		_sliderMouseDown = false;
	});

	$(slider).mousemove(function(e) {
		if (_sliderMouseDown) {
			var offX  = (e.offsetX || e.clientX - $(e.target).offset().left);
			var offY  = (e.offsetY || e.clientY - $(e.target).offset().top);
			sliderEvent(offX, offY);
		}
	});

	$(document).mouseup(function(event) {
		_sliderMouseDown = false;
	});


	// CoffeeScript code entry point
	kosmosMain();

	updateSpeed();
	showIntro();

	window.onresize = function() {
		resizeCanvas();
		updateMessagePositions();
		kosmosResize();
	}

	document.onkeydown = function(event) {
		hideIntro();

		// down arrow / S / -
		if (event.keyCode == 189 || event.keyCode == 83 || event.keyCode == 40) {
			_speed -= 0.005;
		}

		// up arrow / W / +
		if (event.keyCode == 187 || event.keyCode == 87 || event.keyCode == 38) {
			_speed += 0.005;
		}

		// escape
		if (event.keyCode == 27) {
			_speed = 0;
		}

		// space
		if (event.keyCode == 32) {
			_reverseMode = !_reverseMode;
			updateButtons();
		}

		updateSpeed();
	}
}

function hideIntro() {
	var msg = document.getElementById("introMessage");
	msg.style.display = "none";
}

function hideBrowserMessage() {
	var msg = document.getElementById("browserErrorMessage");
	msg.style.display = "none";
	_ignoreWarning = true;
	jsMain();
}

function hideErrorMessage() {
	var msg = document.getElementById("glErrorMessage");
	msg.style.display = "none";
}

function updateMessagePositions() {
	var sidebarWidth = document.getElementById("sidebar").clientWidth;

	var messages = document.getElementsByClassName("message");
	for (var i = 0; i < messages.length; ++i) {
		var msg = messages[i];

		var oldDisp = msg.style.display;
		msg.style.display = "block";

		var x = sidebarWidth + (window.innerWidth-sidebarWidth)/2 - (msg.clientWidth+23)/2;
		var y = window.innerHeight/2 - (msg.clientHeight+23)/2;

		msg.style.display = oldDisp;

		msg.style.left = x;
		msg.style.top = y;
	}
}

function showIntro() {
	var msg = document.getElementById("introMessage");
	msg.style.display = "block";
}

function showShare() {
	hideIntro();
	var msg = document.getElementById("shareMessage");
	msg.style.display = "block";
	btn = document.getElementById("shareBtn");
	btn.className = "btn lit";
	saveLocation(); // this updates the share link as well
}

function hideShare() {
	var msg = document.getElementById("shareMessage");
	msg.style.display = "none";
	btn = document.getElementById("shareBtn");
	btn.className = "btn";
}

function updateSpeed() {
	hideIntro();

	if (_speed > 1.0) _speed = 1.0;

	// the first few percent of the speed bar is 0, to give a reasonable click region for it
	var speedBarZeroArea = 0.07;
	var slider = document.getElementById("slider");

	var cSpeed = _speed;
	if (cSpeed > 1) {
		cSpeed = 1;
	} else if (cSpeed <= speedBarZeroArea) {
		cSpeed = speedBarZeroArea;
		_speed = speedBarZeroArea - 0.0001;
		slider.className = "slider sliderDisabled";
	} else {
		slider.className = "slider";
	}

	var sliderBar = document.getElementById("sliderBar");
	sliderBar.style.height = ((1.0 - cSpeed) * 100.0) + "%";

	var speed = (_speed - speedBarZeroArea);

	kosmosSetSpeed(speed, _reverseMode);
}

function updateButtons() {
	document.getElementById("reverse").className = (_reverseMode ? "btn lit" : "btn");
	document.getElementById("autopilot").className = (_autopilotMode ? "btn lit" : "btn");
}

function toggleReverse() {
	_reverseMode = !_reverseMode;
	updateButtons();
	updateSpeed();
}

function toggleAutopilot() {
	_autopilotMode = !_autopilotMode;
	updateButtons();
	kosmosSetAutopilot(_autopilotMode);
}

function killSimulation() {
	kosmosKill();
}
