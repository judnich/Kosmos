// NOTE: Needs major cleanup, decouple events from html, change to coffeescript
// This file is meant to cover all UI stuff and abstract that away from the main 
// simulation/game code found in Main.coffee

_speed = 0.65;
_reverseMode = false;
_sliderMouseDown = false;

function jsMain() {
	function resizeCanvas() {
		// correct canvas dimensions due to sidebar
		document.getElementById("rightbar").style.width = 
			(window.innerWidth - document.getElementById("sidebar").clientWidth) + "px";
	}
	resizeCanvas();

	// set up slider events
	var slider = document.getElementById("slider");

	function sliderEvent(x, y) {
		_speed = 1.0 - (y / (slider.clientHeight+3));
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
		kosmosResize();
		updateIntro();
	}

	document.onkeydown = function(event) {
		hideIntro();
		if (event.keyCode == 189 || event.keyCode == 83 || event.keyCode == 40) {
			_speed -= 0.025;
		}
		if (event.keyCode == 187 || event.keyCode == 87 || event.keyCode == 38) {
			_speed += 0.025;
		}
		if (_speed > 1.5) _speed = 1.5;

		if (event.keyCode == 27) { // escape
			killSimulation();
		}
		if (event.keyCode == 32) { // space
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

function updateIntro() {
	var msg = document.getElementById("introMessage");
	var sidebarWidth = document.getElementById("sidebar").clientWidth;
	var x = sidebarWidth + (window.innerWidth-sidebarWidth)/2 - (msg.clientWidth+23)/2;
	var y = window.innerHeight/2 - (msg.clientHeight+23)/2;
	msg.style.left = x;
	msg.style.top = y;
}

function showIntro() {
	var msg = document.getElementById("introMessage");
	msg.style.display = "block";
	updateIntro();
}

function updateSpeed() {
	hideIntro();

	// the first few percent of the speed bar is 0, to give a reasonable click region for it
	var speedBarZeroArea = 0.07;
	var slider = document.getElementById("slider");
	if (_speed < speedBarZeroArea) {
		_speed = speedBarZeroArea;
		slider.className = "slider sliderDisabled";
	} else {
		slider.className = "slider";
	}

	var cSpeed = _speed;
	if (cSpeed > 1) cSpeed = 1; else if (cSpeed < 0) cSpeed = 0;
	var sliderBar = document.getElementById("sliderBar");
	sliderBar.style.height = ((1.0 - cSpeed) * 100.0) + "%";

	var speed = (_speed - speedBarZeroArea);

	var espeed = Math.pow(3.0, Math.abs(speed) * 20.0 - 10.0);
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
