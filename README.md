## Kosmos

A fully explorable virtual 3D universe.

### Coming Soon

Kosmos allows you to explore a computer-generated 3D universe from your browser.

### About

Kosmos originally was meant as a large-scale universe visualization on fairly high end PCs -- my senior design project for my Computer Science and Engineering BS degree at SCU. I spent a few months implementing towards this goal using C++ and an assortment of Open-Source libraries. However about one month before the senior design project completion deadline, I realized that such a thing already exists (en.spaceengine.org).

So rather than remake an existing product, I decided to re-target Kosmos to a different audience with a slightly different set of goals. In particular, Kosmos should run smoothly on an average modern laptop. Moreover, this latest rewrite of Kosmos runs *in any modern web-browser*, thanks to WebGL. 

Unfortunately, this means the entire project had to be rewritten from scratch using JavaScript/CoffeeScript and WebGL (where an entire 3D engine must be built from the ground up, whereas in C++ I was using the open source OGRE engine to accelerate productivity).

Progress: So far, stars are done. Now I just need to add planets and general polish. TODO: Update progress when finished.

### Teaser Screenshot

![moon](https://raw.github.com/judnich/Kosmos/master/moon.png)