#!/bin/bash
./node_modules/.bin/docco -l linear -c public/docs/docco.css -o public/docs `find . \( -name "*.md" ! -path "*node_modules*" \)`
./node_modules/.bin/docco -l linear -c public/docs/docco.css -o public/docs `find ./assets \( -name "*.coffee" ! -path "*node_modules*" \)`
./node_modules/.bin/docco -l linear -c public/docs/docco.css -o public/docs/server `find ./server \( -name "*.coffee" ! -path "*node_modules*" \)`

./node_modules/.bin/docco -l linear -c public/docs/docco.css -o gh-pages/docs `find . \( -name "*.md" ! -path "*node_modules*" \)`
./node_modules/.bin/docco -l linear -c public/docs/docco.css -o gh-pages/docs `find ./assets \( -name "*.coffee" ! -path "*node_modules*" \)`
./node_modules/.bin/docco -l linear -c public/docs/docco.css -o gh-pages/docs/server `find ./server \( -name "*.coffee" ! -path "*node_modules*" \)`