#!/bin/bash
docco -o public/docs `find . \( -name "*.md" ! -path "*node_modules*" \)`
docco -o public/docs `find ./assets \( -name "*.coffee" ! -path "*node_modules*" \)`
docco -o public/docs/server `find ./server \( -name "*.coffee" ! -path "*node_modules*" \)`