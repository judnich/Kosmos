// NOTE: Needs major cleanup, decouple events from html, change to coffeescript
// This file is meant to cover all UI stuff and abstract that away from the main 
// simulation/game code found in Main.coffee

_speed = 0.0;
_reverseMode = false;
_sliderMouseDown = false;

function jsMain() {
	updateMessagePositions();

	var is_chrome = !(window.chrome === undefined);
	//var is_safari = navigator.userAgent.toLowerCase().indexOf('safari/') > -1;

	if (!is_chrome) {
		document.getElementById("browserErrorMessage").style.display = "block";
		return;
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

	window.onmousewheel = function(event) {
		d = event.wheelDelta
		_speed -= d / 4000.0	
		if (_speed > 1) _speed = 1;
		updateSpeed();
		event.preventDefault();
		return false;
	}

	document.body.style.overflow = 'hidden';

	slider.addEventListener("mousedown", function(event) {
		_sliderMouseDown = true;
		sliderEvent(event.offsetX, event.offsetY);
	}, false);

	slider.addEventListener("mouseup", function(event) {
		_sliderMouseDown = false;
	}, false);

	slider.addEventListener("mousemove", function(event) {
		if (_sliderMouseDown) {
			sliderEvent(event.offsetX, event.offsetY);
		}
	}, false);

	document.addEventListener("mouseup", function(event) {
		_sliderMouseDown = false;
	}, false);


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
	//msg.parentNode.removeChild(msg);
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
	var espeed = Math.pow(3.0, Math.abs(speed) * 21.0 - 6.0);

	if (speed <= 0) espeed = 0;
	if (_reverseMode) espeed *= -1;

	kosmosSetSpeed(espeed);
}

function updateButtons() {
	document.getElementById("reverse").className = (_reverseMode ? "btn lit" : "btn");
	//document.getElementById("stop").className = (_stoppedMode ? "btn redlit" : "btn red");
}

function toggleReverse() {
	_reverseMode = !_reverseMode;
	updateButtons();
	updateSpeed();
}

function killSimulation() {
	kosmosKill();
}
