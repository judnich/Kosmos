[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/KosmosBanner.png "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

Kosmos allows you to explore a computer-generated 3D universe from your browser. This virtual universe is extremely vast, containing trillions of stars, planets, and moons to explore. Click the banner above or any of the images below to start Kosmos now (or click this link: http://judnich.github.io/Kosmos/) 

#### System Requirements

As long as your GPU is as fast or faster than an *Intel HD 4000*, Kosmos should run seamlessly up to 1600p+ screen resolutions. This means most *modern* laptops and ultrabooks should be able to run Kosmos smoothly.

*Compatibility Warning:* Kosmos makes advanced use of WebGL, a new internet standard enabling 3D graphics in your browser. Unfortunately, WebGL support on Microsoft Windows is flakey and performs poorly, even on some modern browsers. For example, Chrome does not run Kosmos at all on Windows, due to Google's so-called "compatibility layer" [ANGLE](http://code.google.com/p/angleproject/) which panics and crashes when it encounters complex GPU code. Currently the only semi-working browser on Windows is the *latest version* of Mozilla Firefox.

## Screenshots

*Note: All of these images are raw, unedited screen captures from Kosmos with NO retouching of any kind. Even the banner image at the top of this page is an unedited screenshot from Kosmos (aside from the addition of text captions).*

"Moon"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/moon.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Lava Planet"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/lava1.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Eclipse"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/small-eclipse.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Rusty Planet"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/mars1.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Warp 1"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/blue-shift.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Moon Landing"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/moon2.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Ice Planet"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/ice1.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Moon Surface"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/moon3.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Alien World"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/purple1.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Jungle Planet"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/green1.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Solar Orbit"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/green2.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )

"Red Shift"

[![Click to run Kosmos now!](https://raw.github.com/judnich/Kosmos/master/screenshots/red-shift.jpg "Click to run Kosmos now!")](http://judnich.github.io/Kosmos/ )


## About

Kosmos is my (John Judnich) senior design project for my BS degree at Santa Clara University. I wrote this entire project in WebGL/HTML5 after implementing several other similar prototypes in native code (C++/OpenGL/etc.) The decision to implement in WebGL/HTML5 was due to a number of factors, but mainly for the learning experience to try something new (this is really my first time making a nontrivial HTML5 app).

Also, random people are far more likely to try a web app than a native app (simply because web apps don't require you to invest the time, effort, caution, etc. that is associated with installing and running native binary packages) -- so even for this reason alone, I could have justified the risky proposition of rewriting my entire senior design project from scratch, in HTML5 (WebGL+JS).

Note that this entire project was written completely from scratch in about *four weeks* of solid work (spread out across about a month and a half with breaks in between), during which time I learned the necessary tools: CoffeeScript (because I dislike JavaScript), WebGL, glMatrix, jQuery. As always, it's just a matter of Googling a lot of things until you're proficient, which never takes long. Also, no third party 3D engine was used to build Kosmos, because none were powerful enough to accomplish what I needed (huge universe, high resolution planets, running almost everything on the GPU, etc.)

All of Kosmos (the source code you see in this repository except for the "external" folder) was implemented from the ground up over these few weeks. However, the ideas / algorithms behind Kosmos's technology have been generally within my focus over the past few years (I'm very familiar in-depth in many areas of 3D graphics) which no doubt accelerated my learning curve.

## Credits

The following external open-source libraries were used in Kosmos:

* [glMatrix](http://glmatrix.net/) (JavaScript matrix/vector math) - Brandon Jones and Colin MacKenzie IV
* [jQuery](http://jquery.com/) (Cross-browser compatibility) - jQuery Foundation, Inc.
* [Simplex Noise](https://github.com/ashima/webgl-noise) (Pseudorandom 3D noise) - Ian McEwan, Ashima Arts.

All design and technologies of Kosmos (from UI/UX design and 3D engine implementation, to several cutting-edge technology/algorithm inventions) are the sole creations of John Judnich, designed and implemented entirely from scratch using only the external open-source libraries mentioned above.

## License

#### Kosmos is released as open source under [The MIT License](https://github.com/judnich/Kosmos/blob/master/LICENSE).

#### Copyright (C) 2013 John Judnich. All Rights Reserved.
