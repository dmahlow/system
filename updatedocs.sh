#!/bin/bash
docco -l linear -c public/docs/docco.css -o public/docs `find . \( -name "*.md" ! -path "*node_modules*" \)`
docco -l linear -c public/docs/docco.css -o public/docs `find ./assets \( -name "*.coffee" ! -path "*node_modules*" \)`
docco -l linear -c public/docs/docco.css -o public/docs/server `find ./server \( -name "*.coffee" ! -path "*node_modules*" \)`