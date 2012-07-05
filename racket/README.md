# Notes

The server is currently not at all done. It's an exploration of a few things.

To run it, slam it into DrRacket and hit "run".

It expects the directory "htdocs" to be symlinked ../Express/public/. This serves
up the webapp.

Also, I broke the webapp with respect to the Node.JS server. It now points at port 8000 with the "run", and it sends stringified JSON. This is in parse.js, which is an adapter. This pushes the data to the Scheme server, and preps it for conversion.

We already have the conversion code. Now we have to script the backend tools, and set the correct port from the webapp.

All told, we're pretty close.

