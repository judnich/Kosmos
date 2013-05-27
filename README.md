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

### Future Plans

Kosmos (this web based version version) was mostly an experimental, self-educational project for me. In retrospect, WebGL simply has too many compatibility issues/hassles for it to be a valuable target for my spare time projects. My future versions or projects will most likely be done with native code instead -- certainly until WebGL stops being flakey, and browsers figure out how to get closer to native performance.

For example I'd like to make a future improved version of Kosmos as a mobile game app, targeting tablets in particular. Additionally, there are a lot of features I'd include that I didn't have time for in the current web based version:

* Planet atmospheres with correct simulated atmospheric scattering effects

* Much more ground-level detail (i.e. trees, grass, etc.)

* Animated planet orbits and rotations

* More variety of planet types (right now there's just a few base types)

* Gameplay dynamics with space and ground combat

However since following graduation most of my time will be dedicated to full-time work, "Kosmos 2.0" probably won't be likely any time soon exept possibly as a weekend project.

### Lessons Learned

* WebGL is flakey and not ready for "serious" 3D games yet (except the most rudimentary last-gen graphics)

* Procedural content generation, while a nice idea in concept, ultimately doesn't "save" you all that much work. In theory it provides "infinite variation" of planets, stars, etc., but it does NOT provide infinite *novelty*.

#### Sidenote: Thoughts on procedural generation

What we find interesting artistically and visually is not variation, but "novelty". While admittedly a more vague word, novelty represents content that is truly "new", rather than just parameterized variations of the same thing seen before.

Although procedural generation engines (like Kosmos) can provide infinitely varying universes with trillions of stars without the need for each to be individually designed, it becomes boring after a while because our minds eventually adapt and figure out the underlying patterns very rapidly.

Therefore, some amount of hand-crafting and artistically created content is needed to make content sufficiently interesting for a game, for example. However, one possible exception would be a more intricately simulation-oriented generation system (i.e. rather than simple mathematical functions to generate planet-resembling things, actually simulate gasses in space, gravity in space, star formation, planet formation, erosion, elements, etc. etc.) This could produce a system so complex that variation does become truly "novel" in some sense, simply from the sheer scale and detail of the simulation. However doing this would require far too much computational power to be feasible in real-time on even powerful gaming computers, let alone mobile/casual devices. It might be feasible though as a offline content creation tool to ease the work of artists, however. Or, it could be feasible if offloaded to a supercomputing "cloud", with the data streamed to users of the game world on-demand. Even then though, creating the rules for such a simulation would be no small feat in of itself.

So for at least quite some time, I think most 3D worlds will need to have some aspect of human-guided design to be effectively interesting for games. This doesn't rule out procedurally generated content by any means, it just means you'll probably spend about as much time crafting procedural rules/equations as an artist would making it by hand anyway.


## Credits

The following external open-source libraries were used in Kosmos:

* [glMatrix](http://glmatrix.net/) (JavaScript matrix/vector math) - Brandon Jones and Colin MacKenzie IV
* [jQuery](http://jquery.com/) (Cross-browser compatibility) - jQuery Foundation, Inc.
* [Simplex Noise](https://github.com/ashima/webgl-noise) (Pseudorandom 3D noise) - Ian McEwan, Ashima Arts.

All design and technologies of Kosmos (from UI/UX design and 3D engine implementation, to several cutting-edge technology/algorithm inventions) are the sole creations of John Judnich, designed and implemented entirely from scratch using only the external open-source libraries mentioned above.

## License

#### Kosmos is released as open source under [The BSD License](https://github.com/judnich/Kosmos/blob/master/LICENSE).

#### Copyright (C) 2013 John Judnich. All Rights Reserved.
